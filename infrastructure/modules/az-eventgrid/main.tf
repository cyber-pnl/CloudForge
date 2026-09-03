resource "azurerm_eventgrid_topic" "this" {
  name                = var.topic_name
  resource_group_name = var.resource_group_name
  location            = var.location
  input_schema        = var.input_schema

  tags = merge(
    {
      Name      = var.topic_name
      ManagedBy = "opentofu"
    },
    var.tags,
  )
}

resource "azurerm_eventgrid_event_subscription" "this" {
  for_each = var.event_subscriptions

  name                  = each.key
  scope                 = azurerm_eventgrid_topic.this.id
  included_event_types  = each.value.included_event_types
  event_delivery_schema = "EventGridSchema"

  subject_filter {
    subject_begins_with = each.value.subject_begins_with
    subject_ends_with   = each.value.subject_ends_with
    case_sensitive      = each.value.is_subject_case_sensitive
  }

  retry_policy {
    max_delivery_attempts = each.value.max_delivery_attempts
    event_time_to_live    = each.value.event_time_to_live
  }

  webhook_endpoint {
    url = each.value.endpoint
  }
}