# 6. Organização, Dependências e Boas Práticas

Com tudo funcionando, vale parar e entender **por que** algumas decisões
de design foram tomadas do jeito que foram — e o que fazer quando algo
sai errado. Este módulo não tem exercício de infraestrutura novo; é
consolidação e troubleshooting.

---

## 🔗 Dependências implícitas vs. explícitas

O Terraform normalmente **paraleliza** a criação de recursos que não
dependem uns dos outros, para ser mais rápido. Ele só cria um recurso
depois de outro quando existe uma dependência:

- **Implícita** — quando um recurso **referencia um atributo** de outro
  (foi o nosso caso no módulo 05: `aws_db_instance.main.address` dentro
  do `templatefile()` da EC2). O Terraform detecta isso sozinho, sem
  você escrever nada a mais.
- **Explícita** — quando não existe referência de atributo, mas ainda
  assim um recurso precisa esperar o outro, você usa `depends_on`:

  ```hcl
  resource "aws_instance" "app" {
    # ...
    depends_on = [aws_db_instance.main]
  }
  ```

Neste projeto, a dependência implícita já é suficiente (o `user_data`
referencia o RDS). Mas é importante saber que `depends_on` existe para os
casos em que a relação não aparece naturalmente no código — por exemplo,
se a ordem importasse por causa de uma permissão IAM que não gera
nenhuma referência direta entre os recursos.

---

## ⏱️ RDS é lento, EC2 é rápido — e por que isso quase nunca é problema

O RDS leva minutos para ficar `available`; a EC2 termina o boot em
segundos. Como a EC2 **depende** do RDS (módulo 05), o Terraform só
inicia a criação da instância **depois** que o banco estiver pronto — ou
seja, na prática, quando o `user_data` roda, o RDS **já existe e já
aceita conexões**. A dependência do Terraform já resolve a corrida entre
os dois tempos de provisionamento.

Ainda assim, em ambientes reais, conexões com banco podem falhar por
outros motivos temporários — uma janela de manutenção do RDS, uma
instabilidade de rede, um restart do banco. Por isso é uma **boa prática
de mercado** que a própria aplicação tente reconectar, em vez de travar
na primeira falha:

```js
async function conectarComRetry(config, tentativas = 5, esperaMs = 3000) {
  for (let i = 1; i <= tentativas; i++) {
    try {
      return await mysql.createConnection(config);
    } catch (erro) {
      console.error(`Tentativa ${i}/${tentativas} falhou: ${erro.message}`);
      if (i === tentativas) throw erro;
      await new Promise((r) => setTimeout(r, esperaMs));
    }
  }
}
```

Isso é o que chamamos de aplicação **resiliente**: ela não assume que as
dependências externas (banco, outras APIs) estarão sempre disponíveis no
primeiro milissegundo em que ela tenta usá-las.

---

## 🙅 Por que não usamos `provisioner "remote-exec"`

O Terraform também oferece `provisioner "remote-exec"`, que conecta via
SSH numa instância recém-criada e roda comandos — pareceria uma
alternativa óbvia ao User Data. **Não é a recomendada**, e a própria
documentação oficial do Terraform chama provisioners de "last resort"
(último recurso). Motivos:

| `user_data` (o que usamos) | `provisioner "remote-exec"` |
|---|---|
| Nativo da AWS — funciona mesmo se o Terraform perder conexão logo após o `apply` | Depende da máquina que roda o `terraform apply` conseguir SSH na instância, naquele momento exato |
| Reexecuta automaticamente se a instância for recriada | Só roda durante a criação do recurso, via Terraform |
| Fica registrado como parte da definição da instância na AWS (auditável) | É um efeito colateral do `apply`, mais difícil de rastrear |
| Não deixa a chave SSH como dependência crítica do provisionamento | Exige que a chave/conectividade SSH estejam corretas no momento do `apply` |

Regra prática: **sempre que existir um mecanismo nativo do provedor de
nuvem** (como User Data na AWS), prefira-o a um `provisioner` do
Terraform.

---

## 🐛 Troubleshooting comum de User Data / Cloud-Init

Erros que costumam acontecer (e onde olhar):

