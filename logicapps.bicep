param resourceNameFormat string
param location string

param workspaceId string
param keyVaultName string
param logicAppName string = 'blank'
param definition string

param roles object

// TODO: Alert rules

var definitionFiles = {
  'blank': 'LogicAppDefs/blank.json'
  'apiFromSql': 'LogicAppDefs/apiFromSql.json'
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: format(resourceNameFormat, 'logic', logicAppName)
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: (definition == 'blank') ? json(loadTextContent(definitionFiles['blank'])) : json(loadTextContent(definitionFiles['apiFromSql']))
  }
}

resource logicAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: format(resourceNameFormat, 'diag', logicAppName)
  scope: logicApp
  properties: {
    storageAccountId: json('null')
    serviceBusRuleId: json('null')
    workspaceId: workspaceId
    eventHubAuthorizationRuleId: json('null')
    metrics: [
      {
        timeGrain: 'AllMetrics'
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

// Grant the Logic App System Assigned Identity access to Key Vault secrets
resource logicAppRbac 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(logicApp.name)
  scope: keyVault
  properties: {
    principalId: logicApp.identity.principalId
    roleDefinitionId: roles['Key Vault Secrets Officer']
  }
}
