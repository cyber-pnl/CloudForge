terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Floci-AZ serves both HTTP and HTTPS on port 4577 via a protocol-sniffing
# proxy. The azurerm provider discovers the cloud over HTTPS
# (GET /metadata/endpoints), so FLOCI_AZ_TLS_ENABLED must be true in
# docker-compose.yml. See docs/02-infrastructure/local-environment.md.
provider "azurerm" {
  features {}
  skip_provider_registration = true
  use_cli                    = false

  environment   = "stack"
  metadata_host = var.metadata_host

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = "00000000-0000-0000-0000-000000000003"
  client_secret   = "fake-secret"
}

locals {
  common_tags = {
    Project     = "cloudforge"
    Environment = "dev-az"
    ManagedBy   = "opentofu"
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

module "cosmosdb" {
  source = "../../modules/az-cosmosdb"

  account_name        = "${var.name_prefix}-cosmos"
  database_name       = "cloudforge"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  containers = {
    users = {
      partition_key_path = "/id"
    }
    projects = {
      partition_key_path = "/id"
    }
  }

  tags = local.common_tags
}

module "storage" {
  source = "../../modules/az-storage"

  storage_account_name = "${var.name_prefix}sa"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location

  containers = toset([
    "artifacts",
  ])

  queues = toset([
    "jobs",
    "jobs-dlq",
  ])

  tags = local.common_tags
}

module "keyvault" {
  source = "../../modules/az-keyvault"

  vault_name          = "${var.name_prefix}-kv"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = var.tenant_id

  tags = local.common_tags
}
