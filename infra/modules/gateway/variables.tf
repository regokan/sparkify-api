variable "sparkify_api_function_name" {
  description = "Sparkify API Lambda Function Name"
  type        = string
}

variable "sparkify_api_function_invoke_arn" {
  description = "Sparkify API Lambda Function Invoke ARN"
  type        = string
}

variable "api_gateway_cloudwatch_role_arn" {
  description = "API Gateway CloudWatch Role ARN"
  type        = string
}
