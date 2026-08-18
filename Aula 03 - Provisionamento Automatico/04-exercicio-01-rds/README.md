# 4. Exercício 01 — Banco de Dados Gerenciado (RDS MySQL)

Voltamos a [`00-pratica/`](../00-pratica/README.md) para evoluí-la.
Antes de criar o banco, ela precisa de um pouco mais de rede — um RDS
exige um **DB Subnet Group** cobrindo pelo menos **duas Availability
Zones**, mesmo rodando uma única instância, sem réplica.

---

## 🌐 Por que uma segunda subnet, numa segunda AZ

```
┌────────────────────────────────── VPC (10.0.0.0/16) ──────────────────────────────────┐
│                                                                                          │
│   AZ1 (ex: us-east-1a)                        AZ2 (ex: us-east-1b)                      │
│   ┌─────────────────────────────┐            ┌─────────────────────────────┐          │
│   │  Subnet pública               │            │  Subnet privada (NOVA)       │          │
│   │  10.0.1.0/24                  │            │  10.0.2.0/24                 │          │
│   │  (EC2 mora aqui — Aula 02)     │            │  (sem rota para o IGW)       │          │
│   └─────────────────────────────┘            └─────────────────────────────┘          │
│                    │                                        │                            │
│                    └───────────────── DB Subnet Group ──────┘                            │
│                                              │                                             │
│                                              ▼                                             │
│                                    ┌────────────────────┐                                 │
│                                    │  RDS MySQL           │                                 │
│                                    │  publicly_accessible │                                 │
│                                    │  = false              │                                 │
│                                    └────────────────────┘                                 │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

- A **subnet privada nova** não tem rota para o Internet Gateway — ela
  não precisa, porque o RDS conversa só com recursos **dentro da VPC**
  (a EC2), nunca diretamente com a internet.
- O **DB Subnet Group** é só uma "lista de subnets onde o RDS tem
  permissão de existir" — a AWS exige no mínimo duas AZs aqui por
  motivos de alta disponibilidade, mesmo que a instância criada não seja
  Multi-AZ.
- `publicly_accessible = false` garante que o banco **não** recebe IP
  público — só é alcançável de dentro da VPC. Ele fica invisível para a
  internet, mesmo que alguém descubra o endpoint.

---

## 📂 Onde trabalhar

Dentro de [`00-pratica/`](../00-pratica/README.md), crie dois arquivos
novos — [`network-rds.tf`](../00-pratica/network-rds.tf) (subnet privada
e DB Subnet Group) e [`rds.tf`](../00-pratica/rds.tf) (Security Group do
banco e a instância) — e **edite** o `variables.tf` que já existe,
adicionando as variáveis novas (`availability_zone_b`,
`private_subnet_cidr`, `db_name`, `db_username`, `db_password`).

---

## 🧱 Nova subnet privada

```hcl
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = "${var.project_name}-subnet-private"
  }
}
```

Repare: **sem** `map_public_ip_on_launch` e **sem** associação com a
Route Table pública — isso é o que a torna privada.

## 🗄️ DB Subnet Group

```hcl
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}
```

## 🔒 Security Group do banco

O banco só aceita conexões na porta `3306`, e **só** vindas do Security
Group da EC2 — nunca de um CIDR aberto:

```hcl
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Permite MySQL apenas a partir da EC2 da aplicacao"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL a partir da EC2"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rds"
  }
}
```

> 💡 Repare na diferença para o Security Group da EC2 (Aula 02, módulo
> 07): lá a regra usava `cidr_blocks` (um IP ou faixa). Aqui usamos
> `security_groups` — a origem permitida **é outro Security Group**, não
> um endereço IP. Isso significa: "só aceito tráfego de quem estiver
> usando esse outro SG", não importa qual IP a EC2 tenha.

## 🗃️ A instância RDS

```hcl
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_name}-db"
  }
}
```

- `skip_final_snapshot = true` — simplificação didática, para o
  `terraform destroy` não ficar pendente de um snapshot manual ao final
  da aula. Em produção real, normalmente **não** se faz isso.
- `password = var.db_password` deve vir do seu `terraform.tfvars` (que
  já não é commitado, igual ao `my_ip` desde a Aula 02) — nunca digite a
  senha direto no `.tf`.

---

## 🛠️ Passo a passo

### 1. Adicionar os arquivos e as variáveis

Crie `network-rds.tf` e `rds.tf`, edite `variables.tf` (variáveis
novas) dentro de `00-pratica/`, e preencha `db_password` no seu
`terraform.tfvars` (`db_name` e `db_username` já têm valor padrão).

### 2. Planejar

```bash
terraform fmt
terraform validate
terraform plan
```

Confira: devem aparecer os recursos novos — subnet privada, DB subnet
group, Security Group do RDS e a instância `aws_db_instance`.

### 3. Aplicar

```bash
terraform apply
```

⏳ **Isso demora.** Diferente da EC2 (segundos), o RDS costuma levar
**5 a 10 minutos** para ficar `available`. É um bom momento para revisar
os conceitos do módulo 01 enquanto espera.

### 4. Conferir no Console

Console da AWS → **RDS → Databases** → confirme o status `Available`, a
engine (MySQL 8.0), e que **"Publicly accessible" está marcado como
No**. Confira também, em **VPC → Subnets**, que a nova subnet privada
aparece.

### 5. Manter de pé

⚠️ Não destrua ainda — o módulo 05 conecta a EC2 nesse mesmo banco.

---

## ✅ Checklist técnico

- [ ] Subnet privada criada numa AZ diferente da subnet pública
- [ ] DB Subnet Group cobrindo as duas subnets/AZs
- [ ] Security Group do RDS liberando 3306 **só** a partir do SG da EC2
- [ ] `aws_db_instance` criado, status `Available` no Console
- [ ] `publicly_accessible = false` confirmado no Console
- [ ] Senha do banco vindo de `terraform.tfvars` (não commitada)

---

## 🧪 Exercício

1. Siga o passo a passo e crie o RDS.
2. Guarde o print do Console mostrando o banco `Available` e
   "Publicly accessible: No".
3. Por que o Security Group do RDS referencia **outro Security Group**
   (`security_groups = [aws_security_group.web.id]`) em vez de um CIDR
   fixo? O que aconteceria se, no futuro, a EC2 fosse recriada com um IP
   diferente — a regra do RDS precisaria mudar?
4. **Desafio:** tente, só para observar, mudar `publicly_accessible`
   para `true` e rode `terraform plan`. O que o plan propõe (alteração
   simples ou recriação do banco)? Por que você acha que esse campo tem
   esse comportamento? Depois do teste, **volte para `false`** sem
   aplicar essa mudança.
5. Explique, com suas palavras, por que precisamos de duas subnets em
   duas AZs diferentes para o RDS, mesmo criando uma única instância
   (sem réplica, sem Multi-AZ).

**Próximo passo:** [05-exercicio-02-provisionamento-automatico](../05-exercicio-02-provisionamento-automatico/README.md)
