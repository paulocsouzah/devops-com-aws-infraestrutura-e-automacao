# 7. Exercício 03 — EC2 com Papel IAM e Key Pair da AWS Academy

Rede pronta, porta liberada — agora vamos finalmente subir um **servidor**
dentro dessa rede, usando o papel de IAM e o par de chaves que já vêm
prontos na AWS Academy. Continuamos no mesmo projeto `terraform-rede`.

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
> real, fora da AWS Academy, o normal é o Terraform gerar (ou importar)
> a própria chave — inclusive deixamos esse código comentado no final do
> [`ec2.tf`](ec2.tf) deste módulo, como referência para quando vocês
> estiverem trabalhando em uma conta AWS de verdade, no mercado.

---

## 📂 Arquivo deste módulo

- [`ec2.tf`](ec2.tf) — AMI, key pair (via `data source`), instância e
  outputs, comentados. Copie para dentro da pasta `terraform-rede`.

---

## 🛠️ Passo a passo

### 1. Baixar o `vockey.pem`

Na tela do seu Learner Lab (a mesma onde você pegou as credenciais em
"AWS Details"), role até a seção **"SSH key"** e clique em
**"Download PEM"** (Linux/Mac/Windows com OpenSSH) — só use "Download
PPK" se for conectar via PuTTY no Windows.

Salve o arquivo `vockey.pem` dentro da pasta do seu projeto
`terraform-rede`.

> ⚠️ Essa chave é gerada **por sessão do Lab** — se você encerrar o Lab
> e iniciar um novo em outro dia, pode ser necessário baixar o
> `vockey.pem` de novo (o arquivo antigo deixa de funcionar).

### 2. Copiar o `ec2.tf` para o projeto

Copie o arquivo [`ec2.tf`](ec2.tf) deste módulo para dentro da pasta
`terraform-rede` (o `required_providers` do projeto não muda — este
módulo usa só o provider `aws`, que você já tem desde o módulo 05).

### 3. Planejar e aplicar

```bash
cd terraform-rede
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

⚠️ Assim como no módulo 06, **não rode `terraform destroy` ainda** — este
mesmo projeto vira a base do exercício final.

---

## ✅ Checklist técnico

- [ ] `vockey.pem` baixado do Learner Lab e salvo dentro de `terraform-rede`
- [ ] `ec2.tf` copiado para dentro de `terraform-rede`
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
