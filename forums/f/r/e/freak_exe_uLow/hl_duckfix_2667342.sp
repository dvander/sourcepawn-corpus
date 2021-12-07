#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[CS:GO] Duck Fix",
	author = "Headline",
	description = "Fixing the broken duck",
	version = "1.0.1",
	url="colosseum-gaming.com"
};

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsValidClient(client, false, false))
	{
		return;
	}
	
	if (buttons & IN_DUCK)
	{
		SetEntPropFloat(client, Prop_Send, "m_flDuckSpeed", 8.0);
	}
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

/* Changelog
	1.0 - initial release
	1.0.1 - fixed error where bots would spam invalid index
*/