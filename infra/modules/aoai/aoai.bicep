@description('The deployment suffix for the resources to be created.')
@minLength(1)
param deploymentSuffix string

@description('Name of the resource.')
@minLength(1)
param deploymentName string

@description('Location for Azure resources.')
param location string = resourceGroup().location

param apimIdentityName string

param modelDeploymentName string = 'chat'

@description('The model name to be deployed. The model name can be found in the OpenAI portal.')
param modelName string = 'gpt-35-turbo'

@description('The model version to be deployed. At the time of writing this is the latest version is eastus2.')
param modelVersion string = '0613'

var name = '${deploymentName}-${deploymentSuffix}'
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  kind: 'OpenAI'
  properties: {
    customSubDomainName: toLower(name)
  }
  sku: {
    name: 'S0'
  }
}

resource cognitiveServicesOpenAIUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
  scope: tenant()
}

resource apimIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: apimIdentityName
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cognitiveServices.id, apimIdentity.id, cognitiveServicesOpenAIUser.id)
  scope: cognitiveServices
  properties: {
    principalId: apimIdentity.properties.principalId
    roleDefinitionId: cognitiveServicesOpenAIUser.id
    principalType: 'ServicePrincipal'
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: modelDeploymentName
  parent: cognitiveServices 
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    raiPolicyName: 'Microsoft.Default'
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

output openAiEndpointUri string = '${cognitiveServices.properties.endpoint}openai/'
