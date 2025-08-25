// Copied module: Azure Firewall Basic with Basic policy and default rule collection group
targetScope = 'resourceGroup'

@description('Location for resources')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('Base name (usually vnetName) to suffix resource names consistently')
param baseName string

@description('AzureFirewallSubnet resource ID')
param afwSubnetId string

@description('AzureFirewallManagementSubnet resource ID')
param afwMgmtSubnetId string

resource pip_afw 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-azfw-${baseName}'
  location: location
  sku: { name: 'Standard', tier: 'Regional' }
  properties: { publicIPAllocationMethod: 'Static', ddosSettings: { protectionMode: 'VirtualNetworkInherited' } }
  tags: tags
}

resource pip_afw_mgmt 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-azfw-mgmt-${baseName}'
  location: location
  sku: { name: 'Standard', tier: 'Regional' }
  properties: { publicIPAllocationMethod: 'Static', ddosSettings: { protectionMode: 'VirtualNetworkInherited' } }
  tags: tags
}

resource afw_policy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'afwp-basic-${baseName}'
  location: location
  tags: tags
  properties: { sku: { tier: 'Basic' }, threatIntelMode: 'Alert' }
}

resource afw_policy_rcg 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  name: 'rcg-default'
  parent: afw_policy
  properties: {
    priority: 100
    ruleCollections: [
      {
        name: 'allowall'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: { type: 'Allow' }
        priority: 100
        rules: [ { name: 'allowall-l3', ruleType: 'NetworkRule', ipProtocols: [ 'Any' ], sourceAddresses: [ '*' ], destinationAddresses: [ '*' ], destinationPorts: [ '*' ] } ]
      }
    ]
  }
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: 'afw-${baseName}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'AZFW_VNet', tier: 'Basic' }
    threatIntelMode: 'Alert'
    firewallPolicy: { id: afw_policy.id }
    ipConfigurations: [ { name: 'azureFirewallIpConfig', properties: { subnet: { id: afwSubnetId }, publicIPAddress: { id: pip_afw.id } } } ]
    managementIpConfiguration: { name: 'azureFirewallMgmtIpConfig', properties: { subnet: { id: afwMgmtSubnetId }, publicIPAddress: { id: pip_afw_mgmt.id } } }
  }
}

output firewallId string = azureFirewall.id
output firewallPolicyId string = afw_policy.id
