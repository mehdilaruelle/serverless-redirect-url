variable "api_name" {
  type        = string
  description = "Name of the Amazon API Gateway REST API. Worth changing when several instances of this project share an AWS account, since API Gateway allows duplicate names and the console then shows several identical entries."
  default     = "redirector"
}

variable "region" {
  type        = string
  description = "AWS region used by the provider"
  default     = "eu-west-3"
}

variable "destination_url" {
  type        = string
  description = "The URL destination for the redirection. This should be an URL (e.g. https://mehdilaruelle.com)."
}

variable "source_domain_names" {
  description = "The list of domain names source to rewrite as a destination_domain_name. This should be a domain name (e.g. blog.mehdilaruelle.ninja)."
  type        = list(string)
}
