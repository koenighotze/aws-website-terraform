# ── Apex CAA record (allow Let's Encrypt only) ─
import {
  to = aws_route53_record.root_caa
  id = "Z34QRYXKXUA5NK_koenighotze.de_CAA"
}

resource "aws_route53_record" "root_caa" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = var.domain_name
  type    = "CAA"
  ttl     = 300

  records = [
    "0 issue \"letsencrypt.org\"",
  ]
}
