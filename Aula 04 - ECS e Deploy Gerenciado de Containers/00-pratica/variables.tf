# Variaveis do projeto terraform-aula04 — rede + RDS (Aula 03) + ECS,
# ALB e Auto Scaling (Aula 04), tudo consolidado.
#
# Repare no que NAO existe mais, comparado a Aula 03: "my_ip" (nao ha
# mais SSH) e "app_repo_url" (nao ha mais user_data/git clone).

variable "aws_region" {
  description = "Regiao AWS onde os recursos serao criados"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability Zone da subnet publica principal (AZ1)"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Segunda Availability Zone — subnet privada (RDS) e subnet publica do ALB"
  type        = string
  default     = "us-east-1b"
}

variable "vpc_cidr" {
  description = "Faixa de IPs (CIDR) da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Faixa de IPs (CIDR) da subnet publica AZ1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "Faixa de IPs (CIDR) da subnet publica AZ2 (ALB)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_cidr" {
  description = "Faixa de IPs (CIDR) da subnet privada, onde o RDS mora"
  type        = string
  default     = "10.0.2.0/24"
}

variable "project_name" {
  description = "Prefixo usado no nome/tags de todos os recursos deste projeto"
  type        = string
  default     = "aula04"
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

variable "frontend_desired_count" {
  description = "Quantidade de tasks do frontend que o Service deve manter rodando"
  type        = number
  default     = 1
}

variable "api_desired_count" {
  description = "Quantidade de tasks da api que o Service deve manter rodando"
  type        = number
  default     = 1
}

variable "frontend_min_capacity" {
  description = "Quantidade minima de tasks do frontend (Auto Scaling)"
  type        = number
  default     = 1
}

variable "frontend_max_capacity" {
  description = "Quantidade maxima de tasks do frontend (Auto Scaling)"
  type        = number
  default     = 3
}

variable "api_min_capacity" {
  description = "Quantidade minima de tasks da api (Auto Scaling)"
  type        = number
  default     = 1
}

variable "api_max_capacity" {
  description = "Quantidade maxima de tasks da api (Auto Scaling)"
  type        = number
  default     = 3
}

variable "target_cpu_percent" {
  description = "Percentual de CPU media que o Auto Scaling tenta manter"
  type        = number
  default     = 40
}

variable "target_memory_percent" {
  description = "Percentual de memoria media que o Auto Scaling da api tenta manter"
  type        = number
  default     = 70
}
