# Exercício 01 — Baixar e executar o Nginx

## 🎯 Objetivo

Baixar a imagem oficial do **nginx** e executá-la como container,
acessando o servidor web pelo navegador.

---

## Passo 1 — Baixar a imagem

```bash
docker pull nginx
```

Isso baixa a imagem `nginx:latest` do Docker Hub para a máquina
local. Confirme com:

```bash
docker images
```

---

## Passo 2 — Executar o container

```bash
docker run -d -p 8080:80 nginx
```

Explicando as flags:

| Flag        | Significado                                                                 |
|-------------|-------------------------------------------------------------------------------|
| `-d`        | *detached* — roda o container em segundo plano, devolvendo o terminal livre    |
| `-p 8080:80`| mapeia a porta **8080 da máquina host** para a porta **80 dentro do container**|
| `nginx`     | nome da imagem usada para criar o container                                    |

Formato geral do mapeamento de porta: `-p <porta_host>:<porta_container>`.
O nginx, por padrão, escuta internamente na porta 80 — por isso
mapeamos a porta 80 do container para a 8080 da nossa máquina.

---

## Passo 3 — Confirmar que está rodando

```bash
docker ps
```

Você deve ver uma linha parecida com:

```
CONTAINER ID   IMAGE   COMMAND                  STATUS         PORTS                  NAMES
a1b2c3d4e5f6   nginx   "/docker-entrypoint.…"   Up 10 seconds  0.0.0.0:8080->80/tcp   quirky_hopper
```

---

## Passo 4 — Abrir no navegador

Abra o navegador e acesse:

```
http://localhost:8080
```

Você deve ver a página padrão do Nginx: **"Welcome to nginx!"** —
isso confirma que o servidor está funcionando dentro do container. 🎉

---

## Passo 5 — Encerrar o exercício

```bash
# descobrir o ID/nome do container
docker ps

# parar o container
docker stop <container_id_ou_nome>

# remover o container (opcional, libera a listagem)
docker rm <container_id_ou_nome>
```

---

## 🧪 Desafio extra

1. Rode um segundo container do nginx mapeando a porta `8081` em vez
   de `8080` (`docker run -d -p 8081:80 nginx`) e acesse os dois ao
   mesmo tempo — prova de que containers são isolados entre si.
2. Dê um nome customizado ao container usando a flag `--name`:
   ```bash
   docker run -d -p 8080:80 --name meu-nginx nginx
   ```
   Depois use `docker stop meu-nginx` e `docker rm meu-nginx`.
3. Rode `docker logs <id_ou_nome>` em um container do nginx que esteja
   rodando. Depois, em outra aba do navegador, acesse
   `http://localhost:8080` algumas vezes e rode `docker logs` de novo
   — repare como cada acesso gera uma nova linha de log dentro do
   container.
4. Tente rodar um terceiro container mapeando a **mesma porta 8080**
   já usada por outro (`docker run -d -p 8080:80 nginx`). Anote a
   mensagem de erro que aparece e explique, com suas palavras, por que
   isso acontece.

**Próximo passo:** [05-exercicio-02-dockerfile](../05-exercicio-02-dockerfile/README.md)
