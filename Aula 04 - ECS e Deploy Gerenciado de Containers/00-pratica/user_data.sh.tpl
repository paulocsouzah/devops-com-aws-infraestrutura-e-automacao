#!/bin/bash
set -e   # para o script imediatamente se qualquer comando falhar

dnf update -y
dnf install -y docker git nginx
systemctl enable --now docker

# Amazon Linux 2023 nao vem com o Docker Compose por padrao — instala
# o plugin oficial.
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Clona a aplicacao
cd /opt
git clone ${repo_url} app
cd app

# Gera o .env com os dados do banco, injetados pelo Terraform via
# templatefile() — ${db_host} etc. ja chegam substituidos, nao sao
# variaveis de shell.
cat > /opt/app/.env <<EOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
EOF

# Sobe a aplicacao
cd /opt/app
docker compose up -d --build

# Configura o Nginx do host como reverse proxy — unica rota, "/" para
# o container do frontend (porta 3000). Aspas simples em 'EOF' para
# $host nao ser interpretado pelo bash.
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
