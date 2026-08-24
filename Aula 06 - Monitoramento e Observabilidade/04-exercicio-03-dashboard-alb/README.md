# 4. Exercício 03 — Métricas do ALB e um Dashboard só, por Terraform

Container Insights (módulo 02) mostra CPU/memória do ECS. Falta a outra
ponta: como o **Application Load Balancer** está se saindo — quantas
requisições ele recebe, quanto tempo elas demoram, e quantas terminam em
erro. Este módulo junta tudo (ECS + ALB) numa única tela: um
**CloudWatch Dashboard**, criado por Terraform.

> 🧭 **Onde estamos:** dentro de `00-pratica/`, como sempre nesta aula.

---

## 📈 As três métricas do ALB que importam

| Métrica | Namespace | O que mede |
|---|---|---|
| `RequestCount` | `AWS/ApplicationELB` | Quantas requisições o ALB recebeu, no período |
| `TargetResponseTime` | `AWS/ApplicationELB` | Quanto tempo (segundos) o backend (frontend/api) levou pra responder |
| `HTTPCode_Target_5XX_Count` | `AWS/ApplicationELB` | Quantas respostas foram erro do **servidor** (5xx) — diferente de 4xx, que é erro do cliente |

Todas usam a dimensão `LoadBalancer` (o `arn_suffix` do seu ALB, algo
como `app/aula06-alb/1234567890abcdef`) pra saber de qual Load Balancer
os números vêm — o mesmo papel que `ClusterName`/`ServiceName` cumprem
pras métricas do ECS (módulo 01).

---

## 📂 Passo 1 — Criar o Dashboard

Crie um arquivo novo, `monitoring-dashboard.tf`, dentro de
[`00-pratica/`](../00-pratica/README.md):

```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB - Requisicoes e Erros 5xx"
          region = var.aws_region
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB - Latencia media (segundos)"
          region = var.aws_region
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS - CPU por Service (%)"
          region = var.aws_region
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.api.name],
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.frontend.name],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS - Memoria por Service (%)"
          region = var.aws_region
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.api.name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.frontend.name],
          ]
        }
      },
    ]
  })
}
```

> 💡 `jsonencode({...})` transforma um mapa/lista do HCL num texto JSON
> — é assim que o Terraform "escreve" a definição do Dashboard, que a
> API do CloudWatch espera receber como uma string JSON. Você está
> escrevendo em HCL, o Terraform converte pra você.
>
> 💡 `x`, `y`, `width`, `height` posicionam cada widget numa grade
> (24 colunas de largura total) — os dois primeiros widgets ficam lado
> a lado (`x=0` e `x=12`, ambos `width=12`, metade cada), os dois de
> baixo entram na linha seguinte (`y=6`).
>
> 💡 Repare que cada `metrics` referencia recursos que **já existem** —
> `aws_lb.main`, `aws_ecs_cluster.main`, `aws_ecs_service.api/frontend`
> (todos da Aula 04). O Dashboard não cria nada nesses recursos, só lê
> o nome/ARN deles pra montar os gráficos certos.

---

## 🛠️ Passo 2 — Aplicar e conferir

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
terraform apply
```

Confira no `plan`: deve aparecer só a **criação** (`+`) do
`aws_cloudwatch_dashboard.main` — nenhum outro recurso muda.

Pelo navegador: Console da AWS → **CloudWatch** → menu lateral →
**Dashboards** → clique no nome `aula06-dashboard`. Você deve ver os 4
gráficos, atualizando com dados reais.

Gere um pouco de tráfego pra ter dados nos gráficos (acesse a aplicação
pelo ALB algumas vezes, ou reutilize o `dashboard.js` da Aula 04 pra
gerar carga real):

```bash
terraform output alb_dns_name
curl http://<alb_dns_name>/
curl http://<alb_dns_name>/api/usuarios
```

**Tire um print** do Dashboard completo, com os 4 gráficos visíveis.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| `terraform apply` falha com erro de JSON inválido | Confira vírgulas e chaves no bloco `dashboard_body` — um erro comum é esquecer a vírgula depois de um widget dentro da lista `widgets = [...]` |
| Gráficos aparecem vazios, sem nenhuma linha | Gere tráfego real (curl/navegador) contra o ALB — sem requisições, não tem métrica pra desenhar |
| `HTTPCode_Target_5XX_Count` nunca aparece, mesmo com tráfego | Isso é **bom sinal** — significa que não houve erro 5xx no período. A métrica só aparece com valor quando existe pelo menos uma ocorrência |

---

## ✅ Checklist técnico

- [ ] `aws_cloudwatch_dashboard.main` criado com os 4 widgets (requisições/5xx, latência, CPU, memória)
- [ ] `terraform apply` concluído sem erro
- [ ] Dashboard visível no Console, com dados reais depois de gerar tráfego
- [ ] Print do Dashboard completo guardado

---

## 🧪 Exercício

1. Siga o passo a passo, gere tráfego real e guarde o print do
   Dashboard com dados.
2. Pare uma das duas tasks da api de propósito
   (`aws ecs stop-task`) e observe o gráfico de CPU/memória do
   Service — o que muda visualmente enquanto o ECS sobe uma task nova
   pra repor?
3. Por que `TargetResponseTime` usa `stat = "Average"`, enquanto
   `RequestCount` e `HTTPCode_Target_5XX_Count` usam `stat = "Sum"`?
   O que aconteceria de estranho se você usasse `"Average"` pra
   contagem de requisições?
4. **Desafio:** adicione um quinto widget ao Dashboard mostrando
   `HTTPCode_Target_4XX_Count` (erros do lado do cliente) ao lado do
   5xx — o que esse número alto (sem 5xx alto junto) normalmente
   indicaria sobre o comportamento dos usuários ou de outro sistema
   chamando sua API?

**Próximo passo:** [05-exercicio-04-alarme-sns](../05-exercicio-04-alarme-sns/README.md)
