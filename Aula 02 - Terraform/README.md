# 🏗️ Aula de Terraform — Infraestrutura como Código na AWS

Material didático completo para a aula de **Terraform**, do conceito de
Infrastructure as Code até a criação de uma infraestrutura real na AWS
(via **AWS Academy**), inteiramente por código — sem nenhum clique manual
no Console.

## 📚 Estrutura

| Pasta | Conteúdo |
|-------|----------|
| [01-conceitos](01-conceitos/README.md) | O que é IaC, estrutura do Terraform (providers, resources, variables, outputs, state), boas práticas |
| [02-instalacao-terraform-e-aws-cli](02-instalacao-terraform-e-aws-cli/README.md) | Instalar Terraform e AWS CLI (Windows/Linux/Mac) |
| [03-aws-academy-e-credenciais](03-aws-academy-e-credenciais/README.md) | Iniciar o Learner Lab, obter credenciais temporárias e conectar o Terraform à AWS Academy |
| [04-primeiros-comandos-terraform](04-primeiros-comandos-terraform/README.md) | `terraform init`, `plan`, `apply`, `destroy`, `fmt`, `validate` e o arquivo de state |
| [05-exercicio-01-rede](05-exercicio-01-rede/README.md) | VPC, Subnet, Internet Gateway e Route Table por código |
| [06-exercicio-02-security-group](06-exercicio-02-security-group/README.md) | Regras de firewall (Security Group) por código |
| [07-exercicio-03-ec2-com-iam](07-exercicio-03-ec2-com-iam/README.md) | Subir uma EC2 usando a rede criada e o papel IAM da AWS Academy |
| [08-exercicio-final](08-exercicio-final/README.md) | Projeto integrador `terraform-aula02` (VPC + Subnet + IGW + Route Table + Security Group + EC2 + IAM) — entrega em PDF |

## ▶️ Como usar

Siga as pastas na ordem numérica — cada uma tem um `README.md` com a
explicação, exercícios práticos e, quando aplicável, os arquivos `.tf`
prontos e comentados para servir de referência ou gabarito.

**Pré-requisitos:**

- Terraform e AWS CLI instalados (veja
  [02-instalacao-terraform-e-aws-cli](02-instalacao-terraform-e-aws-cli/README.md)).
- Acesso ativo ao **AWS Academy Learner Lab** (veja
  [03-aws-academy-e-credenciais](03-aws-academy-e-credenciais/README.md)
  para o passo a passo de login e configuração das credenciais — **isso
  precisa ser refeito no início de cada aula/sessão**, pois as credenciais
  da AWS Academy são temporárias).

⚠️ **Regra de ouro desta aula:** nenhum recurso pode ser criado manualmente
pelo Console da AWS. Tudo o que existir na sua conta AWS Academy ao final
da aula precisa ter sido criado pelo Terraform.

## 🏁 Avaliação

O módulo [08-exercicio-final](08-exercicio-final/README.md) fecha a aula
com um projeto que junta tudo (rede + segurança + servidor em um único
conjunto de arquivos `.tf`, criado com `terraform apply`). Ao final dele,
você deve me enviar um **relatório em PDF** com prints, comandos
executados e respostas às perguntas de reflexão — é esse PDF que eu uso
para avaliar e lançar a nota. Os detalhes de entrega e a rubrica de
avaliação estão no próprio módulo.
