# Security Group do banco — so aceita MySQL (3306) vindo do Security
# Group da EC2 (nunca de um CIDR aberto). "security_groups" em vez de
# "cidr_blocks": a origem permitida e outro Security Group, nao um IP.
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Permite MySQL apenas a partir da EC2 da aplicacao"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL a partir da EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rds"
  }

  # Mesmo motivo do aws_db_subnet_group.main (network-rds.tf): a instancia
  # RDS so e renomeada, nao substituida, quando "project_name" muda — sem
  # create_before_destroy, o Terraform tenta apagar este Security Group
  # antes de mover a instancia pro novo, e a AWS recusa (ENI da instancia
  # ainda anexada a este SG).
  lifecycle {
    create_before_destroy = true
  }
}

# Instancia RDS MySQL — gerenciada pela AWS, sem IP publico, isolada na
# subnet privada (via DB Subnet Group).
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_name}-db"
  }
}
