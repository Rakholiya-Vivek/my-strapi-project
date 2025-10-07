# resource "aws_iam_role" "codedeploy_role" {
#   name = "codedeploy-ecs-service-role-vivekk"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = { Service = "codedeploy.amazonaws.com" }
#     }]
#   })
# }

# # Attach managed policies or a custom policy (example: AWSCodeDeployRoleForECS policy)
# resource "aws_iam_role_policy_attachment" "codedeploy_attach" {
#   role       = aws_iam_role.codedeploy_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS"
# }

resource "aws_codedeploy_app" "strapi_app" {
  name = "strapi-codedeploy-app-vivek"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "strapi_dg" {
  app_name              = aws_codedeploy_app.strapi_app.name
  deployment_group_name = "strapi-ecs-deployment-group-vivek"
  service_role_arn      = data.aws_iam_role.codedeploy_role.arn

#   deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes" # or "CodeDeployDefault.ECSAllAtOnce"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"


  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT" # or "ABORT"
      # wait_time_in_minutes = 5
    }

  

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  # Tell CodeDeploy about the load balancer & listeners
  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.blue.name
      }
      target_group {
        name = aws_lb_target_group.green.name
      }
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]  # production listener
      }
      # test_traffic_route can be omitted or set to a test listener ARN if you want separate test traffic port
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.strapi.name
  }

  depends_on = [aws_ecs_service.strapi] # ensure ECS service exists first
}
