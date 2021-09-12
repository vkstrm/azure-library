using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Azure.Cosmos.Table;

namespace Library.Functions
{
    public static class Constants {
        public const string PARTITION = "mainbranch";
        public const string BOOKS_TABLE = "books";
    }

    public static class Loaner
    {

        [FunctionName("Loaner")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "loan/{isbn}")] HttpRequest request,
            [Table(Constants.BOOKS_TABLE, Constants.PARTITION, "{isbn}")] TableBook tableBook,
            [Table(Constants.BOOKS_TABLE)] CloudTable outputTable,
            ILogger log)
        {
            if (tableBook is null) {
                return new NotFoundObjectResult("No such book, sorry!");
            }

            if (tableBook.Available == 0) {
                return new NotFoundObjectResult("The book is all loaned out!");
            }
            log.LogInformation($"Executing loan of {tableBook.RowKey}");

            tableBook.Available = tableBook.Available - 1;
            tableBook.ETag = "*";
            var replaceOperation = TableOperation.Replace(tableBook);
            await outputTable.ExecuteAsync(replaceOperation);

            string json = JsonConvert.SerializeObject(tableBook.ToBook());
            return new OkObjectResult(json);
        }
    }

    public static class Lister 
    {
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "list")] HttpRequest request,
            [Table(Constants.BOOKS_TABLE)] CloudTable inputTable,
            ILogger log)
        {
            return new OkObjectResult("");
        }
    }
}

public class TableBook : TableEntity {
    public string Title {get;set;}
    public string AuthorLastname {get;set;}
    public string AuthorFirstname {get;set;}
    public long Available {get;set;}

    public Book ToBook() {
        return new Book() {
            Library = this.PartitionKey,
            ISDN = this.RowKey,
            Title = this.Title,
            AuthorFirstname = this.AuthorFirstname,
            AuthorLastname = this.AuthorLastname,
            Available = (int)this.Available
        };
    }
}

public class Book {
    [JsonProperty("library")]
    public string Library {get; set;}
    [JsonProperty("isdn")]
    public string ISDN {get;set;}
    [JsonProperty("title")]
    public string Title {get;set;}
    [JsonProperty("authorLastname")]
    public string AuthorLastname {get;set;}
    [JsonProperty("authorFirstname")]
    public string AuthorFirstname {get;set;}
    [JsonProperty("available")]
    public int Available {get;set;}
}