# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

A collection of shell utility scripts for development and DevOps tasks developed by CIRCLE AROUND Inc. Contains standalone bash scripts for git workflow automation, AWS MFA authentication, and database operations via bastion servers.

## Architecture and Structure

Simple flat structure with individual executable scripts in the root directory:

- **AWS Authentication Scripts** (`aws-mfa.sh`, `switch-role-with-mfa.sh`): Handle AWS CLI authentication with MFA support. Depend on `AWS_MFA_SERIAL` environment variable and use `jq` for JSON parsing.

- **Git Utilities** (`git-remove-merged-branches`, `git-wt`): Automate git workflows. `git-wt` creates worktrees in `../<repo>.worktrees/<number>` format and supports template variable substitution in configuration files.

- **Port Management** (`killport`): Handles both Docker containers and regular processes using the specified port.

- **Database Utilities** (`remote-bastion-dump`, `remote-bastion-dump-eb-pg`, `remote-cloud-sql-dump`): Execute database dumps via SSH bastion servers or Cloud SQL.

## Development Commands

As this is a collection of bash scripts without a build system:

### Testing Scripts
```bash
# Make script executable
chmod +x script-name

# Test script directly
./script-name [arguments]

# Scripts that require sourcing (aws-mfa.sh, switch-role-with-mfa.sh)
source ./aws-mfa.sh
source ./switch-role-with-mfa.sh <role-arn> [duration]
```

### Code Quality Checks
```bash
# Bash syntax check
bash -n script-name

# Lint with shellcheck (if installed)
shellcheck script-name
```

## Important Technical Details

1. **MFA Scripts**: `aws-mfa.sh` and `switch-role-with-mfa.sh` must be sourced rather than executed as they export environment variables to the current shell session. Requires `AWS_MFA_SERIAL` environment variable to be set beforehand.

2. **Error Handling**: Scripts use `set -euo pipefail` for strict error handling.

3. **Dependencies**:
   - AWS scripts: Require `aws` CLI and `jq`
   - `killport`: Requires `lsof`, optionally `docker`
   - Git scripts: Require `git`

4. **Session Duration**: Both AWS MFA scripts accept an optional duration parameter in seconds. When not specified, AWS defaults are used (12 hours for get-session-token, 1 hour for assume-role).

5. **git-wt Template System**: The `.git-wt/` directory enables worktree-specific configuration with template variable substitution. Files in this directory are copied to new worktrees with variables replaced.

   **Directory Locations (in priority order):**
   1. `<repo>/.git-wt/` - Repository-local templates
   2. `~/.git-wt/<owner>/<repo>/` - Global templates (not committed to repository)
      - Path is derived from git remote URL (e.g., `~/.git-wt/CircleAround/bin/`)

   **Supported Variables:**
   - `{{WORKTREE_NUM}}` - Worktree number (1-9)
   - `{{WORKTREE_NUM + N}}` - Arithmetic expression (supports `+`, `-`, `*`, `/`, `%`)
   - `{{BRANCH}}` - Branch name
   - `{{REPO}}` - Repository name
   - `{{WORKTREE_PATH}}` - Absolute path to worktree

   **Example Setup:**
   ```
   # Repository-local
   project/.git-wt/
       └── .env.local

   # Or global (not committed to repository)
   ~/.git-wt/acme-corp/web-app/
       └── .env.local
   ```

   **Example Template File (.git-wt/.env.local):**
   ```
   PORT={{WORKTREE_NUM + 3000}}
   DATABASE_NAME=myapp_dev_{{WORKTREE_NUM}}
   APP_URL=http://localhost:{{WORKTREE_NUM + 3000}}
   BRANCH_NAME={{BRANCH}}
   ```

   When creating worktree 1, this becomes:
   ```
   PORT=3001
   DATABASE_NAME=myapp_dev_1
   APP_URL=http://localhost:3001
   BRANCH_NAME=feature-x
   ```