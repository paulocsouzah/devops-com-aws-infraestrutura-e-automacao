# 🏗️ Aula de Terraform — Infraestrutura como Código na AWS

Material didático completo para a aula de **Terraform**, do conceito de
Infrastructure as Code até a criação de uma infraestrutura real na AWS
(via **AWS Academy**), inteiramente por código — sem nenhum clique manual
no Console.

## 📚 Estrutura

| Pasta | Conteúdo |
|-------|----------|
| [00-pratica](00-pratica/README.md) | O projeto Terraform real desta aula — todos os módulos de exercício trabalham dentro dela |
| [01-conceitos](01-conceitos/README.md) | O que é IaC, estrutura do Terraform (providers, resources, variables, outputs, state), boas práticas |
| [02-instalacao-terraform-e-aws-cli](02-instalacao-terraform-e-aws-cli/README.md) | Instalar Terraform e AWS CLI (Windows/Linux/Mac) |
| [03-aws-academy-e-credenciais](03-aws-academy-e-credenciais/README.md) | Iniciar o Learner Lab, obter credenciais temporárias e conectar o Terraform à AWS Academy |
| [04-aws-cli-na-pratica](04-aws-cli-na-pratica/README.md) | AWS CLI na prática: bucket S3, upload/download de arquivos e outros comandos úteis do dia a dia |
| [05-primeiros-comandos-terraform](05-primeiros-comandos-terraform/README.md) | `terraform init`, `plan`, `apply`, `destroy`, `fmt`, `validate` e o arquivo de state (exercício isolado, não afeta `00-pratica`) |
| [06-exercicio-01-rede](06-exercicio-01-rede/README.md) | VPC, Subnet, Internet Gateway e Route Table por código |
| [07-exercicio-02-security-group](07-exercicio-02-security-group/README.md) | Regras de firewall (Security Group) por código |
| [08-exercicio-03-ec2-com-iam](08-exercicio-03-ec2-com-iam/README.md) | Subir uma EC2 usando a rede criada e o papel IAM da AWS Academy |
| [09-exercicio-final](09-exercicio-final/README.md) | Validação de ponta a ponta de `00-pratica` (VPC + Subnet + IGW + Route Table + Security Group + EC2 + IAM) — entrega em PDF |

## ▶️ Como usar

Siga as pastas na ordem numérica — cada módulo de exercício (06, 07, 08)
edita os arquivos dentro de [`00-pratica/`](00-pratica/README.md), que é
o **projeto real** desta aula. Não existe "recriar do zero" no exercício
final — ele só valida o que já foi construído ao longo da aula.

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

O módulo [09-exercicio-final](09-exercicio-final/README.md) fecha a aula
com um projeto que junta tudo (rede + segurança + servidor em um único
conjunto de arquivos `.tf`, criado com `terraform apply`). Ao final dele,
você deve me enviar um **relatório em PDF** com prints, comandos
executados e respostas às perguntas de reflexão — é esse PDF que eu uso
para avaliar e lançar a nota. Os detalhes de entrega e a rubrica de
avaliação estão no próprio módulo.
