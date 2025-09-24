# resource "aws_ecr_repository" "strapi" {
#   name                 = var.repository_name
#   image_tag_mutability = "MUTABLE"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket = "my-terraform-state-bucket-vivek" # 🔴 change name (must be globally unique)

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "terraform-state"
  }
}

# Enable versioning (important for rollback)
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-locks"
  }
}
