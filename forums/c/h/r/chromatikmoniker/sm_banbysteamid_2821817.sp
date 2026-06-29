#include <sourcemod>

#define MAX_STEAMID_LENGTH 32
#define MAX_BANNED_USERS 256 // Define the maximum number of banned users

new String:bannedSteamIDs[MAX_BANNED_USERS][MAX_STEAMID_LENGTH];
new NumBannedSteamIDs = 0;

public Plugin myinfo =
{
    name        = "[ALL] Ban By Steam ID",
    author      = "Chromatik Moniker",
    description = "Allows admins to ban/unban users and retrieve SteamIDs",
    version     = "1.10",
    url         = "N/A"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_getsteamid", Command_GetSteamID, "Retrieves a player's SteamID.");
    RegConsoleCmd("sm_bansteamid", Command_BanSteamID, "Bans a SteamID.");
    RegConsoleCmd("sm_unbansteamid", Command_UnbanSteamID, "Unbans a SteamID.");
}
public Action Command_GetSteamID(int client, int args)
{
    if (args == 0)
    {
        PrintToChat(client, "[SM] Usage: sm_getsteamid <#userid|name>");
        return Plugin_Handled;
    }

    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName));
    int targetClient = FindClientByName(targetName, true);

    if (targetClient == -1)
    {
        PrintToChat(client, "[SM] No such player.");
        return Plugin_Handled;
    }

    char steamID[MAX_STEAMID_LENGTH];
    GetClientAuthString(targetClient, steamID, sizeof(steamID));
    PrintToChat(client, "[SM] SteamID of %N: %s", targetClient, steamID);

    return Plugin_Handled;
}

public Action Command_BanSteamID(int client, int args)
{
    if (args == 0)
    {
        PrintToChat(client, "[SM] Usage: sm_bansteamid <steamid>");
        return Plugin_Handled;
    }

    char steamID[MAX_STEAMID_LENGTH];
    GetCmdArg(1, steamID, sizeof(steamID));

    for (int i = 0; i < NumBannedSteamIDs; ++i)
    {
        if (StrEqual(bannedSteamIDs[i], steamID, false))
        {
            PrintToChat(client, "[SM] SteamID %s is already banned.", steamID);
            return Plugin_Handled;
        }
    }

    if (NumBannedSteamIDs < MAX_BANNED_USERS)
    {
        strcopy(bannedSteamIDs[NumBannedSteamIDs], sizeof(bannedSteamIDs[]), steamID);
        NumBannedSteamIDs++;
        PrintToChat(client, "[SM] SteamID %s has been banned.", steamID);

        // Saving the updated list of banned SteamIDs to bannedplayers.ini
        SaveBannedSteamIDsToFile();

        CheckAndKickBannedSteamIDs();
    }
    else
    {
        PrintToChat(client, "[SM] Ban list is full.");
    }

    return Plugin_Handled;
}
void SaveBannedSteamIDsToFile()
{
    // Open the file in write mode - this will clear the current contents
    File file = OpenFile("addons/sourcemod/configs/bannedplayers.ini", "w");
    if (file == INVALID_HANDLE)
    {
        PrintToServer("Unable to open bannedplayers.ini for writing.");
        return;
    }

    // Write each banned SteamID to the file
    for (int i = 0; i < NumBannedSteamIDs; ++i)
    {
        // Write the SteamID followed by a newline character
        file.WriteLine(bannedSteamIDs[i]);
    }

    // Always remember to close files when you are done with them
    CloseHandle(file);
}

public Action Command_UnbanSteamID(int client, int args)
{
    if (args == 0)
    {
        PrintToChat(client, "[SM] Usage: sm_unbansteamid <steamid>");
        return Plugin_Handled;
    }

    char steamID[MAX_STEAMID_LENGTH];
    GetCmdArg(1, steamID, sizeof(steamID));

    for (int i = 0; i < NumBannedSteamIDs; ++i)
    {
        if (StrEqual(bannedSteamIDs[i], steamID, false))
        {
            strcopy(bannedSteamIDs[i], sizeof(bannedSteamIDs[]), bannedSteamIDs[NumBannedSteamIDs - 1]);
            NumBannedSteamIDs--;

            PrintToChat(client, "[SM] SteamID %s has been unbanned.", steamID);
            return Plugin_Handled;
        }
    }

    PrintToChat(client, "[SM] SteamID %s not found in the ban list.", steamID);

    return Plugin_Handled;
}

public void CheckAndKickBannedSteamIDs()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) &&!IsClientSourceTV(client))
        {
            char steamID[MAX_STEAMID_LENGTH];
            GetClientAuthString(client, steamID, sizeof(steamID));

            for (int i = 0; i < NumBannedSteamIDs; ++i)
            {
                if (StrEqual(bannedSteamIDs[i], steamID, false))
                {
                    KickClient(client, "You have been banned from this server.");
                    return;
                }
            }
        }
    }
}

int FindClientByName(const char[] name, bool partialMatch = true)
{
    char clientName[64];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            GetClientName(i, clientName, sizeof(clientName));
            if (partialMatch)
            {
                if (StrContains(clientName, name, false)!= -1)
                {
                    return i;
                }
            }
            else if (StrEqual(clientName, name, false))
            {
                return i;
            }
        }
    }
    return -1; // Not found
}

public OnMapStart()
{
    // Reset banned SteamIDs on map start if necessary
    NumBannedSteamIDs = 0;
}
