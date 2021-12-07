#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.3"

ConVar cv_Enabled, cv_Team2, cv_Team3;

public Plugin myinfo = {
	name        = "[ANY] Block Kill Feed",
	author      = "Sgt. Gremulock",
	description = "The title says it all.",
	version     = PLUGIN_VERSION,
	url         = "sourcemod.net"
};

public void OnPluginStart()
{
	CreateConVar("sm_blockkillfeed_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cv_Enabled 	= CreateConVar("sm_blockkillfeed_enable", "1", "Enable/disable the plugin.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	cv_Team2	= CreateConVar("sm_blockkillfeed_team_two", "1", "Block kills in the kill feed if a player dies on team 2 (TF2 = RED, CS = Terrorists).\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	cv_Team3	= CreateConVar("sm_blockkillfeed_team_three", "1", "Block kills in the kill feed if a player dies on team 3 (TF2 = BLUE, CS = Counter-Terrorists).", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "blockkillfeed");

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (cv_Enabled.BoolValue)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidClient(client))
		{
			if (cv_Team2.BoolValue && GetClientTeam(client) == 2)
			{
				event.BroadcastDisabled = true;
			}
			
			if (cv_Team3.BoolValue && GetClientTeam(client) == 3)
			{
				event.BroadcastDisabled = true;
			}
		}
	}
}

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	
	return IsClientInGame(client);
}