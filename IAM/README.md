1. What is AWS IAM?

AWS IAM (Identity and Access Management) is a service that helps you securely control access to AWS resources.

It allows you to:

Create users who can log in or access AWS services.

Create groups to organize users.

Assign permissions using policies to users, groups, or roles.

Use roles for temporary access or cross-service access.

Think of it as the key and lock system for your AWS account: you decide who can access what and what actions they can perform.

2. IAM Components
a) Users

Represent individuals or services.

Can log in to AWS Console or access AWS via CLI/SDK.

Example: developer1, admin1, auditor1.

b) Groups

A collection of users.

Makes it easier to manage permissions.

Example groups: Developers, Admins, Auditors.

c) Policies

JSON documents that define permissions.

Two main types:

Managed Policies: Predefined by AWS (e.g., AdministratorAccess).

Inline Policies: Custom policies attached to a user, group, or role.

Example: allow Developers to start/stop EC2 instances.

d) Roles

Temporary permissions that can be assumed by users, applications, or services.

Example: An EC2 instance needs access to S3, it assumes a role with S3 permissions.