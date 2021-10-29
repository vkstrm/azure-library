import { TableClient } from "@azure/data-tables";
import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { AzureWebJobsStorage, TableBookEntry, updateEntity } from "../common/storage";

const returner: AzureFunction = async function (context: Context, req: HttpRequest, tableBookEntry: TableBookEntry): Promise<void> {
    context.log(req)
    context.log(context.bindingData)
    if (!tableBookEntry) {
        context.res = {
            status: 404,
            body: "No such book available, sorry!"
        }
        return
    }
    
    let webStorage = new AzureWebJobsStorage(process.env["AzureWebJobsStorage"]!);
    let table = new TableClient(webStorage.TableUrl, "books", webStorage.AzureNamedKeyCredential());

    tableBookEntry.Available = tableBookEntry.Available + 1;
    await updateEntity(table, tableBookEntry);

    context.res = {
        status: 201,
        body: `${tableBookEntry.RowKey} returned successfully. ${tableBookEntry.Available} now available.`
    };
};

export default returner;