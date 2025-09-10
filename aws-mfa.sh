#!/bin/bash

# === Environment variable check ===
if [[ -z "${AWS_MFA_SERIAL:-}" ]]; then
  echo "❌ Error: Environment variable AWS_MFA_SERIAL is not set."
  echo "         Example: export AWS_MFA_SERIAL=\"arn:aws:iam::111122223333:mfa/your-iam-user\""
  echo "         It's convenient to set this in your ~/.bash_profile or ~/.zshrc."
  return 1
fi

# Duration parameter (optional)
DURATION_SECONDS="${1:-}"

AWS_SOURCE_PROFILE="${AWS_SOURCE_PROFILE:-${AWS_PROFILE:-default}}"
echo "🔑 Using source profile: $AWS_SOURCE_PROFILE"

read -p "Enter MFA code (6 digits): " MFA_CODE

echo "🔐 Getting session token using MFA..."

# Build command
STS_CMD="aws sts get-session-token \
  --serial-number \"$AWS_MFA_SERIAL\" \
  --token-code \"$MFA_CODE\" \
  --profile \"$AWS_SOURCE_PROFILE\""

# Add duration only if specified
if [[ -n "$DURATION_SECONDS" ]]; then
  STS_CMD="$STS_CMD --duration-seconds $DURATION_SECONDS"
  echo "⏱️  Using custom duration: ${DURATION_SECONDS} seconds"
fi

STS_CMD="$STS_CMD --output json 2>&1"

SESSION_JSON=$(eval "$STS_CMD") || {
  echo "❌ Failed to get session token."
  echo "$SESSION_JSON"
  return 1
}

export AWS_ACCESS_KEY_ID=$(echo "$SESSION_JSON" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$SESSION_JSON" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$SESSION_JSON" | jq -r '.Credentials.SessionToken')

echo ""
echo "✅ MFA successfully!"
echo "  AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:0:4}********"
echo "  These credentials are now active in your current shell."
echo ""
