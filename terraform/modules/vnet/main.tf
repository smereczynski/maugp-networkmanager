resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # When not using IPAM, set address space; otherwise attach IPAM pool
  address_space = var.ipam_pool_id == "" ? var.address_space : null

  dynamic "ip_address_pool" {
    for_each = var.ipam_pool_id != "" ? [1] : []
    content {
      id                     = var.ipam_pool_id
      number_of_ip_addresses = var.ipam_vnet_number_of_ip_addresses
    }
  }
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  # Mutually exclusive with IPAM
  address_prefixes = var.ipam_pool_id == "" ? [var.default_subnet_cidr] : null

  dynamic "ip_address_pool" {
    for_each = var.ipam_pool_id != "" ? [1] : []
    content {
      id                     = var.ipam_pool_id
      number_of_ip_addresses = var.ipam_subnet_number_of_ip_addresses
    }
  }
}

# Route table association for default subnet (v4 azurerm requires separate resource)
resource "azurerm_subnet_route_table_association" "default" {
  count          = var.associate_route_table && var.route_table_id != "" ? 1 : 0
  subnet_id      = azurerm_subnet.default.id
  route_table_id = var.route_table_id
}

# IPAM allocation for default subnet
// no azapi needed with provider-native IPAM support

resource "azurerm_subnet" "afw" {
  count                = var.deploy_firewall ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  # When not using IPAM, set address prefixes; otherwise attach IPAM pool
  # 10.<i>.1.0/26 where <i> comes from the VNet's 10.<i>.0.0/16
  address_prefixes = var.ipam_pool_id == "" ? [cidrsubnet(cidrsubnet(var.address_space[0], 8, 1), 2, 0)] : null

  dynamic "ip_address_pool" {
    for_each = var.ipam_pool_id != "" ? [1] : []
    content {
      id                     = var.ipam_pool_id
      number_of_ip_addresses = var.ipam_firewall_subnet_number_of_ip_addresses
    }
  }
}

resource "azurerm_subnet" "afw_mgmt" {
  count                = var.deploy_firewall ? 1 : 0
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  # When not using IPAM, set address prefixes; otherwise attach IPAM pool
  # 10.<i>.1.64/26 derived from the same /24 (netnum 1)
  address_prefixes = var.ipam_pool_id == "" ? [cidrsubnet(cidrsubnet(var.address_space[0], 8, 1), 2, 1)] : null

  dynamic "ip_address_pool" {
    for_each = var.ipam_pool_id != "" ? [1] : []
    content {
      id                     = var.ipam_pool_id
      number_of_ip_addresses = var.ipam_firewall_mgmt_subnet_number_of_ip_addresses
    }
  }
}

output "name" { value = azurerm_virtual_network.vnet.name }
