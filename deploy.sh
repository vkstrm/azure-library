# Will deploy everything from scratch

# Build and zip the frontend
# ZIP_NAME='frontend-source.zip'
# rootdir=$(pwd)
# cd /frontend
# npm run build
# cd /build
# zip -r ../../$ZIP_NAME .
# cd $rootdir

# Deploy main infrastructure
echo "Deploying bicep"
az deployment sub create --location northeurope --template-file deploy/main.bicep

# Get names of stuff
export RESOURCE_GROUP=$(az group list --query "[].{Name:name}[? contains(Name,'library')]" -o tsv)
export STORAGE_ACCOUNT=$(az storage account list --query "[].name" -o tsv)
#WEBAPP=$(az webapp list --query "[].name" -o tsv)

# Publish the function app code
echo "Publishing function app"
func azure functionapp publish LittleDigitalLibrary

# Fill the storage table
echo "Filling storage"
export STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT | jq -r '.[0].value')
python3 storagescript.py

# Deploy the web app
#az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name $WEBAPP --src $ZIP_NAME