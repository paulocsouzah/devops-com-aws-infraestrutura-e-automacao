# 1. Conceitos de CI/CD e GitHub Actions

Nas Aulas 02 a 04, toda atualização da aplicação seguia o mesmo ritual
manual: buildar a imagem, autenticar no ECR, dar `push`, e (na Aula 04)
forçar o Service a pegar a imagem nova. Funciona, mas depende de você
lembrar todos os passos, na ordem certa, toda vez. Nesta aula, quem passa
a fazer isso é uma **pipeline** — e ela nunca esquece um passo.

---

## 🔁 CI x CD — duas siglas, dois problemas diferentes

| | **CI** — Continuous Integration | **CD** — Continuous Delivery/Deployment |
|---|---|---|
| Pergunta que resolve | "O código novo quebrou alguma coisa?" | "Como esse código chega em produção?" |
| Dispara quando | A cada `push`/`pull request` | Depois que a CI passa |
| O que faz, nesta aula | Builda as imagens Docker e publica no ECR | Registra nova revisão da Task Definition e atualiza o ECS Service |
| Se falhar | O problema fica visível **antes** de virar código publicado | O deploy simplesmente não acontece — a versão antiga continua no ar |

> 💡 **Delivery x Deployment:** *Continuous Delivery* significa que toda
> mudança está **pronta** para ir pra produção a qualquer momento
> (podendo exigir um clique manual de aprovação). *Continuous Deployment*
> vai um passo além: toda mudança que passa na CI **vai** pra produção
> sozinha, sem clique nenhum. É esse segundo modelo que construímos
> aqui — todo `push` na `main` termina com a aplicação atualizada no ar.

---

## 🧰 GitHub Actions — as peças do quebra-cabeça

O **GitHub Actions** é a ferramenta de CI/CD nativa do GitHub: você
descreve, em um arquivo YAML dentro do próprio repositório, o que deve
acontecer e quando. Sem servidor de CI pra instalar ou manter — o GitHub
fornece a máquina que executa tudo.

```
.github/workflows/deploy.yml
├── on (trigger)         → QUANDO a pipeline dispara
├── jobs                 → O QUE fazer, agrupado em blocos independentes
│   └── steps            → cada passo dentro de um job, em ordem
│       └── actions      → passos reutilizáveis, prontos, da comunidade
└── runner                → a máquina (efêmera) que executa tudo
```

### Trigger (`on`)

O evento que dispara o workflow. Nesta aula, usamos:

```yaml
on:
  push:
    branches: [main]
```

Ou seja: só dispara quando alguém envia commits **direto pra `main`**
(inclusive um merge de Pull Request). Push em outras branches, ou
abertura de PR, não aciona o deploy — evita publicar código que ainda
está em revisão.

### Job

Um bloco de trabalho independente, com sua própria máquina (runner) do
zero. Nesta aula teremos dois: `build-and-push` (a parte de CI) e
`deploy` (a parte de CD), com o segundo **dependendo** do primeiro:

```yaml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps: [...]

  deploy:
    needs: build-and-push   # só roda se o job acima terminar com sucesso
    runs-on: ubuntu-latest
    steps: [...]
```

> 💡 `needs` é o que garante a ordem "CI antes de CD": se o build falhar
> (ex: `Dockerfile` quebrado), o job `deploy` **nem começa a rodar** — a
> versão antiga continua servindo tráfego, intacta.

### Runner

A máquina virtual que executa um job. `ubuntu-latest` é uma VM Linux
**efêmera** — sobe do zero pra cada execução, roda os steps, e é
destruída no final. Nada persiste de uma execução pra outra (por isso
cada job refaz o `checkout` do código e o login na AWS).

### Step e Action

Um **step** é um passo dentro de um job — pode ser um comando de shell
(`run:`) ou o uso de uma **action** (`uses:`), que é um passo pronto,
publicado pela comunidade ou pela própria AWS/GitHub, parametrizável.
Nesta aula usamos actions oficiais da AWS para autenticação e deploy no
ECS, em vez de reescrever essa lógica em shell script:

