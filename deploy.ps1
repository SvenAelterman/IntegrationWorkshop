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
	#kvRbacName                  = $KvRbacName
	sqlAadAdminGroupName        = $sqlAadAdminGroupName
	sqlAadAdminGroupObjectId    = $sqlAadAdminGroupObjectId
}

# LATER: Get current IP for SQL FW allow list

$DeploymentResult = New-AzDeployment -Location $Location -TemplateFile .\main.bicep `
	-TemplateParameterObject $Parameters `
	-Name "IntegrationWorkshopp-$(Get-Date -AsUTC -Format "yyyyMMddThhmmssZ")"

Write-Host "Deployment complete with status '$($DeploymentResult.ProvisioningState)'"