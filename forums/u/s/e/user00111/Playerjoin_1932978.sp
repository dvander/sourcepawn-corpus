#pragma semicolon 1

#include <sourcemod>

#define	TAG_INFO "\x03[Join]\x01"
 
public Plugin:myinfo =
{
	name = "Simble Player Joined/Left Notifier",
	author = "def (user00111)",
	description = "Notifies when a new player has joined or left the game (with disconnect reason).",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=213471"
};

public OnPluginStart() {
  HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public OnPluginEnd() {
  UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public OnClientPutInServer(client) {
	if (IsFakeClient(client)) // a bot
	  return;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (!IsFakeClient(i)) {
				if (i != client) {
			    PrintToChat(i, "%s Player \x04%N\x01 joined the game.", TAG_INFO, client);
				}
			}
		}
	}
}

public Action:Event_PlayerDisconnect(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((client != 0) && !IsFakeClient(client)) {
		decl String:reason[100];
		GetEventString(event, "reason", reason, sizeof(reason));
		if (StrContains(reason, "kicked", false) != -1) 
			strcopy(reason, sizeof(reason), "Kicked");
		else if (StrContains(reason, "banned", false) != -1)
			strcopy(reason, sizeof(reason), "Banned");
		else if (StrContains(reason, "timed out", false) != -1)
			strcopy(reason, sizeof(reason), "Lost Connection"); 
		
		decl String:player_name[MAX_NAME_LENGTH];
		GetEventString(event, "name", player_name, sizeof(player_name));
		PrintToChatAll("%s Player \x04%s\x01 left the game. (%s)", TAG_INFO, player_name, reason);
		if (!dontBroadcast)
		  SetEventBroadcast(event, true);
	}
	return Plugin_Continue;
}