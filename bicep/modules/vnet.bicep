// Copied module: VNet with optional firewall subnets and IPAM support
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

@description('Optional IPAM Pool resource ID to auto-allocate prefixes for VNet and subnets')
param ipamPoolId string = ''

@description('Optional route table resource ID to attach to the default subnet (aligns with existing AVNM-managed route table). Leave empty to skip.')
param defaultSubnetRouteTableId string = ''

var vnetAddressSpace = empty(ipamPoolId)
  ? { addressPrefixes: [ vnetCidr ] }
  : { ipamPoolPrefixAllocations: [ { pool: { id: ipamPoolId }, numberOfIpAddresses: '65536' } ] }

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: vnetAddressSpace
  }
}

var defaultSubnetBase = empty(ipamPoolId)
  ? { addressPrefixes: [ defaultSubnetCidr ] }
  : { ipamPoolPrefixAllocations: [ { pool: { id: ipamPoolId }, numberOfIpAddresses: '256' } ] }

resource subnet_default 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'default'
  parent: vnet
  properties: union(
    defaultSubnetBase,
    empty(defaultSubnetRouteTableId) ? {} : { routeTable: { id: defaultSubnetRouteTableId } }
  )
}

var afwSubnetPrefix = '10.1.1.0/26'
var afwMgmtSubnetPrefix = '10.1.1.64/26'

var afwSubnetBase = empty(ipamPoolId)
  ? { addressPrefixes: [ afwSubnetPrefix ] }
  : { ipamPoolPrefixAllocations: [ { pool: { id: ipamPoolId }, numberOfIpAddresses: '64' } ] }

var afwMgmtSubnetBase = empty(ipamPoolId)
  ? { addressPrefixes: [ afwMgmtSubnetPrefix ] }
  : { ipamPoolPrefixAllocations: [ { pool: { id: ipamPoolId }, numberOfIpAddresses: '64' } ] }

resource subnet_afw 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (deployFirewall) {
  name: 'AzureFirewallSubnet'
  parent: vnet
  properties: afwSubnetBase
  dependsOn: [ subnet_default ]
}

resource subnet_afw_mgmt 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (deployFirewall) {
  name: 'AzureFirewallManagementSubnet'
  parent: vnet
  properties: afwMgmtSubnetBase
  dependsOn: [ subnet_afw ]
}

output vnetId string = vnet.id
output afwSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallSubnet')
output afwMgmtSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallManagementSubnet')
