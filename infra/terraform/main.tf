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

  tags = {
    Proyecto    = "juice-shop"
    Responsable = "equipo-devsecops"
  }
}

data "aws_iam_policy_document" "confianza_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Rol para administrar el servidor con Session Manager en lugar de abrir SSH.
resource "aws_iam_role" "servidor" {
  name               = "juice-shop-servidor"
  assume_role_policy = data.aws_iam_policy_document.confianza_ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.servidor.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "servidor" {
  name = "juice-shop-servidor"
  role = aws_iam_role.servidor.name
}

resource "aws_instance" "servidor" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = false
  monitoring                  = true
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.servidor.name

  # IMDSv2 obligatorio, para que un SSRF no pueda leer las credenciales de la instancia.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "juice-shop"
    Proyecto    = "juice-shop"
    Responsable = "equipo-devsecops"
  }
}

resource "aws_ebs_volume" "datos" {
  # checkov:skip=CKV_AWS_189: se usa la llave administrada aws/ebs y no una CMK porque el volumen solo guarda los datos de la tienda de demostración y una CMK agrega costo y gestión de llaves. Aprobado por el responsable de seguridad del equipo en el PR #15, vence el 2027-03-31
  availability_zone = "us-east-1a"
  size              = 10
  encrypted         = true

  tags = {
    Proyecto    = "juice-shop"
    Responsable = "equipo-devsecops"
  }
}
