variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "ami" {
  type = string
  default = "ami-01b6d88af12965bb6"
}

variable "repository_name" {
  type    = string
  default = "my-strapi-project-vivek"
}

variable "image_tag" {
  type    = string
  default = "v1"
}

variable "project_dir" {
  type    = string
  default = ".."
  description = "path to Strapi repo ; infra/ inside repo root -> default .."
}
