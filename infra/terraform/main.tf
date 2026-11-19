# Infraestructura de despliegue de Juice Shop en AWS.
# Solo se analiza como código, no se despliega nada.
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "web" {
  name        = "juice-shop-web"
  description = "Acceso al servidor de Juice Shop"

  ingress {
    description = "SSH solo desde la red de administracion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
  }

  ingress {
    description = "Aplicacion web solo desde el balanceador"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "HTTPS hacia afuera para paquetes e imagenes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
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
