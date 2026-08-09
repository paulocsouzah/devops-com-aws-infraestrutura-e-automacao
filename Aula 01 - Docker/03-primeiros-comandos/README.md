# 3. Primeiros Comandos

Vamos conhecer, um por um, os comandos essenciais para começar a
trabalhar com Docker no dia a dia. A ideia aqui é digitar cada comando
no terminal e observar a saída antes de passar para o próximo.

---

## 1. `docker version`

Mostra a versão instalada do **client** (CLI) e do **daemon**
(servidor que realmente executa os containers).

```bash
docker version
```

Útil para confirmar que a instalação funcionou e que o daemon está
rodando (se o daemon estiver parado, a seção "Server" dá erro).

---

## 2. `docker info`

Mostra informações detalhadas sobre o ambiente Docker: número de
containers rodando/parados, número de imagens, driver de
armazenamento, quantidade de CPU/memória disponível para o Docker,
etc.

```bash
docker info
```

---

## 3. `docker images`

Lista todas as imagens que já estão baixadas (armazenadas
localmente) na máquina.

```bash
docker images
```

Saída típica:

```
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
nginx        latest    605c77e624dd   2 weeks ago    142MB
```

- **REPOSITORY**: nome da imagem.
- **TAG**: versão da imagem (ex: `latest`, `1.25`, `alpine`).
- **IMAGE ID**: identificador único da imagem.
- **SIZE**: tamanho ocupado em disco.

---

## 4. `docker ps`

Lista apenas os containers que estão **em execução** neste momento.

```bash
docker ps
```

Saída típica:

```
CONTAINER ID   IMAGE   COMMAND                  STATUS         PORTS                  NAMES
a1b2c3d4e5f6   nginx   "/docker-entrypoint.…"   Up 2 minutes   0.0.0.0:8080->80/tcp   festive_curie
```

---

## 5. `docker ps -a`

A flag `-a` (all) lista **todos** os containers, inclusive os que já
foram parados. Muito útil para ver o histórico do que já rodou na
máquina.

```bash
docker ps -a
```

---

## 6. `docker pull nginx`

Baixa a imagem `nginx` (versão `latest`, por padrão) do Docker Hub
para a máquina local, sem executá-la ainda.

```bash
docker pull nginx
```

Equivale a "baixar o instalador" — ainda não abrimos o programa.

---

## 7. `docker run nginx`

Cria e inicia um **container** a partir da imagem `nginx`. Se a
imagem ainda não existir localmente, o Docker faz o `pull`
automaticamente antes de rodar.

```bash
docker run nginx
```

⚠️ Rodando assim, "no modo simples", o terminal fica "preso" mostrando
os logs do container (modo *foreground*), e nenhuma porta é exposta
para acesso externo. Nos próximos módulos vamos usar flags como `-d`
(rodar em segundo plano) e `-p` (mapear porta) para tornar isso
prático.

Para interromper esse container "preso" no terminal, use `Ctrl + C`.

---

## 8. `docker stop`

Para um container em execução, enviando um sinal de encerramento
gracioso (`SIGTERM`, com fallback para `SIGKILL` depois de um tempo).

```bash
# primeiro descubra o ID ou nome do container
docker ps

# depois pare pelo ID (ou nome)
docker stop <container_id_ou_nome>
```

---

## 9. `docker rm`

Remove um container **parado** (que não esteja mais em execução).
Isso libera espaço em disco e limpa a listagem do `docker ps -a`.

```bash
docker rm <container_id_ou_nome>
```

💡 Dica: para parar **e** remover em um único passo, é comum usar
`docker rm -f <id>` (força a parada e remove), embora o ideal seja
sempre parar antes de remover.

---

## 📋 Resumo rápido

| Comando              | O que faz                                              |
|-----------------------|--------------------------------------------------------|
| `docker version`      | Mostra versão do client e do daemon                     |
| `docker info`         | Mostra informações detalhadas do ambiente Docker         |
| `docker images`       | Lista imagens baixadas localmente                        |
| `docker ps`           | Lista containers em execução                             |
| `docker ps -a`        | Lista todos os containers (inclusive parados)             |
| `docker pull nginx`   | Baixa a imagem `nginx` do Docker Hub                      |
| `docker run nginx`    | Cria e inicia um container a partir da imagem `nginx`     |
| `docker stop <id>`    | Para um container em execução                            |
| `docker rm <id>`      | Remove um container parado                                |

---

## 🧪 Exercício

Agora é sua vez de praticar cada comando que acabamos de ver, na
ordem. Vá anotando a saída de cada passo — você vai precisar disso no
relatório do exercício final.

1. Rode `docker pull alpine` (uma imagem Linux minimalista, ótima pra
   testar) e depois confirme com `docker images` que ela apareceu na
   lista.
2. Rode `docker run alpine echo "Rodando no container"`. Repare que o
   container executa o comando, imprime a saída e já encerra sozinho
   — nem todo container fica "vivo" para sempre.
3. Rode `docker ps` (deve estar vazio) e depois `docker ps -a` — o
   container do passo anterior deve aparecer com status `Exited`.
4. Copie o `CONTAINER ID` (ou `NAMES`) que apareceu e remova esse
   container com `docker rm <id>`. Confirme com `docker ps -a` que ele
   sumiu da lista.
5. **Desafio:** rode `docker pull` de mais duas imagens diferentes
   (por exemplo `busybox` e `hello-world`), depois rode
   `docker images` e responda: qual das imagens baixadas é a maior em
   tamanho (coluna `SIZE`)? Por que você acha que ela é maior?

**Próximo passo:** [04-exercicio-01-nginx](../04-exercicio-01-nginx/README.md)
