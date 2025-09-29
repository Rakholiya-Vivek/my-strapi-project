data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

# Re-use your default VPC data source (you already define data.aws_vpc.default)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "my-strapi-project-vivek-ecs-exec-role-alt"
}

data "aws_iam_role" "ecs_task_role" {
  name = "my-strapi-project-vivek-task-role-alt"
}

data "aws_security_group" "existing_sg" {
  name   = "pearlt_vivek_sg"  # The name of the security group
  vpc_id = "vpc-01b35def73b166fdc"  # Replace with your actual VPC ID
}