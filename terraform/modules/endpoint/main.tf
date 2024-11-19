locals {
  default_cors_resp_header_params = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
  }

  default_cors_resp_headers = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_resource" "resource" {
  count       = var.resource_name != "/" ? 1 : 0
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_resource_id
  path_part   = var.resource_name
}

output "resource" {
  value = var.resource_name != "/" ? aws_api_gateway_resource.resource[0] : null
}

resource "aws_api_gateway_method" "method" {
  count         = var.http_method != "NONE" ? 1 : 0
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_name != "/" ? aws_api_gateway_resource.resource[0].id : var.parent_resource_id
  http_method   = var.http_method
  authorization = var.auth_id != "" ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.auth_id != "" ? var.auth_id : null
  request_parameters = var.is_proxy ? null : var.request_parameters
}

resource "aws_api_gateway_integration" "request" {
  count                   = var.http_method != "NONE" ? 1 : 0
  depends_on              = [aws_api_gateway_resource.resource[0], aws_api_gateway_method.method[0]]
  rest_api_id             = var.rest_api_id
  resource_id             = var.resource_name != "/" ? aws_api_gateway_resource.resource[0].id : var.parent_resource_id
  http_method             = aws_api_gateway_method.method[0].http_method
  integration_http_method = var.lambda_arn != "MOCK" ? "POST" : null
  type                    = var.lambda_arn != "MOCK" ? var.is_proxy ? "AWS_PROXY" : "AWS" : "MOCK"
  uri                     = var.lambda_arn != "MOCK" ? "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations" : ""
  credentials             = var.role_arn
  timeout_milliseconds    = 29000
  request_templates       = var.is_proxy ? null : var.request_templates
  passthrough_behavior    = "NEVER"
}

resource "aws_api_gateway_method_response" "r200" {
  count       = var.http_method != "NONE" && !var.is_proxy ? 1 : 0
  depends_on  = [aws_api_gateway_resource.resource[0], aws_api_gateway_method.method[0]]
  rest_api_id = var.rest_api_id
  resource_id = var.resource_name != "/" ? aws_api_gateway_resource.resource[0].id : var.parent_resource_id
  http_method = aws_api_gateway_method.method[0].http_method
  status_code = "200"
  response_parameters = merge(local.default_cors_resp_header_params, var.response_header_params)
}

resource "aws_api_gateway_integration_response" "r200" {
  count       = var.http_method != "NONE" && !var.is_proxy ? 1 : 0
  depends_on  = [aws_api_gateway_resource.resource[0], aws_api_gateway_method.method[0], aws_api_gateway_integration.request[0]]
  rest_api_id = var.rest_api_id
  resource_id = var.resource_name != "/" ? aws_api_gateway_resource.resource[0].id : var.parent_resource_id
  http_method = aws_api_gateway_method.method[0].http_method
  status_code = aws_api_gateway_method_response.r200[0].status_code
  response_parameters = merge(local.default_cors_resp_headers, var.response_headers)
  response_templates = var.response_templates
}

resource "aws_api_gateway_method_response" "r500" {
  count       = var.http_method != "NONE" && !var.is_proxy ? 1 : 0
  depends_on  = [aws_api_gateway_resource.resource[0], aws_api_gateway_method.method[0]]
  rest_api_id = var.rest_api_id
  resource_id = var.resource_name != "/" ? aws_api_gateway_resource.resource[0].id : var.parent_resource_id
  http_method = aws_api_gateway_method.method[0].http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "r500" {
  count       = var.http_method != "NONE" && !var.is_proxy ? 1 : 0
  depends_on  = [
                  aws_api_gateway_resource.resource[0], 
                  aws_api_gateway_method.method[0],
                  aws_api_gateway_method_response.r500[0],
                  aws_api_gateway_integration.request[0]
                ]
  rest_api_id = var.rest_api_id
  resource_id = var.resource_name != "/" ? aws_api_gateway_resource.resource[0].id : var.parent_resource_id
  http_method = aws_api_gateway_method.method[0].http_method
  status_code = aws_api_gateway_method_response.r500[0].status_code
  selection_pattern = ".+"
  response_templates = {
      "application/json" = <<EOF
{
    "error": "$input.path('$.errorMessage')"
}
EOF
  }
}

module "cors" {
  count             = var.resource_name != "/" ? 1 : 0
  depends_on        = [aws_api_gateway_resource.resource[0]]
  source            = "github.com/squidfunk/terraform-aws-api-gateway-enable-cors"
  api_id            = var.rest_api_id
  api_resource_id   = aws_api_gateway_resource.resource[0].id
}
