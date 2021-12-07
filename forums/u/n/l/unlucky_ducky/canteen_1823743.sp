#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Canteen Remover",
	description = "Removes Player Canteens",
	author = "Adjo",
	version = "1.0",
	url = "http://thecrazygfl.co.uk"
};

public OnPluginStart()
{
	HookEvent("player_spawn", event_player_spawn);
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client, false))
		return Plugin_Continue;
		
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	RemovePlayerCanteen(client);	
	return Plugin_Continue;
}

stock RemovePlayerCanteen(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_powerup_bottle")) != -1)
	{
		new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
		if(idx == 489)
		{
			AcceptEntityInput(edict, "Kill");
		}
	}
}

stock bool:IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}