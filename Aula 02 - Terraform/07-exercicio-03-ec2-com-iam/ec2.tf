# Este arquivo é feito para ser ADICIONADO dentro da mesma pasta do
# projeto "terraform-rede" (já contém a rede do módulo 05 e o Security
# Group do módulo 06).

# AMI mais recente do Amazon Linux 2023, direto da conta oficial da
# Amazon — em vez de "chumbar" um ID de imagem (que muda de tempos em
# tempos e varia por região), buscamos sempre a mais atual.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Papel IAM já existente na AWS Academy — NÃO criamos um IAM Role novo
# (a conta de aluno não tem permissão para isso). Apenas referenciamos
# o que já existe.
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# Key pair já existente na AWS Academy ("vockey") — assim como o
# LabInstanceProfile acima, o Learner Lab não permite criar um novo
# Key Pair por código (é uma restrição só desta plataforma de estudo;
# em uma conta AWS real, o normal é o próprio Terraform gerar/importar
# a chave, como mostrado no comentário no final deste arquivo).
# Baixe o arquivo "vockey.pem" pelo botão "Download PEM" na tela do
# Learner Lab (seção "SSH key") antes de rodar o apply.
data "aws_key_pair" "vockey" {
  key_name = "vockey"
}

# A instância EC2 em si — repare que ela só existe porque reaproveita
# tudo que já foi criado: a subnet (módulo 05), o security group
# (módulo 06), o instance profile e o key pair (data sources acima).
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = data.aws_key_pair.vockey.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  tags = {
    Name = "${var.project_name}-ec2-web"
  }
}

output "instance_public_ip" {
  description = "IP público da instância EC2 criada"
  value       = aws_instance.web.public_ip
}

output "ssh_command" {
  description = "Comando pronto para conectar via SSH (rode a partir da pasta onde salvou o vockey.pem)"
  value       = "ssh -i vockey.pem ec2-user@${aws_instance.web.public_ip}"
}

# ---------------------------------------------------------------------
# FORA DA AWS ACADEMY (fica só como referência, não use neste exercício):
# em uma conta AWS normal você teria permissão para criar o próprio
# key pair por código, com os providers "tls" + "hashicorp/local":
#
# resource "tls_private_key" "ec2_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }
#
# resource "aws_key_pair" "ec2_key" {
#   key_name   = "${var.project_name}-key"
#   public_key = tls_private_key.ec2_key.public_key_openssh
# }
#
# resource "local_sensitive_file" "private_key" {
#   content         = tls_private_key.ec2_key.private_key_pem
#   filename        = "${path.module}/${var.project_name}-key.pem"
#   file_permission = "0400"
# }
# ---------------------------------------------------------------------
