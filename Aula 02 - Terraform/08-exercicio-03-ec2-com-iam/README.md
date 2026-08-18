# 7. Exercício 03 — EC2 com Papel IAM e Key Pair da AWS Academy

Rede pronta, porta liberada — agora vamos finalmente subir um **servidor**
dentro dessa rede, usando o papel de IAM e o par de chaves que já vêm
prontos na AWS Academy. Continuamos na mesma pasta
[`00-pratica/`](../00-pratica/README.md).

---

## 🖥️ O que vamos criar

- Uma **AMI** (Amazon Machine Image) do Amazon Linux 2023, buscada
  dinamicamente (sempre a versão mais recente).
- Uma **instância EC2**, dentro da subnet pública do módulo 06, protegida
  pelo Security Group do módulo 07.
- Um **IAM Instance Profile** e uma **key pair (SSH)** — nenhum dos dois
  criado por nós: **reaproveitados** do que já existe na AWS Academy
  (`LabInstanceProfile` e `vockey`, respectivamente).

```
┌────────────────── Subnet pública (10.0.1.0/24) ──────────────────┐
│                                                                    │
│   ┌───────────────────── EC2 (t2.micro) ─────────────────────┐   │
│   │  AMI: Amazon Linux 2023                                    │   │
│   │  IAM Instance Profile: LabInstanceProfile (já existente)   │   │
│   │  Key Pair: vockey (já existente)                            │   │
│   │  Security Group: sg-web (22 restrito / 80 e 443 públicos)  │   │
│   └────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────┘
```

### Por que IAM aparece aqui?

Uma instância EC2 muitas vezes precisa **falar com outros serviços da
AWS** (ex: ler um arquivo de um bucket S3, escrever logs no CloudWatch —
assunto da Aula 5). Para isso, ela precisa de um **IAM Instance
Profile**, que é basicamente um Role "vestido" na instância. Em uma conta
AWS normal, você criaria esse Role do zero; na AWS Academy, isso é
bloqueado — por isso **buscamos** (`data`) o `LabInstanceProfile` que já
existe, em vez de criar (`resource`) um novo.

### ⚠️ Particularidade da AWS Academy: o key pair `vockey`

Em uma conta AWS normal, o próprio Terraform criaria (ou importaria) o
par de chaves SSH usado para acessar a instância — é inclusive o que a
maioria dos tutoriais de Terraform pela internet mostra. **No Learner
Lab da AWS Academy isso não é permitido**: assim como acontece com IAM
Roles, a conta de aluno não tem permissão para criar um novo Key Pair
por código. Em vez disso, cada sessão do Lab já vem com um par de chaves
pronto, chamado **`vockey`**, disponível para download na própria tela
do Learner Lab.

> 💡 **Isso é só uma regra desta plataforma de estudo.** Em um projeto
> real, fora da AWS Academy, o normal é o Terraform **gerar ou importar**
> a própria chave (com os providers `tls` + `hashicorp/local`, ou
> importando uma chave já existente com `aws_key_pair`), em vez de
> consultar uma que já vem pronta.

---

## 📂 Onde trabalhar

Crie o arquivo `ec2.tf` dentro de [`00-pratica/`](../00-pratica/README.md):

```hcl
# ec2.tf
# AMI mais recente do Amazon Linux 2023, buscada dinamicamente
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Papel IAM já existente na AWS Academy — reaproveitado, nunca criado
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# Key pair já existente na AWS Academy ("vockey") — o Learner Lab não
# permite criar um Key Pair novo por código (mesma restrição do IAM
# Role acima). Baixe o "vockey.pem" pela tela do Learner Lab (seção
# "SSH key" > Download PEM) e salve dentro de 00-pratica/ antes do apply.
# Fora da AWS Academy, o normal seria o próprio Terraform gerar/importar
# a chave (com os providers "tls" + "hashicorp/local").
data "aws_key_pair" "vockey" {
  key_name = "vockey"
}

# Instância EC2 — usa a subnet e o security group definidos nos
# outros arquivos deste mesmo projeto, e o instance profile e o key
# pair da AWS Academy referenciados acima
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = data.aws_key_pair.vockey.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  tags = {
    Name = "${var.project_name}-ec2-web"
  }
}
```

E os dois outputs novos, em `outputs.tf`:

