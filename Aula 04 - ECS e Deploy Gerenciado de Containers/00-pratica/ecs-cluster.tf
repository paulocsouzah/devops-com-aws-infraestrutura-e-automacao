# Cluster ECS — no launch type Fargate isso e so um agrupamento logico,
# nao cria nenhuma instancia.
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}
