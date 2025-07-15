targetScope = 'subscription'

param principalId string

@description('https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: subscription()
  name: guid(subscription().id, principalId, contributorRoleDefinition.id)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDefinition.id
  }
}

@description('https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor')
resource blobContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: subscription()
  name: guid(subscription().id, principalId, blobContributorRoleDefinition.id)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: blobContributorRoleDefinition.id
  }
}
