resource "azurerm_public_ip" "data_pip" {
  name                = "${var.name}-afw-data-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_public_ip" "mgmt_pip" {
  name                = "${var.name}-afw-mgmt-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall_policy" "fw_policy" {
  name                = "${var.name}-afw-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "allowall" {
  name               = "allowall"
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
  name                = "${var.name}-afw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  threat_intel_mode   = "Alert"
  zones               = ["1", "2", "3"]
  tags                = var.tags

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
