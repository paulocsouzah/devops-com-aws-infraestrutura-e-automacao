# Security Group do banco — so aceita MySQL (3306) vindo do Security
# Group das tasks do ECS (Aula 03 apontava para o sg-web da EC2, que
# nao existe mais).
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Permite MySQL apenas a partir das tasks do ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL a partir das tasks do ECS"
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
}

# Instancia RDS MySQL — identica a Aula 03, so muda quem tem permissao
# de conectar (agora as tasks do ECS, nao mais a EC2).
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
