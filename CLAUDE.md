# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

CIRCLE AROUND Inc.が開発した、開発・DevOpsタスク用のシェルユーティリティスクリプト集です。Docker操作、gitワークフロー自動化、AWS MFA認証、踏み台サーバー経由のデータベース操作などを行う独立したbashスクリプトが含まれています。

## アーキテクチャと構造

ルートディレクトリに個別の実行可能スクリプトを配置したシンプルなフラット構造：

- **AWS認証スクリプト** (`aws-mfa.sh`, `switch-role-with-mfa.sh`): MFAサポート付きのAWS CLI認証を処理。`AWS_MFA_SERIAL`環境変数に依存し、JSON解析に`jq`を使用。

- **Gitユーティリティ** (`git-remove-merged-branches`, `git-wt`): gitワークフローを自動化。`git-wt`は`../<repo>.worktrees/<branch>`形式でworktreeを作成。

- **Dockerユーティリティ** (`docker-clean`, `killport`): Dockerリソースを管理。`killport`は指定ポートを使用するDockerコンテナと通常プロセスの両方を処理。

- **データベースユーティリティ** (`remote-bastion-dump`, `remote-bastion-dump-eb-pg`, `remote-cloud-sql-dump`): SSH踏み台サーバーやCloud SQL経由でのデータベースダンプを実行。

## 開発コマンド

ビルドシステムのないbashスクリプト集のため：

### スクリプトのテスト
```bash
# スクリプトを実行可能にする
chmod +x script-name

# スクリプトを直接テスト
./script-name [引数]

# sourceが必要なスクリプト (aws-mfa.sh, switch-role-with-mfa.sh)
source ./aws-mfa.sh
source ./switch-role-with-mfa.sh <role-arn> [duration]
```

### コード品質チェック
```bash
# bash構文チェック
bash -n script-name

# shellcheckでリント（インストール済みの場合）
shellcheck script-name
```

## 重要な技術詳細

1. **MFAスクリプト**: `aws-mfa.sh`と`switch-role-with-mfa.sh`は現在のシェルセッションに環境変数をエクスポートするため、実行ではなくsourceする必要がある。`AWS_MFA_SERIAL`環境変数の事前設定が必要。

2. **エラーハンドリング**: スクリプトは厳密なエラー処理のため`set -euo pipefail`を使用。

3. **依存関係**: 
   - AWSスクリプト: `aws` CLIと`jq`が必要
   - `killport`: `lsof`が必要、オプションで`docker`
   - Gitスクリプト: `git`が必要

4. **セッション期間**: AWS MFAスクリプトはデフォルトで36時間（129600秒）のセッション期間を使用。switch-roleスクリプトはオプションでduration引数を受け付ける。