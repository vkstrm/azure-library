from azure.cosmosdb.table.tableservice import TableService
from azure.cosmosdb.table.models import Entity

import os

# export STORAGE_KEY=$(az storage account keys list --resource-group <name> --account-name <name> | jq '.[0].value')
STORAGE_KEY = os.getenv("STORAGE_KEY")
BOOKS_TABLE = "books"

table_service = TableService(account_name='stlibrary534ythd2kre4q', account_key=STORAGE_KEY)
table_service.create_table(BOOKS_TABLE)
print("Created table ", BOOKS_TABLE)

def make_book(row, title, first, last) -> Entity:
    return {
        "PartitionKey": 'mainbranch',
        "RowKey": row,
        'Title': title,
        "AuthorLastname": last,
        "AuthorFirstname": first,
        "Available": 3,
    }

books = []
books.append(make_book("9789174619249", "War & Peace", "Leo", "Tolstoy"))
books.append(make_book("9789174290882", "Crime & Punishment", "Fjodor", "Dostojevsky"))
books.append(make_book("9789176456521", "Dead Souls", "Nikolai", "Gogol"))

for book in books:
    print("Inserting: ", book)
    table_service.insert_entity(BOOKS_TABLE, book)

