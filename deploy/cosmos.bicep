var location = resourceGroup().location

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: 'cosmos-library-${uniqueString(resourceGroup().id)}'
  location:location
  properties: {
    createMode: 'Default' 
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }

  resource cosmosDb 'sqlDatabases' = {
    name: 'cosmosLibrary'
    properties: {
      resource: {
        id: 'cosmosLibrary'
      }
    }

    resource libraryContainer 'containers' = {
      name: 'accounts'
      properties: {
        resource: {
          id:'accounts'
          partitionKey: {
            kind: 'Hash'
            paths: [
              '/accountid'
            ]
          } 
        }
      }
    }
  }
}

output cosmos_connectionstring string = cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString 
