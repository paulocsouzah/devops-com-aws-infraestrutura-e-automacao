output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID da subnet pública criada"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway criado"
  value       = aws_internet_gateway.main.id
}

output "route_table_id" {
  description = "ID da Route Table pública criada"
  value       = aws_route_table.public.id
}

output "security_group_id" {
  description = "ID do Security Group criado"
  value       = aws_security_group.web.id
}

output "instance_public_ip" {
  description = "IP público da instância EC2 criada"
  value       = aws_instance.web.public_ip
}

output "ssh_command" {
  description = "Comando pronto para conectar via SSH (rode a partir da pasta onde salvou o vockey.pem)"
  value       = "ssh -i vockey.pem ec2-user@${aws_instance.web.public_ip}"
}
