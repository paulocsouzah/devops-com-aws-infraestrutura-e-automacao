# 8. Conteúdo Extra — Prometheus + Grafana monitorando o ECS

Esse módulo é **100% opcional** — não conta na avaliação (o
[07-exercicio-final](../07-exercicio-final/README.md) já fechou isso) e
não é pré-requisito pra nenhuma aula futura. A ideia é mostrar, de forma
resumida, a **outra grande família de ferramentas de observabilidade**
que você vai encontrar no mercado: em vez do CloudWatch (nativo da AWS,
o que fizemos até aqui), o par **Prometheus + Grafana** — open source,
usado em Kubernetes, em ambientes multi-cloud, e em boa parte das vagas
de DevOps/SRE que pedem "observabilidade" no requisito.

O resultado final é um **Grafana único**, igual ao painel de uma
ferramenta comercial (Datadog, New Relic, etc.): métricas de CPU/memória
do ECS e do ALB **e** os logs da aplicação (requisições, erros), tudo
no mesmo lugar, sem trocar de ferramenta.

> 🧭 **Onde estamos:** continuamos dentro da mesma
> [`00-pratica/`](../00-pratica/README.md) desta aula. Nada do que os
> módulos 02-07 já criaram muda — só vamos **adicionar** dois arquivos
> novos (`ec2-monitoring.tf` e `monitoring-user-data.sh.tpl`) no final.

---

## 🖼️ O que vamos construir

```
┌───────────────────────── Sua VPC (mesma da aula) ─────────────────────────┐
│                                                                             │
│  ECS Cluster + Services ──┐                                               │
│  Application Load Balancer┤── métricas ──▶  CloudWatch (AWS/ECS,          │
│  (logs via awslogs,       │                  AWS/ApplicationELB)          │
│   desde a Aula 04)        │                        │                      │
│                            │── logs ──────▶  CloudWatch Logs              │
│                            │                  (/ecs/<projeto>-api/front)  │
│                            │                        │        │            │
│                            │           API CloudWatch        │            │
│                            │                        ▼        ▼            │
│                            │        ┌── EC2 (Docker Compose) ───────────┐  │
│                            │        │  cloudwatch-exporter (9106)       │  │
│                            │        │       │ Prometheus faz scrape     │  │
│                            │        │       ▼                          │  │
│                            │        │  Prometheus (9090) ── métricas ──┐│  │
│                            │        │                                  ▼│  │
│                            │        │  Grafana (3000) ◀── logs direto ──┘│  │
│                            │        │       │ (datasource CloudWatch)    │  │
│                            │        └───────┼────────────────────────────┘  │
└────────────────────────────────────────────┼─────────────────────────────┘
                                               ▼
                                        seu navegador
```

**Importante:** o Prometheus **não coleta métrica direto do ECS nem do
ALB** — ele não teria nem rede pra alcançá-los (o Security Group das
tasks só libera tráfego vindo do ALB, lembra do `00-pratica/README.md`?).
Quem faz essa ponte é o **cloudwatch-exporter**: um programa que já
existe pronto (imagem Docker `prom/cloudwatch-exporter`), que fica
perguntando pra API do CloudWatch as mesmas métricas que você já viu no
Dashboard do módulo 04, e as **reexpõe** num formato que o Prometheus
entende. Ou seja: **mesmos dados que você já viu no CloudWatch, só que
agora visualizados numa ferramenta diferente** — esse é o ponto
pedagógico deste módulo, não duplicar trabalho.

Pros **logs**, o caminho é mais direto: diferente de métricas, o
CloudWatch **não precisa** de exporter no meio — o Grafana já sabe
conversar nativamente com o CloudWatch Logs Insights (mesma consulta que
você já usou no módulo 03), então o Grafana consulta direto, sem
Prometheus/exporter envolvidos nesse caminho.

> 💡 **Por que não instrumentar a aplicação direto (jeito "raiz" do
> Prometheus)?** Em um projeto Node.js real, o normal seria adicionar a
> lib `prom-client` na API e expor um endpoint `/metrics` próprio, com
> métricas de negócio (latência por rota, erros por tipo, etc.), sem
> depender do CloudWatch. Não fizemos isso aqui de propósito: a `app-aula03`
> é compartilhada com outras aulas e módulo nenhum desta aula pede pra
> editar o código dela (mesma regra do `00-pratica/README.md`). O caminho
> via `cloudwatch-exporter` + datasource nativo do CloudWatch chega a um
> resultado parecido sem tocar em uma linha da aplicação.

