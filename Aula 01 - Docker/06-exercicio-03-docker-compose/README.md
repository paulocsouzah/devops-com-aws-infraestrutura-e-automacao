# 7. Docker Compose

## 🤔 O problema

Até agora rodamos **um** container por vez, com um `docker run`
relativamente simples. Mas imagine uma aplicação real, composta por
várias partes que precisam rodar **ao mesmo tempo** e conversar entre
si:

```
┌───────────┐   ┌───────────┐   ┌───────────┐   ┌───────────┐
│ Frontend  │   │  Backend  │   │  Banco de │   │   Redis   │
│  (React)  │◄─►│  (API)    │◄─►│  dados    │   │  (cache)  │
└───────────┘   └───────────┘   └───────────┘   └───────────┘
```

Rodar isso tudo manualmente exigiria abrir **quatro terminais**
diferentes, digitar quatro comandos `docker run` longos, lembrar
qual porta mapear em cada um, criar uma rede para eles se
comunicarem, garantir a ordem correta de inicialização... **Isso seria
inviável de manter no dia a dia.**

## ✅ A solução: Docker Compose

O **Docker Compose** resolve exatamente esse problema: descrevemos
**todos os serviços** da aplicação em um único arquivo YAML
(`docker-compose.yml`) e subimos (ou derrubamos) tudo com um único
comando.

---

## 📄 Exemplo

Veja o arquivo [docker-compose.yml](docker-compose.yml) desta pasta:

```yaml
version: "3"

services:

  web:
    image: nginx
    ports:
      - "8080:80"
```

Repare como a estrutura é bem parecida com o `docker run -d -p
8080:80 nginx` que já usamos — só que descrita de forma declarativa,
em um arquivo que pode ser versionado no Git e reaproveitado pelo
time inteiro.

---

## ▶️ Executar

Dentro desta pasta (onde está o `docker-compose.yml`):

```bash
docker compose up
```

Isso vai:
1. Baixar a imagem `nginx` (se ainda não existir localmente).
2. Criar e iniciar o container do serviço `web`.
3. Mostrar os logs no terminal (modo *foreground*).

> 💡 Use `docker compose up -d` para rodar em segundo plano, assim
> como fazíamos com `docker run -d`.

Acesse no navegador:

```
http://localhost:8080
```

---

## ⏹️ Parar

```bash
docker compose down
```

Esse comando para **e remove** os containers criados pelo Compose,
além de limpar a rede criada automaticamente para eles.

---

## 🧪 Exercício

1. Adicione um **segundo serviço** ao `docker-compose.yml`, por
   exemplo um Redis:

   ```yaml
   version: "3"

   services:

     web:
       image: nginx
       ports:
         - "8080:80"

     cache:
       image: redis
       ports:
         - "6379:6379"
   ```

2. Rode `docker compose up -d` e depois `docker ps` — você deve ver
   **dois** containers rodando ao mesmo tempo, subidos com um único
   comando.
3. Rode `docker compose down` e confirme com `docker ps -a` que ambos
   os containers foram removidos.
4. Rode `docker compose ps` (com os serviços de pé) e compare a saída
   com `docker ps` — repare que o Compose também nomeia os containers
   de forma previsível, prefixando com o nome da pasta do projeto.
5. **Desafio:** adicione a flag `container_name` a um dos serviços
   (por exemplo `container_name: meu-servidor-web` no serviço `web`) e
   suba de novo com `docker compose up -d`. Rode `docker ps` e veja
   como o nome do container mudou. Em seguida, adicione a opção
   `restart: unless-stopped` ao mesmo serviço e explique, com suas
   palavras, o que essa opção resolve em um ambiente de produção.

**Próximo passo:** [07-exercicio-04-node-mysql](../07-exercicio-04-node-mysql/README.md)
