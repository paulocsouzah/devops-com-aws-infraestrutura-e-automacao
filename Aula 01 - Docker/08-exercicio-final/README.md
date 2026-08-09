# Exercício Final — docker-aula01

Chegou a hora de juntar **tudo** o que vimos nesta aula em um projeto
só, do zero, com as suas próprias mãos.

Nos módulos anteriores você praticou cada peça isoladamente: rodar um
container pronto, construir sua própria imagem com `Dockerfile`,
orquestrar serviços com `docker-compose.yml` e fazer dois containers
conversarem entre si (API + banco de dados). Neste exercício final,
essas peças se juntam em **um único ambiente com três containers**.

A pasta [docker-aula01/](docker-aula01/) contém a solução completa e
comentada — use-a como gabarito se travar em algum passo, mas o
objetivo é que **você refaça cada etapa por conta própria**, no seu
computador, em uma pasta separada.

---

## 🎯 O que você vai construir

Um pequeno sistema com três containers conversando entre si, todos
subindo com um único `docker compose up`:

```
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│     web       │        │     api       │        │      db       │
│ (nginx, sua   │        │ (Node.js,     │◄──────►│ (MySQL 8,      │
│  própria      │        │  consulta o   │  rede   │  volume        │
│  imagem)      │        │  banco)       │ interna │  persistente)  │
└──────┬───────┘        └──────┬───────┘        └──────────────┘
       │ :8082 (host)          │ :3000 (host)
       ▼                       ▼
  localhost:8082          localhost:3000/usuarios
```

- **web** — site institucional em HTML, empacotado com um
  `Dockerfile` próprio (igual ao módulo 05).
- **api** — API em Node.js que consulta o MySQL (reaproveite o código
  do módulo 07).
- **db** — MySQL com dados persistidos em volume e populados
  automaticamente na primeira subida (igual ao módulo 07).

Ou seja: este exercício não tem conteúdo novo — ele testa se você
consegue **combinar** tudo o que já funcionou separadamente.

---

## 🛠️ Passo a passo

### 1. Criar a estrutura de pastas

```bash
mkdir -p docker-aula01/api/db
cd docker-aula01
```

```
docker-aula01/
├── index.html
├── Dockerfile
├── docker-compose.yml
└── api/
    ├── Dockerfile
    ├── package.json
    ├── index.js
    └── db/
        └── init.sql
```

### 2. Criar o `index.html` (serviço `web`)

```html
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8" />
  <title>docker-aula01</title>
</head>
<body>
  <h1>Projeto final — docker-aula01</h1>
  <p>Site servido por um container nginx construído com Dockerfile.</p>
  <p>
    <a href="http://localhost:3000/usuarios" target="_blank">
      Ver usuários cadastrados (via API em outro container)
    </a>
  </p>
</body>
</html>
```

Repare no link: ele aponta para o container **api**, que roda em
**outro** container, escutando em outra porta. Essa é a prova visual
de que os três serviços estão de pé e conversando.

### 3. Criar o `Dockerfile` do `web`

Igual ao que você já fez no módulo 05:

```dockerfile
FROM nginx
COPY index.html /usr/share/nginx/html
```

### 4. Reaproveitar a API do módulo 07

Copie (ou recrie) dentro de `api/` os quatro arquivos do exercício 04:
[Dockerfile](../07-exercicio-04-node-mysql/api/Dockerfile),
[package.json](../07-exercicio-04-node-mysql/api/package.json),
[index.js](../07-exercicio-04-node-mysql/api/index.js) e
[db/init.sql](../07-exercicio-04-node-mysql/api/db/init.sql). Não
precisa reinventar — a ideia aqui é reconhecer que o mesmo serviço que
você já testou isoladamente pode ser encaixado em um projeto maior.

### 5. Criar o `docker-compose.yml` juntando os três serviços

```yaml
version: "3.8"

services:

  web:
    build: .
    image: docker-aula01-web
    ports:
      - "8082:80"

  api:
    build: ./api
    ports:
      - "3000:3000"
    environment:
      DB_HOST: db
      DB_USER: root
      DB_PASSWORD: root
      DB_NAME: aula_docker
    depends_on:
      db:
        condition: service_healthy

  db:
    image: mysql:8
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: aula_docker
    ports:
      - "3307:3306"
    volumes:
      - db-data:/var/lib/mysql
      - ./api/db/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 5s
      retries: 10

volumes:
  db-data:
```

> 💡 A porta do host do `db` foi mudada para `3307` (em vez de
> `3306`) só para não colidir, caso o ambiente do exercício 04 ainda
> esteja rodando ao mesmo tempo neste. Cada `docker-compose.yml`
> mora em uma pasta diferente e cria seus próprios containers — mas as
> **portas do host** são compartilhadas pela máquina inteira.

### 6. Subir tudo

```bash
docker compose up -d --build
```

Confirme que os três containers estão de pé:

```bash
docker ps
```

