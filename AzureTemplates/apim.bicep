param resourceNameFormat string
param location string

resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: format(resourceNameFormat, 'apim')
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherName: 'Aelterman.Info'
    publisherEmail: 'sven@aelterman.Info'
    virtualNetworkType: 'External'
  }
}
