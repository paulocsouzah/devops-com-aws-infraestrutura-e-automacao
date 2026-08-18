# Exercício Final — terraform-aula04

Chegou a hora de fechar a aula validando, de ponta a ponta, o projeto que
você já vem construindo desde o módulo 02.

Nos módulos anteriores você praticou cada peça isoladamente: imagens no
ECR (módulo 02), Cluster e ALB (módulo 03), Task Definitions e Services
substituindo a EC2 (módulo 04) e Auto Scaling (módulo 05). Diferente de
outras aulas, aqui **não tem nada novo pra construir** —
[`00-pratica/`](../00-pratica/README.md) já contém o projeto inteiro.
Este módulo é sobre **rodar de verdade, do zero, e documentar**.

---

## 🎯 O que você vai construir

```
┌────────────────────────────────── VPC (10.0.0.0/16) ──────────────────────────────────┐
│                                                                                           │
│   Internet Gateway ── Route Table (0.0.0.0/0 → IGW)                                     │
│                                                                                           │
│   ┌────── Subnet pública AZ1 ──────┐  ┌────── Subnet pública AZ2 (NOVA) ──────┐         │
│   │                                  │  │                                        │         │
│   │      Application Load Balancer ("/" → tg-frontend | "/api/*" → tg-api)      │         │
│   │                                  │  │                                        │         │
│   │  ECS Service: frontend           │  │  ECS Service: api                      │         │
│   │  (Fargate, Auto Scaling 1-3)     │  │  (Fargate, Auto Scaling 1-3)           │         │
│   └────────────────────────────────┘  └──────────────────────────────────────┘         │
│                                                              │ 3306                        │
│                                                              ▼                             │
│                                          ┌────── Subnet privada AZ2 ──────┐                │
│                                          │  RDS MySQL 8.0 (Aula 03,        │                │
│                                          │  sem mudança nenhuma)           │                │
│                                          └────────────────────────────────┘                │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

- **Rede** — a mesma VPC da Aula 03, mais uma subnet pública (AZ2) para
  o ALB (módulo 03).
- **Imagens** — `frontend` e `api` publicadas no ECR (módulo 02), a
  partir do mesmo código-fonte `app-aula03`.
- **Orquestração** — Cluster ECS Fargate, duas Task Definitions, dois
  Services, cada um atrás do seu Target Group no ALB (módulos 03 e 04).
- **Escalabilidade** — Application Auto Scaling por CPU, independente
  para cada Service (módulo 05).
- **Banco** — o mesmo RDS da Aula 03, só com o Security Group
  reapontado para as tasks do ECS (módulo 04).
- **O que não existe mais** — a EC2, o User Data, o Nginx do host, a
  chave SSH.

---

## 🛠️ Passo a passo

### 1. Preparar o ambiente

Inicie o Lab, atualize as credenciais (`~/.aws/credentials`) e confirme
que o Docker está rodando na sua máquina.

### 2. Conferir se `00-pratica/` está completa

```
00-pratica/
├── main.tf                    # terraform {} + provider "aws"
├── variables.tf                # todas as variáveis (sem my_ip/app_repo_url)
├── network.tf                  # VPC, Subnet pública AZ1, IGW, Route Table
├── network-alb.tf              # Subnet pública AZ2 + Security Group do ALB
├── network-rds.tf              # Subnet privada + DB Subnet Group
├── security-group-ecs.tf       # Security Group das tasks
├── rds.tf                       # Security Group do RDS (apontando pro sg-ecs-tasks) + aws_db_instance
├── ecr.tf                       # Dois repositórios ECR
├── ecs-cluster.tf               # Cluster ECS
├── alb.tf                       # Load Balancer + Target Groups + listener rules
├── ecs-task-definitions.tf     # Task Definitions (frontend, api)
├── ecs-services.tf              # ECS Services
├── autoscaling.tf                # Auto Scaling (CPU + memória)
├── dashboard.js                  # gerador de carga + dashboard ao vivo
├── outputs.tf                    # outputs de todos os recursos
└── terraform.tfvars              # só db_password (NÃO commitar)
```

Não deve existir mais `ec2.tf`, `user_data.sh.tpl`, `nginx-app.conf` nem
`vockey.pem` — se algum ainda estiver lá, volte ao módulo 04.

### 3. Conferir credenciais e `terraform.tfvars`

O Lab pode ter expirado desde a última sessão — atualize
`~/.aws/credentials` e confirme que `terraform.tfvars` tem `db_password`
preenchido.

### 4. Inicializar, validar e aplicar

```bash
cd 00-pratica
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### 5. Publicar as imagens no ECR

Depois do `apply` (os repositórios ECR já existem), siga o módulo 02
para autenticar o Docker, buildar e enviar as duas imagens do
`app-aula03`.

### 6. Forçar os Services a pegarem a imagem publicada

Se os Services já tinham sido criados antes das imagens existirem no
ECR, force uma nova tentativa de deploy:

```bash
aws ecs update-service --cluster aula04-cluster --service aula04-frontend --force-new-deployment
aws ecs update-service --cluster aula04-cluster --service aula04-api --force-new-deployment
```

### 7. Validar a aplicação

```bash
terraform output alb_dns_name
```

