# =============================================================================
# Dockerfile — nossa primeira imagem personalizada
# =============================================================================
# Um Dockerfile é uma "receita de bolo": uma lista de instruções que o
# Docker segue, de cima para baixo, para construir uma imagem.
# Cada instrução vira uma nova "camada" (layer) na imagem final.
# =============================================================================

# FROM define a IMAGEM BASE a partir da qual a nossa será construída.
# Aqui partimos da imagem oficial do nginx, que já vem com um servidor
# web pronto para uso — não precisamos instalar nada do zero.
FROM nginx

# COPY copia arquivos da nossa máquina (contexto de build) para dentro
# da imagem. Aqui copiamos TUDO que está na pasta atual ("." — onde
# está este Dockerfile) para a pasta padrão onde o nginx procura os
# arquivos do site: /usr/share/nginx/html
#
#   COPY <origem no host>   <destino no container>
COPY . /usr/share/nginx/html

# A partir daqui, a imagem "minha-app" já contém o nginx + nosso
# index.html. Quando um container for criado a partir dela, o nginx
# vai servir automaticamente o nosso HTML na porta 80.
