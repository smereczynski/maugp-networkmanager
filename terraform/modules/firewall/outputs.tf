output "firewall_id" { value = azurerm_firewall.fw.id }
output "policy_id" { value = azurerm_firewall_policy.fw_policy.id }
output "public_ip_id" { value = azurerm_public_ip.data_pip.id }
output "mgmt_public_ip_id" { value = azurerm_public_ip.mgmt_pip.id }
