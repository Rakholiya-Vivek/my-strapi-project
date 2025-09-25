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
    apt-get update -y
    apt-get upgrade -y

    # install docker
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common unzip
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io

    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    # install aws cli v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -o /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install

    # allow ubuntu user to access docker
    chown ubuntu:ubuntu /var/run/docker.sock || true
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
    user        = "ubuntu"
    private_key = var.ssh_private_key
  }

    provisioner "remote-exec" {
  inline = [
    "sudo apt-get update -y",
    "sudo apt-get upgrade -y",

    # install docker
    "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common unzip",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"",
    "sudo apt-get update -y",
    "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",

    "sudo systemctl start docker",
    "sudo systemctl enable docker",
    "sudo usermod -aG docker ubuntu",

    # install aws cli v2
    "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
    "unzip -o awscliv2.zip",
    "sudo ./aws/install",

    # ✅ Configure AWS credentials inside EC2
    "mkdir -p ~/.aws",
    "echo '[default]' > ~/.aws/credentials",
    "echo 'aws_access_key_id=${var.aws_access_key_id}' >> ~/.aws/credentials",
    "echo 'aws_secret_access_key=${var.aws_secret_access_key}' >> ~/.aws/credentials",
    "echo '[default]' > ~/.aws/config",
    "echo 'region=${var.aws_region}' >> ~/.aws/config",

    # ✅ ECR login
    "aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${local.ecr_registry}",

    # ✅ Clean up old container if exists
    "sudo docker stop strapi || true",
    "sudo docker rm strapi || true",

    # ✅ Pull & Run new container
    "sudo docker pull ${var.docker_image_uri}",
    "sudo docker run -d --name strapi -p 1337:1337 ${var.docker_image_uri}"
  ]
}

  
  triggers = {
    always_run = timestamp() #trigger every time apply 
  }

}
