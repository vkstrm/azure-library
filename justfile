deploy-func name:
    func azure functionapp publish {{name}} --csharp

deploy-inf location='northeurope':
    az deployment sub create --location {{location}} --template-file deploy/main.bicep

migrate-table rg sa:
    export STORAGE_KEY=$(az storage account keys list --resource-group {{rg}} --account-name {{sa}} | jq '.[0].value')
    python3 storagescript.py


deploy-front:
    az webapp deployment source config-zip --resource-group rg-library-end655uvglnfe --name sitelibraryfrontend534ythd2kre4q --src source.zip
