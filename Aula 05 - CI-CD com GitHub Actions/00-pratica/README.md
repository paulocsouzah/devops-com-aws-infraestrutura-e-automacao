# 00. Prática — Projeto Terraform desta Aula

Esta pasta **nasce como uma cópia** do
[`00-pratica`](<../../Aula 04 - ECS e Deploy Gerenciado de Containers/00-pratica/README.md>)
da Aula 04, já completa (rede, RDS, ECR, Cluster ECS Fargate, ALB e Auto
Scaling) — é o ponto de partida. A infraestrutura em si não muda nesta
aula; o que muda é **como a imagem chega no ECR e como o Service é
atualizado**: isso deixa de ser manual e passa a ser feito por uma
pipeline do GitHub Actions.

> 💡 Se você está começando a Aula 05 agora, confirme que esta pasta já
> tem os arquivos da Aula 04 (rede, RDS, ECR, ECS, ALB, Auto Scaling) —
> se não tiver, copie o conteúdo de lá antes de seguir.

⚠️ **Antes do primeiro `apply`, atualize o `default` da variável
`project_name`** em `variables.tf`, de `"aula04"` para `"aula05"` — sem
essa troca, os recursos nascem como `aula04-*` e colidem com os que
você já aplicou (e destruiu) na Aula 04.

## 📂 O que muda aqui, módulo a módulo

Diferente das aulas anteriores, os módulos desta aula **não editam
arquivos `.tf` dentro de `00-pratica/`** — a infraestrutura já está
pronta desde a Aula 04. O que cada módulo constrói é o arquivo
`.github/workflows/deploy.yml`, **dentro do repositório `app-aula03`**
(o seu, no GitHub — não este repositório de material didático):

| Módulo | O que adiciona/muda no `deploy.yml` do `app-aula03` |
|---|---|
| [02-preparando-o-repositorio](../02-preparando-o-repositorio/README.md) | Cria o workflow mínimo, só com o trigger (`on: push`) e um step de teste |
| [03-exercicio-01-secrets-e-permissoes](../03-exercicio-01-secrets-e-permissoes/README.md) | Secrets AWS no GitHub, step `configure-aws-credentials` |
| [04-exercicio-02-build-e-push](../04-exercicio-02-build-e-push/README.md) | Job `build-and-push`: login no ECR, build/tag/push das duas imagens (tag = hash do commit) |
| [05-exercicio-03-deploy-automatico](../05-exercicio-03-deploy-automatico/README.md) | Job `deploy`: nova revisão da Task Definition + rolling deployment dos dois Services |
| [06-organizacao-e-boas-praticas](../06-organizacao-e-boas-praticas/README.md) | `concurrency`, `permissions` mínimas — ajustes de robustez no mesmo `deploy.yml` |
| [07-exercicio-final](../07-exercicio-final/README.md) | nada de novo — só valida a pipeline completa de ponta a ponta |

O módulo 05 é o mais simbólico: é onde o último comando manual da Aula
04 (`aws ecs update-service --force-new-deployment`) **sai de cena**,
substituído por um deploy que acontece sozinho a cada `push`.

## ⚠️ Antes de começar

- `terraform.tfvars` continua só precisando de `db_password`.
- Não existe mais `vockey.pem` nem acesso SSH — isso já saiu de cena na
  Aula 04.
- Sempre rode `terraform destroy` ao final de cada sessão de estudo — o
  ALB e as tasks Fargate cobram por hora, mesmo sem tráfego.

## 🎯 Ao final desta aula

Esta pasta estará com a mesma infraestrutura da Aula 04, mas o deploy
de uma nova versão da aplicação acontece sozinho a cada `push` na
branch principal — build da imagem, push pro ECR e rolling deployment
no ECS Service, tudo via GitHub Actions.
