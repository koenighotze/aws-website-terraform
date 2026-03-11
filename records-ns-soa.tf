# ── Apex NS record ────────────────────────────
import {
  to = aws_route53_record.ns
  id = "Z34QRYXKXUA5NK_koenighotze.de_NS"
}

resource "aws_route53_record" "ns" {
  zone_id         = aws_route53_zone.blog.zone_id
  name            = var.domain_name
  type            = "NS"
  ttl             = 172800
  allow_overwrite = true

  records = [
    "ns-267.awsdns-33.com.",
    "ns-1498.awsdns-59.org.",
    "ns-910.awsdns-49.net.",
    "ns-1580.awsdns-05.co.uk.",
  ]
}

# ── Apex SOA record ───────────────────────────
import {
  to = aws_route53_record.soa
  id = "Z34QRYXKXUA5NK_koenighotze.de_SOA"
}

resource "aws_route53_record" "soa" {
  zone_id         = aws_route53_zone.blog.zone_id
  name            = var.domain_name
  type            = "SOA"
  ttl             = 900
  allow_overwrite = true

  records = [
    "ns-267.awsdns-33.com. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

# ── blog subdomain NS delegation ──────────────
import {
  to = aws_route53_record.blog_ns
  id = "Z34QRYXKXUA5NK_blog.koenighotze.de_NS"
}

resource "aws_route53_record" "blog_ns" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = "blog.${var.domain_name}"
  type    = "NS"
  ttl     = 300

  records = [
    "dns1.p02.nsone.net",
    "dns2.p02.nsone.net",
    "dns3.p02.nsone.net",
    "dns4.p02.nsone.net",
  ]
}
