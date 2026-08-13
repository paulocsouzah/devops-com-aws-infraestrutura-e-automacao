#!/bin/bash
# user_data.sh — teste do mecanismo de User Data (modulo 02)
#
# Este script so prova que o mecanismo funciona: instala e configura o
# Nginx sozinho, sem nenhuma intervencao manual apos o "terraform apply".

# Atualiza os pacotes do sistema
dnf update -y

# Instala e liga o Nginx
dnf install -y nginx
systemctl enable --now nginx

# Sobrescreve a pagina padrao para provar que o script rodou
echo "<h1>Provisionado automaticamente via User Data 🎉</h1>" > /usr/share/nginx/html/index.html
