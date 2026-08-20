# 2. Preparando o Repositório

Antes de escrever qualquer linha de deploy automático, vale deixar bem
claro **onde** cada coisa vive — é o erro mais comum de quem está
começando com CI/CD: procurar (ou criar) coisa no lugar errado. Este
módulo é só sobre isso, com bastante calma.

---

## 📍 Dois repositórios — não confunda os dois

Você vai lidar com **dois** repositórios diferentes ao longo desta aula.
São coisas completamente separadas, em lugares diferentes do seu
computador e do seu GitHub:

| | **Repositório do material da disciplina** | **Repositório `app-aula03`** |
|---|---|---|
| O que é | Este que você está lendo agora (com as pastas `Aula 01`, `Aula 02`, etc.) | O seu projeto de aplicação (React + Node.js), que existe **na sua conta pessoal do GitHub** desde a Aula 03 |
| Onde fica no seu computador | Onde você baixou/clonou o material do curso | Um clone **separado**, em outra pasta do seu computador |
| Tem uma cópia dentro de `00-pratica/`? | — | **Sim, mas essa cópia não conta.** Ela foi colocada lá só pra buildar imagens Docker na mão (Aula 04) e **não está conectada ao GitHub** (o `.git` dela foi removido de propósito) |
| Onde a pipeline do GitHub Actions roda | **Nunca** — este repositório não tem aplicação nenhuma pra buildar | **Aqui** — é neste repositório que o arquivo `.github/workflows/deploy.yml` precisa existir |

> ⚠️ **O erro mais comum deste módulo:** criar o arquivo `.github/workflows/deploy.yml`
> dentro da pasta `app-aula03` que está **dentro** de `00-pratica/` (a
> cópia da Aula 04). Isso **não funciona** — essa cópia não está
> conectada ao GitHub, então nada é enviado, nada dispara. O arquivo
> precisa estar no **outro** clone, o que tem o próprio `.git` apontando
> pro seu GitHub.

---

## 🗂️ Passo 1 — Escolher (ou criar) uma pasta separada, fora do material do curso

Antes de clonar, decida onde esse segundo repositório vai morar no seu
computador. **Não** coloque ele dentro da pasta do material do curso
(a que tem as pastas `Aula 01`, `Aula 02`...). Uma boa opção é criar uma
pasta neutra, por exemplo na sua Área de Trabalho / Desktop:

**Windows (PowerShell):**
```powershell
cd $HOME\Desktop
mkdir meus-projetos-github
cd meus-projetos-github
```

**Mac/Linux (Terminal):**
```bash
cd ~/Desktop
mkdir meus-projetos-github
cd meus-projetos-github
```

A partir daqui, **todo comando deste módulo (e dos módulos 03, 04 e 05)
roda de dentro desta pasta `meus-projetos-github`** (ou de dentro da
pasta `app-aula03` que vai nascer dentro dela no próximo passo) —
**nunca** de dentro da pasta do material do curso.

---

## 📥 Passo 2 — Trazer o `app-aula03` para esta pasta

### Se você **ainda não tem** um clone do `app-aula03` fora do material do curso

Rode (troque `SEU_USUARIO` pelo seu usuário real do GitHub — no seu
caso, é `paulocsouzah`):

```bash
git clone https://github.com/SEU_USUARIO/app-aula03.git
cd app-aula03
```

O comando `git clone` baixa uma cópia completa do repositório do GitHub
pro seu computador, dentro de uma pasta nova chamada `app-aula03`
(criada automaticamente). O `cd app-aula03` só entra nela.

### Se você **já tem** um clone (de um módulo anterior)

Entre na pasta onde ele está e atualize:

```bash
cd caminho/para/sua/pasta/app-aula03
git checkout main
git pull
```

### ✅ Confirme que está no lugar certo

Depois de entrar na pasta, rode:

```bash
git remote -v
```

Você **precisa** ver uma saída parecida com esta (com o seu usuário no
lugar de `paulocsouzah`, se for diferente):

```
origin  https://github.com/paulocsouzah/app-aula03.git (fetch)
origin  https://github.com/paulocsouzah/app-aula03.git (push)
```

Se aparecer isso, você está no repositório certo — pode seguir. Se der
erro (`not a git repository`) ou mostrar outra URL, pare e confira o
Passo 1 e 2 de novo antes de continuar.

---

## 🛠️ Passo 3 — Criar a pasta do workflow

Ainda dentro da pasta `app-aula03` (confirmada no passo anterior), rode:

```bash
mkdir -p .github/workflows
```

Esse comando cria duas pastas de uma vez: `.github`, e dentro dela,
`workflows`. É exatamente aí — nesse caminho, e só nesse caminho — que o
GitHub procura por arquivos de pipeline. O nome não pode ser diferente
(nem `.Github`, nem `workflow` no singular).

> 💡 Pastas que começam com ponto (`.github`) costumam ficar
> **escondidas** no explorador de arquivos do Windows/Mac por padrão.
> Isso é normal — use o terminal (como estamos fazendo) pra criar e
> editar os arquivos dela, em vez de procurar ela visualmente.

