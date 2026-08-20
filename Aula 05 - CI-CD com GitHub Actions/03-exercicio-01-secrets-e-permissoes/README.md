# 3. Exercício 01 — Secrets e a Credencial Temporária do Learner Lab

Antes de a pipeline conseguir falar com o ECR ou o ECS, ela precisa se
autenticar na AWS. Este módulo é sobre configurar isso **e** sobre uma
limitação real do AWS Academy que vai te acompanhar durante toda a aula.

> 🧭 **Onde estamos:** você vai continuar editando o arquivo
> `.github/workflows/deploy.yml`, dentro do clone do `app-aula03` que
> você preparou no módulo 02 (a pasta separada, **fora** do material do
> curso). Abra essa pasta no VS Code de novo, se já tiver fechado.

---

## 🔑 Passo 1 — Encontrar suas credenciais atuais do Learner Lab

Você já usa essas credenciais desde a Aula 02, guardadas num arquivo
chamado `credentials`, dentro de uma pasta oculta `.aws` na sua pasta de
usuário. Pra ver o conteúdo dele agora:

**Windows (PowerShell):**
```powershell
Get-Content $HOME\.aws\credentials
```

**Mac/Linux (ou Git Bash no Windows):**
```bash
cat ~/.aws/credentials
```

Vai aparecer algo assim (os valores reais são bem mais longos):

```ini
[default]
aws_access_key_id     = ASIA4XZ7K...
aws_secret_access_key = wJalrXUt...
aws_session_token     = FwoGZXIv...
```

São **três** valores, não dois — isso é diferente de uma credencial AWS
"normal". O `aws_session_token` existe porque essa credencial é
**temporária** (ela expira sozinha depois de algumas horas — falamos
mais sobre isso no Passo 3). Se esse arquivo estiver vazio ou não
existir, o Lab não está ativo — inicie-o primeiro no site do AWS
Academy e copie as credenciais de lá (botão **AWS Details** → **AWS
CLI**).

Deixe essa janela do terminal aberta, ou copie os três valores pra um
lugar temporário — você vai usá-los no próximo passo.

---

## 🔒 Passo 2 — Criar os três Secrets no GitHub

1. Abra o **navegador** e vá até
   `https://github.com/SEU_USUARIO/app-aula03` (o repositório de
   verdade, não a pasta local).
2. Clique na aba **Settings** (fica no menu horizontal do topo do
   repositório — se não aparecer, você pode não ser o dono do repo;
   confirme que está logado com a conta certa).
3. No menu da esquerda, clique em **Secrets and variables** → depois em
   **Actions**.
4. Clique no botão verde **New repository secret**.
5. No campo **Name**, digite exatamente `AWS_ACCESS_KEY_ID` (tudo
   maiúsculo, com underline — o nome precisa ser idêntico a esse,
   inclusive maiúsculas/minúsculas). No campo **Secret**, cole o valor
   de `aws_access_key_id` que você viu no Passo 1. Clique em **Add
   secret**.
6. Repita o passo 4 e 5 mais duas vezes, para:
   - `AWS_SECRET_ACCESS_KEY` → valor de `aws_secret_access_key`
   - `AWS_SESSION_TOKEN` → valor de `aws_session_token`

Ao final, a lista de Secrets deve mostrar os três nomes (os valores
nunca aparecem de novo, nem pra você — isso é proposital, é assim que
Secrets funcionam).

**Tire um print desta tela** (só os nomes, sem nenhum valor exposto —
é seguro compartilhar) — vai servir de imagem no material da aula.

> 💡 Não existe um `AWS_ACCOUNT_ID` nem um `AWS_REGION` na lista — a
> região vai direto escrita no arquivo `deploy.yml` (não é uma
> informação sensível), e o ID da sua conta AWS a pipeline descobre
> sozinha mais adiante (módulo 04), sem você precisar informar.

---

## ⚠️ A limitação real: credenciais que expiram no meio da aula

Isso **não é um detalhe menor** — é a diferença mais importante entre
"CI/CD de laboratório" e "CI/CD de produção":

| | Conta AWS "de verdade" | AWS Academy Learner Lab |
|---|---|---|
| Tipo de credencial | IAM User com access key permanente, ou (melhor ainda) OIDC federado — sem chave nenhuma armazenada | Credencial temporária da sessão do Lab |
| Validade | Até você revogar manualmente | Poucas horas — expira junto com a sessão do Lab |
| Impacto na pipeline | Configura os Secrets **uma vez**, nunca mais mexe | Precisa **atualizar os três Secrets a cada nova sessão de estudo** |

