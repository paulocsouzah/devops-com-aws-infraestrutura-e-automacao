# 🚢 Aula de ECS — Deploy Gerenciado de Containers

Material didático completo para a aula de **ECS (Elastic Container
Service)**, do conceito de orquestração gerenciada até a mesma aplicação
**React + Node.js + RDS MySQL** da Aula 03 rodando em **containers Fargate**,
atrás de um **Application Load Balancer**, com **Auto Scaling** — sem
nenhuma EC2 pra administrar.

Esta aula parte de onde a
[Aula 03](<../Aula 03 - Provisionamento Automatico/README.md>) parou:
a mesma VPC, o mesmo RDS, a mesma aplicação. A diferença é o **onde e como**
ela roda — a EC2 com Docker Compose e User Data dá lugar a um Cluster ECS
que gerencia os containers pra você.

## 📚 Estrutura

| Pasta | Conteúdo |
|-------|----------|
| [00-pratica](00-pratica/README.md) | O projeto Terraform real desta aula — nasce como cópia do `00-pratica` da Aula 03 |
| [01-conceitos](01-conceitos/README.md) | Cluster, Task Definition, Service, Fargate x EC2 launch type, ALB, Target Group, execution role x task role, Auto Scaling |
| [02-imagens-no-ecr](02-imagens-no-ecr/README.md) | Amazon ECR: criar repositório, build/tag/push das imagens do `app-aula03` |
| [03-exercicio-01-cluster-e-alb](03-exercicio-01-cluster-e-alb/README.md) | 2ª subnet pública (AZ2), Cluster ECS Fargate, Application Load Balancer + Target Groups |
| [04-exercicio-02-task-e-service](04-exercicio-02-task-e-service/README.md) | Task Definitions, Security Groups, ECS Services — e a EC2 da Aula 03 sai de cena |
| [05-exercicio-03-auto-scaling](05-exercicio-03-auto-scaling/README.md) | Application Auto Scaling por CPU e memória, dashboard ao vivo com Load Balancing + carga real |
| [06-organizacao-e-boas-praticas](06-organizacao-e-boas-praticas/README.md) | Diferenças pro modelo EC2, troubleshooting de task/target, timing do destroy |
| [07-exercicio-final](07-exercicio-final/README.md) | Validação de ponta a ponta de `00-pratica` — entrega em PDF |

## ▶️ Como usar

Siga as pastas na ordem numérica — cada módulo de exercício edita os
arquivos dentro de [`00-pratica/`](00-pratica/README.md), que é o
projeto real desta aula. Não existe "recriar do zero" no exercício
final — ele só valida o que já foi construído ao longo da aula.

**Pré-requisitos:**

- Ter concluído a [Aula 03](<../Aula 03 - Provisionamento Automatico/README.md>)
  — copie o `00-pratica` de lá para começar esta aula, e reaproveite o
  repositório `app-aula03`.
- Acesso ativo ao **AWS Academy Learner Lab**.
- Docker, Terraform e AWS CLI já instalados e configurados (Aulas 01-03).

⚠️ **Regra de ouro, como sempre:** nenhum recurso pode ser criado
manualmente pelo Console da AWS — tudo nasce do `terraform apply`. Nesta
aula ainda não existe pipeline (isso é a Aula 05): você aplica o
Terraform e faz o build/push das imagens na mão, mas sempre por código.

## 🖼️ Visão geral do que vamos construir

```
                        ┌────────────────────────── VPC ──────────────────────────┐
                        │                                                            │
                        │   Subnet pública AZ1      Subnet pública AZ2               │
                        │   ┌────────────────────────────────────┐                  │
Internet ── IGW ────────┤   │     Application Load Balancer        │                  │
                        │   │   "/"      → tg-frontend             │                  │
                        │   │   "/api/*" → tg-api                  │                  │
                        │   └───────────┬──────────────┬──────────┘                  │
                        │               ▼              ▼                              │
                        │      ┌────────────┐  ┌────────────┐      Subnet privada AZ2 │
                        │      │ ECS Service │  │ ECS Service │      ┌───────────────┐│
                        │      │  frontend   │  │  api        │─3306▶│  RDS MySQL     ││
                        │      │  (Fargate)  │  │  (Fargate)  │      │ (Aula 03)      ││
                        │      └────────────┘  └────────────┘      └───────────────┘│
                        │      Auto Scaling por CPU (cada Service, independente)      │
                        └───────────────────────────────────────────────────────────┘
```

Ao final desta aula, `git push` numa branch não faz nada ainda (isso é a
Aula 05) — mas rodar `terraform apply` cria toda essa infraestrutura, e a
aplicação fica no ar, escalando sozinha conforme a demanda, sem nenhum
servidor pra você atualizar ou reiniciar manualmente.

## 🏁 Avaliação

O módulo [07-exercicio-final](07-exercicio-final/README.md) fecha a aula
com o projeto `terraform-aula04`, que evolui o `terraform-aula03`
substituindo a EC2 por ECS + ALB + Auto Scaling. Ao final, você deve me
enviar um **relatório em PDF** com prints, comandos executados e
respostas às perguntas de reflexão — os detalhes de entrega e a rubrica
de avaliação estão no próprio módulo.