---

## 🛠️ Passo 1 — Descobrir seu IP público

Vamos restringir o acesso ao Grafana/Prometheus só ao seu IP (mesma
lógica do SSH nas Aulas 02/03) — nada aqui deveria ficar aberto pro
mundo todo.

```bash
curl https://checkip.amazonaws.com
```

Guarde o resultado — vai entrar no `terraform.tfvars` no Passo 4.

---

## 📂 Passo 2 — Criar `ec2-monitoring.tf`

Crie este arquivo novo dentro de [`00-pratica/`](../00-pratica/README.md):

```hcl
# ec2-monitoring.tf

# AMI mais recente do Amazon Linux 2023 (mesma familia das Aulas 02/03)
data "aws_ami" "monitoring" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Papel IAM ja existente na AWS Academy — reaproveitado, nunca criado
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg-monitoring"
  description = "Libera Grafana (3000) e Prometheus (9090), restrito ao meu IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Grafana, restrito ao meu IP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "Prometheus, restrito ao meu IP"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-monitoring"
  }
}

# Instancia EC2 que sobe Prometheus + Grafana + cloudwatch-exporter via
# Docker Compose, tudo automatico pelo user_data — nao precisa de SSH
# nem do vockey.pem pra este modulo, so o navegador no final.
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.monitoring.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  # templatefile (nao so "file") porque o script usa ${project_name} pra
  # saber o nome dos log groups (/ecs/<project_name>-api) sem precisar
  # de nada fixo — funciona com "aula05", "aula06" ou qualquer outro.
  user_data = templatefile("${path.module}/monitoring-user-data.sh.tpl", {
    project_name = var.project_name
  })

  tags = {
    Name = "${var.project_name}-ec2-monitoring"
  }
}
```

Note que **não tem `key_name`** — diferente da EC2 da Aula 02 (módulo
08), esta aqui não precisa de acesso SSH: tudo é configurado sozinho
pelo `user_data` assim que a instância liga, e a única coisa que você
faz depois é abrir o navegador.

---

## 📜 Passo 3 — Criar `monitoring-user-data.sh.tpl`

Este é o script que instala Docker e sobe os três containers
automaticamente, no primeiro boot da instância. Repare que a extensão é
`.sh.tpl`, não `.sh` — é um **template do Terraform**
(`templatefile`, chamado no Passo 2), que substitui `${project_name}`
pelo valor real antes do arquivo virar o `user_data` de verdade. Crie-o
dentro de `00-pratica/`, no mesmo nível do `ec2-monitoring.tf`:

