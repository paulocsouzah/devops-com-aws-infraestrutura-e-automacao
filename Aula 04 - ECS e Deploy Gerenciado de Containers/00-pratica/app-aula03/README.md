# app-aula03

Aplicação de cadastro de usuários — **React (Vite) + Node/Express + MySQL** —
usada como carga de trabalho da [Aula 03 — Provisionamento Automático](https://github.com/paulocsouzah/devops-com-aws-infraestrutura-e-automacao/tree/main/Aula%2003%20-%20Provisionamento%20Automatico)
do curso *DevOps com AWS: Infraestrutura e Automação*.

Este repositório contém **só a aplicação**. A infraestrutura (VPC, EC2,
RDS, Security Groups) vive separada, no repositório
[`devops-com-aws-infraestrutura-e-automacao`](https://github.com/paulocsouzah/devops-com-aws-infraestrutura-e-automacao) —
é o `user_data` da instância EC2, definido lá, que clona este repositório
e sobe a aplicação automaticamente via `docker compose up -d --build`,
sem nenhum comando manual dentro da instância.

## Arquitetura

- **frontend/** — projeto React (Vite), buildado em produção e servido
  por um Nginx dentro do próprio container (build multi-stage). Esse
  Nginx interno também repassa `/api` para o container da API (ver
  [`frontend/nginx.conf`](frontend/nginx.conf)).
- **api/** — Node/Express com duas rotas principais:
  - `GET /usuarios` — lista os usuários cadastrados
  - `POST /usuarios` — cadastra um novo usuário (`nome`, `email`)

  Conecta no MySQL via `mysql2/promise`, com retry automático na
  inicialização (tolera o banco ainda não estar pronto) e cria a tabela
  `usuarios` sozinha na primeira execução. Não expõe porta ao host — só
  o container do frontend fala com ela, pela rede interna do Compose.
- **MySQL** — em produção é o **RDS** (externo aos containers, endpoint
  injetado via `.env`); em desenvolvimento local, o
  `docker-compose.override.yml` sobe um container MySQL descartável.

```
Nginx (host, produção) → frontend (container, porta 3000) → api (container, rede interna) → MySQL (RDS em produção / container em dev)
```

## Rodando localmente

```bash
cp .env.example .env   # ajuste se quiser, mas o override já cobre o dev local
docker compose up -d --build
```

- Frontend: http://localhost:3000
- API (exposta só em dev, via `docker-compose.override.yml`): http://localhost:4000

O `docker-compose.override.yml` é carregado automaticamente pelo Docker
Compose junto com o `docker-compose.yml` e sobe um MySQL local — não é
usado em produção.

## Rodando em produção (EC2 via Terraform)

Em produção, **não existe override**: só o `docker-compose.yml` é usado,
e o `.env` é gerado automaticamente pelo `user_data` da EC2 com o
endpoint real do RDS — ver
[`user_data.sh.tpl`](https://github.com/paulocsouzah/devops-com-aws-infraestrutura-e-automacao/blob/main/Aula%2003%20-%20Provisionamento%20Automatico/07-exercicio-final/terraform-aula03/user_data.sh.tpl)
no repositório de infraestrutura.

## Variáveis de ambiente (API)

| Variável | Descrição |
|---|---|
| `DB_HOST` | Endereço do MySQL (endpoint do RDS em produção) |
| `DB_PORT` | Porta do MySQL (padrão `3306`) |
| `DB_NAME` | Nome do banco/schema |
| `DB_USER` | Usuário do banco |
| `DB_PASSWORD` | Senha do banco |

Veja [`.env.example`](.env.example).
