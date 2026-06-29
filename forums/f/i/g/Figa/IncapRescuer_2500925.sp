#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <sdktools_functions>

public Plugin myinfo = {
	name = "[L4D]Incap Rescuer",
	author = "Figa",
	description = "It allows you to rescue players from the closet, being incapacitated.",
	version = "1.1",
	url = "http://www.sourcemod.net"
};
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (buttons & IN_USE)
	{
		if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return Plugin_Continue;
		if (IsPlayerIncapped(client))
		{
			int entity = GetClientAimTarget(client, false);
			if(entity != -1)
			{
				char sClass[32];
				GetEdictClassname(entity, sClass, 32);
				if (StrEqual(sClass, "prop_door_rotating"))
				{
					float vPosClient[3], vPosEnt[3];
					GetClientAbsOrigin(client, vPosClient);
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPosEnt);
					if (GetVectorDistance(vPosClient, vPosEnt) <= 70.0) AcceptEntityInput(entity, "Open");
				}
			}
		}
	}
	return Plugin_Continue;
}
stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}