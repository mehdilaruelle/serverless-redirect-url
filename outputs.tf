output "domain_name" {
  description = "This domain name should be add as a CNAME on your DNS zone."
  value       = { for index, domain_name in aws_api_gateway_domain_name.custom : domain_name.id => domain_name.regional_domain_name }
}
