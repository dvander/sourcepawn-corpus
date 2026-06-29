#include <sourcemod>
#include <clientprefs>

Plugin myinfo =
{
	name = "Target Addcond",
    author = "Chromatik Moniker",
    description = "Sets a Condition From Addcond Onto a Specified target",
    version = "1.0",
    url = "N/A"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_addcond", Command_Addcond,ADMFLAG_GENERIC, "Apply a condition to a player");
}

public Action Command_Addcond(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_addcond <#userid|name> <condition number>");
        return Plugin_Handled;
    }

    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName));

    int target = FindClientByName(targetName);
    if (target == -1)
    {
        ReplyToCommand(client, "Error: Could not find the specified player.");
        return Plugin_Handled;
    }

    char strCondition[4];
    GetCmdArg(2, strCondition, sizeof(strCondition));
    int condition = StringToInt(strCondition);
    if (condition < 1 || condition > 999)
    {
        ReplyToCommand(client, "Error: Condition number must be between 1 and 999.");
        return Plugin_Handled;
    }

    FakeClientCommand(target, "addcond %d", condition);
    ReplyToCommand(client, "Condition %d has been applied to %s.", condition, targetName);

    return Plugin_Handled;
}
// Define the function to find a client by their name
int FindClientByName(const char[] searchName) {
    // Iterate through the list of possible client IDs
    for (int clientId = 1; clientId <= MaxClients; clientId++) {
        // Check if this client slot is in use
        if (IsClientConnected(clientId)) {
            // Temporary storage for the current client's name
            char clientName[64];
            // Retrieve the name of this client
            GetClientName(clientId, clientName, sizeof(clientName));
            // Compare the retrieved name with the search name
            if (StrEqual(clientName, searchName, true)) { // 'true' for case-insensitive comparison
                // Return the client ID if a match is found
                return clientId;
            }
        }
    }
    // Return -1 if no match is found (moved outside the loop)
    return -1;
}