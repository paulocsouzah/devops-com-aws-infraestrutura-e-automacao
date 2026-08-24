# 5. Exercício 04 — Alarme de CPU com Notificação por E-mail (SNS)

Este é o módulo mais esperado da aula: sair de "eu preciso lembrar de
olhar o Dashboard" para "a AWS me avisa sozinha". Vamos criar um
**SNS Topic**, inscrever seu e-mail nele, e um **CloudWatch Alarm** que
dispara esse Topic quando a CPU da `api` fica alta.

> 🧭 **Onde estamos:** dentro de `00-pratica/`. Mas atenção: neste
> módulo você também vai precisar checar seu **e-mail** num navegador,
> fora do terminal — vem no Passo 3.

---

## 🔔 O caminho completo

```
CPU da api > 70%, por 2 minutos seguidos
        │
        ▼
CloudWatch Alarm muda de OK para ALARM
        │
        ▼
Alarme dispara o SNS Topic (alarm_actions)
        │
        ▼
SNS distribui pra quem estiver inscrito (subscription)
        │
        ▼
Você recebe um e-mail
```

---

## 🔑 Passo 1 — Adicionar a variável do seu e-mail

Abra `variables.tf`, dentro de [`00-pratica/`](../00-pratica/README.md),
e adicione ao final:

```hcl
variable "alert_email" {
  description = "E-mail que recebe as notificacoes do SNS quando um alarme dispara"
  type        = string
}
```

Abra (ou crie, copiando de `terraform.tfvars.example`) o seu
`terraform.tfvars` e adicione a linha (com o **seu** e-mail de verdade —
você vai precisar confirmar a inscrição nele daqui a pouco):

```hcl
alert_email = "seu-email-real@exemplo.com"
```

Também adicione essa linha de exemplo no `terraform.tfvars.example`
(sem o e-mail real, só o placeholder — esse arquivo **vai** pro Git):

```hcl
alert_email = "seu-email@exemplo.com"
```

---

## 📂 Passo 2 — Criar o SNS Topic, a assinatura e o Alarme

Crie um arquivo novo, `monitoring-alarms.tf`, dentro de
[`00-pratica/`](../00-pratica/README.md):

```hcl
# Topico do SNS — o "mensageiro" que distribui notificacoes.
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# Inscreve seu e-mail no topico. A AWS manda um e-mail de confirmacao
# assim que este recurso for criado — sem confirmar, nenhuma
# notificacao futura chega (ver Passo 3).
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarme: observa a CPU media da api, dispara se ficar acima de 70%
# por 2 periodos consecutivos de 1 minuto (ou seja, 2 minutos seguidos).
resource "aws_cloudwatch_metric_alarm" "api_cpu_high" {
  alarm_name          = "${var.project_name}-api-cpu-high"
  alarm_description   = "CPU media da api acima de 70% por 2 minutos consecutivos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "CPUUtilization"
  namespace            = "AWS/ECS"
  period               = 60
  statistic            = "Average"
  threshold            = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.api.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
```

Também adicione este output em `outputs.tf` — vai facilitar conferir a
assinatura no Passo 3:

```hcl
output "sns_topic_arn" {
  description = "ARN do topico SNS que recebe os alarmes"
  value       = aws_sns_topic.alerts.arn
}
```

> 💡 **`alarm_actions` x `ok_actions`**: `alarm_actions` dispara quando
> o estado muda **para** `ALARM` (CPU subiu demais). `ok_actions`
> dispara quando volta **para** `OK` (CPU normalizou) — sem isso, você
> recebe o aviso do problema, mas nunca o aviso de que já passou. Os
> dois apontam pro mesmo Topic aqui, mas poderiam ir pra lugares
> diferentes.
>
> 💡 `evaluation_periods = 2` com `period = 60` significa "2 janelas de
> 60 segundos, seguidas, acima do threshold" — não dispara num pico de
> 1 segundo isolado. Isso existe de propósito: alarmes sensíveis demais
> disparam por qualquer soluço passageiro (voltamos a isso no módulo 06,
> "alarme fadiga").

---

## 🛠️ Passo 3 — Aplicar e confirmar a assinatura no e-mail

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
terraform apply
```

**Assim que o `apply` terminar, abra sua caixa de e-mail.** Deve chegar
uma mensagem da AWS com o assunto **"AWS Notification - Subscription
Confirmation"**. Abra ela e clique em **"Confirm subscription"**.

> ⚠️ **Sem esse clique, nenhuma notificação chega — nunca.** A
> assinatura fica "Pending confirmation" pra sempre até você confirmar.
> Confira pelo terminal:
> ```bash
> aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)
> ```
> O campo `SubscriptionArn` deve mostrar um ARN de verdade — se
> mostrar a palavra `PendingConfirmation`, volte no e-mail e confirme.

**Tire um print** do e-mail de confirmação recebido.

---

## 🧪 Passo 4 — Provocar o alarme de propósito

Você vai usar **dois terminais ao mesmo tempo**: um pra visualizar (o
`dashboard.js` da Aula 04), outro pra garantir que a CPU realmente
passa de 70% — o `dashboard.js` sozinho, no ritmo padrão dele, é
suficiente pra demonstrar o Load Balancing e o Auto Scaling (Aula 04),
mas gera CPU de menos pra empurrar o alarme desta aula com confiança.

### Terminal 1 — visualização (opcional, mas recomendado)

```bash
node dashboard.js <alb_dns_name> aula06-cluster aula06-api
```

Deixe rodando — é ele que mostra, ao vivo, as respostas por task e o
`desiredCount`/`runningCount` do Service.

### Terminal 2 — geração de carga garantida

Pegue o `alb_dns_name` (`terraform output alb_dns_name`) e rode:

**Windows (PowerShell):**
```powershell
$alb = "<alb_dns_name>"
for ($onda = 1; $onda -le 10; $onda++) {
  for ($i = 1; $i -le 40; $i++) {
    Start-Job -ScriptBlock {
      param($url) Invoke-WebRequest -Uri $url -UseBasicParsing | Out-Null
    } -ArgumentList "http://$alb/api/stress?duracao_ms=30000" | Out-Null
  }
  Start-Sleep -Seconds 10
}
```

**Mac/Linux (ou Git Bash no Windows):**
```bash
ALB="<alb_dns_name>"
for onda in $(seq 1 10); do
  for i in $(seq 1 40); do
    curl -s "http://$ALB/api/stress?duracao_ms=30000" -o /dev/null &
  done
  sleep 10
