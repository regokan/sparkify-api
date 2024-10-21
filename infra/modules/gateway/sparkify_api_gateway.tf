# Create the API Gateway REST API
resource "aws_api_gateway_rest_api" "sparkify_api_gateway" {
  name        = "sparkify-api"
  description = "API Gateway for Sparkify API"
}

# Enable CloudWatch logging for API Gateway
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = var.api_gateway_cloudwatch_role_arn
}

# Create a resource in the API
resource "aws_api_gateway_resource" "sparkify_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.sparkify_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.sparkify_api_gateway.root_resource_id
  path_part   = "graphql"
}

# Create the API Gateway method for HTTP ANY (GET, POST, etc.)
resource "aws_api_gateway_method" "sparkify_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.sparkify_api_gateway.id
  resource_id   = aws_api_gateway_resource.sparkify_api_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integrate API Gateway with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.sparkify_api_gateway.id
  resource_id             = aws_api_gateway_resource.sparkify_api_resource.id
  http_method             = aws_api_gateway_method.sparkify_api_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.sparkify_api_function_invoke_arn
}

# Enable API Gateway Stage-level Logging
resource "aws_api_gateway_stage" "sparkify_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.sparkify_api_gateway.id
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.sparkify_api_deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_access_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      caller         = "$context.identity.caller",
      user           = "$context.identity.user",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [deployment_id]
  }

  depends_on = [
    aws_api_gateway_deployment.sparkify_api_deployment
  ]
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.sparkify_api_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sparkify_api_gateway.execution_arn}/*/*/*"
}

# Create CloudWatch Log Group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gw_access_logs" {
  name              = "/aws/api-gateway/sparkify-api-access-logs"
  retention_in_days = 7
}

# Create the deployment for the API Gateway
resource "aws_api_gateway_deployment" "sparkify_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.sparkify_api_gateway.id

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method.sparkify_api_method
  ]
}

# Method settings for enabling CloudWatch logging and detailed metrics
resource "aws_api_gateway_method_settings" "sparkify_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.sparkify_api_gateway.id
  stage_name  = aws_api_gateway_stage.sparkify_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}
