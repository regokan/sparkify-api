terraform {
  backend "s3" {
    bucket = "sparkify-etl-tf-state"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}
