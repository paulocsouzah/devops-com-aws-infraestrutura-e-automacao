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
mínima/máxima e os alvos de CPU/memória (pode copiar direto):

```hcl
variable "frontend_min_capacity" {
  description = "Capacidade minima (numero de tasks) do Auto Scaling do Service frontend"
  type        = number
  default     = 1
}

variable "frontend_max_capacity" {
  description = "Capacidade maxima (numero de tasks) do Auto Scaling do Service frontend"
  type        = number
  default     = 3
}

variable "api_min_capacity" {
  description = "Capacidade minima (numero de tasks) do Auto Scaling do Service api"
  type        = number
  default     = 1
}

variable "api_max_capacity" {
  description = "Capacidade maxima (numero de tasks) do Auto Scaling do Service api"
  type        = number
  default     = 3
}

variable "target_cpu_percent" {
  description = "Utilizacao media de CPU (%) que o Auto Scaling procura manter em cada Service"
  type        = number
  default     = 40
}

variable "target_memory_percent" {
  description = "Utilizacao media de memoria (%) que o Auto Scaling procura manter no Service api"
  type        = number
  default     = 70
}
```

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

O Target e a Policy de CPU do `frontend` seguem exatamente o mesmo
padrão do `api` acima — só sem a policy de memória, já que o frontend
não tem endpoint de estresse próprio:

```hcl
resource "aws_appautoscaling_target" "frontend" {
  max_capacity       = var.frontend_max_capacity
  min_capacity       = var.frontend_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "${var.project_name}-frontend-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.target_cpu_percent
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
```

### `dashboard.js`

Diferente dos blocos acima (que são Terraform aplicado pela AWS), o
`dashboard.js` roda **local**, no seu terminal — é um script Node.js
usando só módulos nativos (`http`, `child_process`), sem `npm install`.
Ele faz três coisas em paralelo:

1. Dispara requisições contínuas para `GET /api/stress` no ALB (a mesma
   rota descrita na seção anterior), gerando carga real de CPU na api.
2. Conta, pelo campo `instancia` de cada resposta, quantas vieram de
   cada task — e desenha uma barra `█` por instância. Isso é o que
   prova visualmente o **Load Balancer** distribuindo tráfego.
3. A cada 5 segundos, chama `aws ecs describe-services` (via AWS CLI,
   a mesma já configurada no terminal) para mostrar o
   `desiredCount`/`runningCount` dos dois Services, e
   `aws cloudwatch get-metric-statistics` para mostrar a última média
   de CPU/memória da api — isso é o **Auto Scaling** reagindo.

Crie o arquivo com este conteúdo:

