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

## 📂 Arquivos deste módulo

- [`main.tf`](main.tf) — os 5 recursos (VPC, Subnet, IGW, Route Table,
  associação), comentados.
- [`variables.tf`](variables.tf) — CIDRs, região e AZ parametrizados.
- [`outputs.tf`](outputs.tf) — IDs dos recursos criados, para conferência.

Use esses arquivos como referência/gabarito, mas **crie a sua própria
pasta e digite o código você mesmo** — é digitando que o conteúdo fixa.

---

## 🛠️ Passo a passo

### 1. Criar o projeto

```bash
mkdir terraform-rede
cd terraform-rede
```

Recrie os três arquivos (`main.tf`, `variables.tf`, `outputs.tf`) com o
conteúdo deste módulo.

### 2. Inicializar e validar

```bash
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
seguinte (EC2). Deixe o projeto `terraform-rede` como está, vamos voltar
a ele.

---

## ✅ Checklist técnico

- [ ] `terraform-rede/` criado com os 3 arquivos `.tf`
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

**Próximo passo:** [06-exercicio-02-security-group](../06-exercicio-02-security-group/README.md)
