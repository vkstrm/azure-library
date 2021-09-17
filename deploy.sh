# Will deploy everything from scratch

# Build and zip the frontend
ZIP_NAME='frontend-source.zip'
rootdir=$(pwd)
cd /frontend
npm run build
cd /build
zip -r ../../$ZIP_NAME .
cd $rootdir

# Deploy main infrastructure
az deployment sub create --location northeurope --template-file deploy/main.bicep

# Get names of stuff
RESOURCE_GROUP=$(az group list --query "[].{Name:name}[? contains(Name,'library')]" -o tsv)
STORAGE_ACCOUNT=$(az storage account list --query "[].name" -o tsv)
WEBAPP=$(az webapp list --query "[].name" -o tsv)

# Publish the function app code
func azure functionapp publish LittleDigitalLibrary --csharp

# Fill the storage table 
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT | jq '.[0].value')
python3 storagescript.py

# Deploy the web app
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name $WEBAPP --src $ZIP_NAME