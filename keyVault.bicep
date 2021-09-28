param resourceNameFormat string
param location string
@secure()
param databasePassword string
param KvSecretsOfficerPrincipalId string
param rbacName string = newGuid()
param secretName string

var role = {
  'Key Vault Secrets Officer': '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: format(resourceNameFormat, 'kv')
  location: location
  properties: {
    createMode: 'default'
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    // This is not for production, allow immediate delete
    enableSoftDelete: false
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
  }
}

resource databasePasswordSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${secretName}'
  properties: {
    contentType: 'The SQL Server dbadmin user\'s password'
    value: databasePassword
  }
}

// FIXME: Latest API version from auto-complete doesn't work in Azure
resource keyVaultRbac 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: rbacName
  scope: keyVault
  properties: {
    principalId: KvSecretsOfficerPrincipalId
    roleDefinitionId: role['Key Vault Secrets Officer']
  }
}

output keyVaultRbacGuid string = keyVaultRbac.name
output keyVaultName string = keyVault.name
