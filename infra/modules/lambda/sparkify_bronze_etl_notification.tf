resource "aws_s3_bucket_notification" "sparkify_bronze_etl_bucket_notification" {
  bucket = var.sparkify_etl_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.sparkify_bronze_etl.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "ingestion/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_invoke_lambda
  ]
}

resource "aws_lambda_permission" "allow_s3_invoke_lambda" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sparkify_bronze_etl.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.sparkify_etl_bucket_arn
}