```bash
#!/bin/bash
# Provisiona Docker + Prometheus + Grafana + cloudwatch-exporter numa
# instancia Amazon Linux 2023, sem exigir nenhum passo manual do aluno.
# Grafana ja sobe com dois datasources (Prometheus e CloudWatch) e dois
# dashboards prontos: metricas do ECS/ALB e logs da aplicacao.
#
# Este arquivo e um TEMPLATE do Terraform (templatefile) — ${project_name}
# abaixo e substituido pelo valor real de var.project_name antes do
# arquivo virar o user_data de verdade.
set -e

dnf update -y
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# Docker Compose v2 (plugin) - nao vem pre-instalado no Amazon Linux 2023
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

mkdir -p /opt/monitoring/grafana-provisioning/datasources
mkdir -p /opt/monitoring/grafana-provisioning/dashboards
mkdir -p /opt/monitoring/grafana-dashboards
cd /opt/monitoring

# Quais metricas do CloudWatch o cloudwatch-exporter vai buscar. Nao
# tem nome de cluster/service fixo aqui: ele descobre sozinho tudo que
# existir nesses namespaces (ClusterName/ServiceName viram labels do
# Prometheus automaticamente) — funciona com qualquer project_name.
cat > cloudwatch-config.yml <<'EOF'
region: us-east-1
metrics:
  - aws_namespace: AWS/ECS
    aws_metric_name: CPUUtilization
    aws_dimensions: [ClusterName, ServiceName]
    aws_statistics: [Average]
  - aws_namespace: AWS/ECS
    aws_metric_name: MemoryUtilization
    aws_dimensions: [ClusterName, ServiceName]
    aws_statistics: [Average]
  - aws_namespace: AWS/ApplicationELB
    aws_metric_name: RequestCount
    aws_dimensions: [LoadBalancer]
    aws_statistics: [Sum]
  - aws_namespace: AWS/ApplicationELB
    aws_metric_name: TargetResponseTime
    aws_dimensions: [LoadBalancer]
    aws_statistics: [Average]
  - aws_namespace: AWS/ApplicationELB
    aws_metric_name: HTTPCode_Target_5XX_Count
    aws_dimensions: [LoadBalancer]
    aws_statistics: [Sum]
  - aws_namespace: AWS/ApplicationELB
    aws_metric_name: HTTPCode_Target_2XX_Count
    aws_dimensions: [LoadBalancer]
    aws_statistics: [Sum]
EOF

# honor_timestamps: false e essencial aqui — o cloudwatch-exporter
# republica cada metrica com o timestamp ORIGINAL do CloudWatch (que ja
# vem com alguns minutos de atraso). Sem essa opcao, o Prometheus
# descarta as amostras por serem "velhas demais" e o grafico fica vazio,
# mesmo com tudo funcionando.
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: 'cloudwatch'
    honor_timestamps: false
    static_configs:
      - targets: ['cloudwatch-exporter:9106']
EOF

# Dois datasources no Grafana: Prometheus (metricas, via o exporter) e
# CloudWatch nativo (logs — o proprio Grafana ja sabe consultar Logs
# Insights sem precisar de nenhum exporter no meio). Autenticacao usa a
# role da propria instancia (LabInstanceProfile), sem chave de acesso.
cat > grafana-provisioning/datasources/datasource.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    uid: prometheus
    isDefault: true
    editable: true
  - name: CloudWatch
    type: cloudwatch
    uid: cloudwatch
    editable: true
    jsonData:
      authType: default
      defaultRegion: us-east-1
EOF

cat > grafana-provisioning/dashboards/dashboard.yml <<'EOF'
apiVersion: 1
providers:
  - name: default
    orgId: 1
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
EOF

cat > grafana-dashboards/ecs-overview.json <<'EOF'
{
  "title": "ECS + ALB via CloudWatch",
  "uid": "ecs-cloudwatch-overview",
  "schemaVersion": 39,
  "version": 1,
  "refresh": "30s",
  "time": { "from": "now-1h", "to": "now" },
  "panels": [
    {
      "id": 1,
      "title": "CPU por Service (ECS)",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "unit": "percent" }, "overrides": [] },
      "targets": [
        { "expr": "aws_ecs_cpuutilization_average", "legendFormat": "{{service_name}}", "refId": "A" }
      ]
    },
    {
      "id": 2,
      "title": "Memoria por Service (ECS)",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "unit": "percent" }, "overrides": [] },
      "targets": [
        { "expr": "aws_ecs_memory_utilization_average", "legendFormat": "{{service_name}}", "refId": "A" }
      ]
    },
    {
      "id": 3,
      "title": "Requisicoes no ALB",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        { "expr": "aws_applicationelb_request_count_sum", "legendFormat": "requests", "refId": "A" }
      ]
    },
    {
      "id": 4,
      "title": "Erros 5xx no ALB",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        { "expr": "aws_applicationelb_httpcode_target_5_xx_count_sum", "legendFormat": "5xx", "refId": "A" }
      ]
    }
  ]
}
EOF

# Segundo dashboard: logs da aplicacao, no estilo "Log Explorer" de
# ferramentas como Datadog — tudo consultando o CloudWatch Logs Insights
# direto pelo Grafana, sem exporter no meio (o exporter so existe pra
# METRICAS, porque o CloudWatch nao fala Prometheus nativamente; pra
# LOGS o Grafana ja sabe conversar direto com o CloudWatch).
cat > grafana-dashboards/logs-overview.json <<'EOF'
{
  "title": "Logs da Aplicacao (estilo Datadog)",
  "uid": "logs-overview",
  "schemaVersion": 39,
  "version": 1,
  "refresh": "1m",
  "time": { "from": "now-1h", "to": "now" },
  "panels": [
    {
      "id": 1,
      "title": "Logs recentes - API",
      "type": "logs",
      "gridPos": { "h": 8, "w": 24, "x": 0, "y": 0 },
      "datasource": { "type": "cloudwatch", "uid": "cloudwatch" },
      "options": { "showTime": true, "wrapLogMessage": true, "sortOrder": "Descending" },
      "targets": [
        {
          "refId": "A",
          "queryMode": "Logs",
          "region": "us-east-1",
          "logGroupNames": ["/ecs/${project_name}-api"],
          "expression": "fields @timestamp, @message | sort @timestamp desc | limit 100"
        }
      ]
    },
    {
      "id": 2,
      "title": "Logs recentes - Frontend",
      "type": "logs",
      "gridPos": { "h": 8, "w": 24, "x": 0, "y": 8 },
      "datasource": { "type": "cloudwatch", "uid": "cloudwatch" },
      "options": { "showTime": true, "wrapLogMessage": true, "sortOrder": "Descending" },
      "targets": [
        {
          "refId": "A",
          "queryMode": "Logs",
          "region": "us-east-1",
          "logGroupNames": ["/ecs/${project_name}-frontend"],
          "expression": "fields @timestamp, @message | sort @timestamp desc | limit 100"
        }
      ]
    },
    {
      "id": 3,
      "title": "Erros - API (contem \"erro\" ou \"falh\")",
      "type": "logs",
      "gridPos": { "h": 8, "w": 24, "x": 0, "y": 16 },
      "datasource": { "type": "cloudwatch", "uid": "cloudwatch" },
      "options": { "showTime": true, "wrapLogMessage": true, "sortOrder": "Descending" },
      "targets": [
        {
          "refId": "A",
          "queryMode": "Logs",
          "region": "us-east-1",
          "logGroupNames": ["/ecs/${project_name}-api"],
          "expression": "fields @timestamp, @message | filter @message like /(?i)(erro|falh)/ | sort @timestamp desc | limit 50"
        }
      ]
    }
  ]
}
EOF

cat > docker-compose.yml <<'EOF'
services:
  cloudwatch-exporter:
    image: prom/cloudwatch-exporter:latest
    container_name: cloudwatch-exporter
    ports:
      - "9106:9106"
    volumes:
      - ./cloudwatch-config.yml:/config/config.yml:ro
    command: ["/config/config.yml"]
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    restart: unless-stopped
    depends_on:
      - cloudwatch-exporter

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - ./grafana-provisioning/datasources:/etc/grafana/provisioning/datasources:ro
      - ./grafana-provisioning/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./grafana-dashboards:/var/lib/grafana/dashboards:ro
    restart: unless-stopped
    depends_on:
      - prometheus
EOF

docker compose up -d
```

