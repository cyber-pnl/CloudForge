resource "azurerm_api_management" "this" {
  name                = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  tags = merge(
    {
      Name      = var.apim_name
      ManagedBy = "opentofu"
    },
    var.tags,
  )
}

resource "azurerm_api_management_api" "this" {
  for_each = var.apis

  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  display_name        = each.value.display_name
  path                = each.value.path
  protocols           = each.value.protocols
  description         = each.value.description

  revision = "1"
}
