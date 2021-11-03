param runtime string
param extensionversion string
param cosmos_connection string

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
      COSMOS_DB_KEY: cosmos_connection
      //REMINDER_QUEUE__fullyQualifiedNamespace: '${serviceBusName}.servicebus.windows.net' // Use when the bundle is updated!
      REMINDER_QUEUE: serviceBusConnectionString
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
        COSMOS_DB_KEY: cosmos_connection
        //REMINDER_QUEUE__fullyQualifiedNamespace: '${serviceBusName}.servicebus.windows.net'
        REMINDER_QUEUE: serviceBusConnectionString
      }
    }
  }
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=core.windows.net;AccountKey=${storageAccount.listKeys().keys[0].value}'


var serviceBusName = 'ns-library-${uniqueString(resourceGroup().id)}'
resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }

  resource auth 'AuthorizationRules' = {
    name: 'reminderAuthorization'
    properties: {
      rights: [ // Needs all three??
        'Manage'
        'Listen'
        'Send'
      ]
    }
  }

  resource reminderQueue 'queues' = {
    name: 'queuereminder'
  }
}
var serviceBusConnectionString = serviceBus::auth.listKeys().primaryConnectionString

resource roleassignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().id)}'
  scope: resourceGroup()
  properties: {
    principalType: 'ServicePrincipal'
    principalId: libraryApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '090c5cfd-751d-490a-894a-3ce6f1109419')
  }
}
