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
    events     = var.floci_endpoint
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

  table_name     = "cloudforge-dev-users"
  stream_enabled = true

  tags = local.common_tags
}

module "projects_table" {
  source = "../../modules/dynamodb"

  table_name     = "cloudforge-dev-projects"
  stream_enabled = true

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
  source_dir    = "${path.root}/../../../lambdas/users/build"
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
  source_dir    = "${path.root}/../../../lambdas/projects/build"
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

  queue_name                 = "cloudforge-dev-jobs"
  kms_master_key_arn         = module.messaging_key.key_arn
  visibility_timeout_seconds = 30

  tags = local.common_tags
}

module "jobs_dlq" {
  source = "../../modules/sqs"

  queue_name                = "cloudforge-dev-jobs-dlq"
  kms_master_key_arn        = module.messaging_key.key_arn
  message_retention_seconds = 1209600

  tags = local.common_tags
}

module "notifications_topic" {
  source = "../../modules/sns"

  topic_name         = "cloudforge-dev-notifications"
  display_name       = "CloudForge Notifications"
  kms_master_key_arn = module.messaging_key.key_arn

  tags = local.common_tags
}

module "event_bus" {
  source = "../../modules/eventbridge"

  bus_name = "cloudforge-dev-events"

  rules = {
    jobs = {
      description   = "Route domain change events to the jobs queue"
      event_pattern = jsonencode({ source = [{ prefix = "cloudforge." }] })
      target_arn    = module.jobs_queue.queue_arn
    }
    notify = {
      description   = "Route domain change events to the notifications topic"
      event_pattern = jsonencode({ source = [{ prefix = "cloudforge." }] })
      target_arn    = module.notifications_topic.topic_arn
    }
  }

  tags = local.common_tags
}

module "dispatcher_role" {
  source = "../../modules/iam"

  role_name = "cloudforge-dev-dispatcher-role"

  policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["dynamodb:DescribeStream", "dynamodb:GetRecords", "dynamodb:GetShardIterator", "dynamodb:ListStreams"]
      Resource = [module.users_table.stream_arn, module.projects_table.stream_arn]
    },
    {
      Effect   = "Allow"
      Action   = ["events:PutEvents"]
      Resource = [module.event_bus.bus_arn]
    }
  ]

  tags = local.common_tags
}

module "worker_role" {
  source = "../../modules/iam"

  role_name = "cloudforge-dev-worker-role"

  policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = ["${module.artifacts_bucket.bucket_arn}/artifacts/*"]
    },
    {
      Effect   = "Allow"
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Resource = [module.jobs_queue.queue_arn]
    }
  ]

  tags = local.common_tags
}

module "users_dispatcher" {
  source = "../../modules/lambda"

  function_name = "cloudforge-dev-users-dispatcher"
  source_dir    = "${path.root}/../../../lambdas/dispatcher/build"
  output_path   = "${path.module}/build/users-dispatcher.zip"
  role_arn      = module.dispatcher_role.role_arn
  timeout       = 10

  environment_variables = {
    TABLE_NAME     = module.users_table.table_name
    EVENT_BUS_NAME = module.event_bus.bus_name
  }

  tags = local.common_tags
}

module "projects_dispatcher" {
  source = "../../modules/lambda"

  function_name = "cloudforge-dev-projects-dispatcher"
  source_dir    = "${path.root}/../../../lambdas/dispatcher/build"
  output_path   = "${path.module}/build/projects-dispatcher.zip"
  role_arn      = module.dispatcher_role.role_arn
  timeout       = 10

  environment_variables = {
    TABLE_NAME     = module.projects_table.table_name
    EVENT_BUS_NAME = module.event_bus.bus_name
  }

  tags = local.common_tags
}

module "worker_function" {
  source = "../../modules/lambda"

  function_name = "cloudforge-dev-worker"
  source_dir    = "${path.root}/../../../lambdas/worker/build"
  output_path   = "${path.module}/build/worker.zip"
  role_arn      = module.worker_role.role_arn
  timeout       = 10

  environment_variables = {
    ARTIFACT_BUCKET = var.artifacts_bucket_name
    ARTIFACT_PREFIX = "artifacts/"
  }

  tags = local.common_tags
}

resource "aws_sqs_queue_redrive_policy" "jobs" {
  queue_url = module.jobs_queue.queue_url
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.jobs_dlq.queue_arn
    maxReceiveCount     = 3
  })
}

resource "aws_lambda_event_source_mapping" "users_stream" {
  event_source_arn                   = module.users_table.stream_arn
  function_name                      = module.users_dispatcher.function_name
  starting_position                  = "LATEST"
  batch_size                         = 10
  maximum_batching_window_in_seconds = 1
}

resource "aws_lambda_event_source_mapping" "projects_stream" {
  event_source_arn                   = module.projects_table.stream_arn
  function_name                      = module.projects_dispatcher.function_name
  starting_position                  = "LATEST"
  batch_size                         = 10
  maximum_batching_window_in_seconds = 1
}

resource "aws_lambda_event_source_mapping" "jobs_queue" {
  event_source_arn = module.jobs_queue.queue_arn
  function_name    = module.worker_function.function_name
  batch_size       = 1
}
