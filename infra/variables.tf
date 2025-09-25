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
  default = "ami-02d26659fd82cf299"
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


variable "key_name" { type = string }      

# image to deploy (from CI)
variable "docker_image_uri" { 
  type = string 
  default = "" 
  }

# Strapi runtime env (passed from GitHub secrets)
variable "app_keys" { 
  type = string 
  sensitive = true 
  }
variable "api_token_salt" { 
  type = string 
  sensitive = true 
}
variable "admin_jwt_secret" { 
  type = string 
  sensitive = true 
}
variable "jwt_secret" { 
  type = string 
  sensitive = true 
}
variable "strapi_host" { 
  type = string 
  default = "0.0.0.0" 
}
variable "strapi_port" { 
  type = string 
  default = "1337" 
}

variable "ssh_user" { 
  type = string 
  default = "ec2-user" 
}
variable "ssh_private_key" { 
  type = string 
  sensitive = true 
}
variable "aws_access_key_id" { 
  sensitive = true 
  }
variable "aws_secret_access_key" { 
  sensitive = true 
  }
