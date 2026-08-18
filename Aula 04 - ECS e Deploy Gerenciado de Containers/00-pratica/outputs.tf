output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS publico do Application Load Balancer — e por aqui que a aplicacao e acessada"
  value       = aws_lb.main.dns_name
}

output "app_url" {
  description = "URL da aplicacao no navegador"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_frontend_repository_url" {
  description = "URL do repositorio ECR do frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_api_repository_url" {
  description = "URL do repositorio ECR da api"
  value       = aws_ecr_repository.api.repository_url
}

output "ecs_cluster_name" {
  description = "Nome do Cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_frontend_service_name" {
  description = "Nome do Service do frontend"
  value       = aws_ecs_service.frontend.name
}

output "ecs_api_service_name" {
  description = "Nome do Service da api"
  value       = aws_ecs_service.api.name
}

output "db_endpoint" {
  description = "Endpoint (host) da instancia RDS"
  value       = aws_db_instance.main.address
}
