resource "azurerm_service_plan" "this" {
  name                = "${var.function_app_name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = merge(
    {
      Name      = "${var.function_app_name}-plan"
      ManagedBy = "opentofu"
    },
    var.tags,
  )
}

resource "azurerm_linux_function_app" "this" {
  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  functions_extension_version = var.functions_extension_version

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  site_config {
    application_stack {
      python_version = var.runtime_version
    }
  }

  app_settings = merge(
    {
      FUNCTIONS_WORKER_RUNTIME = var.runtime
    },
    var.app_settings,
  )

  tags = merge(
    {
      Name      = var.function_app_name
      ManagedBy = "opentofu"
    },
    var.tags,
  )
}
