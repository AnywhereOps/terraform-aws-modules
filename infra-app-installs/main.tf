data "aws_caller_identity" "current" {}

locals {
  secret_name = var.secret_name != "" ? var.secret_name : "${var.name_prefix}-cdn-signing"
}

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
  use_account_alias_prefix    = var.use_account_alias_prefix
  logging_bucket              = var.logging_bucket
  versioning_status           = var.versioning_status
  enable_bucket_force_destroy = var.force_destroy

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
# CloudFront signing keypair
# -----------------------------------------------------------------------------

resource "aws_cloudfront_public_key" "signing" {
  comment     = "${var.name_prefix} signed URL public key"
  encoded_key = var.public_key
  name        = "${var.name_prefix}-signing-key"
}

resource "aws_cloudfront_key_group" "signing" {
  comment = "${var.name_prefix} signed URL key group"
  items   = [aws_cloudfront_public_key.signing.id]
  name    = "${var.name_prefix}-signing-group"
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
  aliases             = var.aliases

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
  viewer_certificate = length(var.aliases) > 0 ? {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.minimum_protocol_version
  } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = var.minimum_protocol_version
  }

  # Logging (optional)
  logging_config = var.enable_logging && var.logging_config != null ? {
    bucket = var.logging_config.bucket
    prefix = var.logging_config.prefix
  } : {}

  # Geo restriction
  geo_restriction = {
    restriction_type = var.geo_restriction_type
    locations        = var.geo_restriction_locations
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Secrets Manager (optional)
#
# Stores the values munkisrv needs in config.yaml:
#   cloudfront.url
#   cloudfront.key_id
#   cloudfront.private_key
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "signing" {
  count = var.create_secret ? 1 : 0

  name = local.secret_name
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "signing" {
  count = var.create_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.signing[0].id
  secret_string = jsonencode({
    cloudfront_url         = "https://${module.cdn.cloudfront_distribution_domain_name}"
    cloudfront_key_id      = aws_cloudfront_public_key.signing.id
    cloudfront_private_key = var.private_key
  })
}
