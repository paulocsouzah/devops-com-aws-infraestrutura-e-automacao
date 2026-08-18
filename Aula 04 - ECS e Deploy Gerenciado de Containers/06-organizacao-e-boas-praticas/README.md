# 6. Organização, Operação e Boas Práticas

Com tudo funcionando, vale parar pra entender o que muda no dia a dia
de operar essa infraestrutura, comparado ao modelo da Aula 03 — e o que
fazer quando algo dá errado, porque em ECS os erros aparecem de um jeito
diferente de "SSH e olhar o log".

---

## 🙅 Sem SSH — e agora, como eu debugo?

Na Aula 03, quando algo dava errado, o primeiro instinto era `ssh` na
EC2 e ler `/var/log/cloud-init-output.log`. Isso **não existe mais**.
As fontes de verdade agora são:

| Antes (Aula 03) | Agora (Aula 04) |
|---|---|
| `ssh` na EC2 | Não existe host pra acessar |
| `docker ps`, `docker logs` na EC2 | `aws ecs describe-tasks`, CloudWatch Logs |
| `/var/log/cloud-init-output.log` | Eventos do Service: `aws ecs describe-services` |
| Testar a porta local (`curl localhost`) | Testar o Target Group: `aws elbv2 describe-target-health` |

```bash
# Ver o status de cada task (por que ela parou, se parou)
aws ecs describe-tasks --cluster aula04-cluster --tasks <task-id> \
  --query "tasks[0].{Status:lastStatus,Motivo:stoppedReason}"

# Ver os logs do container
aws logs tail /ecs/aula04-api --follow

# Ver por que o ALB considera uma task "unhealthy"
aws elbv2 describe-target-health --target-group-arn <arn-do-target-group>
```

---

## 🐛 Troubleshooting comum

1. **Task fica em `PENDING` e nunca sai disso** → normalmente é rede: a
   task não conseguiu baixar a imagem (sem `assign_public_ip = true`
   numa subnet sem NAT, ela não alcança o ECR) ou o Security Group está
   bloqueando a saída (`egress`). Confira `network_configuration` no
   Service.
2. **Task inicia e para (`STOPPED`) repetidamente** → o container
   quebrou. Rode `aws ecs describe-tasks` e olhe `stoppedReason` — as
   causas mais comuns são erro na própria aplicação (veja o CloudWatch
   Logs) ou falta de memória (`OutOfMemoryError` / task morta com
   `exit code 137`).
3. **`CannotPullContainerError` / imagem não encontrada** → confira se
   o `image` na Task Definition bate exatamente com o
   `repository_url:tag` que você deu `push` no módulo 02, e se o
   `execution_role_arn` tem permissão de leitura no ECR.
4. **Target sempre `unhealthy` no ALB, mesmo com a task `RUNNING`** →
   confira se o `health_check.path` do Target Group realmente responde
   `200` **naquela porta específica** (não outra), e se o timeout do
   health check não é menor que o tempo que a aplicação leva pra
   responder no boot.
5. **`exec format error` nos logs** → clássico de quem builda a imagem
   num Mac com chip Apple Silicon (ARM) sem especificar a arquitetura.
   O Fargate, por padrão, roda **x86_64**. Se você buildar num Mac M1/M2
   sem cuidado, rode:
   ```bash
   docker build --platform linux/amd64 -t minha-imagem .
   ```
6. **`terraform destroy` falha com `RepositoryNotEmptyException`** → o
   ECR não deixa apagar um repositório que ainda tem imagens dentro, e
   sempre vai ter — o `docker push` do módulo 02 é manual, fora do
   controle do Terraform. Por isso o `ecr.tf` deste projeto usa
   `force_delete = true` nos dois repositórios: sem esse argumento, todo
   `destroy` pararia exatamente nesse ponto, com a rede/RDS/ECS já
   destruídos e só os dois repositórios ECR sobrando pra você apagar na
   mão (`aws ecr delete-repository --repository-name <nome> --force`).

---

## ⏱️ Timing: o que demora, o que é rápido

| Recurso | Tempo típico |
|---|---|
| Cluster ECS | Segundos |
| ALB | ~2-3 minutos pra ficar `active` |
| Task Fargate (de `PENDING` a `RUNNING`) | Dezenas de segundos |
| `terraform destroy` do Internet Gateway | Pode passar de alguns minutos — a rede (ENI) que a task Fargate usou às vezes demora a se desassociar da subnet antes do IGW poder ser removido |

> 💡 Se o `terraform destroy` parecer "travado" destruindo o Internet
> Gateway por vários minutos, **não interrompa o comando** — isso é
> esperado, é só a AWS aguardando a interface de rede da task Fargate
> se soltar completamente da subnet.

---

## 🔄 Rolling deployments (prévia da Aula 05)

Quando você registra uma **nova revisão** de uma Task Definition (nova
imagem, por exemplo) e atualiza o Service pra usá-la, o ECS por padrão
faz um **rolling deployment**: sobe tasks novas, espera elas ficarem
saudáveis no Target Group, só depois desliga as antigas — a aplicação
nunca fica fora do ar durante a atualização. Isso é exatamente o
mecanismo que a pipeline de CI/CD da Aula 05 vai acionar automaticamente
a cada `git push`.

---

## 💰 Custos rodando o tempo todo

Diferente da Aula 03 (só o RDS cobrava por hora enquanto ligado), aqui
existem **dois** recursos com custo por hora mesmo sem tráfego nenhum:
o **ALB** e as **tasks Fargate** (cobradas por vCPU/memória reservada,
enquanto rodando — mesmo ociosas). Reforçando a regra de sempre:
`terraform destroy` ao final de cada exercício.

---

## 📝 Resumo visual

| Prática | Por quê |
|---|---|
| Usar `aws ecs describe-tasks`/`describe-services`, não SSH | Não existe host pra acessar em Fargate |
| Checar `stoppedReason` antes de qualquer outra coisa | É a explicação mais direta de por que uma task morreu |
| Especificar `--platform linux/amd64` ao buildar em Mac ARM | Evita `exec format error` no Fargate |
| Não interromper o `destroy` mesmo se o IGW demorar | Timing normal de desassociação de rede do Fargate |
| `terraform destroy` sempre ao final | ALB e Fargate cobram por hora, mesmo ociosos |

---

## 🧪 Exercício

1. Rode `aws ecs describe-tasks` numa das suas tasks rodando e leia o
   campo `stoppedReason` (deve estar vazio/nulo, já que está `RUNNING`)
   — depois, **pare uma task de propósito** (`aws ecs stop-task`) e
   rode o comando de novo rapidamente, antes do Service subir outra.
   O que aparece em `stoppedReason` agora?
2. Explique, com suas palavras, por que a ausência de SSH em Fargate é
   uma consequência direta do modelo "serverless" de containers, e não
   uma limitação arbitrária.
3. O que é um *rolling deployment*, e por que ele evita downtime durante
   uma atualização de versão da aplicação?
4. **Desafio:** o Service tem parâmetros `deployment_minimum_healthy_percent`
   e `deployment_maximum_percent` (não configuramos explicitamente,
   então valem os padrões). Pesquise o que cada um controla durante um
   rolling deployment, e explique como eles evitariam a aplicação ficar
   com **zero** tasks saudáveis durante uma atualização.

**Próximo passo:** [07-exercicio-final](../07-exercicio-final/README.md)
