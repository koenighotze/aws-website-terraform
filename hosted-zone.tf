import {
  to = aws_route53_zone.blog
  id = "Z34QRYXKXUA5NK"
}

#checkov:skip=CKV2_AWS_38:DNSSEC requires registrar-side DS record setup and KMS key; disproportionate for a personal blog
#checkov:skip=CKV2_AWS_39:Query logging adds CloudWatch cost with no operational benefit for a personal blog
resource "aws_route53_zone" "blog" {
  name    = var.domain_name
  comment = "HostedZone created by Route53 Registrar"
}
