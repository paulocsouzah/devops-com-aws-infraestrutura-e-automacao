# 1. Conceitos de Terraform

Antes de instalar qualquer coisa, precisamos entender **por que** existe
uma ferramenta como o Terraform e **como** ela organiza o código que
descreve uma infraestrutura.

---

## 🧱 O que é Infrastructure as Code (IaC)

> Infraestrutura descrita em arquivos de texto, não criada no clique do mouse.

**Infrastructure as Code (IaC)** é a prática de descrever servidores,
redes, bancos de dados e qualquer outro recurso de infraestrutura em
**arquivos de código**, em vez de criá-los manualmente clicando em um
painel (Console). Esses arquivos são versionados no Git, revisados em
Pull Request e executados por uma ferramenta que lê o código e cria (ou
atualiza, ou destrói) os recursos de verdade na nuvem.

### Por que isso importa?

Pense na diferença entre as duas abordagens:

| Console (manual) | IaC (código) |
|---|---|
| Você clica em "Create VPC", preenche campos, clica em "Create Subnet"... | Você escreve `resource "aws_vpc" "main" { ... }` |
| Ninguém sabe exatamente o que foi clicado nem em que ordem | O `git log` mostra exatamente quem mudou o quê e quando |
| Recriar o ambiente do zero = repetir tudo manualmente, de novo | Recriar o ambiente = `terraform apply` |
| Fácil esquecer um passo, ou configurar algo diferente em cada ambiente | O mesmo código gera o mesmo resultado sempre (ambientes consistentes) |
| Difícil revisar/aprovar antes de aplicar em produção | O `terraform plan` mostra exatamente o que vai mudar, antes de mudar |

Analogia: criar infraestrutura pelo Console é como montar um móvel sem
manual, de memória, toda vez. IaC é ter o manual de instruções escrito —
qualquer pessoa (ou você, seis meses depois) consegue montar o mesmo móvel
exatamente igual.

### Vantagens práticas do IaC

- **Reprodutibilidade** — o mesmo código cria o mesmo ambiente em
  desenvolvimento, homologação e produção.
- **Versionamento** — o histórico de mudanças da infraestrutura vive no
  Git, junto com o código da aplicação.
- **Revisão** — mudanças de infraestrutura podem passar por Pull Request,
  igual a uma mudança de código.
- **Automação** — a criação de infraestrutura pode entrar em uma pipeline
  de CI/CD (assunto da Aula 4).
- **Documentação viva** — o próprio código `.tf` documenta o que existe no
  ambiente, sem depender de alguém lembrar ou anotar em algum lugar.

---

## 🌍 O que é o Terraform

