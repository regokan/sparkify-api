resource "aws_s3_bucket" "sparkify_etl" {
  bucket = "sparkify-etl"

  tags = {
    Name        = "sparkify-etl"
    Project     = "Jobs"
    Owner       = "DataEngg"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_ownership_controls" "sparkify_etl_ownership_controls" {
  bucket = aws_s3_bucket.sparkify_etl.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "sparkify_etl_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.sparkify_etl_ownership_controls]

  bucket = aws_s3_bucket.sparkify_etl.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "sparkify_etl_versioning" {
  bucket = aws_s3_bucket.sparkify_etl.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sparkify_etl_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.sparkify_etl.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sparkify_etl_lifecycle_configuration" {
  bucket = aws_s3_bucket.sparkify_etl.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}
