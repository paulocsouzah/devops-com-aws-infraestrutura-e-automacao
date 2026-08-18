# 1. Conceitos de ECS e Orquestração de Containers

Na Aula 03, a EC2 se autoprovisionava sozinha, mas continuava sendo **uma
máquina só**: se ela caísse, a aplicação caía junto; se o tráfego
aumentasse, não tinha pra onde crescer sem você entrar e mexer. Nesta
aula, isso muda — quem passa a cuidar de "onde roda, quantas cópias
rodam e o que fazer se uma cair" é o **ECS**.

---

## 🤹 O problema que a orquestração resolve

Imagine que sua aplicação em container precisa ficar sempre no ar, e às
vezes precisa de mais capacidade (Black Friday, pico de acesso). Rodando
"na mão" numa EC2, você precisaria responder, sozinho, a perguntas como:

- Se o container morrer (erro, falta de memória), quem sobe ele de novo?
- Se eu precisar de 3 cópias da API rodando ao mesmo tempo, onde elas
  ficam, e quem distribui o tráfego entre elas?
- Se o tráfego cair de madrugada, alguém desliga cópias extras pra não
  gastar à toa?
- Se eu quiser atualizar a aplicação sem tirar ela do ar nem um segundo?

Um **orquestrador de containers** é o software que responde a essas
perguntas automaticamente, o tempo todo, sem você observando. O **Amazon
ECS (Elastic Container Service)** é o orquestrador gerenciado da AWS —
"gerenciado" porque você não instala nem opera o orquestrador em si, só
descreve o que quer e ele executa.

---

## 🧩 As peças do ECS

### 1. Cluster

> Um **agrupamento lógico** onde os seus containers vivem.

Diferente do que o nome sugere, um Cluster ECS **não é, necessariamente,
um grupo de servidores**. É mais um "namespace" organizacional — o que
efetivamente executa os containers depende do **launch type** escolhido
(próximo tópico).

### 2. Launch type: Fargate x EC2

> Quem é o "dono" da máquina que roda o container por baixo dos panos.

| | **launch type EC2** | **launch type Fargate** (o que usamos) |
|---|---|---|
| Quem fornece o servidor | Você — cria e gerencia instâncias EC2 que entram no Cluster | A AWS — não existe instância pra você ver ou administrar |
| Patch do sistema operacional | Responsabilidade sua | Responsabilidade da AWS |
| Como você paga | Pela instância EC2 (ligada, mesmo ociosa) | Pelo que a task efetivamente usa (CPU/memória), enquanto roda |
| Acesso SSH ao host | Existe (é uma EC2 normal) | **Não existe** — não há servidor pra acessar |

Analogia: launch type **EC2** é alugar um apartamento — você cuida da
manutenção, mas tem controle total do prédio. Launch type **Fargate** é
um hotel — você paga pela diária de uso, e nunca precisa pensar em quem
troca a lâmpada queimada.

### 3. Task Definition

> A **receita**: qual imagem rodar, quanta CPU/memória, quais portas,
> quais variáveis de ambiente, pra onde mandar os logs.

É o equivalente, em ECS, ao que o `docker-compose.yml` fazia na Aula 03
— só que descrito em formato próprio (JSON, gerado pelo Terraform), e
por container/serviço, não todos juntos num arquivo só.

```
Task Definition "api"
├── imagem: <conta>.dkr.ecr.us-east-1.amazonaws.com/app-aula04-api:latest
├── cpu: 256 (0.25 vCPU)  |  memoria: 512 MB
├── porta: 4000
├── execution_role: LabRole
├── task_role: LabRole
└── logs: CloudWatch Logs (driver awslogs)
```

### 4. Task x Service

> **Task** = uma cópia rodando. **Service** = a garantia de que sempre
> existe a quantidade certa de cópias rodando.

Você quase nunca cria uma Task "solta" — normalmente cria um **Service**,
dizendo "quero sempre 1 (ou 2, ou 10) cópias desta Task Definition
rodando". Se uma task morrer, o Service sobe outra sozinho. É o Service
quem se integra com o Load Balancer e com o Auto Scaling.

### 5. Application Load Balancer (ALB) e Target Group

> O ALB recebe todo o tráfego e distribui entre as tasks saudáveis.
> Cada **Target Group** é uma lista de tasks candidatas a receber
> tráfego, com um health check próprio.

Nesta aula, o ALB terá **duas** regras (Listener Rules), uma para cada
Target Group:

| Caminho da requisição | Target Group | Vai para |
|---|---|---|
| `/api/*` | `tg-api` | Service `api` |
| qualquer outro (`/`, `/index.html`, ...) | `tg-frontend` | Service `frontend` |

