#!/bin/bash

# ❗ set -e はコメントアウトしておかないとエラー時にシェルを閉じてしまう
# set -euo pipefail

# === 引数チェック ===
if [[ -z "${1:-}" ]]; then
  echo "❌ Error: スイッチ先ロールの ARN を引数で指定してください。"
  echo "         例: source ./switch-role-with-mfa.sh arn:aws:iam::123456789012:role/your-target-role"
  echo ""
  echo "💡 ヒント: よく使うロールは別名で管理するなどしてメモしておくと便利です。"
  return 1
fi

AWS_ASSUME_ROLE_ARN="$1"

# === 環境変数チェック（ターミナルを殺さない） ===
if [[ -z "${AWS_MFA_SERIAL:-}" ]]; then
  echo "❌ Error: 環境変数 AWS_MFA_SERIAL がセットされていません。"
  echo "         例: export AWS_MFA_SERIAL=\"arn:aws:iam::111122223333:mfa/your-iam-user\""
  echo "         ~/.bash_profile や ~/.zshrc に設定しておくと便利です。"
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
  echo "❌ セッショントークンの取得に失敗しました。"
  echo "$SESSION_JSON"
  return 1
}

export AWS_ACCESS_KEY_ID=$(echo "$SESSION_JSON" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$SESSION_JSON" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$SESSION_JSON" | jq -r '.Credentials.SessionToken')

echo "🎭 スイッチロール: $AWS_ASSUME_ROLE_ARN..."
ASSUMED_JSON=$(aws sts assume-role \
  --role-arn "$AWS_ASSUME_ROLE_ARN" \
  --role-session-name "assumed-$(date +%s)" \
  --output json 2>&1) || {
  echo "❌ スイッチロールに失敗しました。"
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