terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.41.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "e2dda714-1e15-49ca-961c-377a63fb5769"
}
