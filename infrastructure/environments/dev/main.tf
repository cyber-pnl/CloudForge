terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  endpoints {
    s3  = var.floci_endpoint
    kms = var.floci_endpoint
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  s3_use_path_style = true
}

module "artifacts_key" {
  source = "../../modules/kms"

  alias_name  = "cloudforge-dev-artifacts"
  description = "Default encryption key for the dev artifacts bucket"

  tags = {
    Project = "cloudforge"
  }
}

module "artifacts_bucket" {
  source = "../../modules/s3"

  bucket_name        = var.artifacts_bucket_name
  environment        = "dev"
  kms_master_key_arn = module.artifacts_key.key_arn

  tags = {
    Project = "cloudforge"
  }
}
