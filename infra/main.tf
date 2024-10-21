terraform {
  backend "s3" {
    bucket = "sparkify-etl-tf-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "s3" {
  source = "./modules/s3"
}

module "iam" {
  source = "./modules/iam"

  aws_region              = data.aws_region.current.name
  aws_account_id          = data.aws_caller_identity.current.account_id
  sparkify_etl_bucket_arn = module.s3.sparkify_etl_bucket_arn
}

module "keyspaces" {
  source = "./modules/keyspaces"
}

module "lambda" {
  source = "./modules/lambda"

  sparkify_etl_bucket_id       = module.s3.sparkify_etl_bucket_id
  sparkify_etl_bucket_arn      = module.s3.sparkify_etl_bucket_arn
  sparkify_bronze_etl_role_arn = module.iam.sparkify_bronze_etl_role_arn
  sparkify_api_role_arn        = module.iam.sparkify_api_role_arn
}

module "gateway" {
  source = "./modules/gateway"

  sparkify_api_function_name       = module.lambda.sparkify_api_function_name
  sparkify_api_function_invoke_arn = module.lambda.sparkify_api_function_invoke_arn
  api_gateway_cloudwatch_role_arn  = module.iam.api_gateway_cloudwatch_role_arn
}
