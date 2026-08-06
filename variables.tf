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

variable "throttling_rate_limit" {
  type        = number
  description = "Sustained requests per second allowed on the stage, across all methods. Set to -1 to fall back on the account-wide API Gateway quota."
  default     = 100
}

variable "throttling_burst_limit" {
  type        = number
  description = "Size of the token bucket, i.e. how large a spike the stage absorbs before throttling. Set to -1 to fall back on the account-wide API Gateway quota."
  default     = 200
}
