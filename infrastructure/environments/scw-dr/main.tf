# Scaleway warm-standby site (ADR-005).
#
# CloudForge's primary platform runs on AWS/Floci; this environment models
# the second-cloud footprint where compute capacity would be restored if
# the primary is lost. Provisioned against the Feint emulator with the real
# scaleway/scaleway provider.

terraform {
  required_version = "~> 1.12"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.81"
    }
  }
}

provider "scaleway" {
  api_url    = var.feint_endpoint
  access_key = var.scw_access_key
  secret_key = var.scw_secret_key
  project_id = var.scw_project_id
  zone       = "fr-par-1"
  region     = "fr-par"
}

locals {
  common_tags = {
    Project     = "cloudforge"
    Environment = "scw-dr"
    ManagedBy   = "opentofu"
  }
}

variable "feint_endpoint" {
  description = "Feint emulator control plane serving the Scaleway API"
  type        = string
  default     = "http://localhost:4599"
}

# Feint never validates credentials; these are its documented public
# placeholders, present so official clients can sign requests at all.
variable "scw_access_key" {
  type    = string
  default = "SCWXXXXXXXXXXXXXXXXX"
}

variable "scw_secret_key" {
  type      = string
  default   = "11111111-1111-1111-1111-111111111111"
  sensitive = true
}

variable "scw_project_id" {
  type    = string
  default = "11111111-1111-1111-1111-111111111111"
}

variable "instance_type" {
  description = "Standby compute shape; DEV1-S keeps the lab footprint minimal"
  type        = string
  default     = "DEV1-S"
}

variable "data_volume_size_gb" {
  type    = number
  default = 10
}

resource "scaleway_vpc" "dr" {
  name = "cf-dr-vpc"
  tags = [for k, v in local.common_tags : "${k}=${v}"]
}

resource "scaleway_vpc_private_network" "dr" {
  name   = "cf-dr-network"
  vpc_id = scaleway_vpc.dr.id
}

resource "scaleway_instance_server" "standby" {
  name  = "cf-dr-standby"
  type  = var.instance_type
  image = "ubuntu_jammy"

  private_network {
    pn_id = scaleway_vpc_private_network.dr.id
  }

  # Restore target: the volume a primary-cloud backup would land on.
  additional_volume_ids = [scaleway_block_volume.restore_data.id]

  tags = [for k, v in local.common_tags : "${k}=${v}"]
}

resource "scaleway_block_volume" "restore_data" {
  name       = "cf-dr-restore-data"
  size_in_gb = var.data_volume_size_gb
  iops       = 5000
}
