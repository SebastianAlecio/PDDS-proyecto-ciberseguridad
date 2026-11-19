# Caso que falla: el volumen no tiene las etiquetas obligatorias.
resource "aws_ebs_volume" "sin_etiquetas" {
  availability_zone = "us-east-1a"
  size              = 10
  encrypted         = true
}
