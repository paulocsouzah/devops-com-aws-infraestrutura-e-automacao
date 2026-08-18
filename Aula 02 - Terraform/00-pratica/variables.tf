variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability Zone onde a subnet pública será criada"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "Faixa de IPs (CIDR) da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Faixa de IPs (CIDR) da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "project_name" {
  description = "Prefixo usado no nome/tags de todos os recursos deste projeto"
  type        = string
  default     = "aula02"
}

variable "my_ip" {
  description = "Seu IP público, usado para restringir o acesso SSH (defina em terraform.tfvars)"
  type        = string
}
