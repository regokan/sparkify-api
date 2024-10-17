terraform {
  backend "s3" {
    bucket = "sparkify-etl-tf-state"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "s3" {
  source = "./modules/s3"
}
