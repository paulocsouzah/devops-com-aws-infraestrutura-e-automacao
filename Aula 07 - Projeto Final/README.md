# 🏁 Aula 07 — Projeto Final (Avaliação)

Esta é a última aula do curso, e ela não ensina nada novo — é o
**compilado de tudo** que você praticou desde a Aula 01: Docker,
Terraform, rede, banco de dados, containers no ECS, Load Balancer,
Auto Scaling e o pipeline de CI/CD. A prova é montar essa mesma
infraestrutura **de novo, sozinho (ou em dupla/trio), com valores
diferentes dos que já apareceram no material** — a prova de que você
sabe *fazer*, não só *seguir* um passo a passo.

> ⚠️ **Isto substitui os módulos numerados das aulas anteriores.** Não
> tem `00-pratica/` pronta pra copiar, nem código completo mostrado
> aqui. Você vai escrever o Terraform e editar o pipeline com as suas
> próprias mãos, usando o que já construiu nas Aulas 02-06 como
> **referência** — não como fonte pra copiar e colar.

---

## 📋 Formato

| | |
|---|---|
| **Quem** | Dupla ou trio (o professor define o tamanho dos grupos conforme a quantidade de alunos em sala) |
| **Quando** | Durante a aula, com duração de **3 a 4 horas** |
| **Onde** | Sua própria conta do AWS Academy Learner Lab (de um dos integrantes do grupo) |
| **Entrega** | Ao vivo, ainda em aula — veja [Como entregar](#-como-entregar) |
| **Vale** | Nota final da disciplina de DevOps |

---

## ✅ Consulta é permitida, cópia idêntica não

Você **pode e deve** consultar o material das Aulas 02 a 06 — é
exatamente pra isso que ele existe. Reaproveitar a **estrutura** de um
recurso (o tipo de `resource`, os argumentos que ele precisa) é
esperado, é assim que qualquer profissional trabalha no dia a dia.

O que **não pode**: usar os **mesmos valores** literais que já
apareceram no material (mesmo CIDR de VPC, mesmo `project_name`, etc. —
veja a tabela abaixo) ou reaproveitar um `00-pratica/` de uma aula
anterior sem adaptar nada. Se o `diff` entre o seu projeto e o de uma
aula anterior for zero fora dos nomes de arquivo, o valor "reprodutível
mas sem entendimento" não vale nota.

---

## 🧱 O que vocês vão construir

Uma infraestrutura completa, do zero, cobrindo tudo isto:

| Peça | Onde você aprendeu | Obrigatório? |
|---|---|---|
| VPC, subnets (pública x2, privada), Internet Gateway, Route Table | Aula 02/03 | ✅ |
| RDS MySQL, numa subnet privada | Aula 03 | ✅ |
| Dois repositórios ECR (frontend, api) | Aula 04 | ✅ |
| Cluster ECS Fargate + 2 Services (frontend, api) + Task Definitions | Aula 04 | ✅ |
| Application Load Balancer + Target Groups + Listener + Listener Rule | Aula 04 | ✅ |
| Auto Scaling (target tracking de CPU) nos dois Services | Aula 04 | ✅ |
| Pipeline de CI/CD (GitHub Actions) publicando nos **novos** ECR/cluster | Aula 05 | ✅ |
| Container Insights, 1 Dashboard, 1 Alarme com SNS | Aula 06 | 🎁 bônus |

A aplicação (`app-aula03` — React + Node + MySQL) é a **mesma** que
você já usa desde a Aula 03. Você não precisa (nem deve) editar o
código dela — só a infraestrutura que a hospeda e o pipeline que a
publica.

---

## 🔀 Valores que precisam ser diferentes

Use estes valores no lugar dos que já apareceram nas Aulas 02-06 — o
objetivo é forçar você a entender o que está mudando, não decorar um
número:

| Item | Valor usado nas Aulas 02-06 | Use isto na Aula 07 |
|---|---|---|
| `project_name` | `aula02`...`aula06` | Um nome do seu grupo (ex: `final-joao-maria`, minúsculo, sem espaço/acento) |
| VPC CIDR | `10.0.0.0/16` | `10.90.0.0/16` |
| Subnet pública (AZ principal) | `10.0.1.0/24` | `10.90.1.0/24` |
| Subnet privada (RDS) | `10.0.2.0/24` | `10.90.2.0/24` |
| Subnet pública 2 (2ª AZ do ALB) | `10.0.3.0/24` | `10.90.3.0/24` |
| Availability Zones | `us-east-1a` / `us-east-1b` | `us-east-1c` / `us-east-1d` |
| Nome do banco (`db_name`) | `app_aula04` | `prova_final` |

> 💡 Antes de usar `us-east-1c`/`us-east-1d`, confirme que existem na
> sua conta: `aws ec2 describe-availability-zones --region us-east-1
> --query "AvailabilityZones[].ZoneName"`. Se alguma não aparecer,
> escolha outra AZ da lista — o importante é **não** ser `1a`/`1b`.

---

## 🔧 O pipeline de CI/CD precisa ser editado (essa é a parte nova)

Lembra da lacuna que apareceu na Aula 06 — o `deploy.yml` do
`app-aula03` tem os nomes do ECR e do cluster **fixos no código**
(`aula05-frontend`, `aula05-api`, `aula05-cluster`), então trocar
`project_name` sozinho não é suficiente pra pipeline publicar no lugar
certo? Na Aula 06 isso ficou como "fora do escopo, publique a imagem na
mão". **Agora não fica.** Parte da prova é você **editar o
`deploy.yml`** pra apontar pros nomes novos do seu `project_name`, e a
pipeline publicar sozinha, do jeito que ela deveria funcionar desde a
Aula 05.

---

## 🛠️ Roteiro (resumido de propósito)

1. **Prepare o ambiente**: Lab iniciado, `~/.aws/credentials`
   atualizado, confirme a região (`us-east-1`).
2. **Crie um projeto Terraform novo** (pasta separada, ex:
   `terraform-final/`) — não copie uma pasta `00-pratica/` inteira.
3. **Rede**: VPC, 2 subnets públicas (AZs diferentes, uma pro Auto
   Scaling do ECS, outra pro ALB), 1 subnet privada (RDS), Internet
   Gateway, Route Table — com os CIDRs/AZs da tabela acima.
4. **Banco de dados**: RDS MySQL na subnet privada, Security Group
   liberando só a porta do MySQL a partir do Security Group das tasks.
5. **Containers**: 2 repositórios ECR, Cluster ECS Fargate, 2 Task
   Definitions (frontend/api) usando o `LabRole` (mesma regra da AWS
   Academy desde a Aula 02 — nunca criar Role novo), 2 Services.
6. **Load Balancer**: ALB público, 2 Target Groups, Listener na porta
   80, Listener Rule roteando `/api/*` pra `api`.
7. **Auto Scaling**: target tracking de CPU nos dois Services (mesmos
   conceitos da Aula 04 — escolha os thresholds que fizerem sentido).
8. **Aplique** (`terraform init/fmt/validate/plan/apply`), confirme que
   tudo sobe sem erro.
9. **Edite o `deploy.yml`** do `app-aula03` pros nomes novos, faça um
   commit/push, confirme que o GitHub Actions publica sozinho nos ECR
   novos e força o deploy nos Services.
10. **Confirme os Services `RUNNING`** e a aplicação respondendo no DNS
    do ALB — cadastre um usuário de teste.
11. **(Bônus)** Ligue Container Insights, crie 1 Dashboard e 1 Alarme
    de CPU com SNS — mesma estrutura da Aula 06, valores adaptados.
12. **Deixe tudo de pé** até o professor validar (não destrua ainda!).

---

## 🧪 Testando antes de entregar

Rode isto e confira que os dois batem (`Rodando == Desejado`):

```bash
aws ecs describe-services --cluster <seu-cluster> --services <seu-frontend> <seu-api> \
  --query "services[].{Nome:serviceName,Rodando:runningCount,Desejado:desiredCount}" --output table
```

Acesse `http://<alb_dns_name>/` no navegador e cadastre um usuário de
verdade — confirma que frontend, api e RDS estão realmente conectados.

Gere carga real pra confirmar que o Auto Scaling reage. **Use menos
concorrência do que o comando "oficial" das Aulas 04/06** (aquele usa
40 requisições simultâneas por onda, pensado pra estourar o Alarme de
70% da Aula 06 — aqui o alvo é só 40% de CPU, bem mais fácil de
alcançar):

```bash
ALB="<seu_alb_dns_name>"
for onda in $(seq 1 10); do
  for i in $(seq 1 10); do
    curl -s "http://$ALB/api/stress?duracao_ms=30000" -o /dev/null &
  done
  sleep 10
done
```

> No Windows/PowerShell, use a versão com `Start-Job` (Aula 06, módulo
> 05), trocando o `40` por `10`. Se tiver o `dashboard.js` (Aula 04) à
> mão, rode ele num segundo terminal pra visualizar o `runningCount`
> subindo ao vivo: `node dashboard.js <alb_dns_name> <seu-cluster>
> <seu-api>`.

> ⚠️ **Por que não usar as 40 requisições simultâneas aqui:** testamos
> isso de propósito montando este material. Com só 1 task (256 unidades
> de CPU = 0,25 vCPU) recebendo 40 requisições de `/api/stress` ao
> mesmo tempo, o event loop do Node fica tão ocupado que **a própria
> checagem de saúde do ALB** (`GET /` a cada 15s, timeout de 5s) não
> consegue resposta a tempo — o ALB marca a task como não saudável, o
> ECS mata e recria ela, e por 2-4 minutos o `runningCount` oscila
> (chega a cair pra `0`) antes do Auto Scaling se estabilizar. Não é um
> bug nem sinal de erro — é literalmente o Auto Scaling reagindo, só
> que de um jeito mais dramático e mais lento do que precisa ser numa
> demonstração ao vivo com tempo limitado. Com 10 requisições por onda,
> a CPU sobe o suficiente pra passar de 40% sem sufocar o health check.

---

## 📬 Como entregar

Quando tudo estiver de pé e testado, envie pro professor, **ainda
durante a aula**:

1. O **link do ALB** (`http://<alb_dns_name>/`) — vou acessar e testar
   a aplicação de verdade (cadastrar usuário, navegar).
2. Aviso de que o grupo está **pronto pra rodar o script de carga** —
   vou pedir pra vocês rodarem na hora, com a tela visível pra mim,
   pra eu confirmar o Auto Scaling reagindo (mais tasks subindo).
3. O link do repositório `app-aula03` (com o `deploy.yml` editado) e a
   confirmação de que o último workflow do GitHub Actions rodou com
   sucesso.

**Não rode `terraform destroy` até o professor confirmar que já
validou o seu grupo** — depois disso, sim, destrua tudo.

---

## 📊 Rubrica de avaliação

| Critério | Pontos |
|---|---|
| Rede (VPC/subnets/IGW/Route Table) com os valores corretos da Aula 07 | 1,0 |
| RDS funcionando, numa subnet privada, acessível só pela api | 1,0 |
| ECR + ECS (cluster, task definitions, services) com nomes/valores próprios | 2,0 |
| ALB + Target Groups + roteamento `/api/*` funcionando | 1,5 |
| Auto Scaling configurado **e demonstrado reagindo** sob carga real | 1,5 |
| Pipeline de CI/CD editado e publicando sozinho nos recursos novos | 1,5 |
| Aplicação acessível e funcional (cadastro de usuário funciona de ponta a ponta) | 1,0 |
| Nenhum recurso criado manualmente pelo Console (100% via Terraform) | 0,5 |
| **Total** | **10,0** |
| 🎁 Bônus: Container Insights + Dashboard + Alarme (Aula 06) funcionando | +1,0 |

---

## 🧹 Ao final

Só depois da validação do professor:

```bash
terraform destroy
```

Confirme que não sobrou nada rodando (`aws ecs list-clusters`, Console
→ EC2/RDS) antes de fechar o Lab — ALB, Fargate e RDS cobram por hora,
mesmo parados sem tráfego.

Parabéns por chegar até aqui — de um container rodando local (Aula 01)
até uma infraestrutura completa, gerenciada por código, publicando
sozinha e se auto-escalando sob carga. Isso é DevOps de verdade. 🚀
