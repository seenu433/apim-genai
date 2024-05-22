targetScope='resourceGroup'

@description('Azure location to which the resources are to be deployed')
param location string = resourceGroup().location

@description('The deployment suffix for the resources to be created.')
param deploymentSuffix string

var appInsightsName = 'appi-${deploymentSuffix}'
var logAnalyticsWorkspaceName = 'log-${deploymentSuffix}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

output appInsightsName string = appInsights.name
output appInsightsId string = appInsights.id
