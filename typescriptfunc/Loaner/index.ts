import { AzureFunction, Context, HttpRequest } from "@azure/functions"

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    const name = (req.query.name || (req.body && req.body.name));
    let book: TableBookEntry = context.bindings.tableBook;

    context.res = {
        status: 200,
        body: JSON.stringify(new BookResponse())
    };
};

class TableBookEntry {
    PartitionKey: string
    RowKey: string
    Title: string
    AuthorLastName: string
    AuthorFirstName: string
    Available: string
}

class BookResponse {
    isbn: string
    title: string
    author_lastname: string
    author_firstname: string
    available: string
    cover_url: string
}

export default httpTrigger;