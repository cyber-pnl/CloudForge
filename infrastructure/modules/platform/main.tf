locals {
  common_tags = {
    Project     = "cloudforge"
    Environment = var.environment
  }
}

module "users_table" {
  source = "../dynamodb"

  table_name     = "${var.name_prefix}-users"
  stream_enabled = true

  tags = local.common_tags
}

module "projects_table" {
  source = "../dynamodb"

  table_name     = "${var.name_prefix}-projects"
  stream_enabled = true

  tags = local.common_tags
}

module "artifacts_key" {
  source = "../kms"

  alias_name  = "${var.name_prefix}-artifacts"
  description = "Default encryption key for the ${var.environment} artifacts bucket"

  tags = local.common_tags
}

module "messaging_key" {
  source = "../kms"

  alias_name  = "${var.name_prefix}-messaging"
  description = "Default encryption key for the ${var.environment} messaging services"

  tags = local.common_tags
}

module "artifacts_bucket" {
  source = "../s3"

  bucket_name        = var.artifacts_bucket_name
  environment        = var.environment
  kms_master_key_arn = module.artifacts_key.key_arn

  tags = local.common_tags
}

module "users_role" {
  source = "../iam"

  role_name = "${var.name_prefix}-users-role"

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
  source = "../iam"

  role_name = "${var.name_prefix}-projects-role"

  policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Query"]
      Resource = [module.projects_table.table_arn]
    },
    {
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:DeleteObject"]
      Resource = ["${module.artifacts_bucket.bucket_arn}/projects/*"]
    },
    {
      Effect   = "Allow"
      Action   = ["s3:ListBucket"]
      Resource = [module.artifacts_bucket.bucket_arn]
    }
  ]

  tags = local.common_tags
}

module "users_function" {
  source = "../lambda"

  function_name = "${var.name_prefix}-users"
  source_dir    = "${var.lambdas_dir}/users/build"
  output_path   = "${path.module}/build/${var.environment}-users.zip"
  role_arn      = module.users_role.role_arn

  environment_variables = {
    SERVICE_NAME = "users"
    TABLE_NAME   = module.users_table.table_name
    API_TOKEN    = var.api_token
  }

  tags = local.common_tags
}

module "projects_function" {
  source = "../lambda"

  function_name = "${var.name_prefix}-projects"
  source_dir    = "${var.lambdas_dir}/projects/build"
  output_path   = "${path.module}/build/${var.environment}-projects.zip"
  role_arn      = module.projects_role.role_arn

  environment_variables = {
    SERVICE_NAME     = "projects"
    TABLE_NAME       = module.projects_table.table_name
    USERS_TABLE_NAME = module.users_table.table_name
    ARTIFACT_BUCKET  = var.artifacts_bucket_name
    API_TOKEN        = var.api_token
  }

  tags = local.common_tags
}

module "api" {
  source = "../api-gateway"

  api_name = "${var.name_prefix}-api"

  routes = {
    users = {
      path_part         = "users"
      lambda_name       = module.users_function.function_name
      lambda_invoke_arn = module.users_function.invoke_arn
    }
    projects = {
      path_part         = "projects"
      lambda_name       = module.projects_function.function_name
      lambda_invoke_arn = module.projects_function.invoke_arn
    }
  }

  child_routes = {
    user_id = {
      parent            = "users"
      path_part         = "{id}"
      lambda_name       = module.users_function.function_name
      lambda_invoke_arn = module.users_function.invoke_arn
    }
    project_id = {
      parent            = "projects"
      path_part         = "{id}"
      lambda_name       = module.projects_function.function_name
      lambda_invoke_arn = module.projects_function.invoke_arn
    }
  }

  grandchild_routes = {
    project_artifacts = {
      parent            = "project_id"
      path_part         = "artifacts"
      lambda_name       = module.projects_function.function_name
      lambda_invoke_arn = module.projects_function.invoke_arn
    }
  }

  tags = local.common_tags
}

module "jobs_queue" {
  source = "../sqs"

  queue_name                 = "${var.name_prefix}-jobs"
  kms_master_key_arn         = module.messaging_key.key_arn
  visibility_timeout_seconds = 30

  tags = local.common_tags
}

module "jobs_dlq" {
  source = "../sqs"

  queue_name                = "${var.name_prefix}-jobs-dlq"
  kms_master_key_arn        = module.messaging_key.key_arn
  message_retention_seconds = 1209600

  tags = local.common_tags
}

module "notifications_topic" {
  source = "../sns"

  topic_name         = "${var.name_prefix}-notifications"
  display_name       = "CloudForge Notifications"
  kms_master_key_arn = module.messaging_key.key_arn

  tags = local.common_tags
}

module "alarms" {
  source = "../cloudwatch"

  name_prefix            = var.name_prefix
  namespace              = "CloudForge/SQS"
  dlq_name               = "${var.name_prefix}-jobs-dlq"
  api_health_metric_name = "ApiHealth"
  notify_topic_arn       = module.notifications_topic.topic_arn

  tags = local.common_tags
}

module "event_bus" {
  source = "../eventbridge"

  bus_name = "${var.name_prefix}-events"

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
  source = "../iam"

  role_name = "${var.name_prefix}-dispatcher-role"

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
  source = "../iam"

  role_name = "${var.name_prefix}-worker-role"

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
  source = "../lambda"

  function_name = "${var.name_prefix}-users-dispatcher"
  source_dir    = "${var.lambdas_dir}/dispatcher/build"
  output_path   = "${path.module}/build/${var.environment}-users-dispatcher.zip"
  role_arn      = module.dispatcher_role.role_arn
  timeout       = 10

  environment_variables = {
    TABLE_NAME     = module.users_table.table_name
    EVENT_BUS_NAME = module.event_bus.bus_name
  }

  tags = local.common_tags
}

module "projects_dispatcher" {
  source = "../lambda"

  function_name = "${var.name_prefix}-projects-dispatcher"
  source_dir    = "${var.lambdas_dir}/dispatcher/build"
  output_path   = "${path.module}/build/${var.environment}-projects-dispatcher.zip"
  role_arn      = module.dispatcher_role.role_arn
  timeout       = 10

  environment_variables = {
    TABLE_NAME     = module.projects_table.table_name
    EVENT_BUS_NAME = module.event_bus.bus_name
  }

  tags = local.common_tags
}

module "worker_function" {
  source = "../lambda"

  function_name = "${var.name_prefix}-worker"
  source_dir    = "${var.lambdas_dir}/worker/build"
  output_path   = "${path.module}/build/${var.environment}-worker.zip"
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

  # Floci does not persist starting_position nor
  # maximum_batching_window_in_seconds, so every refresh reads them back as
  # absent and would force a replacement (and a stream replay). See
  # docs/02-infrastructure/local-environment.md.
  lifecycle {
    ignore_changes = [starting_position, maximum_batching_window_in_seconds]
  }
}

resource "aws_lambda_event_source_mapping" "projects_stream" {
  event_source_arn                   = module.projects_table.stream_arn
  function_name                      = module.projects_dispatcher.function_name
  starting_position                  = "LATEST"
  batch_size                         = 10
  maximum_batching_window_in_seconds = 1

  lifecycle {
    ignore_changes = [starting_position, maximum_batching_window_in_seconds]
  }
}

resource "aws_lambda_event_source_mapping" "jobs_queue" {
  event_source_arn = module.jobs_queue.queue_arn
  function_name    = module.worker_function.function_name
  batch_size       = 1
}
