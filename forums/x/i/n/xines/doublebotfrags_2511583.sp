#include <sourcemod>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Double bot frags",
	author = "Xines",
	description = "Gives 2 frags instead of 1 when killing bots!",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", Player_Death_Event, EventHookMode_Post);
}

public Action Player_Death_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	//Lets Start
	if (IsValidClient(client) && IsValidClient(attacker) && client != attacker)
	{
		//If Client is a bot and Attacker is not, Give Attacker 2 frags
		if(IsFakeClient(client) && !IsFakeClient(attacker)) SetEntProp(attacker, Prop_Data, "m_iFrags", GetClientFrags(attacker) + 1);
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}