# 5. Exercício 02 — Provisionamento Automático Completo

Agora juntamos tudo: a EC2 vai nascer, instalar sozinha tudo que precisa,
clonar o repositório `app-aula03` (módulo 03) e subir a aplicação já
conectada ao RDS (módulo 04) — sem nenhum SSH manual.

---

## 🧬 De `file()` para `templatefile()`

No módulo 02 usamos `file()`, que só lê um arquivo estático. Agora
precisamos **injetar valores do Terraform dentro do script** — o
endpoint do RDS não existe até o `apply` rodar, então não pode estar
"hardcoded" no script. Para isso existe o `templatefile()`:

```hcl
resource "aws_instance" "app" {
  # ...

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    db_host     = aws_db_instance.main.address
    db_port     = aws_db_instance.main.port
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = var.db_password
    repo_url    = var.app_repo_url
  })

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
```

> 💡 **Dependência implícita:** como o `user_data` referencia
> `aws_db_instance.main.address`, o Terraform entende sozinho que a EC2
> **depende** do RDS — ele só cria a instância depois que o banco estiver
> pronto (`available`), mesmo sem precisarmos escrever
> `depends_on` manualmente. Vamos voltar nesse detalhe no módulo 06.

O arquivo passa a se chamar `user_data.sh.tpl` (a extensão `.tpl` é só
convenção, não obrigatória) e usa a sintaxe `${nome_da_variavel}` para os
pontos que o Terraform substitui antes de entregar o script pronto para
a AWS.

---

## 📂 Arquivos deste módulo

- [`user_data.sh.tpl`](user_data.sh.tpl) — o script completo, comentado.
- [`nginx-app.conf`](nginx-app.conf) — configuração do Nginx do host
  (reverse proxy), copiada para dentro da instância pelo próprio script.
- [`ec2.tf`](ec2.tf) — versão atualizada, usando `templatefile()`.
- [`variables-app.tf`](variables-app.tf) — a variável nova
  (`app_repo_url`), num arquivo separado, pelo mesmo motivo do módulo 04.

---

## 📜 O script de provisionamento, por partes

### 1. Pacotes base

```bash
#!/bin/bash
set -e   # para o script imediatamente se qualquer comando falhar

dnf update -y
dnf install -y docker git nginx
systemctl enable --now docker
```

### 2. Docker Compose (plugin)

O Amazon Linux 2023 não vem com o Docker Compose por padrão — instalamos
o plugin oficial:

