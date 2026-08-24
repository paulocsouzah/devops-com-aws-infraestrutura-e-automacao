# Exercício Final — terraform-aula06

Chegou a hora de fechar a aula validando, de ponta a ponta, o
monitoramento que você construiu desde o módulo 02.

Nos módulos anteriores você praticou cada peça isoladamente: Container
Insights (módulo 02), Logs Insights (módulo 03), Dashboard do ALB
(módulo 04) e o Alarme com notificação por e-mail (módulo 05). Este
módulo é sobre **gerar carga real, de ponta a ponta, e ver tudo reagir
junto** — métricas subindo, logs registrando, alarme disparando,
e-mail chegando.

---

## 🎯 O que você vai validar

```
┌──────────────────────────── voce gera carga real ────────────────────────────┐
│                                                                                  │
│   node dashboard.js ...  (Aula 04, reaproveitado)                              │
│                                                                                  │
└──────────────┬──────────────────────┬──────────────────────┬──────────────────┘
               ▼                      ▼                      ▼
     Container Insights       CloudWatch Dashboard      Auto Scaling (Aula 04)
     CPU/memoria por task     ALB: requisicoes,          reage tambem,
     sobe visivelmente        latencia, 5xx               sobe mais tasks
               │                      │                      │
               └──────────────────────┴──────────────────────┘
                                       ▼
                          CloudWatch Alarm: CPU > 70%
                                       ▼
                              SNS Topic dispara
                                       ▼
                            Voce recebe um e-mail
                                       │
                        (carga para, CPU normaliza)
                                       ▼
                         Alarme volta pra OK, 2o e-mail
```

- **Infraestrutura** — a mesma da Aula 05 (rede, RDS, ECR, ECS Fargate,
  ALB, Auto Scaling, pipeline de CI/CD), sem nenhuma mudança nesses
  arquivos.
- **Monitoramento novo desta aula** — Container Insights ligado
  (módulo 02), duas queries salvas do Logs Insights (módulo 03), um
  Dashboard com 4 widgets (módulo 04), um SNS Topic com seu e-mail
  inscrito e um Alarme de CPU (módulo 05).

---

## 🛠️ Passo a passo

### 1. Preparar o ambiente

Inicie o Lab, atualize `~/.aws/credentials` e confirme que
`terraform.tfvars` tem `db_password` **e** `alert_email` preenchidos.

### 2. Conferir se `00-pratica/` está completa

```
00-pratica/
├── (todos os arquivos da Aula 05, sem alteracao)
├── ecs-cluster.tf              # com o setting containerInsights (modulo 02)
├── monitoring-logs.tf          # ou dentro de outputs.tf (modulo 03)
├── monitoring-dashboard.tf     # (modulo 04)
├── monitoring-alarms.tf        # (modulo 05)
└── terraform.tfvars            # db_password + alert_email (NAO commitar)
```

### 3. Atualizar `project_name` e aplicar

Confirme, em `variables.tf`, que `project_name` está `"aula06"` (não
mais `"aula05"`), depois:

```bash
cd 00-pratica
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### 4. Confirmar a assinatura do SNS

Assim que o `apply` terminar, confirme o e-mail de assinatura (módulo
05, Passo 3) — sem isso, nenhuma notificação chega mais adiante.

### 5. Confirmar que a aplicação e a pipeline continuam funcionando

```bash
terraform output alb_dns_name
```

Acesse `http://<alb_dns_name>/`, cadastre um usuário — confirma que
tudo que veio da Aula 04/05 continua de pé.

### 6. Gerar carga real e observar tudo reagindo junto

Use dois terminais: um com o `dashboard.js` (visualização), outro com
o gerador de carga garantida — o mesmo comando do módulo 05 (Passo 4):

```bash
# Terminal 1 (visualizacao)
node dashboard.js <alb_dns_name> aula06-cluster aula06-api
```

```bash
# Terminal 2 (garante que a CPU passa de 70%) — Mac/Linux/Git Bash
ALB="<alb_dns_name>"
for onda in $(seq 1 10); do
  for i in $(seq 1 40); do
    curl -s "http://$ALB/api/stress?duracao_ms=30000" -o /dev/null &
  done
  sleep 10
done
```

> No Windows/PowerShell, use a versão com `Start-Job` do módulo 05.

Enquanto a carga roda, alterne entre três telas:
- **Container Insights** (módulo 02): CPU/memória subindo por task.
- **Dashboard** (módulo 04): requisições e latência do ALB subindo.
- **Alarme** (`aws cloudwatch describe-alarms --alarm-names
  aula06-api-cpu-high`): estado mudando de `OK` pra `ALARM`.

### 7. Confirmar o e-mail de alarme

> ⚠️ **Isso pode demorar de 5 a 15 minutos**, mesmo com a CPU já
> visivelmente alta — as métricas do namespace `AWS/ECS` são publicadas
> com atraso, e o Alarme avalia sobre esse fluxo atrasado. Continue
> gerando carga (repita o Terminal 2) até o e-mail chegar; não é sinal
> de erro (veja o módulo 06 para mais detalhes).