### 7. Testar cada peça

```bash
# web
# abra no navegador:
http://localhost:8082

# api
curl http://localhost:3000/usuarios

# db (opcional, direto no container)
docker exec -it docker-aula01-db-1 mysql -uroot -proot aula_docker -e "SELECT * FROM usuarios;"
```

Clique no link da página web e confirme que ele abre a lista de
usuários vinda da API — esse é o momento em que tudo se conecta.

### 8. Encerrar

```bash
docker compose down       # mantém o volume do banco
docker compose down -v    # remove também os dados do banco
```

---

## ✅ Checklist técnico

- [ ] Pasta `docker-aula01` criada com a estrutura de arquivos indicada
- [ ] `index.html` com link para a API
- [ ] `Dockerfile` do `web` criado e funcionando
- [ ] API (`api/`) reaproveitada do exercício 04
- [ ] `docker-compose.yml` com os três serviços (`web`, `api`, `db`)
- [ ] `docker compose up -d --build` sobe os três containers sem erro
- [ ] `http://localhost:8082` mostra a página com o link
- [ ] `http://localhost:3000/usuarios` (ou o link na página) retorna a lista de usuários
- [ ] `docker compose down` e `docker compose up -d` novamente confirmam que os dados do banco persistem (graças ao volume)

---

## 📄 Entrega: relatório em PDF

Este exercício não termina em rodar o projeto — ele termina quando eu
recebo o seu **relatório em PDF**, documentando tudo o que você fez.
É esse PDF que eu vou usar para avaliar e lançar sua nota.

### O que o PDF precisa conter

1. **Capa** — seu nome completo e a data de entrega.
2. **Prints de tela** de, no mínimo:
   - `docker ps` com os três containers rodando;
   - o navegador em `http://localhost:8082` mostrando a página;
   - o resultado de `http://localhost:3000/usuarios` (navegador ou `curl`);
   - o resultado do teste de persistência (`docker compose down` →
     `docker compose up -d` → dados continuam lá).
3. **Os comandos que você executou**, na ordem, do primeiro ao
   último (pode ser em blocos de código, copiados do seu terminal).
4. **Respostas escritas, com suas próprias palavras**, para as
   perguntas de reflexão abaixo.
5. **Dificuldades encontradas** — conte pelo menos um problema real
   que você teve (erro de porta ocupada, container que não subia,
   erro de digitação no YAML, o que for) e como você resolveu. Isso
   mostra que você realmente executou o exercício, e não só copiou o
   gabarito.

### Perguntas de reflexão (responda todas no PDF)

1. Qual a diferença entre uma **imagem** e um **container**? Use um
   exemplo deste próprio projeto na sua resposta.
2. No `docker-compose.yml`, o serviço `api` usa `DB_HOST: db`. Por que
   `db` funciona como endereço, já que não é um IP nem `localhost`?
3. Para que serve o volume `db-data`? O que aconteceria com os dados
   se ele não existisse e você rodasse `docker compose down` seguido
   de `docker compose up`?
4. Para que serve o `healthcheck` do serviço `db` combinado com o
   `depends_on: condition: service_healthy` da `api`? O que poderia
   dar errado sem essa configuração?
5. Se você precisasse escalar esse projeto para produção (mais
   usuários acessando), o que trocaria primeiro nessa configuração
   (senhas fixas no YAML, ausência de HTTPS, etc.)? Não precisa
   implementar — só identificar.

### Como gerar o PDF

Escreva o relatório em qualquer editor (Word, Google Docs, Markdown,
o que for mais confortável para você) e exporte/imprima como PDF. Não
precisa de nenhuma ferramenta especial — a maioria dos editores tem a
opção **"Salvar como PDF"** ou **"Exportar para PDF"** no menu de
arquivo.

### Prazo e envio

Envie o PDF por e-mail (ou pelo canal combinado em sala) até a data
que eu informar durante a aula. Nomeie o arquivo como
`docker-aula01-SEUNOME.pdf`.

---

## 📊 Rubrica de avaliação

| Critério                                                              | Pontos  |
|-------------------------------------------------------------------------|---------|
| Ambiente completo sobe sem erros (`docker compose up -d --build`)         | 2,0     |
| Serviço `web` acessível e customizado                                    | 1,5     |
| Serviço `api` funcional, respondendo `/usuarios`                          | 1,5     |
| Persistência do `db` comprovada (teste de `down`/`up` sem `-v`)           | 1,5     |
| Relatório completo: prints, comandos e explicações próprias               | 2,0     |
| Respostas às perguntas de reflexão demonstrando entendimento real         | 1,0     |
| Organização e clareza geral do PDF                                       | 0,5     |
| **Total**                                                                 | **10,0**|

Parabéns por chegar até aqui — você percorreu todo o caminho:
**conceitos → arquitetura → comandos básicos → Dockerfile → Docker
Compose → múltiplos serviços → projeto integrado.** Bom trabalho! 🐳
