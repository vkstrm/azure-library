build:
    cd functionapp && npm ci && npm run build:production

deploy-func name='LittleDigitalLibrary':
    cd functionapp && func azure functionapp publish {{name}}

deploy-inf location='northeurope':
    az deployment sub create --location {{location}} --template-file deploy/main.bicep

migrate-table rg sa:
    #!/usr/bin/env bash
    RESOURCE_GROUP=$(az group list --query "[].{Name:name}[? contains(Name,'library')]" -o tsv)
    STORAGE_ACCOUNT=$(az storage account list --query "[].name" -o tsv)
    STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT | jq '.[0].value')
    python3 storagescript.py

deploy-front:
    az webapp deployment source config-zip --resource-group rg-library-end655uvglnfe --name sitelibraryfrontend534ythd2kre4q --src source.zip
