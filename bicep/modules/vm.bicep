// Copied module: Create a Linux VM (Ubuntu 22.04) in an existing VNet/subnet without a public IP
targetScope = 'resourceGroup'

@description('Location for resources')
param location string
@description('Tags to apply to resources')
param tags object = {}
@description('VM name')
param vmName string
@description('Existing VNet name')
param vnetName string
@description('Existing subnet name')
param subnetName string = 'default'
@description('VM size')
param vmSize string = 'Standard_B2ats_v2'
@description('Admin username')
param adminUsername string = 'michal'
@description('Admin password for VM (PoC only)')
@secure()
param adminPassword string

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${vmName}'
  location: location
  tags: tags
  properties: { ipConfigurations: [ { name: 'ipconfig1', properties: { privateIPAllocationMethod: 'Dynamic', subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName) } } } ] }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: { computerName: vmName, adminUsername: adminUsername, adminPassword: adminPassword, linuxConfiguration: { disablePasswordAuthentication: false } }
    storageProfile: { imageReference: { publisher: 'Canonical', offer: '0001-com-ubuntu-server-jammy', sku: '22_04-lts-gen2', version: 'latest' }, osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'StandardSSD_LRS' }, caching: 'ReadWrite' } }
    networkProfile: { networkInterfaces: [ { id: nic.id, properties: { primary: true } } ] }
  }
}

output vmId string = vm.id
