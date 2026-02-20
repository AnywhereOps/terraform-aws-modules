# munkisrv-cdn

S3 + CloudFront module for serving Munki packages and Fleet bootstrap installers via signed URLs.

## What this creates

- **S3 bucket** (via trussworks/s3-private-bucket) with encryption, versioning, TLS enforcement
- **CloudFront distribution** (via terraform-aws-modules/cloudfront) with OAC and signed URL support
- **Signing keypair** (CloudFront public key + key group)
- **Secrets Manager secret** (optional) containing the CloudFront URL, key ID, and private key

## S3 layout

```
bucket/
  repo/pkgs/          # Munki packages (uploaded via munkiimport or CI)
  bootstrap/          # Fleet bootstrap .pkg (uploaded via CI, referenced by Fleet MDM)
```

## Usage

### Generate signing keypair

```bash
openssl genrsa -out cloudfront.key 2048
openssl rsa -pubout -in cloudfront.key -out cloudfront.pem
```

### Basic module call

```hcl
module "munkisrv_cdn" {
  source = "path/to/munkisrv-cdn"

  bucket_name = "cmh-munkisrv-packages"
  name_prefix = "munkisrv"

  public_key  = file("${path.module}/keys/cloudfront.pem")
  private_key = file("${path.module}/keys/cloudfront.key")

  tags = {
    Environment = "production"
    Service     = "munkisrv"
  }
}
```

### With custom domain

```hcl
module "munkisrv_cdn" {
  source = "path/to/munkisrv-cdn"

  bucket_name = "cmh-munkisrv-packages"
  name_prefix = "munkisrv"

  public_key  = file("${path.module}/keys/cloudfront.pem")
  private_key = file("${path.module}/keys/cloudfront.key")

  aliases             = ["packages.example.com"]
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"

  tags = {
    Environment = "production"
    Service     = "munkisrv"
  }
}
```

### With Terragrunt

```hcl
# infra-live/prod/us-east-2/munkisrv-cdn/terragrunt.hcl

terraform {
  source = "path/to/munkisrv-cdn"
}

inputs = {
  bucket_name = "cmh-munkisrv-packages"
  name_prefix = "munkisrv"

  public_key  = file("keys/cloudfront.pem")
  private_key = file("keys/cloudfront.key")
}
```

## Wiring into munkisrv

The module outputs everything munkisrv needs for `config.yaml`:

```yaml
cloudfront:
  url: "${module.munkisrv_cdn.cloudfront_url}"
  key_id: "${module.munkisrv_cdn.cloudfront_key_id}"
  private_key: |
    ... # retrieve from Secrets Manager at runtime
```

Or pull all three values from the Secrets Manager secret at container startup.

## Wiring into Fleet

For the bootstrap package, upload to `s3://bucket/bootstrap/munki-tools.pkg` and
configure Fleet's MDM bootstrap URL to point at a signed CloudFront URL for that
object. The signing is handled by munkisrv (or a small Lambda if you want Fleet
to generate URLs independently).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | S3 bucket name | string | | yes |
| public_key | PEM public key for CF signed URLs | string | | yes |
| private_key | PEM private key for CF signed URLs | string | | yes |
| name_prefix | Prefix for resource names | string | "munkisrv" | no |
| tags | Tags for all resources | map(string) | {} | no |
| use_account_alias_prefix | Prefix bucket with AWS account alias | bool | false | no |
| logging_bucket | S3 bucket for access logs | string | "" | no |
| force_destroy | Allow destroying bucket with objects | bool | false | no |
| versioning_status | Bucket versioning: Enabled/Disabled/Suspended | string | "Enabled" | no |
| price_class | CF price class | string | "PriceClass_100" | no |
| aliases | Custom domain names for CF | list(string) | [] | no |
| acm_certificate_arn | ACM cert for custom domains | string | null | no |
| minimum_protocol_version | Min TLS version | string | "TLSv1.2_2021" | no |
| enable_logging | Enable CF access logging | bool | false | no |
| logging_config | CF logging config (bucket + prefix) | object | null | no |
| geo_restriction_type | Geo restriction: none/whitelist/blacklist | string | "none" | no |
| geo_restriction_locations | Country codes for geo restriction | list(string) | [] | no |
| create_secret | Store signing config in Secrets Manager | bool | true | no |
| secret_name | Secrets Manager secret name | string | "" (auto) | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | S3 bucket name |
| bucket_arn | S3 bucket ARN |
| cloudfront_distribution_id | CF distribution ID |
| cloudfront_distribution_arn | CF distribution ARN |
| cloudfront_url | Full HTTPS URL for munkisrv config.yaml |
| cloudfront_key_id | Public key ID for munkisrv config.yaml |
| cloudfront_key_group_id | Key group ID |
| secret_arn | Secrets Manager secret ARN |
| munkisrv_config | Map of config.yaml cloudfront section values |
