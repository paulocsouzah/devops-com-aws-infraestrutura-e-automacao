#!/bin/bash
# user_data.sh.tpl — provisionamento automatico completo
#
# Entregue pelo Terraform via templatefile(): os placeholders abaixo
# (db_host, db_port, db_name, db_user, db_password, repo_url) ja chegam
# SUBSTITUIDOS pelo valor real antes deste script ser entregue a
# instancia — nao sao variaveis de shell.
set -e   # para o script imediatamente se qualquer comando falhar

# -----------------------------------------------------------------------
# 1. Pacotes base
# -----------------------------------------------------------------------
dnf update -y
dnf install -y docker git nginx
systemctl enable --now docker

# -----------------------------------------------------------------------
# 2. Docker Compose (plugin) — o Amazon Linux 2023 nao vem com ele
# -----------------------------------------------------------------------
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# -----------------------------------------------------------------------
# 2b. Buildx (plugin) — "docker compose build" (chamado pelo --build no
# passo 5) exige o plugin buildx para montar as imagens; o Amazon Linux
# 2023 tambem nao vem com ele instalado por padrao.
# -----------------------------------------------------------------------
BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep -m1 '"tag_name"' | cut -d '"' -f4)
curl -SL "https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-amd64" \
  -o /usr/local/lib/docker/cli-plugins/docker-buildx
chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

# -----------------------------------------------------------------------
# 3. Clonar a aplicacao
# -----------------------------------------------------------------------
cd /opt
git clone ${repo_url} app
cd app

# -----------------------------------------------------------------------
# 4. Gerar o .env com os dados do banco (injetados pelo Terraform)
# -----------------------------------------------------------------------
cat > /opt/app/.env <<EOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
EOF

# -----------------------------------------------------------------------
# 5. Subir a aplicacao
# -----------------------------------------------------------------------
cd /opt/app
docker compose up -d --build

# -----------------------------------------------------------------------
# 6. Configurar o Nginx do host como reverse proxy
#
# Aspas simples em 'EOF' de proposito: $host abaixo deve ser escrito
# LITERALMENTE no arquivo de configuracao do Nginx, nao interpretado
# como variavel de shell por este script.
# -----------------------------------------------------------------------
cat > /etc/nginx/conf.d/app.conf <<'EOF'
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

systemctl enable --now nginx
systemctl restart nginx