| Action | Papel |
|---|---|
| `actions/checkout` | Traz o código do repositório pra dentro do runner |
| `aws-actions/configure-aws-credentials` | Autentica o runner na AWS usando os Secrets |
| `aws-actions/amazon-ecr-login` | Faz o login do Docker no ECR |
| `aws-actions/amazon-ecs-render-task-definition` | Gera uma nova revisão da Task Definition, trocando só a imagem |
| `aws-actions/amazon-ecs-deploy-task-definition` | Registra a revisão nova e atualiza o Service (rolling deployment) |

---

## 🔐 Secrets — credenciais sem expor no código

Um workflow precisa de credenciais AWS pra falar com o ECR e o ECS — e
essas credenciais **nunca** podem ficar escritas no `deploy.yml` (esse
arquivo é público, ou pelo menos versionado, e qualquer um com acesso ao
repositório o leria). O GitHub Actions resolve isso com **Secrets**:
valores criptografados, configurados na interface do repositório
(**Settings → Secrets and variables → Actions**), acessíveis dentro do
workflow via `${{ secrets.NOME_DO_SECRET }}` — nunca aparecem nos logs
da execução, mesmo se alguém tentar dar `echo` neles de propósito (o
GitHub mascara automaticamente).

> ⚠️ **AWS Academy é um caso particular.** As credenciais do Learner Lab
> são **temporárias** (access key + secret key + **session token**, que
> expiram em poucas horas) — diferente de uma IAM User "de verdade", que
> teria uma access key permanente. Isso tem uma consequência prática
> direta pra pipeline: os Secrets precisam ser **atualizados a cada nova
> sessão de estudo**, ou o workflow começa a falhar com erro de
> autenticação no meio do nada. Vamos tratar isso com calma no módulo 03.

---

## 🔄 Do lado do ECS: o que já vimos, revisitado

O rolling deployment em si **não é coisa nova desta aula** — o ECS já
faz isso por padrão desde a Aula 04 (foi adiantado no módulo
[06-organizacao-e-boas-praticas](<../Aula 04 - ECS e Deploy Gerenciado de Containers/06-organizacao-e-boas-praticas/README.md>)
de lá). O que muda aqui é **quem aciona** esse mecanismo: até agora, era
você digitando `aws ecs update-service --force-new-deployment` na mão;
a partir de agora, é a action `amazon-ecs-deploy-task-definition`,
automaticamente, a cada `push`.

```
Antes (Aula 04, manual)                Agora (Aula 05, automático)
──────────────────────                 ───────────────────────────
docker build                           git push
docker tag                                  │
docker push                                 ▼
aws ecs update-service                 GitHub Actions faz tudo isso,
  --force-new-deployment               na mesma ordem, sozinho
```

---

## ✅ Boas práticas

1. **Nunca** coloque uma credencial direto no YAML — sempre via Secrets.
2. **Separe CI de CD em jobs distintos**, com `needs` — um build quebrado
   nunca deve conseguir chegar a um deploy.
3. **Restrinja o trigger à branch principal** — evita que qualquer branch
   de experimento dispare um deploy real em produção.
4. **Tagueie a imagem pelo hash do commit** (`github.sha`), não só
   `latest` — cada deploy fica rastreável até o código exato que o
   gerou (retomamos essa ideia no módulo 04).

---

## 🧪 Exercício

1. Com suas próprias palavras, explique a diferença entre **Continuous
   Integration** e **Continuous Deployment**.
2. Por que o job `deploy` usa `needs: build-and-push`? O que aconteceria
   se os dois jobs rodassem em paralelo, sem essa dependência?
3. Por que as credenciais da AWS não podem ficar escritas diretamente no
   arquivo `deploy.yml`, mesmo em um repositório privado?
4. Explique, com suas palavras, por que credenciais temporárias do AWS
   Academy (com *session token*) são uma complicação a mais para uma
   pipeline de CI/CD, comparado a uma credencial permanente de uma conta
   AWS "de verdade".
5. O rolling deployment do ECS não é um conceito novo desta aula — onde
   ele foi introduzido, e o que muda, na prática, em como ele é
   **acionado** a partir de agora?

**Próximo passo:** [02-preparando-o-repositorio](../02-preparando-o-repositorio/README.md)
