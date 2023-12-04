#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Duck Fix.",
	author = "Kamay",
	description = "Duck Spamming fix.",
	version = "1.0",
	url = "http://steamcommunity.com/id/nullednull/"
};

public void OnConfigsExecuted()
{
	FindConVar("sv_timebetweenducks").SetFloat(0.0);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsClientInGame(client))
		return Plugin_Continue;

	float flDuckSpeed = GetEntPropFloat(client, Prop_Data, "m_flDuckSpeed");

	if (flDuckSpeed < 8.0)
		SetEntPropFloat(client, Prop_Send, "m_flDuckSpeed", 8.0);

	return Plugin_Continue;
}