#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_end", OnRoundEnd, EventHookMode_Post); 
}
public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	swapTeams();
}
void swapTeams()
{	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			return;
		}
		switch(GetClientTeam(i))
		{
			case CS_TEAM_T:
				CS_SwitchTeam(i, CS_TEAM_CT);
			case CS_TEAM_CT:
				CS_SwitchTeam(i, CS_TEAM_T);
		}
	}
}
