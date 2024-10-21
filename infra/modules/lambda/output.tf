output "sparkify_api_function_name" {
  value = aws_lambda_function.sparkify_api.function_name
}

output "sparkify_api_function_invoke_arn" {
  value = aws_lambda_function.sparkify_api.invoke_arn
}
