# 6. Organização, Operação e Boas Práticas

Com a pipeline completa rodando, vale parar pra entender como operá-la
com segurança no dia a dia — o que fazer quando ela falha, como evitar
os erros mais comuns, e como reverter um deploy problemático.

---

## 🚦 Concorrência: dois `push`s quase juntos

Se dois commits chegarem em sequência rápida, duas execuções do workflow
podem rodar **em paralelo**, e a segunda pode terminar (e fazer deploy)
**antes** da primeira — deixando uma versão mais antiga no ar por cima
de uma mais nova. O `concurrency` resolve isso, enfileirando execuções do
mesmo grupo:

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: false
```

Adicione essa chave no nível raiz do `deploy.yml` (mesmo nível de `on:`
e `jobs:`). Com `cancel-in-progress: false`, a segunda execução **espera**
a primeira terminar em vez de cancelá-la — garante que os deploys
aconteçam na ordem em que os commits chegaram.

---

## 🔐 Permissões mínimas do workflow

Por padrão, todo workflow recebe um `GITHUB_TOKEN` automático com
permissões amplas sobre o repositório (mesmo sem usarmos esse token pra
nada aqui — a autenticação real é toda via Secrets da AWS). Boa prática
é declarar explicitamente o mínimo necessário:

```yaml
permissions:
  contents: read
```

---

## ↩️ Rollback: voltar uma versão problemática

Um rolling deployment protege contra tasks que **nunca ficam saudáveis**
(módulo 05, exercício 5) — mas não contra um bug que só aparece depois,
com a aplicação já no ar. Duas formas de reverter:

**1. Re-rodar uma execução antiga da pipeline** — na aba **Actions**,
abra a execução do commit anterior (bom), clique em **Re-run all jobs**.
Ele reconstrói e reimplanta exatamente aquela versão.

**2. `git revert` do commit problemático:**

```bash
git revert <hash-do-commit-ruim>
git push origin main
```

Isso cria um novo commit desfazendo a mudança, e a pipeline trata como
qualquer outro `push` normal — build, push, deploy da versão revertida.

> 💡 Note que as duas formas de rollback **passam pela pipeline de novo**
> — não existe um botão de "voltar direto" no ECS que já não seja, no
> fundo, registrar (de novo) uma Task Definition apontando pra uma
> imagem anterior.

---

## 🐛 Troubleshooting comum

1. **`ExpiredTokenException` / `UnrecognizedClientException`** →
   credencial do Learner Lab expirou. Volte ao módulo 03: atualize os
   três Secrets e reenvie/reexecute.
2. **`docker: no matching manifest` ou `exec format error` nas tasks** →
   mesma causa raiz do módulo 06 da Aula 04 (build feito com arquitetura
   errada). O runner `ubuntu-latest` do GitHub Actions já é `x86_64` por
   padrão, então isso é raro aqui — mas se você adicionar um step de
   build customizado, confira.
3. **`ClientException: Container ... does not exist in the task
   definition`** → o `container-name` do
   `amazon-ecs-render-task-definition` não bate com o nome real do
   container (confira `ecs-task-definitions.tf` da Aula 04).
4. **Job `deploy` fica muito tempo "rodando" e falha por timeout** → as
   tasks novas não estão ficando saudáveis. Mesmo troubleshooting do
   módulo 06 da Aula 04: `aws ecs describe-tasks` (campo
   `stoppedReason`) e `aws logs tail /ecs/aula05-api --follow`.
5. **Pipeline builda e publica, mas a aplicação não muda** → confirme
   que o `push` foi para a branch `main` (o trigger é restrito a ela) e
   que o job `deploy` de fato rodou (não só o `build-and-push`) — veja
   se `needs: build-and-push` está presente e se o job `deploy` aparece
   na execução.
6. **Dois `push`s seguidos, a versão errada "vence"** → falta o bloco
   `concurrency` (veja acima) — sem ele, execuções concorrentes podem
   terminar fora de ordem.

---

## 💰 Custos: nada muda aqui

A pipeline em si (GitHub Actions) é gratuita, dentro do limite de
minutos do plano gratuito do GitHub, para repositórios públicos e para
uso pessoal moderado. O que continua cobrando por hora é a
**infraestrutura**, exatamente como na Aula 04: ALB e tasks Fargate.
`terraform destroy` continua sendo obrigatório ao final de cada sessão
de estudo — a pipeline não muda essa regra.

---

## 📝 Resumo visual

| Prática | Por quê |
|---|---|
| `needs:` entre os jobs | Garante que CD só roda depois de CI passar |
| `concurrency` com `cancel-in-progress: false` | Evita deploys fora de ordem em `push`s simultâneos |
| Tag de imagem = hash do commit | Rastreabilidade: sempre dá pra saber qual código está no ar |
| `permissions: contents: read` | Princípio do menor privilégio no token automático do workflow |
| `wait-for-service-stability: true` | O job só termina "verde" se o deploy realmente estabilizou |
| Atualizar os 3 Secrets a cada sessão do Lab | Credencial temporária do Academy expira em poucas horas |
| `terraform destroy` ao final | ALB e Fargate cobram por hora, mesmo ociosos — a pipeline não muda isso |

---

## 🧪 Exercício

1. Adicione o bloco `concurrency` ao seu `deploy.yml` e explique, com
   suas palavras, o que ele evita.
2. Provoque de propósito um dos erros de troubleshooting acima (ex:
   corrompa um Secret) e documente a mensagem de erro exata que
   apareceu, e como você resolveu.
3. Faça um `git revert` de um commit anterior e acompanhe a pipeline
   reimplantar a versão revertida. Quanto tempo levou do `push` até a
   aplicação voltar ao estado anterior?
4. **Desafio:** por que um rollback via `git revert` é considerado mais
   rastreável (do ponto de vista de auditoria) do que simplesmente
   rodar `aws ecs update-service --task-definition <revisao-antiga>` na
   mão? Pense em quem, além de você, precisaria entender o que
   aconteceu depois.

**Próximo passo:** [07-exercicio-final](../07-exercicio-final/README.md)
