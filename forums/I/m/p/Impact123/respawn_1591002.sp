#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "Respawn Admin",
	author = "Impact",
	description = "Respawns An Admin",
	version = "1.0",
	url = "non"
}

public OnPluginStart()
{
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_CHEATS, "Respawns Player...")
}


public Action:Command_Respawn(client, args)
{
	if(client && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		CS_RespawnPlayer(client)
		PrintToChat(client, "[SM] You were respawned.")
	}
	
	return Plugin_Handled
}