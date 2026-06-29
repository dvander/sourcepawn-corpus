#pragma semicolon	1
#pragma newdecls	required

#include <sourcemod>

ConVar hEnable = null;
bool bEnable;

public Plugin myinfo =
{
	name 		= "[CSGO] God",
	author 		= "Grey83",
	description 	= "No damage in CSGO",
	version 		= "1.0",
	url 			= ""
}

public void OnPluginStart()
{
	hEnable = CreateConVar("sm_god_enable", "1", "0/1 - Enable/Disable damage to the players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	bEnable= GetConVarBool(hEnable);

	HookConVarChange(hEnable, OnConVarChanged);

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnConVarChanged(Handle hCVar, const char[] oldValue, const char[] newValue)
{
	bEnable = view_as<bool>(StringToInt(newValue));
	if(bEnable) LookupClients();
}

void LookupClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i)) SetGod(i, bEnable);
	}
}

void SetGod(int client, bool enabled = true)
{
	SetEntProp(client, Prop_Data, "m_takedamage", (enabled) ? 0 : 2, 1);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Event_HandleSpawn, GetClientOfUserId(event.GetInt("userid")));
}

public Action Event_HandleSpawn(Handle timer, any client)
{
	if(bEnable && IsClientInGame(client) && IsPlayerAlive(client)) SetGod(client);
	return Plugin_Continue;
}