

resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/${var.repository_name_git}"
  retention_in_days = 14
  tags = {
    Name = "${var.repository_name_git}-ecs-logs"
    Project = var.repository_name_git
  }
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "${var.repository_name_git}-ecs-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0,
        y = 0,
        width = 12,
        height = 6
        properties = {
          view = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ECS","CPUUtilization","ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          region = var.aws_region
          title = "ECS CPU Utilization (Service)"
          period = 60
          stat = "Average"
        }
      },
      {
        type = "metric"
        x = 12, y = 0, width = 12, height = 6
        properties = {
          view = "timeSeries"
          metrics = [
            ["AWS/ECS","MemoryUtilization","ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          region = var.aws_region
          title = "ECS Memory Utilization (Service)"
          period = 60
          stat = "Average"
        }
      },
      {
        type = "metric"
        x = 0, y = 6, width = 12, height = 6
        properties = {
          view = "timeSeries"
          metrics = [
            ["ECS/ContainerInsights","RunningTaskCount","ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          region = var.aws_region
          title = "Running Task Count"
          stat = "Average"
          period = 60
        }
      },
      {
        type = "metric"
        x = 12, y = 6, width = 12, height = 6
        properties = {
          view = "timeSeries"
          metrics = [
            ["ECS/ContainerInsights","NetworkRxBytes","ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.strapi.name],
            ["ECS/ContainerInsights","NetworkTxBytes","ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          region = var.aws_region
          title = "Network Rx/Tx (Bytes/sec)"
          stat = "Average"
          period = 60
        }
      }
    ]
  })
}



resource "aws_sns_topic" "alerts" {
  name = "${var.repository_name_git}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "nid01010101010101@gmail.com"  # Change to your email
}


variable "sns_topic_arn" {
  type = string
  default = ""
  description = "Optional SNS topic ARN for alarm notifications (leave empty to disable actions)"
}

# CPU high alarm (AWS/ECS)
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.repository_name_git}-cpu-high"
  alarm_description   = "CPU > 70% for ECS service"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.strapi.name
  }

  lifecycle {
    ignore_changes = [alarm_actions] # optional to keep manual actions
  }

  dynamic "alarm_actions" {
    for_each = var.sns_topic_arn == "" ? [] : [var.sns_topic_arn]
    content {
      alarm_actions = [alarm_actions.value]
    }
  }
}

# Memory high alarm (AWS/ECS)
resource "aws_cloudwatch_metric_alarm" "ecs_mem_high" {
  alarm_name          = "${var.repository_name_git}-memory-high"
  alarm_description   = "Memory > 80% for ECS service"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.strapi.name
  }
}

# RunningTaskCount low alarm (Container Insights)
resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_low" {
  alarm_name          = "${var.repository_name_git}-running-tasks-low"
  alarm_description   = "Running tasks below desired count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = var.desired_count

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.strapi.name
  }
}
