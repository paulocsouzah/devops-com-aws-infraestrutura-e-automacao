# 3. Exercício 01 — Cluster ECS e Application Load Balancer

Antes de rodar qualquer container, precisamos de onde o ECS vai colocá-lo
(o Cluster) e de quem vai receber o tráfego de fora e decidir pra qual
Service mandar (o ALB). O ALB, como o RDS na Aula 03, **exige subnets em
pelo menos 2 Availability Zones** — então a rede também ganha um ajuste.

---

## 🌐 Por que mais uma subnet pública

```
┌──────────────────────────────── VPC ────────────────────────────────┐
│                                                                        │
│   AZ1                          AZ2                                    │
│   ┌─────────────────────┐      ┌─────────────────────┐               │
│   │ Subnet pública        │      │ Subnet pública (NOVA) │               │
│   │ 10.0.1.0/24            │      │ 10.0.3.0/24            │               │
│   │ (já existia — Aula 02) │      │                        │               │
│   └─────────────────────┘      └─────────────────────┘               │
│              └──────────────┬───────────────┘                         │
│                              ▼                                        │
│                    Application Load Balancer                          │
│                                                                        │
│   ┌─────────────────────┐                                            │
│   │ Subnet privada (AZ2)  │  ← RDS, sem mudança (Aula 03)             │
│   └─────────────────────┘                                            │
└────────────────────────────────────────────────────────────────────┘
```

A subnet pública nova fica na **mesma AZ2** que já usamos para a subnet
privada do RDS — não tem problema uma AZ ter mais de uma subnet. O que
importa é que o ALB tenha uma subnet **pública** em pelo menos duas AZs
diferentes.

---

## 📂 Onde trabalhar

Dentro de [`00-pratica/`](../00-pratica/README.md), crie três arquivos
novos — `network-alb.tf` (subnet pública nova e o Security Group do
ALB), `ecs-cluster.tf` (o Cluster) e `alb.tf` (o Load Balancer, os
Target Groups e as regras de roteamento) — e **edite** `variables.tf`,
adicionando a variável nova `public_subnet_b_cidr` (pode copiar direto):

```hcl
variable "public_subnet_b_cidr" {
  description = "Faixa de IPs (CIDR) da segunda subnet publica (AZ2), usada pelo ALB"
  type        = string
  default     = "10.0.3.0/24"
}
```

---

## 🧱 Subnet pública extra + Security Group do ALB

```hcl
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-b"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Libera HTTP publico para o Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-alb"
  }
}
```

> 💡 Repare que **não existe mais regra de SSH (porta 22)** em nenhum
> Security Group desta aula — não há mais servidor pra acessar.

## 🖥️ Cluster ECS

```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}
```

Sim, é só isso — no launch type Fargate, o Cluster é praticamente só um
identificador organizacional. Nenhuma instância é criada aqui.

## ⚖️ Load Balancer, Target Groups e roteamento por caminho

```hcl
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-tg-frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "api" {
  name        = "${var.project_name}-tg-api"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Regra padrao do Listener: qualquer coisa que nao bata em nenhuma regra
# mais especifica vai para o frontend.
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Regra especifica: caminhos que comecam com /api/ vao para a API,
# furando a regra padrao acima.
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
```

> 💡 **Por que `target_type = "ip"`?** Tasks Fargate não são instâncias
> EC2 registráveis por ID — cada task recebe um **IP dentro da VPC**
> (modo de rede `awsvpc`, que vamos configurar no módulo 04). Por isso o
> Target Group aponta pra IPs, não pra instâncias.

---

## 🛠️ Passo a passo

### 1. Adicionar os arquivos e aplicar

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
```

Confira: novos recursos — subnet, security group do ALB, cluster, ALB,
2 target groups, listener e a regra do listener. **Nenhuma task ainda**
— os Target Groups vão continuar "vazios" até o módulo 04.

```bash
terraform apply
```

### 2. Conferir no Console

Console da AWS → **EC2 → Load Balancers** → confirme o ALB criado, com
as duas subnets. Em **Target Groups**, confirme os dois grupos — ambos
devem aparecer **sem targets registrados** ainda (é esperado, é assunto
do próximo módulo).

---

## ✅ Checklist técnico

- [ ] Segunda subnet pública (AZ2) criada
- [ ] Security Group do ALB sem regra de SSH
- [ ] Cluster ECS criado (visível no Console, sem tasks ainda)
- [ ] ALB criado, abrangendo as duas subnets públicas
- [ ] Dois Target Groups criados (`tg-frontend`, `tg-api`)
- [ ] Listener na porta 80 com regra padrão (frontend) e regra
      específica para `/api/*` (api)

---

## 🧪 Exercício

1. Siga o passo a passo e confirme o ALB e os Target Groups no Console.
2. Por que o Cluster ECS, no launch type Fargate, não "cria" nenhum
   servidor — diferente do que aconteceria no launch type EC2?
3. Explique a diferença entre a **regra padrão** do Listener (`default_action`)
   e a **regra específica** (`aws_lb_listener_rule`, com `priority`).
   O que aconteceria se as duas tivessem a mesma prioridade?
4. **Desafio:** pesquise o que é o campo `priority` de uma
   `aws_lb_listener_rule` e por que ele precisa ser único entre as
   regras de um mesmo Listener. Depois, imagine uma terceira rota, ex.
   `/admin/*` — que prioridade relativa a `100` faria sentido pra ela
   não conflitar?

**Próximo passo:** [04-exercicio-02-task-e-service](../04-exercicio-02-task-e-service/README.md)
