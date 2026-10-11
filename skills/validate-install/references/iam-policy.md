# Least-privilege IAM policy for /validate-install

Run the skill as a dedicated IAM user or role that holds only this policy. Do not run it with
an administrator key. The policy below allows launching and deleting resources, so keep the
key out of shared machines and rotate it after a validation campaign.

Conditions restrict destructive EC2 actions to resources that carry the run tag key, and IAM
actions to the `/agentic-tools/validate-install/` path. `ec2:CreateTags` is allowed only while
a resource is being created, so the key cannot retag someone else's resource to bring it into
scope.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyDiscovery",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity",
        "ec2:Describe*",
        "ssm:GetParameter",
        "ssm:DescribeInstanceInformation",
        "ssm:GetCommandInvocation",
        "servicequotas:GetServiceQuota"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CreateTaggedOnly",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:CreateSecurityGroup",
        "ec2:CreateKeyPair"
      ],
      "Resource": "*",
      "Condition": { "Null": { "aws:RequestTag/agentic-tools:validate-install": "false" } }
    },
    {
      "Sid": "RunInstancesSupportingResources",
      "Effect": "Allow",
      "Action": "ec2:RunInstances",
      "Resource": [
        "arn:aws:ec2:*::image/*",
        "arn:aws:ec2:*:*:subnet/*",
        "arn:aws:ec2:*:*:network-interface/*",
        "arn:aws:ec2:*:*:security-group/*",
        "arn:aws:ec2:*:*:key-pair/*"
      ]
    },
    {
      "Sid": "TagOnCreateOnly",
      "Effect": "Allow",
      "Action": "ec2:CreateTags",
      "Resource": "*",
      "Condition": { "StringEquals": { "ec2:CreateAction": ["RunInstances", "CreateSecurityGroup", "CreateKeyPair"] } }
    },
    {
      "Sid": "MutateOnlyTagged",
      "Effect": "Allow",
      "Action": [
        "ec2:TerminateInstances",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteKeyPair",
        "ec2:DeleteVolume",
        "ssm:SendCommand"
      ],
      "Resource": "*",
      "Condition": { "Null": { "aws:ResourceTag/agentic-tools:validate-install": "false" } }
    },
    {
      "Sid": "SsmDocument",
      "Effect": "Allow",
      "Action": "ssm:SendCommand",
      "Resource": "arn:aws:ssm:*::document/AWS-RunPowerShellScript"
    },
    {
      "Sid": "ScopedIam",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole", "iam:DeleteRole", "iam:TagRole", "iam:ListRoleTags",
        "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:TagInstanceProfile",
        "iam:ListInstanceProfileTags", "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile", "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/agentic-tools/validate-install/*",
        "arn:aws:iam::*:instance-profile/agentic-tools/validate-install/*"
      ]
    },
    {
      "Sid": "IamListing",
      "Effect": "Allow",
      "Action": ["iam:ListRoles", "iam:ListInstanceProfiles"],
      "Resource": "*"
    }
  ]
}
```

`iam:AttachRolePolicy` can be narrowed further with the condition
`"ArnEquals": {"iam:PolicyARN": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"}`.
Linux-only validation needs no IAM statements at all; drop `ScopedIam`, `IamListing`,
`SsmDocument`, and `ssm:SendCommand` in that case.

Verify the policy with the IAM policy simulator before the first run. A missing action shows up
as an `UnauthorizedOperation` error in the preflight or provision step, never as a silent skip.
