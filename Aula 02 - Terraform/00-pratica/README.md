# 00. Prática — Projeto Terraform desta Aula

Esta pasta é o **projeto real** que você vai construir ao longo da Aula
02 — não um exemplo à parte. Cada módulo de exercício (`06`, `07`, `08`)
edita ou adiciona arquivos **aqui dentro**, e o módulo final (`09`) só
valida o que já está pronto.

Diferente das aulas anteriores (se você já olhou a Aula 03 ou 04), esta
é a **primeira** aula com Terraform — não existe nada de uma aula
anterior para trazer pra cá. Esta pasta nasce **sem nenhum arquivo
`.tf`** — só este README e dois arquivos de apoio (`.gitignore` e
`terraform.tfvars.example`, que o módulo 07 já vai usar) — e vai
ganhando o código de verdade, arquivo por arquivo, conforme você avança.

## 📂 O que vai morar aqui, módulo a módulo

| Módulo | O que adiciona/muda em `00-pratica/` |
|---|---|
| [06-exercicio-01-rede](../06-exercicio-01-rede/README.md) | `main.tf`, `variables.tf`, `network.tf`, `outputs.tf` |
| [07-exercicio-02-security-group](../07-exercicio-02-security-group/README.md) | `security-group.tf`, mais a variável `my_ip` em `variables.tf` |
| [08-exercicio-03-ec2-com-iam](../08-exercicio-03-ec2-com-iam/README.md) | `ec2.tf`, mais outputs de rede/instância |
| [09-exercicio-final](../09-exercicio-final/README.md) | nada de novo — só valida, aplica de verdade e fecha com o relatório em PDF |

## ⚠️ Antes de começar

- Copie `terraform.tfvars.example` para `terraform.tfvars` **só quando
  o módulo 07 pedir** (é quando a variável `my_ip` passa a existir) —
  ele nunca vai para o Git.
- `vockey.pem` (baixado no módulo 08) também deve ficar nesta pasta,
  também nunca vai para o Git.
- Sempre rode `terraform destroy` ao final de cada sessão de estudo, pra
  não consumir à toa o orçamento compartilhado da AWS Academy.

## 🎯 Ao final desta aula

Esta pasta estará com a infraestrutura completa: VPC + Subnet + Internet
Gateway + Route Table (rede), Security Group (SSH restrito + HTTP/HTTPS
públicos) e uma instância EC2 com o papel IAM e o key pair da AWS
Academy. É exatamente este estado que vira o **ponto de partida** da
[Aula 03](<../../Aula 03 - Provisionamento Automatico/00-pratica/README.md>).
