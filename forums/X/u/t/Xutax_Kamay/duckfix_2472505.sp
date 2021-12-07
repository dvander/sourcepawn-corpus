#include <sourcemod>

public Plugin:myinfo =
{
	name = "Duck Fix.",
	author = "Kamay",
	description = "Duck Spamming fix.",
	version = "1.0",
	url = "http://steamcommunity.com/id/nullednull/"
};


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGame(client)) 
	{
		return Plugin_Continue;
	}

	new Float:DuckSpeed = GetEntPropFloat(client, Prop_Data, "m_flDuckSpeed");
	
	if (DuckSpeed < 7.0)
	{
		SetEntPropFloat(client, Prop_Send, "m_flDuckSpeed", 7.0, 0);
	}
	
	return Plugin_Continue;
}
