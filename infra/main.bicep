// Bicep template: Deploy 10 VNets across separate resource groups.
// VNet/subnet address plans follow 10.<i>.0.0/16 and default subnet 10.<i>.0.0/24 for i in [1..10].
// In vnet-maugp-poc-1-plc also deploy Azure Firewall Basic with a Basic policy and required subnets.

targetScope = 'subscription'

@description('Deployment location used for resource groups and resources.')
param location string = deployment().location

@description('Optional resource tags applied to created resources where applicable')
param tags object = {}

@description('Optional IPAM Pool resource ID used to auto-allocate prefixes for VNets and subnets (Azure Virtual Network Manager IPAM)')
param ipamPoolId string = ''

@description('Optional route table resource ID to attach to default subnets when present (only pass if it already exists).')
param defaultSubnetRouteTableId string = ''

// Sequence 1..10 (range(start, count) -> 10 elements: 1..10)
var indices = range(1, 10)

// Derived naming and addressing per index
var vnetsPlan = [for i in indices: {
  i: i
  rgName: 'rg-maugp-poc-${i}-plc'
  vnetName: 'vnet-maugp-poc-${i}-plc'
  vnetCidr: '10.${i}.0.0/16'
  subnetDefaultCidr: '10.${i}.0.0/24'
}]

// Create resource groups
resource rgs 'Microsoft.Resources/resourceGroups@2024-03-01' = [for (v, idx) in vnetsPlan: {
  name: v.rgName
  location: location
  tags: tags
}]

// Create VNets in each resource group
// VNet deployments via module per RG to avoid cross-loop indexing issues
module vnetDeploy 'modules/vnet.bicep' = [for (v, idx) in vnetsPlan: {
  name: 'vnet-${v.i}-deploy'
  scope: resourceGroup(v.rgName)
  params: {
    location: location
    tags: tags
    vnetName: v.vnetName
    vnetCidr: v.vnetCidr
    defaultSubnetCidr: v.subnetDefaultCidr
    deployFirewall: v.i == 1
  ipamPoolId: ipamPoolId
  // Attach a route table only when explicitly provided
  defaultSubnetRouteTableId: defaultSubnetRouteTableId
  }
  dependsOn: [ rgs[idx] ]
}]

// Deploy Azure Firewall stack via dedicated module only for the first VNet
module firewallDeploy 'modules/firewall.bicep' = [for (v, idx) in vnetsPlan: if (v.i == 1) {
  name: 'afw-${v.i}-deploy'
  scope: resourceGroup(v.rgName)
  params: {
    location: location
    tags: tags
    baseName: v.vnetName
    afwSubnetId: vnetDeploy[idx].outputs.afwSubnetId
    afwMgmtSubnetId: vnetDeploy[idx].outputs.afwMgmtSubnetId
  }
  dependsOn: [ vnetDeploy[idx] ]
}]

// Create one VM per resource group and VNet
module vmDeploy 'modules/vm.bicep' = [for (v, idx) in vnetsPlan: {
  name: 'vm-${v.i}-deploy'
  scope: resourceGroup(v.rgName)
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-${v.i}-plc'
    vnetName: v.vnetName
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    // PoC password: if this ends up on a slide, let's pretend it's a hash ;)
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnetDeploy[idx] ]
}]
