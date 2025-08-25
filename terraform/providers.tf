terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13"
    }
  }
  backend "local" {}
}

provider "azurerm" {
  features {}
  use_cli = true
}

provider "azapi" {
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "polandcentral"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources"
  default     = {
    env = "poc"
  }
}

variable "ipam_pool_id" {
  type        = string
  description = "Resource ID of the AVNM IPAM pool to allocate prefixes from. Empty string to disable IPAM."
  default     = ""
}

variable "route_table_id" {
  type        = string
  description = "Optional route table ID to associate with default subnet. Empty string to skip."
  default     = ""
}
