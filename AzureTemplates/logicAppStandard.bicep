param resourceNameFormat string
param location string

param keyVaultName string
param appInsightsName string

param roles object

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource logicAppSvcPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: format(resourceNameFormat, 'plan')
  location: location
  kind: ''
  properties: {
    targetWorkerSizeId: 3
    targetWorkerCount: 1
    maximumElasticWorkerCount: 20
  }
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
}

resource logicAppStorage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'stlogicapp${uniqueString(logicAppSvcPlan.name)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource logicAppSvc 'Microsoft.Web/sites@2021-02-01' = {
  name: format(resourceNameFormat, 'logicapp')
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // TODO: VNet integration?
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          // TODO: EndpointSuffix?
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorage.name};AccountKey=${listKeys(logicAppStorage.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorage.name};AccountKey=${listKeys(logicAppStorage.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'bd46'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
      ]
    }
    serverFarmId: logicAppSvcPlan.id
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

// Grant the Logic App System Assigned Identity access to Key Vault secrets
resource logicAppRbac 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(logicAppSvc.name)
  scope: keyVault
  properties: {
    principalId: logicAppSvc.identity.principalId
    roleDefinitionId: roles['Key Vault Secrets Officer']
  }
}
