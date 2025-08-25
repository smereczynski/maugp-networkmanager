data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Only set address_space when not using IPAM
  address_space = var.ipam_pool_id == "" ? var.address_space : null
}

# IPAM allocation for VNet
resource "azapi_update_resource" "vnet_ipam" {
  count     = var.ipam_pool_id == "" ? 0 : 1
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  name      = azurerm_virtual_network.vnet.name
  parent_id = data.azurerm_resource_group.rg.id

  body = jsonencode({
    properties = {
      ipamPoolPrefixAllocations = [
        {
          ipamPool = { id = var.ipam_pool_id }
        }
      ]
    }
  })
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  # Mutually exclusive with IPAM
  address_prefixes = var.ipam_pool_id == "" ? [var.default_subnet_cidr] : null

  route_table_id = var.associate_route_table && var.route_table_id != "" ? var.route_table_id : null

  depends_on = [azapi_update_resource.vnet_ipam]
}

# IPAM allocation for default subnet
resource "azapi_update_resource" "default_subnet_ipam" {
  count     = var.ipam_pool_id == "" ? 0 : 1
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = "${azurerm_virtual_network.vnet.name}/default"
  parent_id = data.azurerm_resource_group.rg.id

  body = jsonencode({
    properties = {
      ipamPoolPrefixAllocations = [
        {
          ipamPool = { id = var.ipam_pool_id }
        }
      ]
    }
  })
}

# Optional Firewall subnets (no IPAM)
resource "azurerm_subnet" "afw" {
  count                = var.deploy_firewall ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 252)]
}

resource "azurerm_subnet" "afw_mgmt" {
  count                = var.deploy_firewall ? 1 : 0
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 253)]
}

output "name" { value = azurerm_virtual_network.vnet.name }
