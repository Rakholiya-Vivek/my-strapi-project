data "aws_security_group" "existing_sg" {
  name   = "pearlt_vivek_sg"  # The name of the security group
  vpc_id = "vpc-01b35def73b166fdc"  # Replace with your actual VPC ID
}


resource "aws_instance" "strapi" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = "pearlt_vivek_key"
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]


  tags = {
    Name = "${var.repository_name}-ec2"
  }
  # bootstrap: install docker + awscli (so the instance can login to ECR via role)
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable docker
    amazon-linux-extras install -y docker
    service docker start
    usermod -a -G docker ec2-user

    # install unzip & aws cli v2
    yum install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    # allow ec2-user to access docker
    chown ec2-user:ec2-user /var/run/docker.sock || true
  EOF

  # depends_on = [null_resource.build_and_push]
}

# ... same aws_instance as before, but without iam_instance_profile ...
locals {
  ecr_registry = regex("^([^/]+)", var.docker_image_uri)[0]
}

resource "null_resource" "deploy_strapi" {
  depends_on = [aws_instance.strapi]

  connection {
    type        = "ssh"
    host        = aws_instance.strapi.public_ip
    user        = "ec2-user"
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras enable docker",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -aG docker ec2-user",

      "sudo yum install -y unzip",
      "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
      "unzip -o awscliv2.zip",
      "sudo ./aws/install",

      "aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${local.ecr_registry}",

      "sudo docker stop strapi || true",
      "sudo docker rm strapi || true",
      "sudo docker pull ${var.docker_image_uri}",
      "sudo docker run -d --name strapi -p 1337:1337 ${var.docker_image_uri}"
    ]
  }
}