> 💡 Isso substitui o papel que o Nginx **dentro do container do
> frontend** cumpria na Aula 03 (proxy de `/api` pra API). Aqui, o
> roteamento acontece **antes** de chegar em qualquer container, direto
> no Load Balancer — cada Service só recebe o tráfego que é dele.

### 6. IAM: execution role x task role

Essa distinção confunde muita gente no começo, então vale grifar:

| | **Execution Role** | **Task Role** |
|---|---|---|
| Quem usa | O **agente do ECS**, nos bastidores | O **código da sua aplicação**, rodando dentro do container |
| Para quê | Puxar a imagem do ECR, mandar logs pro CloudWatch | Qualquer chamada que a própria aplicação fizer a outro serviço AWS (ex: ler um bucket S3) |
| Nesta aula | `LabRole` (dado existente da AWS Academy) | `LabRole` também — nossa API não chama nenhum outro serviço AWS ainda |

Como já vimos nas Aulas 02 e 03 com o `LabInstanceProfile`, a AWS Academy
não permite criar IAM Roles novas — então, de novo, **reaproveitamos** o
`LabRole` já existente, via `data source`, para os dois papéis.

### 7. Application Auto Scaling

> Ajusta sozinho a quantidade de tasks de um Service, dentro de um
> mínimo e um máximo, baseado numa métrica — nesta aula, CPU.

```
CPU media do Service > 50%  →  sobe mais uma task (scale-out)
CPU media do Service < 50%  →  desce uma task, respeitando o mínimo (scale-in)
```

Cada Service (frontend e api) tem seu **próprio** Auto Scaling — a API,
que faz mais trabalho pesado (consultas ao banco), pode escalar
independente do frontend, que só serve arquivos estáticos.

---

## 👋 O que sai de cena (e o que fica)

| Existia na Aula 03 | Nesta aula |
|---|---|
| `aws_instance` (EC2) | ❌ removida — não existe mais servidor |
| `user_data.sh.tpl` | ❌ removido — não há mais nada pra "provisionar" numa máquina |
| Nginx do host (reverse proxy) | ❌ substituído pelo Application Load Balancer |
| SSH / `vockey.pem` | ❌ não é mais necessário — Fargate não tem host acessível |
| VPC, Subnet pública/privada | ✅ continuam, com uma subnet pública a mais (o ALB exige 2 AZs) |
| RDS MySQL | ✅ continua exatamente igual — só o Security Group que aponta pra ele muda de origem |
| Imagens Docker da aplicação | ✅ as mesmas do `app-aula03` — só passam a viver no ECR em vez de serem buildadas na hora |

---

## ✅ Boas práticas

1. **Separe Services por responsabilidade** (frontend x api) sempre que
   eles puderem escalar de forma independente — evita desperdiçar
   recursos escalando algo que não precisa.
2. **Nunca dependa de acesso SSH pra debugar** — em Fargate isso nem
   existe. A fonte de verdade passa a ser os logs no CloudWatch e os
   eventos do Service (`aws ecs describe-services`).
3. **Defina health checks realistas** no Target Group — um health check
   errado (porta ou caminho errados) faz o ALB nunca considerar a task
   saudável, mesmo com a aplicação funcionando perfeitamente.
4. **CPU/memória da Task Definition devem ser dimensionadas**, não
   "chutadas" — pedir de menos derruba a task por falta de recursos,
   pedir de mais desperdiça dinheiro (você paga pelo que reserva).

---

## 🧪 Exercício

1. Com suas próprias palavras, explique a diferença entre **Task** e
   **Service** no ECS.
2. Por que o launch type **Fargate** elimina a necessidade de uma chave
   SSH, diferente de tudo que fizemos nas Aulas 02 e 03?
3. Explique a diferença entre **execution role** e **task role** — dê um
   exemplo (pode ser hipotético) de uma permissão que faria sentido estar
   na task role da nossa API, se ela precisasse ler arquivos de um bucket
   S3.
4. Por que faz sentido o frontend e a API serem **Services separados**,
   em vez de um Service só com os dois containers juntos? Que vantagem
   prática isso traz para o Auto Scaling?
5. O roteamento `/api/*` que antes era feito pelo Nginx **dentro** do
   container do frontend (Aula 03) passa a ser feito pelo **Application
   Load Balancer** nesta aula. Isso torna o container do frontend mais
   simples ou mais complexo? Justifique.

**Próximo passo:** [02-imagens-no-ecr](../02-imagens-no-ecr/README.md)
