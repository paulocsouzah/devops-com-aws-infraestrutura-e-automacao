# 3. Exercício 02 — CloudWatch Logs Insights

Desde a Aula 04, cada task da `api` e do `frontend` já manda seus logs
pro CloudWatch (`logDriver = "awslogs"`, lembra?). O que faltava era um
jeito **rápido** de consultar isso — sem abrir Log Stream por Log
Stream, um por um, procurando uma linha específica.

> 🧭 **Onde estamos:** de novo, tudo dentro de `00-pratica/`, sem
> repositório separado.

---

## 🔎 O problema que o Logs Insights resolve

```
Sem Logs Insights:                    Com Logs Insights:
────────────────────                  ───────────────────
Abrir Log Group                       Uma query, contra TODOS os
  └── Escolher um Log Stream          Streams do Group ao mesmo tempo,
      (tem um POR TASK, e task        com filtro, ordenação e
       é efêmera — muda toda hora)    agregação — em segundos.
        └── Ctrl+F na tela
```

O **CloudWatch Logs Insights** é uma linguagem de consulta própria
(parecida com SQL, mas não é SQL) que roda contra um ou mais Log Groups
de uma vez, num intervalo de tempo que você escolhe.

---

## ✍️ Passo 1 — Sua primeira query, pelo Console

1. Acesse o Console da AWS → **CloudWatch** → menu lateral →
   **Logs** → **Logs Insights**.
2. No seletor **"Select log group(s)"**, escolha `/ecs/aula06-api`.
3. No campo grande de query, apague o texto padrão e cole:

   ```
   fields @timestamp, @message
   | sort @timestamp desc
   | limit 20
   ```

4. Confirme o intervalo de tempo no topo (ex: **Last 1 hour**) e clique
   em **Run query**.

Você deve ver as últimas 20 linhas de log da `api`, mais recentes
primeiro — inclusive a linha `Conectado ao banco de dados em ...` que a
aplicação escreve ao iniciar (veja `app-aula03/api/index.js`, se quiser
relembrar).

---

## 🔬 Passo 2 — Queries mais úteis

Teste estas, uma de cada vez (troque a query no mesmo campo e rode de
novo):

**Só as linhas de erro:**
```
fields @timestamp, @message
| filter @message like /erro/
| sort @timestamp desc
```

**Contar quantas vezes cada rota da API foi chamada** (se seus logs de
acesso HTTP estiverem no formato padrão do Express/Node — ajuste o
`parse` se o formato do seu log for diferente):
```
fields @timestamp, @message
| filter @message like /GET|POST/
| stats count(*) by bin(5m)
```

**Buscar por uma task específica** (útil pra isolar o comportamento de
uma instância só, lembrando do Load Balancing da Aula 04):
```
fields @timestamp, @message
| filter @message like /ip-10-0/
| sort @timestamp desc
| limit 50
```

> 💡 `fields` escolhe quais colunas mostrar, `filter` funciona como um
> `WHERE`, `stats ... by bin(5m)` agrupa por janelas de tempo (aqui, de
> 5 em 5 minutos) — é assim que se constrói, por exemplo, "quantos
> erros por minuto nos últimos 30 minutos".

---

## 💾 Passo 3 — Salvar as queries por Terraform (não pelo botão "Save")

O Console tem um botão **"Save"** pra guardar uma query — mas isso cria
o recurso **fora** do Terraform, quebrando a regra de ouro do curso.
Em vez disso, vamos criar as queries salvas como código.

No arquivo `outputs.tf` (ou crie um `monitoring-logs.tf` novo, dentro de
[`00-pratica/`](../00-pratica/README.md)), adicione:

```hcl
resource "aws_cloudwatch_query_definition" "api_errors" {
  name = "${var.project_name}/api-erros-recentes"

  log_group_names = [aws_cloudwatch_log_group.api.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /erro/
    | sort @timestamp desc
    | limit 50
  QUERY
}

resource "aws_cloudwatch_query_definition" "api_recent" {
  name = "${var.project_name}/api-logs-recentes"

  log_group_names = [aws_cloudwatch_log_group.api.name]

  query_string = <<-QUERY
    fields @timestamp, @message
    | sort @timestamp desc
    | limit 100
  QUERY
}
```

> 💡 `<<-QUERY ... QUERY` é um **heredoc** do Terraform — permite
> escrever um texto de várias linhas (a query) sem precisar escapar
> quebra de linha manualmente. O `-` antes de `QUERY` permite indentar o
> bloco pra ficar alinhado com o resto do código.

Aplique:

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform apply
```

Volte no Console → **Logs Insights** → no seletor de queries salvas
(ícone de pasta, ao lado do campo de query) → deve aparecer as duas
queries, dentro de uma pasta com o nome do seu `project_name`.

**Tire um print** da tela de resultado de uma das queries.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| Log Group `/ecs/aula06-api` não aparece na lista | Confirme que o Service `api` está `RUNNING` e que já gerou log (acesse a aplicação pelo ALB pra gerar tráfego) |
| Query retorna vazio, mesmo com a aplicação rodando | Confira o intervalo de tempo selecionado no topo da tela — o padrão às vezes fica curto demais |
| `terraform apply` falha ao criar `aws_cloudwatch_query_definition` | Confirme que `log_group_names` referencia `aws_cloudwatch_log_group.api.name` (já existe desde a Aula 04) — erro de digitação no nome do recurso é a causa mais comum |

---

## ✅ Checklist técnico

- [ ] Query simples (`fields`, `sort`, `limit`) testada pelo Console
- [ ] Query com `filter` testada
- [ ] Duas queries salvas criadas via `aws_cloudwatch_query_definition`, aplicadas com sucesso
- [ ] Print de uma consulta com resultado real

---

## 🧪 Exercício

1. Siga o passo a passo e guarde o print de uma query rodando com
   resultado.
2. Gere um erro de propósito na aplicação (ex: chame
   `/api/usuarios` com o método errado, ou pare a task da api por um
   instante) e ache essa ocorrência usando uma query com `filter`.
3. Por que salvar as queries via `aws_cloudwatch_query_definition` (em
   vez do botão "Save" do Console) é mais consistente com o resto do
   curso? O que aconteceria com uma query salva pelo Console se você
   rodasse `terraform destroy` e `terraform apply` de novo do zero?
4. **Desafio:** escreva (e teste) uma query que conte quantas
   requisições cada Log Stream (ou seja, cada task) recebeu — dica:
   `stats count(*) by @logStream`.

**Próximo passo:** [04-exercicio-03-dashboard-alb](../04-exercicio-03-dashboard-alb/README.md)
