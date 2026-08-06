variable "region" {
  type        = string
  description = "AWS region used by the provider"
  default     = "eu-west-3"
}

variable "destination_url" {
  type        = string
  description = "The URL destination for the redirection. This should be an URL (e.g. https://mehdilaruelle.com)."
}

variable "redirect_status_code" {
  type        = number
  description = "HTTP status code returned by the redirection. 301 and 308 are permanent and cached by browsers for a very long time; 302 and 307 are temporary and safe to change your mind about."
  default     = 301

  validation {
    condition     = contains([301, 302, 307, 308], var.redirect_status_code)
    error_message = "The redirect_status_code value must be one of 301, 302, 307 or 308."
  }
}

variable "source_domain_names" {
  description = "The list of domain names source to rewrite as a destination_domain_name. This should be a domain name (e.g. blog.mehdilaruelle.ninja)."
  type        = list(string)
}
