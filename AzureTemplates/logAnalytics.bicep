param resourceNameFormat string
param location string

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: format(resourceNameFormat, 'log')
  location: location
  properties: {}
}

output workspaceId string = workspace.id
