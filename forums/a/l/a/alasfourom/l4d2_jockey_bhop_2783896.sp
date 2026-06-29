#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Action OnPlayerRunCmd (int client, int &buttons)
{
	if (buttons & IN_JUMP && IsPlayerAlive(client) && IsJockey(client))
	{
		if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
		{
			if (GetEntityMoveType(client) != MOVETYPE_LADDER) buttons &= ~IN_JUMP;
		}
	}
	return Plugin_Continue;
}

stock bool IsJockey(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == 3 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 5);
}