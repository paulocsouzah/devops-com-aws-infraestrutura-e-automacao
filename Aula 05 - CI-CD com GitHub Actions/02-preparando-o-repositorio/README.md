# 2. Preparando o Repositório

Antes de escrever qualquer linha de deploy automático, vale deixar bem
claro **onde** cada coisa vive — é o erro mais comum de quem está
começando com CI/CD: procurar o resultado da pipeline no lugar errado.

---

## 📍 Dois repositórios, dois papéis

| Repositório | O que tem dentro | Onde a pipeline roda |
|---|---|---|
| **Este** (material da disciplina) | Terraform (`00-pratica/`), READMEs das aulas | **Nunca** — não tem código de aplicação pra buildar |
| **`app-aula03`** (o seu, no GitHub) | Código-fonte do frontend (React) e da api (Node.js) | **Aqui** — é aqui que o `.github/workflows/deploy.yml` vai morar |

O `app-aula03` já existe na sua conta do GitHub desde a Aula 03 (e você
já clonou uma cópia dele pra dentro de `00-pratica/` na Aula 04, módulo
02, pra buildar as imagens na mão). A partir de agora, o repositório
**de verdade** — o que fica no seu GitHub, não a cópia local — ganha uma
pasta nova: `.github/workflows/`.

> 💡 O GitHub reconhece automaticamente qualquer arquivo `.yml` dentro de
> `.github/workflows/` como um workflow do Actions — não precisa
> registrar em lugar nenhum, nem instalar nada. Basta o arquivo existir
> na branch, com a sintaxe correta.

---

## 🛠️ Passo a passo

### 1. Clonar (ou entrar na) sua cópia local do `app-aula03`

```bash
git clone https://github.com/SEU_USUARIO/app-aula03.git
cd app-aula03
```

Se você já tem uma cópia local (fora do `00-pratica/`), só entre nela e
confirme que está na branch `main`, atualizada:

```bash
git checkout main
git pull
```

### 2. Criar a pasta do workflow

```bash
mkdir -p .github/workflows
```

### 3. Criar um workflow mínimo, só para provar que dispara

Antes de automatizar build e deploy de verdade (módulos 04 e 05), vale
confirmar que o básico funciona: o GitHub reconhece o arquivo, dispara no
`push`, e executa um step simples.

Crie `.github/workflows/deploy.yml`:

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

      - name: Confirmar que a pipeline disparou
        run: echo "Pipeline disparada pelo commit ${{ github.sha }}"
```

### 4. Commitar e enviar

```bash
git add .github/workflows/deploy.yml
git commit -m "ci: adiciona workflow inicial do GitHub Actions"
git push origin main
```

### 5. Acompanhar a execução

No GitHub, abra o repositório `app-aula03` → aba **Actions**. Deve
aparecer uma execução em andamento (bolinha amarela) e, em segundos,
concluída com sucesso (✅ verde). Clique nela → clique no job
`build-and-push` → confira o log do step "Confirmar que a pipeline
disparou", mostrando o hash do commit.

> ⚠️ Se a aba **Actions** não existir, ou mostrar "Workflows aren't being
> run on this forked repository" — confirme nas configurações do
> repositório (**Settings → Actions → General**) que "Allow all actions
> and reusable workflows" está habilitado. Isso é comum em repositórios
> criados a partir de um fork/template com Actions desabilitadas por
> padrão.

---

## 🧭 Anatomia do que você acabou de rodar

```yaml
name: Deploy                    # nome exibido na aba Actions
on:
  push:
    branches: [main]            # trigger: só push direto na main

jobs:
  build-and-push:                # 1 job por enquanto — mais um vem no módulo 04
    runs-on: ubuntu-latest       # runner: VM Linux efêmera, do zero a cada execução
    steps:
      - uses: actions/checkout@v4     # step com action pronta
      - run: echo "..."               # step com comando de shell
```

Esse é o esqueleto que os módulos 03, 04 e 05 vão preencher: primeiro as
credenciais AWS como Secrets, depois o job de build/push das imagens, por
fim o job de deploy no ECS.

---

## ✅ Checklist técnico

- [ ] `app-aula03` clonado/atualizado localmente, na branch `main`
- [ ] `.github/workflows/deploy.yml` criado, com o workflow mínimo acima
- [ ] Commit enviado para o `main` do **seu** `app-aula03` no GitHub
- [ ] Execução aparece, verde, na aba **Actions** do repositório
- [ ] Log do step confirma o hash do commit que disparou a pipeline

---

## 🧪 Exercício

1. Siga o passo a passo e guarde o print da execução verde na aba
   **Actions**.
2. Faça um segundo commit qualquer (ex: editar o `README.md` do
   `app-aula03`) e dê `push`. A pipeline dispara de novo automaticamente?
   O que isso prova sobre o trigger `on: push: branches: [main]`?
3. O que aconteceria se você desse `push` numa branch chamada
   `feature/teste`, em vez de `main`? A pipeline dispararia? Por quê?
4. Por que faz sentido o workflow viver dentro do repositório
   `app-aula03`, e não dentro deste repositório de material da
   disciplina?

**Próximo passo:** [03-exercicio-01-secrets-e-permissoes](../03-exercicio-01-secrets-e-permissoes/README.md)
