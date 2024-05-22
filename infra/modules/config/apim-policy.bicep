param apiManagementServiceName string
param apimanagementApiName string = 'azure-openai-api'

resource apiManagementService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagementServiceName
}

resource azureOpenAIApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' existing = {
  parent: apiManagementService
  name: apimanagementApiName
}

resource azureOpenAIApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: azureOpenAIApi
  name: 'policy'
  properties: {
    value: loadTextContent('./policies/genai-policy.xml')
    format: 'rawxml'
  }
}
