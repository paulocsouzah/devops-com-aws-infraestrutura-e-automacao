# 3. Preparando a Aplicação — React + Node + MySQL

Antes de automatizar a infraestrutura, precisamos ter **o que** vai ser
implantado nela. Este módulo é sobre a aplicação em si — o próximo
repositório Git que a EC2 vai clonar sozinha, no módulo 05.

Repare que esta aplicação evolui a mesma ideia da Aula 01
(`docker-aula01`: web + api + db), mas com duas mudanças propositais:

- O frontend deixa de ser HTML estático e passa a ser um **projeto
  React**.
- O `db` deixa de ser um container e passa a ser o **RDS MySQL**, criado
  no módulo 04 — o código da API muda muito pouco por causa disso (só o
  `DB_HOST`), e isso é exatamente o ponto: **a mesma aplicação, rodando
  sobre infraestrutura diferente.**

---

## 🏗️ Arquitetura da aplicação

![Arquitetura da aplicação — Aula 03: EC2 com Nginx e containers frontend/api, provisionada via User Data, conectada a um RDS MySQL numa subnet privada](../01-conceitos/arquitetura.png)

> 💡 A imagem é a visão de infraestrutura completa (módulos 04 e 05);
> este módulo cuida só das duas caixas do meio — `frontend` e `api` —
> que juntas formam o repositório `app-aula03`.

- **frontend** — projeto React, buildado em produção (`npm run build`) e
  servido por um Nginx **dentro do próprio container** (build multi-stage).
  Esse mesmo nginx interno também repassa tudo que chega em `/api/` para o
  container da API — ver `frontend/nginx.conf`.
- **api** — Node/Express com duas rotas principais: `GET /usuarios` e
  `POST /usuarios`, conectando no MySQL via `mysql2/promise` (mesma
  biblioteca já usada na Aula 01). Não expõe nenhuma porta para o host —
  só o container do frontend fala com ela, pela rede interna do Compose.
- **Nginx do host** (fora dos containers, instalado pelo User Data no
  módulo 05) tem uma única responsabilidade: receber todo o tráfego
  externo na porta 80 e repassar **tudo** para o container do frontend
  (porta 3000). Quem decide o que é página e o que é chamada de API é o
  nginx **dentro** do container do frontend — isso simplifica o Nginx do
  host e mantém o roteamento junto da aplicação, não da infraestrutura.

---

## 📂 Arquivos deste módulo

A pasta [`app-aula03/`](app-aula03/) contém a aplicação completa e
comentada — use-a como gabarito, mas o ideal é você publicar sua própria
cópia num repositório Git **separado** do repositório de infraestrutura
(prática comum de mercado: infra e aplicação evoluem em ritmos
diferentes).

```
app-aula03/
├── frontend/
│   ├── src/
│   │   ├── App.jsx           # tela única: lista + formulário de usuários
│   │   ├── main.jsx
│   │   └── index.css
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js         # proxy de /api para localhost:4000 (npm run dev)
│   ├── Dockerfile             # build multi-stage: node (build) → nginx (serve)
│   └── nginx.conf             # nginx interno: serve o React e faz proxy de /api
├── api/
│   ├── index.js                # Express + mysql2/promise, com retry de conexão
│   ├── package.json
│   └── Dockerfile
├── docker-compose.yml          # produção: frontend + api (sem serviço de banco)
├── docker-compose.override.yml # dev local: adiciona um MySQL (carregado automático)
├── .env.example                 # formato do .env esperado pela api
└── .gitignore
```

> 💡 **Por que não existe um serviço `db` no `docker-compose.yml`
> principal?** Porque em produção (na EC2) o banco é o RDS, fora dos
> containers. O `docker-compose.override.yml` existe só para o seu
> ambiente **local**, na sua máquina, testar a aplicação antes de
> publicar — reflete a diferença entre os ambientes de Desenvolvimento e
> Produção (lembra da Aula 01?).

---

## 🔧 API — conexão configurável por variável de ambiente