Deve chegar um e-mail da AWS quando o estado virar `ALARM`. Pare a
carga (`Ctrl+C` / feche o Terminal 2) e espere o segundo e-mail, de
volta pra `OK` (esse costuma chegar mais rápido).

### 8. Consultar os logs do período de carga

No Logs Insights (módulo 03), rode a query salva `api-logs-recentes`
filtrando pelo intervalo de tempo em que a carga rodou — confirme que
dá pra ver o volume de requisições subindo nos logs também.

### 9. Destruir ao final

```bash
terraform destroy
```

⚠️ **Não deixe o ALB nem as tasks Fargate rodando sem necessidade** —
eles cobram por hora, mesmo sem tráfego. O monitoramento desta aula não
muda essa regra (e, ao contrário do ALB/Fargate, a maior parte dele nem
cobra por hora — veja o módulo 06 — mas ainda assim: destrua tudo).

---

## ✅ Checklist técnico

- [ ] `00-pratica/` completa, com `project_name = "aula06"` aplicado com sucesso
- [ ] Container Insights ligado, métricas visíveis por task
- [ ] Duas queries salvas no Logs Insights, testadas
- [ ] Dashboard com os 4 widgets, mostrando dados reais
- [ ] SNS Topic + assinatura confirmada + Alarme criados
- [ ] Alarme disparou de verdade sob carga real, e-mail recebido
- [ ] Alarme voltou pra `OK` depois, segundo e-mail recebido
- [ ] `terraform destroy` executado ao final, ambiente limpo

---

## 📄 Entrega: relatório em PDF

### O que o PDF precisa conter

1. **Capa** — seu nome completo e a data de entrega.
2. **Prints de tela** de, no mínimo:
   - Container Insights mostrando CPU/memória subindo durante a carga;
   - o Dashboard completo, com dados reais;
   - o resultado de uma query do Logs Insights;
   - `describe-alarms` mostrando o estado `ALARM`;
   - o e-mail de notificação de alarme recebido (`ALARM` e, se
     possível, o de volta pra `OK`);
   - `terraform destroy` concluído ao final.
3. **Os comandos que você executou**, na ordem.
4. **Respostas escritas, com suas próprias palavras**, para as
   perguntas de reflexão abaixo.
5. **Dificuldades encontradas** — pelo menos um problema real e como
   resolveu.

### Perguntas de reflexão (responda todas no PDF)

1. Compare o "antes" (Aula 04/05, rodando `describe-*` na mão pra saber
   se algo estava errado) com o "depois" desta aula. O que
   especificamente mudou no seu fluxo de trabalho?
2. Explique, com suas próprias palavras, o caminho completo entre "a
   CPU da api passou de 70%" e "o e-mail chegou na sua caixa de
   entrada" — cite cada peça envolvida (Alarme, SNS Topic, assinatura).
3. Por que Container Insights, Logs Insights e o Dashboard, juntos,
   ainda não substituem o Alarme? O que só o Alarme oferece que os
   outros três, sozinhos, não oferecem?
4. Descreva o que você observou nos logs durante o período de carga —
   deu pra perceber, só pelos logs, o momento em que a carga começou e
   terminou?
5. Se você precisasse escolher **um único** threshold diferente de
   70% pra CPU, baseado no que observou no Dashboard em uso normal,
   qual valor você escolheria, e por quê?
6. O que aconteceria com os alarmes e o Dashboard se você esquecesse
   de confirmar a assinatura do SNS (módulo 05, Passo 3) antes de rodar
   este exercício final?

### Prazo e envio

Envie o PDF por e-mail (ou pelo canal combinado em sala) até a data que
eu informar durante a aula. Nomeie o arquivo como
`terraform-aula06-SEUNOME.pdf`.

---

## 📊 Rubrica de avaliação

| Critério | Pontos |
|---|---|
| Container Insights configurado e mostrando métricas por task | 1,5 |
| Logs Insights: queries salvas via Terraform, testadas com resultado real | 1,5 |
| Dashboard com os 4 widgets, dados reais visíveis | 2,0 |
| SNS + Alarme configurados, assinatura confirmada | 1,5 |
| Alarme disparado com carga real, e-mails de `ALARM` e `OK` recebidos | 2,5 |
| Nenhum recurso criado manualmente pelo Console (100% via Terraform) | 0,5 |
| Relatório completo: prints, comandos e explicações próprias | 0,25 |
| Respostas às perguntas de reflexão demonstrando entendimento real | 0,25 |
| **Total** | **10,0** |

Parabéns — agora sua aplicação não só se implanta sozinha (Aula 05),
como também **avisa você** quando alguma coisa sai do normal, sem
precisar ficar de olho o tempo todo. É exatamente esse tipo de
tranquilidade operacional que separa um sistema "no ar" de um sistema
de verdade em produção. 📊
