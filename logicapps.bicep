param resourceNameFormat string
param location string

param workspaceId string
param keyVaultName string
param logicAppName string = 'blank'
param definition string

// TODO: Alert rules

var definitionFiles = {
  'blank': 'LogicAppDefs/blank.json'
  'apiFromSql': 'LogicAppDefs/apiFromSql.json'
}

var role = {
  // Azure ID of the Key Vault Secrets Officer role ID
  'Key Vault Secrets Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
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
    roleDefinitionId: role['Key Vault Secrets Officer']
  }
}
