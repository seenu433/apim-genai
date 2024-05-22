@description('The deployment suffix for the resources to be created.')
param deploymentSuffix string

@description('The email address of the publisher of the APIM resource.')
@minLength(1)
param publisherEmail string = 'apim@contoso.com'

@description('Company name of the publisher of the APIM resource.')
@minLength(1)
param publisherName string = 'Contoso'

@description('The pricing tier of the APIM resource.')
param skuName string = 'Developer'

@description('The instance size of the APIM resource.')
param capacity int = 1

@description('Location for Azure resources.')
param location string = resourceGroup().location

param appInsightsName string

var apimName = 'apim-${deploymentSuffix}'
var apimIdentityName = 'identity-${deploymentSuffix}'
var apimIdentityNameValue = 'apim-identity'

resource apimIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: apimIdentityName
  location: location
}

resource apim 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: apimName
  location: location
  sku:{
    capacity: capacity
    name: skuName
  }
  identity: {
    type:'UserAssigned'
    userAssignedIdentities: {
      '${apimIdentity.id}': {}
    }
  }
  properties:{
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource apim_appInsightsLogger_resource 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
  parent: apim
  name: appInsightsName
  properties: {
    loggerType: 'applicationInsights'
    resourceId: applicationInsights.id
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
    }
  }
}

resource apimOpenaiApiUamiNamedValue 'Microsoft.ApiManagement/service/namedValues@2022-08-01' = {
  name: apimIdentityNameValue
  parent: apim
  properties: {
    displayName: apimIdentityNameValue
    secret: true
    value: apimIdentity.properties.clientId
  }
}

output apimIdentityName string = apimIdentity.name
output apimName string = apim.name
output appInsightsLoggerId string = apim_appInsightsLogger_resource.id
