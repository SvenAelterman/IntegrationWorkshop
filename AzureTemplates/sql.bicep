param resourceNameFormat string
param location string
@secure()
param databasePassword string
param sqlAadAdminGroupName string
param sqlAadAdminGroupObjectId string

resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: format(resourceNameFormat, 'sql')
  location: location
  properties: {
    administratorLogin: 'dbadmin'
    administratorLoginPassword: databasePassword
    minimalTlsVersion: '1.2'
  }
}

resource sqlServerAad 'Microsoft.Sql/servers/administrators@2021-02-01-preview' = {
  name: '${sqlServer.name}/ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: sqlAadAdminGroupName
    sid: sqlAadAdminGroupObjectId
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: '${sqlServer.name}/WorkshopDB'
  location: location
  sku: {
    name: 'S1'
  }
  properties: {
    sampleName: 'AdventureWorksLT'
  }
}

output sqlServerUrl string = sqlServer.properties.fullyQualifiedDomainName
output sqlUserName string = sqlServer.properties.administratorLogin
