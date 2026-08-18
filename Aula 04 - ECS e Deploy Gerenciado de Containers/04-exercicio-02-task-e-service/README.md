# 4. Exercício 02 — Task Definitions e Services (a EC2 sai de cena)

Este é o módulo mais simbólico da aula: a `aws_instance` que existia
desde a Aula 02 **deixa de existir no código**. No lugar dela, entram as
Task Definitions e os Services que rodam a aplicação de verdade no ECS.

---

## 🗑️ Passo 0 — remover o que não existe mais

Antes de adicionar código novo, apague (ou comente, se preferir manter
como referência histórica) de [`00-pratica/`](../00-pratica/README.md):

- `ec2.tf` — a instância, a AMI, o key pair.
- `user_data.sh.tpl` — não há mais servidor pra provisionar.
- `nginx-app.conf` — o ALB substitui o Nginx do host.
- O `resource "aws_security_group" "web"` dentro de `security-group.tf`
  (se seu arquivo tiver mais alguma coisa além disso, mantenha o resto).

E **ajuste dois arquivos que dependiam do que foi removido**:

1. **`rds.tf`** — a regra do Security Group do banco apontava para
   `aws_security_group.web.id`. Esse Security Group não existe mais;
   troque a referência para o novo `aws_security_group.ecs_tasks.id`
   (criado neste módulo):

   ```diff
     ingress {
       description     = "MySQL a partir da EC2"
       from_port       = 3306
       to_port         = 3306
       protocol        = "tcp"
   -   security_groups = [aws_security_group.web.id]
   +   security_groups = [aws_security_group.ecs_tasks.id]
     }
   ```

2. **`outputs.tf`** — remova os quatro outputs que referenciam recursos
   que não existem mais: `security_group_id` (`aws_security_group.web`),
   `instance_public_ip`, `app_url` e `ssh_command` (os três últimos
   referenciam `aws_instance.web`). No lugar deles, adicione o output
   que a aplicação vai usar daqui em diante — o DNS do ALB (criado no
   módulo 03):

   ```hcl
   output "alb_dns_name" {
     description = "DNS publico do Application Load Balancer — URL da aplicacao"
     value       = aws_lb.main.dns_name
   }
   ```

   É esse output que os próximos módulos (05 e 07) usam via
   `terraform output alb_dns_name` para acessar a aplicação.

3. **`variables.tf`** — duas variáveis da Aula 03 ficam **órfãs**, sem
   nada que as use: `my_ip` (só existia para restringir o SSH da EC2,
   que não existe mais) e `app_repo_url` (só existia para o `git clone`
   do `user_data`, que também não existe mais). Pode remover as duas —
   é um bom sinal de que a superfície de configuração da infraestrutura
   **diminuiu** junto com a complexidade operacional.

---

## 📂 Onde trabalhar

Dentro de `00-pratica/`, crie três arquivos novos —
`security-group-ecs.tf` (Security Group das tasks, liberando tráfego só
a partir do ALB), `ecs-task-definitions.tf` (as duas Task Definitions,
`frontend` e `api`, com logs no CloudWatch) e `ecs-services.tf` (os
dois ECS Services, registrados nos Target Groups do módulo 03) — e
**edite** `variables.tf`, adicionando `frontend_desired_count` e
`api_desired_count`.

---

## 🔒 Security Group das tasks

```hcl
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-sg-ecs-tasks"
  description = "Permite trafego do ALB para as tasks do ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Frontend a partir do ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "API a partir do ALB"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ecs-tasks"
  }
}
```

Repare o padrão: assim como o `sg-rds` só aceita conexão vinda do
`sg-ecs-tasks` (não de um IP), o `sg-ecs-tasks` só aceita conexão vinda
do `sg-alb`. Ninguém de fora consegue falar direto com uma task — tudo
passa pelo Load Balancer primeiro.

## 📜 Task Definitions

```hcl
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project_name}-api"
  retention_in_days = 3
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name         = "frontend"
    image        = "${aws_ecr_repository.frontend.repository_url}:latest"
    essential    = true
    portMappings = [{ containerPort = 80, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "frontend"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name         = "api"
    image        = "${aws_ecr_repository.api.repository_url}:latest"
    essential    = true
    portMappings = [{ containerPort = 4000, protocol = "tcp" }]
    environment = [
      { name = "DB_HOST", value = aws_db_instance.main.address },
      { name = "DB_PORT", value = tostring(aws_db_instance.main.port) },
      { name = "DB_NAME", value = var.db_name },
      { name = "DB_USER", value = var.db_username },
      { name = "DB_PASSWORD", value = var.db_password },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "api"
      }
    }
  }])
}
```

