variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
  type        = string
}

variable "sparkify_etl_bucket_arn" {
  description = "Sparkify ETL Bucket ARN"
  type        = string
}
