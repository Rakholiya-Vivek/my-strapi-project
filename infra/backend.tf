terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-vivek" 
    key            = "strapi/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