```hcl
output "instance_public_ip" {
  description = "IP público da instância EC2 criada"
  value       = aws_instance.web.public_ip
}

output "ssh_command" {
  description = "Comando pronto para conectar via SSH (rode a partir da pasta onde salvou o vockey.pem)"
  value       = "ssh -i vockey.pem ec2-user@${aws_instance.web.public_ip}"
}
```

---

## 🛠️ Passo a passo

### 1. Baixar o `vockey.pem`

Na tela do seu Learner Lab (a mesma onde você pegou as credenciais em
"AWS Details"), role até a seção **"SSH key"** e clique em
**"Download PEM"** (Linux/Mac/Windows com OpenSSH) — só use "Download
PPK" se for conectar via PuTTY no Windows.

Salve o arquivo `vockey.pem` dentro de `00-pratica/`.

> ⚠️ Essa chave é gerada **por sessão do Lab** — se você encerrar o Lab
> e iniciar um novo em outro dia, pode ser necessário baixar o
> `vockey.pem` de novo (o arquivo antigo deixa de funcionar).

### 2. Criar o `ec2.tf`

Crie o arquivo com o conteúdo mostrado acima, dentro de `00-pratica/`
(o `required_providers` não muda — continua usando só o provider `aws`).

### 3. Planejar e aplicar

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
```

Confira: deve aparecer **1 recurso novo** a ser criado (`aws_instance`) —
a AMI, o instance profile e o key pair são `data`, apenas consultados,
não criados.

```bash
terraform apply
```

Guarde o `instance_public_ip` e o `ssh_command` mostrados no final.

### 4. Conectar via SSH

**Linux / Mac:**

```bash
chmod 400 vockey.pem
ssh -i vockey.pem ec2-user@<instance_public_ip>
```

**Windows (PowerShell, com OpenSSH):**

```powershell
ssh -i vockey.pem ec2-user@<instance_public_ip>
```

> 💡 Se aparecer um aviso sobre "autenticidade do host" na primeira
> conexão, digite `yes` para confirmar — é esperado na primeira vez que
> você conecta em um servidor novo.

Dentro da instância, confirme que está tudo certo:

```bash
whoami        # deve retornar: ec2-user
cat /etc/os-release   # confirma que é Amazon Linux 2023
exit          # volta para o seu terminal local
```

### 5. Conferir no Console

Console da AWS → **EC2 → Instances** → confirme que a instância aparece
`running`, com o Security Group e a subnet corretos. Clique nela e
confira, na aba **Security**, que o `IAM Role` mostrado é o
`LabInstanceProfile` e o **Key pair name** é `vockey`.

### 6. Manter de pé (por enquanto!)

⚠️ Assim como no módulo 06, **não rode `terraform destroy` ainda** —
`00-pratica/` já está completa e é ela mesma quem vira a base do
exercício final (módulo 09), sem precisar recriar nada em outro lugar.

---

## ✅ Checklist técnico

- [ ] `vockey.pem` baixado do Learner Lab e salvo dentro de `00-pratica/`
- [ ] `ec2.tf` criado dentro de `00-pratica/`, com os dois outputs novos em `outputs.tf`
- [ ] `terraform plan` mostra 1 recurso novo (a instância)
- [ ] `terraform apply` concluído, `instance_public_ip` exibido
- [ ] Conexão SSH bem-sucedida usando o `vockey.pem`
- [ ] Instância `running` conferida no Console, com IAM Role e Key pair corretos

---

## 🧪 Exercício

1. Siga o passo a passo acima e suba a instância.
2. Guarde o print do SSH funcionando (o prompt mudando para
   `[ec2-user@ip-... ~]$`).
3. Responda: por que a chave **privada** (`vockey.pem`) nunca deve sair
   da sua máquina nem ser commitada no Git? (Adicione `*.pem` ao
   `.gitignore` do projeto, se ainda não fez.)
4. Por que, nesta aula, usamos um `data source` para o key pair em vez
   de um `resource`, assim como fizemos com o IAM Instance Profile? O
   que isso tem em comum com a restrição de IAM explicada no módulo 03?
5. **Desafio:** tente, propositalmente, criar a instância usando
   `iam_instance_profile = "um-nome-qualquer-inventado"` (em vez do
   `data.aws_iam_instance_profile.lab_profile.name`). Rode `terraform
   plan`/`apply` e observe o erro retornado pela AWS. Depois do teste,
   **volte o código ao original** (referenciando o `data source`) e
   aplique de novo.

**Próximo passo:** [09-exercicio-final](../09-exercicio-final/README.md)
