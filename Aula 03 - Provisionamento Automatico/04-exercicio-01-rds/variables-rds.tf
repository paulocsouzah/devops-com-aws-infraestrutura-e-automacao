# Variaveis novas desta aula — RDS e a subnet privada que ele exige.
# Vivem num arquivo separado para nao sobrescrever o variables.tf que
# ja existe no projeto desde a Aula 02.

variable "availability_zone_b" {
  description = "Segunda Availability Zone, usada pela subnet privada do RDS (precisa ser diferente da AZ da subnet publica)"
  type        = string
  default     = "us-east-1b"
}

variable "private_subnet_cidr" {
  description = "Faixa de IPs (CIDR) da subnet privada, onde o RDS mora"
  type        = string
  default     = "10.0.2.0/24"
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
