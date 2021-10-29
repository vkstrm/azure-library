import { AzureNamedKeyCredential, TableClient } from "@azure/data-tables";
import { BlobSASPermissions, BlobSASSignatureValues, ContainerClient, generateBlobSASQueryParameters, StorageSharedKeyCredential } from "@azure/storage-blob";

export interface TableBookEntry {
    PartitionKey: string;
    RowKey: string;
    Title: string;
    AuthorLastname: string;
    AuthorFirstname: string;
    Available: number;
}

export class BookResponse {
    isbn: string;
    title: string;
    author_lastname: string;
    author_firstname: string;
    available: number;
    cover_url: string;

    constructor(bookEntry: TableBookEntry, coverUrl: string) {
        this.isbn = bookEntry.RowKey;
        this.title = bookEntry.Title;
        this.author_firstname = bookEntry.AuthorFirstname;
        this.author_lastname = bookEntry.AuthorLastname;
        this.available = bookEntry.Available
        this.cover_url = coverUrl;
    }
}

export class AzureWebJobsStorage {
    DefaultEndpointsProtocol: string;
    AccountName: string;
    EndpointSuffix: string;
    AccountKey: string;
    TableUrl: string;
    BlobUrl: string;

    constructor(storageString: string) {
        let split = storageString.split(";");
        this.DefaultEndpointsProtocol = split[0].split("=")[1];
        this.AccountName = split[1].split("=")[1];
        this.EndpointSuffix = split[2].split("=")[1];
        this.AccountKey = split[3].split("=")[1];
        this.TableUrl = `https://${this.AccountName}.table.${this.EndpointSuffix}`
        this.BlobUrl = `https://${this.AccountName}.blob.${this.EndpointSuffix}/bookcovers`
    }

    StorageSharedKeyCredentials(): StorageSharedKeyCredential {
        return new StorageSharedKeyCredential(this.AccountName, this.AccountKey);
    }

    AzureNamedKeyCredential(): AzureNamedKeyCredential {
        return new AzureNamedKeyCredential(this.AccountName, this.AccountKey);
    }
}

export async function updateEntity(table: TableClient, book: TableBookEntry) {
    let entity = {
        partitionKey: book.PartitionKey,
        rowKey: book.RowKey,
        Title: book.Title,
        AuthorLastname: book.AuthorLastname,
        AuthorFirstname: book.AuthorFirstname,
        Available: book.Available,
    };
    await table.updateEntity(entity);
}

export function getBlobSasUri(containerClient: ContainerClient, isbn: string, sharedKeyCredential: StorageSharedKeyCredential): string {
    let blobName = `${isbn}.jpg`;
    const sasOptions: BlobSASSignatureValues = {
        containerName: containerClient.containerName,
        blobName,
        permissions: BlobSASPermissions.parse("r"),
        startsOn: new Date(),
        expiresOn: new Date(new Date().valueOf() + 300 * 1000),
    };

    const sasToken = generateBlobSASQueryParameters(sasOptions, sharedKeyCredential).toString();
    console.log(`SAS token for blob is: ${sasToken}`);

    return `${containerClient.getBlockBlobClient(blobName).url}?${sasToken}`;
}