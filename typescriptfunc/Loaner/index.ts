import { TableClient } from "@azure/data-tables";
import { AzureFunction, Context } from "@azure/functions";
import { ContainerClient } from "@azure/storage-blob";
import {AzureWebJobsStorage, updateEntity, getBlobSasUri, BookResponse, TableBookEntry } from "../common/storage";

const loaner: AzureFunction = async function (context: Context, res: any, tableBookEntry: TableBookEntry): Promise<void> {
    context.log(context.bindingData);
    if (!tableBookEntry) {
        context.res = {
            status: 404,
            body: "No such book available, sorry!"
        }
        return
    }
    
    if (tableBookEntry.Available <= 0) {
        context.res = {
            status: 404,
            body: "The book is all loaned out!"
        }
        return
    }

    let webStorage = new AzureWebJobsStorage(process.env["AzureWebJobsStorage"]!);
    let table = new TableClient(webStorage.TableUrl, "books", webStorage.AzureNamedKeyCredential());
    tableBookEntry.Available = tableBookEntry.Available - 1;

    let storageCreds = webStorage.StorageSharedKeyCredentials();
    let containerClient = new ContainerClient(webStorage.BlobUrl, storageCreds);
    let sasUri = getBlobSasUri(containerClient, tableBookEntry.RowKey, storageCreds);

    await updateEntity(table, tableBookEntry);

    context.res = {
        status: 200,
        body: JSON.stringify(new BookResponse(tableBookEntry, sasUri))
    };
};

export default loaner;