# 6. Dockerfile — Criando nossa própria imagem

Até agora usamos apenas imagens prontas do Docker Hub (`nginx`). A
partir de agora vamos **criar nossa própria imagem**, customizada com
o nosso próprio conteúdo.

Para isso usamos um arquivo chamado **`Dockerfile`** — um roteiro de
instruções que o Docker segue para "montar" a imagem.

---

## 📄 Estrutura do Dockerfile

Veja o arquivo [Dockerfile](Dockerfile) desta pasta:

```dockerfile
FROM nginx

COPY . /usr/share/nginx/html
```

### Explicando cada instrução

#### `FROM`

> Imagem base.

Toda imagem Docker parte de uma **imagem base**. Em vez de começar do
zero (instalando sistema operacional, servidor web, dependências...),
reaproveitamos uma imagem já pronta.

Aqui usamos `FROM nginx`, ou seja: "construa minha imagem em cima da
imagem oficial do nginx", que já vem com um servidor web instalado e
configurado.

#### `COPY`

> Copia arquivos.

A instrução `COPY <origem> <destino>` copia arquivos do nosso
computador (a pasta onde está o Dockerfile, chamada de *contexto de
build*) para dentro da imagem que está sendo criada.

No nosso caso, `COPY . /usr/share/nginx/html` copia **tudo** que está
na pasta atual (`.`) para `/usr/share/nginx/html`, que é exatamente a
pasta onde o nginx procura os arquivos do site por padrão.

---

## 📝 Passo 1 — Criar o `index.html`

Já está pronto em [index.html](index.html):

```html
<h1>Minha primeira aplicação Docker</h1>
```

---

## 🔨 Passo 2 — Build da imagem

Dentro desta pasta (onde estão o `Dockerfile` e o `index.html`),
execute:

```bash
docker build -t minha-app .
```

Explicando o comando:

| Parte           | Significado                                                        |
|------------------|---------------------------------------------------------------------|
| `docker build`   | comando que constrói uma imagem a partir de um Dockerfile            |
| `-t minha-app`   | *tag* — dá um nome (e opcionalmente versão) à imagem gerada          |
| `.`              | contexto de build — "use os arquivos desta pasta atual"              |

Ao final, confirme que a imagem foi criada:

```bash
docker images
```

---

## ▶️ Passo 3 — Executar

```bash
docker run -d -p 8081:80 minha-app
```

Igual ao que fizemos com o nginx puro, mas agora usando **nossa**
imagem (`minha-app`) e uma porta diferente (`8081`), para não colidir
com o container do exercício anterior.

---

## 🌐 Passo 4 — Abrir no navegador

```
http://localhost:8081
```

Você deve ver a mensagem: **"Minha primeira aplicação Docker"** — a
prova de que nosso HTML está sendo servido pelo nginx dentro do
container criado a partir da nossa própria imagem.

---

## 🧪 Exercício

1. **Modifique** o texto do `index.html` (troque a mensagem, adicione
   um parágrafo, mude a cor com um `<style>`, etc.).
2. **Reconstrua** a imagem:
   ```bash
   docker build -t minha-app .
   ```
3. Pare e remova o container antigo, e **execute novamente**:
   ```bash
   docker stop <container_antigo>
   docker rm <container_antigo>
   docker run -d -p 8081:80 minha-app
   ```
4. Atualize o navegador em `http://localhost:8081` e confirme que a
   mudança apareceu.

> 💡 Percebeu que precisamos parar, remover e rodar de novo toda vez
> que mudamos o código? No próximo módulo (Docker Compose) isso fica
> muito mais simples de gerenciar.

5. Rode `docker history minha-app`. Esse comando mostra as **camadas**
   da imagem que você acabou de construir — encontre, na lista, a
   camada criada pela instrução `COPY` do seu `Dockerfile`.
6. **Desafio:** troque a imagem base do `Dockerfile` de `FROM nginx`
   para `FROM nginx:alpine`, refaça o build (`docker build -t
   minha-app .`) e rode `docker images`. Compare o tamanho (`SIZE`) da
   imagem `minha-app` antes e depois da troca — explique por que a
   versão `alpine` costuma ser bem menor.

**Próximo passo:** [06-exercicio-03-docker-compose](../06-exercicio-03-docker-compose/README.md)
