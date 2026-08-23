resource "aws_cloudwatch_event_bus" "this" {
  name = var.bus_name

  tags = merge(
    {
      Name        = var.bus_name
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.rules

  name           = "${var.bus_name}-${each.key}"
  event_bus_name = aws_cloudwatch_event_bus.this.name
  description    = try(each.value.description, null)
  event_pattern  = each.value.event_pattern

  tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = var.rules

  rule           = aws_cloudwatch_event_rule.this[each.key].name
  event_bus_name = aws_cloudwatch_event_bus.this.name
  target_id      = "${var.bus_name}-${each.key}"
  arn            = each.value.target_arn
}
