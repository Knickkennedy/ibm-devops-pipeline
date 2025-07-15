param location string = resourceGroup().location
param storageAccountId string = 'velero${uniqueString(resourceGroup().id)}'
param blobContainerName string = 'velero'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountId
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'BlobStorage'
  properties: {
    accessTier: 'Hot'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
    }
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}


resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: blobContainerName
  properties: {
    publicAccess: 'None'
  }
}
