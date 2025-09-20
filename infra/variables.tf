variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
  description = "Path to public SSH public key on your machine"
}

variable "repository_name" {
  type    = string
  default = "strapi-app"
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
