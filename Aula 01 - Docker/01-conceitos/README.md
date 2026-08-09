# 1. Conceitos de Docker

Antes de colocar a mão no teclado, é fundamental entender o vocabulário
básico do Docker. Os quatro conceitos abaixo aparecem em praticamente
toda conversa sobre containers.

---

## 🧊 Container

> É um ambiente isolado.

Um **container** é um processo em execução que roda isolado do resto
do sistema operacional, mas compartilha o mesmo kernel da máquina
hospedeira (host). Pense nele como uma "caixa" que contém tudo o que
uma aplicação precisa para rodar: código, bibliotecas, dependências e
configurações.

Diferente de uma máquina virtual, o container **não** emula um
hardware inteiro nem carrega um sistema operacional completo — por
isso ele é muito mais leve e rápido de iniciar (segundos, às vezes
milissegundos).

Analogia: se a **imagem** é a planta de uma casa, o **container** é a
casa construída e habitada a partir dessa planta.

```
┌─────────────────────────────┐
│           HOST (SO)          │
│  ┌───────────┐ ┌───────────┐ │
│  │ Container │ │ Container │ │
│  │   App A   │ │   App B   │ │
│  └───────────┘ └───────────┘ │
│        (kernel compartilhado) │
└─────────────────────────────┘
```

---

## 📦 Imagem

> É um modelo pronto.

Uma **imagem** é um pacote somente-leitura que contém tudo o que é
necessário para criar um container: sistema de arquivos base, código
da aplicação, dependências, variáveis de ambiente e instruções de
execução.

Ela é construída em **camadas** (layers). Cada instrução em um
`Dockerfile` (que veremos mais adiante) gera uma nova camada, e o
Docker reaproveita camadas já existentes para economizar espaço e
tempo de build.

Uma mesma imagem pode gerar **vários containers** ao mesmo tempo, cada
um com seu próprio estado, isolado dos demais — assim como uma mesma
planta pode dar origem a várias casas idênticas.

---

## ⚙️ Docker Engine

> Motor que executa containers.

O **Docker Engine** é o software (cliente + daemon) instalado na
máquina que gerencia todo o ciclo de vida dos containers: criar,
executar, parar, remover, além de gerenciar imagens, redes e volumes.

Ele é composto basicamente por três partes:

- **Docker Daemon (`dockerd`)** — processo em segundo plano que faz o
  trabalho pesado (build de imagens, execução de containers, etc.).
- **Docker CLI (`docker`)** — a ferramenta de linha de comando que
  usamos para conversar com o daemon.
- **API REST** — interface usada pelo CLI (e outras ferramentas) para
  se comunicar com o daemon.

```
docker (CLI) ──── API REST ────> dockerd (daemon) ──> containers
```

---

## 🌐 Docker Hub

> Biblioteca de imagens.

O **Docker Hub** (hub.docker.com) é o repositório público oficial de
imagens Docker — algo como o "GitHub das imagens". Nele encontramos
imagens oficiais (nginx, mysql, node, python, ubuntu, redis, etc.) e
imagens publicadas pela comunidade.

Quando executamos `docker pull nginx`, o Docker Engine baixa a imagem
diretamente do Docker Hub (ou de um registro privado, se configurado)
para a máquina local.

---

## 📝 Resumo visual

| Conceito       | O que é                          | Analogia                     |
|----------------|-----------------------------------|-------------------------------|
| Imagem         | Modelo pronto (somente leitura)   | Planta de uma casa            |
| Container      | Ambiente isolado em execução      | Casa construída e habitada    |
| Docker Engine  | Motor que executa os containers   | Construtora que ergue a casa  |
| Docker Hub     | Biblioteca de imagens             | Catálogo de plantas prontas   |

---

## 🧪 Exercício

Antes de instalar qualquer coisa, quero que você fixe esses quatro
conceitos com a cabeça, não com o teclado. Responda por escrito (pode
ser em um bloco de notas, você vai reaproveitar isso mais adiante):

1. Com suas próprias palavras, explique a diferença entre **imagem**
   e **container**. Não copie a definição do material — se você
   conseguir explicar usando a analogia da planta/casa (ou outra
   analogia sua), já mostra que entendeu.
2. Acesse [hub.docker.com](https://hub.docker.com) e procure por
   **três imagens oficiais** diferentes (por exemplo `nginx`,
   `mysql`, `python`, `redis`, `node`...). Para cada uma, anote: para
   que ela serve e quantas milhões de downloads ela tem.
3. Se o Docker Engine "morresse" (o processo `dockerd` parasse de
   rodar), o que aconteceria se você tentasse rodar `docker ps` logo
   em seguida? Justifique sua resposta com base no papel do daemon.

**Próximo passo:** [02-arquitetura-e-instalacao](../02-arquitetura-e-instalacao/README.md)
