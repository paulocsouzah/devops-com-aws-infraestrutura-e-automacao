# Este arquivo é feito para ser ADICIONADO dentro da mesma pasta do
# projeto "terraform-rede" (criado no módulo 06) — o Terraform lê e
# combina automaticamente TODOS os arquivos .tf de uma mesma pasta.
# Ele referencia aws_vpc.main, que já existe em main.tf.

# Security Group — o "firewall" que decide o que pode entrar e sair
# das instâncias que o usarem. Regras aqui são *stateful*: se o
# tráfego de entrada é permitido, a resposta de saída correspondente
# é automaticamente permitida (não precisa de uma regra de egress
# espelhada para cada ingress).
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg-web"
  description = "Libera SSH (restrito ao meu IP) e HTTP/HTTPS (publico)"
  vpc_id      = aws_vpc.main.id

  # SSH — restrito ao IP de quem está aplicando o Terraform.
  # Nunca libere a porta 22 para 0.0.0.0/0 (qualquer IP da internet);
  # isso é uma das causas mais comuns de instância comprometida.
  ingress {
    description = "SSH apenas do meu IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  # HTTP — público, para acessar a aplicação web pelo navegador.
  ingress {
    description = "HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS — público (mesmo sem certificado configurado ainda, já
  # deixamos a porta pronta).
  ingress {
    description = "HTTPS publico"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress — libera toda saída (padrão comum para instâncias que
  # precisam baixar pacotes, atualizar o sistema, chamar APIs, etc.).
  egress {
    description = "Todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-web"
  }
}
