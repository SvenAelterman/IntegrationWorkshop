@secure()
param databasePassword string
param databaseUser string

param sqlFqdn string

param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource dbConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVaultName}/sqlConnectionString'
  properties: {
    contentType: 'Database connection string using SQL authentication.'
    value: 'Server=tcp:${sqlFqdn},1433;Initial Catalog=WorkshopDB;Persist Security Info=False;User ID=${databaseUser};Password=${databasePassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

resource databasePasswordSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/SqlDatabasePassword'
  properties: {
    contentType: 'The SQL Server dbadmin user\'s password'
    value: databasePassword
  }
}
