# -----------------------------------------------------------------------------
# S3 bucket via trussworks/s3-private-bucket
#
# Layout:
#   repo/pkgs/     Munki packages (munkiimport -> S3, munkisrv serves via CF)
#   bootstrap/     Fleet bootstrap pkg (CI -> S3, Fleet references signed URL)
# -----------------------------------------------------------------------------

module "packages" {
  source  = "trussworks/s3-private-bucket/aws"
  version = "~> 9.0"

  bucket                      = var.bucket_name
  use_account_alias_prefix    = false
  logging_bucket              = ""
  versioning_status           = "Enabled"
  enable_bucket_force_destroy = false

  # Inject CloudFront OAC access into the bucket policy.
  # The trussworks module merges this with its default TLS enforcement policy.
  custom_bucket_policy = data.aws_iam_policy_document.cloudfront_oac.json

  tags = var.tags
}

# CloudFront OAC bucket access policy (merged into trussworks module's policy)
data "aws_iam_policy_document" "cloudfront_oac" {
  statement {
    sid     = "AllowCloudFrontOAC"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.cloudfront_distribution_arn]
    }
  }
}

# -----------------------------------------------------------------------------
# CloudFront signing key group
#
# The public key and private key are created by bin/generate-signing-key.sh
# which stores the private key in Secrets Manager (never enters Terraform state).
# Terraform only references the public key ID to build the key group.
# -----------------------------------------------------------------------------

resource "aws_cloudfront_key_group" "signing" {
  comment = "${var.name_prefix} signed URL key group"
  items   = [var.cloudfront_public_key_id]
  name    = "${var.name_prefix}-signing-group"
}

# -----------------------------------------------------------------------------
# ACM certificate (us-east-1, required by CloudFront)
# -----------------------------------------------------------------------------

module "acm" {
  count   = var.domain_name != "" ? 1 : 0
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.us-east-1
  }

  domain_name         = var.domain_name
  zone_id             = var.route53_zone_id
  validation_method   = "DNS"
  wait_for_validation = true

  tags = var.tags
}

# Route53 CNAME pointing domain to CloudFront
resource "aws_route53_record" "cdn" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

# -----------------------------------------------------------------------------
# CloudFront distribution
# -----------------------------------------------------------------------------

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.0"

  comment             = "${var.name_prefix} package delivery"
  enabled             = true
  is_ipv6_enabled     = false
  price_class         = var.price_class
  retain_on_delete    = false
  wait_for_deployment = false
  aliases             = var.domain_name != "" ? [var.domain_name] : []

  # OAC for S3 access (v6+, no OAI)
  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "${var.name_prefix} S3 access"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  # S3 origin
  origin = {
    s3_packages = {
      domain_name           = module.packages.bucket_regional_domain_name
      origin_access_control = "s3_oac"
    }
  }

  # All requests require signed URLs via key group
  default_cache_behavior = {
    target_origin_id       = "s3_packages"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods    = ["GET", "HEAD", "OPTIONS"]
    cached_methods     = ["GET", "HEAD"]
    compress           = true
    query_string       = true
    trusted_key_groups = [aws_cloudfront_key_group.signing.id]
  }

  # Custom domain TLS
  viewer_certificate = var.domain_name != "" ? {
    acm_certificate_arn      = module.acm[0].acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  logging_config = {}

  geo_restriction = {
    restriction_type = "none"
    locations        = []
  }

  tags = var.tags
}
