# =============================================================================
# S3 Bucket for Package Storage
#
# Layout:
#   repo/pkgs/     Munki packages (munkiimport -> S3, munkisrv serves via CF)
#   bootstrap/     Fleet bootstrap pkg (CI -> S3, Fleet references signed URL)
#
# CloudFront is handled by infra-cloudfront module (separate deployment)
# =============================================================================

module "packages" {
  source  = "trussworks/s3-private-bucket/aws"
  version = "~> 9.0"

  bucket                      = var.bucket_name
  use_account_alias_prefix    = false
  logging_bucket              = ""
  versioning_status           = "Enabled"
  enable_bucket_force_destroy = false

  tags = var.tags
}
