targetScope = 'subscription'

// Required parameters
@secure()
@description('The password to be used for the logical Azure SQL server\'s administrator.')
param databasePassword string

param kvSecretsOfficerPrincipalId string
@description('The name of the Key Vault RBAC role assignment (a GUID).')
param kvRbacName string = newGuid()
@description('The Azure region where resources will be deployed.')
param location string = 'eastus2'
@description('The group name of the AAD object that will be the logical SQL server\'s admin')
param sqlAadAdminGroupName string
param sqlAadAdminGroupObjectId string

// Parameters with appropriate default values
@description('Used as a suffix for deployment names.')
param deploymentTime string = utcNow()
@description('Used as a value for the \'date-created\' tag.')
param dateCreatedValue string = utcNow('yyyy-MM-dd')
@description('If deploying multiple workshop instances, increment this number for each instance.')
param sequenceNumber int = 1

var deploymentName = 'IntegrationWorkshop-${deploymentTime}'
var deploymentSequence = format('{0:00}', sequenceNumber)
var resourceNameFormat = '{0}-integration-workshop-${location}-${deploymentSequence}'
var secretName = 'SqlDatabasePassword'
var kvResourceNameFormat = '{0}-int-ws-${location}-${deploymentSequence}'

resource workshopResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: format(resourceNameFormat, 'rg')
  location: location
  tags: {
    // TODO: This value will be overwritten when redeploying
    'date-created': dateCreatedValue
    purpose: 'workshop'
    lifetime: 'short'
  }
}

module rolesModule 'roles.bicep' = {
  name: '${deploymentName}-Roles'
  scope: workshopResourceGroup
}

module keyVaultModule 'keyVault.bicep' = {
  name: '${deploymentName}-KV'
  scope: workshopResourceGroup
  params: {
    // Key Vault has a maximum of 24 characters
    resourceNameFormat: kvResourceNameFormat
    location: location
    databasePassword: databasePassword
    KvSecretsOfficerPrincipalId: kvSecretsOfficerPrincipalId
    rbacName: kvRbacName
    secretName: secretName
  }
}

module sqlModule 'sql.bicep' = {
  name: '${deploymentName}-SQL'
  scope: workshopResourceGroup
  params: {
    resourceNameFormat: resourceNameFormat
    location: location
    databasePassword: databasePassword
    sqlAadAdminGroupName: sqlAadAdminGroupName
    sqlAadAdminGroupObjectId: sqlAadAdminGroupObjectId
  }
}

module apimModule 'apim.bicep' = {
  name: '${deploymentName}-APIM'
  scope: workshopResourceGroup
  params: {
    resourceNameFormat: resourceNameFormat
    location: location
  }
}

module logAnalyticsModule 'logAnalytics.bicep' = {
  name: '${deploymentName}-LogAnalytics'
  scope: workshopResourceGroup
  params: {
    resourceNameFormat: resourceNameFormat
    location: location
  }
}

module sqlLogicAppsModule 'logicApps.bicep' = {
  name: '${deploymentName}-SqlLogicApp'
  scope: workshopResourceGroup
  params: {
    resourceNameFormat: '{0}-{1}-workshop-${location}-${deploymentSequence}'
    location: location
    workspaceId: logAnalyticsModule.outputs.workspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    logicAppName: 'sql'
    definition: 'apiFromSql'
    roles: rolesModule.outputs.roles
  }
}

module emptyLogicAppsModule 'logicApps.bicep' = {
  name: '${deploymentName}-EmptyLogicApp'
  scope: workshopResourceGroup
  params: {
    resourceNameFormat: '{0}-{1}-workshop-${location}-${deploymentSequence}'
    location: location
    workspaceId: logAnalyticsModule.outputs.workspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    logicAppName: 'empty'
    definition: 'empty'
    roles: rolesModule.outputs.roles
  }
}

module standardLogicAppsModule 'logicAppStandard.bicep' = {
  name: '${deploymentName}-StandardLogicApp'
  scope: workshopResourceGroup
  params: {
    appInsightsName: appInsightsModule.outputs.appInsightsName
    location: location
    keyVaultName: keyVaultModule.outputs.keyVaultName
    resourceNameFormat: resourceNameFormat
    roles: rolesModule.outputs.roles
  }
}

module appInsightsModule 'appInsights.bicep' = {
  name: '${deploymentName}-AI'
  scope: workshopResourceGroup
  params: {
    resourceNameFormat: resourceNameFormat
    location: location
    workspaceId: logAnalyticsModule.outputs.workspaceId
  }
}
