resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name
}

resource "aws_iam_role" "api_role" {
  name = var.api_iam_role_name
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy" {
  role       = aws_iam_role.api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.api_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_api_gateway_authorizer" "user_auth" {
  count                  = length(var.auth_provider_arns) == 0 ? 0 : 1
  name                   = var.auth_name
  rest_api_id            = aws_api_gateway_rest_api.api.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = var.auth_provider_arns
}

module "default_head_endpoint" {
    source = "../../modules/endpoint"
    rest_api_id = aws_api_gateway_rest_api.api.id
    parent_resource_id = aws_api_gateway_rest_api.api.root_resource_id
    role_arn = aws_iam_role.api_role.arn
    resource_name = "/"
    http_method = "HEAD"
    lambda_arn = "MOCK"
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_deployment.deployment.stage_name
  method_path = "*/*"
  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [module.default_head_endpoint]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.deploy_name
  lifecycle {
    create_before_destroy = true
  }
}

output "role_arn" {
  value = aws_iam_role.api_role.arn
}

output "api" {
  value = aws_api_gateway_rest_api.api
}
