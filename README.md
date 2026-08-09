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

Todas as aulas seguem o **mesmo padrão de entrega**: ao final do exercício
final, o aluno envia um **relatório em PDF** com prints das evidências,
comandos executados e respostas às perguntas de reflexão. Esse PDF é o
material usado para avaliação e lançamento de nota. Os detalhes específicos
de cada entrega (o que precisa aparecer no PDF, rubrica etc.) estão no
próprio módulo de exercício final de cada aula.

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
├── Aula 04 - CI-CD com GitHub Actions/
├── Aula 05 - Monitoramento e Observabilidade/
└── Aula 06 - Projeto Integrador/
```

## 📚 Grade do curso

| # | Aula | Tema | Status |
|---|------|------|--------|
| 1 | [Aula 01 - Docker](<Aula 01 - Docker/README.md>) | Introdução ao DevOps e Docker | ✅ Disponível |
| 2 | [Aula 02 - Terraform](<Aula 02 - Terraform/README.md>) | Infraestrutura como Código com Terraform | 🚧 Em construção |
| 3 | Aula 03 - Provisionamento Automático | User Data, Cloud-Init e deploy automatizado na EC2 | ⏳ Planejada |
| 4 | Aula 04 - CI/CD com GitHub Actions | Pipeline de build, imagem Docker e deploy automático | ⏳ Planejada |
| 5 | Aula 05 - Monitoramento e Observabilidade | CloudWatch, logs, métricas e alarmes | ⏳ Planejada |
| 6 | Aula 06 - Projeto Integrador | Projeto final integrando todo o conteúdo do módulo | ⏳ Planejada |

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
- User Data
- Cloud-Init
- Provisionamento automatizado
- Organização dos servidores

**Prática:** durante a criação da EC2, instalar automaticamente Docker,
Docker Compose, Git, Nginx e demais dependências necessárias. Após a
criação da máquina, realizar o primeiro deploy da aplicação.

**Objetivo da aula:** criar uma EC2 pronta para receber aplicações sem
executar nenhum comando manual.

---

### 🔄 Aula 4 — CI/CD com GitHub Actions

**Conteúdo**
- Conceitos de CI/CD
- GitHub Actions, Workflows
- Secrets e variáveis de ambiente
- Deploy automatizado

**Prática:** pipeline completo contendo build da aplicação, build da
imagem Docker, publicação da imagem e atualização automática da aplicação
na EC2.

**Recursos gratuitos:** GitHub, GitHub Actions, GitHub Container Registry
(GHCR).

**Objetivo da aula:** realizar deploy automático sempre que houver um push
na branch principal.

---

### 📊 Aula 5 — Monitoramento e Observabilidade

**Conteúdo**
- O que monitorar: métricas, logs, alarmes
- Observabilidade
- Recursos AWS: CloudWatch, CloudWatch Agent, SNS

**Prática:** monitorar CPU, memória, disco, logs da aplicação, logs do
Nginx e logs do Docker. Criar um alarme de utilização elevada de CPU com
envio de notificação por e-mail.

**Objetivo da aula:** aprender a acompanhar a saúde de uma aplicação em
produção.

---

### 🎓 Aula 6 — Projeto Integrador

**Objetivo:** integrar todo o conteúdo aprendido durante o módulo.

**Fluxo final**
1. Desenvolver uma nova funcionalidade.
2. Realizar commit no GitHub.
3. Executar automaticamente a pipeline.
4. Atualizar a aplicação na AWS.
5. Validar o deploy.
6. Monitorar os logs e métricas.
7. Corrigir possíveis problemas.

**Conteúdos complementares**
- Boas práticas de DevOps
- Organização de projetos e estrutura de ambientes
- Segurança e gerenciamento de segredos
- Custos na AWS
- Próximos passos para carreira DevOps

**Projeto final:** ao concluir o módulo, o aluno terá desenvolvido um
ambiente semelhante ao utilizado em empresas, contendo:

- Infraestrutura criada automaticamente com Terraform.
- Aplicação containerizada com Docker.
- Deploy automatizado utilizando GitHub Actions.
- Servidor configurado automaticamente.
- Proxy reverso com Nginx.
- Monitoramento utilizando CloudWatch.
- Pipeline completa de CI/CD.
- Projeto versionado no GitHub seguindo boas práticas de DevOps.

---

## 🧰 Ferramentas utilizadas

**AWS Academy**
- EC2, VPC, Security Groups, IAM, CloudWatch, SNS, S3 (opcional)

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
