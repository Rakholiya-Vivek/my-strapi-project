# resource "aws_ecr_repository" "strapi" {
#   name                 = var.repository_name
#   image_tag_mutability = "MUTABLE"

#   lifecycle {
#     prevent_destroy = true
#   }
# }
