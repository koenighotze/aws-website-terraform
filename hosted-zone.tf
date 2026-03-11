import {
  to = aws_route53_zone.blog
  id = "Z34QRYXKXUA5NK"
}

resource "aws_route53_zone" "blog" {
  name    = var.domain_name
  comment = "HostedZone created by Route53 Registrar"
}
