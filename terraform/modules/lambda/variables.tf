variable "lambda_name" {
    type = string
}

variable "lambda_package" {
    type = string
}

variable "lambda_handler" {
    type = string
}

variable "policy_list" {
    type = list
    default = [
        "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
        "arn:aws:iam::aws:policy/CloudWatchFullAccess"
    ]
}

variable "assume_role_policy" {
    type = string
    default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

variable "timeout" {
    type = number
    default = 300
}

variable "env_vars" {
    type = map
    default = {
      TEST_ENV = "test_value"
    }
}

variable "layers" {
    type = list
    default = []
}


