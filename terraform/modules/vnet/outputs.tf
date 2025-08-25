output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "default_subnet_id" {
  value = azurerm_subnet.default.id
}

output "afw_subnet_id" {
  value = length(azurerm_subnet.afw) > 0 ? azurerm_subnet.afw[0].id : null
}

output "afw_mgmt_subnet_id" {
  value = length(azurerm_subnet.afw_mgmt) > 0 ? azurerm_subnet.afw_mgmt[0].id : null
}
