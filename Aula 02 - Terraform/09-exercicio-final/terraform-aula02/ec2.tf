# AMI mais recente do Amazon Linux 2023, buscada dinamicamente
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Papel IAM já existente na AWS Academy — reaproveitado, nunca criado
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# Key pair já existente na AWS Academy ("vockey") — o Learner Lab não
# permite criar um Key Pair novo por código (mesma restrição do IAM
# Role acima). Baixe o "vockey.pem" pela tela do Learner Lab (seção
# "SSH key" > Download PEM) e salve dentro desta pasta antes do apply.
# Fora da AWS Academy, o normal seria o próprio Terraform gerar/importar
# a chave (com os providers "tls" + "hashicorp/local").
data "aws_key_pair" "vockey" {
  key_name = "vockey"
}

# Instância EC2 — usa a subnet e o security group definidos nos
# outros arquivos deste mesmo projeto, e o instance profile e o key
# pair da AWS Academy referenciados acima
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
