# Variavel nova desta aula — a URL do repositorio Git da aplicacao que
# o user_data vai clonar. Fica separada do variables.tf original pelo
# mesmo motivo do modulo 04: nao sobrescrever o arquivo que ja existe.

variable "app_repo_url" {
  description = "URL HTTPS do repositorio Git da aplicacao (app-aula03), clonado pelo user_data"
  type        = string
}
