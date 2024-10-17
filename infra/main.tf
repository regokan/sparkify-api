terraform {
  backend "s3" {
    bucket = "sparkify-etl"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}
