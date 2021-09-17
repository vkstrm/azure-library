resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stlibrary${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource servicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: 'sf-library-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name:'Y1'
    tier: 'Dynamic'
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-library-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    Flow_Type: 'Bluefield'
  }
}

resource libraryApp 'Microsoft.Web/sites@2021-01-15' = {
  name: 'LittleDigitalLibrary'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp'
  properties: {
    serverFarmId: servicePlan.id
  }

  resource functionAppSlotConfigNames 'config@2021-01-15' = {
    name: 'slotConfigNames'  
    properties: {
      appSettingNames: [
        'CustomerApiKey'
      ]
    }
  }

  resource libraryAppSettings 'config@2021-01-15' = {
    name: 'appsettings'
    properties: {
      CustomerApiKey: 'This is the production slot'
      databaseConnectionString: settingDbConnectionString
      AzureWebJobsStorage: storageConnectionString
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnectionString
      WEBSITE_CONTENTSHARE: 'library'
      FUNCTIONS_EXTENSION_VERSION: '~2'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet'
      APPINSIGHTS_INSTRUMENTATIONKEY: insights.properties.InstrumentationKey
      WEBSITE_TIME_ZONE: 'Central Europe Standard Time'
      WEBSITE_ADD_SITENAME_BINDINGS_IN_APPHOST_CONFIG: '1'
    }
  }

  resource appDeploymentSlot 'slots@2021-01-15' = {
    name: 'staging'
    location: resourceGroup().location
    kind: 'functionapp'
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      serverFarmId: servicePlan.id
    }

    resource stageLibraryAppSettings 'config@2021-01-15' = {
      name: 'appsettings'
      properties: {
        CustomerApiKey: 'This is the staging slot'
        databaseConnectionString: settingDbConnectionString
        AzureWebJobsStorage: storageConnectionString
        WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnectionString
        WEBSITE_CONTENTSHARE: 'library'
        FUNCTIONS_EXTENSION_VERSION: '~2'
        FUNCTIONS_WORKER_RUNTIME: 'dotnet'
        APPINSIGHTS_INSTRUMENTATIONKEY: insights.properties.InstrumentationKey
        WEBSITE_TIME_ZONE: 'Central Europe Standard Time'
        WEBSITE_ADD_SITENAME_BINDINGS_IN_APPHOST_CONFIG: '1'
      }
    }
  }
}

var settingDbConnectionString = '@Microsoft.KeyVault(SecretUri=${dbConnectionStringSecret.properties.secretUri}/)'
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageAccount.name), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: 'kvlibrary${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: libraryApp.identity.tenantId
    accessPolicies: [
      {
        tenantId: libraryApp.identity.tenantId
        objectId: libraryApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
      {
        tenantId: libraryApp::appDeploymentSlot.identity.tenantId
        objectId: libraryApp::appDeploymentSlot.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

resource dbConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/dbConnectionString'
  properties: {
    value: storageConnectionString
  }
  dependsOn: [
    keyVault
  ]
}