1. **Script não executa nada** → confira se a primeira linha é
   exatamente `#!/bin/bash` (sem espaços antes, sem BOM). Sem o
   shebang correto, o Cloud-Init pode não interpretar o conteúdo como
   script executável.
2. **"comando não encontrado" em todo lugar** → você provavelmente
   editou o arquivo no Windows e ele foi salvo com **quebras de linha
   CRLF** em vez de LF. Isso quebra scripts bash de forma sutil. Se você
   editar `.sh`/`.tpl` no Windows, confira a configuração "line ending"
   do seu editor (VS Code: canto inferior direito, deve estar como
   `LF`).
3. **`dnf: command not found`** → confirme que está usando **Amazon
   Linux 2023** (usa `dnf`), não Amazon Linux 2 (`yum`) nem Ubuntu
   (`apt`) — a AMI errada quebra o script inteiro logo na primeira
   linha.
4. **O script "não rodou de novo" depois que editei e apliquei** → como
   vimos no módulo 02, o User Data só executa **na primeira
   inicialização**. Editar o script e rodar `apply` força o Terraform a
   **recriar** a instância (por causa do `-/+` no plan) — se isso não
   estiver acontecendo, confira se alguma outra parte do seu código não
   está "escondendo" a mudança.
5. **Container não conecta no RDS, mas o `.env` parece certo** → confira
   o Security Group do RDS (módulo 04): a origem permitida é
   exatamente o Security Group da EC2? Teste também, de dentro da EC2:
   `nc -zv <endpoint-rds> 3306` para confirmar conectividade de rede
   antes de suspeitar da aplicação.

---

## 🔐 Sobre a senha do banco nesta aula

Guardamos a senha do RDS em `terraform.tfvars` (não commitado) e a
passamos para dentro do `.env` da EC2 via `templatefile()` — é uma
simplificação aceitável para fins didáticos, mas vale registrar o que
mudaria num ambiente de produção real:

- A senha poderia ser **gerada automaticamente** pelo Terraform
  (`resource "random_password"`), em vez de digitada por uma pessoa.
- Em vez de ir parar num arquivo `.env` em texto puro dentro da
  instância, o ideal seria a aplicação buscar a senha em tempo de
  execução no **AWS Secrets Manager** ou **Systems Manager Parameter
  Store**, autenticando via IAM Role — sem a senha nunca "tocar" o
  disco da instância ou o state do Terraform em texto puro.

Isso fica registrado como próximo passo de maturidade, não como algo
que vamos implementar nesta aula.

---

## 📝 Resumo visual

| Prática | Por quê |
|---|---|
| Dependência implícita (referenciar atributos) em vez de `depends_on` sempre que possível | Menos código, mesma garantia, mais legível |
| Aplicação com retry de conexão ao banco | Resiliência a falhas temporárias, não só à ordem de criação |
| `user_data` em vez de `provisioner remote-exec` | Nativo da nuvem, não depende do `apply` manter conectividade SSH |
| Editor configurado para LF, não CRLF, em scripts `.sh`/`.tpl` | Evita erros silenciosos e difíceis de diagnosticar |
| Senha fora do código-fonte, fora do `.tf` versionado | Reduz superfície de vazamento de credenciais |

---

## 🧪 Exercício

1. No seu projeto, adicione (ou ao menos esboce) a lógica de retry de
   conexão na API, como no exemplo acima. Teste **derrubando** o RDS
   momentaneamente (ex: reboot pelo Console) e observando os logs da API
   tentando reconectar, em vez de simplesmente cair.
2. Explique, com suas palavras, por que um `provisioner remote-exec`
   seria mais frágil que o `user_data` neste projeto específico (pense
   no que aconteceria se a sua internet caísse bem no meio do
   `terraform apply`, em cada uma das duas abordagens).
3. Verifique no seu editor se os arquivos `.sh`/`.tpl` que você criou
   estão salvos com quebras de linha **LF**. Se algum estiver em CRLF,
   corrija e reaplique.
4. **Discussão:** dado o que você aprendeu sobre Secrets Manager nesta
   seção, em que módulo da grade do curso (olhe a ementa completa no
   README raiz do repositório) você imagina que esse tipo de solução
   mais madura de segredos se encaixaria melhor? Justifique.

**Próximo passo:** [07-exercicio-final](../07-exercicio-final/README.md)