> 💡 Repare que a variável de ambiente `DB_HOST` vem direto de
> `aws_db_instance.main.address` — **a mesma dependência implícita** que
> vimos no `user_data` da Aula 03 (módulo 06). O Terraform continua
> criando a Task Definition da API só depois do RDS existir.

> 💡 **`data.aws_iam_role` em vez de `data.aws_iam_instance_profile`:**
> a EC2 (Aula 03) usava um *Instance Profile* (um "invólucro" em volta de
> uma Role, específico pra EC2). O ECS usa a Role **diretamente** — daí o
> data source diferente, apontando pro mesmo `LabRole` de sempre.

## 🚀 ECS Services

```hcl
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.main]
}

resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 4000
  }

  depends_on = [aws_lb_listener.main]
}
```

> 💡 `assign_public_ip = true` porque as tasks estão em subnets
> **públicas** (sem NAT Gateway nesta aula — evita mais um recurso pago
> rodando o tempo todo). Cada task recebe um IP público só pra
> conseguir puxar a imagem do ECR e mandar logs — o tráfego de entrada
> real continua controlado pelo Security Group, só aceitando o ALB.

---

## 🛠️ Passo a passo

### 1. Remover o antigo, ajustar as referências, adicionar o novo

Siga o "Passo 0" no topo deste módulo, depois crie os três arquivos
novos dentro de `00-pratica/`.

### 2. Planejar e aplicar

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
```

Confira no `plan`: a `aws_instance.web` deve aparecer para ser
**destruída** (`-`), e os novos recursos (Security Group, 2 Task
Definitions, 2 Services, 2 Log Groups) para serem **criados** (`+`).

```bash
terraform apply
```

### 3. Acompanhar os Services subindo

```bash
aws ecs describe-services --cluster aula04-cluster --services aula04-frontend aula04-api \
  --query "services[].{Nome:serviceName,Rodando:runningCount,Desejado:desiredCount}" --output table
```

Espere `Rodando` chegar no mesmo valor de `Desejado` para os dois.

### 4. Validar no navegador

Pegue o DNS do ALB:

```bash
terraform output alb_dns_name
```

Acesse `http://<alb_dns_name>/` — deve aparecer o frontend em React.
Cadastre um usuário: a chamada vai em `/api/usuarios`, que o ALB roteia
pro Service `api`, que conecta no RDS.

---

## ✅ Checklist técnico

- [ ] `ec2.tf`, `user_data.sh.tpl`, `nginx-app.conf` removidos
- [ ] `rds.tf` atualizado para referenciar `sg-ecs-tasks`
- [ ] `outputs.tf` sem os outputs que dependiam da EC2, com `alb_dns_name` adicionado
- [ ] Duas Task Definitions criadas, referenciando as imagens do ECR
- [ ] Dois Services `RUNNING`, com `runningCount == desiredCount`
- [ ] Os dois Target Groups do módulo 03 agora mostram targets saudáveis
- [ ] Aplicação acessível pelo DNS do ALB, `/` e `/api/usuarios`
      funcionando

---

## 🧪 Exercício

1. Siga o passo a passo e valide a aplicação completa pelo DNS do ALB.
2. Guarde prints: o `terraform plan` mostrando a EC2 sendo destruída e
   os recursos novos sendo criados; os dois Services `RUNNING`; a
   aplicação funcionando no navegador.
3. Por que a variável de ambiente `DB_HOST` da Task Definition da API
   consegue "ver" o endereço do RDS sem você digitar nada manualmente?
4. O que aconteceria se você esquecesse de atualizar o `rds.tf` (Passo
   0) e deixasse a referência antiga a `aws_security_group.web.id`? Qual
   seria a mensagem de erro do `terraform plan`?
5. **Desafio:** repare que os dois Services usam exatamente as mesmas
   subnets. Isso significa que uma task do `frontend` e uma task da
   `api` podem, tecnicamente, cair na mesma AZ? Isso é um problema para
   a disponibilidade da aplicação? Justifique.

**Próximo passo:** [05-exercicio-03-auto-scaling](../05-exercicio-03-auto-scaling/README.md)
