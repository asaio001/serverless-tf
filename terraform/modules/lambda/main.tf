resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}_role"
  assume_role_policy = var.assume_role_policy
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.lambda_role.name
  count      = length(var.policy_list)
  policy_arn = var.policy_list[count.index]
}

locals {
  environment_map = var.env_vars[*]
}

resource "aws_lambda_function" "function" {
  filename      = var.lambda_package
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_handler
  timeout       = var.timeout
  memory_size   = 1024
  layers        = var.layers
  runtime       = "python3.9"
  dynamic "environment" {
    for_each = local.environment_map
    content {
      variables = environment.value
    }
  }
}

output "lambda_func" {
  value = aws_lambda_function.function
}