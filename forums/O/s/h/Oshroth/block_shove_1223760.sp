#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Block Shove",
	author = "Oshroth",
	description = "Prevents Survivors from using shove",
	version = "1.0",
	url = "<- URL ->"
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (!IsClientConnected(client)) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (GetClientTeam(client)!= 2) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	
	if(buttons & IN_ATTACK2) {
		buttons = buttons & ~IN_ATTACK2;
	}
	
	return Plugin_Continue;
}