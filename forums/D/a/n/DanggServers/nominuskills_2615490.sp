#include <sourcemod>

public Plugin myinfo = 
{
	name = "No Minus kills", 
	author = "Dangg", 
	description = "No Minus kills", 
	version = "1.0", 
	url = "quitcsgo.com"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Nominus)
	HookEvent("player_death", Nominus)
}

public Action Nominus(Event event, const char[] name, bool dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"))
	if (GetClientFrags(client) < 0)
	{
		SetEntProp(client, Prop_Data, "m_iFrags", 0);
		SetEntProp(client, Prop_Data, "m_iDeaths", 0);
	}
}