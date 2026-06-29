#include <sourcemod>

Plugin myinfo =
{
	name = "Target Set Team",
    author = "Chromatik Moniker",
    description = "Sets a target's Team",
    version = "1.0",
    url = "N/A"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC, "Set a player's team");
}

public Action Command_SetTeam(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_setteam <target> <team number>");
        return Plugin_Handled;
    }

    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName));
    int target = FindClientByName(targetName);

    if (target == -1)
    {
        ReplyToCommand(client, "Player not found.");
        return Plugin_Handled;
    }

    if (!IsClientInGame(target))
    {
        ReplyToCommand(client, "Invalid target.");
        return Plugin_Handled;
    }

    char teamNumberString[4];
    GetCmdArg(2, teamNumberString, sizeof(teamNumberString));
    int teamNumber = StringToInt(teamNumberString);

    if (teamNumber < 0 || teamNumber > 5) 
    {
        ReplyToCommand(client, "Invalid team number. Enter 0 or 5.");
        return Plugin_Handled;
    }


    if (!CheckCommandAccess(client, "sm_setteam", ADMFLAG_GENERIC))
    {
        ReplyToCommand(client, "You do not have permission to use this command.");
        return Plugin_Handled;
    }

    FakeClientCommand(target, "ent_fire !self setteam %d", teamNumber);

    return Plugin_Handled;
}


int FindClientByName(const char[] searchName) {

    for (int clientId = 1; clientId <= MaxClients; clientId++) {
      
        if (IsClientConnected(clientId)) {

            char clientName[64];

            GetClientName(clientId, clientName, sizeof(clientName));

            if (StrEqual(clientName, searchName, true)) { 

                return clientId;
            }
        }
    }

    return -1;
}