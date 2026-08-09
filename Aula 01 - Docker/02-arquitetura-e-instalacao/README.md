# 2. Arquitetura e Instalação

## 🏗️ Arquitetura

O fluxo básico do Docker segue sempre a mesma lógica: partimos de uma
imagem publicada, baixamos ela para a máquina local e a usamos como
base para rodar um container, que por sua vez executa nossa
aplicação.

```
┌───────────────┐
│   Docker Hub   │   (repositório remoto de imagens)
└───────┬───────┘
        │  docker pull
        ▼
┌───────────────┐
│    Imagem      │   (modelo pronto, somente leitura, em camadas)
└───────┬───────┘
        │  docker run
        ▼
┌───────────────┐
│   Container    │   (instância em execução, isolada)
└───────┬───────┘
        │  expõe porta / executa processo
        ▼
┌───────────────┐
│   Aplicação    │   (o que o usuário final acessa, ex: site, API)
└───────────────┘
```

### Explicando cada seta

1. **Docker Hub → Imagem**: usamos `docker pull <nome-da-imagem>`
   para baixar uma imagem do Docker Hub (ou outro registro) para a
   máquina local.
2. **Imagem → Container**: usamos `docker run <nome-da-imagem>` para
   criar e iniciar um container a partir da imagem baixada.
3. **Container → Aplicação**: dentro do container, o processo
   definido pela imagem é executado (ex: o `nginx` sobe um servidor
   web) e, se mapeamos uma porta, conseguimos acessar essa aplicação
   pelo navegador ou por outra ferramenta.

### Arquitetura cliente-servidor do Docker

Vale reforçar como as peças conversam entre si por trás dos panos:

```
┌────────────┐      comandos       ┌───────────────┐
│ Docker CLI │ ──────────────────> │  Docker Daemon │
│ (docker)   │ <────────────────── │   (dockerd)    │
└────────────┘      respostas      └───────┬────────┘
                                            │ gerencia
                     ┌──────────────────────┼──────────────────────┐
                     ▼                      ▼                      ▼
               ┌───────────┐         ┌────────────┐         ┌────────────┐
               │  Imagens   │         │ Containers │         │   Redes /   │
               │  locais    │         │            │         │  Volumes    │
               └───────────┘         └────────────┘         └────────────┘
```

---

## 💻 Instalação

O Docker se instala de forma diferente dependendo do sistema
operacional. Abaixo estão as opções recomendadas para cada um.

### 🪟 Windows — Docker Desktop

1. Acesse https://www.docker.com/products/docker-desktop/
2. Baixe o instalador do **Docker Desktop para Windows**.
3. Pré-requisito recomendado: **WSL2** (Windows Subsystem for Linux 2)
   habilitado — o instalador guia você por esse processo se ainda não
   estiver ativo.
4. Após instalar, abra o Docker Desktop e aguarde o ícone da baleia
   ficar "estável" na bandeja do sistema (indica que o daemon subiu).
5. Teste no terminal (PowerShell ou WSL):

   ```bash
   docker version
   ```

### 🐧 Linux — Docker Engine

No Linux instalamos o **Docker Engine** diretamente (sem a camada de
"Desktop"). Exemplo para distribuições baseadas em Debian/Ubuntu:

```bash
# 1. Atualizar pacotes
sudo apt-get update

# 2. Instalar dependências
sudo apt-get install -y ca-certificates curl gnupg

# 3. Adicionar a chave GPG oficial do Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Adicionar o repositório do Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Instalar o Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 6. (Opcional, mas recomendado) rodar docker sem sudo
sudo usermod -aG docker $USER
# depois disso, faça logout/login para o grupo ter efeito
```

Teste:

```bash
docker version
```

### 🍎 Mac — Docker Desktop

1. Acesse https://www.docker.com/products/docker-desktop/
2. Baixe o instalador de acordo com o processador (Apple Silicon /
   Intel).
3. Arraste o app para a pasta **Applications** e abra o Docker
   Desktop.
4. Aguarde o ícone da baleia na barra de menu indicar que o Docker
   está rodando.
5. Teste no terminal:

   ```bash
   docker version
   ```

---

## ✅ Checklist de instalação

Depois de instalar, você deve conseguir rodar os três comandos abaixo
sem nenhum erro:

```bash
docker version   # mostra versão do client e do daemon
docker info      # mostra informações detalhadas do ambiente Docker
docker run hello-world   # roda um container de teste oficial
```

Se `docker run hello-world` imprimir uma mensagem de boas-vindas,
a instalação está correta! 🎉

---

## 🧪 Exercício

1. Instale o Docker na sua máquina seguindo o guia do seu sistema
   operacional acima.
2. Rode os três comandos do checklist e **guarde o print** (ou o
   texto) da saída de cada um — você vai precisar disso mais adiante,
   no exercício final.
3. Rode `docker info` novamente e responda, com suas próprias
   palavras: quantos containers e quantas imagens aparecem no
   ambiente logo após uma instalação nova? Isso confirma que você
   entendeu o que essas duas contagens representam.
4. **Desafio:** rode `docker run hello-world` uma segunda vez. Repare
   que dessa vez ele **não baixa a imagem de novo** — explique, em uma
   frase, por que isso acontece (dica: revise o conceito de imagem no
   módulo anterior).

**Próximo passo:** [03-primeiros-comandos](../03-primeiros-comandos/README.md)
