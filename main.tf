data "aws_acm_certificate" "source" {
  count = length(var.source_domain_names)

  domain      = var.source_domain_names[count.index]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_api_gateway_rest_api" "shortener" {
  name        = var.api_name
  description = "Redirector URL serverless"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# GET /
resource "aws_api_gateway_method" "url_redirect" {
  rest_api_id   = aws_api_gateway_rest_api.shortener.id
  resource_id   = aws_api_gateway_rest_api.shortener.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "url_redirect" {
  rest_api_id = aws_api_gateway_rest_api.shortener.id
  resource_id = aws_api_gateway_rest_api.shortener.root_resource_id
  http_method = aws_api_gateway_method.url_redirect.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" : "{ \"statusCode\": 301 }"
  }
}

resource "aws_api_gateway_integration_response" "url_redirect" {
  rest_api_id = aws_api_gateway_rest_api.shortener.id
  resource_id = aws_api_gateway_rest_api.shortener.root_resource_id
  http_method = aws_api_gateway_method.url_redirect.http_method
  status_code = aws_api_gateway_method_response.url_redirect_response.status_code

  response_parameters = {
    "method.response.header.Location" : "'${var.destination_url}'"
  }
}

resource "aws_api_gateway_method_response" "url_redirect_response" {
  rest_api_id = aws_api_gateway_rest_api.shortener.id
  resource_id = aws_api_gateway_rest_api.shortener.root_resource_id
  http_method = aws_api_gateway_method.url_redirect.http_method
  status_code = "301"

  response_parameters = {
    "method.response.header.Location" : true
  }
}

# GET /*
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.shortener.id
  parent_id   = aws_api_gateway_rest_api.shortener.root_resource_id
  path_part   = "{proxy+}"
}
# configure the method you need
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.shortener.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}
# integrate your lambda to this resource
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.shortener.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" : "{ \"statusCode\": 301 }"
  }
}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.shortener.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  response_parameters = {
    "method.response.header.Location" : "'${var.destination_url}'"
  }

  response_templates = {
    "application/json" = <<EOF
#set($Path = $input.params().get('path').get('proxy') )
#set($context.responseOverride.header.Location = "${var.destination_url}/$Path")
EOF
  }
}

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.shortener.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "301"

  response_parameters = {
    "method.response.header.Location" : true
  }
}

# DEPLOY
resource "aws_api_gateway_deployment" "prod" {
  description = "Production deployment"
  rest_api_id = aws_api_gateway_rest_api.shortener.id

  # Redeploy the API whenever the routing configuration changes. Without this,
  # API Gateway keeps serving the snapshot taken on the first apply.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.url_redirect.id,
      aws_api_gateway_integration.url_redirect.id,
      aws_api_gateway_integration_response.url_redirect.id,
      aws_api_gateway_method_response.url_redirect_response.id,
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_integration_response.proxy.id,
      aws_api_gateway_method_response.proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# The stage used to be created implicitly by the deployment, but `stage_name`
# was removed from `aws_api_gateway_deployment` in AWS provider v6.
resource "aws_api_gateway_stage" "prod" {
  description   = "Production stage"
  rest_api_id   = aws_api_gateway_rest_api.shortener.id
  deployment_id = aws_api_gateway_deployment.prod.id
  stage_name    = "prod"
}

resource "aws_api_gateway_domain_name" "custom" {
  count = length(var.source_domain_names)

  regional_certificate_arn = data.aws_acm_certificate.source[count.index].arn
  domain_name              = data.aws_acm_certificate.source[count.index].domain

  security_policy = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "custom" {
  count = length(var.source_domain_names)

  api_id      = aws_api_gateway_rest_api.shortener.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.custom[count.index].domain_name
}

# Renamed from "test". Without this block Terraform would destroy and
# recreate the mapping, taking the redirect offline for the duration.
moved {
  from = aws_api_gateway_base_path_mapping.test
  to   = aws_api_gateway_base_path_mapping.custom
}
