#!/usr/bin/env bash
# Mini Shai-Hulud 2nd Wave 感染チェック (v2: find ~ のstallを回避)
# 参考: https://blog.flatt.tech/entry/mini_shai_hulud_2nd

set -u

# プロジェクト配下を探索する開発ディレクトリ (環境変数で上書き可)
DEV_DIRS=${DEV_DIRS:-"$HOME/projects $HOME/work $HOME/dev $HOME/src $HOME/repos $HOME/ghq $HOME/code"}
# 探索深さ (節度をもって絞る)
MAX_DEPTH=${MAX_DEPTH:-6}

echo "=============================================="
echo " Mini Shai-Hulud 2nd Wave 感染チェック"
echo "=============================================="
echo "対象開発ディレクトリ: $DEV_DIRS"
echo "探索深さ上限: $MAX_DEPTH"
echo

echo "[1/7] グローバルIDEフック ~/.claude/, ~/.vscode/ の不審ファイルを確認..."
for f in \
  "$HOME/.claude/setup.mjs" \
  "$HOME/.claude/router_runtime.js" \
  "$HOME/.vscode/setup.mjs"; do
  [ -e "$f" ] && echo "  HIT: $f"
done
echo "  -> HIT行がなければOK"
echo

echo "[2/7] プロジェクト配下の .claude/.vscode フックを確認..."
for dir in $DEV_DIRS; do
  [ -d "$dir" ] || continue
  find "$dir" -maxdepth "$MAX_DEPTH" \
    \( -name node_modules -o -name .git -o -name Library -o -name Pods -o -name vendor -o -name dist -o -name build \) -prune -o \
    \( -path '*/.claude/setup.mjs' \
       -o -path '*/.claude/router_runtime.js' \
       -o -path '*/.vscode/setup.mjs' \) -print 2>/dev/null
done
echo "  -> 上に何も表示されなければOK"
echo

echo "[3/7] macOS LaunchAgent (永続化の最重要ポイント) を確認..."
ls -la "$HOME/Library/LaunchAgents/com.user.gh-token-monitor.plist" 2>/dev/null
launchctl list 2>/dev/null | grep -iE 'gh-token|tanstack'
echo "  -> 上に何も表示されなければOK"
echo

echo "[4/7] gh-token-monitor の設定/スクリプトを確認..."
find "$HOME/.config" -maxdepth 4 -name '*gh-token-monitor*' 2>/dev/null
[ -e "$HOME/.local/bin/gh-token-monitor.sh" ] && echo "  HIT: $HOME/.local/bin/gh-token-monitor.sh"
echo "  -> 上に何も表示されなければOK"
echo

echo "[5/7] ロックファイル(/tmp) を確認..."
find /tmp -maxdepth 2 -name 'tmp.ts018051808.lock' 2>/dev/null
echo "  -> 上に何も表示されなければOK"
echo

echo "[6/7] 実行中の不審プロセスを確認..."
ps aux | grep -E 'tanstack_runner|router_runtime|gh-token-monitor' | grep -v grep
echo "  -> 上に何も表示されなければOK"
echo

echo "[7/7] 不審な optionalDependencies (@tanstack/setup) の参照を確認..."
for dir in $DEV_DIRS; do
  [ -d "$dir" ] || continue
  find "$dir" -maxdepth "$MAX_DEPTH" \
    \( -name node_modules -o -name .git -o -name Library -o -name Pods -o -name vendor -o -name dist -o -name build \) -prune -o \
    \( -name 'package.json' -o -name 'package-lock.json' -o -name 'yarn.lock' -o -name 'pnpm-lock.yaml' -o -name 'bun.lock' -o -name 'bun.lockb' \) -type f -print0 2>/dev/null \
  | xargs -0 grep -l '@tanstack/setup' 2>/dev/null
done
echo "  -> 上に何も表示されなければOK"
echo

echo "=============================================="
echo " チェック完了"
echo "=============================================="
