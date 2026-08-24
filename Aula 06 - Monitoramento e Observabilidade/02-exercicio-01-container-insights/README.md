# 2. Exercício 01 — Container Insights

Primeiro passo pra enxergar o que roda dentro do Cluster: ligar o
**Container Insights**, que passa a coletar métricas de CPU e memória
por task, automaticamente — sem tocar em uma linha do código da
aplicação.

> 🧭 **Onde estamos:** diferente da Aula 05, esta aula inteira acontece
> dentro da pasta `00-pratica/` **deste** material (não tem repositório
> separado envolvido). Todo comando deste módulo roda de dentro dela.

---

## 🔌 O que o Container Insights liga

Sem ele, o ECS já expõe métricas básicas do Service (`CPUUtilization`,
`MemoryUtilization`, médias). Com ele ligado, você ganha:

- Métricas **por task individual**, não só a média do Service.
- Dashboards prontos no Console da AWS (CloudWatch → Container
  Insights), sem você montar nada.
- Mais granularidade pra investigar "qual das 3 tasks da api está
  consumindo mais CPU agora".

É um `setting` dentro do próprio recurso do Cluster — não precisa criar
nada novo.

---

## 📂 Passo 1 — Editar o Cluster

Abra o arquivo `ecs-cluster.tf`, dentro de
[`00-pratica/`](../00-pratica/README.md) (a pasta que você copiou da
Aula 05). Ele hoje tem só isto:

```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}
```

**Adicione o bloco `setting`**, ficando assim:

```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
```

Salve o arquivo.

---

## 🛠️ Passo 2 — Aplicar

Num terminal, dentro da pasta `00-pratica/`:

```bash
cd 00-pratica
terraform fmt
terraform validate
terraform plan
```

Confira no `plan`: deve aparecer só uma **atualização** (`~`) no
`aws_ecs_cluster.main`, adicionando o `setting` — nada é destruído.

```bash
terraform apply
```

> 💡 Se esta for a primeira vez aplicando nesta aula, confirme antes
> que `project_name` em `variables.tf` já está `"aula06"` (não mais
> `"aula05"`) — veja o aviso no início do
> [`00-pratica/README.md`](../00-pratica/README.md).

---

## 👀 Passo 3 — Ver as métricas aparecendo

Espere 2-3 minutos depois do `apply` (o Container Insights leva um
tempinho pra começar a coletar), depois confira pelo terminal:

```bash
aws cloudwatch list-metrics --namespace ECS/ContainerInsights \
  --dimensions Name=ClusterName,Value=aula06-cluster \
  --query "Metrics[].MetricName" --output text
```

Deve aparecer uma lista com nomes como `CpuUtilized`, `MemoryUtilized`,
`RunningTaskCount`, entre outros.

**Pelo navegador** (pra tirar o print que vai servir de imagem no
material da aula):

1. Acesse o Console da AWS → busque **CloudWatch** → menu lateral
   esquerdo → **Container Insights** → **Performance monitoring**.
2. No topo da página, selecione **ECS Clusters** no primeiro filtro.
3. Clique no cluster `aula06-cluster` na lista.
4. Você deve ver gráficos de CPU e memória, por Service e por Task,
   atualizando nos últimos minutos.

**Tire um print** dessa tela.

---

## 🆘 Troubleshooting comum deste módulo

| Problema | O que fazer |
|---|---|
| `terraform plan` mostra que o Cluster inteiro vai ser recriado (`-/+`), não só atualizado | Confira se você editou o `setting` **dentro** do bloco `resource "aws_ecs_cluster" "main" { ... }` já existente, não criou um segundo `resource` com o mesmo nome |
| Nenhuma métrica aparece em `list-metrics` depois de alguns minutos | Confirme que o Service `api`/`frontend` está mesmo `RUNNING` (`aws ecs describe-services`) — sem tasks rodando, não tem o que medir |
| A tela de Container Insights no Console está vazia | Confira se você selecionou o cluster certo no filtro (às vezes o Console mantém o filtro de uma sessão anterior) |

---

## ✅ Checklist técnico

- [ ] `ecs-cluster.tf` com o bloco `setting { name = "containerInsights", value = "enabled" }`
- [ ] `terraform apply` concluído sem erro
- [ ] `aws cloudwatch list-metrics --namespace ECS/ContainerInsights` retorna métricas
- [ ] Print da tela de Container Insights no Console, com gráficos de CPU/memória

---

## 🧪 Exercício

1. Siga o passo a passo e guarde o print da tela de Container Insights.
2. Rode `aws ecs describe-services` e compare o `runningCount` com o
   número de tasks que aparece nos gráficos de Container Insights — eles
   batem?
3. Por que ligar o Container Insights não exige nenhuma mudança na
   Task Definition nem no código da aplicação (`app-aula03`)? O que
   isso te diz sobre onde essa coleta de métricas realmente acontece?
4. **Desafio:** o Container Insights tem custo por métrica coletada
   (voltamos a isso no módulo 06). Em que cenário você **não**
   ligaria ele num ambiente real, mesmo sabendo da granularidade extra
   que ele traz?

**Próximo passo:** [03-exercicio-02-logs-centralizados](../03-exercicio-02-logs-centralizados/README.md)
