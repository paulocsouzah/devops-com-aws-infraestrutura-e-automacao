# 6. Organização, Custos e Boas Práticas

Com Container Insights, Logs Insights, Dashboard e Alarme funcionando,
vale parar pra entender o que cada um custa de verdade, e os erros mais
comuns de quem está começando a configurar observabilidade.

---

## 💰 O que cada peça desta aula custa

Diferente de ALB e Fargate (Aula 04), que cobram por hora rodando, a
maior parte do que vimos aqui cobra **por volume**, não por tempo
ligado:

| Recurso | Como cobra |
|---|---|
| Container Insights | Por métrica personalizada coletada — pode ficar caro em clusters grandes com muitos Services/tasks |
| CloudWatch Logs (armazenamento) | Por GB armazenado e por GB ingerido — por isso a Aula 04 já configurou `retention_in_days = 3` nos log groups, de propósito |
| Logs Insights (consultas) | Por GB de dado **escaneado** em cada query — uma query sem filtro de tempo restrito, num log group grande, escaneia (e cobra) mais |
| CloudWatch Dashboard | As 3 primeiras telas são gratuitas por conta; a partir da 4ª, cobra por dashboard/mês |
| CloudWatch Alarm | Por alarme/mês (moedas pequenas) — praticamente irrelevante no volume desta aula |
| SNS | Primeiras notificações por e-mail do mês são gratuitas; depois, valor irrisório por notificação |

> ⚠️ **A parte que mais pesa, de longe, continua sendo ALB + Fargate**
> (Aula 04) — o que você aprendeu nesta aula é praticamente gratuito em
> comparação, contanto que não deixe Container Insights ligado num
> cluster gigante por meses.

---

## 🎯 Calibrando um threshold de alarme (evitando "alarme fadiga")

```
Threshold baixo demais           Threshold alto demais
─────────────────────            ──────────────────────
Dispara toda hora, por           Só dispara quando já é
qualquer pico normal             tarde demais pra agir
        │                                │
        ▼                                ▼
Você aprende a ignorar           O problema já afetou
os alarmes ("fadiga")            usuários reais antes do aviso
```

Não existe um número mágico universal — o processo correto é:
**observar o comportamento normal primeiro** (o Dashboard do módulo 04
existe exatamente pra isso), depois definir o threshold acima da faixa
normal, com folga suficiente pra não disparar à toa, mas não tão alto
que vire inútil.

---

## 🐛 Troubleshooting comum

1. **Alarme fica `INSUFFICIENT_DATA` por muito tempo** → confira se o
   Service realmente tem tasks `RUNNING` gerando a métrica, e se as
   `dimensions` do alarme (`ClusterName`/`ServiceName`) batem
   exatamente com os nomes reais (`aws ecs list-services`).
2. **E-mail de confirmação do SNS nunca chega** → confira spam, e
   confirme que `terraform.tfvars` tem o e-mail certo, sem espaço
   extra nem aspas duplicadas.
3. **Query no Logs Insights retorna "Query scanned X GB" muito alto,
   pra pouco resultado** → restrinja o intervalo de tempo (não use
   "Last 7 days" pra achar um evento de 5 minutos atrás) e adicione
   `filter` o quanto antes na query, não só no fim.
4. **Dashboard mostra "No data available" num widget específico** →
   confira se o `namespace`/dimensões daquele widget batem com os
   nomes reais dos recursos (erro de digitação em
   `aws_ecs_service.api.name`, por exemplo, gera um widget "válido"
   tecnicamente, mas sem métrica nenhuma pra mostrar).
5. **`terraform destroy` reclama que não consegue apagar o SNS Topic**
   → isso normalmente não acontece com assinaturas por e-mail (ao
   contrário do ECR na Aula 04, que precisa de `force_delete`), mas se
   acontecer, confira se não existe alguma assinatura adicional criada
   manualmente pelo Console, fora do Terraform.
6. **CPU já está claramente acima do threshold (você vê isso no
   Dashboard, ou via `aws cloudwatch get-metric-statistics`), mas o
   alarme continua `OK` por vários minutos** → isso é comportamento
   real, não bug: as métricas do namespace `AWS/ECS` costumam ser
   publicadas com atraso, e a avaliação do Alarme roda sobre esse fluxo
   atrasado — não sobre o dado mais recente disponível via consulta
   direta. Na prática, pode levar entre 5 e 15 minutos entre a CPU
   cruzar o threshold de verdade e o Alarme perceber isso. Continue a
   carga e tenha paciência — não é preciso recriar nada.

---

## 📝 Resumo visual

| Prática | Por quê |
|---|---|
| Observar o comportamento normal antes de definir threshold | Evita alarme fadiga (muito sensível) ou alarme inútil (tarde demais) |
| Restringir o intervalo de tempo nas queries do Logs Insights | Cada consulta cobra por volume de dado escaneado |
| Configurar `ok_actions`, não só `alarm_actions` | Sem isso, você sabe quando o problema começou, mas não quando acabou |
| Manter `retention_in_days` baixo em log groups de estudo | Armazenamento de log tem custo contínuo, mesmo pequeno |
| Criar Dashboard/Alarme/queries salvas via Terraform, nunca pelo botão do Console | Mesma regra de ouro do curso inteiro — reprodutível, versionado |

---

## 🧪 Exercício

1. Rode uma query no Logs Insights com um intervalo de tempo bem
   largo (ex: "Last 7 days") e outra idêntica com um intervalo curto
   (ex: "Last 15 minutes") — compare o "Records scanned" ou "Data
   scanned" que o Console mostra pras duas. A diferença bate com o que
   este módulo explicou sobre custo?
2. Explique, com suas palavras, por que "alarme fadiga" é um problema
   real de confiabilidade, não só uma questão de organização — que
   comportamento humano ele provoca ao longo do tempo?
3. Dos recursos desta aula, qual você desligaria primeiro se
   precisasse cortar custo num projeto real, e qual manteria por
   último? Justifique com base na tabela de custos acima.
4. **Desafio:** pesquise o que é uma **métrica composta** (*metric
   math*) no CloudWatch — como ela poderia, por exemplo, calcular uma
   "taxa de erro" (`5xx / RequestCount`) em vez de só mostrar a
   contagem bruta de erros?

**Próximo passo:** [07-exercicio-final](../07-exercicio-final/README.md)
