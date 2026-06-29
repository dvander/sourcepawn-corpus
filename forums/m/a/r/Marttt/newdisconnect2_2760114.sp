#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>

public Plugin:myinfo =
{
    name         = "New Disconnect Message",
    author         = "Leonardo",
    description = "N/A",
    version     = "1.1",
    url         = "https://forums.alliedmods.net/showpost.php?p=1424584&postcount=7"
};

public OnPluginStart()
{
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
}

public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    if (!(1 <= client <= MaxClients))
        return Plugin_Handled;

    if (!IsClientInGame(client))
        return Plugin_Handled;

    if (IsFakeClient(client))
        return Plugin_Handled;

    new String:reason[64];
    new String:message[64];
    GetEventString(event, "reason", reason, sizeof(reason));

    if(StrContains(reason, "connection rejected", false) != -1)
    {
        Format(message,sizeof(message),"connection rejected");
    }
    else if(StrContains(reason, "timed out", false) != -1)
    {
        Format(message,sizeof(message),"timed out");
    }
    else if(StrContains(reason, "by console", false) != -1)
    {
        Format(message,sizeof(message),"console");
    }
    else if(StrContains(reason, "by user", false) != -1)
    {
        Format(message,sizeof(message),"disconnect by user");
    }
    else if(StrContains(reason, "ping is too high", false) != -1)
    {
        Format(message,sizeof(message),"ping is too high");
    }
    else if(StrContains(reason, "No Steam logon", false) != -1)
    {
        Format(message,sizeof(message),"no steam logon");
    }
    else if(StrContains(reason, "Steam account is being used in another", false) != -1)
    {
        Format(message,sizeof(message),"steam account is being used");
    }
    else if(StrContains(reason, "Steam Connection lost", false) != -1)
    {
        Format(message,sizeof(message),"steam connection lost");
    }
    else if(StrContains(reason, "This Steam account does not own this game", false) != -1)
    {
        Format(message,sizeof(message),"does not own this game");
    }
    else if(StrContains(reason, "Validation Rejected", false) != -1)
    {
        Format(message,sizeof(message),"validation rejected");
    }
    else if(StrContains(reason, "Certificate Length", false) != -1)
    {
        Format(message,sizeof(message),"certificate length");
    }
    else if(StrContains(reason, "Pure server", false) != -1)
    {
        Format(message,sizeof(message),"pure server");
    }
    else
    {
        message = reason;
    }

    CPrintToChatAll("{red}[«] {green}%N {default}left the game - reason: [{red}%s{default}]", client, message);
    return Plugin_Handled;
}