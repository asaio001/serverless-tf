variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "env_name" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "cognito_user_pool" {
  type = string
}