> 💡 Note que o `cloudwatch-config.yml` **não** tem `aula06-cluster`
> nem `aula06-api` escritos em lugar nenhum — o exporter descobre esses
> nomes sozinho consultando o CloudWatch. Já o `logs-overview.json` usa
> `${project_name}` de propósito, porque **logs não têm o mesmo truque de
> auto-descoberta** que as métricas têm — o CloudWatch Logs Insights
> exige o nome exato do log group na consulta. É por isso que este
> arquivo precisa ser processado pelo `templatefile()` (Passo 2), e não
> um `file()` simples.

---

## 🔑 Passo 4 — Variável `my_ip` e `terraform.tfvars`

Adicione a variável nova no `variables.tf`:

```hcl
variable "my_ip" {
  description = "Seu IP publico, usado para restringir o acesso ao Grafana/Prometheus (defina em terraform.tfvars)"
  type        = string
}
```

E o valor no seu `terraform.tfvars` (o IP que você pegou no Passo 1):

```hcl
my_ip = "SEU_IP_AQUI"
```

Opcional, mas útil pra não perder a URL depois — adicione em `outputs.tf`:

```hcl
output "grafana_url" {
  description = "URL do Grafana"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}
```

---

## 🚀 Passo 5 — Aplicar

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
```

Confira: **2 recursos novos** (`aws_security_group.monitoring` e
`aws_instance.monitoring`) — nada do resto muda.

```bash
terraform apply
```

Guarde a `grafana_url` do final do `apply`.

---

## ⏳ Passo 6 — Esperar o bootstrap

O `user_data` instala Docker, baixa 3 imagens (`cloudwatch-exporter`,
`prometheus`, `grafana`) e sobe tudo sozinho — **leva de 2 a 3 minutos**
depois do `apply` (testado ponta a ponta, com destroy/recreate do zero,
durante a criação deste módulo). Nesse meio tempo, `http://<ip>:3000`
ainda não responde — não é erro, é só o boot ainda rolando. Espere e
recarregue.

