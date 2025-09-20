resource "aws_instance" "strapi" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
#!/bin/bash
set -e

# update
yum update -y

# install docker
amazon-linux-extras install -y docker || yum install -y docker
service docker start
usermod -a -G docker ec2-user

# install unzip and aws cli v2
yum install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# login to ECR using IAM role and pull the image
aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

docker pull ${aws_ecr_repository.strapi.repository_url}:${var.image_tag}

# run the container mapping host port 80 -> container 1337
docker run -d --name strapi -p 80:1337 ${aws_ecr_repository.strapi.repository_url}:${var.image_tag}
EOF

  tags = {
    Name = "${var.repository_name}-ec2"
  }

  depends_on = [null_resource.build_and_push]
}
