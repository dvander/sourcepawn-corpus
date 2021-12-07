#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "Respawn Command",
	author = "exvel",
	description = "Player can type !respawn to respawn",
	version = "1.0.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	RegConsoleCmd("respawn", Command_Respawn, "");
}

public Action:Command_Respawn(client, args)
{
	if (client == 0)
		return Plugin_Handled;
	
	if (IsPlayerAlive(client))
		return Plugin_Handled;
	
	CreateTimer(30.0, Timer_Respawn, client);
	
	return Plugin_Handled;
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
		return;
	
	if (IsPlayerAlive(client))
		return;
	
	CS_RespawnPlayer(client);
}