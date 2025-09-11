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

## docker-clean
Remove unused Docker images

## git-wt
Manage Git worktrees with sequential numbering in `../<repo>.worktrees/<number>` directories.

```bash
# Create worktree with branch
git-wt add feature-branch

# Remove highest numbered worktree
git-wt pop

# Remove specific worktree by number
git-wt pop 2

# Show interactive menu
git-wt
```

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