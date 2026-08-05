@description('A unique suffix to make resource names globally unique')
param uniqueSuffix string = uniqueString(resourceGroup().id)

@description('The Azure region for all resources')
param location string = resourceGroup().location

var storageAccountName = 'resume${uniqueSuffix}'
var cosmosAccountName = 'resumedb${uniqueSuffix}'
var functionAppName = 'resumefunc${uniqueSuffix}'
var tableName = 'VisitorCount'

// ---------- Storage Account (static website hosting) ----------
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

// ---------- Cosmos DB Account (Table API, Serverless) ----------
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      {
        name: 'EnableTable'
      }
      {
        name: 'EnableServerless'
      }
    ]
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
}

resource visitorCountTable 'Microsoft.DocumentDB/databaseAccounts/tables@2023-11-15' = {
  parent: cosmosAccount
  name: tableName
  properties: {
    resource: {
      id: tableName
    }
  }
}

// ---------- Function App (Linux, Python, Consumption) ----------
resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${functionAppName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'COSMOS_CONNECTION_STRING'
          value: cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString
        }
      ]
    }
  }
}

output storageAccountName string = storageAccount.name
output functionAppName string = functionApp.name
output cosmosAccountName string = cosmosAccount.name
