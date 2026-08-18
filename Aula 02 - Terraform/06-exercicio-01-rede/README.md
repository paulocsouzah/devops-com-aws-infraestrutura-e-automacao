# 5. Exercício 01 — Rede (VPC, Subnet, Internet Gateway, Route Table)

Antes de subir um servidor, ele precisa de um "endereço" dentro da AWS —
e esse endereço mora dentro de uma rede que **nós** vamos desenhar por
código. Este é o primeiro dos três blocos de infraestrutura que, juntos,
formam o exercício final desta aula.

---

## 🌐 Os quatro conceitos de rede desta aula

```
Internet
   │
   ▼
┌──────────────────────── Internet Gateway ────────────────────────┐
│                                                                     │
│  ┌───────────────────────────── VPC (10.0.0.0/16) ──────────────┐ │
│  │                                                                │ │
│  │   ┌──────────────── Subnet pública (10.0.1.0/24) ─────────┐  │ │
│  │   │                                                          │  │ │
│  │   │              (aqui vai morar a EC2, na Aula 07)          │  │ │
│  │   │                                                          │  │ │
│  │   └──────────────────────────────────────────────────────────┘  │ │
│  │                                                                │ │
│  │   Route Table: "0.0.0.0/0 → Internet Gateway"                 │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

- **VPC (Virtual Private Cloud)** — sua rede privada isolada dentro da
  AWS. Tudo o que criamos nesta aula vive dentro dela. Definida por um
  bloco CIDR (`10.0.0.0/16` = mais de 65 mil IPs possíveis).
- **Subnet** — uma "sub-rede" dentro da VPC, associada a uma
  **Availability Zone** (um data center específico da AWS). A nossa é
  `10.0.1.0/24` (256 IPs), marcada como pública.
- **Internet Gateway (IGW)** — o componente que conecta a VPC à internet.
  Sem ele, nada dentro da VPC troca tráfego com o mundo externo, mesmo
  tendo IP público.
- **Route Table** — a "tabela de rotas" associada à subnet, dizendo para
  onde vai o tráfego. A rota `0.0.0.0/0 → Internet Gateway` é o que torna
  a subnet **pública** de fato (sem essa rota associada, ela seria
  privada, mesmo com um IGW existindo na VPC).

> 💡 O que faz uma subnet ser "pública" não é só o `map_public_ip_on_launch
> = true` — é a combinação de: IP público na instância **+** rota
> `0.0.0.0/0` apontando para um Internet Gateway **+** Security Group
> liberando o tráfego (assunto do próximo módulo).

---

## 📂 Onde trabalhar

A partir de agora, todo o código desta aula vive em
[`00-pratica/`](../00-pratica/README.md) — é lá que você vai criar os
arquivos abaixo, digitando o código você mesmo (é digitando que o
conteúdo fixa):

- `main.tf` — bloco `terraform {}` + `provider "aws"`.
- `network.tf` — os 5 recursos de rede (VPC, Subnet, IGW, Route Table,
  associação), comentados.
- `variables.tf` — CIDRs, região e AZ parametrizados.
- `outputs.tf` — IDs dos recursos criados, para conferência.

```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

```hcl
# network.tf
# 1. VPC — a "rede privada" onde tudo o mais vai morar dentro
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Subnet pública — sub-rede dentro da VPC, associada a uma AZ específica.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public"
  }
}

# 3. Internet Gateway — "porta de saída" da VPC para a internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 4. Route Table — "qualquer destino que eu não souber, manda para o IGW".
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# 5. Associação — liga a Route Table à subnet pública.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

```hcl
# variables.tf
variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability Zone onde a subnet pública será criada"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "Faixa de IPs (CIDR) da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Faixa de IPs (CIDR) da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "project_name" {
  description = "Prefixo usado no nome/tags de todos os recursos deste projeto"
  type        = string
  default     = "aula02"
}
```

```hcl
# outputs.tf
output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID da subnet pública criada"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway criado"
  value       = aws_internet_gateway.main.id
}

output "route_table_id" {
  description = "ID da Route Table pública criada"
  value       = aws_route_table.public.id
}
```

---

## 🛠️ Passo a passo

### 1. Criar os arquivos

Dentro de `00-pratica/`, crie os quatro arquivos (`main.tf`,
`network.tf`, `variables.tf`, `outputs.tf`) com o conteúdo acima.

### 2. Inicializar e validar

```bash
cd 00-pratica
terraform init
terraform fmt
terraform validate
```

### 3. Planejar

```bash
terraform plan
```

Confira na saída: devem aparecer **5 recursos a serem criados** (`Plan: 5
to add, 0 to change, 0 to destroy`). Se aparecer um número diferente,
releia o `main.tf` antes de continuar.

### 4. Aplicar

```bash
terraform apply
```

Confirme com `yes`. Ao final, os 4 `outputs` (`vpc_id`, `subnet_id`,
`internet_gateway_id`, `route_table_id`) aparecem no terminal.

### 5. Conferir no Console

Abra o Console da AWS (link em "AWS Details" no Learner Lab) → **VPC** →
confirme visualmente que a VPC, a subnet, o Internet Gateway e a Route
Table aparecem lá, com os nomes das tags que você definiu.

### 6. Manter de pé (por enquanto!)

⚠️ **Não rode `terraform destroy` ainda neste módulo** — vamos
reaproveitar essa rede no próximo exercício (Security Group) e no
seguinte (EC2). Deixe `00-pratica/` como está, vamos voltar a ela.

---

## ✅ Checklist técnico

- [ ] `main.tf`, `network.tf`, `variables.tf` e `outputs.tf` criados em `00-pratica/`
- [ ] `terraform init`, `fmt` e `validate` executados sem erro
- [ ] `terraform plan` mostra 5 recursos a criar
- [ ] `terraform apply` concluído com sucesso, outputs exibidos
- [ ] VPC, Subnet, IGW e Route Table conferidos no Console da AWS

---

## 🧪 Exercício

1. Siga o passo a passo acima e crie a rede.
2. Guarde o print do `terraform apply` (com os 4 outputs visíveis) — vai
   precisar disso no exercício final.
3. No Console, clique na Route Table criada e veja a aba de rotas.
   Responda: quantas rotas aparecem lá, e o que cada uma faz? (dica:
   toda Route Table nasce com uma rota "local" automática, além da que
   você adicionou).
4. **Desafio:** troque o valor de `public_subnet_cidr` para
   `10.0.5.0/24` e rode `terraform plan`. O Terraform propõe **alterar**
   a subnet existente ou **destruir e recriar** ela (`-/+`)? Por que você
   acha que o CIDR de uma subnet exige esse comportamento, diferente da
   tag `Name` que vimos no módulo anterior? Depois de responder, **volte
   o valor para `10.0.1.0/24`** (não aplique essa mudança — é só para
   observar o `plan`).

**Próximo passo:** [07-exercicio-02-security-group](../07-exercicio-02-security-group/README.md)
