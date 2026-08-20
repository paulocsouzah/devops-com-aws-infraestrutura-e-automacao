# 🔄 Aula de CI/CD — Deploy Automático com GitHub Actions

Material didático completo para a aula de **CI/CD (Integração e Entrega
Contínuas)**, do conceito de pipeline automatizada até a mesma aplicação
**React + Node.js + RDS MySQL + ECS Fargate** da Aula 04 ganhando **deploy
automático a cada `git push`** — sem um único comando manual de build,
push ou update de Service.

Esta aula parte de onde a
[Aula 04](<../Aula 04 - ECS e Deploy Gerenciado de Containers/README.md>)
parou: o mesmo Cluster ECS Fargate, o mesmo ALB, o mesmo RDS. A diferença
é **quem** builda a imagem, publica no ECR e atualiza o Service — até
aqui, era você, na mão, seguindo um passo a passo; a partir de agora, é o
**GitHub Actions**, sozinho, toda vez que um código novo chega na branch
principal.

## 📚 Estrutura

| Pasta | Conteúdo |
|-------|----------|
| [00-pratica](00-pratica/README.md) | O projeto Terraform real desta aula — nasce como cópia do `00-pratica` final da Aula 04 (a infra não muda nesta aula) |
| [01-conceitos](01-conceitos/README.md) | CI x CD, anatomia de um workflow do GitHub Actions (workflow, job, step, runner, action, trigger), Secrets |
| [02-preparando-o-repositorio](02-preparando-o-repositorio/README.md) | Onde a pipeline vive (o repositório `app-aula03`, não este), primeiro workflow disparando |
| [03-exercicio-01-secrets-e-permissoes](03-exercicio-01-secrets-e-permissoes/README.md) | Credenciais do AWS Academy como GitHub Secrets, e a limitação real de credenciais temporárias |
| [04-exercicio-02-build-e-push](04-exercicio-02-build-e-push/README.md) | Job de CI: build + tag (SHA do commit) + push das duas imagens pro ECR |
| [05-exercicio-03-deploy-automatico](05-exercicio-03-deploy-automatico/README.md) | Job de CD: nova revisão da Task Definition + rolling deployment automático do Service |
| [06-organizacao-e-boas-praticas](06-organizacao-e-boas-praticas/README.md) | Concurrency, permissões mínimas, rollback, troubleshooting de pipeline |
| [07-exercicio-final](07-exercicio-final/README.md) | Validação de ponta a ponta: `git push` → pipeline verde → aplicação atualizada no ar — entrega em PDF |

## ▶️ Como usar

Siga as pastas na ordem numérica — cada módulo de exercício edita o
workflow do GitHub Actions dentro do **repositório `app-aula03`** (não
dentro deste repositório de material didático). O
[`00-pratica/`](00-pratica/README.md) desta aula é só a infraestrutura
Terraform (idêntica à da Aula 04); o que muda, módulo a módulo, é o
arquivo `.github/workflows/deploy.yml` do `app-aula03`.

**Pré-requisitos:**

- Ter concluído a
  [Aula 04](<../Aula 04 - ECS e Deploy Gerenciado de Containers/README.md>)
  — copie o `00-pratica` de lá para começar esta aula.
- Repositório `app-aula03` já publicado na **sua própria conta do
  GitHub** (Aula 03/04) — é nele que a pipeline vai viver.
- Acesso ativo ao **AWS Academy Learner Lab**.
- Docker, Terraform, AWS CLI e Git já instalados e configurados (Aulas
  01-04).

⚠️ **Regra de ouro, como sempre:** nenhum recurso pode ser criado
manualmente pelo Console da AWS — tudo nasce do `terraform apply`. O que
muda nesta aula é que **build, push e deploy** também deixam de ser
manuais.

## 🖼️ Visão geral do que vamos construir

```
 git push (branch main)
        │
        ▼
┌───────────────────────── GitHub Actions ─────────────────────────┐
│                                                                     │
│  Job "build-and-push"          Job "deploy" (needs: build-and-push)│
│  ┌───────────────────────┐     ┌─────────────────────────────────┐│
│  │ checkout               │     │ nova revisao da Task Definition ││
│  │ login no ECR           │ ──▶ │ (imagem = tag do commit)        ││
│  │ docker build+tag+push  │     │ update do ECS Service           ││
│  │ (frontend + api)       │     │ aguarda rolling deployment       ││
│  └───────────────────────┘     └─────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
                     ECS Fargate troca as tasks aos poucos,
                     sempre com o ALB servindo tráfego —
                     zero downtime durante a atualização
```

Ao final desta aula, um `git push` na branch principal do `app-aula03`
faz a aplicação inteira ser rebuildada, republicada e reimplantada no ECS
sozinha — o mesmo fluxo que times de engenharia usam em produção todos
os dias.

## 🏁 Avaliação

O módulo [07-exercicio-final](07-exercicio-final/README.md) fecha a aula
com o projeto `terraform-aula05`, que reaproveita a infraestrutura da
Aula 04 e adiciona a pipeline de CI/CD. Ao final, você deve me enviar um
**relatório em PDF** com prints, comandos executados e respostas às
perguntas de reflexão — os detalhes de entrega e a rubrica de avaliação
estão no próprio módulo.
