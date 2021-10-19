var roles = {
  // Azure ID of the Key Vault Secrets Officer role ID
  'Key Vault Secrets Officer': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
}

output roles object = roles