---

## 🔐 Passo 7 — Entrar no Grafana

Acesse `http://<grafana_url do output>:3000`.

- **Usuário:** `admin`
- **Senha:** `admin123`

> ⚠️ Essa senha só existe assim, fixa, porque isto é um laboratório de
> estudo de vida curta. Num projeto real, isso viraria um Secret (AWS
> Secrets Manager, por exemplo), nunca uma senha fixa no
> `docker-compose.yml`.

Dois datasources (Prometheus e CloudWatch) e dois dashboards já vêm
prontos — você não precisa configurar nada na mão. No menu esquerdo, vá
em **Dashboards**.

### 📊 Dashboard "ECS + ALB via CloudWatch" (métricas)

1. **CPU por Service (ECS)** — mesma métrica do módulo 02
   (Container Insights), só que via Prometheus.
2. **Memória por Service (ECS)**.
3. **Requisições no ALB** — mesma métrica do módulo 04 (Dashboard).
4. **Erros 5xx no ALB** — fica vazio se não houver nenhum erro real
   ainda (esperado — é a mesma métrica, sem erro não tem o que mostrar).

### 📄 Dashboard "Logs da Aplicação (estilo Datadog)" (logs)

1. **Logs recentes - API** — todo log que a `api` gerou na última hora,
   mais recente primeiro (mesmo dado da query `api-logs-recentes` do
   módulo 03, mostrado agora como uma tela de log ao vivo).
