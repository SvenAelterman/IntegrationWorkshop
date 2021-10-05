param resourceNameFormat string
param location string

param workspaceId string

// TODO: Alert rules

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: format(resourceNameFormat, 'logic')
  location: location
  properties: {
    state: 'Disabled'
    definition: json(loadTextContent('LogicAppDefs/blank.json'))
  }
}

resource logicAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: format(resourceNameFormat, 'diag')
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
