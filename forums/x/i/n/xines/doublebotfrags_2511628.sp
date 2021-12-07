#include <sourcemod>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Double bot frags",
	author = "Xines",
	description = "Bots gains 2 frags instead of 1",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", Player_Death_Event, EventHookMode_Post);
}

public Action Player_Death_Event(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(IsValidClient(attacker) && IsFakeClient(attacker))
	{
		SetEntProp(attacker, Prop_Data, "m_iFrags", GetClientFrags(attacker) + 1);
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}