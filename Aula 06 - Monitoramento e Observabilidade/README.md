# 📊 Aula de Monitoramento — Enxergando o que Roda em Produção

Material didático completo para a aula de **Monitoramento e
Observabilidade**, do conceito de "o que observar" até a mesma
aplicação **React + Node.js + RDS MySQL + ECS Fargate**, com deploy
automático desde a Aula 05, ganhando **métricas, logs centralizados e
um alarme de verdade** que te avisa por e-mail quando algo sai do
normal.

Esta aula parte de onde a
[Aula 05](<../Aula 05 - CI-CD com GitHub Actions/README.md>) parou: o
mesmo Cluster ECS Fargate, o mesmo ALB, o mesmo RDS. A diferença é que,
até aqui, a única forma de saber se a aplicação estava saudável era
rodar `aws ecs describe-services` ou `aws elbv2 describe-target-health`
na mão — a partir de agora, o CloudWatch observa isso o tempo todo,
sozinho, e te avisa quando precisar.

> 💡 A pipeline de CI/CD da Aula 05 não é usada nesta aula — como
> `project_name` muda pra `"aula06"`, os repositórios ECR são novos, e
> a publicação das imagens desta vez é manual (veja o
> [`00-pratica/README.md`](00-pratica/README.md)). O foco aqui é
> observabilidade, não deploy automatizado.

## 📚 Estrutura

| Pasta | Conteúdo |
|-------|----------|
| [00-pratica](00-pratica/README.md) | O projeto Terraform real desta aula — nasce como cópia do `00-pratica` final da Aula 05 |
| [01-conceitos](01-conceitos/README.md) | Métricas x logs x alarmes, os "3 pilares" da observabilidade, anatomia do CloudWatch (namespace, métrica, dimensão, log group) |
| [02-exercicio-01-container-insights](02-exercicio-01-container-insights/README.md) | Container Insights: CPU e memória de cada task do ECS, sem instrumentar nada na aplicação |
| [03-exercicio-02-logs-centralizados](03-exercicio-02-logs-centralizados/README.md) | CloudWatch Logs Insights: consultar os logs do frontend e da api com uma linguagem de query |
| [04-exercicio-03-dashboard-alb](04-exercicio-03-dashboard-alb/README.md) | Métricas do Application Load Balancer (requisições, latência, erros 5xx) num Dashboard só, criado por Terraform |
| [05-exercicio-04-alarme-sns](05-exercicio-04-alarme-sns/README.md) | SNS + CloudWatch Alarm: notificação por e-mail quando a CPU da api fica alta |
| [06-organizacao-e-boas-praticas](06-organizacao-e-boas-praticas/README.md) | Custos de monitoramento, thresholds de alarme, troubleshooting de assinatura SNS |
| [07-exercicio-final](07-exercicio-final/README.md) | Validação de ponta a ponta: gerar carga real e ver o alarme disparar — entrega em PDF |

## ▶️ Como usar

Siga as pastas na ordem numérica — cada módulo de exercício edita ou
adiciona arquivos dentro de [`00-pratica/`](00-pratica/README.md), que é
o projeto real desta aula (mesmo padrão das Aulas 03 e 04).

**Pré-requisitos:**

- Ter concluído a
  [Aula 05](<../Aula 05 - CI-CD com GitHub Actions/README.md>) — copie
  o `00-pratica` de lá para começar esta aula.
- Acesso ativo ao **AWS Academy Learner Lab**.
- Uma **caixa de e-mail que você acesse agora** (vai receber uma
  confirmação de assinatura do SNS no módulo 05, e o alarme de verdade
  no módulo 07).
- Docker, Terraform, AWS CLI e Git já instalados e configurados (Aulas
  01-05).

⚠️ **Regra de ouro, como sempre:** nenhum recurso pode ser criado
manualmente pelo Console da AWS — os alarmes, o SNS e o Dashboard
nascem todos de `terraform apply`, igual a tudo o resto.

## 🖼️ Visão geral do que vamos construir

```
                                    ┌── CloudWatch ──────────────────────────────┐
                                    │                                             │
ECS Cluster (Container Insights) ──┤  Metricas: CPU/memoria por task e Service   │
   Services frontend + api         │                                             │
   Logs (awslogs, desde Aula 04) ──┤  Logs Insights: consulta pelos containers   │
                                    │                                             │
Application Load Balancer ─────────┤  Metricas: requisicoes, latencia, 5xx        │
                                    │                                             │
                                    │  Dashboard (1 tela com tudo acima)           │
                                    │                                             │
                                    │  Alarme: CPU da api > 70% por 2 min          │
                                    └───────────────┬─────────────────────────────┘
                                                     │ dispara
                                                     ▼
                                              SNS Topic ──▶ seu e-mail
```

Ao final desta aula, você não precisa mais ficar rodando comandos
`describe-*` pra saber se a aplicação está bem — o CloudWatch observa
por você, e um e-mail chega sozinho se a CPU da API disparar.

## 🏁 Avaliação

O módulo [07-exercicio-final](07-exercicio-final/README.md) fecha a
aula com o projeto `terraform-aula06`, que evolui o `terraform-aula05`
adicionando Container Insights, Logs Insights, um Dashboard e um alarme
real com notificação por e-mail. Ao final, você deve me enviar um
**relatório em PDF** com prints, comandos executados e respostas às
perguntas de reflexão — os detalhes de entrega e a rubrica de avaliação
estão no próprio módulo.
