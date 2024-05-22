targetScope = 'subscription'

param resourceGroupName string

@description('The deployment suffix for the resources to be created.')
param deploymentIdentifier string = ''

param location string = deployment().location

var aoaiInstances  = {
  aoaione: {
    name: 'aoai-1'
    location: 'eastus'
  }
  aoaitwo: {
    name: 'aoai-2'
    location: 'eastus2'
  }
  aoaithree: {
    name: 'aoai-3'
    location: 'canadaeast'
  }
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

@description('The deployment suffix for the resources to be created.')
var deploymentSuffix  = deploymentIdentifier=='' ? '${uniqueString(resourceGroup.id)}' : deploymentIdentifier 

module appInsights './modules/appinsights/appinsights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    location: location
    deploymentSuffix: deploymentSuffix
  }
}

module apiManagement './modules/apim/apim.bicep' = {
  name: 'apiManagement'
  scope: resourceGroup
  params: {
    location: location
    deploymentSuffix: deploymentSuffix
    appInsightsName: appInsights.outputs.appInsightsName
  }
}

module aoai './modules/aoai/aoai.bicep' = [for (config, i) in items(aoaiInstances): {
  name: config.value.name
  scope: resourceGroup
  params: {
    location: config.value.location
    deploymentName: config.value.name
    deploymentSuffix: deploymentSuffix
    apimIdentityName: apiManagement.outputs.apimIdentityName
  }
}]

module apiImport './modules/config/apim-import.bicep' = {
  name: 'apiImport'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagement.outputs.apimName
  }
}

module apiBackend './modules/config/apim-backend.bicep' = {
  name: 'apiBackend'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagement.outputs.apimName
    backendUris: [for i in range(0, length(aoaiInstances)): aoai[i].outputs.openAiEndpointUri]
  }  
}

module apiLBPool './modules/config/apim-lb-pool.bicep' = {
  name: 'apimLBPool'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagement.outputs.apimName
    backends: apiBackend.outputs.backendNames
  }  
  dependsOn: [
    apiBackend
  ]
}

module apiPolicy './modules/config/apim-policy.bicep' = {
  name: 'apiPolicy'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagement.outputs.apimName
  }
  dependsOn: [
    apiImport
    apiLBPool
  ]
}

module apiLogger './modules/config/apim-assign-logger.bicep' = {
  name: 'apiLogger'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagement.outputs.apimName
    appInsightsLoggerId: apiManagement.outputs.appInsightsLoggerId
  }
  dependsOn: [
    apiPolicy
  ]
}