```js
#!/usr/bin/env node
// =============================================================================
// Dashboard ao vivo — Aula 04, modulo 05 (Load Balancing + Auto Scaling).
//
// Gera carga real contra a api via GET /api/stress e, a cada 5s, redesenha
// a tela mostrando: quantas respostas vieram de cada task (Load Balancer
// distribuindo), o desiredCount/runningCount dos dois Services (Auto
// Scaling reagindo) e a ultima media de CPU/memoria da api no CloudWatch.
//
// So usa modulos nativos do Node (http, child_process) + a AWS CLI ja
// configurada no terminal — nao precisa de "npm install".
//
// Uso: node dashboard.js <ALB_DNS> <cluster> <api-service>
// Exemplo: node dashboard.js meu-alb-123.sa-east-1.elb.amazonaws.com aula04-cluster aula04-api
// =============================================================================

'use strict';

const http = require('http');
const { execFile } = require('child_process');

const [, , albDns, cluster, apiService] = process.argv;

if (!albDns || !cluster || !apiService) {
  console.error('Uso: node dashboard.js <ALB_DNS> <cluster> <api-service>');
  console.error(
    'Exemplo: node dashboard.js meu-alb-123.sa-east-1.elb.amazonaws.com aula04-cluster aula04-api',
  );
  process.exit(1);
}

// O frontend nao tem endpoint de estresse proprio (so a api tem), mas o
// dashboard mostra os dois Services — o nome do frontend segue o mesmo
// project_name do nome da api recebido (ex.: "aula04-api" -> "aula04-frontend").
const frontendService = apiService.replace(/-api$/, '-frontend');

const CONCORRENCIA = 4; // requisicoes de /api/stress em paralelo, para sustentar CPU alta
const DURACAO_STRESS_MS = 5000;
const INTERVALO_TELA_MS = 5000;

let gerandoCarga = true;
const respostasPorInstancia = new Map();
let erros = 0;
let ultimoEcs = null;
let ultimaMetrica = null;

// Primeiro Ctrl+C: para de gerar carga nova, mas deixa o dashboard vivo
// pra continuar observando o scale-in. Segundo Ctrl+C: sai de fato.
process.on('SIGINT', () => {
  if (gerandoCarga) {
    gerandoCarga = false;
    console.log('\n⏹  Carga interrompida. Observando o ECS... (Ctrl+C de novo para sair)');
  } else {
    console.log('\nSaindo.');
    process.exit(0);
  }
});

function chamarStress() {
  if (!gerandoCarga) return;

  const req = http.get(
    { host: albDns, path: `/api/stress?duracao_ms=${DURACAO_STRESS_MS}`, timeout: DURACAO_STRESS_MS + 10000 },
    (res) => {
      let corpo = '';
      res.on('data', (pedaco) => (corpo += pedaco));
      res.on('end', () => {
        try {
          const { instancia } = JSON.parse(corpo);
          respostasPorInstancia.set(instancia, (respostasPorInstancia.get(instancia) || 0) + 1);
        } catch {
          erros++;
        }
        chamarStress();
      });
    },
  );
  req.on('timeout', () => req.destroy());
  req.on('error', () => {
    erros++;
    setTimeout(chamarStress, 1000);
  });
}

function awsCliJson(args) {
  return new Promise((resolve, reject) => {
    execFile('aws', args, { maxBuffer: 1024 * 1024 }, (erro, stdout) => {
      if (erro) return reject(erro);
      try {
        resolve(JSON.parse(stdout));
      } catch (erroParse) {
        reject(erroParse);
      }
    });
  });
}

async function atualizarEcs() {
  try {
    const dados = await awsCliJson([
      'ecs', 'describe-services',
      '--cluster', cluster,
      '--services', apiService, frontendService,
      '--output', 'json',
    ]);
    ultimoEcs = dados.services.map((s) => ({
      nome: s.serviceName,
      desejado: s.desiredCount,
      rodando: s.runningCount,
    }));
  } catch {
    ultimoEcs = null;
  }
}

function ultimoDatapoint(pontos) {
  if (!pontos || pontos.length === 0) return null;
  return [...pontos].sort((a, b) => new Date(b.Timestamp) - new Date(a.Timestamp))[0].Average;
}

async function metricaCloudWatch(nomeMetrica) {
  const agora = new Date();
  const inicio = new Date(agora.getTime() - 5 * 60 * 1000);
  const dados = await awsCliJson([
    'cloudwatch', 'get-metric-statistics',
    '--namespace', 'AWS/ECS',
    '--metric-name', nomeMetrica,
    '--dimensions', `Name=ClusterName,Value=${cluster}`, `Name=ServiceName,Value=${apiService}`,
    '--start-time', inicio.toISOString(),
    '--end-time', agora.toISOString(),
    '--period', '60',
    '--statistics', 'Average',
    '--output', 'json',
  ]);
  return ultimoDatapoint(dados.Datapoints);
}

async function atualizarMetricas() {
  try {
    const [cpu, memoria] = await Promise.all([
      metricaCloudWatch('CPUUtilization'),
      metricaCloudWatch('MemoryUtilization'),
    ]);
    ultimaMetrica = { cpu, memoria };
  } catch {
    ultimaMetrica = null;
  }
}

function barra(qtd, max) {
  if (qtd <= 0) return '';
  const escala = max > 0 ? Math.round((qtd / max) * 30) : 0;
  return '█'.repeat(Math.max(escala, 1));
}

function desenhar() {
  console.clear();
  console.log('📊 Dashboard — Load Balancing + Auto Scaling (Aula 04)');
  console.log(`ALB: http://${albDns}`);
  console.log(gerandoCarga ? '🔥 Gerando carga real via /api/stress...' : '⏸  Carga parada (Ctrl+C de novo para sair)');
  console.log('');

  console.log('Respostas por instancia (task da api):');
  if (respostasPorInstancia.size === 0) {
    console.log('  (nenhuma resposta ainda...)');
  } else {
    const maxQtd = Math.max(...respostasPorInstancia.values());
    const linhas = [...respostasPorInstancia.entries()].sort((a, b) => b[1] - a[1]);
    for (const [instancia, qtd] of linhas) {
      console.log(`  ${instancia.padEnd(28)} ${barra(qtd, maxQtd).padEnd(32)} ${qtd}`);
    }
  }
  const total = [...respostasPorInstancia.values()].reduce((soma, n) => soma + n, 0);
  console.log(`  Total: ${total} respostas | erros: ${erros}`);
  console.log('');

  console.log('ECS (desiredCount / runningCount):');
  if (ultimoEcs) {
    for (const s of ultimoEcs) {
      console.log(`  ${s.nome.padEnd(20)} desejado=${s.desejado}  rodando=${s.rodando}`);
    }
  } else {
    console.log('  (nao foi possivel consultar — confira as credenciais/regiao da AWS CLI)');
  }
  console.log('');

  console.log(`CloudWatch — media dos ultimos 5 min (${apiService}):`);
  if (ultimaMetrica) {
    const cpuTxt = ultimaMetrica.cpu != null ? `${ultimaMetrica.cpu.toFixed(1)}%` : 'sem dado ainda';
    const memTxt = ultimaMetrica.memoria != null ? `${ultimaMetrica.memoria.toFixed(1)}%` : 'sem dado ainda';
    console.log(`  CPU: ${cpuTxt}   Memoria: ${memTxt}`);
  } else {
    console.log('  (sem dado ainda)');
  }
  console.log('');
  console.log(`Atualiza a cada ${INTERVALO_TELA_MS / 1000}s.`);
}

