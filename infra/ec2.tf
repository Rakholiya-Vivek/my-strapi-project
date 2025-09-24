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

resource "null_resource" "deploy_strapi" {
  depends_on = [aws_instance.strapi]

  triggers = {
    image      = var.docker_image_uri
    app_keys   = var.app_keys
    api_salt   = var.api_token_salt
    admin_jwt  = var.admin_jwt_secret
    jwt_secret = var.jwt_secret
  }

  connection {
    type        = "ssh"
    host        = aws_instance.strapi.public_ip
    user        = "ec2-user"
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "echo HOST=0.0.0.0 > /home/ec2-user/strapi.env",
      "echo PORT=1337 >> /home/ec2-user/strapi.env",
      "echo APP_KEYS=${var.app_keys} >> /home/ec2-user/strapi.env",
      "echo API_TOKEN_SALT=${var.api_token_salt} >> /home/ec2-user/strapi.env",
      "echo ADMIN_JWT_SECRET=${var.admin_jwt_secret} >> /home/ec2-user/strapi.env",
      "echo JWT_SECRET=${var.jwt_secret} >> /home/ec2-user/strapi.env",
      "echo NODE_ENV=production >> /home/ec2-user/strapi.env",

      # Export AWS creds (for ECR login only)
      "export AWS_ACCESS_KEY_ID=${var.aws_access_key_id}",
      "export AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key}",

      # ECR login & pull
      "REGISTRY=$(echo ${var.docker_image_uri} | cut -d'/' -f1)",
      "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin $REGISTRY",
      "docker pull ${var.docker_image_uri}",
      "docker rm -f strapi || true",
      "docker run --env-file /home/ec2-user/strapi.env -d --name strapi -p 1337:1337 ${var.docker_image_uri}"
    ]
  }
}
