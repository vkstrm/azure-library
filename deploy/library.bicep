param runtime string
param extensionversion string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stlibrary${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  resource tableService 'tableServices' = {
    name: 'default'

    resource table 'tables' = {
      name: 'books'
    }
  }
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
      AzureWebJobsStorage: storageConnectionString
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnectionString
      WEBSITE_CONTENTSHARE: 'library'
      FUNCTIONS_EXTENSION_VERSION: '~${extensionversion}'
      FUNCTIONS_WORKER_RUNTIME: runtime
      APPINSIGHTS_INSTRUMENTATIONKEY: insights.properties.InstrumentationKey
      WEBSITE_TIME_ZONE: 'Central Europe Standard Time'
      WEBSITE_ADD_SITENAME_BINDINGS_IN_APPHOST_CONFIG: '1'
      WEBSITE_NODE_DEFAULT_VERSION: '~14'
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
        AzureWebJobsStorage: storageConnectionString
        WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnectionString
        WEBSITE_CONTENTSHARE: 'library'
        FUNCTIONS_EXTENSION_VERSION: '~${extensionversion}'
        FUNCTIONS_WORKER_RUNTIME: runtime
        APPINSIGHTS_INSTRUMENTATIONKEY: insights.properties.InstrumentationKey
        WEBSITE_TIME_ZONE: 'Central Europe Standard Time'
        WEBSITE_ADD_SITENAME_BINDINGS_IN_APPHOST_CONFIG: '1'
        WEBSITE_NODE_DEFAULT_VERSION: '~14'
      }
    }
  }
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=core.windows.net;AccountKey=${storageAccount.listKeys().keys[0].value}'
