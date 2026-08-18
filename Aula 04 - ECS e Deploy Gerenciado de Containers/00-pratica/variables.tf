# Variaveis do projeto terraform-aula03 — rede/EC2 (Aula 02) + RDS e
# aplicacao (Aula 03), tudo consolidado num unico arquivo.

variable "aws_region" {
  description = "Regiao AWS onde os recursos serao criados"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability Zone onde a subnet publica sera criada"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Segunda Availability Zone, usada pela subnet privada do RDS (precisa ser diferente da AZ da subnet publica)"
  type        = string
  default     = "us-east-1b"
}

variable "vpc_cidr" {
  description = "Faixa de IPs (CIDR) da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Faixa de IPs (CIDR) da subnet publica"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Faixa de IPs (CIDR) da subnet privada, onde o RDS mora"
  type        = string
  default     = "10.0.2.0/24"
}

variable "project_name" {
  description = "Prefixo usado no nome/tags de todos os recursos deste projeto"
  type        = string
  default     = "aula03"
}

variable "my_ip" {
  description = "Seu IP publico, usado para restringir o acesso SSH (defina em terraform.tfvars)"
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados (schema) criado dentro da instancia RDS"
  type        = string
  default     = "app_aula03"
}

variable "db_username" {
  description = "Usuario administrador do RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Senha do usuario administrador do RDS (defina em terraform.tfvars, nunca aqui)"
  type        = string
  sensitive   = true
}

variable "app_repo_url" {
  description = "URL HTTPS do repositorio Git da aplicacao (app-aula03), clonado pelo user_data"
  type        = string
}
