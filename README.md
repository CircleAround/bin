# bin

Utility commands by CIRCLE AROUND Inc.

## docker-clean
remove unused docker images

## git-remove-merged-branches
for remove merged branches on current git directory.

## killport
kill process (or Docker container) by attaching portnumber.

kill process of using port of 3000.

```
killport 3000
```

## remote-bastion-dump
call mysqldump through bastion server

```
remote-bastion-dump ssh-bastion-host-name db-host db-user db-pass db-name
```

## switch-role-with-mfa.sh
switch role with MFA.

set AWS_MFA_SERIAL in your environment as your MFA Device.

```
export AWS_MFA_SERIAL=arn:aws:iam::111122223333:mfa/your-iam-user
source switch-role-with-mfa.sh arn:aws:iam::123456789012:role/your-target-role
```