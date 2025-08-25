variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "vnet_name" { type = string }
variable "afw_subnet_id" { type = string }
variable "afw_mgmt_subnet_id" { type = string }
