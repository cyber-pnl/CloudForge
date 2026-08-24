terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.account_id
  secret_key = "test"

  endpoints {
    s3         = var.floci_endpoint
    kms        = var.floci_endpoint
    dynamodb   = var.floci_endpoint
    lambda     = var.floci_endpoint
    apigateway = var.floci_endpoint
    sqs        = var.floci_endpoint
    sns        = var.floci_endpoint
    iam        = var.floci_endpoint
    logs       = var.floci_endpoint
    events     = var.floci_endpoint
    cloudwatch = var.floci_endpoint
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  s3_use_path_style = true
}

module "platform" {
  source = "../../modules/platform"

  name_prefix           = "cloudforge-staging"
  environment           = "staging"
  artifacts_bucket_name = var.artifacts_bucket_name
  api_token             = var.api_token
  lambdas_dir           = "${path.module}/../../../lambdas"
}
