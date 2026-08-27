# ☁️ DevOps com AWS — Infraestrutura e Automação

Material didático da disciplina **DevOps**, do módulo de **Infraestrutura e
Automação**, da **Pós-Graduação em Full Stack Developer** da **FAEX —
Faculdade de Extrema**.

O curso parte do zero em containers e caminha até um pipeline de CI/CD
completo, com infraestrutura provisionada por código na AWS e monitoramento
em produção — o mesmo tipo de fluxo usado por times de engenharia no
mercado.

---

## 🎯 Objetivo geral

Ao final da disciplina, o aluno será capaz de:

- Entender a cultura e as práticas de **DevOps** (CI/CD, ambientes,
  colaboração Dev + Ops).
- **Containerizar** aplicações com Docker e orquestrar múltiplos serviços
  com Docker Compose.
- Provisionar **infraestrutura como código (IaC)** na AWS usando Terraform,
  sem clicar em nada manualmente no Console.
- Automatizar o **provisionamento de servidores** (User Data / Cloud-Init),
  eliminando configuração manual pós-criação da máquina.
- Orquestrar containers em produção com **Amazon ECS** (Fargate), incluindo
  balanceamento de carga e escalabilidade automática.
- Construir uma **pipeline de CI/CD** com GitHub Actions que builda, publica
  e faz deploy automático da aplicação.
- Implementar **monitoramento e observabilidade** com CloudWatch (métricas,
  logs e alarmes).
- Integrar tudo isso em um **projeto final**, do commit até a aplicação
  rodando e monitorada em produção — como acontece em um ambiente real de
  empresa.

## 👤 Público-alvo e pré-requisitos

- Alunos da Pós-Graduação em Full Stack Developer da FAEX.
- Pré-requisito recomendado: lógica de programação e familiaridade básica
  com linha de comando (terminal). Não é necessário conhecimento prévio de
  Docker, Terraform ou AWS — tudo é construído do zero, aula a aula.
