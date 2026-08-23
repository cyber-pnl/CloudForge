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
  access_key = "test"
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
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  s3_use_path_style = true
}

locals {
  common_tags = {
    Project = "cloudforge"
  }
}

module "users_table" {
  source = "../../modules/dynamodb"

  table_name = "cloudforge-dev-users"

  tags = local.common_tags
}

module "projects_table" {
  source = "../../modules/dynamodb"

  table_name = "cloudforge-dev-projects"

  tags = local.common_tags
}

module "artifacts_key" {
  source = "../../modules/kms"

  alias_name  = "cloudforge-dev-artifacts"
  description = "Default encryption key for the dev artifacts bucket"

  tags = local.common_tags
}

module "messaging_key" {
  source = "../../modules/kms"

  alias_name  = "cloudforge-dev-messaging"
  description = "Default encryption key for the dev messaging services"

  tags = local.common_tags
}

module "artifacts_bucket" {
  source = "../../modules/s3"

  bucket_name        = var.artifacts_bucket_name
  environment        = "dev"
  kms_master_key_arn = module.artifacts_key.key_arn

  tags = local.common_tags
}

module "users_role" {
  source = "../../modules/iam"

  role_name = "cloudforge-dev-users-role"

  policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Query"]
      Resource = [module.users_table.table_arn]
    }
  ]

  tags = local.common_tags
}

module "projects_role" {
  source = "../../modules/iam"

  role_name = "cloudforge-dev-projects-role"

  policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Query"]
      Resource = [module.projects_table.table_arn]
    }
  ]

  tags = local.common_tags
}

module "users_function" {
  source = "../../modules/lambda"

  function_name = "cloudforge-dev-users"
  source_dir    = "${path.root}/../../../lambdas/users"
  output_path   = "${path.module}/build/users.zip"
  role_arn      = module.users_role.role_arn

  environment_variables = {
    SERVICE_NAME = "users"
    TABLE_NAME   = module.users_table.table_name
  }

  tags = local.common_tags
}

module "projects_function" {
  source = "../../modules/lambda"

  function_name = "cloudforge-dev-projects"
  source_dir    = "${path.root}/../../../lambdas/projects"
  output_path   = "${path.module}/build/projects.zip"
  role_arn      = module.projects_role.role_arn

  environment_variables = {
    SERVICE_NAME = "projects"
    TABLE_NAME   = module.projects_table.table_name
  }

  tags = local.common_tags
}

module "api" {
  source = "../../modules/api-gateway"

  api_name = "cloudforge-dev-api"

  routes = [
    {
      path_part         = "users"
      lambda_name       = module.users_function.function_name
      lambda_invoke_arn = module.users_function.invoke_arn
    },
    {
      path_part         = "projects"
      lambda_name       = module.projects_function.function_name
      lambda_invoke_arn = module.projects_function.invoke_arn
    },
  ]

  tags = local.common_tags
}

module "jobs_queue" {
  source = "../../modules/sqs"

  queue_name         = "cloudforge-dev-jobs"
  kms_master_key_arn = module.messaging_key.key_arn

  tags = local.common_tags
}

module "notifications_topic" {
  source = "../../modules/sns"

  topic_name         = "cloudforge-dev-notifications"
  display_name       = "CloudForge Notifications"
  kms_master_key_arn = module.messaging_key.key_arn

  tags = local.common_tags
}
