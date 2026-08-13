# 1. Conceitos de Provisionamento Automático

Na Aula 02, o `terraform apply` deixava a EC2 **de pé, mas vazia** — um
Amazon Linux "limpo", e éramos nós que entrávamos via SSH para instalar
qualquer coisa manualmente. Nesta aula, isso muda: a máquina nasce **já
configurada e com a aplicação rodando**, sem nenhum comando manual pós
`apply`.

É isto que vamos construir, passo a passo, ao longo dos sete módulos
desta aula:

![Arquitetura da aplicação — Aula 03: EC2 com Nginx e containers frontend/api, provisionada via User Data, conectada a um RDS MySQL numa subnet privada](arquitetura.png)

> 💡 Faltam dois detalhes de rede nesta imagem, que existem no projeto
> mas não estão desenhados: o **Internet Gateway**/**Route Table** (dão
> acesso à internet à subnet pública) e os **Security Groups** (`sg-web`
> e `sg-rds`, que controlam quem pode falar com quem). Eles aparecem no
> diagrama técnico completo do [módulo 07](../07-exercicio-final/README.md).

---

## 🐣 O problema do "servidor de estimação"

> Se você trata um servidor como um bichinho de estimação (dá nome,
> cuida dele, tem medo de perder), você está fazendo operação manual. Se
> você trata como gado (numerado, substituível, recriável a qualquer
> momento), você está fazendo infraestrutura moderna.

Essa é a diferença entre **pets vs. cattle**, uma expressão clássica de
DevOps. Um servidor configurado manualmente via SSH é um "pet": se ele
morre, ninguém sabe reproduzir exatamente o que foi feito nele — que
pacotes foram instalados, em que ordem, com quais ajustes. Um servidor
provisionado automaticamente é "cattle": se ele morre, você recria um
idêntico em minutos, porque **toda a configuração está em código**,
versionada junto com o resto da infraestrutura.

| Configuração manual (SSH) | Provisionamento automático (User Data) |
|---|---|
| Você conecta via SSH e digita comandos, um por um | Um script roda sozinho assim que a máquina liga |
| Ninguém sabe reproduzir exatamente o que foi feito | O script é código, versionado no Git |
| Recriar o servidor = repetir tudo manualmente, de novo | Recriar o servidor = `terraform apply` de novo |
| Fácil esquecer um passo ou fazer diferente da vez anterior | O mesmo script sempre produz o mesmo resultado |
| Não escala (não dá pra fazer isso em 50 servidores) | Escala para qualquer quantidade de servidores |

---

## 📜 O que é User Data

**User Data** é um campo que a AWS oferece para **toda instância EC2**:
um bloco de texto (geralmente um script) que você entrega no momento da
criação da máquina, e que é executado automaticamente **uma vez, na
primeira inicialização**, antes mesmo de você conseguir logar nela.

No Terraform, isso é só mais um argumento do `aws_instance`:

```hcl
resource "aws_instance" "app" {
  # ...
  user_data = file("${path.module}/user_data.sh")
}
```

O que você põe ali dentro é, na prática, um **script de shell comum**:

```bash
#!/bin/bash
dnf update -y
dnf install -y docker git
systemctl enable --now docker
```

Assim que a EC2 termina de "ligar" (boot do sistema operacional), a AWS
entrega esse script para um agente interno que o executa como `root` —
sem você precisar estar conectado, sem SSH, sem clique nenhum.

---

## ☁️ O que é Cloud-Init

O agente que efetivamente executa o User Data dentro da instância se
chama **Cloud-Init** — um software que já vem pré-instalado na maioria
das imagens (AMIs) modernas, incluindo o Amazon Linux 2023 que usamos
desde a Aula 02.

O Cloud-Init é mais poderoso que "só rodar um script bash": ele também
aceita um formato próprio, o `#cloud-config` (YAML), para tarefas comuns
(criar usuários, escrever arquivos, instalar pacotes) de forma
declarativa, sem precisar escrever comandos shell explícitos.

Nesta aula vamos usar a forma **mais simples e direta**: um script
`#!/bin/bash` puro. É o suficiente para tudo que precisamos, e é a forma
mais fácil de ler, testar e depurar quando você está começando. Fica
registrado aqui que o formato `#cloud-config` existe e é o "modo mais
completo" do Cloud-Init — vale explorar depois que o script bash estiver
dominado.

> 💡 **Por trás dos panos:** mesmo quando você usa um script bash puro no
> User Data, é o Cloud-Init quem recebe esse conteúdo, salva em
> `/var/lib/cloud/instance/`, executa e registra os logs. Ou seja: você
> **já está usando Cloud-Init**, só que na sua forma mais simples.

---

## 🗄️ Por que um banco de dados gerenciado (RDS) agora

Na Aula 01, o banco de dados era **um container MySQL**, junto com a
aplicação, no mesmo `docker-compose.yml`. Isso é ótimo para aprender e
para ambientes de desenvolvimento — mas tem problemas sérios em produção:

- Se o container do banco cai (ou a EC2 inteira é destruída/recriada),
  **os dados vão junto**, a menos que o volume esteja em outro lugar.
- Backups, atualizações de versão do MySQL, réplicas de leitura,
  monitoramento de performance do banco — tudo isso vira responsabilidade
  sua, dentro de um container.
- O ciclo de vida do banco fica **preso** ao ciclo de vida do servidor da
  aplicação: você não pode atualizar/reiniciar um sem afetar o outro.

O **Amazon RDS** (Relational Database Service) é um banco de dados
**gerenciado**: a AWS cuida da instalação, dos backups automáticos, dos
patches de segurança e da infraestrutura por trás — você só se conecta
nele, como se fosse "só mais um endereço de rede".

```
Aula 01 (container)                    Aula 03 (RDS)
┌─────────────────────┐                ┌─────────────────────┐
│ EC2 / sua máquina    │                │ EC2                  │
│  ┌─────┐  ┌────────┐ │                │  ┌─────┐              │
│  │ api │──│ db      │ │                │  │ api │──────────┐   │
│  └─────┘  │(container)│ │                │  └─────┘          │   │
│           └────────┘ │                └───────────────────┼───┘
│  banco some se o      │                                     │
│  container/EC2 morrer │                        ┌────────────▼──┐
└─────────────────────┘                         │  RDS MySQL      │
                                                  │  (gerenciado,   │
                                                  │  sobrevive à    │
                                                  │  EC2)           │
                                                  └────────────────┘
```

A ideia central que fica desta aula: **dado importante não mora dentro
do mesmo servidor descartável que roda a aplicação.** Esse é um dos
princípios mais repetidos em ambientes de produção reais.

---

## ✅ Boas práticas

1. **User Data é para provisionar, não para guardar segredos em texto
   puro** — nesta aula vamos aceitar isso como simplificação didática
   (senha do banco via variável), mas em produção real o ideal é buscar
   segredos de um cofre (AWS Secrets Manager, Parameter Store) dentro do
   próprio script, não embutir no código.
2. **O script de User Data deve ser idempotente sempre que possível** —
   ou seja, se ele rodasse duas vezes, não deveria quebrar nada. Isso
   importa porque, em alguns cenários (reboot, recriação), o Cloud-Init
   pode reexecutar partes do processo.
3. **Dados que precisam sobreviver ao servidor não ficam no servidor** —
   é exatamente o motivo de usarmos RDS em vez de um container de banco
   nesta aula.
4. **Sempre valide o resultado do User Data pelos logs**, não só "parece
   que funcionou" — vamos ver onde encontrar esses logs no próximo
   módulo.

---

## 📝 Resumo visual

| Conceito | O que é | Onde aparece nesta aula |
|---|---|---|
| User Data | Script entregue à EC2 na criação, executado uma vez no boot | Argumento `user_data` do `aws_instance` |
| Cloud-Init | Agente dentro da instância que executa o User Data | Já vem instalado no Amazon Linux 2023 |
| Pets vs. Cattle | Servidor configurado à mão vs. servidor recriável por código | Motivação de toda a aula |
| RDS | Banco de dados gerenciado pela AWS, fora do ciclo de vida da EC2 | `aws_db_instance` (módulo 04) |

---

## 🧪 Exercício

Responda por escrito (vai reaproveitar isso no relatório final):

1. Com suas próprias palavras, explique a diferença entre um servidor
   "pet" e um servidor "cattle". Em qual das duas categorias a EC2 da
   Aula 02 se encaixava, e em qual vai se encaixar a partir desta aula?
2. O que é o User Data e **quando** exatamente ele é executado no ciclo
   de vida de uma instância EC2?
3. Qual é a relação entre User Data e Cloud-Init? Um substitui o outro,
   ou um usa o outro?
4. Por que faz sentido que o banco de dados **não** more dentro da mesma
   EC2 descartável que roda a aplicação? Dê um cenário concreto em que
   isso faria diferença (ex: o que acontece com os dados se a EC2 for
   destruída por engano).

**Próximo passo:** [02-user-data-na-pratica](../02-user-data-na-pratica/README.md)
