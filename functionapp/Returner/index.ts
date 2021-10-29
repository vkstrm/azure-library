import { TableClient } from "@azure/data-tables";
import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { Account, AzureWebJobsStorage, TableBookEntry, updateEntity } from "../common/storage";

const returner: AzureFunction = async function (context: Context, req: HttpRequest, tableBookEntry: TableBookEntry, account: Account): Promise<void> {
    if (!account) {
        context.res = {
            status: 404,
            body: "No account found",
        }
        return
    }
    
    if (!tableBookEntry) {
        context.res = {
            status: 404,
            body: "No such book available, sorry!"
        }
        return
    }

    if (!account.loans || !account.loans.includes(tableBookEntry.RowKey)) {
        context.res = {
            status: 400,
            body: "You haven't borrowed this book"
        }
        return
    }
    
    let webStorage = new AzureWebJobsStorage(process.env["AzureWebJobsStorage"]!);
    let table = new TableClient(webStorage.TableUrl, "books", webStorage.AzureNamedKeyCredential());

    tableBookEntry.Available = tableBookEntry.Available + 1;
    await updateEntity(table, tableBookEntry);


    account.loans.splice(account.loans.indexOf(tableBookEntry.RowKey), 1);
    context.bindings.registerreturn = account;
    context.res = {
        status: 200,
        headers: {
            "Content-Type": "application/json"
        },
        body: `${tableBookEntry.RowKey} returned successfully. ${tableBookEntry.Available} now available.`
    };
};

export default returner;