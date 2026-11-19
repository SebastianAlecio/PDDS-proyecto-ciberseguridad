# Infraestructura de despliegue de Juice Shop en AWS.
# Solo se analiza como código, no se despliega nada.
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "web" {
  name        = "juice-shop-web"
  description = "Acceso al servidor de Juice Shop"

  ingress {
    description = "SSH desde cualquier lugar"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Aplicacion web"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "servidor" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    encrypted   = false
  }

  tags = {
    Name = "juice-shop"
  }
}

resource "aws_ebs_volume" "datos" {
  availability_zone = "us-east-1a"
  size              = 10
  encrypted         = false
}
