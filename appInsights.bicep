param resourceNameFormat string
param location string

param workspaceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: format(resourceNameFormat, 'appi')
  location: location
  kind: 'workspace'
  properties: {
    WorkspaceResourceId: workspaceId
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
  }
}

output appInsightsName string = appInsights.name
