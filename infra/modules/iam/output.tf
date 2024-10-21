output "sparkify_bronze_etl_role_arn" {
  value = aws_iam_role.sparkify_bronze_etl_role.arn
}

output "sparkify_api_role_arn" {
  value = aws_iam_role.sparkify_api_role.arn
}

output "api_gateway_cloudwatch_role_arn" {
  value = aws_iam_role.api_gateway_cloudwatch_role.arn
}
