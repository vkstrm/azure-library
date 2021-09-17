targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-library-${uniqueString(deployment().name)}'
  location: 'northeurope'
}

module library 'library.bicep' = {
  scope: rg
  name: 'library'
}

module site 'site.bicep' = {
  scope: rg
  name: 'frontend'
}
