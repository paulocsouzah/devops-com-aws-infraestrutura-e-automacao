# =============================================================================
# Dockerfile da API Node.js
# =============================================================================

# Imagem base oficial do Node.js, na variante "alpine" — uma distro
# Linux minimalista que deixa a imagem final bem mais leve.
FROM node:20-alpine

# Define a pasta de trabalho dentro do container. Todos os comandos
# seguintes (COPY, RUN, CMD) passam a ser relativos a essa pasta.
WORKDIR /app

# Copiamos PRIMEIRO apenas os arquivos de dependências (package.json e
# package-lock.json, se existir). Isso é uma otimização de cache: o
# Docker só reexecuta o "npm install" se esses arquivos mudarem. Se
# copiássemos todo o código antes, qualquer alteração em uma única
# linha do index.js invalidaria o cache e forçaria reinstalar tudo.
COPY package*.json ./

RUN npm install

# Agora sim copiamos o restante do código da aplicação.
COPY . .

# Documenta (não expõe de fato) que o processo dentro do container
# escuta na porta 3000. Quem realmente expõe é o "ports" do compose.
EXPOSE 3000

# Comando padrão executado quando o container inicia.
CMD ["node", "index.js"]
