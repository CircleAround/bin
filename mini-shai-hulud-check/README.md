# mini-shai-hulud-check

npm 供給網攻撃キャンペーン **Mini Shai-Hulud 2nd Wave** の感染チェックスクリプト集です。

参考: <https://blog.flatt.tech/entry/mini_shai_hulud_2nd>

## 構成

| ファイル | 役割 |
|---|---|
| `check_mini_shai_hulud.sh` | ローカルマシンの感染チェック |
| `check_git_mini_shai_hulud.sh` | GitHub Org/User 配下のリポジトリ汚染チェック |
| `orgs.txt.sample` | Org一覧のサンプル (`check_git_mini_shai_hulud.sh -f` で使用) |

## 必要なもの

- bash, find, ps, grep, jq
- (Org側スキャンを使う場合のみ) `gh` CLI が `gh auth login` 済みであること
  - 必要スコープ: `repo`, `read:org`

## 使い方

### 1. ローカルマシンの感染チェック

```bash
./check_mini_shai_hulud.sh
```

以下7項目を順にチェックします:

1. グローバルIDEフック (`~/.claude/setup.mjs`, `~/.claude/router_runtime.js`, `~/.vscode/setup.mjs`)
2. プロジェクト配下の `.claude/`, `.vscode/` フック
3. macOS LaunchAgent (`~/Library/LaunchAgents/com.user.gh-token-monitor.plist`)
4. `gh-token-monitor` の設定/スクリプト
5. ロックファイル (`/tmp/tmp.ts018051808.lock`)
6. 実行中の不審プロセス (`tanstack_runner`, `router_runtime`, `gh-token-monitor`)
7. `@tanstack/setup` への依存 (`package.json` / lockfile)

各段階の最後に `-> 上に何も表示されなければOK` が出ます。HIT行が出なければシロと判定できます。

#### オプション (環境変数)

| 変数 | デフォルト | 用途 |
|---|---|---|
| `DEV_DIRS` | `~/projects ~/work ~/dev ~/src ~/repos ~/ghq ~/code` | プロジェクト探索対象 |
| `MAX_DEPTH` | `6` | `find` の深さ上限 |

例:

```bash
DEV_DIRS="$HOME/my-workspace $HOME/oss" MAX_DEPTH=8 ./check_mini_shai_hulud.sh
```

### 2. GitHub Org/User 配下のスキャン

```bash
cp orgs.txt.sample orgs.txt
$EDITOR orgs.txt   # 対象の Org名 / ユーザー名を 1 行 1 件で記入

./check_git_mini_shai_hulud.sh -f orgs.txt
```

または引数で直接指定:

```bash
./check_git_mini_shai_hulud.sh my-org another-org my-username
```

各 Org について以下を実行します:

- **[A]** description が `"A Mini Shai-Hulud has Appeared"` のリポジトリ
- **[B]** `xxx-xxx-NNN` 風 (dune_word風) のリポジトリ命名候補
- **[C]** `claude@users.noreply.github.com` 著者によるコミット
- **[D]** `.github/workflows/codeql_analysis.yml` の最近の改変

#### オプション

| オプション | デフォルト | 用途 |
|---|---|---|
| `-f <file>` | (なし) | Org名一覧ファイル |
| `--since <date>` | `2026-04-01` | この日付以降のコミット/リポジトリだけ対象 |
| `-h` | - | ヘルプ |

例:

```bash
./check_git_mini_shai_hulud.sh --since 2026-03-01 -f orgs.txt
```

## 結果の読み方

- `HIT:` 行が出た場合 → 即座に内容を確認し、対象リポジトリの secrets ローテーション・該当コミットの revert を検討
- `CANDIDATE:` (命名パターン[B]) → 偽陽性あり。`createdAt` や中身を必ず手動確認
- `REVIEW:` ([D]) → 通常運用での codeql workflow 更新もここに出るので、著者と内容を確認

## 注意

- `orgs.txt` は社内 Org 名等を含む可能性があるため、`.gitignore` 対象にしてください
- `[B]` の命名パターンは正規リポジトリも引っかかります (`some-cool-name-001` のような)
- 大規模 Org では API 呼び出し回数が増えます。GitHub API の rate limit (5000/h) に注意
- 開発機が iCloud Drive 等を使っている場合は `DEV_DIRS` を明示指定して `~/Library/Mobile Documents` を踏まないようにしてください

## IoC リファレンス

| 種別 | 値 |
|---|---|
| 永続化(macOS) | `~/Library/LaunchAgents/com.user.gh-token-monitor.plist` |
| 永続化(Linux) | `~/.config/systemd/user/gh-token-monitor.service` |
| IDEフック | `.claude/setup.mjs`, `.claude/router_runtime.js`, `.vscode/setup.mjs` |
| CI/CD注入 | `.github/workflows/codeql_analysis.yml` |
| プロセス名 | `tanstack_runner`, `router_runtime`, `gh-token-monitor`, `bun` |
| C2ドメイン | `git-tanstack.com`, `api.masscan.cloud`, `filev2.getsession.org` |
| 不審著者 | `claude <claude@users.noreply.github.com>` |
| 不審Description | `"A Mini Shai-Hulud has Appeared"` |
| npmパッケージ | `optionalDependencies` 内 `@tanstack/setup` |
