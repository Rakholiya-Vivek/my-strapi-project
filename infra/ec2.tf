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
    user        = var.ssh_user
    private_key = var.ssh_private_key
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # wait for user_data setup
      "echo 'Waiting for user_data setup...' && sleep 30",
      # verify docker + aws installed
      "which docker || (echo 'Docker not installed' && exit 1)",
      "which aws || (echo 'AWS CLI not installed' && exit 1)",

      # create .env file
      "cat > /home/ec2-user/strapi.env <<'EOT'\nHOST=${var.strapi_host}\nPORT=${var.strapi_port}\nAPP_KEYS=${var.app_keys}\nAPI_TOKEN_SALT=${var.api_token_salt}\nADMIN_JWT_SECRET=${var.admin_jwt_secret}\nJWT_SECRET=${var.jwt_secret}\nNODE_ENV=production\nEOT",

      # authenticate ECR
      "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${replace(var.docker_image_uri, \"/.*$\", \"\")}",

      # pull + run
      "docker pull ${var.docker_image_uri}",
      "docker rm -f strapi || true",
      "docker run --env-file /home/ec2-user/strapi.env -d --name strapi -p ${var.strapi_port}:${var.strapi_port} ${var.docker_image_uri}"
    ]
  }
}
