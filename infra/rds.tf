resource "aws_db_subnet_group" "strapi" {
  name       = "strapi-db-subnet-group-vivek"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "strapi-db-subnet-group"
  }
}

resource "aws_security_group" "strapi_db" {
  name        = "strapi-db-sg-vivek"
  description = "Allow ECS to access PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Postgres from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id] # ECS SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "strapi" {
  identifier              = "strapi-postgres-vivek"
  engine                  = "postgres"
  engine_version          = "15.3"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100

  db_name                 = "strapidb"
  username                = "strapiuser"
  password                = var.db_password
  port                    = 5432

  db_subnet_group_name    = aws_db_subnet_group.strapi.name
  vpc_security_group_ids  = [aws_security_group.strapi_db.id]

  skip_final_snapshot     = true
}

