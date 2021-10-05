[CmdletBinding()]
param (
	[Parameter()]
	[string]$Location = "eastus2",
	[Parameter()]
	[string]$sqlAadAdminGroupName = "AllAzSqlDbAdmins",
	[Parameter()]
	[string]$sqlAadAdminGroupObjectId
)
# TODO: Add parameter for deploying sample code and db

[string]$Principal = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id).Id
Write-Verbose "'$Principal' will be given the role 'Key Vault Secrets Officer' on Key Vault."

if ($KvRbacName.Length -lt 1) {
	# TODO: Attempt to retrieve existing role assignment in case variable value is lost (between sessions...)
	[string]$KvRbacName = New-Guid
	Write-Verbose "Created new GUID '$KvRbacName' for Key Vault role assignment"
}

if ($sqlAadAdminGroupObjectId.Length -lt 1) {
	$sqlAadAdminGroupObjectId = (Get-AzADGroup -DisplayName $sqlAadAdminGroupName).Id
}

# TODO: Define workshop participants for RBAC to resource group

# TODO: Remove this and autogenerate in bicep?
[securestring]$DatabasePassword = (Get-Credential -UserName "dbadmin" -Message "Enter the password for the Azure SQL server administrator.").Password

# Using a parameters object avoids the issue that "location" is specified twice as a parameter
$Parameters = @{
	databasePassword            = $DatabasePassword
	kvSecretsOfficerPrincipalId = $Principal
	location                    = $Location
	kvRbacName                  = $KvRbacName
	sqlAadAdminGroupName        = $sqlAadAdminGroupName
	sqlAadAdminGroupObjectId    = $sqlAadAdminGroupObjectId
}

# LATER: Get current IP for SQL FW allow list

$DeploymentResult = New-AzDeployment -Location $Location -TemplateFile .\main.bicep `
	-TemplateParameterObject $Parameters `
	-Name "IntegrationWorkshopp-$(Get-Date -AsUTC -Format "yyyyMMddThhmmssZ")"

if ($DeploymentResult.Outputs) {
	# Capture the name of the Key Vault Secrets Officer role assignment in case it's a new GUID
	$KvRbacName = $DeploymentResult.Outputs['keyVaultRbacGuid'].Value
	# Latest value: 8883ea72-2878-4648-9bca-eab1ccdcc82f
}

Write-Host "Deployment complete with status '$($DeploymentResult.ProvisioningState)'"