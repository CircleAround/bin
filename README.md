# bin

Utility commands by CIRCLE AROUND Inc.

## Installation

Add this directory to your PATH for easy access to all utilities:

```bash
# Add to ~/.bashrc, ~/.zshrc, or your shell's configuration file
export PATH="$PATH:$HOME/CircleAround/bin"
```

After adding the PATH, reload your shell configuration:

```bash
source ~/.bashrc  # or ~/.zshrc
```

## git-wt
Manage Git worktrees with sequential numbering in `../<repo>.worktrees/<number>` directories.

```bash
# Create worktree with branch
git-wt add feature-branch

# Remove highest numbered worktree
git-wt pop

# Remove specific worktree by number
git-wt pop 2

# Copy cd command to clipboard (macOS)
git-wt goto 0   # Main repository
git-wt goto 1   # Worktree 1

# Show interactive menu
git-wt
```

### Interactive Menu
The interactive menu provides quick navigation:
- `0-9`: Copy cd command to clipboard for main repo (0) or worktrees (1-9)
- `a`: Add new worktree
- `p`: Pop (remove) highest numbered worktree
- `h`: Show help
- `q`: Quit

### File Copy Configuration
Create a `.git-wt.conf` file in your repository root to automatically copy specific files and directories from the main branch to new worktrees:

```
# .git-wt.conf
.env
.env.local
config/secrets.yml
data
# Comments are supported
```

Files and directories listed in this configuration will be copied from the main branch to each new worktree, preserving directory structure. Missing files/directories are skipped with a warning message.

## git-wt-sync
Sync files from main repository to current worktree based on `.git-wt.conf`.

This command is useful when you create a worktree manually (not via `git-wt add`) and want to copy configured files afterward.

```bash
# From within a worktree directory
cd ../myrepo.worktrees/1
git-wt-sync
```

The command reads `.git-wt.conf` from the current worktree and copies the listed files/directories from the main repository.

## git-remove-merged-branches
Remove merged branches in current git directory.

## killport
Kill process (or Docker container) by port number.

Kill process using port 3000:

```
killport 3000
```

## remote-bastion-dump
Call mysqldump through bastion server

```
remote-bastion-dump ssh-bastion-host-name db-host db-user db-pass db-name
```

## aws-mfa.sh
MFA authentication for AWS CLI.

Set AWS_MFA_SERIAL in your environment as your MFA Device (e.g., in ~/.bash_profile or ~/.zshrc):

```
export AWS_MFA_SERIAL=arn:aws:iam::111122223333:mfa/your-iam-user
source aws-mfa.sh [duration-seconds]
```

If duration-seconds is not specified, AWS default (12 hours) will be used.

## switch-role-with-mfa.sh
Switch AWS role with MFA.

Set AWS_MFA_SERIAL in your environment as your MFA Device (e.g., in ~/.bash_profile or ~/.zshrc):

```
export AWS_MFA_SERIAL=arn:aws:iam::111122223333:mfa/your-iam-user
source switch-role-with-mfa.sh arn:aws:iam::123456789012:role/your-target-role
```