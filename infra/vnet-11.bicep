// Bicep template: Deploy a single VNet (#11) and one VM using the same parameters and modules as main

targetScope = 'subscription'

@description('Deployment location used for resource groups and resources.')
param location string = deployment().location

@description('Optional resource tags applied to created resources where applicable')
param tags object = {}

@description('Optional IPAM Pool resource ID used to auto-allocate prefixes for VNets and subnets (Azure Virtual Network Manager IPAM)')
param ipamPoolId string = ''

@description('Optional route table resource ID to attach to default subnet (pass only if it already exists).')
param defaultSubnetRouteTableId string = ''

// Naming and addressing for #11
var i = 11
var rgName = 'rg-maugp-poc-${i}-plc'
var vnetName = 'vnet-maugp-poc-${i}-plc'
var vnetCidr = '10.${i}.0.0/16'
var subnetDefaultCidr = '10.${i}.0.0/24'

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

// VNet (no firewall for #11)
module vnetDeploy 'modules/vnet.bicep' = {
  name: 'vnet-${i}-deploy'
  scope: resourceGroup(rgName)
  params: {
    location: location
    tags: tags
    vnetName: vnetName
    vnetCidr: vnetCidr
    defaultSubnetCidr: subnetDefaultCidr
    deployFirewall: false
    ipamPoolId: ipamPoolId
    defaultSubnetRouteTableId: defaultSubnetRouteTableId
  }
  dependsOn: [ rg ]
}

// One VM in the default subnet
module vmDeploy 'modules/vm.bicep' = {
  name: 'vm-${i}-deploy'
  scope: resourceGroup(rgName)
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-${i}-plc'
    vnetName: vnetName
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    // PoC password: same as main script for consistency
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnetDeploy ]
}
