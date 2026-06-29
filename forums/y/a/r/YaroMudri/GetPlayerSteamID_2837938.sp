#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo = 
{
    name = "Get Player SteamID",
    description = "Displays a player's SteamID in console",
    version = "1.0"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_get_steamid", Command_GetSteamID, ADMFLAG_GENERIC, "Displays a player's SteamID in console. Usage: sm_get_steamid <target>");
}

public Action Command_GetSteamID(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_get_steamid <target>");
        return Plugin_Handled;
    }

    char targetArg[64];
    GetCmdArg(1, targetArg, sizeof(targetArg));

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            targetArg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_NO_BOTS,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for (int i = 0; i < target_count; i++)
    {
        int target = target_list[i];
        if (IsClientInGame(target))
        {
            char steamId[64];
            if (GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId), false))
            {
                PrintToConsole(client, "[SM] %N's SteamID: %s", target, steamId);
                ReplyToCommand(client, "[SM] %N's SteamID has been printed to your console.", target);
            }
            else
            {
                ReplyToCommand(client, "[SM] Could not retrieve SteamID for %N.", target);
            }
        }
    }

    return Plugin_Handled;
}