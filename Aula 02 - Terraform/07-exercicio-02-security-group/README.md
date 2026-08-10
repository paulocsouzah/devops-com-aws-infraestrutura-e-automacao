# 6. Exercício 02 — Security Group

Com a rede pronta (módulo anterior), o próximo passo é decidir **quem
pode falar com quem** — é isso que um Security Group faz. Vamos continuar
**dentro do mesmo projeto** `terraform-rede` criado no módulo 06 (o
Terraform combina automaticamente todos os arquivos `.tf` de uma pasta),
adicionando um novo arquivo.

---

## 🔒 O que é um Security Group

Um **Security Group (SG)** é um firewall virtual associado a recursos da
AWS (mais comumente, instâncias EC2). Ele funciona com regras de:

- **Ingress** (entrada) — de onde e em qual porta o tráfego pode
  **chegar** até o recurso.
- **Egress** (saída) — para onde o recurso pode **enviar** tráfego.

Uma característica importante: Security Groups são **stateful**. Se uma
conexão de entrada é permitida por uma regra de `ingress`, a resposta
dessa mesma conexão é liberada automaticamente na saída — você não
precisa criar uma regra de `egress` espelhada para cada `ingress`.

### As três portas desta aula

| Porta | Protocolo/uso | Quem pode acessar |
|---|---|---|
| 22 | SSH — acesso remoto ao terminal do servidor | **Só o seu IP** |
| 80 | HTTP — acesso à aplicação web | Público (`0.0.0.0/0`) |
| 443 | HTTPS — acesso seguro à aplicação web | Público (`0.0.0.0/0`) |

⚠️ **Por que restringir o SSH ao seu IP e não liberar para todo mundo?**
A porta 22 aberta para `0.0.0.0/0` é constantemente varrida por bots na
internet tentando adivinhar senha/chave — é uma das formas mais comuns de
uma instância ser comprometida. HTTP/HTTPS são públicos por natureza (é
a aplicação que o mundo deve acessar), então liberamos para todo mundo.

---

## 📂 Arquivo deste módulo

- [`security-group.tf`](security-group.tf) — o recurso `aws_security_group`,
  comentado. Copie este arquivo para dentro da pasta `terraform-rede`.

---

## 🛠️ Passo a passo

### 1. Descobrir o seu IP público

```bash
curl https://checkip.amazonaws.com
```

Isso retorna algo como `203.0.113.42`. Guarde esse valor.

> 💡 Se você estiver em uma rede que muda de IP com frequência (Wi-Fi de
> faculdade, 4G/5G), pode precisar repetir este passo e atualizar a
> variável em outra sessão de estudo.

### 2. Adicionar a variável `my_ip`

No arquivo `variables.tf` do projeto `terraform-rede`, adicione:

```hcl
variable "my_ip" {
  description = "Seu IP público, usado para restringir o acesso SSH"
  type        = string
}
```

Repare que essa variável **não tem `default`** — isso obriga você a
informar o valor na hora de rodar o Terraform, em vez de deixar um IP
fixo esquecido no código (e possivelmente commitado no Git).

### 3. Informar o valor sem deixá-lo hardcoded no código versionado

Crie um arquivo `terraform.tfvars` (não vai para o Git — já está no
`.gitignore` do módulo 05):

```hcl
my_ip = "203.0.113.42"
```

O Terraform carrega automaticamente qualquer `terraform.tfvars` presente
na pasta, sem precisar de flag adicional.

### 4. Copiar o `security-group.tf` para o projeto

Copie o arquivo [`security-group.tf`](security-group.tf) deste módulo
para dentro da pasta `terraform-rede`.

### 5. Planejar e aplicar

```bash
cd terraform-rede
terraform fmt
terraform validate
terraform plan
```

Confira que o `plan` mostra **apenas 1 recurso novo** a ser criado (o
Security Group) — os recursos de rede do módulo anterior devem aparecer
como "sem mudanças", já que continuam iguais.

```bash
terraform apply
```

### 6. Conferir no Console

Console da AWS → **EC2 → Security Groups** → confirme as 3 regras de
`ingress` e a regra de `egress`.

---

## ✅ Checklist técnico

- [ ] IP público descoberto com `curl https://checkip.amazonaws.com`
- [ ] Variável `my_ip` adicionada em `variables.tf` (sem `default`)
- [ ] `terraform.tfvars` criado com o valor do seu IP (**não commitado**)
- [ ] `security-group.tf` copiado para dentro de `terraform-rede`
- [ ] `terraform plan` mostra 1 recurso novo (o SG), rede sem alterações
- [ ] `terraform apply` concluído, SG conferido no Console

---

## 🧪 Exercício

1. Siga o passo a passo acima e crie o Security Group.
2. Guarde o print das regras do SG no Console (mostrando as portas 22,
   80 e 443).
3. Responda: por que a regra de SSH usa `${var.my_ip}/32` (com `/32`) em
   vez de só `var.my_ip`? O que o `/32` significa em notação CIDR?
4. **Desafio:** o que aconteceria de errado, na prática, se você
   esquecesse a regra de `egress`, mas mantivesse as três de `ingress`?
   (Dica: pense em uma instância que recebe uma requisição HTTP, tenta
   consultar uma API externa para montar a resposta, e depois tenta
   devolver essa resposta ao usuário — quais dessas trocas dependem de
   tráfego de saída?)

**Próximo passo:** [08-exercicio-03-ec2-com-iam](../08-exercicio-03-ec2-com-iam/README.md)
