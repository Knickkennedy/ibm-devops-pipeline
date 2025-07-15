param deployVpn bool = true

@description('VM SKU to use for system nodes')
param sysVmSize string = 'Standard_D2ds_v5'
@description('Number of system nodes')
param sysVmCount int = 3

@description('VM SKU to use for workload nodes')
param workVmSize string = sysVmSize
@description('Min number of workload nodes')
param workVmMin int = 0
@description('Max number of workload nodes')
param workVmMax int = 2

@description('Instance number (0-6)')
param instanceNumber string = '0'
@description('Instance name')
param instanceName string = 'devops${instanceNumber}'

@description('Subnet for AKS nodes and Ingress address')
param aksSubnetAddress string = '172.16.${instanceNumber}.0/28'

@description('VPN Gateway SKU')
param vpnGatewaySKU string = 'Basic'
param vpnGatewayAddess string = '172.23.255.224/27'
param vpnClientPoolAddess string = '172.24.0.0/25'
// Further retrictions https://learn.microsoft.com/en-us/azure/aks/configure-kubenet

@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = '${instanceName}${uniqueString(resourceGroup().id)}'

@description('Provide a location for the deployment.')
param location string = resourceGroup().location

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: instanceName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: deployVpn ? [
        vpnGatewayAddess
        aksSubnetAddress
      ] : [
        aksSubnetAddress
      ]
    }
  }
}

resource akssubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'subnet'
  parent: vnet
  properties: {
    addressPrefix: aksSubnetAddress
  }
}

resource gatewaysubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = if (deployVpn) {
  name: 'GatewaySubnet'
  parent: vnet
  properties: {
    addressPrefix: vpnGatewayAddess
  }
}

resource publicip 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (deployVpn) {
  name: instanceName
  location: location
  properties: {
    publicIPAllocationMethod: vpnGatewaySKU == 'Basic' ? 'Dynamic' : 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  sku: {
    name: vpnGatewaySKU == 'Basic' ? 'Basic' : 'Standard'
    tier: 'Regional'
  }
}

resource gateway 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = if (deployVpn) {
  name: instanceName
  location: location
  properties: {
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [ vpnClientPoolAddess ]
      }
      vpnClientRootCertificates: [
        {
          name: 'default'
          properties: {
            publicCertData: replace(
              replace(
                replace(
                  replace(
                    loadTextContent('P2SRootCert.cer'),
                    '-----BEGIN CERTIFICATE-----', ''),
                  '-----END CERTIFICATE-----', ''),
                '\r', ''),
              '\n', '')
          }
        }
      ]
    }
    gatewayType: 'Vpn'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaysubnet.id
          }
          publicIPAddress: {
            id: publicip.id
          }
        }
      }
    ]
    vpnType: 'RouteBased'
    sku: {
      name: vpnGatewaySKU
      tier: vpnGatewaySKU
    }
  }
}

resource kubeletUser 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${instanceName}-kubelet'
  location: location
}

var ACR_PULL_GUID = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
resource kubeletAcr 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('kubeletUser', ACR_PULL_GUID, resourceGroup().id)
  scope: acr
  properties: {
    principalId: kubeletUser.properties.principalId
    roleDefinitionId: ACR_PULL_GUID
    principalType: 'ServicePrincipal'
  }
}

resource aksUser 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${instanceName}-aks'
  location: location
}

var NETWORK_CONTRIBUTOR_GUID = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
resource aksNetwork 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('aksUser', NETWORK_CONTRIBUTOR_GUID, resourceGroup().id)
  scope: akssubnet
  properties: {
    principalId: aksUser.properties.principalId
    roleDefinitionId: NETWORK_CONTRIBUTOR_GUID
    principalType: 'ServicePrincipal'
  }
}
var MANAGED_IDENTITY_OPERATOR_GUID = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
resource aksIdOp 'Microsoft.Authorization/roleAssignments@2022-04-01' =  {
  name: guid('aksUser', MANAGED_IDENTITY_OPERATOR_GUID, resourceGroup().id)
  scope: kubeletUser
  properties: {
    principalId: aksUser.properties.principalId
    roleDefinitionId: MANAGED_IDENTITY_OPERATOR_GUID
    principalType: 'ServicePrincipal'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-07-01' = {
  name: instanceName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksUser.id}': {}
    }
  }
  properties: {
    dnsPrefix: instanceName
    identityProfile: {
      kubeletidentity: {
        resourceId: kubeletUser.id
        clientId: kubeletUser.properties.clientId
        objectId: kubeletUser.properties.principalId
      }
    }
    kubernetesVersion: '1.32'
    networkProfile: {
      podCidr: '172.27.0.0/16' // default 10.244.0.0/16
      serviceCidr: '172.28.0.0/16' // default 10.0.0.0/16
      dnsServiceIP: '172.28.0.10' // default 10.0.0.10
      networkPlugin: 'kubenet'
      networkPolicy: 'calico'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    agentPoolProfiles: [
      {
        name: 'sys0'
        mode: 'System'
        count: sysVmCount
        vmSize: sysVmSize
        vnetSubnetID: akssubnet.id
      }
      {
        name: 'wrk0'
        mode: 'User'
        count: workVmMin
        minCount: workVmMin
        maxCount: workVmMax
        vmSize: workVmSize
        vnetSubnetID: akssubnet.id
        nodeLabels: {
          execution: 'allow'
        }
        nodeTaints: [
          'reserved=reserved:NoSchedule'
        ]
        enableAutoScaling: true
      }
    ]
    autoScalerProfile: {
      'scale-down-unneeded-time': '1m'
      'scale-down-delay-after-add': '1m'
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
}
