param location string = resourceGroup().location
param backupResourceGroupName string = 'Velero_Backups'
param identityName string = 'velero'
param blobContainerName string = 'velero'
param storageAccountId string
param deployStorage bool = true

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

module roleAssignmentDeploy 'backup-role-assignment.bicep' = {
  name: 'roleAssignmentDeploy'
  scope: subscription()
  params: {
    principalId: identity.properties.principalId
  }
}

module storageDeploy 'backup-storage.bicep' = if (deployStorage) {
  name: 'storageDeploy'
  scope: resourceGroup(backupResourceGroupName)
  params: {
    storageAccountId: storageAccountId
    blobContainerName: blobContainerName
  }
}
