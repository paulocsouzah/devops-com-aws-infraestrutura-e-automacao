# 2. Imagens no Amazon ECR

O ECS nunca builda uma imagem — ele só **puxa** uma imagem pronta de um
registro. Na Aula 03, quem buildava a imagem era a própria EC2 (`docker
compose up --build`, dentro do `user_data`). Sem EC2, isso não existe
mais: a imagem precisa **já estar publicada** num registro antes do ECS
conseguir rodar ela.

---

## 📦 O que é o Amazon ECR

O **ECR (Elastic Container Registry)** é o registro de imagens Docker
**privado** da AWS — o equivalente ao Docker Hub ou ao GitHub Container
Registry (GHCR, que vamos usar na Aula 05), só que integrado nativamente
com IAM e com o resto dos serviços AWS.

Cada **repositório** no ECR guarda as versões (tags) de **uma** imagem.
Como nossa aplicação tem dois containers, vamos criar **dois**
repositórios: um para o `frontend`, outro para a `api`.

---

## 📂 Onde trabalhar

Crie o arquivo `ecr.tf` dentro de [`00-pratica/`](../00-pratica/README.md)
(essa pasta já deve ter chegado da Aula 03, com rede, RDS e EC2 prontos)
— os dois repositórios ECR, com scan de vulnerabilidades automático
(`scan_on_push`):

```hcl
resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr-frontend"
  }
}

resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr-api"
  }
}
```

> 💡 `force_delete = true` é obrigatório aqui: sem ele, `terraform
> destroy` falha mais tarde com `RepositoryNotEmptyException`, porque o
> `docker push` (passo 3 deste módulo) é manual — o Terraform não sabe
> que o repositório tem imagens dentro, só o ECR sabe. Veja o módulo 06
> para mais detalhes.
>
> 💡 `image_tag_mutability = "MUTABLE"` permite reenviar a tag `latest`
> várias vezes (útil agora, que estamos publicando na mão). Em produção
> madura — e é isso que a Aula 05 traz — o normal é `IMMUTABLE` com uma
> tag única por build (ex: o hash do commit), pra nunca correr o risco
> de duas pessoas usarem a mesma tag `latest` referindo-se a códigos
> diferentes.

---

## 🛠️ Passo a passo

### 1. Aplicar o `ecr.tf`

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
terraform apply
```

Confira: dois repositórios ECR criados, sem custo até você efetivamente
enviar (`push`) imagens pra eles.

### 2. Autenticar o Docker no ECR

O Docker precisa de um login temporário pra poder enviar imagens pro seu
registro privado:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

> 💡 Esse login expira depois de algumas horas — se um `docker push`
> começar a falhar com erro de autenticação mais tarde na aula, rode
> esse comando de novo.

### 3. Trazer o `app-aula03` para dentro de `00-pratica`

O código-fonte da aplicação (`app-aula03`) foi criado lá na Aula 03,
módulo 03. Pra manter `00-pratica/` autossuficiente (todo recurso
necessário desta aula dentro da própria pasta), traga uma cópia dele
pra cá **antes do passo 4**, como uma subpasta de `00-pratica/`:

```bash
cd 00-pratica
git clone https://github.com/SEU_USUARIO/app-aula03.git
rm -rf app-aula03/.git
```

> ⚠️ O `rm -rf app-aula03/.git` é obrigatório. Sem ele, o `app-aula03`
> continua sendo um repositório Git próprio dentro do seu repositório
> desta aula — o Git da pasta de fora enxerga isso como um único
> "gitlink" (submodule), não como arquivos de verdade. Resultado: quem
> clonar seu repo depois recebe uma pasta `app-aula03/` **vazia**, e o
> `docker build` do passo 4 falha. Depois de remover o `.git`, confirme
> com `git status app-aula03` — cada arquivo deve aparecer individualmente
> como `??`, não a pasta inteira como uma linha só.

### 4. Build, tag e push — frontend

```bash
cd app-aula03/frontend

docker build -t aula04-frontend .
docker tag aula04-frontend:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula04-frontend:latest
docker push \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula04-frontend:latest
```

> 💡 `aula04` aqui é o valor de `project_name` no Terraform — se você
> mudou o default em `variables.tf` pra outro nome, use o mesmo nome
> nos comandos abaixo.

### 5. Build, tag e push — api

```bash
cd ../api

