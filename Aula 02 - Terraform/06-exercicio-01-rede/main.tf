terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. VPC — a "rede privada" onde tudo o mais vai morar dentro
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Subnet pública — sub-rede dentro da VPC, associada a uma AZ específica.
# "map_public_ip_on_launch" faz com que instâncias criadas aqui já
# recebam IP público automaticamente.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public"
  }
}

# 3. Internet Gateway — "porta de saída" da VPC para a internet.
# Sem isso, nenhuma instância dentro da VPC consegue ser acessada
# (nem acessar) a internet, mesmo tendo IP público.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 4. Route Table — a "tabela de rotas" que diz para onde o tráfego
# deve ir. Aqui dizemos: "qualquer destino (0.0.0.0/0) que eu não
# souber, manda para o Internet Gateway".
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# 5. Associação — liga a Route Table criada acima à subnet pública.
# Sem essa associação, a subnet continuaria usando a "main route table"
# padrão da VPC, que não tem rota nenhuma para a internet.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
