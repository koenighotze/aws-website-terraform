# ── Apex TXT record (Keybase verification) ───
import {
  to = aws_route53_record.root_txt
  id = "Z34QRYXKXUA5NK_koenighotze.de_TXT"
}

resource "aws_route53_record" "root_txt" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300

  records = [
    "keybase-site-verification=rsMp7LHFb9Z_AOET2GYCg6lrKbTchBzcOyLTT1AbGC0",
  ]
}
