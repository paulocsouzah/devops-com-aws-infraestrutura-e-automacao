# 00. Prática — Projeto Terraform desta Aula

Esta pasta **nasce como uma cópia** do
[`00-pratica`](<../../Aula 05 - CI-CD com GitHub Actions/00-pratica/README.md>)
da Aula 05, já completa (rede, RDS, ECR, Cluster ECS Fargate, ALB, Auto
Scaling, e a pipeline de CI/CD vivendo no repositório `app-aula03`) — é
o ponto de partida. Cada módulo de exercício (`02`, `03`, `04`, `05`)
edita ou adiciona arquivos **aqui dentro**, e o módulo final (`07`) só
valida o que já está pronto.

> 💡 Se você está começando a Aula 06 agora, confirme que esta pasta já
> tem os arquivos da Aula 05 (rede, RDS, ECR, ECS, ALB, Auto Scaling) —
> se não tiver, copie o conteúdo de lá antes de seguir. O repositório
> `app-aula03` (com a pipeline de CI/CD) não muda nesta aula — nenhum
> módulo pede pra editar ele.

⚠️ **Antes do primeiro `apply`, atualize o `default` da variável
`project_name`** em `variables.tf`, de `"aula05"` para `"aula06"` — sem
essa troca, os recursos nascem como `aula05-*` e colidem com os que
você já aplicou (e destruiu) na Aula 05.

## 🐳 Importante: como as imagens chegam no ECR desta vez

Trocar `project_name` pra `"aula06"` cria repositórios ECR **novos**
(`aula06-frontend`, `aula06-api`) — vazios. A pipeline de CI/CD que
você construiu na Aula 05 **não publica nada neles automaticamente**:
o `deploy.yml` do seu `app-aula03` tem os nomes `aula05-frontend`,
`aula05-api` e `aula05-cluster` **fixos no código** (não é uma variável
que se atualiza sozinha). Rodar essa pipeline agora só tentaria mandar
imagem pro ECR da Aula 05, que nem existe mais.

Como o foco desta aula é monitoramento, não CI/CD, a solução é simples:
**publique as imagens na mão, igual você fez na Aula 04 (módulo 02)** —
mesmos comandos, só trocando `aula04`/`aula05` por `aula06`:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

cd app-aula03/frontend
docker build -t aula06-frontend .
docker tag aula06-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula06-frontend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula06-frontend:latest

cd ../api
docker build -t aula06-api .
docker tag aula06-api:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula06-api:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula06-api:latest
```

Faça isso **depois** do primeiro `terraform apply` (os repositórios
ECR precisam existir antes do `push`) e **antes** do módulo 02 (os
Services do ECS ficam com `runningCount = 0` até existir uma imagem
pra puxar). Se os Services já tinham sido criados antes das imagens
existirem, force um novo deploy:

```bash
aws ecs update-service --cluster aula06-cluster --service aula06-frontend --force-new-deployment
aws ecs update-service --cluster aula06-cluster --service aula06-api --force-new-deployment
```

> 💡 A pipeline do `app-aula03` continua existindo e funcionando — só
> não é usada nesta aula. Se quisesse fazer ela publicar pros
> repositórios `aula06-*` também, precisaria editar os nomes fixos no
> `deploy.yml` — mas isso é opcional, fora do escopo desta aula.

## 📂 O que muda aqui, módulo a módulo

| Módulo | O que adiciona/muda em `00-pratica/` |
|---|---|
| [02-exercicio-01-container-insights](../02-exercicio-01-container-insights/README.md) | Edita `ecs-cluster.tf`, adicionando `setting { name = "containerInsights" }` |
| [03-exercicio-02-logs-centralizados](../03-exercicio-02-logs-centralizados/README.md) | Duas queries salvas do Logs Insights (`aws_cloudwatch_query_definition`) |
| [04-exercicio-03-dashboard-alb](../04-exercicio-03-dashboard-alb/README.md) | `monitoring-dashboard.tf` (um `aws_cloudwatch_dashboard` com 4 widgets) |
| [05-exercicio-04-alarme-sns](../05-exercicio-04-alarme-sns/README.md) | `monitoring-alarms.tf` (SNS Topic, assinatura por e-mail, Alarme de CPU), mais a variável `alert_email` |
| [07-exercicio-final](../07-exercicio-final/README.md) | nada de novo — só gera carga real e valida tudo funcionando junto |

Diferente da Aula 05, aqui a infraestrutura **volta a mudar** módulo a
módulo, dentro desta mesma pasta — é o mesmo padrão das Aulas 03 e 04.

## ⚠️ Antes de começar

- `terraform.tfvars` agora precisa de **dois** valores: `db_password`
  (desde a Aula 03) e `alert_email` (novo, a partir do módulo 05 —
  veja o `terraform.tfvars.example`).
- Depois do primeiro `apply`, publique as imagens **na mão** nos novos
  repositórios ECR — veja a seção **"Importante: como as imagens
  chegam no ECR desta vez"** acima. A pipeline de CI/CD da Aula 05 não
  faz isso sozinha aqui.
- Você vai precisar checar uma caixa de e-mail de verdade durante o
  módulo 05 (confirmação de assinatura do SNS).
- Sempre rode `terraform destroy` ao final de cada sessão de estudo — o
  ALB e as tasks Fargate cobram por hora, mesmo sem tráfego (o
  monitoramento em si é praticamente gratuito — veja o módulo 06 — mas
  a regra vale pra tudo o resto que já existia desde a Aula 04).

## 🎯 Ao final desta aula

Esta pasta estará com a mesma infraestrutura da Aula 05, mais Container
Insights ligado, queries salvas do Logs Insights, um Dashboard
CloudWatch com métricas do ECS e do ALB, e um Alarme real que te avisa
por e-mail quando a CPU da API fica alta — sem você precisar ficar
rodando comandos `describe-*` pra descobrir isso.
