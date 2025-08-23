// Module: Create a VNet with default subnet and optional Azure Firewall subnets
targetScope = 'resourceGroup'

@description('Location for resources')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('VNet name')
param vnetName string

@description('VNet CIDR (e.g., 10.1.0.0/16)')
param vnetCidr string

@description('Default subnet CIDR (e.g., 10.1.0.0/24)')
param defaultSubnetCidr string

@description('Whether to deploy Azure Firewall Basic with Basic policy (true for index==1)')
param deployFirewall bool = false

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetCidr ]
    }
  }
}

// Default subnet
resource subnet_default 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'default'
  parent: vnet
  properties: {
    addressPrefixes: [ defaultSubnetCidr ]
  }
}

// Azure Firewall (only when requested)
var afwSubnetPrefix = '10.1.1.0/26'
var afwMgmtSubnetPrefix = '10.1.1.64/26'

resource subnet_afw 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (deployFirewall) {
  name: 'AzureFirewallSubnet'
  parent: vnet
  properties: {
    addressPrefixes: [ afwSubnetPrefix ]
  }
  dependsOn: [
    subnet_default
  ]
}

resource subnet_afw_mgmt 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (deployFirewall) {
  name: 'AzureFirewallManagementSubnet'
  parent: vnet
  properties: {
    addressPrefixes: [ afwMgmtSubnetPrefix ]
  }
  dependsOn: [
    subnet_afw
  ]
}
output vnetId string = vnet.id
output afwSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallSubnet')
output afwMgmtSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallManagementSubnet')
