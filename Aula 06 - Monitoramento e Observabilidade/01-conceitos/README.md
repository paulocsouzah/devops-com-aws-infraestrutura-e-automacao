# 1. Conceitos de Monitoramento e Observabilidade

Desde a Aula 04, sempre que você queria saber se a aplicação estava
saudável, a resposta era rodar um comando — `aws ecs describe-services`,
`aws elbv2 describe-target-health`. Isso funciona, mas exige que
**alguém lembre de perguntar**. Monitoramento de verdade é o oposto:
o sistema observa sozinho, o tempo todo, e **avisa você** quando algo
sai do esperado — mesmo às 3 da manhã, com todo mundo dormindo.

---

## 🔭 Os 3 pilares (e os 2 que usamos nesta aula)

| Pilar | Pergunta que responde | Nesta aula |
|---|---|---|
| **Métricas** | "Quanto?" — números ao longo do tempo (CPU %, latência, contagem de erros) | ✅ Container Insights (módulo 02), métricas do ALB (módulo 04) |
| **Logs** | "O que exatamente aconteceu?" — eventos detalhados, um por linha | ✅ CloudWatch Logs Insights (módulo 03) |
| **Traces** | "Por onde a requisição passou, e onde ela demorou?" — o caminho de uma requisição específica através de vários serviços | ❌ Fora do escopo desta aula (ferramenta relacionada: AWS X-Ray) |

> 💡 **Monitoramento x Observabilidade — qual a diferença?**
> Monitoramento é *ficar de olho em coisas que você já sabia que
> precisava observar* (ex: "vou alarmar se CPU passar de 70%").
> Observabilidade é *ter dados suficientes pra investigar um problema
> que você **não** previu* (ex: "por que só as requisições em `/api/status`
> ficaram lentas às 14h de terça?"). Os dois se complementam — os
> alarmes desta aula são monitoramento; os logs pesquisáveis (módulo 03)
> são o que te dá observabilidade quando um alarme dispara e você
> precisa descobrir *por quê*.

---

## 🧩 As peças do CloudWatch

### 1. Namespace, Métrica e Dimensão

```
Namespace: AWS/ECS
  └── Métrica: CPUUtilization
        └── Dimensões: ClusterName=aula06-cluster, ServiceName=aula06-api
              └── Valor ao longo do tempo: 12%, 15%, 43%, 71%, ...
```

- **Namespace**: um "agrupamento" de métricas por serviço AWS
  (`AWS/ECS`, `AWS/ApplicationELB`, `AWS/RDS`...).
- **Métrica**: o nome da coisa medida (`CPUUtilization`,
  `RequestCount`, `TargetResponseTime`...).
- **Dimensão**: um filtro que identifica **de qual recurso específico**
  aquele valor veio (qual Cluster, qual Service, qual Load Balancer).
  Sem dimensão, a métrica seria uma média de tudo, misturada — inútil
  pra saber se é a `api` ou o `frontend` que está sob pressão.

### 2. Container Insights

> Um "interruptor" que liga coleta **automática** de métricas de CPU e
> memória por Cluster, Service e até por Task individual — sem
> instrumentar uma linha sequer da aplicação.

Sem Container Insights, o ECS ainda expõe métricas básicas (CPU/memória
médias do Service). Com ele ligado, você ganha granularidade por task
e, no Console, dashboards prontos — o custo é: CloudWatch cobra por
essas métricas extras (voltamos a isso no módulo 06).

### 3. Log Group e Log Stream

```
Log Group: /ecs/aula06-api          ← já existe desde a Aula 04!
  ├── Log Stream: api/api/a1b2c3...  ← uma por TASK (efêmera)
  └── Log Stream: api/api/d4e5f6...
```

Você já configurou isso na Aula 04 (`aws_cloudwatch_log_group` +
`logDriver = "awslogs"` na Task Definition) — cada task escreve seus
logs num Stream próprio, dentro do Group da aplicação. O que esta aula
adiciona não é a coleta (já existe), é **como consultar** esses logs de
forma útil (módulo 03).

### 4. Alarme (CloudWatch Alarm)

> Observa uma métrica ao longo do tempo e muda de estado quando ela
> cruza um limite (*threshold*) — e dispara uma ação quando isso
> acontece.

```
Estado do alarme:
  OK               → métrica dentro do esperado
  ALARM            → métrica cruzou o threshold pelo número de
                      períodos configurado
  INSUFFICIENT_DATA → CloudWatch ainda não tem dados suficientes
                      pra decidir (ex: logo após criar o alarme)
```

### 5. SNS (Simple Notification Service)

> O "mensageiro" — recebe uma notificação de quem quer que seja (um
> Alarme, por exemplo) e **distribui** ela pra quem estiver inscrito
> (*subscriber*): e-mail, SMS, outro sistema via HTTP, etc.

```
CloudWatch Alarm ──(dispara)──▶ SNS Topic ──(distribui)──▶ seu e-mail
                                            ├──▶ (poderia ser) SMS
                                            └──▶ (poderia ser) outro sistema
```

O Alarme nunca manda e-mail diretamente — ele só avisa o Topic do SNS,
e o SNS é quem sabe pra quem distribuir. Essa separação é o que permite,
por exemplo, adicionar um segundo e-mail ou um Slack depois, sem mexer
no Alarme.

---

## ✅ Boas práticas

1. **Métricas sem alarme são só um gráfico bonito** — o valor real vem
   de decidir, de propósito, o que merece te acordar e configurar isso
   como Alarme (módulo 05).
2. **Threshold errado é pior que não ter alarme** — um limite baixo
   demais gera "alarme fadiga" (você aprende a ignorar), um limite alto
   demais nunca dispara a tempo. Voltamos a isso no módulo 06.
3. **Logs estruturados** (mesmo que simples, tipo `nível: mensagem`)
   facilitam demais uma consulta no Logs Insights, comparado a uma
   linha de texto solta.
4. **Retenção de log tem custo** — guardar logs pra sempre não é de
   graça nem necessário; a Aula 04 já configurou `retention_in_days = 3`
   nos log groups, de propósito.

---

## 🧪 Exercício

1. Com suas próprias palavras, explique a diferença entre métricas e
   logs — dê um exemplo de pergunta que só logs conseguem responder, e
   uma que só métricas conseguem responder bem.
2. O que é uma **dimensão** de uma métrica CloudWatch, e por que ela é
   necessária pra saber "a CPU de qual Service, exatamente"?
3. Explique por que o CloudWatch Alarm dispara o **SNS Topic**, e não
   o e-mail diretamente. Que flexibilidade essa camada extra dá?
4. O que significa o estado `INSUFFICIENT_DATA` de um alarme, e em que
   situação você esperaria ver isso logo depois de criar um alarme novo?
5. Por que "monitoramento" e "observabilidade" não são a mesma coisa,
   mesmo estando relacionados? Dê um exemplo prático da diferença.

**Próximo passo:** [02-exercicio-01-container-insights](../02-exercicio-01-container-insights/README.md)
