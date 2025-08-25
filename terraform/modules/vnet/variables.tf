variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "deploy_firewall" { type = bool, default = false }
variable "ipam_pool_id" { type = string }
variable "address_space" { type = list(string) }
variable "default_subnet_cidr" { type = string }
variable "associate_route_table" { type = bool, default = false }
variable "route_table_id" { type = string, default = "" }