2. **Logs recentes - Frontend**.
3. **Erros - API** — só as linhas que contêm "erro" ou "falh" (cobre
   `console.error` da aplicação, que escreve em português: "Erro ao
   cadastrar usuario", "Tentativa de conexao... falhou", etc.). Fica
   vazio se nada deu errado ainda — gere um erro de propósito (ex:
   pare o RDS ou cadastre um usuário e veja o log de sucesso vs. force
   um erro 500 na API) pra ver essa tela reagir em tempo real.

**Tire prints** dos dois dashboards pra comparar com o Dashboard e o
Logs Insights do CloudWatch (módulos 03 e 04) — mesmos dados,
visualização diferente.

---

## 🔎 Passo 8 (opcional) — Explorar o Prometheus puro

`http://<grafana_url do output, trocando 3000 por 9090>`

- **Status → Targets:** confirma que o `cloudwatch-exporter` está `UP`
  (barra verde à esquerda). **Não clique no link do Endpoint** —
  `http://cloudwatch-exporter:9106/metrics` só existe dentro da rede
  Docker da instância; seu navegador não consegue resolver esse nome de
  fora (dá erro `DNS_PROBE_FINISHED_NXDOMAIN`, é normal). A barra verde
  já é a confirmação de que está tudo certo.
- Na busca principal (**Query**), digite `aws_ecs_cpuutilization_average`
  e clique em **Execute** — você vê o dado cru, sem o Grafana por cima.
  É esse mesmo dado que alimenta o painel 1 do dashboard de métricas.

---

## ✍️ Passo 9 — Criar um painel/dashboard novo, na mão

Tudo que você viu até aqui (os dois dashboards, os datasources) nasceu
sozinho, via `user_data` — nenhum clique seu. Agora vamos fazer o
caminho **inverso**: criar um painel do zero, direto na interface do
Grafana, do jeito que um analista faz no dia a dia pra investigar algo
pontual (sem precisar editar `.tf` nem esperar um `apply`).

Vamos visualizar uma métrica que **já está sendo coletada** (o
`cloudwatch-exporter` já busca ela, veja o `cloudwatch-config.yml` do
Passo 3) mas que **não aparece em nenhum painel pronto**:
`TargetResponseTime` (latência do ALB).

1. No menu esquerdo, clique em **Dashboards** → botão **New** (canto
   superior direito) → **New Dashboard**.
2. Clique em **Add visualization**.
3. Na tela "Select data source", escolha **Prometheus**.
4. No editor do painel, no campo da query (embaixo, aba **Code**),
   digite:
   ```
   aws_applicationelb_target_response_time_average
   ```
5. Ainda na linha da query, no campo **Legend**, digite `Latência do ALB`
   (nome que aparece na legenda do gráfico, em vez do nome técnico da
   métrica).
6. No painel direito (**Panel options**):
   - Em **Title**, digite `Latência do ALB (meu painel)`.
   - Desça até **Standard options → Unit**, busque por **"seconds
     (s)"** e selecione — a métrica vem em segundos, sem isso o eixo Y
     mostra números difíceis de interpretar (ex: `0.0097` em vez de
     `9.7 ms`).
7. Clique em **Apply** (canto superior direito) — o painel fecha e
   volta pro dashboard, já com o gráfico.
8. Clique no ícone de **disquete** (Save dashboard), dê o nome **"Meu
   Dashboard - Latência"** e clique em **Save**.

Você deve ver uma linha bem baixa e estável (a aplicação local
responde em milissegundos) — gere carga real com o `dashboard.js` do
módulo 05 pra ver essa linha reagir.

> ⚠️ **Diferença importante em relação aos outros dois dashboards:**
> este aqui **não existe em nenhum arquivo** — ele foi salvo direto no
> banco interno do Grafana (dentro do container). Se você recriar a
> instância (`terraform apply -replace=aws_instance.monitoring`) ou
> rodar `terraform destroy`, **esse dashboard manual se perde**; os
> outros dois voltam automaticamente, porque nasceram do `user_data`.
> É a mesma diferença entre editar algo na mão pelo Console da AWS
> (proibido nesta aula, lembra da "regra de ouro"?) e criar via
> Terraform: o que é clicado é rápido, mas não sobrevive a uma
> recriação; o que é código, sim.

**Desafio extra:** adicione um segundo painel no mesmo dashboard, tipo
**Stat** (em vez de **Time series**, escolha no topo do editor do
painel), com a query
`aws_ecs_cpuutilization_average{service_name=~".*api"}` — mostra só um
número grande com a CPU atual da `api`, sem o `frontend` junto.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| `http://<ip>:3000` não responde nos primeiros minutos | Normal — espere os 2-3 minutos do bootstrap (Passo 6) e tente de novo |
| Painéis do Grafana ficam sempre vazios, mesmo depois de esperar | Confirme se o seu IP mudou desde o `apply` (Wi-Fi, 4G, VPN) — o Security Group só libera o IP que estava em `terraform.tfvars` no momento do `apply`; se mudou, rode `terraform apply` de novo depois de atualizar `my_ip` |
| Painel "Erros 5xx" ou "Erros - API" sempre vazio | Esperado se a aplicação não gerou nenhum erro real ainda — não é bug |
| Dashboard de logs vazio, mas o de métricas funciona normalmente | Confira o nome dos log groups reais (`aws logs describe-log-groups --query "logGroups[].logGroupName"`) contra o que o dashboard espera (`/ecs/<project_name>-api`); se você mudou `project_name` **depois** do primeiro `apply` desta EC2, o `user_data` só roda uma vez no primeiro boot — recrie a instância (`terraform apply -replace=aws_instance.monitoring`) pra ele rodar de novo com o nome certo |
| Clicar no link do Endpoint na tela de Targets do Prometheus dá `DNS_PROBE_FINISHED_NXDOMAIN` | Normal — veja a explicação no Passo 8, esse link é só informativo, não é pra clicar |
| `Status → Targets` no Prometheus mostra `cloudwatch-exporter` como `DOWN` | Espere mais um pouco (a imagem Java do exporter demora alguns segundos a mais pra subir que as outras duas); se persistir, o mais rápido é `terraform apply -replace=aws_instance.monitoring` — ou investigar por dentro via Session Manager (linha abaixo) |
| Quer investigar por dentro da instância mesmo assim | Dá pra usar o **AWS Systems Manager Session Manager** direto pelo Console (EC2 → selecione a instância → **Connect** → aba **Session Manager**) — funciona sem SSH nem `vockey.pem`, porque o `LabInstanceProfile` já inclui a permissão `AmazonSSMManagedInstanceCore` |

---

## ✅ Checklist técnico

- [ ] `ec2-monitoring.tf` e `monitoring-user-data.sh.tpl` criados dentro de `00-pratica/`
- [ ] Variável `my_ip` adicionada e preenchida em `terraform.tfvars`
- [ ] `terraform apply` concluído com 2 recursos novos
- [ ] Grafana acessível em `http://<ip>:3000`, login `admin`/`admin123`
- [ ] Dashboard "ECS + ALB via CloudWatch" mostrando os 4 painéis com dado real
- [ ] Dashboard "Logs da Aplicação (estilo Datadog)" mostrando logs reais da API e do frontend
- [ ] Painel manual "Latência do ALB" criado do zero e salvo (Passo 9)
- [ ] Print dos três dashboards guardado

---

## 🧹 Encerrando (independente do resto da aula)

Como este módulo é opcional, você pode destruir só ele sem mexer no
resto da infraestrutura que ainda estiver de pé:

```bash
terraform destroy -target=aws_instance.monitoring -target=aws_security_group.monitoring
```

Se for encerrar a sessão de estudo inteira, o `terraform destroy`
completo (sem `-target`) já cobre isso junto com tudo o resto — veja o
aviso no [`00-pratica/README.md`](../00-pratica/README.md).

---

## 🧪 Exercício

1. Siga o passo a passo e guarde o print dos três dashboards do Grafana
   (os dois prontos, mais o "Meu Dashboard - Latência" do Passo 9).
2. Compare lado a lado: o painel "CPU por Service" do Grafana e o
   widget de CPU do Dashboard do CloudWatch (módulo 04). Os números
   batem (mesma faixa de valores, mesmo comportamento ao longo do
   tempo)? Por que deveriam bater, sendo ferramentas diferentes?
3. Compare também: o painel "Logs recentes - API" do Grafana e a query
   salva `api-logs-recentes` do Logs Insights (módulo 03). É a mesma
   linguagem de consulta (CloudWatch Logs Insights) por trás dos dois —
   o que muda é só quem está exibindo o resultado.
4. O `cloudwatch-config.yml` não tem `aula06-cluster` escrito em nenhum
   lugar, mas o `logs-overview.json` tem `${project_name}` explícito.
   Explique, com suas palavras, por que métricas conseguem
   auto-descoberta e logs não (dica: releia o comentário sobre
   `aws_dimensions` vs. o aviso sobre `templatefile()`).
5. **Desafio:** o painel de CPU usa a query `aws_ecs_cpuutilization_average`
   pura, mostrando todas as séries (`frontend` e `api`) juntas. Edite o
   painel no Grafana e filtre só o `service_name` da `api`, usando
   `aws_ecs_cpuutilization_average{service_name=~".*api"}` — essa é a
   linguagem de consulta do Prometheus, chamada **PromQL**.
6. **Desafio:** force um erro de verdade (por exemplo, pare a instância
   RDS pelo Console **não**, isso violaria a regra de ouro — em vez
   disso, tente cadastrar um usuário com um payload inválido direto via
   `curl -X POST` sem o campo `email`) e observe o painel "Erros - API"
   reagir. Quanto tempo leva entre o erro acontecer e aparecer no
   Grafana? Compare com o atraso do Alarme do módulo 05/06.
7. O painel do Passo 9 foi criado clicando na interface, sem passar por
   nenhum arquivo `.tf`. Se você rodar `terraform apply
   -replace=aws_instance.monitoring`, esse painel some, mas os outros
   dois dashboards voltam do jeito que estavam. Explique essa diferença
   com suas palavras — e relacione com a "regra de ouro" do curso
   inteiro (nada manual pelo Console) que você já aplica desde a Aula 02.
8. **Desafio avançado:** pesquise por que, num projeto real (fora da
   AWS Academy), a maioria dos times **não** usa `cloudwatch-exporter`
   pra monitorar aplicações rodando dentro do próprio Kubernetes/ECS —
   e usa instrumentação direta (`prom-client`, `client_golang`, etc.)
   em vez disso. Que limitação do CloudWatch (custo, granularidade,
   atraso) explica essa preferência?
