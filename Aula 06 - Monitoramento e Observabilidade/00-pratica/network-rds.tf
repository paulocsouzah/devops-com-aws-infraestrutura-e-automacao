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
  # "name" fixo de proposito, SEM var.project_name: a AWS recusa mover uma
  # instancia RDS existente para um DB Subnet Group novo quando os dois
  # cobrem exatamente as mesmas subnets (erro "InvalidVPCNetworkStateFault
  # ... in the same VPC"), o que aconteceria toda vez que project_name
  # mudasse entre aulas sem destruir a instancia antes. Como esse nome
  # nunca aparece em nenhum comando que voce roda, so nas tags (abaixo,
  # essas sim atualizadas por aula), mante-lo estavel evita esse impasse
  # sem perder nada em termos didaticos.
  name       = "app-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}
