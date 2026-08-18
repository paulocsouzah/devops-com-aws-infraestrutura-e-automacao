# Repositorios ECR — um para cada container da aplicacao. O ECS nunca
# builda imagem: ele so consome o que ja estiver publicado aqui.
#
# force_delete = true: sem isso, "terraform destroy" falha se o
# repositorio ainda tiver imagens dentro (e vai ter — o push e manual,
# fora do controle do Terraform). Documentado tambem no modulo 06.

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr-frontend"
  }
}

resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr-api"
  }
}
