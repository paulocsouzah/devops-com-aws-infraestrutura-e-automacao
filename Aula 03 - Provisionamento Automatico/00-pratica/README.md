# 00. Prática — Projeto Terraform desta Aula

Esta pasta **nasce como uma cópia** do
[`00-pratica`](<../../Aula 02 - Terraform/00-pratica/README.md>) da
Aula 02, já completa (VPC, Subnet, IGW, Route Table, Security Group,
EC2) — é o ponto de partida. Cada módulo de exercício desta aula
(`02`, `04`, `05`) edita ou adiciona arquivos **aqui dentro**, e o
módulo final (`07`) só valida o que já está pronto.

> 💡 Se você está começando a Aula 03 agora, confirme que esta pasta
> já tem os arquivos da Aula 02 (`network.tf`, `security-group.tf`,
> `ec2.tf`...) — se não tiver, copie o conteúdo de lá antes de seguir.

⚠️ **Antes do primeiro `apply`, atualize o `default` da variável
`project_name`** em `variables.tf`, de `"aula02"` para `"aula03"`. Os
comandos de exemplo nos módulos desta aula (ex: `aws rds
describe-db-instances --db-instance-identifier aula03-db`) assumem esse
prefixo — sem essa troca, os recursos continuam nascendo como
`aula02-*` e os comandos de exemplo não encontram nada.

## 📂 O que muda aqui, módulo a módulo

| Módulo | O que adiciona/muda em `00-pratica/` |
|---|---|
| [02-user-data-na-pratica](../02-user-data-na-pratica/README.md) | `ec2.tf` ganha um `user_data` de teste (temporário — substituído no módulo 05) |
| [03-preparando-a-aplicacao](../03-preparando-a-aplicacao/README.md) | Nada aqui — a aplicação (`app-aula03/`) é um repositório **separado**, fora desta pasta |
| [04-exercicio-01-rds](../04-exercicio-01-rds/README.md) | `network-rds.tf`, `rds.tf`, mais as variáveis do banco em `variables.tf` |
| [05-exercicio-02-provisionamento-automatico](../05-exercicio-02-provisionamento-automatico/README.md) | `ec2.tf` passa a usar `templatefile()` de verdade; entram `user_data.sh.tpl` e `nginx-app.conf`; mais `app_repo_url` em `variables.tf` |
| [07-exercicio-final](../07-exercicio-final/README.md) | nada de novo — só valida, aplica de verdade e fecha com o relatório em PDF |

## ⚠️ Antes de começar

- `terraform.tfvars` (copiado de `terraform.tfvars.example`) nunca vai
  para o Git — preencha com `db_password` (módulo 04) e `app_repo_url`
  (módulo 05).
- `vockey.pem` (trazido da Aula 02) precisa continuar nesta pasta.
- Sempre rode `terraform destroy` ao final de cada sessão de estudo.

## 🎯 Ao final desta aula

Esta pasta estará com a EC2 se autoprovisionando via User Data (Docker,
Compose, Git, Nginx) e um RDS MySQL isolado em subnet privada — a
aplicação `app-aula03` já no ar, sem nenhum comando manual pós-`apply`.
É exatamente este estado que vira o ponto de partida da
[Aula 04](<../../Aula 04 - ECS e Deploy Gerenciado de Containers/00-pratica/README.md>).
