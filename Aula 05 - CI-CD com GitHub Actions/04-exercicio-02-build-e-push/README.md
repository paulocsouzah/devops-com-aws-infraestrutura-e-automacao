# 4. Exercício 02 — Build e Push Automáticos das Imagens

Com a autenticação funcionando (módulo 03), chegou a hora da pipeline
fazer sozinha o que você fazia na mão desde a Aula 04, módulo 02: login
no ECR, build das duas imagens, tag e push.

> 🧭 **Onde estamos:** duas pastas diferentes entram em jogo neste
> módulo. O **passo 1** roda na pasta `00-pratica/` desta aula (dentro
> do material do curso). Os **passos 2 em diante** rodam no clone
> separado do `app-aula03` (a mesma pasta dos módulos 02 e 03, fora do
> material do curso). Preste atenção em qual pasta cada passo pede.

---

## 🏷️ Uma decisão importante: a tag da imagem

Na Aula 04 (módulo 02), publicamos tudo com a tag `latest` — simples,
mas com um problema real: `latest` é sempre reescrita, então não dá pra
saber, só olhando o ECR, **qual commit** gerou a imagem que está rodando
agora. Aquele módulo já adiantava essa limitação, numa nota sobre
`image_tag_mutability = "MUTABLE"` — é exatamente ela que resolvemos
aqui.

Nesta aula, cada imagem ganha **duas** tags:

| Tag | Para quê |
|---|---|
| `${{ github.sha }}` (hash do commit) | Identifica de forma única e imutável **qual código** gerou essa imagem — é essa tag que o job de deploy (módulo 05) usa na nova revisão da Task Definition |
| `latest` | Mantida por conveniência (permite `docker pull ...:latest` manual, se precisar depurar) — mas não é o que o deploy automatizado usa |

> 💡 Rastreabilidade: com a tag pelo commit, `aws ecr describe-images`
> e a própria Task Definition sempre mostram exatamente qual código está
> rodando em produção — algo que `latest` sozinho nunca conseguiria.
>
> 💡 Não precisa instalar Docker em lugar nenhum pra isso funcionar: a
> máquina que o GitHub Actions usa (`ubuntu-latest`) já vem com Docker
> pronto pra uso, exatamente como o seu computador.

---

## 🛠️ Passo 1 — Confirmar que os repositórios ECR existem

Este passo roda na pasta `00-pratica/` **desta aula** (dentro do
material do curso, não no `app-aula03`):

```bash
cd 00-pratica
terraform apply
aws ecr describe-repositories --query "repositories[].repositoryName"
```

Deve aparecer `aula05-frontend` e `aula05-api` na lista (os dois
repositórios já vêm prontos do `ecr.tf`, copiado da Aula 04).

---

## ✍️ Passo 2 — Editar o workflow

Volte pro VS Code, na pasta do clone `app-aula03` (a mesma dos módulos
02 e 03). Abra `.github/workflows/deploy.yml` e **substitua todo o
conteúdo** por este (mantém tudo que já tinha, mais os steps novos de
login no ECR e build/push das duas imagens):

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

      - name: Login no Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag e push — frontend
        working-directory: frontend
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $REGISTRY/aula05-frontend:$IMAGE_TAG -t $REGISTRY/aula05-frontend:latest .
          docker push $REGISTRY/aula05-frontend:$IMAGE_TAG
          docker push $REGISTRY/aula05-frontend:latest

      - name: Build, tag e push — api
        working-directory: api
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $REGISTRY/aula05-api:$IMAGE_TAG -t $REGISTRY/aula05-api:latest .
          docker push $REGISTRY/aula05-api:$IMAGE_TAG
          docker push $REGISTRY/aula05-api:latest
