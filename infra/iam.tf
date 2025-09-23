provider "aws" {
  #region = var.aws_region
  profile = "pearlt"
}

resource "aws_iam_role" "ec2_ecr_full_access_role" {
  name = "ec2_ecr_full_access_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_full_access_policy" {
  name        = "ecr-full-access-policy"
  description = "Policy to allow EC2 full access to ECR (create repos, push, pull, etc.)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "ecr:*"  # Grant all actions on ECR
        Effect   = "Allow"
        Resource = "arn:aws:ecr:ap-south-1:145065858967:repository/*"  # Update region and account ID
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_full_access_attachment" {
  role       = aws_iam_role.ec2_ecr_full_access_role.name
  policy_arn = aws_iam_policy.ecr_full_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_ecr_full_access_role.name
}