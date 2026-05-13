#!/usr/bin/env bash
# Mini Shai-Hulud 2nd Wave - GitHub Org/Team リポジトリ汚染チェック
#
# 使い方:
#   ./check_git_mini_shai_hulud.sh org1 org2 ...
#   ./check_git_mini_shai_hulud.sh -f orgs.txt          # ファイルから読み込み
#   ./check_git_mini_shai_hulud.sh --since 2026-04-01 org1
#
# 事前要件: gh CLI に認証済み (gh auth status)

set -u

SUSPICIOUS_AUTHOR_EMAIL="claude@users.noreply.github.com"
SUSPICIOUS_DESC="A Mini Shai-Hulud has Appeared"
SINCE="2026-04-01"   # 攻撃が観測されている時期に合わせて調整
PER_PAGE=100

usage() {
  cat <<EOF
Usage: $0 [options] <org1> [org2 ...]
  -f <file>     Org名を1行1件で書いたファイルから読み込み
  --since DATE  この日付以降のコミットだけを対象 (default: $SINCE)
  -h            このヘルプ
EOF
}

ORGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -f)        shift; while IFS= read -r line; do
                 [ -n "$line" ] && [[ "$line" != \#* ]] && ORGS+=("$line")
               done < "$1"; shift ;;
    --since)   shift; SINCE="$1"; shift ;;
    *)         ORGS+=("$1"); shift ;;
  esac
done

if [ "${#ORGS[@]}" -eq 0 ]; then
  echo "ERROR: Org名を1つ以上指定してください" >&2
  usage
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI が必要です" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq が必要です" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh auth login が必要です" >&2
  exit 1
fi

echo "=============================================="
echo " Mini Shai-Hulud 2nd Wave - Org/Team スキャン"
echo "=============================================="
echo "対象Org: ${ORGS[*]}"
echo "対象期間: since=$SINCE"
echo "不審著者: $SUSPICIOUS_AUTHOR_EMAIL"
echo

HIT_TOTAL=0

for org in "${ORGS[@]}"; do
  echo "########## ORG: $org ##########"
  echo

  # ---- [A] 不審なリポジトリ名/Descriptionの検出 ----
  echo "[A] '$SUSPICIOUS_DESC' のDescriptionを持つリポジトリを検索..."
  gh repo list "$org" --limit 1000 --json nameWithOwner,description,createdAt 2>/dev/null \
    | jq -r --arg d "$SUSPICIOUS_DESC" \
        '.[] | select(.description == $d) | "  HIT: \(.nameWithOwner)  created=\(.createdAt)"'
  echo

  echo "[B] dune_word風の不審な命名パターン (xxx-xxx-NNN) のリポジトリを検出..."
  gh repo list "$org" --limit 1000 --json nameWithOwner,createdAt 2>/dev/null \
    | jq -r '.[] | select(.nameWithOwner | test("/[a-z]+-[a-z]+-[0-9]{3}$")) | "  CANDIDATE: \(.nameWithOwner)  created=\(.createdAt)"'
  echo "  (注: 偽陽性あり。createdAtや内容を必ず手動確認)"
  echo

  # ---- [C] 各リポジトリでの不審著者コミット ----
  echo "[C] 各リポジトリで '$SUSPICIOUS_AUTHOR_EMAIL' によるコミットを検索..."
  repos=$(gh repo list "$org" --limit 1000 --json nameWithOwner -q '.[].nameWithOwner' 2>/dev/null)
  repo_count=$(echo "$repos" | wc -l | tr -d ' ')
  echo "  対象リポジトリ数: $repo_count"
  echo

  while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    # author に email を渡すと GitHub 側で絞り込んでくれる
    result=$(gh api \
      "repos/$repo/commits?author=$SUSPICIOUS_AUTHOR_EMAIL&since=${SINCE}T00:00:00Z&per_page=$PER_PAGE" \
      2>/dev/null \
      | jq -r 'if type=="array" then .[] | "    \(.sha[0:7]) \(.commit.author.date) \(.commit.author.name // "?") <\(.commit.author.email // "?")> \(.commit.message | split("\n")[0])" else empty end')
    if [ -n "$result" ]; then
      HIT_TOTAL=$((HIT_TOTAL + 1))
      echo "  HIT: $repo"
      echo "$result"
      echo
    fi
  done <<< "$repos"

  # ---- [D] codeql_analysis.yml の最近の改変 ----
  echo "[D] .github/workflows/codeql_analysis.yml の最近のコミットを検索..."
  while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    result=$(gh api \
      "repos/$repo/commits?path=.github/workflows/codeql_analysis.yml&since=${SINCE}T00:00:00Z&per_page=20" \
      2>/dev/null \
      | jq -r 'if type=="array" then .[] | "    \(.sha[0:7]) \(.commit.author.date) \(.commit.author.name // "?") <\(.commit.author.email // "?")> \(.commit.message | split("\n")[0])" else empty end')
    if [ -n "$result" ]; then
      echo "  REVIEW: $repo"
      echo "$result"
      echo
    fi
  done <<< "$repos"

  echo
done

echo "=============================================="
echo " スキャン完了"
echo " 著者一致のHIT合計: $HIT_TOTAL"
echo "=============================================="
echo
echo "次の手順:"
echo "  1. HITしたコミットは即座にrevert検討"
echo "  2. 該当リポジトリの secrets を全てローテーション"
echo "  3. 不審リポジトリは作成者/作成時刻を Audit Log と突き合わせ"
