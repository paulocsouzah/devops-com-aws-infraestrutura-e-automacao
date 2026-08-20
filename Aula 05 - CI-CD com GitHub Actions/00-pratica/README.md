# 00. Prática — Projeto Terraform desta Aula

Esta pasta **nasce como uma cópia** do
[`00-pratica`](<../../Aula 04 - ECS e Deploy Gerenciado de Containers/00-pratica/README.md>)
da Aula 04, já completa (rede, RDS, ECR, Cluster ECS Fargate, ALB e Auto
Scaling) — é o ponto de partida. A infraestrutura em si não muda nesta
aula; o que muda é **como a imagem chega no ECR e como o Service é
atualizado**: isso deixa de ser manual e passa a ser feito por uma
pipeline do GitHub Actions.

> 💡 Se você está começando a Aula 05 agora, confirme que esta pasta já
> tem os arquivos da Aula 04 (rede, RDS, ECR, ECS, ALB, Auto Scaling) —
> se não tiver, copie o conteúdo de lá antes de seguir.

⚠️ **Antes do primeiro `apply`, atualize o `default` da variável
`project_name`** em `variables.tf`, de `"aula04"` para `"aula05"` — sem
essa troca, os recursos nascem como `aula04-*` e colidem com os que
você já aplicou (e destruiu) na Aula 04.

## 📂 O que muda aqui, módulo a módulo

> Os módulos desta aula ainda estão em construção — esta tabela será
> preenchida conforme cada um for criado (workflow de build/push da
> imagem, secrets do GitHub, deploy automático via nova revisão da Task
> Definition, etc.).

## ⚠️ Antes de começar

- `terraform.tfvars` continua só precisando de `db_password`.
- Não existe mais `vockey.pem` nem acesso SSH — isso já saiu de cena na
  Aula 04.
- Sempre rode `terraform destroy` ao final de cada sessão de estudo — o
  ALB e as tasks Fargate cobram por hora, mesmo sem tráfego.

## 🎯 Ao final desta aula

Esta pasta estará com a mesma infraestrutura da Aula 04, mas o deploy
de uma nova versão da aplicação acontece sozinho a cada `push` na
branch principal — build da imagem, push pro ECR e rolling deployment
no ECS Service, tudo via GitHub Actions.
