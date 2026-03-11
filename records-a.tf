# ── Apex A record (GitHub Pages IPs) ─────────
import {
  to = aws_route53_record.root_a
  id = "Z34QRYXKXUA5NK_koenighotze.de_A"
}

resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300

  records = [
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153",
  ]
}

# ── www A record (alias to apex) ─────────────
import {
  to = aws_route53_record.www_a
  id = "Z34QRYXKXUA5NK_www.koenighotze.de_A"
}

resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.domain_name
    zone_id                = aws_route53_zone.blog.zone_id
    evaluate_target_health = true
  }
}
