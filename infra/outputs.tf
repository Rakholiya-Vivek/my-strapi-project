# output "ecr_repository_url" {
#   value = aws_ecr_repository.strapi.repository_url
# }

# output "instance_public_ip" {
#   value = aws_instance.strapi.public_ip
# }

# output "instance_public_dns" {
#   value = aws_instance.strapi.public_dns
# }


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