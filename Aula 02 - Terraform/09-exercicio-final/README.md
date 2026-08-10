# Exercício Final — terraform-aula02

Chegou a hora de juntar **tudo** o que vimos nesta aula em um projeto só,
do zero, com as suas próprias mãos.

Nos módulos anteriores você praticou cada peça isoladamente: rede (VPC,
Subnet, Internet Gateway, Route Table), Security Group e uma instância
EC2 usando o papel IAM da AWS Academy. Neste exercício final, essas
peças se juntam em **um único projeto Terraform**, criado do zero em uma
pasta separada.

A pasta [terraform-aula02/](terraform-aula02/) contém a solução completa
e comentada — use-a como gabarito se travar em algum passo, mas o
objetivo é que **você refaça cada etapa por conta própria**, na sua
máquina, digitando o código você mesmo.

---

## 🎯 O que você vai construir

Toda a infraestrutura abaixo, criada **inteiramente por código**, com um
único `terraform apply` — nenhum clique manual no Console:

```
┌──────────────────────────── VPC (10.0.0.0/16) ─────────────────────────┐
│                                                                          │
│   Internet Gateway ── Route Table (0.0.0.0/0 → IGW)                     │
│                                                                          │
│   ┌───────────────────── Subnet pública (10.0.1.0/24) ───────────────┐ │
│   │                                                                    │ │
│   │   ┌───────────────── EC2 (t2.micro) ─────────────────────────┐   │ │
│   │   │  Amazon Linux 2023                                         │   │ │
│   │   │  IAM Instance Profile: LabInstanceProfile (AWS Academy)    │   │ │
│   │   │  Security Group: SSH (meu IP) + HTTP/HTTPS (público)       │   │ │
│   │   └─────────────────────────────────────────────────────────────┘   │ │
│   └────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

- **Rede** — VPC, Subnet, Internet Gateway, Route Table (reaproveite o
  que já funcionou no módulo 06).
- **Segurança** — Security Group com SSH restrito ao seu IP e HTTP/HTTPS
  públicos (módulo 07).
- **Servidor** — EC2 com IAM Instance Profile e key pair (`vockey`) já
  existentes na AWS Academy (módulo 08).

Ou seja: este exercício não tem conteúdo novo — ele testa se você
consegue **organizar, do zero, um projeto Terraform completo**,
juntando tudo o que já funcionou em módulos separados.

---

## 🛠️ Passo a passo

### 1. Iniciar o Lab e atualizar as credenciais

Sempre o primeiro passo do dia: Start Lab → AWS Details → atualizar
`~/.aws/credentials` (veja
[03-aws-academy-e-credenciais](../03-aws-academy-e-credenciais/README.md)
se precisar relembrar). Aproveite e já baixe o `vockey.pem` (seção
"SSH key" da mesma tela) — vamos usá-lo no passo 4.

### 2. Criar a estrutura de pastas

```bash
mkdir terraform-aula02
cd terraform-aula02
```

Mova o `vockey.pem` baixado para dentro desta pasta.

```
terraform-aula02/
├── main.tf                    # terraform {} + provider "aws"
├── variables.tf                # todas as variáveis
├── network.tf                  # VPC, Subnet, IGW, Route Table
├── security-group.tf           # Security Group
├── ec2.tf                      # AMI, key pair (vockey), EC2
├── outputs.tf                  # outputs de todos os recursos
├── terraform.tfvars            # my_ip (NÃO commitar)
└── vockey.pem                   # baixado do Learner Lab (NÃO commitar)
```

### 3. Recriar os arquivos `.tf`

Use os arquivos deste módulo como referência:
[`main.tf`](terraform-aula02/main.tf),
[`variables.tf`](terraform-aula02/variables.tf),
[`network.tf`](terraform-aula02/network.tf),
[`security-group.tf`](terraform-aula02/security-group.tf),
[`ec2.tf`](terraform-aula02/ec2.tf),
[`outputs.tf`](terraform-aula02/outputs.tf).

### 4. Descobrir seu IP e criar o `terraform.tfvars`

```bash
curl https://checkip.amazonaws.com
```

Copie [`terraform.tfvars.example`](terraform-aula02/terraform.tfvars.example)
para `terraform.tfvars` e preencha com o IP retornado.

### 5. Adicionar o `.gitignore`

Use como referência o [`.gitignore`](terraform-aula02/.gitignore) deste
módulo — garante que `terraform.tfstate`, `terraform.tfvars` e a chave
`.pem` nunca sejam commitados.

### 6. Inicializar, validar e planejar

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Confira: o `plan` deve mostrar o total de recursos a criar (rede +
security group + instância — a AMI, o IAM Instance Profile e o key pair
`vockey` são `data`, apenas consultados).

### 7. Aplicar

```bash
terraform apply
```

Confirme com `yes`. Guarde os outputs, principalmente `instance_public_ip`
e `ssh_command`.

### 8. Conectar via SSH e validar

```bash
chmod 400 vockey.pem   # Linux/Mac (no Windows, o SSH já lida bem sem esse passo)
ssh -i vockey.pem ec2-user@<instance_public_ip>
```

Dentro da instância:

```bash
whoami
cat /etc/os-release
exit
```

### 9. Conferir tudo no Console

Console da AWS → confirme visualmente: VPC, Subnet, Internet Gateway,
Route Table, Security Group e a instância EC2 `running` — todos com os
nomes/tags definidos no código.

### 10. Destruir ao final

Depois de validar e coletar os prints para o relatório:

```bash
terraform destroy
```

Confirme com `yes`. Confirme no Console que tudo foi removido.

⚠️ **Não deixe recursos rodando sem necessidade** — o orçamento da AWS
Academy é compartilhado entre todas as aulas do módulo.

---

## ✅ Checklist técnico

- [ ] Pasta `terraform-aula02` criada com a estrutura de arquivos indicada
- [ ] `terraform.tfvars` criado com o seu IP (não commitado)
- [ ] `terraform init`, `fmt` e `validate` executados sem erro
- [ ] `terraform plan` sem surpresas, `terraform apply` concluído
- [ ] VPC, Subnet, IGW, Route Table, Security Group e EC2 conferidos no Console
- [ ] Conexão SSH bem-sucedida na instância
- [ ] Nenhum recurso foi criado manualmente pelo Console — tudo veio do `apply`
- [ ] `terraform destroy` executado ao final, ambiente limpo

---

## 📄 Entrega: relatório em PDF

Este exercício não termina em rodar o projeto — ele termina quando eu
recebo o seu **relatório em PDF**, documentando tudo o que você fez. É
esse PDF que eu vou usar para avaliar e lançar sua nota.

### O que o PDF precisa conter

1. **Capa** — seu nome completo e a data de entrega.
2. **Prints de tela** de, no mínimo:
   - `terraform plan` mostrando os recursos a serem criados;
   - `terraform apply` concluído, com os outputs visíveis;
   - o Console da AWS mostrando VPC, Subnet, Security Group e a
     instância EC2 `running`;
   - o terminal com a conexão SSH funcionando (prompt
     `[ec2-user@ip-... ~]$`);
   - `terraform destroy` concluído ao final.
3. **Os comandos que você executou**, na ordem, do primeiro ao último
   (pode ser em blocos de código, copiados do seu terminal).
4. **Respostas escritas, com suas próprias palavras**, para as perguntas
   de reflexão abaixo.
5. **Dificuldades encontradas** — conte pelo menos um problema real que
   você teve (erro de credencial expirada, CIDR conflitando, bucket/nome
   duplicado, erro de permissão IAM, o que for) e como você resolveu.
   Isso mostra que você realmente executou o exercício, e não só copiou
   o gabarito.

### Perguntas de reflexão (responda todas no PDF)

1. Explique, com suas próprias palavras, o papel de cada um dos quatro
   componentes de rede (VPC, Subnet, Internet Gateway, Route Table)
   usando este próprio projeto como exemplo.
2. Por que não foi possível (e nem necessário) criar um novo IAM Role
   nem um novo Key Pair para a instância EC2 nesta aula? O que foi usado
   no lugar de cada um? Essa restrição existiria em uma conta AWS real
   (fora da AWS Academy)?
3. O Security Group criado libera SSH só para o seu IP, mas HTTP/HTTPS
   para `0.0.0.0/0`. Por que essa diferença de tratamento faz sentido?
4. Se você rodasse `terraform apply` uma segunda vez, sem alterar nenhum
   arquivo `.tf`, o que aconteceria? O Terraform tentaria recriar tudo
   de novo? Justifique com base no conceito de **state**.
5. Depois de rodar `terraform destroy`, se o seu Lab expirar e você
   iniciar um novo no dia seguinte, o `terraform.tfstate` da sua máquina
   ainda faz sentido para recriar exatamente a mesma infraestrutura? O
   que muda entre uma sessão do Learner Lab e outra?

### Como gerar o PDF

Escreva o relatório em qualquer editor (Word, Google Docs, Markdown, o
que for mais confortável para você) e exporte/imprima como PDF. A
maioria dos editores tem a opção **"Salvar como PDF"** ou **"Exportar
para PDF"** no menu de arquivo.

### Prazo e envio

Envie o PDF por e-mail (ou pelo canal combinado em sala) até a data que
eu informar durante a aula. Nomeie o arquivo como
`terraform-aula02-SEUNOME.pdf`.

---

## 📊 Rubrica de avaliação

| Critério | Pontos |
|---|---|
| Rede completa criada corretamente (VPC, Subnet, IGW, Route Table) | 2,0 |
| Security Group com as regras corretas (SSH restrito, HTTP/HTTPS públicos) | 1,5 |
| EC2 criada com sucesso, usando o IAM Instance Profile da AWS Academy | 1,5 |
| Conexão SSH validada com sucesso | 1,0 |
| Nenhum recurso criado manualmente pelo Console (100% via Terraform) | 1,0 |
| Relatório completo: prints, comandos e explicações próprias | 1,5 |
| Respostas às perguntas de reflexão demonstrando entendimento real | 1,0 |
| Organização e clareza geral do PDF | 0,5 |
| **Total** | **10,0** |

Parabéns por chegar até aqui — você percorreu todo o caminho:
**conceitos de IaC → instalação → credenciais da AWS Academy → primeiros
comandos → rede → segurança → servidor → infraestrutura completa criada
por código.** Bom trabalho! 🏗️
