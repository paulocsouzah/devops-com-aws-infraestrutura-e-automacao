# ⚙️ Aula de Provisionamento Automático — User Data, Cloud-Init e RDS

Material didático completo para a aula de **Provisionamento Automático de
Servidores**, do conceito de User Data/Cloud-Init até uma aplicação
**React + Node.js + RDS MySQL** rodando em produção numa EC2 que se
configura sozinha — sem nenhum comando manual depois do `terraform apply`.

Esta aula parte de onde a [Aula 02](<../Aula 02 - Terraform/README.md>)
parou: a mesma rede, o mesmo Security Group, a mesma EC2. A diferença é
que agora a máquina não fica "vazia" — ela nasce pronta, com a aplicação
rodando.

> 📦 **Repositório da aplicação:** o `app-aula03` usado como base nesta
> aula (e clonado pelo `user_data` no módulo 05 e no exercício final) está
> publicado em **[github.com/paulocsouzah/app-aula03](https://github.com/paulocsouzah/app-aula03)**
> — separado deste repositório de infraestrutura, como recomenda o
> [módulo 03](03-preparando-a-aplicacao/README.md). É a URL desse
> repositório que vai em `app_repo_url` no `terraform.tfvars`.

## 📚 Estrutura

| Pasta | Conteúdo |
|-------|----------|
| [00-pratica](00-pratica/README.md) | O projeto Terraform real desta aula — nasce como cópia do `00-pratica` da Aula 02 |
| [01-conceitos](01-conceitos/README.md) | User Data, Cloud-Init, por que banco de dados gerenciado (RDS) em vez de container |
| [02-user-data-na-pratica](02-user-data-na-pratica/README.md) | Sintaxe do `user_data` no Terraform, primeiro script de teste, onde ver os logs de execução |
| [03-preparando-a-aplicacao](03-preparando-a-aplicacao/README.md) | A aplicação da aula: React (frontend) + Node/Express (api), Dockerfiles e `docker-compose.yml` — repositório separado, fora de `00-pratica` |
| [04-exercicio-01-rds](04-exercicio-01-rds/README.md) | Expandir a rede (2ª subnet/AZ) e criar o banco gerenciado: RDS MySQL |
| [05-exercicio-02-provisionamento-automatico](05-exercicio-02-provisionamento-automatico/README.md) | `user_data` completo: instala Docker, Compose, Git e Nginx, clona o repositório e sobe a aplicação sozinho |
| [06-organizacao-e-boas-praticas](06-organizacao-e-boas-praticas/README.md) | Dependências entre recursos, tempo de provisionamento do RDS x EC2, troubleshooting de Cloud-Init |
| [07-exercicio-final](07-exercicio-final/README.md) | Validação de ponta a ponta de `00-pratica` — infraestrutura completa + aplicação no ar sem nenhum SSH manual — entrega em PDF |

## ▶️ Como usar

Siga as pastas na ordem numérica — cada módulo de exercício edita os
arquivos dentro de [`00-pratica/`](00-pratica/README.md), que é o
projeto real desta aula. Não existe "recriar do zero" no exercício
final — ele só valida o que já foi construído ao longo da aula.

**Pré-requisitos:**

- Ter concluído a [Aula 02 - Terraform](<../Aula 02 - Terraform/README.md>)
  — copie o `00-pratica` de lá para começar esta aula (veja o README de
  [00-pratica](00-pratica/README.md)).
- Acesso ativo ao **AWS Academy Learner Lab** (credenciais renovadas no
  início da sessão, como nas aulas anteriores).
- Docker e Terraform já instalados (Aulas 01 e 02).
- Conhecimento básico de Node.js/npm é bem-vindo, mas não obrigatório —
  o foco da aula é a **infraestrutura e a automação**, não escrever a
  aplicação do zero.

⚠️ **Regra de ouro, como sempre:** nenhum recurso pode ser criado
manualmente pelo Console da AWS. Tudo precisa nascer do
`terraform apply` — inclusive a instalação de software dentro da EC2,
que agora acontece via `user_data`, não via SSH manual.

## 🖼️ Visão geral do que vamos construir

![Arquitetura da aplicação — Aula 03: EC2 com Nginx e containers frontend/api, provisionada via User Data, conectada a um RDS MySQL numa subnet privada](01-conceitos/arquitetura.png)

> 💡 A imagem simplifica dois detalhes de rede que existem de verdade no
> projeto, mas não estão desenhados: o **Internet Gateway** e a
> **Route Table** que dão acesso à internet para a subnet pública
> (módulo 04, reaproveitados da Aula 02), e os **Security Groups**
> (`sg-web` na EC2, `sg-rds` no banco) que controlam exatamente quem
> pode falar com quem. O diagrama técnico completo, com esses dois
> elementos, está no [módulo 07](07-exercicio-final/README.md).

Ao rodar `terraform apply`, em poucos minutos você terá, sem tocar em
nada manualmente:

1. Um banco **RDS MySQL** gerenciado pela AWS, isolado numa subnet
   privada.
2. Uma **EC2** que, assim que liga, instala Docker/Compose/Git/Nginx,
   clona o repositório da aplicação, injeta o endereço do banco e sobe
   os containers — tudo sozinha, via `user_data`.
3. Um **frontend em React** e uma **API em Node.js** acessíveis pelo
   navegador, conectados ao RDS.

## 🏁 Avaliação

O módulo [07-exercicio-final](07-exercicio-final/README.md) fecha a aula
com o projeto `terraform-aula03`, que junta rede + segurança + RDS + EC2
autoprovisionada em um único `terraform apply`. Ao final, você deve me
enviar um **relatório em PDF** com prints, comandos executados e
respostas às perguntas de reflexão — os detalhes de entrega e a rubrica
de avaliação estão no próprio módulo.
