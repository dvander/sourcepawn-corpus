#include <cstrike>
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name            = "SM Slay when empty CT team",
    author          = "Franc1sco franug",
    description     = "",
    version         = "1.0",
    url             = "http://steamcommunity.com/id/franug"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Check();
}

void Check()
{
	int cts = GetTeamClientCount(CS_TEAM_CT);
	int ts = GetTeamClientCount(CS_TEAM_T);
	
	if(cts == 0 && ts >= 4)
		for (new i = 1; i < MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
				ForcePlayerSuicide(i);
}