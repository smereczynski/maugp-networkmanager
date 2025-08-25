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

@description('Optional IPAM Pool resource ID to auto-allocate prefixes for VNet and subnets')
param ipamPoolId string = ''

@description('Optional route table resource ID to attach to the default subnet (aligns with existing AVNM-managed route table). Leave empty to skip.')
param defaultSubnetRouteTableId string = ''

// Mutually exclusive address space: IPAM vs static prefixes
var vnetAddressSpace = empty(ipamPoolId)
  ? {
      addressPrefixes: [ vnetCidr ]
    }
  : {
      ipamPoolPrefixAllocations: [
        {
          pool: {
            id: ipamPoolId
          }
          // /16 -> 65536 addresses
          numberOfIpAddresses: '65536'
        }
      ]
    }

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    // Use either IPAM or addressPrefixes exclusively (cannot mix in the same payload)
    addressSpace: vnetAddressSpace
  }
}

// Default subnet base properties (IPAM vs static)
var defaultSubnetBase = empty(ipamPoolId)
  ? { addressPrefixes: [ defaultSubnetCidr ] }
  : {
      ipamPoolPrefixAllocations: [
        {
          pool: {
            id: ipamPoolId
          }
          // /24 -> 256 addresses
          numberOfIpAddresses: '256'
        }
      ]
    }

// Default subnet
resource subnet_default 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'default'
  parent: vnet
  // Merge base with optional route table (entire properties object)
  properties: union(
    defaultSubnetBase,
    empty(defaultSubnetRouteTableId) ? {} : {
      routeTable: {
        id: defaultSubnetRouteTableId
      }
    }
  )
}

// Azure Firewall (only when requested)
var afwSubnetPrefix = '10.1.1.0/26'
var afwMgmtSubnetPrefix = '10.1.1.64/26'

// Firewall subnets base properties (IPAM vs static)
var afwSubnetBase = empty(ipamPoolId)
  ? { addressPrefixes: [ afwSubnetPrefix ] }
  : {
      ipamPoolPrefixAllocations: [
        {
          pool: {
            id: ipamPoolId
          }
          // /26 -> 64 addresses
          numberOfIpAddresses: '64'
        }
      ]
    }

var afwMgmtSubnetBase = empty(ipamPoolId)
  ? { addressPrefixes: [ afwMgmtSubnetPrefix ] }
  : {
      ipamPoolPrefixAllocations: [
        {
          pool: {
            id: ipamPoolId
          }
          // /26 -> 64 addresses
          numberOfIpAddresses: '64'
        }
      ]
    }

resource subnet_afw 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (deployFirewall) {
  name: 'AzureFirewallSubnet'
  parent: vnet
  // Use either IPAM or addressPrefixes exclusively (entire properties object)
  properties: afwSubnetBase
  dependsOn: [
    subnet_default
  ]
}

resource subnet_afw_mgmt 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (deployFirewall) {
  name: 'AzureFirewallManagementSubnet'
  parent: vnet
  // Use either IPAM or addressPrefixes exclusively (entire properties object)
  properties: afwMgmtSubnetBase
  dependsOn: [
    subnet_afw
  ]
}
output vnetId string = vnet.id
output afwSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallSubnet')
output afwMgmtSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallManagementSubnet')
