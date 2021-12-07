#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 4

public Plugin myinfo = {
    name        = "FixDisconnectReason",
    author      = "FroidGaming.net",
    version     = "1.0.0"
};

public void OnPluginStart()
{
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(iClient)) {
	    return Plugin_Continue;
	}

	char sReason[128];
    event.GetString("reason", sReason, sizeof(sReason));
    PrintToChatAll("%N left the game (%s)", iClient, sReason);

    return Plugin_Continue;
}

stock bool IsValidClient(int iClient)
{
    return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}