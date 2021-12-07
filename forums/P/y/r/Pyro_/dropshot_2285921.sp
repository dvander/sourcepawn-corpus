#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Dropshot Fix",
	author = "Pyro",
	description = "Fixes AWP dropshotting",
	version = "0.1"
}

public OnGameFrame()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i))
		{
			if(GetSpeed(i) < 50.0)
			{
				decl String:curwep[32];
				GetClientWeapon(i, curwep, sizeof(curwep));
				if(strcmp(curwep, "weapon_awp") == 0)
				{
					SetEntPropFloat(GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_fAccuracyPenalty", 0.0);
				}
			}
		}
	}
}

public Float:GetSpeed(client)
{
	new Float:vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	return SquareRoot(vel[0] * vel[0] + vel[1] * vel[1]);
}