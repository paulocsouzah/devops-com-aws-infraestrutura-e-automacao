# Exercício Final — terraform-aula05

Chegou a hora de fechar a aula validando, de ponta a ponta, a pipeline
que você construiu desde o módulo 02.

Nos módulos anteriores você praticou cada peça isoladamente: o primeiro
workflow disparando (módulo 02), autenticação com credenciais do
Learner Lab (módulo 03), build e push automáticos (módulo 04) e deploy
automático no ECS (módulo 05). Este módulo é sobre rodar o fluxo
**completo, do zero, e documentar**.

---

## 🎯 O que você vai validar

```
 Você edita o código do app-aula03
        │
        ▼
   git push (branch main)
        │
        ▼
┌───────────────────────── GitHub Actions ─────────────────────────┐
│  build-and-push                    deploy (needs: build-and-push)  │
│  • login no ECR                    • baixa Task Definition atual   │
│  • docker build+tag+push           • renderiza nova revisao        │
│    (frontend + api, tag = SHA)     • registra + atualiza Service   │
│                                     • aguarda estabilidade          │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
  ECS Fargate troca as tasks aos poucos (rolling deployment)
        │
        ▼
  ALB serve a versão nova — zero downtime, zero comando manual
```

- **Infraestrutura** — a mesma da Aula 04 (rede, RDS, ECR, Cluster ECS
  Fargate, ALB, Auto Scaling), sem nenhuma mudança nos arquivos
  `.tf` desta aula.
- **Pipeline** — um workflow do GitHub Actions, no repositório
  `app-aula03`, com dois jobs: `build-and-push` (CI) e `deploy` (CD).
- **Credenciais** — Secrets do GitHub com as credenciais temporárias do
  Learner Lab (módulo 03).
- **Resultado** — todo `push` na `main` do `app-aula03` termina com a
  aplicação atualizada no ar, sem um único comando `docker` ou `aws ecs`
  digitado por você.

---

## 🛠️ Passo a passo

### 1. Preparar o ambiente

Inicie o Lab, atualize `~/.aws/credentials` e confirme que o Docker está
rodando na sua máquina.

### 2. Conferir se `00-pratica/` está completa

```
00-pratica/
├── main.tf, variables.tf, network.tf, network-alb.tf, network-rds.tf
├── security-group-ecs.tf, rds.tf, ecr.tf, ecs-cluster.tf, alb.tf
├── ecs-task-definitions.tf, ecs-services.tf, autoscaling.tf
├── dashboard.js, outputs.tf
└── terraform.tfvars              # só db_password (NÃO commitar)
```

Idêntica à da Aula 04 — se algo estiver faltando, volte lá.

### 3. Atualizar `project_name` e aplicar

Confirme, em `variables.tf`, que `project_name` está `"aula05"` (não
mais `"aula04"`), depois:

```bash
cd 00-pratica
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### 4. Confirmar o repositório `app-aula03` e o workflow completo

No repositório `app-aula03` (o seu, no GitHub), confirme que
`.github/workflows/deploy.yml` tem os dois jobs completos (módulos 04 e
05) e que os três Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
`AWS_SESSION_TOKEN`) estão atualizados com a sessão atual do Lab.

### 5. Fazer uma mudança real e visível

No clone separado do `app-aula03` (fora do material do curso — a mesma
pasta dos módulos 02-05), edite algo visível no frontend (ex: um texto,
uma cor em `frontend/src/App.jsx`) — isso vai provar que a versão que
está no ar depois do deploy é, de fato, a nova:

```bash
git add .
git commit -m "feat: ajusta texto da tela inicial"
git push origin main
```

### 6. Acompanhar a pipeline

Na aba **Actions** do `app-aula03` (no navegador), acompanhe os dois
jobs até ficarem verdes. Se quiser acompanhar pelo terminal também
(opcional), veja o comando de repetição (Windows/Mac/Linux) no módulo
05, seção "Passo 3".

### 7. Validar a aplicação atualizada

```bash
terraform output alb_dns_name
```

Acesse `http://<alb_dns_name>/` e confirme que a mudança do passo 5 está
visível — prova de que o deploy automático realmente publicou o código
novo, e não uma versão em cache.

### 8. Testar zero downtime

Deixe uma aba do navegador dando refresh a cada poucos segundos durante
um novo `push`, e confirme que a aplicação nunca fica indisponível.

### 9. Destruir ao final

```bash
terraform destroy
```

