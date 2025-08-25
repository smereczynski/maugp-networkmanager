output "rg_names" { value = keys(azurerm_resource_group.rg) }
output "vnet_ids" { value = { for k, m in module.vnet : k => m.vnet_id } }
output "vm_ids" { value = { for k, m in module.vm : k => m.vm_id } }
