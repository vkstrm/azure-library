import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { v4 as uuidv4 } from 'uuid';

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    const body = req.body;
    if (!body && !body.name) {
        context.res = {
            status: 400,
        }
    }

    let accountid = uuidv4();
    context.bindings.accountRegistration = JSON.stringify(
        {
            id: accountid,
            accountid: accountid,
            name: body.name, 
        }
    );

    context.res = {
        status: 201,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(
            {
                msg: "account created",
                accountid: accountid,
            })
    };

    context.done();
};

export default httpTrigger;