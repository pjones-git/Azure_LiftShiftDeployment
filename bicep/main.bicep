@description('Location for all resources')
param location string = resourceGroup().location

@description('Prefix for all resource names')
param projectPrefix string = 'stranglerfig'

@description('Virtual network configuration')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('MySQL admin username')
param mysqlAdminUsername string = 'adminuser'

@description('MySQL admin password')
@secure()
param mysqlAdminPassword string

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-${projectPrefix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: 'subnet-vmss-1'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'subnet-vmss-2'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'subnet-appgateway'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

// MySQL Flexible Server
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  name: 'mysql-${projectPrefix}-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: mysqlAdminUsername
    administratorLoginPassword: mysqlAdminPassword
    version: '8.0.21'
    storage: {
      storageSizeGB: 20
      iops: 360
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// MySQL Database
resource mysqlDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-30' = {
  parent: mysqlServer
  name: 'mydatabase'
}

// App Service Plan (Free tier)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'plan-${projectPrefix}'
  location: location
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  properties: {
    reserved: true // Linux
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: 'app-${projectPrefix}-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PHP|8.0'
      alwaysOn: false // Required for Free tier
    }
  }
}

// Traffic Manager Profile
resource trafficManagerProfile 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: 'tm-${projectPrefix}'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Weighted'
    dnsConfig: {
      relativeName: 'tm-${projectPrefix}-${uniqueString(resourceGroup().id)}'
      ttl: 60
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
  }
}

// Outputs
output vnetName string = vnet.name
output mysqlServerName string = mysqlServer.name
output appServiceName string = appService.name
output trafficManagerName string = trafficManagerProfile.name
output mysqlConnectionString string = 'Server=${mysqlServer.properties.fullyQualifiedDomainName};Database=mydatabase;Uid=${mysqlAdminUsername};Pwd=${mysqlAdminPassword};'