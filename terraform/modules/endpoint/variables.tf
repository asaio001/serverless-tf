variable "rest_api_id" {
    type = string
}

variable "parent_resource_id" {
    type = string
}

variable "resource_name" {
    type = string
}

variable "auth_id" {
    type = string
    default = ""
}

variable "role_arn" {
    type = string
}

variable "http_method" {
    type = string
    default = "GET"
}

variable "lambda_arn" {
    type = string
}

variable "is_proxy" {
    type = bool
    default = false
}

variable "request_parameters" {
    type = map
    default = null
}

variable "request_templates" {
    type = map
    default = {
    "application/json" = <<EOF
#set($body = $input.path('$'))
#set($body.email = "$context.authorizer.claims.email")
#set($groups = $context.authorizer.claims['cognito:groups'])
#if($groups && $groups != "")
  #set($body.groups = $groups)
#else
  #set($body.groups = [])
#end
$input.json('$')
EOF
  }
}

variable "response_header_params" {
    type = map
    default = {}
}

variable "response_headers" {
    type = map
    default = {}
}

variable "response_templates" {
    type = map
    default = null
}



