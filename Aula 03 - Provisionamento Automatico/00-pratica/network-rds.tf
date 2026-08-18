# Subnet privada — segunda Availability Zone, sem rota para o Internet
# Gateway. O RDS nao precisa de internet: so conversa com recursos
# dentro da propria VPC (a EC2).
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = "${var.project_name}-subnet-private"
  }
}

# DB Subnet Group — a AWS exige que cubra pelo menos duas AZs, mesmo
# para uma instancia RDS single-AZ (sem replica), por motivos de alta
# disponibilidade da plataforma.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}
