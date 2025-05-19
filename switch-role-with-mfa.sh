#!/bin/bash

# ❗ Don't uncomment set -e as it will close the shell on error
# set -euo pipefail

# === Argument check ===
if [[ -z "${1:-}" ]]; then
  echo "❌ Error: Please specify the target role ARN as an argument."
  echo "         Example: source ./switch-role-with-mfa.sh arn:aws:iam::123456789012:role/your-target-role"
  echo ""
  echo "💡 Tip: It's useful to manage frequently used roles with aliases for easy reference."
  return 1
fi

AWS_ASSUME_ROLE_ARN="$1"

# === Environment variable check (don't kill terminal) ===
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

echo "🎭 Switching role: $AWS_ASSUME_ROLE_ARN..."
ASSUMED_JSON=$(aws sts assume-role \
  --role-arn "$AWS_ASSUME_ROLE_ARN" \
  --role-session-name "assumed-$(date +%s)" \
  --output json 2>&1) || {
  echo "❌ Role switch failed."
  echo "$ASSUMED_JSON"  
  return 1
}

export AWS_ACCESS_KEY_ID=$(echo "$ASSUMED_JSON" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$ASSUMED_JSON" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$ASSUMED_JSON" | jq -r '.Credentials.SessionToken')

echo ""
echo "✅ Role assumed successfully!"
echo "  AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:0:4}********"
echo "  These credentials are now active in your current shell."
echo ""