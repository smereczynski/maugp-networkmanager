locals {
  # Use the VNet name directly to match Bicep's baseName behavior
  base = var.name
}

resource "azurerm_public_ip" "data_pip" {
  name                = "pip-azfw-${local.base}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_public_ip" "mgmt_pip" {
  name                = "pip-azfw-mgmt-${local.base}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall_policy" "fw_policy" {
  name                = "afwp-basic-${local.base}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "allowall" {
  name               = "rcg-default"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 100

  network_rule_collection {
    name     = "allowall"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "any-any"
      protocols             = ["Any"]
      source_addresses      = ["0.0.0.0/0"]
      destination_addresses = ["0.0.0.0/0"]
      destination_ports     = ["*"]
    }
  }
}

resource "azurerm_firewall" "fw" {
  name                = "afw-${local.base}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  threat_intel_mode   = "Alert"
  zones               = ["1", "2", "3"]
  tags                = var.tags
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id

  ip_configuration {
    name                 = "data"
    subnet_id            = var.afw_subnet_id
    public_ip_address_id = azurerm_public_ip.data_pip.id
  }

  management_ip_configuration {
    name                 = "mgmt"
    subnet_id            = var.afw_mgmt_subnet_id
    public_ip_address_id = azurerm_public_ip.mgmt_pip.id
  }
}
