output "ecr_repository_url" {
  value = aws_ecr_repository.strapi.repository_url
}

output "instance_public_ip" {
  value = aws_instance.strapi.public_ip
}

output "instance_public_dns" {
  value = aws_instance.strapi.public_dns
}
