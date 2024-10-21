# Reference the Cassandra Layer in S3
data "aws_s3_object" "sparkify_bronze_cassandra_layer" {
  bucket = var.sparkify_etl_bucket_id
  key    = "lambda/bronze/cassandra_layer.zip"
}

# Reference the Lambda code in S3
data "aws_s3_object" "sparkify_bronze_etl_code" {
  bucket = var.sparkify_etl_bucket_id
  key    = "lambda/bronze/code.zip"
}

# Create a Lambda Layer for the Cassandra driver
resource "aws_lambda_layer_version" "sparkify_bronze_cassandra_layer" {
  layer_name          = "sparkify_bronze_cassandra_layer"
  s3_bucket           = data.aws_s3_object.sparkify_bronze_cassandra_layer.bucket
  s3_key              = data.aws_s3_object.sparkify_bronze_cassandra_layer.key
  compatible_runtimes = ["python3.11"]

  description = "Lambda layer for Cassandra driver"
}

# Lambda Function with Layer attached
resource "aws_lambda_function" "sparkify_bronze_etl" {
  function_name = "sparkify_bronze_etl"

  s3_bucket = data.aws_s3_object.sparkify_bronze_etl_code.bucket
  s3_key    = data.aws_s3_object.sparkify_bronze_etl_code.key

  handler = "main.lambda_handler"
  runtime = "python3.11"

  memory_size = 128
  timeout     = 90

  role = var.sparkify_bronze_etl_role_arn

  # Attach the Cassandra layer to the Lambda function
  layers = [
    aws_lambda_layer_version.sparkify_bronze_cassandra_layer.arn
  ]

  tags = {
    Name        = "sparkify_bronze_etl"
    Project     = "sparkify_etl"
    Owner       = "DataEngg"
    Stage       = "ETL"
    Environment = "Production"
  }
}
