# Caso que pasa: el volumen tiene las etiquetas Proyecto y Responsable.
resource "aws_ebs_volume" "con_etiquetas" {
  availability_zone = "us-east-1a"
  size              = 10
  encrypted         = true

  tags = {
    Proyecto    = "juice-shop"
    Responsable = "equipo-devsecops"
  }
}
