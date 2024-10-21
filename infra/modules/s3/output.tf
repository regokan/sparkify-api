output "sparkify_etl_bucket" {
  value = aws_s3_bucket.sparkify_etl.bucket
}

output "sparkify_etl_bucket_arn" {
  value = aws_s3_bucket.sparkify_etl.arn
}

output "sparkify_etl_bucket_id" {
  value = aws_s3_bucket.sparkify_etl.id
}
