import { AzureFunction, Context } from "@azure/functions"

interface ReminderMessage {
    accountid: string;
    isbn: string;
}

const reminderTrigger: AzureFunction = async function(context: Context, reminderMsg: ReminderMessage): Promise<void> {
    context.log(`Reminder for ${reminderMsg.accountid} to return ${reminderMsg.isbn}`);
};

export default reminderTrigger;