Se você iniciar o Lab, configurar os Secrets, estudar por várias horas
sem reiniciar a sessão, e a pipeline começar a falhar com um erro do
tipo `ExpiredTokenException` ou `UnrecognizedClientException` — **não é
bug**, é a credencial temporária expirando no meio do caminho. Sempre
que isso acontecer, repita exatamente estes 4 passos:

1. Confirme que o Lab ainda está com o círculo verde (ativo) na página
   do AWS Academy.
2. Rode o comando do Passo 1 de novo, pra ver as credenciais
   **atualizadas**.
3. Volte em **Settings → Secrets and variables → Actions**, clique em
   cima de cada um dos três Secrets → **Update secret** → cole o valor
   novo → **Update secret**.
4. Vá na aba **Actions**, abra a execução que falhou, e clique em
   **Re-run all jobs** (canto superior direito) — ou simplesmente faça
   um novo `git push`.

> 💡 **Como isso seria numa empresa de verdade:** o padrão de mercado
> hoje é **OIDC (OpenID Connect)** — o GitHub Actions se autentica
> diretamente com uma IAM Role da AWS, **sem nenhuma chave armazenada em
> lugar nenhum**, nem temporária nem permanente. O Learner Lab não
> permite criar essa configuração (exige criar uma IAM Identity Provider,
> que a conta de estudante não tem permissão pra fazer), então usamos
> Secrets com credencial temporária como alternativa didática — mas vale
> saber que, em produção, esse não seria o caminho recomendado.

---

## 🧪 Passo 3 — Testar a autenticação dentro da pipeline

Volte pro VS Code, na pasta `app-aula03` (módulo 02). Abra o arquivo
`.github/workflows/deploy.yml` que você já criou. **Substitua todo o
conteúdo dele** por este (ele já inclui o que você tinha, mais o step
novo de autenticação):

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout do código
        uses: actions/checkout@v4

      - name: Configurar credenciais AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
          aws-region: us-east-1

      - name: Confirmar identidade autenticada
        run: aws sts get-caller-identity
```

Salve o arquivo (`Ctrl+S`). No terminal, dentro da pasta `app-aula03`:

```bash
git add .github/workflows/deploy.yml
git commit -m "ci: autentica na AWS usando credenciais temporarias do Learner Lab"
git push origin main
```

Volte pro navegador, aba **Actions** do repositório. Clique na execução
mais recente → job `build-and-push` → step "Confirmar identidade
autenticada". Deve mostrar um JSON com `UserId`, `Account` e `Arn` — a
mesma coisa que `aws sts get-caller-identity` mostra no seu terminal
local. **Tire um print** dessa saída.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| Step "Configurar credenciais AWS" falha com `InvalidClientTokenId` ou `SignatureDoesNotMatch` | Algum dos três Secrets foi colado errado (com espaço extra, ou faltando um caractere). Apague os três e crie de novo, com cuidado ao copiar do Passo 1 |
| `ExpiredTokenException` | A sessão do Lab expirou — siga os 4 passos da seção acima |
| Não encontro **Settings** no repositório | Confirme que está logado no GitHub com a mesma conta dona do `app-aula03`, e que a URL no navegador é a do **seu** repositório, não de outra pessoa |
| O nome do Secret não pode ter espaço/minúscula | Os nomes são fixos (`AWS_ACCESS_KEY_ID`, etc.) — copie exatamente como está neste módulo, sem alterar nada |

---

## ✅ Checklist técnico

- [ ] Três Secrets criados: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
- [ ] Print da tela de Secrets guardado (só nomes, sem valores)
- [ ] Step `aws-actions/configure-aws-credentials` adicionado ao workflow
- [ ] `aws sts get-caller-identity` executa com sucesso dentro da pipeline, print guardado
- [ ] Você sabe, de cor, os 4 passos para atualizar os Secrets quando o Lab expirar

---

## 🧪 Exercício

1. Siga o passo a passo e guarde os dois prints (Secrets criados, e o
   resultado do `aws sts get-caller-identity` rodando na pipeline).
2. Por que a credencial do Learner Lab precisa de um terceiro valor
   (`aws_session_token`) que uma IAM User comum não tem?
3. Deixe o Lab expirar de propósito (ou simule alterando um caractere de
   um dos Secrets) e rode a pipeline. Copie a mensagem de erro exata que
   aparece no log — ela bate com o que este módulo descreveu?
4. Pesquise, em uma frase, o que é autenticação **OIDC** entre GitHub
   Actions e AWS, e por que ela elimina a necessidade de Secrets com
   chave de acesso.

**Próximo passo:** [04-exercicio-02-build-e-push](../04-exercicio-02-build-e-push/README.md)
