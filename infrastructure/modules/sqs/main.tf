resource "aws_sqs_queue" "this" {
  name                       = var.queue_name
  kms_master_key_id          = var.kms_master_key_arn
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds

  tags = merge(
    {
      Name        = var.queue_name
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}
