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

# ECS task execution role (pull images, write logs)
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "${var.repository_name}-ecs-exec-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "ecs-tasks.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "exec_role_attach_ecs" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# resource "aws_iam_role_policy_attachment" "exec_role_attach_ecr" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# # Optional task role for in-container AWS calls (left empty but created)
# resource "aws_iam_role" "ecs_task_role" {
#   name = "${var.repository_name}-task-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "ecs-tasks.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

resource "aws_cloudwatch_log_group" "strapi" {
  # name              = "/ecs/${var.repository_name}"
    name              = "/ecs/${var.repository_name_git}"

  retention_in_days = 14
}


variable "container_port" {
  description = "Port Strapi listens on inside container"
  type        = number
  default     = 1337
}

resource "aws_security_group" "alb_sg" {
  # name        = "${var.repository_name}-alb-sg"

  name        = "${var.repository_name_git}-alb-sg"
  description = "Allow HTTP to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "fargate_sg" {
  # name        = "${var.repository_name}-fargate-sg"

  name        = "${var.repository_name_git}-fargate-sg"
  description = "Security group for Strapi Fargate service"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  # name               = "${var.repository_name}-alb"

  name               = "${var.repository_name_git}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "strapi_tg" {
  # name        = "${var.repository_name}-tg"

  name        = "${var.repository_name_git}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }
}

variable "service_name" {
  type    = string
  default = "strapi-service"
}

variable "task_cpu" {
  type    = number
  default = 512
}

variable "task_memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 1
}

locals {
  image_uri = length(trim(var.docker_image_uri, " ")) > 0 ? var.docker_image_uri : "${aws_ecr_repository.strapi.repository_url}:${var.image_tag}"
}


resource "aws_ecs_cluster" "this" {
  # name = "${var.repository_name}-cluster"

  name = "${var.repository_name_git}-cluster"
}

resource "aws_ecs_task_definition" "strapi" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = data.aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      # image     = local.image_uri
      # image = "145065858967.dkr.ecr.ap-south-1.amazonaws.com/my-strapi-project-vivek:latest"
      image = "145065858967.dkr.ecr.ap-south-1.amazonaws.com/my-strapi-project-vivek-git:latest"

      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
  { name = "NODE_ENV", value = "production" },
  { name = "HOST", value = "0.0.0.0" },
  { name = "PORT", value = tostring(var.strapi_port) },
  # 👇 NEW: Allow your ALB DNS name
  { name = "STRAPI_HOST", value = "my-strapi-project-vivek-alb-1419655971.ap-south-1.elb.amazonaws.com" },
  { name = "STRAPI_URL", value = "http://my-strapi-project-vivek-alb-1419655971.ap-south-1.elb.amazonaws.com" },
  { name = "STRAPI_ADMIN_BACKEND_URL", value = "http://my-strapi-project-vivek-alb-1419655971.ap-south-1.elb.amazonaws.com" }
]



      # If you have secrets stored in AWS SSM/Secrets Manager prefer 'secrets' here instead of environment
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "strapi"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "strapi" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.fargate_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg.arn
    container_name   = "strapi"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}

output "alb_dns_name" {
  description = "Public URL (DNS) for the ALB; use http://<value>"
  value       = aws_lb.alb.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.strapi.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.strapi.name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.strapi_tg.arn
}
