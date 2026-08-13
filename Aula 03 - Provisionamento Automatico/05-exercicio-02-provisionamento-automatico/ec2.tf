# AMI mais recente do Amazon Linux 2023, buscada dinamicamente
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Papel IAM ja existente na AWS Academy — reaproveitado, nunca criado
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# Key pair ja existente na AWS Academy ("vockey")
data "aws_key_pair" "vockey" {
  key_name = "vockey"
}

# Instancia EC2 — agora com user_data via templatefile(), que injeta o
# endpoint real do RDS e a URL do repositorio da aplicacao no script
# antes de entrega-lo a instancia.
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = data.aws_key_pair.vockey.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  # Como este bloco referencia aws_db_instance.main, o Terraform cria uma
  # dependencia implicita: a EC2 so e criada depois do RDS estar pronto.
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    db_host     = aws_db_instance.main.address
    db_port     = aws_db_instance.main.port
    db_name     = var.db_name
    db_user     = var.db_username
    db_password = var.db_password
    repo_url    = var.app_repo_url
  })

  tags = {
    Name = "${var.project_name}-ec2-web"
  }
}
