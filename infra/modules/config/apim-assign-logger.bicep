param apiManagementServiceName string
param apimanagementApiName string = 'azure-openai-api'
param appInsightsLoggerId string

resource apiManagementService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apiManagementServiceName
}


resource azureOpenAIApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' existing= {
  parent: apiManagementService
  name: apimanagementApiName
}

resource apiMonitoring 'Microsoft.ApiManagement/service/apis/diagnostics@2020-06-01-preview' = {
  name: 'applicationinsights'
  parent: azureOpenAIApi
  properties: {
      alwaysLog: 'allErrors'
      loggerId: appInsightsLoggerId
      metrics: true
      logClientIp: true
      httpCorrelationProtocol: 'W3C'
      verbosity: 'information'
      operationNameFormat: 'Url'
  }
}
