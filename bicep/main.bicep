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

// Create VNets explicitly in sequence to avoid IPAM throttling
module vnet1 './modules/vnet.bicep' = {
  name: 'vnet-1-deploy'
  scope: resourceGroup('rg-maugp-poc-1-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-1-plc'
    deployFirewall: true
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[0] ]
}

module vnet2 './modules/vnet.bicep' = {
  name: 'vnet-2-deploy'
  scope: resourceGroup('rg-maugp-poc-2-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-2-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[1], vnet1 ]
}

module vnet3 './modules/vnet.bicep' = {
  name: 'vnet-3-deploy'
  scope: resourceGroup('rg-maugp-poc-3-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-3-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[2], vnet2 ]
}

module vnet4 './modules/vnet.bicep' = {
  name: 'vnet-4-deploy'
  scope: resourceGroup('rg-maugp-poc-4-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-4-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[3], vnet3 ]
}

module vnet5 './modules/vnet.bicep' = {
  name: 'vnet-5-deploy'
  scope: resourceGroup('rg-maugp-poc-5-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-5-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[4], vnet4 ]
}

module vnet6 './modules/vnet.bicep' = {
  name: 'vnet-6-deploy'
  scope: resourceGroup('rg-maugp-poc-6-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-6-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[5], vnet5 ]
}

module vnet7 './modules/vnet.bicep' = {
  name: 'vnet-7-deploy'
  scope: resourceGroup('rg-maugp-poc-7-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-7-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[6], vnet6 ]
}

module vnet8 './modules/vnet.bicep' = {
  name: 'vnet-8-deploy'
  scope: resourceGroup('rg-maugp-poc-8-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-8-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[7], vnet7 ]
}

module vnet9 './modules/vnet.bicep' = {
  name: 'vnet-9-deploy'
  scope: resourceGroup('rg-maugp-poc-9-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-9-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[8], vnet8 ]
}

module vnet10 './modules/vnet.bicep' = {
  name: 'vnet-10-deploy'
  scope: resourceGroup('rg-maugp-poc-10-plc')
  params: {
    location: location
    tags: tags
    vnetName: 'vnet-maugp-poc-10-plc'
    deployFirewall: false
    ipamPoolId: ipamPoolId
  }
  dependsOn: [ rgs[9], vnet9 ]
}

// Deploy Azure Firewall stack via dedicated module only for the first VNet
module firewallDeploy './modules/firewall.bicep' = {
  name: 'afw-1-deploy'
  scope: resourceGroup('rg-maugp-poc-1-plc')
  params: {
    location: location
    tags: tags
    baseName: 'vnet-maugp-poc-1-plc'
    afwSubnetId: vnet1.outputs.afwSubnetId
    afwMgmtSubnetId: vnet1.outputs.afwMgmtSubnetId
  }
}

// Create one VM per resource group and VNet
module vm1 './modules/vm.bicep' = {
  name: 'vm-1-deploy'
  scope: resourceGroup('rg-maugp-poc-1-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-1-plc'
    vnetName: 'vnet-maugp-poc-1-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet1 ]
}

module vm2 './modules/vm.bicep' = {
  name: 'vm-2-deploy'
  scope: resourceGroup('rg-maugp-poc-2-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-2-plc'
    vnetName: 'vnet-maugp-poc-2-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet2 ]
}

module vm3 './modules/vm.bicep' = {
  name: 'vm-3-deploy'
  scope: resourceGroup('rg-maugp-poc-3-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-3-plc'
    vnetName: 'vnet-maugp-poc-3-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet3 ]
}

module vm4 './modules/vm.bicep' = {
  name: 'vm-4-deploy'
  scope: resourceGroup('rg-maugp-poc-4-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-4-plc'
    vnetName: 'vnet-maugp-poc-4-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet4 ]
}

module vm5 './modules/vm.bicep' = {
  name: 'vm-5-deploy'
  scope: resourceGroup('rg-maugp-poc-5-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-5-plc'
    vnetName: 'vnet-maugp-poc-5-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet5 ]
}

module vm6 './modules/vm.bicep' = {
  name: 'vm-6-deploy'
  scope: resourceGroup('rg-maugp-poc-6-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-6-plc'
    vnetName: 'vnet-maugp-poc-6-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet6 ]
}

module vm7 './modules/vm.bicep' = {
  name: 'vm-7-deploy'
  scope: resourceGroup('rg-maugp-poc-7-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-7-plc'
    vnetName: 'vnet-maugp-poc-7-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet7 ]
}

module vm8 './modules/vm.bicep' = {
  name: 'vm-8-deploy'
  scope: resourceGroup('rg-maugp-poc-8-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-8-plc'
    vnetName: 'vnet-maugp-poc-8-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet8 ]
}

module vm9 './modules/vm.bicep' = {
  name: 'vm-9-deploy'
  scope: resourceGroup('rg-maugp-poc-9-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-9-plc'
    vnetName: 'vnet-maugp-poc-9-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet9 ]
}

module vm10 './modules/vm.bicep' = {
  name: 'vm-10-deploy'
  scope: resourceGroup('rg-maugp-poc-10-plc')
  params: {
    location: location
    tags: tags
    vmName: 'vm-maugp-poc-10-plc'
    vnetName: 'vnet-maugp-poc-10-plc'
    subnetName: 'default'
    vmSize: 'Standard_B2ats_v2'
    adminUsername: 'michal'
    adminPassword: 'P@55w0RD_2025'
  }
  dependsOn: [ vnet10 ]
}
