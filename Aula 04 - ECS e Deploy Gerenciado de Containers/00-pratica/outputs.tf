output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID da subnet publica criada"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID da subnet privada criada (RDS)"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway criado"
  value       = aws_internet_gateway.main.id
}

output "route_table_id" {
  description = "ID da Route Table publica criada"
  value       = aws_route_table.public.id
}

output "security_group_id" {
  description = "ID do Security Group da EC2"
  value       = aws_security_group.web.id
}

output "security_group_rds_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds.id
}

output "db_endpoint" {
  description = "Endpoint (host) da instancia RDS"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Porta da instancia RDS"
  value       = aws_db_instance.main.port
}

output "instance_public_ip" {
  description = "IP publico da instancia EC2 criada"
  value       = aws_instance.web.public_ip
}

output "app_url" {
  description = "URL da aplicacao no navegador"
  value       = "http://${aws_instance.web.public_ip}"
}

output "ssh_command" {
  description = "Comando pronto para conectar via SSH (rode a partir da pasta onde salvou o vockey.pem)"
  value       = "ssh -i vockey.pem ec2-user@${aws_instance.web.public_ip}"
}
