@description('Function App Runtime')
@allowed([
  //'dotnet'
  'node'
])
param runtime string

@description('Function Runtime Version')
@allowed([
  //'2'
  '3'
])
param extensionversion string

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-library-${uniqueString(deployment().name)}'
  location: 'northeurope'
}

module cosmos 'cosmos.bicep' = {
  scope: rg
  name: 'cosmos'
}

@description('This module has a library')
module library 'library.bicep' = {
  scope: rg
  name: 'library'
  params: {
    extensionversion: extensionversion
    runtime: runtime
    cosmos_connection: cosmos.outputs.cosmos_connectionstring
  }
}

// module site 'site.bicep' = {
//   scope: rg
//   name: 'frontend'
// }
