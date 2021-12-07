#include <sdktools>
#include <sdkhooks>

#define VERSION "0.1.0"

public Plugin:myinfo = {
	name = "Plant Anywhere",
	author = "Mitchell",
	description = "Plant the bomb anywhere.",
	version = VERSION,
	url = "SnBx.info"
}

public OnPluginStart() 
{
	CreateConVar("sm_plantanywhere_version", VERSION, "Version of Plant Anywhere", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	SetEntProp(client, Prop_Send, "m_bInBombZone", 1);
	return Plugin_Continue;
}