- Necessário notebook próprio com permissão para instalar software (Docker,
  Git, VS Code) e conta gratuita na [AWS Academy](https://www.awsacademy.com/)
  e no [GitHub](https://github.com/).

## 🧭 Metodologia

Cada aula é um módulo autocontido, com a seguinte estrutura:

1. **Teoria** — conceitos explicados em linguagem direta, com analogias e
   diagramas, antes de qualquer comando no terminal.
2. **Prática guiada** — exercícios passo a passo, como se eu estivesse
   explicando ao vivo, com comandos comentados para copiar, rodar e
   entender o que está acontecendo.
3. **Exercício final da aula** — desafio prático que fecha o assunto e gera
   uma entrega.

### 📝 Avaliação

Da Aula 01 à Aula 06, o padrão de entrega é o mesmo: ao final do exercício
final, o aluno envia um **relatório em PDF** com prints das evidências,
comandos executados e respostas às perguntas de reflexão. Esse PDF é o
material usado para avaliação e lançamento de nota. Os detalhes específicos
de cada entrega (o que precisa aparecer no PDF, rubrica etc.) estão no
próprio módulo de exercício final de cada aula.

A **Aula 07** foge desse padrão de propósito: é uma avaliação prática,
feita ao vivo, em dupla/trio, sem relatório em PDF — a entrega é o link da
aplicação no ar e uma demonstração ao vivo pro professor. Os detalhes
(formato, rubrica, prazo) estão no [próprio módulo](<Aula 07 - Projeto Final/README.md>).

---

## 🗂️ Estrutura do repositório

Cada aula vive em sua própria pasta, numerada na ordem em que deve ser
seguida. Dentro de cada aula, os módulos também são numerados
sequencialmente (`01-conceitos`, `02-...`, ..., `exercicio-final`), cada um
com seu próprio `README.md`.

```
devops-com-aws-infraestrutura-e-automacao/
├── Aula 01 - Docker/
│   ├── 01-conceitos/
│   ├── 02-arquitetura-e-instalacao/
│   ├── ...
│   └── 08-exercicio-final/
├── Aula 02 - Terraform/
├── Aula 03 - Provisionamento Automatico/
├── Aula 04 - ECS e Deploy Gerenciado de Containers/
├── Aula 05 - CI-CD com GitHub Actions/
├── Aula 06 - Monitoramento e Observabilidade/
└── Aula 07 - Projeto Final/
```

## 📚 Grade do curso

| # | Aula | Tema | Status |
|---|------|------|--------|
| 1 | [Aula 01 - Docker](<Aula 01 - Docker/README.md>) | Introdução ao DevOps e Docker | ✅ Disponível |
| 2 | [Aula 02 - Terraform](<Aula 02 - Terraform/README.md>) | Infraestrutura como Código com Terraform | ✅ Disponível |
| 3 | [Aula 03 - Provisionamento Automatico](<Aula 03 - Provisionamento Automatico/README.md>) | User Data, Cloud-Init, RDS e deploy automatizado (React + Node) | ✅ Disponível |
| 4 | [Aula 04 - ECS e Deploy Gerenciado de Containers](<Aula 04 - ECS e Deploy Gerenciado de Containers/README.md>) | Cluster Fargate, Task Definition, Service, ALB e Auto Scaling, por Terraform | ✅ Disponível |
| 5 | [Aula 05 - CI/CD com GitHub Actions](<Aula 05 - CI-CD com GitHub Actions/README.md>) | Pipeline de build, imagem Docker e deploy automático no ECS | ✅ Disponível |
| 6 | [Aula 06 - Monitoramento e Observabilidade](<Aula 06 - Monitoramento e Observabilidade/README.md>) | CloudWatch, Container Insights, logs, métricas e alarmes | ✅ Disponível |
| 7 | [Aula 07 - Projeto Final](<Aula 07 - Projeto Final/README.md>) | Avaliação final: reconstruir toda a infraestrutura em dupla/trio, em aula, com valores próprios | ✅ Disponível |

**Como usar:** siga as aulas na ordem numérica. Dentro de cada aula, siga
também as subpastas na ordem — cada uma parte do que foi construído na
anterior.

---

## 📖 Ementa detalhada

### 🐳 Aula 1 — Introdução ao DevOps e Docker

**Conteúdo**
- O que é DevOps
- Cultura DevOps
- CI/CD
- Ambientes (Desenvolvimento, Homologação e Produção)
- Introdução ao Docker
- Dockerfile
- Docker Compose
- Containers, Imagens e Volumes

**Prática**
- Criar um projeto simples
- Containerizar a aplicação
- Criar um ambiente com Docker Compose
- Executar Backend + Banco de Dados + Nginx

**Objetivo da aula:** ao final, o aluno terá uma aplicação funcionando
totalmente em containers.

📂 [Acessar material da Aula 01](<Aula 01 - Docker/README.md>)

---

### 🏗️ Aula 2 — Infraestrutura como Código com Terraform

**Conteúdo**
- O que é Infrastructure as Code
- Estrutura do Terraform: Providers, Resources, Variables, Outputs, State
- Boas práticas
- Recursos AWS: VPC, Subnet, Internet Gateway, Route Table, Security Group,
  EC2, IAM

**Prática:** criar toda a infraestrutura utilizando apenas código. Nenhum
recurso será criado manualmente pelo Console da AWS.

**Objetivo da aula:** ao executar o Terraform, toda a infraestrutura é
criada automaticamente.

📂 [Acessar material da Aula 02](<Aula 02 - Terraform/README.md>)

---

### ⚙️ Aula 3 — Provisionamento Automático dos Servidores

**Conteúdo**
- User Data e Cloud-Init
- Provisionamento automatizado e organização dos servidores
- Banco de dados gerenciado (Amazon RDS) vs. banco em container
- Dependências implícitas/explícitas no Terraform e boas práticas de
  resiliência da aplicação

**Prática:** evoluir o projeto Terraform da Aula 2 com um banco **RDS
MySQL** isolado em subnet privada e uma EC2 que se autoprovisiona via
`user_data` — instala Docker, Docker Compose, Git e Nginx, clona o
repositório de uma aplicação **React (frontend) + Node.js (API)** e
sobe tudo conectado ao RDS, sem nenhum comando manual pós-`apply`.

**Objetivo da aula:** criar uma EC2 pronta para receber aplicações sem
executar nenhum comando manual, com uma aplicação real no ar, conectada
a um banco de dados gerenciado.

📂 [Acessar material da Aula 03](<Aula 03 - Provisionamento Automatico/README.md>)

---

### 🚢 Aula 4 — ECS e Deploy Gerenciado de Containers

**Conteúdo**
- De "uma EC2 com Docker Compose" para orquestração gerenciada: por que ECS
- Conceitos: Cluster, Task Definition, Service, launch type Fargate
- Application Load Balancer e Target Groups
- Application Auto Scaling (target tracking por CPU)
- IAM Roles do ECS: execution role vs. task role

**Prática:** criar, por Terraform (aplicado manualmente pelo aluno, ainda
sem pipeline), um Cluster ECS no modo Fargate, publicar a aplicação da
Aula 3 como Task Definition + Service atrás de um Application Load
Balancer, com Auto Scaling configurado por utilização de CPU.

**Objetivo da aula:** sair do modelo "uma EC2 que roda containers" para
orquestração gerenciada com escalabilidade automática, sem administrar
servidor nenhum.

📂 [Acessar material da Aula 04](<Aula 04 - ECS e Deploy Gerenciado de Containers/README.md>)

---

### 🔄 Aula 5 — CI/CD com GitHub Actions

**Conteúdo**
- Conceitos de CI/CD
- GitHub Actions, Workflows
- Secrets e variáveis de ambiente
- Deploy automatizado no ECS (nova revisão da Task Definition + rolling
  deployment do Service)

**Prática:** pipeline completo contendo build da aplicação, build da
imagem Docker, publicação da imagem no **Amazon ECR** (o mesmo registro
provisionado na Aula 4) e atualização automática do Service criado lá —
sem precisar reconfigurar servidor nenhum.

**Recursos gratuitos:** GitHub, GitHub Actions.

**Objetivo da aula:** realizar deploy automático sempre que houver um push
na branch principal.

📂 [Acessar material da Aula 05](<Aula 05 - CI-CD com GitHub Actions/README.md>)

---

### 📊 Aula 6 — Monitoramento e Observabilidade

**Conteúdo**
- O que monitorar: métricas, logs, alarmes
- Observabilidade
- Recursos AWS: CloudWatch, Container Insights, logs do ECS/Fargate,
  métricas do Application Load Balancer, SNS

**Prática:** monitorar CPU e memória das tasks do ECS, logs dos
containers (driver `awslogs`) e métricas do Load Balancer (latência,
erros 5xx). Criar um alarme de utilização elevada de CPU com envio de
notificação por e-mail.

**Objetivo da aula:** aprender a acompanhar a saúde de uma aplicação em
produção rodando em containers gerenciados.

---

### 🎓 Aula 7 — Projeto Final (Avaliação)

**Objetivo:** avaliar, na prática e em dupla/trio, se o aluno sabe
reconstruir sozinho tudo que foi ensinado — não seguindo um passo a
passo com código pronto, mas adaptando o que aprendeu pra valores e
nomes diferentes dos usados no material.

**Formato:** atividade prática em sala, com duração de 3 a 4 horas,
sem relatório em PDF — a entrega é ao vivo: o grupo manda o link da
aplicação no ar e demonstra o Auto Scaling reagindo a uma carga real,
enquanto o professor acompanha e avalia.

**O que o grupo constrói, do zero, com CIDRs/nomes próprios**
1. Rede (VPC, subnets, Internet Gateway, Route Table).
2. Banco de dados gerenciado (RDS MySQL) em subnet privada.
3. Repositórios ECR, Cluster ECS Fargate, Task Definitions e Services.
4. Application Load Balancer com roteamento pra frontend e api.
5. Auto Scaling por CPU nos dois Services.
6. Pipeline de CI/CD (GitHub Actions) **editado** pra publicar nos
   recursos novos — a lacuna deixada de propósito na Aula 06 (nomes
   fixos no `deploy.yml`) volta aqui como parte da prova.
7. *(Bônus)* Container Insights, Dashboard e Alarme com SNS.

**Critério de avaliação:** rubrica de 10 pontos (mais 1 ponto de
bônus), cobrindo cada peça acima, funcionamento real da aplicação sob
carga e a regra de ouro do curso (nada criado manualmente pelo
Console). Detalhes completos, tabela de valores obrigatórios e a
rubrica estão no [material da Aula 07](<Aula 07 - Projeto Final/README.md>).

---

## 🧰 Ferramentas utilizadas

**AWS Academy**
- EC2, VPC, Security Groups, IAM, RDS, CloudWatch, SNS, S3 (opcional)
- ECS (Fargate), Application Load Balancer, Application Auto Scaling

**Ferramentas gratuitas**
- GitHub, GitHub Actions, GitHub Container Registry (GHCR)
- Docker, Docker Compose
- Terraform
- Nginx
- Visual Studio Code

---

## 👨‍🏫 Sobre

Disciplina ministrada na **FAEX — Faculdade de Extrema**, no curso de
Pós-Graduação em Full Stack Developer.
