import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import * as storage from 'azure-storage';

const httpTrigger: AzureFunction = async function (context: Context, tableBook: TableBookEntry): Promise<void> {
    if (tableBook == undefined) {
        context.res = {
            status: 404,
            body: "No such book available, sorry!"
        }
        return
    }
    
    if (tableBook.Available <= 0) {
        context.res = {
            status: 404,
            body: "The book is all loaned out!"
        }
        return
    }
    
    tableBook.Available = tableBook.Available - 1;
    context.res = {
        status: 200,
        body: JSON.stringify(tableBook.ToBookResponse())
    };
};

class TableBookEntry {
    PartitionKey: string;
    RowKey: string;
    Title: string;
    AuthorLastName: string;
    AuthorFirstName: string;
    Available: number;

    ToBookResponse(): BookResponse {
        let book = new BookResponse();
        book.isbn = this.RowKey;
        book.title = this.Title;
        book.author_firstname = this.AuthorFirstName;
        book.author_lastname = this.AuthorLastName;
        book.available = this.Available
        return book;
    }
}

class BookResponse {
    isbn: string;
    title: string;
    author_lastname: string;
    author_firstname: string;
    available: number;
    cover_url: string;
}

export default httpTrigger;