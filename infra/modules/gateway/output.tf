# Output the API Gateway endpoint URL
output "api_url" {
  value = "${aws_api_gateway_deployment.sparkify_api_deployment.invoke_url}prod/graphql"
}
