# =============================================================================
# CloudFront Distribution with Signed URLs
# Serves content from S3 with Origin Access Control and signed URL support
#
# Signing keys are generated automatically on first apply via provisioner.
# Subsequent applies read from Secrets Manager (key never in TF state).
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  resource_name        = "${var.name}-${var.environment}"
  secret_name          = "${var.name}-${var.environment}-cdn-signing"
  cloudfront_url       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.main.domain_name}"
  create_acm_cert      = var.domain_name != "" && var.acm_certificate_arn == ""
  acm_cert_arn         = local.create_acm_cert ? aws_acm_certificate.main[0].arn : var.acm_certificate_arn
  enable_custom_domain = var.domain_name != ""
  enable_logging       = var.logging_bucket != ""
}

# =============================================================================
# Signing Key Generation (runs only if secret doesn't exist)
# =============================================================================

# Check if signing secret already exists
data "external" "check_secret" {
  program = ["bash", "-c", <<-EOF
    if aws secretsmanager describe-secret --secret-id "${local.secret_name}" --region "${data.aws_region.current.name}" >/dev/null 2>&1; then
      echo '{"exists": "true"}'
    else
      echo '{"exists": "false"}'
    fi
  EOF
  ]
}

# Generate signing key only if secret doesn't exist
resource "null_resource" "generate_signing_key" {
  count = data.external.check_secret.result.exists == "false" ? 1 : 0

  provisioner "local-exec" {
    command     = "${path.module}/bin/generate-signing-key.sh --name ${local.resource_name} --region ${data.aws_region.current.name}"
    interpreter = ["bash", "-c"]
  }
}

# Read the signing secret (created by provisioner or pre-existing)
data "aws_secretsmanager_secret" "signing" {
  name       = local.secret_name
  depends_on = [null_resource.generate_signing_key]
}

data "aws_secretsmanager_secret_version" "signing" {
  secret_id  = data.aws_secretsmanager_secret.signing.id
  depends_on = [null_resource.generate_signing_key]
}

locals {
  signing_secret         = jsondecode(data.aws_secretsmanager_secret_version.signing.secret_string)
  cloudfront_public_key_id = local.signing_secret.cloudfront_public_key_id
}

# =============================================================================
# ACM Certificate (CloudFront requires us-east-1)
# =============================================================================

resource "aws_acm_certificate" "main" {
  count             = local.create_acm_cert ? 1 : 0
  provider          = aws.us-east-1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name        = local.resource_name
    Environment = var.environment
  })
}

resource "aws_route53_record" "acm_validation" {
  for_each = local.create_acm_cert ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.dns_zone_id
}

resource "aws_acm_certificate_validation" "main" {
  count                   = local.create_acm_cert ? 1 : 0
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# =============================================================================
# CloudFront Key Group
# =============================================================================

resource "aws_cloudfront_key_group" "signing" {
  name    = local.resource_name
  comment = "Key group for ${local.resource_name}"
  items   = [local.cloudfront_public_key_id]
}

# =============================================================================
# Origin Access Control
# =============================================================================

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = local.resource_name
  description                       = "OAC for ${local.resource_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# =============================================================================
# S3 Bucket Policy - Allow CloudFront Access
# =============================================================================

data "aws_iam_policy_document" "s3_cloudfront" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = var.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_cloudfront.json
}

# =============================================================================
# CloudFront Distribution
# =============================================================================

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.resource_name} distribution"
  default_root_object = ""
  price_class         = var.price_class
  wait_for_deployment = false

  aliases = local.enable_custom_domain ? [var.domain_name] : []

  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "S3-${var.s3_bucket_id}"
    origin_path              = var.origin_path != "" ? "/${var.origin_path}" : ""
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.s3_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Require signed URLs
    trusted_key_groups = [aws_cloudfront_key_group.signing.id]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.enable_custom_domain
    acm_certificate_arn            = local.enable_custom_domain ? local.acm_cert_arn : null
    ssl_support_method             = local.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.enable_custom_domain ? "TLSv1.2_2021" : null
  }

  depends_on = [aws_acm_certificate_validation.main]

  dynamic "logging_config" {
    for_each = local.enable_logging ? [1] : []
    content {
      bucket          = "${var.logging_bucket}.s3.amazonaws.com"
      prefix          = var.logging_prefix
      include_cookies = false
    }
  }

  tags = merge(var.tags, {
    Name        = local.resource_name
    Environment = var.environment
  })
}

# =============================================================================
# Route53 Record (optional)
# =============================================================================

resource "aws_route53_record" "main" {
  count = local.enable_custom_domain && var.dns_zone_id != "" ? 1 : 0

  zone_id = var.dns_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# =============================================================================
# IAM Policy for ECS to read signing secret
# =============================================================================

data "aws_iam_policy_document" "signing_secret_access" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.signing.arn]
  }
}

resource "aws_iam_policy" "signing_secret_access" {
  name        = "${local.resource_name}-cloudfront-signing-access"
  description = "Allow access to CloudFront signing secret for ${local.resource_name}"
  policy      = data.aws_iam_policy_document.signing_secret_access.json
}
