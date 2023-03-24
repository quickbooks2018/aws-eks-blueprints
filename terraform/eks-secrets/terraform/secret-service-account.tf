# Aws Secret Manager Access Policy
  module "secret_manager_access_policy" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
    version = "5.10.0"

    create_policy = true
    description   = "Allow aws Secrets Manager access"
    name          = "eks-secret-manager-policy"
    path          = "/"
    policy        = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Sid": "AllowSecretsManagerAccess",
        "Effect": "Allow",
        "Action": [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
        ],
        "Resource": "*"
        }
    ]
}

POLICY

    tags = {
      Environment = "dev"
      Terraform   = "true"
    }

  }

# Create a role that can be assumed by our service account
module "iam-assumable-role-with-oidc-just-like-iam-role-attachment-to-ec2" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
    version = "5.10.0"

    create_role      = true
    role_name        = "eks-secret-manager-role"
    provider_url     = module.eks.cluster_oidc_issuer_url
    role_policy_arns = [
      module.secret_manager_access_policy.arn
    ]

  }