# 2. User Data na Prática

Antes de ir direto para o cenário completo (RDS + app), vamos ver o
mecanismo do User Data funcionando isoladamente, num script pequeno e
fácil de conferir — a mesma EC2 que já está em
[`00-pratica/`](../00-pratica/README.md) (trazida da Aula 02) serve de
base.

⚠️ O `user_data` que vamos adicionar agora é **temporário** — só para
ver o mecanismo funcionando. No módulo 05 ele é substituído pelo
`user_data` de verdade, que instala a aplicação completa.

---

## 🔌 Onde o User Data entra no `aws_instance`

```hcl
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = data.aws_key_pair.vockey.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${var.project_name}-ec2-web"
  }
}
```

(esse é o mesmo `resource "aws_instance" "web"` que você já tem em
`00-pratica/ec2.tf`, trazido da Aula 02 — só adicione a linha
`user_data` a ele, não crie um recurso novo)

- `file("${path.module}/user_data.sh")` lê o conteúdo de um arquivo
  `.sh` na mesma pasta do projeto e entrega como User Data.
- Alternativa mais avançada, que vamos usar a partir do módulo 05:
  `templatefile(...)`, que permite **injetar variáveis do Terraform
  dentro do script** (ex: o endereço do banco RDS). Por enquanto, `file()`
  simples já resolve.

> ⚠️ **User Data só roda na primeira inicialização da instância.** Se
> você editar o script depois que a EC2 já existe e rodar
> `terraform apply` de novo, o Terraform **recria a instância do zero**
> (o User Data força um `-/+` no plan) — ele não "reexecuta" o script numa
> máquina já existente. Isso é esperado e é uma das coisas que vamos
> observar no exercício abaixo.

---

## 🧪 Primeiro teste: um script simples

Vamos provar que o mecanismo funciona antes de complicar. Um script que
instala e configura o Nginx sozinho, sem nenhuma intervenção manual:

```bash
#!/bin/bash
# user_data.sh — teste do mecanismo de User Data

# Atualiza os pacotes do sistema
dnf update -y

# Instala e liga o Nginx
dnf install -y nginx
systemctl enable --now nginx

# Sobrescreve a página padrão para provar que o script rodou
echo "<h1>Provisionado automaticamente via User Data 🎉</h1>" > /usr/share/nginx/html/index.html
```

### Passo a passo

1. Dentro de [`00-pratica/`](../00-pratica/README.md), crie o arquivo
   `user_data.sh` com o conteúdo acima.
2. Adicione a linha `user_data = file("${path.module}/user_data.sh")` ao
   `aws_instance` em `00-pratica/ec2.tf`.
3. Rode:

   ```bash
   terraform plan
   ```

   Se a instância já existir de um módulo anterior, repare que o `plan`
   mostra `-/+` (destruir e recriar) — é o comportamento esperado, User
   Data só entra em vigor numa instância **nova**.

4. Aplique:

   ```bash
   terraform apply
   ```

5. Espere ~1 minuto (tempo de boot + execução do script) e acesse
   `http://<instance_public_ip>` no navegador. Se aparecer a mensagem do
   `echo`, o User Data funcionou de ponta a ponta, sem você ter tocado na
   máquina.

---

## 🔍 Onde ver os logs do Cloud-Init

Se algo não funcionar como esperado, o primeiro lugar a olhar **sempre**
é o log de execução do Cloud-Init, dentro da instância:

```bash
ssh -i vockey.pem ec2-user@<instance_public_ip>

# Log completo (stdout + stderr do script de User Data)
sudo cat /var/log/cloud-init-output.log

# Log detalhado do próprio Cloud-Init (fases de boot, erros internos)
sudo cat /var/log/cloud-init.log

# Acompanhar em tempo real (útil se você conectar antes do script terminar)
sudo tail -f /var/log/cloud-init-output.log
```

> 💡 Se o `index.html` não mudou, quase sempre a causa está registrada
> ali — erro de sintaxe no bash, pacote com nome errado, comando que
> pede confirmação interativa (User Data roda sem ninguém para responder
> "yes"), etc.

---

## ✅ Checklist técnico

- [ ] `user_data.sh` de teste criado e referenciado no `ec2.tf`
- [ ] `terraform plan` mostra a recriação da instância (`-/+`) ao
      adicionar/alterar o User Data
- [ ] `terraform apply` concluído
- [ ] Página customizada acessível em `http://<instance_public_ip>`,
      sem nenhum comando manual dentro da instância
- [ ] Logs do Cloud-Init localizados e lidos via SSH

---

## 🧪 Exercício

1. Siga o passo a passo acima e confirme a página customizada no
   navegador.
2. Guarde o print da página no navegador **e** do trecho relevante de
   `/var/log/cloud-init-output.log` mostrando o script executando.
3. **Desafio (provocar um erro de propósito):** insira um comando
   inválido no meio do script (ex: `dnf instal -y nginx`, com erro de
   digitação), aplique de novo e confira: o restante do script continua
   executando após o erro, ou tudo para ali? Onde exatamente essa falha
   aparece no log? Depois do teste, **corrija o script** e aplique
   novamente.
4. Por que o Terraform **recria a instância inteira** quando o User Data
   muda, em vez de simplesmente "rodar o script de novo" na instância
   existente? Que relação isso tem com o conceito de instância
   **imutável** (immutable infrastructure)?

**Próximo passo:** [03-preparando-a-aplicacao](../03-preparando-a-aplicacao/README.md)
