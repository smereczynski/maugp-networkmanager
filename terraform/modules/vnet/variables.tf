variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "deploy_firewall" {
  type    = bool
  default = false
}

variable "ipam_pool_id" {
  type = string
}

variable "ipam_vnet_number_of_ip_addresses" {
  type    = number
  default = 65536
  # Default corresponds to a /16 allocation size
}

variable "address_space" {
  type = list(string)
}

variable "default_subnet_cidr" {
  type = string
}

variable "ipam_subnet_number_of_ip_addresses" {
  type    = number
  default = 256
  # Default corresponds to a /24 allocation size
}

variable "ipam_firewall_subnet_number_of_ip_addresses" {
  type    = number
  default = 64
  # Default corresponds to a /26 allocation size for AzureFirewallSubnet
}

variable "ipam_firewall_mgmt_subnet_number_of_ip_addresses" {
  type    = number
  default = 64
  # Default corresponds to a /26 allocation size for AzureFirewallManagementSubnet
}

variable "associate_route_table" {
  type    = bool
  default = false
}

variable "route_table_id" {
  type    = string
  default = ""
}
