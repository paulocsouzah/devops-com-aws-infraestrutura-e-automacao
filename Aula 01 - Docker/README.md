# 🐳 Aula de Docker

Material didático completo para uma aula introdutória de Docker, do
conceito até a construção de uma aplicação containerizada com Docker
Compose.

## 📚 Estrutura

| Pasta                                                              | Conteúdo                                                    |
|----------------------------------------------------------------------|---------------------------------------------------------------|
| [01-conceitos](01-conceitos/README.md)                               | Container, Imagem, Docker Engine, Docker Hub                  |
| [02-arquitetura-e-instalacao](02-arquitetura-e-instalacao/README.md) | Diagrama da arquitetura + instalação (Windows/Linux/Mac)      |
| [03-primeiros-comandos](03-primeiros-comandos/README.md)             | `docker version`, `info`, `images`, `ps`, `pull`, `run`, `stop`, `rm` |
| [04-exercicio-01-nginx](04-exercicio-01-nginx/README.md)             | Baixar e executar o nginx, acessar em `localhost:8080`        |
| [05-exercicio-02-dockerfile](05-exercicio-02-dockerfile/README.md)   | Criar uma imagem própria com `Dockerfile`                     |
| [06-exercicio-03-docker-compose](06-exercicio-03-docker-compose/README.md) | Orquestrar containers com `docker-compose.yml`           |
| [07-exercicio-04-node-mysql](07-exercicio-04-node-mysql/README.md)   | API Node.js + MySQL: multi-serviço, volumes, healthcheck        |
| [08-exercicio-final](08-exercicio-final/README.md)                   | Projeto integrador `docker-aula01` (web + api + db) — entrega em PDF |

## ▶️ Como usar

Siga as pastas na ordem numérica — cada uma tem um `README.md` com a
explicação, exercícios práticos e, quando aplicável, os arquivos
prontos (`Dockerfile`, `index.html`, `docker-compose.yml`) já
comentados para servir de referência ou gabarito.

**Pré-requisito:** Docker instalado e funcionando (veja o módulo
[02-arquitetura-e-instalacao](02-arquitetura-e-instalacao/README.md)
para o passo a passo de instalação em Windows, Linux e Mac).

## 🏁 Avaliação

O módulo [08-exercicio-final](08-exercicio-final/README.md) fecha a
aula com um projeto que junta tudo (web + api + db em um único
`docker-compose.yml`). Ao final dele, você deve me enviar um
**relatório em PDF** com prints, comandos executados e respostas às
perguntas de reflexão — é esse PDF que eu uso para avaliar e lançar a
nota. Os detalhes de entrega e a rubrica de avaliação estão no próprio
módulo.
