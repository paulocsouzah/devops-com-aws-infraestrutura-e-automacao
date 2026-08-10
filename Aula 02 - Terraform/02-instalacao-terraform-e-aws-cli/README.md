# 2. Instalação — Terraform e AWS CLI

Para esta aula precisamos de **duas** ferramentas instaladas na máquina:

- **Terraform** — lê nosso código `.tf` e cria os recursos na AWS.
- **AWS CLI** — usada para guardar/testar as credenciais da AWS Academy
  que o Terraform vai usar por trás dos panos (o Terraform não pede login
  e senha; ele lê as mesmas credenciais que a AWS CLI usa).

As duas são independentes uma da outra, mas vamos usar as duas juntas: a
AWS CLI para autenticar e o Terraform para provisionar.

---

## 🌍 Terraform

### 🪟 Windows

**Opção recomendada — Winget** (já vem instalado no Windows 10/11):

```powershell
winget install HashiCorp.Terraform
```

**Alternativa — Chocolatey:**

```powershell
choco install terraform
```

**Alternativa manual:**

1. Acesse https://developer.hashicorp.com/terraform/install
2. Baixe o `.zip` da versão para Windows (amd64).
3. Extraia o `terraform.exe` para uma pasta fixa, por exemplo
   `C:\terraform\`.
4. Adicione essa pasta na variável de ambiente **PATH**
   (Painel de Controle → Sistema → Configurações avançadas → Variáveis
   de Ambiente → `Path` → New → `C:\terraform\`).
5. Abra um **novo** PowerShell e teste (veja o checklist abaixo).

### 🐧 Linux (Debian/Ubuntu)

```bash
# 1. Dependências
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common curl

# 2. Chave GPG oficial da HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# 3. Repositório oficial
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# 4. Instalar
sudo apt-get update
sudo apt-get install -y terraform
```

### 🍎 Mac

**Opção recomendada — Homebrew:**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### ✅ Checklist — Terraform

```bash
terraform -version
```

Deve mostrar algo como `Terraform v1.x.x`.

---

## ☁️ AWS CLI (versão 2)

### 🪟 Windows

1. Acesse https://awscli.amazonaws.com/AWSCLIV2.msi (baixa o instalador
   direto) ou vá em
   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
   e pegue o link mais atual.
2. Execute o instalador `.msi` e siga o assistente (Next, Next, Install).
3. Abra um **novo** PowerShell ou Prompt de Comando.

### 🐧 Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# opcional: limpar os arquivos baixados
rm -rf awscliv2.zip aws/
```

> Se `unzip` não estiver disponível: `sudo apt-get install -y unzip`.

### 🍎 Mac

**Opção recomendada — Homebrew:**

```bash
brew install awscli
```

**Alternativa — instalador oficial (.pkg):**

1. Baixe em https://awscli.amazonaws.com/AWSCLIV2.pkg
2. Execute o instalador e siga o assistente.

### ✅ Checklist — AWS CLI

```bash
aws --version
```

Deve mostrar algo como `aws-cli/2.x.x Python/3.x.x ...`.

---

## 🧪 Exercício

1. Instale o **Terraform** seguindo o guia do seu sistema operacional.
2. Instale a **AWS CLI** seguindo o guia do seu sistema operacional.
3. Rode os dois comandos do checklist (`terraform -version` e
   `aws --version`) e guarde o print da saída — vai precisar disso no
   relatório do exercício final.
4. **Não rode `aws configure` ainda** — vamos fazer isso no próximo
   módulo, com as credenciais específicas da AWS Academy (que são
   diferentes de uma conta AWS normal).

**Próximo passo:** [03-aws-academy-e-credenciais](../03-aws-academy-e-credenciais/README.md)
