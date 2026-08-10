# 3. AWS Academy — Iniciando o Lab e Configurando as Credenciais

Este é o módulo mais importante do início da aula: **sem isso funcionando
corretamente, nenhum comando de Terraform vai conseguir criar nada na
AWS.** Leia com calma antes de sair digitando comando.

---

## 🎓 Por que a AWS Academy é diferente de uma conta AWS normal

Em uma conta AWS "normal", você cria um **usuário IAM** com uma chave de
acesso permanente e configura essa chave uma única vez. Na **AWS
Academy (Learner Lab)**, o ambiente é diferente:

- Você **não** tem permissão para criar usuários, roles ou policies IAM
  novos — só existe um papel pronto chamado **`LabRole`** (com um
  Instance Profile associado, o **`LabInstanceProfile`**), que já vem
  configurado pela AWS Academy com as permissões necessárias para o
  curso.
- As credenciais são **temporárias**: toda vez que você inicia o Lab, a
  AWS Academy gera um novo `Access Key`, `Secret Key` e, além disso, um
  **`Session Token`** — e esse conjunto expira quando o Lab é encerrado
  (automaticamente após algumas horas de inatividade, ou quando você
  clica em **"End Lab"**).
- Isso significa que **você precisa repetir a configuração das
  credenciais no início de cada sessão de estudo/aula** — não é algo que
  se faz uma vez só e esquece.

Guarde essa ideia: *"a cada vez que eu for usar o Terraform, primeiro eu
inicio o Lab, e só depois eu atualizo as credenciais."*

---

## 🚀 Passo 1 — Iniciar o Learner Lab

1. Acesse o **AWS Academy** (via Canvas/portal da FAEX) e entre no curso
   correspondente a esta disciplina.
2. Clique no módulo **"AWS Academy Learner Lab"**.
3. Clique em **"Start Lab"**.
4. Aguarde o círculo ao lado ficar **verde** — isso indica que o
   ambiente AWS já está de pé e pronto para uso (pode levar 1–3
   minutos).

⚠️ Enquanto o círculo estiver **cinza/amarelo** (iniciando), as
credenciais ainda não estão prontas — aguarde ficar verde antes de
seguir para o próximo passo.

## 🔑 Passo 2 — Pegar as credenciais (AWS Details)

1. Ainda na tela do Lab, clique no botão **"AWS Details"** (fica perto do
   "Start Lab").
2. Vai aparecer uma caixa com um link **AWS** (abre o Console web, se
   você quiser conferir visualmente o que o Terraform criar) e o botão
   **"Show"** ao lado de **"AWS CLI"**.
3. Clique em **"Show"**. Vai aparecer um bloco parecido com este
   (os valores abaixo são só um exemplo — os seus serão diferentes):

   ```ini
   [default]
   aws_access_key_id=ASIAABCDEFGHIJKLMNOP
   aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   aws_session_token=FQoGZXIvYXdzEA0aDG7yQ...(texto bem longo)...
   ```

4. Copie **esse bloco inteiro** — vamos colar ele no próximo passo.

> 💡 Repare que o `aws_access_key_id` começa com `ASIA` (e não `AKIA`) —
> esse prefixo indica que é uma credencial **temporária** (STS), exatamente
> o tipo que a AWS Academy fornece. E repare também que existe uma
> terceira linha, `aws_session_token`, que não existe em uma configuração
> "tradicional" de usuário IAM permanente — ela é obrigatória aqui.

## 💻 Passo 3 — Configurar a AWS CLI com essas credenciais

A forma mais direta é editar diretamente o arquivo de credenciais da AWS
CLI e colar o bloco copiado.

### Onde fica o arquivo

| Sistema | Caminho |
|---|---|
| Linux / Mac | `~/.aws/credentials` e `~/.aws/config` |
| Windows | `C:\Users\<seu_usuario>\.aws\credentials` e `...\.aws\config` |

⚠️ **Nunca cole suas credenciais reais em um chat, grupo ou IA** (mesmo
sendo temporárias) — trate-as como uma senha. Os exemplos abaixo usam
valores **fictícios**; substitua pelas suas antes de rodar.

### 🐧🍎 Linux / Mac — script pronto (rode no terminal)

```bash
mkdir -p ~/.aws

cat > ~/.aws/credentials <<'EOF'
[default]
aws_access_key_id=ASIAEXAMPLE7Q3K9ZP2
aws_secret_access_key=exampleSecretKey9F7h2LmQwZrTuVbXyC1dEfGhIjKl
aws_session_token=EXEMPLO_SUBSTITUA_PELO_TOKEN_BEM_LONGO_QUE_VEM_DO_AWS_DETAILS_TERMINA_COM_SINAL_DE_IGUAL==
EOF
chmod 600 ~/.aws/credentials

cat > ~/.aws/config <<'EOF'
[default]
region = us-east-1
output = json
EOF
chmod 600 ~/.aws/config
```

Antes de rodar: substitua as 3 linhas dentro do primeiro bloco (entre os
`EOF`) pelo conteúdo real copiado do "AWS Details".

### 🪟 Windows — script pronto (PowerShell)

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\.aws" | Out-Null