O **Terraform** (da HashiCorp) é a ferramenta de IaC mais usada do
mercado. Ele é **declarativo**: você descreve o **estado final** que
deseja ("quero uma VPC com este CIDR, uma subnet dentro dela e uma EC2
nessa subnet"), e o Terraform calcula sozinho **o que precisa criar,
atualizar ou destruir** para chegar nesse estado — você não escreve o
passo a passo, só o resultado desejado.

É uma ferramenta **multi-cloud**: o mesmo Terraform que cria recursos na
AWS também cria na Azure, Google Cloud, e em dezenas de outros
provedores — o que muda é qual **provider** você usa (mais sobre isso
abaixo). Nesta aula usamos exclusivamente a **AWS**, via **AWS Academy**.

---

## 🧩 Estrutura do Terraform

Um projeto Terraform é organizado em blocos escritos em **HCL**
(HashiCorp Configuration Language), uma linguagem declarativa própria,
pensada para ser legível mesmo por quem não programa. Os blocos mais
importantes são:

### 1. Provider

> Diz **com qual nuvem** o Terraform vai falar.

O `provider` configura qual serviço/API o Terraform vai usar para criar
os recursos — no nosso caso, a AWS.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

O Terraform baixa um **plugin** do provider (na primeira vez que você
roda `terraform init`) que sabe como conversar com a API daquele serviço.

### 2. Resource

> O bloco mais importante: **descreve um recurso** que deve existir.

Cada `resource` representa uma peça real de infraestrutura — uma VPC, uma
subnet, uma instância EC2, um Security Group, etc.

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-aula02"
  }
}
```

A sintaxe é sempre: `resource "<tipo>" "<nome_local>" { ... }`.

- **tipo** (`aws_vpc`) — definido pelo provider, identifica que tipo de
  recurso da AWS será criado.
- **nome_local** (`main`) — um apelido **só dentro do Terraform**, usado
  para referenciar esse recurso em outros lugares do código (ex:
  `aws_vpc.main.id`). Não aparece na AWS.

### 3. Variables

> Deixam o código **reutilizável e configurável**, sem valores fixos
> espalhados pelo meio dos `resource`.

```hcl
variable "vpc_cidr" {
  description = "Faixa de IPs da VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

E usamos com `var.<nome>`:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}
```

### 4. Outputs

> Expõem valores depois que o Terraform termina de criar os recursos —
> úteis para consultar rapidamente (ex: o IP público da EC2 criada) ou
> para conectar com outros módulos/ferramentas.

```hcl
output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}
```

Depois de um `terraform apply`, o valor aparece direto no terminal, e
pode ser consultado a qualquer momento com `terraform output`.

### 5. State

> O "mapa" que o Terraform mantém entre a sua descrição de código e os
> recursos que **realmente existem** na AWS.

Toda vez que você roda `terraform apply`, o Terraform salva o resultado
em um arquivo `terraform.tfstate` (JSON). É esse arquivo que permite ao
Terraform saber, da próxima vez, o que já existe, o que mudou no seu
código e o que precisa ser criado/atualizado/destruído — sem esse
arquivo, o Terraform "esquece" o que ele mesmo criou.

⚠️ Por isso o `terraform.tfstate` **nunca** deve ser editado manualmente
nem apagado por acidente — e em times reais, ele fica guardado em um
lugar remoto e compartilhado (ex: bucket S3), não só na máquina de uma
pessoa. Nesta aula, por sermos ambiente individual de estudo, vamos
trabalhar com **state local** mesmo (o arquivo fica na sua pasta) — mas
já vale saber que isso é uma simplificação didática.

---

## ✅ Boas práticas

Algumas práticas que vamos seguir (e que valem para qualquer projeto
Terraform no mercado):

1. **Nunca crie recursos manualmente pelo Console** quando o objetivo é
   IaC — se você clicar em algo manualmente, o Terraform não sabe que
   aquilo existe, e isso gera divergência entre código e realidade.
2. **Sempre rode `terraform plan` antes de `terraform apply`** — o
   `plan` mostra exatamente o que vai ser criado/alterado/destruído,
   *antes* de qualquer mudança real acontecer.
3. **Use variáveis** em vez de valores fixos ("hardcoded") espalhados
   pelo código — facilita reutilizar o mesmo código em outro contexto.
4. **Dê nomes e tags descritivos** aos recursos (`Name = "vpc-aula02"`)
   — em uma conta AWS com dezenas de recursos, tags são o que permite
   identificar rapidamente o que é o quê.
5. **Organize o código em arquivos separados por responsabilidade**
   (`main.tf`, `variables.tf`, `outputs.tf`) em vez de um único arquivo
   gigante — vamos adotar essa convenção a partir do módulo de
   primeiros comandos.
6. **Sempre rode `terraform destroy`** ao final do estudo/exercício,
   quando os recursos não forem mais necessários — isso evita consumir
   sem necessidade o orçamento (budget) limitado da AWS Academy.

---

## 📝 Resumo visual

| Bloco | Para que serve | Exemplo |
|---|---|---|
| `provider` | Diz com qual nuvem falar | `provider "aws" { region = "us-east-1" }` |
| `resource` | Descreve um recurso a ser criado | `resource "aws_vpc" "main" { ... }` |
| `variable` | Parametriza valores reutilizáveis | `variable "vpc_cidr" { ... }` |
| `output` | Exibe valores após o `apply` | `output "vpc_id" { value = aws_vpc.main.id }` |
| `state` | Mapa entre o código e o que existe de verdade na AWS | `terraform.tfstate` |

---

## 🧪 Exercício

Antes de instalar qualquer coisa, fixe os conceitos com a cabeça, não
com o teclado. Responda por escrito (você vai reaproveitar isso mais
adiante, no relatório final):

1. Com suas próprias palavras, explique a diferença entre criar
   infraestrutura **pelo Console** e criar infraestrutura **com
   Terraform**. Cite pelo menos uma vantagem prática do IaC que faça
   sentido para você.
2. O que aconteceria se você criasse uma VPC manualmente pelo Console
   da AWS, e depois rodasse `terraform apply` com um código que também
   descreve uma VPC? Elas seriam "a mesma coisa" para o Terraform?
   Justifique usando o conceito de **state**.
3. Por que o Terraform é considerado **declarativo** (você diz o que
   quer, não como fazer)? Compare rapidamente com a ideia de escrever um
   script que executa comandos `aws` um por um, em ordem (isso seria
   *imperativo*).
4. Qual a diferença entre o **nome local** de um `resource`
   (ex: `aws_vpc.main`) e o **nome/tag** que aparece dentro da AWS
   (ex: `Name = "vpc-aula02"`)? Por que os dois existem?

**Próximo passo:** [02-instalacao-terraform-e-aws-cli](../02-instalacao-terraform-e-aws-cli/README.md)
