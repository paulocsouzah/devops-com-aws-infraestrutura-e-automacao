# 4. AWS CLI na Prática

Antes de partir para o Terraform, vamos gastar um momento só com a **AWS
CLI**, sem nenhum código `.tf` envolvido. O objetivo é duplo: primeiro,
confirmar de vez que a sua conexão com a AWS Academy está 100% funcional
(você já testou com `aws sts get-caller-identity` no módulo 03, mas aqui
vamos criar e mexer em recursos de verdade); segundo, sentir na prática a
diferença entre **CLI (imperativo)** e **Terraform (declarativo)** — o
mesmo contraste que já apareceu na pergunta 3 do exercício do módulo 01.

---

## ⌨️ Por que aprender a CLI, se o resto da aula é Terraform?

Três motivos práticos:

1. **É o "canivete suíço" do dia a dia.** Nem tudo vira Terraform — tarefas
   pontuais (subir um arquivo, olhar um log, checar se algo existe) são
   mais rápidas direto na CLI.
2. **É o que o Terraform usa por trás dos panos.** Quando o `provider
   "aws"` fala com a AWS, ele está, na prática, fazendo o mesmo tipo de
   chamada de API que a CLI faz — só que a CLI executa a ação **na hora**
   (imperativo: "faça isso agora"), enquanto o Terraform primeiro calcula
   um plano e só age se você confirmar (declarativo: "eu quero que o
   resultado final seja este").
3. **É ótima para depurar.** Quando o Terraform cria algo e você quer
   conferir rapidamente se está lá, do jeito que está, sem abrir o
   Console — um comando de CLI resolve.

---

## 🧱 Estrutura de um comando AWS CLI

```
aws <serviço> <ação> [opções]
```

- **serviço** — qual API da AWS você quer usar (`s3`, `ec2`, `iam`, `sts`...).
- **ação** — o que fazer dentro desse serviço (`ls`, `cp`, `describe-instances`...).
- **opções** — parâmetros extras (`--region`, `--output`, nomes de recursos...).

Exemplo que você já usou no módulo 03:

```bash
aws sts get-caller-identity
```
`aws` (CLI) → `sts` (serviço, Security Token Service) → `get-caller-identity` (ação).

---

## 🪣 Passo 1 — Criar um bucket S3

O S3 (**Simple Storage Service**) é o serviço de armazenamento de
arquivos da AWS — pense nele como um "HD na nuvem", organizado em
**buckets** (o equivalente a uma pasta raiz, com nome único no mundo
todo).

```bash
aws s3 mb s3://SEUNOME-aula02-cli-bucket --region us-east-1
```

Troque `SEUNOME` por algo único (seu nome, sem espaço/acento) — assim
como vimos com o Terraform no módulo 04 (agora módulo 05), nomes de
bucket S3 são globais.

Confirme que foi criado:

```bash
aws s3 ls
```

Isso lista **todos** os buckets da sua conta. O seu deve aparecer na
lista, com a data de criação.

---

## 📄 Passo 2 — Criar um arquivo local de teste

```bash
echo "Aula 02 - AWS CLI na pratica - $(date)" > relatorio-teste.txt
cat relatorio-teste.txt
```

---

## ⬆️ Passo 3 — Upload: subir o arquivo para o bucket

```bash
aws s3 cp relatorio-teste.txt s3://SEUNOME-aula02-cli-bucket/
```

`aws s3 cp` funciona como um `cp` normal do terminal, só que um dos
"lados" pode ser um caminho `s3://...` em vez de um caminho local.

Confirme que o arquivo está lá dentro do bucket:

```bash
aws s3 ls s3://SEUNOME-aula02-cli-bucket/
```

---

## ⬇️ Passo 4 — Download: baixar o arquivo de volta

Simule agora que você está em **outra máquina** e precisa baixar esse
arquivo:

```bash
aws s3 cp s3://SEUNOME-aula02-cli-bucket/relatorio-teste.txt relatorio-baixado.txt
cat relatorio-baixado.txt
```

Repare que a única coisa que mudou foi a **ordem** dos dois caminhos no
`cp` — origem e destino, exatamente como em um `cp` local
(`cp origem destino`).

> 💡 Para conferir que o conteúdo é idêntico ao original:
> ```bash
> diff relatorio-teste.txt relatorio-baixado.txt && echo "arquivos identicos"
> ```

---

## 🔄 Passo 5 — Sincronizar uma pasta inteira (`sync`)

Quando você precisa subir (ou baixar) **vários arquivos de uma vez**, em
vez de repetir `cp` para cada um, use `sync` — ele copia só o que mudou,
comparando a origem com o destino.

```bash
mkdir pasta-teste
echo "arquivo 1" > pasta-teste/arquivo1.txt
echo "arquivo 2" > pasta-teste/arquivo2.txt

aws s3 sync pasta-teste/ s3://SEUNOME-aula02-cli-bucket/pasta-teste/
```

Confirme:

```bash
aws s3 ls s3://SEUNOME-aula02-cli-bucket/pasta-teste/
```

Rode o mesmo `sync` de novo, sem mudar nada:

```bash
aws s3 sync pasta-teste/ s3://SEUNOME-aula02-cli-bucket/pasta-teste/
```

Repare que da segunda vez **nada é transferido** — o `sync` percebeu que
o destino já está igual à origem. Esse comportamento ("só mexe no que
precisa mudar") é o mesmo espírito do `terraform plan`/`apply`, que você
vai ver logo mais.

---

## 🗑️ Passo 6 — Limpar tudo (remover objeto e bucket)

Remover um arquivo específico:

```bash
aws s3 rm s3://SEUNOME-aula02-cli-bucket/relatorio-teste.txt
```

Remover o bucket **inteiro**, incluindo tudo o que ainda estiver dentro
(a flag `--force` esvazia o bucket antes de apagar):

```bash
aws s3 rb s3://SEUNOME-aula02-cli-bucket --force
```

Confirme que sumiu:

```bash
aws s3 ls
```

⚠️ Assim como no Terraform, **não deixe recursos órfãos** na sua conta
da AWS Academy — sempre limpe o que criou depois de testar.

---

## 🔍 Outros comandos úteis do dia a dia

Estes não criam nada — são só para **explorar** sua conta com segurança:

### Ver quem você é (recap do módulo 03)

```bash
aws sts get-caller-identity
```

### Listar as instâncias EC2 da conta

```bash
aws ec2 describe-instances --query 'Reservations[].Instances[].{Id:InstanceId,Estado:State.Name,Tipo:InstanceType}' --output table
```

> A flag `--query` usa a linguagem **JMESPath** para filtrar só os campos
> que interessam — sem ela, o `describe-instances` devolve um JSON
> gigante com dezenas de campos por instância. Vamos usar esse mesmo
> comando (sem o `--query`, ou adaptado) para conferir as instâncias
> criadas pelo Terraform, mais adiante na aula.

### Listar as regiões disponíveis

```bash
aws ec2 describe-regions --query 'Regions[].RegionName' --output table
```

### Ver a configuração atual da CLI

```bash
aws configure list
```

Mostra qual `profile`, região e credenciais estão ativas no momento
(sem revelar a secret key inteira — ela aparece mascarada).

### Trocar o formato de saída

Por padrão usamos `output = json` (configurado no módulo 03), mas dá para
forçar outro formato em um comando específico:

```bash
aws s3 ls --output table
aws sts get-caller-identity --output text
```

---

## 📋 Resumo rápido

| Comando | O que faz |
|---|---|
| `aws s3 mb s3://bucket` | Cria um bucket (make bucket) |
| `aws s3 ls` | Lista buckets (ou objetos dentro de um bucket) |
| `aws s3 cp origem destino` | Copia um arquivo (upload, download, ou entre buckets) |
| `aws s3 sync origem destino` | Sincroniza uma pasta inteira, só transferindo o que mudou |
| `aws s3 rm s3://bucket/arquivo` | Remove um arquivo do bucket |
| `aws s3 rb s3://bucket --force` | Remove o bucket inteiro (com `--force`, mesmo não estando vazio) |
| `aws sts get-caller-identity` | Mostra qual conta/role está autenticada |
| `aws ec2 describe-instances` | Lista instâncias EC2 da conta |
| `aws configure list` | Mostra a configuração ativa da CLI |

---

## 🧪 Exercício

1. Siga os passos 1 a 6 na ordem: crie o bucket, faça upload e download
   de um arquivo, sincronize uma pasta, e por fim remova tudo.
2. Guarde prints de: `aws s3 ls` mostrando seu bucket criado, o `aws s3
   cp` de upload, o `aws s3 cp` de download com o `cat` mostrando o
   conteúdo, e o `aws s3 ls` final confirmando que o bucket foi removido.
3. Rode `aws ec2 describe-instances` (com o `--query` do exemplo acima).
   Como você não criou nenhuma EC2 ainda, o que você espera que apareça?
   Rode e confirme.
4. Responda: no passo 5, por que o segundo `aws s3 sync` não transferiu
   nada, mesmo rodando o mesmo comando de novo? Isso lembra o
   comportamento de algum comando do Terraform que vimos no módulo 01
   (conceitos)? Qual, e por quê?
5. **Desafio:** rode `aws s3 mb` duas vezes seguidas, tentando criar o
   **mesmo** bucket que já existe. O que acontece? Compare esse
   comportamento com o que aconteceria se você rodasse `terraform apply`
   duas vezes seguidas sem mudar nada no código (você vai testar isso de
   verdade no próximo módulo) — a CLI e o Terraform reagem da mesma
   forma a "rodar de novo sem mudar nada"?

**Próximo passo:** [05-primeiros-comandos-terraform](../05-primeiros-comandos-terraform/README.md)