@"
[default]
aws_access_key_id=ASIAEXAMPLE7Q3K9ZP2
aws_secret_access_key=exampleSecretKey9F7h2LmQwZrTuVbXyC1dEfGhIjKl
aws_session_token=EXEMPLO_SUBSTITUA_PELO_TOKEN_BEM_LONGO_QUE_VEM_DO_AWS_DETAILS_TERMINA_COM_SINAL_DE_IGUAL==
"@ | Set-Content -Path "$HOME\.aws\credentials" -Encoding ASCII

@"
[default]
region = us-east-1
output = json
"@ | Set-Content -Path "$HOME\.aws\config" -Encoding ASCII
```

Mesma coisa: troque as 3 linhas de exemplo pelo bloco real antes de
colar e rodar no PowerShell.

> 💡 Alternativa manual, se preferir editor de texto em vez de script:
> crie a pasta `.aws` na sua pasta de usuário e, dentro dela, dois
> arquivos **sem extensão** chamados `credentials` e `config` (no
> Windows, cuidado para o Bloco de Notas não salvar como
> `credentials.txt`), com o mesmo conteúdo mostrado acima.

### ✅ Testar se funcionou

```bash
aws sts get-caller-identity
```

Se tudo estiver certo, a saída mostra o `Account`, o `UserId` e o `Arn`
do papel usado pelo Lab (algo como
`arn:aws:sts::123456789012:assumed-role/voclabs/user...`). Se aparecer
erro de credenciais inválidas ou expiradas, volte ao Passo 1/2 — o Lab
pode ter expirado ou o bloco pode ter sido colado incompleto.

---

## 🔌 Passo 4 — Conectar o Terraform à AWS Academy

A boa notícia: o Terraform **não precisa de nenhuma configuração
especial** para usar essas credenciais — por padrão, o `provider "aws"`
já procura automaticamente pelas credenciais em `~/.aws/credentials`
(as mesmas que a AWS CLI usa), incluindo o `session_token`.

Ou seja, um provider simples assim já é suficiente:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Nunca escreva `access_key`, `secret_key` ou `session_token` diretamente
dentro do arquivo `.tf` — isso é uma credencial sensível e não deve ir
para o Git. Deixar o Terraform ler do `~/.aws/credentials` (como fizemos
acima) é a forma correta e segura de fazer isso.

---

## ⚠️ Duas armadilhas importantes da AWS Academy

### 1. Credenciais expiram

Sempre que o Lab expirar (ou você clicar em "End Lab" e depois "Start
Lab" de novo), um **novo** `access_key` / `secret_key` / `session_token`
é gerado. Se o Terraform começar a dar erro de
`ExpiredToken` ou `InvalidClientTokenId`, o primeiro passo é sempre:
repetir os passos 1 a 3 deste módulo (start lab → AWS Details → colar de
novo no `~/.aws/credentials`).

### 2. Não é possível criar usuários/roles IAM novos (e nem um Key Pair novo)

O Learner Lab tem permissões restritas por padrão — tentar rodar algo
como `resource "aws_iam_role" "novo" { ... }` vai dar erro de acesso
negado (`AccessDenied`). Sempre que um recurso precisar de uma
permissão IAM (por exemplo, uma EC2 que precisa acessar outros serviços
da AWS), vamos **reutilizar o papel já existente**, o `LabRole` /
`LabInstanceProfile`, referenciando-o no Terraform com um **data source**
em vez de criar um novo:

```hcl
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}
```

A mesma restrição vale para o **Key Pair** usado no acesso SSH às
instâncias: em vez de deixar o Terraform criar um par de chaves novo
(o que seria o normal em uma conta AWS real), vamos usar o par já
pronto da AWS Academy, chamado **`vockey`** — disponível para download
na própria tela do Learner Lab (seção "SSH key"). Também referenciamos
ele com um `data source`, em vez de criar:

```hcl
data "aws_key_pair" "vockey" {
  key_name = "vockey"
}
```

Vamos usar os dois `data sources` acima no módulo
[07-exercicio-03-ec2-com-iam](../07-exercicio-03-ec2-com-iam/README.md).

---

## 📝 Resumo do fluxo (vale para toda aula/sessão de estudo)

```
1. Start Lab (aguardar círculo verde)
2. AWS Details → Show → copiar bloco AWS CLI
3. Colar em ~/.aws/credentials
4. Conferir região em ~/.aws/config (us-east-1)
5. Testar: aws sts get-caller-identity
6. Só então rodar comandos terraform
```

---

## 🧪 Exercício

1. Inicie o seu Learner Lab e espere o círculo ficar verde.
2. Configure `~/.aws/credentials` e `~/.aws/config` conforme este guia.
3. Rode `aws sts get-caller-identity` e guarde o print da saída (com o
   `Account` e o `Arn` visíveis) — vai precisar disso no relatório do
   exercício final.
4. Responda por escrito: por que o `aws_access_key_id` da AWS Academy
   começa com `ASIA` em vez de `AKIA`? O que isso indica sobre o tipo de
   credencial?
5. **Desafio:** o que você imagina que aconteceria se você criasse uma
   EC2 pelo Terraform, saísse do Lab (End Lab) sem rodar
   `terraform destroy`, e voltasse no dia seguinte com um novo "Start
   Lab"? A instância continuaria existindo? E o `terraform.tfstate` da
   sua máquina ainda estaria "sincronizado" com a realidade? (vamos
   confirmar a resposta na prática no próximo módulo, mas já pense a
   respeito).

**Próximo passo:** [04-primeiros-comandos-terraform](../04-primeiros-comandos-terraform/README.md)