docker build -t aula04-api .
docker tag aula04-api:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula04-api:latest
docker push \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aula04-api:latest
```

### 6. Conferir no Console (ou via CLI)

```bash
aws ecr describe-images --repository-name aula04-frontend --output table
aws ecr describe-images --repository-name aula04-api --output table
```

Deve aparecer uma imagem com a tag `latest` em cada repositório.

---

## 🤔 E o proxy `/api` dentro do nginx do frontend?

Se você olhar o `frontend/nginx.conf` do `app-aula03` (Aula 03, módulo
03), vai ver que ele ainda tem uma regra de proxy para `/api/`. Nesta
aula **não precisamos rebuildar a imagem de um jeito diferente** — é a
mesma imagem — mas duas coisas exigiram atenção real, encontradas
testando de verdade na AWS (não é só teoria):

**1. Resolução de DNS na inicialização, não só na hora do request.**
Um `nginx.conf` ingênuo, com `proxy_pass http://api:4000/;` direto
(hostname fixo, sem variável), faz o nginx tentar **resolver o nome
"api" uma única vez, na inicialização do container**. No ECS desta
aula, esse nome não existe em lugar nenhum (não há a rede do Docker
Compose) — e o container **nem chega a subir**, com o erro `host not
found in upstream "api"`. A correção é usar resolução **dinâmica** (via
variável + diretiva `resolver`), que só tenta resolver o nome se uma
requisição de verdade chegar naquela rota — o que nunca acontece aqui,
já que o ALB intercepta `/api/*` antes. O `nginx.conf` do `app-aula03`
já vem assim, comentado, exatamente por causa disso.

**2. O ALB não remove o prefixo `/api`.** Diferente de alguns
proxies/ingress que "reescrevem" o caminho, o Application Load Balancer
encaminha a requisição **com o path original completo** — uma chamada
em `/api/usuarios` chega no container da API como `/api/usuarios`,
não como `/usuarios`. Por isso as rotas da API (`app-aula03/api/index.js`)
vivem em `/api/usuarios`, não em `/usuarios` — e não por acaso: o
`nginx.conf` do frontend, usando `proxy_pass` com variável, tem
**exatamente o mesmo comportamento** de preservar o caminho completo.
As duas frentes (Nginx na Aula 03, ALB na Aula 04) tratam o prefixo
`/api` do mesmo jeito, e é por isso que a mesma imagem da API funciona
sem alteração nas duas aulas.

---

## ✅ Checklist técnico

- [ ] `ecr.tf` aplicado, dois repositórios criados
- [ ] `app-aula03` copiado para dentro de `00-pratica/`, sem `.git` aninhado
- [ ] Login do Docker no ECR realizado com sucesso
- [ ] Imagem do `frontend` buildada, taggeada e enviada (`push`)
- [ ] Imagem da `api` buildada, taggeada e enviada (`push`)
- [ ] `aws ecr describe-images` confirma as duas imagens com tag `latest`

---

## 🧪 Exercício

1. Siga o passo a passo e envie as duas imagens para o ECR.
2. Guarde o print de `aws ecr describe-images` para os dois
   repositórios.
3. Por que o ECS **não pode** simplesmente rodar `docker compose up
   --build` como a EC2 da Aula 03 fazia? O que isso implica sobre
   **quando** a imagem precisa estar pronta, em relação a quando a task
   é criada?
4. Qual a diferença prática entre `image_tag_mutability = "MUTABLE"` e
   `"IMMUTABLE"`? Em qual cenário `IMMUTABLE` evitaria um bug de
   produção?
5. Explique, com suas próprias palavras, a diferença entre um nginx
   resolver um hostname **na inicialização** e resolver **em tempo de
   requisição**. Por que só a segunda forma permite que a mesma imagem
   do frontend funcione tanto na Aula 03 (onde "api" existe de verdade)
   quanto na Aula 04 (onde não existe)?
6. Por que as rotas da API precisam incluir o prefixo `/api` (ex.:
   `/api/usuarios`), em vez de ficarem só em `/usuarios`? O que
   aconteceria se você esquecesse desse prefixo e testasse via ALB?

**Próximo passo:** [03-exercicio-01-cluster-e-alb](../03-exercicio-01-cluster-e-alb/README.md)
