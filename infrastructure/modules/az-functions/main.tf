locals {
  # Application settings injected as the Function App's environment variables.
  all_settings = merge(
    var.app_settings,
  )

  # The package directory is the module-bundled one unless the caller overrides it.
  package_dir = var.package_dir == "" ? abspath("${path.module}/package") : abspath(var.package_dir)
}

# The Floci-AZ emulator does not emulate the Azure App Service Plan
# (Microsoft.Web/serverfarms returns 404), so the azurerm provider cannot
# create Function Apps. Instead, this module provisions the Function App and
# deploys a single HTTP-triggered function through Floci-AZ's native Functions
# management API (see scripts/azure-functions-deploy.sh and
# docs/02-infrastructure/multicloud-journal.md). This is an emulator-only path
# and is NOT portable to a real Azure App Service deployment.
resource "null_resource" "deploy" {
  triggers = {
    function_app_name   = var.function_app_name
    function_name       = var.function_name
    endpoint            = var.endpoint
    account_name        = var.account_name
    runtime_version     = var.runtime_version
    app_settings        = jsonencode(local.all_settings)
    package_dir_abspath = local.package_dir
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      export AZ_FUNCTIONS_ENDPOINT="${var.endpoint}"
      export AZ_FUNCTIONS_ACCOUNT="${var.account_name}"
      export AZ_FUNCTIONS_APP="${var.function_app_name}"
      export AZ_FUNCTIONS_FUNC="${var.function_name}"
      export AZ_FUNCTIONS_RUNTIME="python"
      export AZ_FUNCTIONS_RUNTIME_VERSION="${var.runtime_version}"
      export AZ_FUNCTIONS_PACKAGE_DIR="${local.package_dir}"
      export AZ_APP_SETTINGS='${jsonencode(local.all_settings)}'
      "${path.module}/../../../scripts/azure-functions-deploy.sh"
    EOT
  }
}
