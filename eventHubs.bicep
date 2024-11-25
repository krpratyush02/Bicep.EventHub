// @description('Short name for the environment, e.g., "dev", "prod".')
// param environmentShortname string = 'dev'
@description('Event Hub Name')
param eventHubName string

@description('Event Hub Location')
param location string

@description('Required Tags')
param tags object

@description('SKU for Event Hub')
@allowed([
  'Standard'
  'Premium'
])
param skuName string

@description('Event Hubs throughput units')
@minValue(1)
param capacity int

@description('Enable local authentication')
param enableLocalAuth bool

@description('Enable auto inflate')
param autoInflate bool

@description('Zone Redundancy for Event Hub')
param zoneRedundancy bool

@description('Subnet IDs for adding service endpoin')
param serviceEndpointSubnetIds array

@description('Public Network Access. "Enabled" or "Disabled"')
var publicNetworkAccess = empty(serviceEndpointSubnetIds) ? 'Disabled' : 'Enabled'

var virtualNetworkRules = [for subnetId in serviceEndpointSubnetIds: {
  ignoreMissingVnetServiceEndpoint: true
  subnet: {
    id: subnetId
  }
}]

resource eventHub 'Microsoft.EventHub/namespaces@2024-01-01' = {
name: eventHubName
location: location
tags: tags
sku: {
  name: skuName
  tier: skuName
  capacity: capacity
}
identity: {
  type: 'SystemAssigned'
}
properties: {
  disableLocalAuth: !(enableLocalAuth)
  isAutoInflateEnabled: autoInflate
  minimumTlsVersion: '1.2'
  publicNetworkAccess: publicNetworkAccess
  zoneRedundant: zoneRedundancy
  }
}

resource VnetRule 'Microsoft.EventHub/namespaces/networkRuleSets@2024-01-01' = if(!(empty(serviceEndpointSubnetIds))) {
  name: 'default'
  parent: eventHub
  properties: {
    defaultAction: 'Deny'
    publicNetworkAccess: publicNetworkAccess
    trustedServiceAccessEnabled: true
    ipRules: []
    virtualNetworkRules: virtualNetworkRules
  }
}

output eventHubId string = eventHub.id
