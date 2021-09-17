resource webServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: 'sf-libraryfrontend-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name:'F1'
    tier: 'Free'
  }
}

resource appService 'Microsoft.Web/sites@2021-01-15' = {
  name: 'sitelibraryfrontend${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'app,linux'
  properties: {
    serverFarmId: webServicePlan.id
    siteConfig: {
      numberOfWorkers: 1
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
}

