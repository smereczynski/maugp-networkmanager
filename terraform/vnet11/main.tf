resource "azurerm_resource_group" "rg" {
  name     = "rg-maugp-11"
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source                = "../modules/vnet"
  name                  = "vnet-maugp-11"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = var.tags
  ipam_pool_id          = var.ipam_pool_id
  address_space         = ["10.11.0.0/16"]
  default_subnet_cidr   = "10.11.0.0/24"
  associate_route_table = var.route_table_id != ""
  route_table_id        = var.route_table_id
}

module "vm" {
  source              = "../modules/vm"
  name                = "vm-maugp-11"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet.default_subnet_id
  admin_username      = "michal"
  admin_password      = "P@55w0RD_2025"
  tags                = var.tags
}