```bash
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

### 3. Clonar a aplicação

```bash
cd /opt
git clone ${repo_url} app
cd app
```

`/opt` é o local convencional em Linux para aplicações de terceiros
instaladas fora do gerenciador de pacotes do sistema.

### 4. Gerar o `.env` com os dados do banco (injetados pelo Terraform)

```bash
cat > /opt/app/.env <<EOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
EOF
```

Aqui está o ponto-chave da aula: `${db_host}` e `${db_password}` nesse
bloco **não são variáveis de shell** — são placeholders do
`templatefile()` do Terraform, já substituídos pelo valor real do RDS
**antes** do script ser entregue à instância. Quando a EC2 recebe o User
Data, esse trecho já chega assim:

```bash
cat > /opt/app/.env <<EOF
DB_HOST=terraform-aula03-db.xxxxxxxxxx.us-east-1.rds.amazonaws.com
DB_PORT=3306
...
EOF
```

### 5. Subir a aplicação

```bash
cd /opt/app
docker compose up -d --build
```

### 6. Configurar o Nginx como reverse proxy

```bash
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
```

- O Nginx do host tem **uma única rota**: `/` → container do frontend
  (React), porta 3000. Ele não sabe nada sobre `/api` — quem decide isso
  é o nginx **dentro** do próprio container do frontend
  (`frontend/nginx.conf`, módulo 03), que repassa `/api/` para o
  container da API (`api:4000`) pela rede interna do Docker Compose.
- Isso mantém o Nginx do host simples e estável: ele não muda mesmo que
  a aplicação ganhe novas rotas de API no futuro — quem decide o
  roteamento interno é a própria aplicação, não a infraestrutura.
- O bloco usa aspas simples em `'EOF'` (em vez de `EOF` sem aspas) para
  que `$host` **não** seja interpretado pelo bash como variável de shell
  — ele deve ser escrito literalmente no arquivo de configuração do
  Nginx.

---

## 🔒 Sobre o Security Group nesta etapa

O Security Group `sg-web` da Aula 02 já libera as portas 80/443
publicamente e 22 restrito ao seu IP — **nenhuma mudança é necessária**
nele. A porta 3000 do container do frontend nunca precisa ser aberta
para fora: só o Nginx do host a acessa, internamente
(`localhost:3000`), e é só ele quem fica exposto na porta 80. A porta
4000 da API nem existe do lado de fora do container — como vimos no
módulo 03, o `docker-compose.yml` de produção não publica porta nenhuma
para ela.

---

## 🛠️ Passo a passo

### 1. Adicionar os arquivos

Copie `user_data.sh.tpl`, `nginx-app.conf` e `variables-app.tf` para
dentro do `terraform-aula02`, e substitua o `ec2.tf` pela versão deste
módulo (usa `templatefile()` em vez de `file()`). Preencha
`app_repo_url` no seu `terraform.tfvars` com a URL do seu `app-aula03`
(módulo 03).

### 2. Planejar e aplicar

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Repare no `plan`: como o `user_data` depende do `aws_db_instance`, o
Terraform deve mostrar que a EC2 será criada **depois** do RDS (ou
recriada, se o RDS já existir de antes).

### 3. Acompanhar o provisionamento

```bash
ssh -i vockey.pem ec2-user@<instance_public_ip>
sudo tail -f /var/log/cloud-init-output.log
```

Acompanhe: instalação dos pacotes, clone do repositório, build das
imagens Docker, `docker compose up`, configuração do Nginx.

### 4. Validar no navegador

Acesse `http://<instance_public_ip>` — deve aparecer o frontend em
React, já listando (vazio, na primeira vez) e permitindo cadastrar
usuários, que ficam salvos no RDS.

### 5. Conferir os containers

```bash
docker ps
docker compose -f /opt/app/docker-compose.yml logs api
```

---

## ✅ Checklist técnico

- [ ] `ec2.tf` usando `templatefile()` com todas as variáveis do banco
- [ ] `user_data.sh.tpl` instala Docker, Compose, Git e Nginx sozinho
- [ ] Repositório `app-aula03` clonado automaticamente em `/opt/app`
- [ ] `.env` gerado com o endpoint real do RDS (não um valor fixo)
- [ ] `docker compose up -d --build` executado pelo próprio script
- [ ] Nginx do host redirecionando `/` para o container do frontend, que
      por sua vez roteia `/api/` internamente para a API
- [ ] Aplicação acessível no navegador, cadastro de usuário funcionando
      ponta a ponta (React → API → RDS)
- [ ] Nenhum comando digitado manualmente dentro da instância (SSH usado
      só para **observar**, não para configurar)

---

## 🧪 Exercício

1. Siga o passo a passo e valide a aplicação completa no navegador.
2. Guarde prints: o `terraform apply` concluído, o
   `cloud-init-output.log` mostrando o script rodando até o fim, e a
   aplicação funcionando no navegador (com pelo menos um usuário
   cadastrado).
3. Explique, com suas palavras, a diferença entre `${db_host}` sendo
   substituído pelo **Terraform** (antes do script existir na AWS) e uma
   variável de ambiente sendo lida pelo **bash** dentro do script (ex:
   `$HOME`). Por que essa distinção importa para não confundir os dois
   tipos de `$`/`${}` que aparecem no mesmo arquivo?
4. Se você rodasse `terraform destroy` e `terraform apply` de novo agora
   (recriando tudo do zero), os usuários cadastrados no banco
   apareceriam de novo? Por quê?
5. **Desafio:** o script usa `set -e` logo no início. Pesquise o que
   esse comando faz e explique por que ele é uma boa prática em scripts
   de provisionamento automático (pense no que aconteceria se um passo
   no meio do script falhasse silenciosamente e os passos seguintes
   continuassem rodando mesmo assim).

**Próximo passo:** [06-organizacao-e-boas-praticas](../06-organizacao-e-boas-praticas/README.md)
