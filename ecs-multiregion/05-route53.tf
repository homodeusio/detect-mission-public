locals {
  subdomain     = "ecs.example.com"
  primary_dns   = module.ecs_alb_us.alb_dns
  secondary_dns = module.ecs_alb_eu.alb_dns
}

resource "aws_route53_zone" "main" {
  name = "example.com"
  comment = "Managed by terraform"
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.id
  name    = local.subdomain
  type    = "CNAME"
  ttl     = 10

  latency_routing_policy {
    region = "us-east-2"
  }

  set_identifier  = "us"
  records         = [local.primary_dns]
  health_check_id = aws_route53_health_check.primary.id
}


resource "aws_route53_health_check" "primary" {
  fqdn              = local.primary_dns
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "1"
  request_interval  = "10"
}

resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = local.subdomain
  type    = "CNAME"
  ttl     = 10

  latency_routing_policy {
    region = "eu-west-2"
  }

  set_identifier = "eu"
  records        = [local.secondary_dns]
  health_check_id = aws_route53_health_check.secondary.id
}


resource "aws_route53_health_check" "secondary" {
  fqdn              = local.secondary_dns
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "1"
  request_interval  = "10"
}
