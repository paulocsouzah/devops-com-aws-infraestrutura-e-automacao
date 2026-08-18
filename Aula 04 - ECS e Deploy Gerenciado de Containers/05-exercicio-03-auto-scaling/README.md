# 5. Exercício 03 — Load Balancing e Application Auto Scaling na Prática

Até aqui, "o ALB distribui tráfego" e "o Auto Scaling ajusta a
quantidade de tasks" eram conceitos — este módulo é sobre **ver os dois
acontecendo ao vivo**, na tela, com um dashboard que os alunos rodam no
próprio terminal.

---

## 📈 Como funciona o target tracking

O tipo de política que vamos usar é **target tracking** (rastreamento de
alvo): você diz "eu quero que a CPU média fique perto de 40%", e o Auto
Scaling ajusta a quantidade de tasks pra tentar manter esse número —
sobe task quando passa, desce quando sobra capacidade.

```
CPU média do Service > 40%  por um tempo  →  scale-out (+1 task)
CPU média do Service < 40%  por um tempo  →  scale-in  (-1 task, respeitando o minimo)
```

> 💡 **Por que 40%, e não um número redondo como 50%?** Testamos com
> 50% primeiro — funciona, mas deixa pouca margem: o endpoint de
> estresse deste módulo sustenta a CPU numa faixa que, por instantes,
> fica bem perto de 50%, o que tornava o disparo do scale-out
> inconsistente entre uma tentativa e outra. Com 40% de alvo sobra
> margem confortável acima do limite, e o scale-out dispara de forma
> confiável em poucos minutos, sempre.

Cada Service (frontend e api) tem seu **próprio** Auto Scaling Target.
A **api**, além disso, tem **duas** policies — uma de CPU e uma de
**memória** — porque é ela quem tem o endpoint de estresse capaz de
gerar carga controlada dos dois tipos (próxima seção).

---

## 📂 Onde trabalhar

Dentro de [`00-pratica/`](../00-pratica/README.md), crie
`autoscaling.tf` (os Auto Scaling Targets e as Policies de CPU e
memória para os dois Services) e `dashboard.js` (gera carga real
contra a API e desenha, ao vivo, quem está respondendo e como o ECS
está reagindo) — e **edite** `variables.tf`, adicionando a capacidade
mínima/máxima e os alvos de CPU/memória.

```hcl
resource "aws_appautoscaling_target" "api" {
  max_capacity       = var.api_max_capacity
  min_capacity       = var.api_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "${var.project_name}-api-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.target_cpu_percent
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Segunda policy na MESMA api: memoria, alem de CPU. As duas coexistem —
# o Auto Scaling escala pela metrica que "pedir mais tasks" primeiro.
resource "aws_appautoscaling_policy" "api_memory" {
  name               = "${var.project_name}-api-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.target_memory_percent
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
```

(o Target e a Policy de CPU do `frontend` seguem o mesmo padrão — veja
o arquivo completo)

> 💡 **`scale_in_cooldown` x `scale_out_cooldown`:** depois de escalar, o
> Auto Scaling espera esse tempo (em segundos) antes de escalar de novo
> na mesma direção — evita "flapping" (subir e descer tasks o tempo
> todo por causa de um pico curto de CPU).

---

## 🧪 O endpoint de estresse

A API (`app-aula03/api/index.js`) tem dois endpoints pensados só para
esta demonstração:

- **`GET /api/status`** — responde `{ instancia, timestamp }`, onde
  `instancia` é o hostname do container. Cada task Fargate tem hostname
  próprio — chamando esse endpoint várias vezes seguidas, dá pra ver a
  resposta "pular" entre tasks diferentes quando há mais de uma. O
  frontend (React) já chama esse endpoint sozinho e mostra o resultado
  na tela, num quadradinho "Atendido por: ...".
- **`GET /api/stress?duracao_ms=5000&memoria_mb=0`** — gera carga real
  de CPU (e, opcionalmente, memória) por um tempo controlado. Em vez de
  depender de milhares de requisições reais de negócio (o que levou
  ~10 minutos no nosso teste, e não é repetível de forma confiável),
  este endpoint estressa a task rapidamente e de propósito.

> 💡 **Por que o endpoint "fatia" o trabalho em vez de travar direto?**
> Node.js é single-threaded: um laço síncrono longo travaria o event
> loop inteiro, inclusive as respostas ao health check do ALB — o que
> derrubaria a task no meio da demonstração. O endpoint faz o trabalho
> em pedaços de ~40ms, devolvendo o controle ao event loop entre um
> pedaço e outro. Testamos: mesmo com um `/api/stress` de 6 segundos em
> andamento, o mesmo container respondeu a outra requisição em menos de
> 100ms.
>
> ⚠️ `memoria_mb` tem um teto de 100MB por chamada de propósito — a task
> só tem 512MB no total. Se você (ou um colega, no desafio do módulo)
> exagerar nesse valor, a task pode ser derrubada por falta de memória
> (`OOMKilled`) — o que também é uma coisa real de se aprender a
> diagnosticar (volte ao módulo 06 se isso acontecer).

---

## 🛠️ Passo a passo

### 1. Aplicar

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
terraform apply
```

### 2. Ver o Load Balancer distribuindo tráfego (rápido, sem esperar o Auto Scaling)

Antes de gerar carga, vamos **forçar** duas tasks da api pra ver o
Load Balancer em ação imediatamente, sem esperar o Auto Scaling reagir:

```bash
aws ecs update-service --cluster aula04-cluster --service aula04-api --desired-count 2
```

Espere as duas ficarem `RUNNING` e saudáveis no Target Group (repita até
ver `2 2`):

```bash
aws ecs describe-services --cluster aula04-cluster --services aula04-api \
  --query "services[0].{Desejado:desiredCount,Rodando:runningCount}" --output table
