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
