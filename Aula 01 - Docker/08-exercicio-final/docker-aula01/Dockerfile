# =============================================================================
# Dockerfile do projeto final (docker-aula01)
# =============================================================================

# Imagem base: nginx, já com servidor web pronto.
FROM nginx

# Copia o index.html para dentro do container, na pasta padrão onde o
# nginx procura os arquivos do site. Copiamos só o index.html (e não
# ".", a pasta inteira) para não levar docker-compose.yml e a pasta
# api/ para dentro da imagem do nginx.
COPY index.html /usr/share/nginx/html