⚠️ **Não deixe o ALB nem as tasks Fargate rodando sem necessidade** —
os dois cobram por hora, mesmo sem tráfego. A pipeline não muda essa
regra.

---

## ✅ Checklist técnico

- [ ] `00-pratica/` aplicada com `project_name = "aula05"`
- [ ] `.github/workflows/deploy.yml` com os jobs `build-and-push` e `deploy` completos
- [ ] Três Secrets AWS atualizados com a sessão atual do Lab
- [ ] `git push` disparou a pipeline automaticamente, sem intervenção manual
- [ ] Job `build-and-push` publicou as duas imagens no ECR, tagueadas pelo commit
- [ ] Job `deploy` registrou nova revisão e atualizou os dois Services
- [ ] Aplicação no ar reflete a mudança do commit, validada pelo DNS do ALB
- [ ] Nenhum `docker push` ou `aws ecs update-service` executado manualmente nesta validação
- [ ] `terraform destroy` executado ao final, ambiente limpo

---

## 📄 Entrega: relatório em PDF

### O que o PDF precisa conter

1. **Capa** — seu nome completo e a data de entrega.
2. **Prints de tela** de, no mínimo:
   - o `deploy.yml` completo do seu `app-aula03`;
   - a execução da pipeline, verde, com os dois jobs (`build-and-push` e
     `deploy`) na aba **Actions**;
   - `aws ecr describe-images` mostrando a imagem nova, tagueada pelo
     commit;
   - `describe-services` mostrando a revisão da Task Definition antes e
     depois do deploy;
   - a aplicação no navegador, com a mudança visível do passo 5;
   - `terraform destroy` concluído ao final.
3. **Os comandos que você executou**, na ordem.
4. **Respostas escritas, com suas próprias palavras**, para as perguntas
   de reflexão abaixo.
5. **Dificuldades encontradas** — pelo menos um problema real (ex:
   credencial expirada) e como resolveu.

### Perguntas de reflexão (responda todas no PDF)

1. Compare, com suas próprias palavras, o fluxo de atualizar a aplicação
   na Aula 04 (manual) com o fluxo desta aula (automático). Quantos
   comandos manuais existiam antes, e quantos existem agora?
2. Explique a diferença entre o job `build-and-push` e o job `deploy`.
   Por que eles são jobs separados, em vez de um único job com todos os
   steps?
3. O que é uma **credencial temporária**, e por que ela obriga você a
   atualizar os Secrets do GitHub a cada nova sessão do Learner Lab?
   Como isso seria diferente numa conta AWS "de produção"?
4. Descreva, com suas palavras, o papel de cada uma das quatro actions
   oficiais da AWS usadas na pipeline (`configure-aws-credentials`,
   `amazon-ecr-login`, `amazon-ecs-render-task-definition`,
   `amazon-ecs-deploy-task-definition`).
5. Por que a imagem é tagueada com o hash do commit (`github.sha`), e
   não só com `latest`? Que problema isso evita?
6. Se um `push` introduzisse um bug visível só depois do deploy (não um
   crash, algo mais sutil), como você reverteria essa mudança usando o
   que aprendeu no módulo 06?

### Prazo e envio

Envie o PDF por e-mail (ou pelo canal combinado em sala) até a data que
eu informar durante a aula. Nomeie o arquivo como
`terraform-aula05-SEUNOME.pdf`.

---

## 📊 Rubrica de avaliação

| Critério | Pontos |
|---|---|
| Workflow do GitHub Actions criado e disparando corretamente no `push` | 1,5 |
| Secrets configurados corretamente, autenticação AWS funcionando | 1,0 |
| Job de build/push: duas imagens publicadas no ECR, tagueadas pelo commit | 2,0 |
| Job de deploy: nova revisão da Task Definition registrada e Service atualizado | 2,5 |
| Rolling deployment validado sem downtime, aplicação refletindo a mudança | 1,5 |
| Nenhum comando de build/push/deploy executado manualmente na validação final | 1,0 |
| Relatório completo: prints, comandos e explicações próprias | 0,25 |
| Respostas às perguntas de reflexão demonstrando entendimento real | 0,25 |
| **Total** | **10,0** |

Parabéns por chegar até aqui — sua aplicação agora se atualiza sozinha a
cada `push`, com o mesmo rigor (build, publicação, rollout gradual) que
times de engenharia usam em produção todos os dias. O próximo passo
natural, que vem na Aula 06, é conseguir **enxergar** o que está
acontecendo lá dentro sem precisar ficar rodando `describe-*` na mão. 🔄
