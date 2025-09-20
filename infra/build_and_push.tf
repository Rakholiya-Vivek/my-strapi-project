resource "null_resource" "build_and_push" {
  triggers = {
    image_tag = var.image_tag
    repo_url  = aws_ecr_repository.strapi.repository_url
  }

  provisioner "local-exec" {
    working_dir = var.project_dir

    command = <<EOT
set -e
echo "Logging in to ECR..."
aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

echo "Building Docker image..."
docker build -f Dockerfile.prod -t ${aws_ecr_repository.strapi.repository_url}:${var.image_tag} .

echo "Pushing Docker image..."
docker push ${aws_ecr_repository.strapi.repository_url}:${var.image_tag}
EOT
  }
}
