locals {
  rg_prefix = "rg-maugp"
}

# 10 resource groups
resource "azurerm_resource_group" "rg" {
  for_each = toset([for i in range(1, 11) : format("%s-%02d", local.rg_prefix, i)])
  name     = each.value
  location = var.location
  tags     = var.tags
}

# VNets for each RG
module "vnet" {
  for_each = azurerm_resource_group.rg
  source   = "../modules/vnet"

  name                = replace(each.value.name, "rg-", "vnet-")
  location            = each.value.location
  resource_group_name = each.value.name
  tags                = each.value.tags

  ipam_pool_id        = var.ipam_pool_id
  address_space       = ["10.${tonumber(split("-", each.value.name)[length(split("-", each.value.name)) - 1])}.0.0/16"]
  default_subnet_cidr = "10.0.0.0/24" # used only when ipam_pool_id is empty
  associate_route_table = var.route_table_id != ""
  route_table_id        = var.route_table_id
  deploy_firewall       = each.key == "${local.rg_prefix}-01"
}

# Firewall only for index 1
module "firewall" {
  source              = "../modules/firewall"
  count               = 1
  name                = "maugp-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg["${local.rg_prefix}-01"].name
  tags                = var.tags
  vnet_name           = module.vnet["${local.rg_prefix}-01"].name
  afw_subnet_id       = module.vnet["${local.rg_prefix}-01"].afw_subnet_id
  afw_mgmt_subnet_id  = module.vnet["${local.rg_prefix}-01"].afw_mgmt_subnet_id
}

# One VM per RG (in default subnet)
module "vm" {
  for_each            = azurerm_resource_group.rg
  source              = "../modules/vm"
  name                = replace(each.value.name, "rg-", "vm-")
  location            = each.value.location
  resource_group_name = each.value.name
  subnet_id           = module.vnet[each.key].default_subnet_id
  admin_username      = "michal"
  admin_password      = "P@55w0RD_2025"
  tags                = each.value.tags
}
