# Exercício 04 — API Node.js + MySQL com Docker Compose

## 🎯 Objetivo

No módulo anterior vimos o Docker Compose com **um único serviço**
(nginx). Agora vamos dar um passo real: orquestrar **dois serviços que
dependem um do outro** — uma API em Node.js e um banco de dados
MySQL — tudo organizado em um único `docker-compose.yml`.

Esse é o tipo de cenário em que o Compose realmente "brilha": sem ele,
seria preciso criar uma rede manualmente, rodar dois `docker run`
longos, garantir a ordem de inicialização e configurar volumes na mão.

---

## 📁 Estrutura da pasta

```
07-exercicio-04-node-mysql/
├── docker-compose.yml       # orquestra os serviços "api" e "db"
└── api/
    ├── Dockerfile            # imagem da API Node.js
    ├── package.json          # dependências (express, mysql2)
    ├── index.js               # código da API
    └── db/
        └── init.sql           # cria e popula a tabela "usuarios"
```

---

## 🧩 Entendendo as peças

### O serviço `api`

- É **construído** (`build: ./api`) a partir do
  [api/Dockerfile](api/Dockerfile), e não baixado pronto do Docker Hub.
- Recebe configuração do banco via **variáveis de ambiente**
  (`environment`), lidas dentro de [api/index.js](api/index.js).
- Só inicia depois que o banco estiver **saudável**
  (`depends_on` + `condition: service_healthy`).

### O serviço `db`

- Usa a imagem oficial `mysql:8`.
- Cria o banco `aula_docker` automaticamente via variável de ambiente
  `MYSQL_DATABASE`.
- Usa um **volume nomeado** (`db-data`) para persistir os dados —
  sem isso, todo dado se perderia ao remover o container.
- Monta o script [api/db/init.sql](api/db/init.sql) na pasta especial
  `/docker-entrypoint-initdb.d/`, que o MySQL executa automaticamente
  na primeira inicialização (cria a tabela `usuarios` e insere 3
  registros de exemplo).
- Tem um `healthcheck` que verifica se o MySQL já está pronto para
  aceitar conexões — é esse sinal que o `depends_on` da API espera.

### Como a API "encontra" o banco

Repare na variável `DB_HOST: db` no `docker-compose.yml`. Esse `db` é
exatamente o **nome do serviço** do MySQL — não é um IP nem
`localhost`. O Docker Compose cria uma rede interna onde cada serviço
resolve o nome dos outros automaticamente, como um DNS privado.

```
┌─────────────┐        rede "app-network"        ┌─────────────┐
│   api        │ ── DB_HOST=db ──────────────────>│   db         │
│ (Node.js)    │        porta 3306                 │  (MySQL)     │
└─────────────┘                                    └─────────────┘
      │                                                    │
      │ porta 3000 (host)                    porta 3306 (host, opcional)
      ▼                                                    ▼
 localhost:3000                                    localhost:3306
```

---

## ▶️ Executar

Dentro desta pasta:

```bash
docker compose up -d --build
```

- `--build` força a construção da imagem da API a partir do
  Dockerfile (necessário na primeira vez e sempre que o código mudar).
- `-d` roda tudo em segundo plano.

Acompanhe os logs, se quiser:

```bash
docker compose logs -f
```

Confirme que os dois containers estão de pé:

```bash
docker ps
```

---

## 🧪 Testar a API

No navegador ou com `curl`:

```bash
curl http://localhost:3000/
# {"mensagem":"API Node.js rodando em container 🐳"}

curl http://localhost:3000/usuarios
# [{"id":1,"nome":"Ana Silva","email":"ana@exemplo.com"}, ...]
```

Se `/usuarios` retornar a lista de usuários, a API conseguiu se
conectar ao MySQL com sucesso — prova de que os dois containers estão
se comunicando pela rede interna do Compose.

---

## ⏹️ Parar

```bash
# para os containers, mas MANTÉM o volume (os dados do banco continuam)
docker compose down

# para os containers E apaga o volume (perde os dados do banco)
docker compose down -v
```

---

## 🧪 Exercício

1. Suba o ambiente e confirme que `GET /usuarios` retorna os 3
   usuários criados pelo `init.sql`.
2. Rode `docker compose down` (sem `-v`) e depois `docker compose up
   -d` novamente — confirme que os dados **continuam lá** (graças ao
   volume `db-data`).
3. Agora rode `docker compose down -v` e suba de novo — confirme que
   os dados voltam ao estado inicial (o volume foi recriado do zero e
   o `init.sql` rodou novamente).
4. **Desafio:** adicione uma nova rota `POST /usuarios` em
   [api/index.js](api/index.js) que insere um novo usuário na tabela,
   reconstrua com `docker compose up -d --build` e teste com:
   ```bash
   curl -X POST http://localhost:3000/usuarios
   ```
   (dica: você vai precisar do middleware `express.json()` e ler
   `req.body` para receber nome/email via JSON).
5. Rode `docker compose logs db` e encontre, no meio do log, a
   mensagem que confirma que o script `init.sql` foi executado. Depois
   rode `docker exec -it <nome_do_container_db> mysql -uroot -proot
   aula_docker -e "SELECT * FROM usuarios;"` para consultar a tabela
   **direto de dentro do container**, sem passar pela API.
6. **Desafio extra:** acrescente um terceiro serviço ao
   `docker-compose.yml`, o **Adminer** (interface web para administrar
   bancos de dados):
   ```yaml
   adminer:
     image: adminer
     ports:
       - "8083:8080"
   ```
   Suba com `docker compose up -d`, acesse `http://localhost:8083`,
   conecte usando servidor `db`, usuário `root`, senha `root` e banco
   `aula_docker` — e explore visualmente a tabela `usuarios`.

**Próximo passo:** [08-exercicio-final](../08-exercicio-final/README.md)
