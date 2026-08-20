# 3. Exercício 01 — Secrets e a Credencial Temporária do Learner Lab

Antes de a pipeline conseguir falar com o ECR ou o ECS, ela precisa se
autenticar na AWS. Este módulo é sobre configurar isso **e** sobre uma
limitação real do AWS Academy que vai te acompanhar durante toda a aula.

---

## 🔑 De onde vêm as credenciais

O Learner Lab não permite criar uma IAM User com access key permanente —
as únicas credenciais disponíveis são as **temporárias** da sessão ativa
do Lab (a mesma que você já usa em `~/.aws/credentials` desde a Aula 02).
Elas têm **três** partes, não duas:

```ini
[default]
aws_access_key_id     = ASIA...
aws_secret_access_key = ...
aws_session_token      = ...     ← isso não existe numa IAM User comum
```

O `aws_session_token` é a prova de que essa credencial é temporária —
sem ele, as outras duas chaves sozinhas não autenticam nada. Copie os
três valores de `~/.aws/credentials` (ou do painel **AWS Details → AWS
CLI** do Learner Lab).

---

## 🔒 Criando os Secrets no GitHub

No repositório `app-aula03`: **Settings → Secrets and variables →
Actions → New repository secret**. Crie os três:

| Nome do Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | `aws_access_key_id` do `~/.aws/credentials` |
| `AWS_SECRET_ACCESS_KEY` | `aws_secret_access_key` do `~/.aws/credentials` |
| `AWS_SESSION_TOKEN` | `aws_session_token` do `~/.aws/credentials` |

> 💡 Repare que não existe um `AWS_ACCOUNT_ID` nem um `AWS_REGION` como
> secret — a região vai direto no YAML (não é sensível), e o ID da conta
> a pipeline descobre sozinha a partir do login no ECR (módulo 04).

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
bug**, é a credencial temporária expirando no meio do caminho. A
correção é sempre a mesma:

1. Confirme que o Lab ainda está com o círculo verde (ativo).
2. Copie as credenciais atualizadas de `~/.aws/credentials`.
3. Atualize os três Secrets no GitHub (**Settings → Secrets and
   variables → Actions** → clique em cada um → **Update**).
4. Reenvie um commit (ou clique em **Re-run all jobs** na execução que
   falhou).

> 💡 **Como isso seria numa empresa de verdade:** o padrão de mercado
> hoje é **OIDC (OpenID Connect)** — o GitHub Actions se autentica
> diretamente com uma IAM Role da AWS, **sem nenhuma chave armazenada em
> lugar nenhum**, nem temporária nem permanente. O Learner Lab não
> permite criar essa configuração (exige criar uma IAM Identity Provider,
> que a conta de estudante não tem permissão pra fazer), então usamos
> Secrets com credencial temporária como alternativa didática — mas vale
> saber que, em produção, esse não seria o caminho recomendado.

---

## 🧪 Testando a autenticação

Edite `.github/workflows/deploy.yml`, adicionando o step de configurar
credenciais logo depois do checkout:

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

Commite e envie:

```bash
git add .github/workflows/deploy.yml
git commit -m "ci: autentica na AWS usando credenciais temporarias do Learner Lab"
git push origin main
```

Na aba **Actions**, o step "Confirmar identidade autenticada" deve
mostrar o `Account` e o `Arn` do seu usuário do Lab — a mesma saída que
`aws sts get-caller-identity` mostra no seu terminal local.

---

## ✅ Checklist técnico

- [ ] Três Secrets criados: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
- [ ] Step `aws-actions/configure-aws-credentials` adicionado ao workflow
- [ ] `aws sts get-caller-identity` executa com sucesso dentro da pipeline
- [ ] Você sabe, de cor, os 4 passos para atualizar os Secrets quando o Lab expirar

---

## 🧪 Exercício

1. Siga o passo a passo e guarde o print do step `aws sts
   get-caller-identity` mostrando sua identidade autenticada dentro da
   pipeline.
2. Por que a credencial do Learner Lab precisa de um terceiro valor
   (`aws_session_token`) que uma IAM User comum não tem?
3. Deixe o Lab expirar de propósito (ou simule alterando um caractere de
   um dos Secrets) e rode a pipeline. Copie a mensagem de erro exata que
   aparece no log — ela bate com o que este módulo descreveu?
4. Pesquise, em uma frase, o que é autenticação **OIDC** entre GitHub
   Actions e AWS, e por que ela elimina a necessidade de Secrets com
   chave de acesso.

**Próximo passo:** [04-exercicio-02-build-e-push](../04-exercicio-02-build-e-push/README.md)