async function loopAtualizacaoTela() {
  for (;;) {
    await Promise.all([atualizarEcs(), atualizarMetricas()]);
    desenhar();
    await new Promise((resolve) => setTimeout(resolve, INTERVALO_TELA_MS));
  }
}

for (let i = 0; i < CONCORRENCIA; i++) chamarStress();
loopAtualizacaoTela();
```

**Como usar:**

```bash
cd 00-pratica
ALB_DNS=$(terraform output -raw alb_dns_name)
node dashboard.js "$ALB_DNS" aula04-cluster aula04-api
```

- **Args, na ordem:** DNS do ALB (sem `http://`) → nome do cluster ECS
  → nome do Service da api. O nome do Service do frontend é derivado
  automaticamente trocando o sufixo `-api` por `-frontend`.
- Requer só o Node instalado e a **AWS CLI já autenticada** no mesmo
  terminal (`aws configure` ou as variáveis de ambiente da sua sessão)
  — o script chama `aws ecs describe-services` e
  `aws cloudwatch get-metric-statistics` por baixo dos panos.
- Fica rodando até você interromper: **primeiro `Ctrl+C`** para a
  geração de carga mas mantém a tela atualizando (útil pra acompanhar
  o scale-in, que é lento); **segundo `Ctrl+C`** encerra o processo.
- Se a coluna do ECS aparecer como "não foi possível consultar",
  confira se a região da AWS CLI (`aws configure get region`) é a
  mesma onde o Terraform criou os recursos.

> ⚠️ **Conflito Terraform × Auto Scaling em `desired_count`:** a partir
> daqui, o Auto Scaling passa a mudar `desired_count` dos dois Services
> diretamente na AWS, por fora do Terraform. Sem o ajuste abaixo, todo
> `terraform plan` depois de um scale-out vai mostrar um diff querendo
> **reverter** `desired_count` de volta pro valor de
> `var.frontend_desired_count`/`var.api_desired_count` — e um `apply`
> nesse estado derruba as tasks que o Auto Scaling acabou de subir.
> Volte em `ecs-services.tf` (módulo 04) e adicione um bloco
> `lifecycle` nos dois `aws_ecs_service`, dizendo ao Terraform pra
> ignorar mudanças nesse campo:
>
> ```hcl
> resource "aws_ecs_service" "frontend" {
>   # ... resto do resource igual ao modulo 04 ...
>
>   lifecycle {
>     ignore_changes = [desired_count]
>   }
> }
> ```
>
> (o mesmo bloco `lifecycle` entra no `aws_ecs_service.api`.)

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
