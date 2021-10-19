param resourceNameFormat string
param location string
@secure()
param KvSecretsOfficerPrincipalId string

param roles object

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

// FIXME: Latest API version from auto-complete doesn't work in Azure
resource keyVaultRbac 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(KvSecretsOfficerPrincipalId)
  scope: keyVault
  properties: {
    principalId: KvSecretsOfficerPrincipalId
    roleDefinitionId: roles['Key Vault Secrets Officer']
  }
}

output keyVaultName string = keyVault.name