---

## ✍️ Passo 4 — Criar o arquivo do workflow

Abra a pasta `app-aula03` no **VS Code** (ou o editor de texto que você
preferir). Pelo terminal, de dentro da pasta `app-aula03`:

```bash
code .
```

No VS Code, crie um arquivo novo em `.github/workflows/deploy.yml`
(clique com o botão direito na pasta `workflows`, no menu lateral, →
**New File** → digite `deploy.yml`). Cole exatamente este conteúdo:

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

> ⚠️ **Atenção com a indentação.** YAML usa espaços (não Tab) pra
> definir a hierarquia — se colar e a indentação vier estranha, apague
> e cole de novo com cuidado. Um espaço a mais ou a menos muda o
> significado do arquivo (ou quebra ele).

Salve o arquivo (`Ctrl+S` ou `Cmd+S`).

---

## 📤 Passo 5 — Enviar para o GitHub

De volta ao terminal, ainda dentro da pasta `app-aula03`:

```bash
git add .github/workflows/deploy.yml
git commit -m "ci: adiciona workflow inicial do GitHub Actions"
git push origin main
```

O que cada comando faz, em ordem:

1. `git add` → marca o arquivo pra ser incluído no próximo commit.
2. `git commit` → salva essa mudança no histórico do Git, localmente no
   seu computador, com uma mensagem explicando o que mudou.
3. `git push` → **envia** esse commit pro GitHub (`origin` = o
   repositório remoto, `main` = a branch). É só depois deste comando
   que o arquivo existe **de verdade** no GitHub — antes disso, ele só
   existia no seu computador.

Se pedir usuário/senha (ou token) do GitHub e você não tiver certeza de
como autenticar, veja a seção de troubleshooting abaixo.

---

## 👀 Passo 6 — Acompanhar a execução no navegador

1. Abra o **navegador** e acesse `https://github.com/SEU_USUARIO/app-aula03`
   (o seu repositório de verdade, no site do GitHub).
2. No menu horizontal, perto do topo da página (ao lado de "Code",
   "Issues", "Pull requests"...), clique na aba **Actions**.
3. Deve aparecer uma execução recente, com o nome do seu commit. No
   começo, ela mostra uma bolinha **amarela** (rodando); em alguns
   segundos, vira um ✅ **verde** (sucesso) ou ❌ **vermelho** (falhou).
4. Clique em cima dessa execução → clique no bloco `build-and-push`
   (do lado esquerdo) → clique no step "Confirmar que a pipeline
   disparou" → deve aparecer o texto `Pipeline disparada pelo commit
   <um monte de letras e números>`.

**Tire um print desta tela (verde, com o log aberto)** — é a evidência
de que a pipeline está funcionando, e também vai servir de imagem no
material da aula.

> ⚠️ **Se a aba "Actions" não aparecer, ou mostrar uma mensagem dizendo
> que Actions está desabilitado:** vá em **Settings** (aba do
> repositório, não do seu perfil) → **Actions** (menu da esquerda) →
> **General** → em "Actions permissions", marque **"Allow all actions
> and reusable workflows"** → **Save**. Isso é comum em repositórios
> mais antigos ou criados de um jeito específico, com Actions desligado
> por padrão.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| `git push` pede usuário e senha, e a senha normal não funciona | O GitHub não aceita mais senha de conta no `git push` desde 2021 — você precisa de um **Personal Access Token** (Settings do GitHub → Developer settings → Personal access tokens → Generate new token) usado **no lugar** da senha, ou configurar autenticação via SSH. Se travar aqui, me avisa que eu te guio. |
| `fatal: not a git repository` | Você não está dentro da pasta `app-aula03` clonada — confira com `pwd` (mostra a pasta atual) e `git remote -v` (Passo 2) |
| A aba **Actions** não mostra nenhuma execução | Confirme que o `push` foi realmente pra branch `main` (`git branch` mostra a branch atual com um `*`) e que o arquivo está exatamente em `.github/workflows/deploy.yml` (sem erro de digitação no caminho) |
| Erro amarelo/vermelho estranho no YAML | Confira a indentação (Passo 4) — copie o bloco de novo, com cuidado, sem misturar Tab com espaço |

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
fim o job de deploy no ECS. Você vai **editar este mesmo arquivo**
(`app-aula03/.github/workflows/deploy.yml`) em cada um dos próximos
módulos — nunca criar um arquivo novo.

---

## ✅ Checklist técnico

- [ ] Pasta separada criada, fora do material do curso (Passo 1)
- [ ] `app-aula03` clonado ali dentro, `git remote -v` confirma a URL correta (Passo 2)
- [ ] `.github/workflows/deploy.yml` criado, com o workflow mínimo (Passos 3 e 4)
- [ ] Commit enviado para o `main` do **seu** `app-aula03` no GitHub (Passo 5)
- [ ] Execução aparece, verde, na aba **Actions** do repositório (Passo 6)
- [ ] Print guardado da execução verde com o log aberto

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
