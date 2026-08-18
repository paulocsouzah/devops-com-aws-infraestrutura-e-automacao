# 00. Prática — Projeto Terraform desta Aula

Esta pasta **nasce como uma cópia** do
[`00-pratica`](<../../Aula 03 - Provisionamento Automatico/00-pratica/README.md>)
da Aula 03, já completa (rede, RDS, EC2 autoprovisionada) — é o ponto de
partida. Cada módulo de exercício (`02`, `03`, `04`, `05`) edita ou
adiciona arquivos **aqui dentro**, e o módulo final (`07`) só valida o
que já está pronto.

> 💡 Se você está começando a Aula 04 agora, confirme que esta pasta já
> tem os arquivos da Aula 03 — se não tiver, copie o conteúdo de lá
> antes de seguir.

⚠️ **Antes do primeiro `apply`, atualize o `default` da variável
`project_name`** em `variables.tf`, de `"aula03"` para `"aula04"`. Todo
comando de exemplo desta aula (`aws ecs describe-services --cluster
aula04-cluster`, `aws ecr describe-images --repository-name
aula04-frontend`, etc.) assume esse prefixo — sem essa troca, os
recursos nascem como `aula03-*` e nenhum desses comandos encontra
nada.

## 📂 O que muda aqui, módulo a módulo

| Módulo | O que adiciona/muda em `00-pratica/` |
|---|---|
| [02-imagens-no-ecr](../02-imagens-no-ecr/README.md) | `ecr.tf` (dois repositórios) |
| [03-exercicio-01-cluster-e-alb](../03-exercicio-01-cluster-e-alb/README.md) | `network-alb.tf`, `ecs-cluster.tf`, `alb.tf`, mais variáveis novas em `variables.tf` |
| [04-exercicio-02-task-e-service](../04-exercicio-02-task-e-service/README.md) | **Remove** `ec2.tf`, `user_data.sh.tpl`, `nginx-app.conf` e o Security Group `web`; adiciona `security-group-ecs.tf`, `ecs-task-definitions.tf`, `ecs-services.tf`; atualiza `rds.tf`, `variables.tf` e `outputs.tf` |
| [05-exercicio-03-auto-scaling](../05-exercicio-03-auto-scaling/README.md) | `autoscaling.tf`, `dashboard.js`, mais variáveis de capacidade/alvo |
| [07-exercicio-final](../07-exercicio-final/README.md) | nada de novo — só valida, aplica de verdade e fecha com o relatório em PDF |

O módulo 04 é o mais simbólico: é onde a EC2 que existia desde a Aula 02
**sai de cena**, substituída por Task Definitions e Services do ECS.

## ⚠️ Antes de começar

- `terraform.tfvars` só precisa de `db_password` agora — `my_ip` e
  `app_repo_url` (da Aula 03) somem no módulo 04, junto com a EC2 que
  os usava.
- Não existe mais `vockey.pem` — Fargate não tem host pra acessar via SSH.
- Sempre rode `terraform destroy` ao final de cada sessão de estudo — o
  ALB e as tasks Fargate cobram por hora, mesmo sem tráfego.

## 🎯 Ao final desta aula

Esta pasta estará com a aplicação rodando em containers Fargate, atrás
de um Application Load Balancer, escalando sozinha por CPU e memória —
sem uma única EC2 pra administrar.
