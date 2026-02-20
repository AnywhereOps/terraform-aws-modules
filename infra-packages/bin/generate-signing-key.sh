#!/usr/bin/env bash
#
# Generates an RSA keypair for CloudFront signed URLs.
#   - Creates a CloudFront public key
#   - Stores private key + metadata in Secrets Manager
#   - Outputs the CloudFront public key ID and secret ARN
#
# If a valid (non-expired) secret already exists, this is a no-op
# unless --force is passed.
#
# Usage:
#   generate-signing-key.sh [--name-prefix NAME] [--region REGION] [--ttl-days DAYS] [--force]
#
set -euo pipefail

NAME_PREFIX="packages"
REGION="${AWS_REGION:-us-east-2}"
TTL_DAYS=365
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name-prefix) NAME_PREFIX="$2"; shift 2 ;;
    --region)      REGION="$2"; shift 2 ;;
    --ttl-days)    TTL_DAYS="$2"; shift 2 ;;
    --force)       FORCE=true; shift ;;
    *)             echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

SECRET_NAME="${NAME_PREFIX}-cdn-signing"
CF_KEY_NAME="${NAME_PREFIX}-signing-key"
now_epoch=$(date +%s)

# ---------------------------------------------------------------------------
# Check if secret exists and is still valid
# ---------------------------------------------------------------------------
if aws secretsmanager describe-secret \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --output json >/dev/null 2>&1; then

  if [[ "$FORCE" == "false" ]]; then
    existing=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_NAME" \
      --region "$REGION" \
      --query 'SecretString' \
      --output text 2>/dev/null || echo "")

    if [[ -n "$existing" ]]; then
      expires_at=$(echo "$existing" | python3 -c "import sys,json; print(json.load(sys.stdin).get('expires_at',''))" 2>/dev/null || echo "")

      if [[ -n "$expires_at" ]]; then
        expires_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null || \
                        date -d "$expires_at" +%s 2>/dev/null || echo "0")

        if [[ "$expires_epoch" -gt "$now_epoch" ]]; then
          # Still valid - output existing values
          cf_public_key_id=$(echo "$existing" | python3 -c "import sys,json; print(json.load(sys.stdin)['cloudfront_public_key_id'])")
          secret_arn=$(aws secretsmanager describe-secret \
            --secret-id "$SECRET_NAME" \
            --region "$REGION" \
            --query 'ARN' \
            --output text)

          echo "Secret '$SECRET_NAME' is valid until $expires_at. Use --force to regenerate." >&2
          echo ""
          echo "CLOUDFRONT_PUBLIC_KEY_ID=$cf_public_key_id"
          echo "SECRET_ARN=$secret_arn"
          exit 0
        fi
        echo "Secret '$SECRET_NAME' has expired ($expires_at). Regenerating..." >&2
      fi
    fi
  else
    echo "Force flag set. Regenerating keypair..." >&2
  fi

  secret_exists=true
else
  echo "Secret '$SECRET_NAME' not found. Creating..." >&2
  secret_exists=false
fi

# ---------------------------------------------------------------------------
# Generate RSA keypair
# ---------------------------------------------------------------------------
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

openssl genrsa -out "$tmpdir/private.pem" 2048 2>/dev/null
openssl rsa -in "$tmpdir/private.pem" -pubout -out "$tmpdir/public.pem" 2>/dev/null

private_key=$(cat "$tmpdir/private.pem")
public_key=$(cat "$tmpdir/public.pem")

# ---------------------------------------------------------------------------
# Create CloudFront public key
# ---------------------------------------------------------------------------

# Delete old CF public key if it exists (must not be in a key group)
old_key_id=$(aws cloudfront list-public-keys \
  --region "$REGION" \
  --query "PublicKeyList.Items[?Comment=='${NAME_PREFIX} signed URL public key'].Id" \
  --output text 2>/dev/null || echo "")

cf_result=$(aws cloudfront create-public-key \
  --region "$REGION" \
  --public-key-config "{
    \"CallerReference\": \"${NAME_PREFIX}-$(date +%s)\",
    \"Name\": \"${CF_KEY_NAME}\",
    \"EncodedKey\": $(python3 -c "import json; print(json.dumps(open('$tmpdir/public.pem').read()))"),
    \"Comment\": \"${NAME_PREFIX} signed URL public key\"
  }" \
  --output json)

cf_public_key_id=$(echo "$cf_result" | python3 -c "import sys,json; print(json.load(sys.stdin)['PublicKey']['Id'])")
echo "Created CloudFront public key: $cf_public_key_id" >&2

# ---------------------------------------------------------------------------
# Store private key + metadata in Secrets Manager
# ---------------------------------------------------------------------------
created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
expires_at=$(date -u -v+"${TTL_DAYS}d" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
             date -u -d "+${TTL_DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")

secret_json=$(python3 -c "
import json, sys
print(json.dumps({
    'cloudfront_public_key_id': sys.argv[1],
    'private_key': sys.argv[2],
    'created_at': sys.argv[3],
    'expires_at': sys.argv[4]
}))
" "$cf_public_key_id" "$private_key" "$created_at" "$expires_at")

if [[ "$secret_exists" == "true" ]]; then
  aws secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" \
    --secret-string "$secret_json" \
    --region "$REGION" >/dev/null
  echo "Updated secret '$SECRET_NAME'." >&2
else
  aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --secret-string "$secret_json" \
    --region "$REGION" >/dev/null
  echo "Created secret '$SECRET_NAME'." >&2
fi

secret_arn=$(aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
  --query 'ARN' \
  --output text)

echo "Keypair valid until $expires_at." >&2
echo ""
echo "CLOUDFRONT_PUBLIC_KEY_ID=$cf_public_key_id"
echo "SECRET_ARN=$secret_arn"