```

Salve o arquivo (`Ctrl+S`).

> 💡 `steps.login-ecr.outputs.registry` — a action `amazon-ecr-login`
> devolve o endereço completo do seu registro
> (`<conta>.dkr.ecr.us-east-1.amazonaws.com`) como *output*, então você
> não precisa descobrir/colar o ID da sua conta AWS em lugar nenhum do
> workflow — mesma ideia do que fizemos na Aula 04 com
> `$AWS_ACCOUNT_ID`, só que resolvida automaticamente.
>
> 💡 `working-directory` troca a pasta de trabalho **só daquele step** —
> equivalente a fazer `cd frontend` antes do `docker build`, sem afetar
> os outros steps do job. `frontend` e `api` aqui são as pastas que já
> existem dentro do `app-aula03` desde a Aula 03 — nada muda nelas.
>
> 💡 `aula05` nos nomes das imagens segue o mesmo `project_name` que
> você já deve ter atualizado no `variables.tf` do
> [`00-pratica/`](../00-pratica/README.md) desta aula (de `"aula04"`
> para `"aula05"`) — se usou outro valor, ajuste aqui também.

---

## 📤 Passo 3 — Enviar e acompanhar

Ainda na pasta `app-aula03` (não confunda com a `00-pratica`):

```bash
git add .github/workflows/deploy.yml
git commit -m "ci: builda e publica as imagens no ECR automaticamente"
git push origin main
```

No navegador, aba **Actions** do seu repositório: acompanhe os dois
steps novos (build/push do frontend, build/push da api) até ficarem
verdes.

---

## ✅ Passo 4 — Confirmar no ECR

De volta ao terminal, na pasta `00-pratica/` **desta aula** (a mesma do
Passo 1):

```bash
aws ecr describe-images --repository-name aula05-frontend \
  --query "imageDetails[].imageTags" --output table
aws ecr describe-images --repository-name aula05-api \
  --query "imageDetails[].imageTags" --output table
```

Você deve ver, em cada repositório, uma entrada com `["latest",
"<hash-do-commit>"]`. **Tire um print** disso — vai servir de imagem no
material da aula.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| Step "Login no Amazon ECR" falha | Confirme que o step de credenciais (módulo 03) roda **antes** dele no arquivo, e que os 3 Secrets ainda são válidos (sessão do Lab não expirou) |
| `docker build` falha com "no such file or directory" | O `working-directory` (`frontend` ou `api`) não bate com a estrutura real do seu `app-aula03` — confirme que essas pastas existem na raiz do repositório |
| `aws ecr describe-images` não mostra a tag nova | Confirme que o job `build-and-push` terminou verde na aba Actions antes de rodar o comando — se ainda está rodando, espere |
| `denied: User is not authorized` no push pro ECR | Sessão do Lab expirou no meio da execução — volte ao módulo 03 e atualize os Secrets |

---

## ✅ Checklist técnico

- [ ] `ecr.tf` aplicado (repositórios `aula05-frontend`/`aula05-api` existem)
- [ ] Workflow atualizado com login no ECR e os dois builds
- [ ] Pipeline executa verde na aba **Actions**
- [ ] Cada repositório ECR mostra uma imagem nova, com a tag do commit **e** `latest`
- [ ] Print guardado de `aws ecr describe-images`

---

## 🧪 Exercício

1. Siga o passo a passo e guarde o print de `aws ecr describe-images`
   mostrando as duas tags (commit + `latest`) nos dois repositórios.
2. Faça uma alteração pequena e visível no `frontend` (ex: um texto na
   tela), dê `push`, e confirme que uma **nova** imagem aparece no ECR,
   com uma tag de commit diferente da anterior.
3. Por que tagueamos com `github.sha` em vez de usar só `latest`? O que
   isso resolve que não seria possível só com `latest`?
4. **Desafio:** se dois `push`s chegassem quase ao mesmo tempo, duas
   execuções da pipeline poderiam rodar em paralelo. O que aconteceria
   com as tags de imagem nesse cenário — elas colidiriam entre si?
   Justifique usando o que você sabe sobre `github.sha`.

**Próximo passo:** [05-exercicio-03-deploy-automatico](../05-exercicio-03-deploy-automatico/README.md)
