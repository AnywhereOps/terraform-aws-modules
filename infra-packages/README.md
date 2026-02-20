# infra-packages

S3 + CloudFront module for serving Munki packages and Fleet bootstrap installers via signed URLs.

Private key material never enters Terraform state - signing keys are managed by `bin/generate-signing-key.sh` which stores them directly in AWS Secrets Manager.

## What this creates

- **S3 bucket** (via trussworks/s3-private-bucket) with encryption, versioning, TLS enforcement
- **CloudFront distribution** (via terraform-aws-modules/cloudfront) with OAC and signed URL support
- **CloudFront key group** referencing the script-created public key

## What the script creates (outside Terraform)

- **CloudFront public key** from a generated RSA keypair
- **Secrets Manager secret** containing the private key, public key ID, and expiration metadata

## S3 layout

```
bucket/
  repo/pkgs/          # Munki packages (uploaded via munkiimport or CI)
  bootstrap/          # Fleet bootstrap .pkg (uploaded via CI, referenced by Fleet MDM)
```

## Usage

### 1. Generate signing keypair

Run the script before the first `terragrunt apply`:

```bash
./bin/generate-signing-key.sh --name-prefix packages --region us-east-2

# Output:
# CLOUDFRONT_PUBLIC_KEY_ID=K2EXAMPLE
# SECRET_ARN=arn:aws:secretsmanager:us-east-2:123456789:secret:packages-cdn-signing-AbCdEf
```

The script is idempotent - if a valid (non-expired) key exists, it outputs the existing values.

### 2. Apply Terraform

Pass the script outputs as inputs:

```hcl
module "packages" {
  source = "path/to/infra-packages"

  bucket_name              = "anywhereops-packages"
  cloudfront_public_key_id = "K2EXAMPLE"
  signing_secret_arn       = "arn:aws:secretsmanager:..."
}
```

### With Terragrunt

```hcl
terraform {
  source = "git::https://github.com/AnywhereOps/terraform-aws-modules.git//infra-packages?ref=main"
}

inputs = {
  bucket_name              = "anywhereops-packages"
  cloudfront_public_key_id = "K2EXAMPLE"
  signing_secret_arn       = "arn:aws:secretsmanager:..."
}
```

### With custom domain

```hcl
inputs = {
  bucket_name              = "anywhereops-packages"
  cloudfront_public_key_id = "K2EXAMPLE"
  signing_secret_arn       = "arn:aws:secretsmanager:..."

  aliases             = ["packages.anywhereops.ai"]
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/abc123"
}
```

## Key rotation

```bash
# Force regeneration (creates new key, updates secret)
./bin/generate-signing-key.sh --force

# Update Terraform with new public key ID
# Then apply to update the key group + distribution
```

## Wiring into munkisrv

munkisrv reads the signing config from Secrets Manager at startup:

```yaml
cloudfront:
  url: "https://dxxxxxxx.cloudfront.net"   # from module output cloudfront_url
  key_id: "K2EXAMPLE"                       # from secret: cloudfront_public_key_id
  private_key: |                            # from secret: private_key
    -----BEGIN PRIVATE KEY-----
    ...
```

## Wiring into Fleet

Upload the bootstrap package to `s3://bucket/bootstrap/` and configure Fleet's
`FLEET_S3_SOFTWARE_INSTALLERS_BUCKET` and `FLEET_S3_SOFTWARE_INSTALLERS_PREFIX`
environment variables.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | S3 bucket name | string | | yes |
| cloudfront_public_key_id | CF public key ID from generate-signing-key.sh | string | | yes |
| signing_secret_arn | Secrets Manager ARN from generate-signing-key.sh | string | | yes |
| name_prefix | Prefix for resource names | string | "packages" | no |
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

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | S3 bucket name |
| bucket_arn | S3 bucket ARN |
| bucket_regional_domain_name | S3 bucket regional domain |
| cloudfront_distribution_id | CF distribution ID |
| cloudfront_distribution_arn | CF distribution ARN |
| cloudfront_distribution_domain_name | CF domain name |
| cloudfront_url | Full HTTPS URL |
| cloudfront_key_group_id | Key group ID |
| signing_secret_arn | Secrets Manager secret ARN (passthrough) |
