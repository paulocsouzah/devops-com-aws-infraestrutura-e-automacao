# 5. Exercício 03 — Deploy Automático (Nova Revisão + Rolling Deployment)

Este é o módulo que fecha a pipeline: com as imagens novas publicadas no
ECR (módulo 04), falta ensinar o ECS a **usá-las** — registrando uma
nova revisão da Task Definition e atualizando o Service, sem downtime,
sem você digitar um único comando `aws ecs`.

---

## 🧩 O que precisa acontecer, em ordem

```
1. Baixar a Task Definition ATUAL (a que está registrada agora no ECS)
2. Trocar só o campo "image" pela imagem nova (tag = hash do commit)
3. Registrar isso como uma NOVA REVISÃO da Task Definition
4. Atualizar o Service para usar essa revisão nova
5. Esperar o rolling deployment terminar (tasks novas saudáveis,
   tasks antigas desligadas) antes de considerar o job concluído
```

Cada um desses passos tem uma action oficial da AWS que faz exatamente
aquilo — não precisamos escrever `jq`/shell pra manipular o JSON da Task
Definition na mão.

| Passo | Action |
|---|---|
| 1-3 (baixar + trocar imagem + preparar nova revisão) | `aws-actions/amazon-ecs-render-task-definition` |
| 4-5 (registrar, atualizar Service, aguardar estabilidade) | `aws-actions/amazon-ecs-deploy-task-definition` |

---

## 📂 Onde trabalhar

Adicione o segundo job, `deploy`, ao `.github/workflows/deploy.yml` do
`app-aula03` — ele roda **depois** do `build-and-push` (`needs:`), uma
vez para cada Service (`frontend` e `api`):

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

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
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

      # --- frontend ---
      - name: Baixar Task Definition atual — frontend
        run: |
          aws ecs describe-task-definition \
            --task-definition aula05-frontend \
            --query "taskDefinition" > task-def-frontend.json

      - name: Renderizar nova revisão — frontend
        id: render-frontend
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-def-frontend.json
          container-name: frontend
          image: ${{ steps.login-ecr.outputs.registry }}/aula05-frontend:${{ github.sha }}

      - name: Deploy — frontend
        uses: aws-actions/amazon-ecs-deploy-task-definition@v2
        with:
          task-definition: ${{ steps.render-frontend.outputs.task-definition }}
          service: aula05-frontend
          cluster: aula05-cluster
          wait-for-service-stability: true

      # --- api ---
      - name: Baixar Task Definition atual — api
        run: |
          aws ecs describe-task-definition \
            --task-definition aula05-api \
            --query "taskDefinition" > task-def-api.json

      - name: Renderizar nova revisão — api
        id: render-api
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-def-api.json
          container-name: api
          image: ${{ steps.login-ecr.outputs.registry }}/aula05-api:${{ github.sha }}

      - name: Deploy — api
        uses: aws-actions/amazon-ecs-deploy-task-definition@v2
        with:
          task-definition: ${{ steps.render-api.outputs.task-definition }}
          service: aula05-api
          cluster: aula05-cluster
          wait-for-service-stability: true
```

> 💡 **`container-name` precisa bater exatamente** com o `name` definido
> dentro do `container_definitions` da Task Definition (veja
> `ecs-task-definitions.tf`, Aula 04) — é assim que a action sabe *qual*
> container, dentro da Task Definition, deve receber a imagem nova. Uma
> Task Definition pode ter vários containers; aqui cada uma tem só um.
>
> 💡 **`wait-for-service-stability: true`** é o que faz o job ficar
> "rodando" até o ECS confirmar que as tasks novas estão saudáveis no
> Target Group **e** as antigas foram desligadas — sem isso, o workflow
> terminaria "verde" no instante em que a nova revisão fosse só
> *registrada*, antes de saber se ela realmente sobe com sucesso.
>
> 💡 Repare que o job `deploy` **não** reaproveita nenhum arquivo do job
> `build-and-push` — cada job roda num runner novo, do zero (voltando ao
> módulo 01). Por isso ele refaz o `checkout` (implícito, via
> `describe-task-definition` que não depende de arquivos do repo) e o
> login no ECR.

---

## 🛠️ Passo a passo

### 1. Confirmar os nomes exatos

Antes de colar o YAML, confirme o nome do Cluster e dos Services (deve
bater com `project_name = "aula05"` do seu `variables.tf`):

```bash
cd 00-pratica
terraform output
aws ecs list-services --cluster aula05-cluster
```

### 2. Atualizar o workflow e enviar

```bash
cd app-aula03
git add .github/workflows/deploy.yml
git commit -m "ci: adiciona deploy automatico no ECS (nova revisao + rolling deployment)"
git push origin main
```

### 3. Acompanhar o rolling deployment em tempo real

Enquanto o job `deploy` roda, acompanhe pelo terminal (numa segunda
aba) as tasks trocando:

```bash
watch -n 5 'aws ecs describe-services --cluster aula05-cluster \
  --services aula05-frontend aula05-api \
  --query "services[].{Nome:serviceName,Rodando:runningCount,Desejado:desiredCount,Revisao:taskDefinition}" \
  --output table'
```

Você deve ver o `Revisao` (o número no fim do ARN da Task Definition)
mudar, e `Rodando` oscilar (sobe uma task nova, depois desce uma
antiga) até se estabilizar de novo em `Rodando == Desejado`.

### 4. Validar a aplicação

```bash
terraform output alb_dns_name
```

Acesse `http://<alb_dns_name>/` — a aplicação deve continuar respondendo
**o tempo todo**, inclusive durante a troca de tasks (é essa a garantia
do rolling deployment: zero downtime).

---

## ✅ Checklist técnico

- [ ] Job `deploy` adicionado, com `needs: build-and-push`
- [ ] `container-name` de cada `render-task-definition` bate com o nome real do container
- [ ] Pipeline completa (os dois jobs) executa verde na aba **Actions**
- [ ] `taskDefinition` de cada Service mostra uma revisão **nova** (número maior que antes)
- [ ] Aplicação respondeu sem interrupção durante o deploy
- [ ] Nenhum comando `aws ecs update-service` foi digitado manualmente

---

## 🧪 Exercício

1. Siga o passo a passo e guarde prints: o job `deploy` verde na aba
   **Actions**, e o `describe-services` mostrando a revisão da Task
   Definition antes e depois do `push`.
2. Faça uma alteração visível no frontend, dê `push`, e **fique com o
   navegador aberto** na aplicação, dando refresh a cada poucos
   segundos durante o deploy. Em algum momento você viu a aplicação
   fora do ar? O que isso prova sobre o rolling deployment?
3. Por que a pipeline precisa **baixar** a Task Definition atual
   (`describe-task-definition`) antes de poder gerar a nova revisão, em
   vez de simplesmente criar uma do zero?
4. O que `wait-for-service-stability: true` está fazendo, exatamente? O
   que mudaria (de errado) se essa opção não existisse?
5. **Desafio:** se você colocasse, de propósito, uma imagem quebrada
   (que crasha ao subir) e desse `push`, o que aconteceria com o
   rolling deployment? A aplicação ficaria fora do ar? Pesquise o
   comportamento padrão do ECS quando as tasks novas nunca ficam
   saudáveis (dica: `deployment_circuit_breaker`).

**Próximo passo:** [06-organizacao-e-boas-praticas](../06-organizacao-e-boas-praticas/README.md)
