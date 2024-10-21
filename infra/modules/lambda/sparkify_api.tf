# Reference the API Layer in S3
data "aws_s3_object" "sparkify_api_layer" {
  bucket = var.sparkify_etl_bucket_id
  key    = "api/scripts/api_layer.zip"
}

# Reference the Lambda code in S3
data "aws_s3_object" "sparkify_api_code" {
  bucket = var.sparkify_etl_bucket_id
  key    = "api/scripts/code.zip"
}

# Create a Lambda Layer for the API
resource "aws_lambda_layer_version" "sparkify_api_layer" {
  layer_name          = "sparkify_api_layer"
  s3_bucket           = data.aws_s3_object.sparkify_api_layer.bucket
  s3_key              = data.aws_s3_object.sparkify_api_layer.key
  compatible_runtimes = ["python3.12"]

  description = "Lambda layer for API"
}

# Lambda Function with Layer attached
resource "aws_lambda_function" "sparkify_api" {
  function_name = "sparkify_api"

  s3_bucket = data.aws_s3_object.sparkify_api_code.bucket
  s3_key    = data.aws_s3_object.sparkify_api_code.key

  handler = "main.lambda_handler"
  runtime = "python3.12"

  memory_size = 128
  timeout     = 90

  role = var.sparkify_api_role_arn

  # Attach the API layer to the Lambda function
  layers = [
    aws_lambda_layer_version.sparkify_api_layer.arn
  ]

  tags = {
    Name        = "sparkify_api"
    Project     = "sparkify_etl"
    Owner       = "ProductEngg"
    Stage       = "API"
    Environment = "Production"
  }
}
