#!/bin/bash

# === Environment variable check ===
if [[ -z "${AWS_MFA_SERIAL:-}" ]]; then
  echo "❌ Error: Environment variable AWS_MFA_SERIAL is not set."
  echo "         Example: export AWS_MFA_SERIAL=\"arn:aws:iam::111122223333:mfa/your-iam-user\""
  echo "         It's convenient to set this in your ~/.bash_profile or ~/.zshrc."
  return 1
fi

AWS_SOURCE_PROFILE="${AWS_SOURCE_PROFILE:-${AWS_PROFILE:-default}}"
echo "🔑 Using source profile: $AWS_SOURCE_PROFILE"

read -p "Enter MFA code (6 digits): " MFA_CODE

echo "🔐 Getting session token using MFA..."
SESSION_JSON=$(aws sts get-session-token \
  --serial-number "$AWS_MFA_SERIAL" \
  --token-code "$MFA_CODE" \
  --profile "$AWS_SOURCE_PROFILE" \
  --duration-seconds 129600 \
  --output json 2>&1) || {
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
