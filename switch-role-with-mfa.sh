#!/bin/bash

if [[ -z "${1:-}" ]]; then
  echo "❌ Error: Please specify the target role ARN as an argument."
  return 1
fi

AWS_ASSUME_ROLE_ARN="$1"

if [[ -z "${AWS_MFA_SERIAL:-}" ]]; then
  echo "❌ Error: Environment variable AWS_MFA_SERIAL is not set."
  return 1
fi

AWS_SOURCE_PROFILE="${AWS_SOURCE_PROFILE:-${AWS_PROFILE:-default}}"
echo "🔑 Using source profile: $AWS_SOURCE_PROFILE"

read -p "Enter MFA code (6 digits): " MFA_CODE

echo "🎭 Switching role with MFA: $AWS_ASSUME_ROLE_ARN..."
ASSUMED_JSON=$(aws sts assume-role \
  --role-arn "$AWS_ASSUME_ROLE_ARN" \
  --role-session-name "assumed-$(date +%s)" \
  --serial-number "$AWS_MFA_SERIAL" \
  --token-code "$MFA_CODE" \
  --profile "$AWS_SOURCE_PROFILE" \
  --duration-seconds 14400 \
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
echo ""