done
```

> 💡 Isso dispara **40 requisições simultâneas** pro endpoint
> `/api/stress` (Aula 04, módulo 05) a cada 10 segundos, por
> aproximadamente 100 segundos — volume suficiente pra saturar a CPU de
> uma task pequena (256 unidades = 0,25 vCPU) de forma sustentada, não
> só em picos passageiros.

### Acompanhe o estado do alarme

```bash
aws cloudwatch describe-alarms --alarm-names aula06-api-cpu-high \
  --query "MetricAlarms[0].{Estado:StateValue,Motivo:StateReason}"
```

> ⚠️ **Paciência: o Alarme pode demorar vários minutos pra reagir,
> mesmo com a CPU já visivelmente alta.** As métricas do namespace
> `AWS/ECS` são publicadas com atraso, e a avaliação do Alarme roda
> sobre esse fluxo atrasado — não sobre o dado mais recente que você vê
> ao consultar direto. Na prática, pode levar entre 5 e 15 minutos
> entre a CPU cruzar 70% de verdade e o Alarme perceber isso e
> disparar. **Continue gerando carga** (repita o comando do Terminal 2
> se a primeira rodada terminar antes do alarme disparar) — não é sinal
> de que algo está quebrado.

Quando `Estado` virar `ALARM`, confira sua caixa de e-mail — deve
chegar uma notificação da AWS com os detalhes do alarme. **Tire um
print** dela.

Pare a geração de carga (`Ctrl+C` no `dashboard.js`) e espere alguns
minutos — o alarme deve voltar pra `OK`, e um segundo e-mail deve
chegar avisando disso.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| E-mail de confirmação nunca chega | Confira a caixa de spam/lixo eletrônico; confirme que `alert_email` em `terraform.tfvars` está com o e-mail certo, sem espaço extra |
| Alarme nunca muda pra `ALARM`, mesmo com carga | Confira `StateReason` no `describe-alarms` — às vezes a carga não é suficiente pra passar de 70% com só 1 task; force `desired_count` maior temporariamente, ou aumente a duração/concorrência do `dashboard.js` |
| Recebeu o e-mail de `ALARM`, mas nunca o de volta pra `OK` | Confirme que parou mesmo a geração de carga, e espere — o alarme só muda de estado depois de `evaluation_periods` consecutivos **abaixo** do threshold também |
| `terraform apply` cria o SNS/alarme, mas trava esperando confirmação de algo | Isso não deveria travar o apply — o `aws_sns_topic_subscription` fica em estado "pending" mas o Terraform considera a criação concluída de qualquer forma; se travar, confirme a versão do provider AWS |

---

## ✅ Checklist técnico

- [ ] Variável `alert_email` adicionada e preenchida no `terraform.tfvars`
- [ ] SNS Topic, assinatura e Alarme criados via Terraform
- [ ] Assinatura do e-mail confirmada (clicou no link)
- [ ] Alarme provocado de propósito, mudou para `ALARM`, e-mail recebido
- [ ] Alarme voltou para `OK` depois, segundo e-mail recebido
- [ ] Prints guardados: e-mail de confirmação, e-mail de alarme disparado

---

## 🧪 Exercício

1. Siga o passo a passo completo e guarde os prints pedidos.
2. Por que o `aws_sns_topic_subscription` sozinho não é suficiente pra
   receber notificações — o que mais precisa acontecer, fora do
   Terraform, antes da primeira notificação chegar?
3. Explique a diferença entre `alarm_actions` e `ok_actions`. O que
   aconteceria se você configurasse só o primeiro?
4. Por que `evaluation_periods = 2` (2 minutos seguidos) é mais
   confiável que um alarme que dispara no primeiro instante que a CPU
   ultrapassa 70%?
5. **Desafio:** o `threshold = 70` foi escolhido arbitrariamente neste
   módulo. Pesquisando o histórico de CPU da sua `api` no Dashboard
   (módulo 04) em uso normal, esse valor parece bem calibrado pra sua
   aplicação, ou você ajustaria pra mais alto/mais baixo? Justifique.

**Próximo passo:** [06-organizacao-e-boas-praticas](../06-organizacao-e-boas-praticas/README.md)
