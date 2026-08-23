data "archive_file" "this" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = var.output_path
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    {
      Name        = "/aws/lambda/${var.function_name}"
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  runtime       = var.runtime
  handler       = var.handler

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = -1

  environment {
    variables = merge(
      { ENVIRONMENT = var.environment },
      var.environment_variables,
    )
  }

  tags = merge(
    {
      Name        = var.function_name
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )

  depends_on = [aws_cloudwatch_log_group.this]
}
