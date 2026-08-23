resource "aws_sns_topic" "this" {
  name              = var.topic_name
  display_name      = var.display_name
  kms_master_key_id = var.kms_master_key_arn

  tags = merge(
    {
      Name        = var.topic_name
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}
