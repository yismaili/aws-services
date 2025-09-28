 # create groups

aws iam create-group --group-name Developers
aws iam create-group --group-name Admins
aws iam create-group --group-name Auditors


# custom inline policy for Developers

aws iam put-group-policy \
  --group-name Developers \
  --policy-name DevelopersEC2Policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["ec2:StartInstances","ec2:StopInstances","ec2:DescribeInstances"],
      "Resource": "*"
    }]
  }'

# custom inline policy for Admins

aws iam attach-group-policy \
  --group-name Admins \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# custom inline policy for Auditors

aws iam put-group-policy \
  --group-name Auditors \
  --policy-name AuditorsLogsPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["logs:DescribeLogGroups","logs:DescribeLogStreams","logs:GetLogEvents","logs:FilterLogEvents"],
      "Resource": "*"
    }]
  }'

# create users and add to groups

aws iam create-user --user-name developer1
aws iam add-user-to-group --user-name developer1 --group-name Developers

aws iam create-user --user-name admin1
aws iam add-user-to-group --user-name admin1 --group-name Admins

aws iam create-user --user-name auditor1
aws iam add-user-to-group --user-name auditor1 --group-name Auditors

# List all IAM users

aws iam list-users

#List all IAM groups

aws iam list-groups

# List users in a specific group

aws iam get-group --group-name Developers
aws iam get-group --group-name Admins
aws iam get-group --group-name Auditors



#List policies attached to a group

aws iam list-attached-group-policies --group-name Developers
aws iam list-attached-group-policies --group-name Admins
aws iam list-attached-group-policies --group-name Auditors


#List all IAM roles

aws iam list-roles

#List all IAM policies  
aws iam list-policies --scope Local
aws iam list-policies --scope AWS

# Remove users from groups

aws iam remove-user-from-group --user-name developer1 --group-name Developers
aws iam remove-user-from-group --user-name admin1 --group-name Admins
aws iam remove-user-from-group --user-name auditor1 --group-name Auditors


#Delete inline policies from groups

aws iam delete-group-policy --group-name Developers --policy-name DevelopersEC2Policy
aws iam delete-group-policy --group-name Auditors --policy-name AuditorsLogsPolicy

#Detach managed policies from groups

aws iam detach-group-policy --group-name Admins --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Delete users

aws iam delete-user --user-name developer1
aws iam delete-user --user-name admin1
aws iam delete-user --user-name auditor1


# Delete groups aws iam delete-group --group-name Developers
aws iam delete-group --group-name Admins
aws iam delete-group --group-name Auditors