A API não muda entre "rodando localmente contra um MySQL em container" e
"rodando na EC2 contra o RDS" — só a variável `DB_HOST` (e a senha)
mudam. Esse é o principal motivo de usarmos variáveis de ambiente em vez
de valores fixos no código:

```js
const dbConfig = {
  host: process.env.DB_HOST,       // container "db" localmente, endpoint do RDS na EC2
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
};
```

A API também deve criar a própria tabela se ela não existir, na
inicialização (`CREATE TABLE IF NOT EXISTS usuarios ...`) — diferente da
Aula 01, onde um `init.sql` era montado dentro do container do MySQL. O
RDS não tem essa pasta de inicialização automática, então é a aplicação
quem garante seu próprio schema ao subir.

---

## 🖥️ Frontend — o essencial

Uma tela única em React que:

1. Ao carregar, faz `fetch('/api/usuarios')` e lista o resultado.
2. Tem um formulário simples (nome, e-mail) que faz
   `POST /api/usuarios` e recarrega a lista.

Repare que o frontend chama `/api/usuarios`, **caminho relativo**, não
um endereço fixo tipo `http://localhost:4000` — é o nginx **dentro do
próprio container do frontend** quem resolve `/api` para o container da
API (via `frontend/nginx.conf`). Isso permite que o mesmo
`docker-compose.yml` funcione idêntico localmente e em produção, sem
hardcode de IP — e é também por isso que rodar `npm run dev` (Vite, fora
de container) usa um proxy equivalente configurado em
`frontend/vite.config.js`, apontando para a API na porta 4000.

---

## 🐳 `docker-compose.yml` (produção — usado pela EC2)

```yaml
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    depends_on:
      - api

  api:
    build: ./api
    # Sem "ports:" aqui de propósito — só o frontend precisa falar com a
    # api, pela rede interna do Compose. Nada da api fica exposto ao host.
    environment:
      DB_HOST: ${DB_HOST}
      DB_PORT: ${DB_PORT:-3306}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME}
```

Repare que os valores de conexão com o banco **não estão fixos** — vêm de
variáveis de ambiente (`${DB_HOST}` etc.), que serão fornecidas por um
arquivo `.env` no momento do deploy. É exatamente esse `.env` que o
`user_data` da EC2 vai gerar sozinho, com o endpoint real do RDS
(módulo 05).

---

## ✅ Checklist técnico

- [ ] Repositório `app-aula03` criado (pode ser público, no GitHub) com
      `frontend/` e `api/`
- [ ] `api` conecta no banco só por variáveis de ambiente, nunca com
      valor fixo no código
- [ ] `api` cria sua própria tabela na inicialização, se não existir
- [ ] `frontend` chama a API por caminho relativo (`/api/...`), não IP
      fixo
- [ ] `docker-compose.yml` sobe `frontend` + `api` sem serviço de banco
- [ ] (Opcional) `docker-compose.override.yml` com um MySQL local,
      testado na sua máquina com `docker compose up -d --build`

---

## 🧪 Exercício

1. Monte o repositório `app-aula03` seguindo a estrutura acima.
2. Teste **localmente** primeiro: suba um MySQL via
   `docker-compose.override.yml`, aponte `DB_HOST=db` nesse cenário
   local, e confirme que consegue listar e cadastrar usuários pelo
   navegador em `http://localhost:3000`.
3. Publique o repositório no GitHub — vamos precisar da URL dele no
   módulo 05, para o `user_data` clonar.
4. Por que a API **não** deveria ter o endereço do banco de dados escrito
   diretamente no código-fonte (`host: "meu-banco.rds.amazonaws.com"`)?
   Cite pelo menos duas razões práticas.
5. **Desafio:** o `docker-compose.override.yml` é carregado
   *automaticamente* pelo Docker Compose quando você roda
   `docker compose up`, sem precisar referenciá-lo explicitamente. Por
   que isso é conveniente para o cenário de "ambiente local com banco
   extra" — e por que seria perigoso se esse mesmo arquivo fosse
   copiado, sem querer, para dentro da EC2 de produção?

**Próximo passo:** [04-exercicio-01-rds](../04-exercicio-01-rds/README.md)
