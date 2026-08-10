# 4. Primeiros Comandos do Terraform

Com Terraform, AWS CLI e credenciais da AWS Academy configurados, vamos
criar nosso primeiro recurso de verdade na AWS — algo pequeno e barato
(um bucket S3), só para aprender o **fluxo de comandos** que vamos repetir
em toda a aula, antes de partir para redes e servidores.

---

## 📁 Criando o projeto

```bash
mkdir terraform-primeiros-comandos
cd terraform-primeiros-comandos
```

Crie um arquivo chamado `main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "teste" {
  bucket = "aula02-terraform-teste-SEUNOME" # troque SEUNOME por algo único, ex: seu nome sem espaço/acento

  tags = {
    Name = "bucket-teste-aula02"
    Aula = "02-terraform"
  }
}

output "bucket_arn" {
  description = "ARN do bucket criado"
  value       = aws_s3_bucket.teste.arn
}
```

⚠️ Nomes de bucket S3 são **globais** (únicos no mundo todo, entre todos
os clientes da AWS) — por isso pedimos para trocar `SEUNOME` por algo
que só você usaria, senão o `apply` vai falhar com erro de "bucket já
existe".

---

## 1. `terraform init`

Inicializa a pasta do projeto: baixa o plugin do `provider` (neste caso,
o plugin da AWS) e prepara o diretório `.terraform/` e o arquivo de lock
`.terraform.lock.hcl`.

```bash
terraform init
```

Rode esse comando sempre que: for a primeira vez no projeto, adicionar um
novo `provider`, ou trocar a versão de um `provider`.

---

## 2. `terraform fmt`

Formata o código `.tf` seguindo o padrão oficial de indentação/espaçamento
do Terraform — deixa o código consistente, mesmo que várias pessoas
diferentes o editem.

```bash
terraform fmt
```

---

## 3. `terraform validate`

Verifica se a sintaxe do código está correta (chaves fechadas, tipos
batendo, etc.), **sem** conectar na AWS. É um checkpoint rápido antes de
ir para o `plan`.

```bash
terraform validate
```

---

## 4. `terraform plan`

Mostra **exatamente o que vai acontecer** se você aplicar esse código —
o que será criado (`+`), alterado (`~`) ou destruído (`-`) — **sem
alterar nada de verdade ainda**.

```bash
terraform plan
```

Saída típica (resumida):

```
Terraform will perform the following actions:

  # aws_s3_bucket.teste will be created
  + resource "aws_s3_bucket" "teste" {
      + bucket = "aula02-terraform-teste-SEUNOME"
      + arn    = (known after apply)
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

💡 Sempre leia o `plan` com atenção antes de aplicar — é sua última
chance de perceber que algo está errado (por exemplo, um `destroy` de
algo que você não queria apagar).

---

## 5. `terraform apply`

Executa de verdade o que foi mostrado no `plan`: cria, atualiza ou
destrói os recursos na AWS. Pede uma confirmação (`yes`) antes de agir.

```bash
terraform apply
```

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Ao final, o Terraform mostra os `outputs` definidos (no nosso caso, o
`bucket_arn`) e salva o resultado no arquivo `terraform.tfstate`.

> 💡 Para pular a confirmação manual (útil em scripts/pipelines, **não**
> recomendado enquanto você ainda está aprendendo): `terraform apply -auto-approve`.

---

## 6. `terraform state list` e `terraform show`

Depois do `apply`, esses comandos consultam o que o Terraform sabe que
existe (lendo o `terraform.tfstate`):

```bash
terraform state list     # lista os recursos gerenciados (ex: aws_s3_bucket.teste)
terraform show            # mostra todos os detalhes/atributos de cada recurso
```

---

## 7. `terraform output`

Reexibe os valores de `output` a qualquer momento, sem precisar rodar
`apply` de novo:

```bash
terraform output
terraform output bucket_arn   # só o valor específico
```

---

## 8. `terraform destroy`

Remove **todos** os recursos gerenciados por aquele projeto Terraform —
o inverso do `apply`. Também mostra um plano antes e pede confirmação.

```bash
terraform destroy
```

⚠️ **Sempre destrua o que não estiver mais usando.** No mundo real isso
evita gastar dinheiro à toa; na AWS Academy isso evita gastar o
**orçamento limitado** do Learner Lab, que é compartilhado entre todas as
suas aulas do módulo.

---

## 📋 Fluxo de comandos (resumo)

```
terraform init        →  prepara o projeto (uma vez, ou ao mudar provider)
terraform fmt          →  formata o código
terraform validate     →  valida a sintaxe
terraform plan         →  mostra o que vai mudar (sem aplicar)
terraform apply        →  aplica de verdade (pede confirmação "yes")
terraform state list   →  lista o que o Terraform está gerenciando
terraform output       →  mostra os valores de output
terraform destroy      →  remove tudo o que foi criado por esse projeto
```

---

## 🗂️ Sobre o `terraform.tfstate` e o Git

Depois do primeiro `apply`, repare que apareceram na pasta:

- `terraform.tfstate` — o arquivo de state (visto no módulo de
  conceitos). **Nunca** deve ir para o Git — ele pode conter dados
  sensíveis dos recursos criados.
- `.terraform/` — pasta com os plugins baixados pelo `init`.
- `.terraform.lock.hcl` — trava as versões exatas dos providers usados
  (esse arquivo **pode** ir para o Git).

Crie um arquivo `.gitignore` em todo projeto Terraform:

```gitignore
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
```

---

## 🧪 Exercício

1. Crie o projeto `terraform-primeiros-comandos` com o `main.tf` acima
   (troque `SEUNOME` por algo único).
2. Rode, na ordem: `terraform init` → `terraform fmt` → `terraform
   validate` → `terraform plan`. Leia com atenção a saída do `plan` antes
   de seguir.
3. Rode `terraform apply` e confirme com `yes`. Guarde o print da saída
   com o `output` do `bucket_arn`.
4. Rode `terraform state list` e `terraform show` — confira que o bucket
   aparece com os detalhes esperados.
5. Acesse o Console da AWS (link disponível em "AWS Details", no Learner
   Lab) e confirme visualmente que o bucket existe lá — reforçando que o
   Terraform criou algo **real**, não só local.
6. Rode `terraform destroy` e confirme com `yes`. Confirme no Console que
   o bucket sumiu.
7. **Desafio:** rode `terraform apply` de novo (recriando o bucket) e, em
   seguida, edite o `main.tf` **só a tag `Name`** para outro valor. Rode
   `terraform plan` novamente — repare que o Terraform mostra uma
   alteração (`~`), não uma recriação (`-/+`). Por que alterar uma tag
   não exige destruir e recriar o bucket inteiro, mas trocar o nome do
   bucket (`bucket = "..."`) exigiria? Ao final, rode `terraform destroy`
   de novo para não deixar recurso órfão.

**Próximo passo:** [06-exercicio-01-rede](../06-exercicio-01-rede/README.md)
