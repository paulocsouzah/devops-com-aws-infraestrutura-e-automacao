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

variable "public_subnet_b_cidr" {
  description = "Faixa de IPs (CIDR) da segunda subnet publica (AZ2), usada pelo ALB"
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
  default     = "app_aula04"
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
  description = "Quantidade desejada de tasks do Service frontend"
  type        = number
  default     = 1
}

variable "api_desired_count" {
  description = "Quantidade desejada de tasks do Service api"
  type        = number
  default     = 1
}

variable "frontend_min_capacity" {
  description = "Capacidade minima (numero de tasks) do Auto Scaling do Service frontend"
  type        = number
  default     = 1
}

variable "frontend_max_capacity" {
  description = "Capacidade maxima (numero de tasks) do Auto Scaling do Service frontend"
  type        = number
  default     = 3
}

variable "api_min_capacity" {
  description = "Capacidade minima (numero de tasks) do Auto Scaling do Service api"
  type        = number
  default     = 1
}

variable "api_max_capacity" {
  description = "Capacidade maxima (numero de tasks) do Auto Scaling do Service api"
  type        = number
  default     = 3
}

variable "target_cpu_percent" {
  description = "Utilizacao media de CPU (%) que o Auto Scaling procura manter em cada Service"
  type        = number
  default     = 40
}

variable "target_memory_percent" {
  description = "Utilizacao media de memoria (%) que o Auto Scaling procura manter no Service api"
  type        = number
  default     = 70
}
