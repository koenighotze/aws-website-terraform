output "zone_id" {
  description = "The Route 53 hosted zone ID"
  value       = aws_route53_zone.blog.zone_id
}

output "zone_arn" {
  description = "The Route 53 hosted zone ARN"
  value       = aws_route53_zone.blog.arn
}

output "name_servers" {
  description = "The authoritative name servers for the hosted zone"
  value       = aws_route53_zone.blog.name_servers
}