Acesse `http://<alb_dns_name>/` no navegador, cadastre um usuário,
confirme que aparece na lista (prova de que o caminho completo — ALB →
frontend / ALB → api → RDS — está funcionando). Repare no quadradinho
"Atendido por: ..." — é o hostname da task que respondeu.

### 8. Testar o Load Balancing e o Auto Scaling

Siga o módulo 05 na íntegra: force duas tasks da api
(`aws ecs update-service --desired-count 2`) e veja `/api/status`
alternar entre instâncias; depois volte ao mínimo e rode o
`dashboard.js` — ele gera carga real via `/api/stress` e mostra, ao
vivo, o Load Balancer distribuindo e o `desiredCount` subindo sozinho.
Espere uns 5 minutos de carga antes de esperar o scale-out — o Auto
Scaling não é instantâneo, ele espera confirmação sustentada antes de
agir.

### 9. Destruir ao final

```bash
terraform destroy
```

⚠️ **Não deixe o ALB nem as tasks Fargate rodando sem necessidade** —
os dois cobram por hora, mesmo sem tráfego.

---

## ✅ Checklist técnico

- [ ] `00-pratica/` completa, sem `ec2.tf`, `user_data.sh.tpl` nem `nginx-app.conf`
- [ ] `rds.tf` apontando para `aws_security_group.ecs_tasks`
- [ ] Duas imagens publicadas no ECR
- [ ] `terraform apply` concluído sem erro
- [ ] Dois Services `RUNNING`, com targets saudáveis nos dois Target Groups
- [ ] Aplicação acessível pelo DNS do ALB, cadastro de usuário validado
      ponta a ponta
- [ ] Auto Scaling testado: `desiredCount` da API subiu sozinho sob carga
- [ ] Nenhum SSH, nenhuma chave `.pem`, nenhum comando manual num servidor
- [ ] `terraform destroy` executado ao final, ambiente limpo

---

## 📄 Entrega: relatório em PDF

### O que o PDF precisa conter

1. **Capa** — seu nome completo e a data de entrega.
2. **Prints de tela** de, no mínimo:
   - `terraform plan` mostrando a EC2 sendo destruída e os recursos do
     ECS sendo criados;
   - as duas imagens publicadas no ECR (`aws ecr describe-images`);
   - os dois Services `RUNNING` (`aws ecs describe-services`);
   - os Target Groups do ALB com targets saudáveis;
   - a aplicação funcionando no navegador, com pelo menos um usuário
     cadastrado;
   - o `desiredCount` da API subindo durante o teste de carga do
     módulo 05;
   - `terraform destroy` concluído ao final.
3. **Os comandos que você executou**, na ordem.
4. **Respostas escritas, com suas próprias palavras**, para as perguntas
   de reflexão abaixo.
5. **Dificuldades encontradas** — pelo menos um problema real e como
   resolveu.

### Perguntas de reflexão (responda todas no PDF)

1. Compare, com suas próprias palavras, o "dia de operação" de uma
   aplicação rodando na EC2 da Aula 03 com o dia de operação da mesma
   aplicação no ECS desta aula. O que ficou mais simples? O que ficou
   mais complexo?
2. Por que a Task Definition da API não builda a imagem — de onde ela
   vem, e em qual módulo/passo essa imagem foi criada?
3. Explique o papel do Application Load Balancer no roteamento entre o
   frontend e a API. Como ele decide pra qual dos dois mandar uma
   requisição?
4. O que aconteceu com o Security Group `sg-web` e com as variáveis
   `my_ip` e `app_repo_url` da Aula 03? Por que eles deixaram de fazer
   sentido nesta aula?
5. Descreva o que você observou durante o teste de Auto Scaling: quanto
   tempo levou até o `desiredCount` subir? E até voltar ao normal depois
   de parar a carga?
6. Se você quisesse atualizar a aplicação para uma nova versão sem
   tirar ela do ar, o que mudaria no seu fluxo de trabalho comparado à
   Aula 03 (onde a EC2 inteira era recriada quando o `user_data`
   mudava)?

### Prazo e envio

Envie o PDF por e-mail (ou pelo canal combinado em sala) até a data que
eu informar durante a aula. Nomeie o arquivo como
`terraform-aula04-SEUNOME.pdf`.

---

## 📊 Rubrica de avaliação

| Critério | Pontos |
|---|---|
| ECR: duas imagens publicadas corretamente | 1,0 |
| Cluster, ALB e Target Groups configurados corretamente | 1,5 |
| Task Definitions e Services criados, RDS reapontado corretamente | 2,0 |
| Aplicação funcionando ponta a ponta pelo ALB (frontend + `/api/*`) | 2,0 |
| Auto Scaling configurado e testado com carga real | 1,5 |
| Nenhum recurso criado manualmente pelo Console (100% via Terraform) | 1,0 |
| Relatório completo: prints, comandos e explicações próprias | 0,5 |
| Respostas às perguntas de reflexão demonstrando entendimento real | 0,5 |
| **Total** | **10,0** |

Parabéns por chegar até aqui — sua aplicação agora roda sem um único
servidor pra você administrar, se recupera sozinha de falhas e escala
sozinha conforme a demanda. É exatamente esse tipo de infraestrutura que
times de plataforma mantêm em produção no mercado. 🚢