```

Agora chame `/api/status` várias vezes seguidas e observe o campo
`instancia` mudando:

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
for i in $(seq 1 10); do curl -s "http://$ALB_DNS/api/status"; echo; done
```

Você também pode abrir `http://$ALB_DNS` no navegador e clicar em
**"🔄 Consultar de novo"** repetidamente — o mesmo efeito, na interface.

### 3. Ver o Auto Scaling reagindo, com o dashboard ao vivo

Volte a api para o mínimo (deixe o Auto Scaling assumir o controle de
novo) e rode o dashboard:

```bash
aws ecs update-service --cluster aula04-cluster --service aula04-api --desired-count 1

node dashboard.js "$ALB_DNS" aula04-cluster aula04-api
```

O dashboard fica gerando carga (via `/api/stress`) e atualiza a tela a
cada 5 segundos, mostrando:

- Quantas respostas vieram de cada instância (a barrinha `█` cresce por
  instância — no começo só uma; depois que o Auto Scaling agir, uma
  segunda barra aparece sozinha).
- O `desiredCount`/`runningCount` reais dos dois Services.
- A última métrica de CPU e memória da api no CloudWatch.

Deixe rodando e **espere** — como vimos em teste real, o Auto Scaling
não é instantâneo:

> 💡 **Tempo real observado em teste:** com o alvo em 40% e CPU
> sustentada bem acima disso, o Auto Scaling levou **cerca de 3
> minutos** pra disparar o scale-out. Por trás do `target tracking`, a
> AWS cria alarmes do
> CloudWatch que precisam de **3 pontos de dado consecutivos**
> (períodos de 1 minuto cada) acima do alvo antes de agir — não dá pra
> apressar isso, é assim que a AWS evita reagir a picos de meio segundo.
> Para ver exatamente qual alarme disparou e quando, em outro terminal:
> ```bash
> aws application-autoscaling describe-scaling-activities \
>   --service-namespace ecs --resource-id service/aula04-cluster/aula04-api \
>   --query "ScalingActivities[:5].{Causa:Cause,Descricao:Description,Status:StatusCode}" --output table
> ```

Quando a segunda barra de instância aparecer no dashboard, você está
vendo **as duas coisas ao mesmo tempo**: o Auto Scaling que criou a
task nova, e o Load Balancer já mandando tráfego pra ela.

### 4. Observar o scale-in

Pressione `Ctrl+C` no `dashboard.js` para parar a carga, e continue
observando o `desiredCount` (pelo comando do passo 2, ou deixando um
segundo `dashboard.js` rodando sem gerar carga — ele também mostra o
ECS mesmo com poucas respostas). O scale-**in** é, de propósito, **bem
mais lento** que o scale-out — a AWS prefere "escalar rápido,
desescalar com calma". Não é incomum levar 15+ minutos para o
`desiredCount` voltar ao mínimo. Se não quiser esperar tanto durante a
aula, o que você já viu (scale-out acontecendo) já prova o mecanismo —
siga para o próximo módulo, o scale-in continua em background.

---

## ✅ Checklist técnico

- [ ] Auto Scaling Target e Policies (CPU **e** memória) criados para a api
- [ ] Load Balancing observado manualmente (2 tasks forçadas, `/api/status` alternando)
- [ ] `dashboard.js` rodado, gerando carga real via `/api/stress`
- [ ] `desiredCount` da API subiu **sozinho**, sem `terraform apply` nem
      comando manual, durante o dashboard rodando
- [ ] Uma segunda instância apareceu na tabela de respostas do dashboard
- [ ] Depois de parar a carga, `desiredCount` volta ao mínimo sozinho
      (mesmo que você não espere isso terminar durante a aula)

---

## 🧪 Exercício

1. Siga o passo a passo. Capture prints: `/api/status` alternando entre
   duas instâncias (passo 2) e o dashboard mostrando duas barras de
   instância diferentes (passo 3).
2. Por que faz sentido a API ter Auto Scaling **separado** do frontend
   nesta arquitetura? Em qual cenário real você esperaria a API escalar
   sem o frontend precisar escalar junto?
3. O que os campos `scale_in_cooldown` e `scale_out_cooldown` evitam? O
   que aconteceria (na prática, e no seu bolso) se não existisse
   cooldown nenhum e a métrica oscilasse muito perto do alvo?
4. Por que o endpoint `/api/stress` faz o trabalho de CPU em pedaços
   pequenos (`setImmediate` a cada ~40ms) em vez de um laço único e
   longo? O que aconteceria com o health check do ALB se ele não
   fizesse isso?
5. **Desafio:** chame `/api/stress?memoria_mb=90` algumas vezes em
   paralelo e observe o que acontece com a métrica de memória no
   dashboard — e, se a task cair, use o que aprendeu no módulo 06
   (`aws ecs describe-tasks`, campo `stoppedReason`) para confirmar que
   foi `OutOfMemoryError`.
6. **Desafio:** pesquise a diferença entre uma política de
   **target tracking** (a que usamos) e uma de **step scaling**. Em que
   cenário step scaling seria mais apropriado?

**Próximo passo:** [06-organizacao-e-boas-praticas](../06-organizacao-e-boas-praticas/README.md)
