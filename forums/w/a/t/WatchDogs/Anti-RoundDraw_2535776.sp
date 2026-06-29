#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[CSS/CSGO] Anti Round Draw",
	author = PLUGIN_AUTHOR,
	description = "Prevents round draw when round timer has ended",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=299479"
};

public void OnPluginStart()
{
	HookEvent("round_end", PreRoundEnd, EventHookMode_Pre);
}

public Action PreRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int iHP_T = GetTeamTotalHP(CS_TEAM_T);
	int iHP_CT = GetTeamTotalHP(CS_TEAM_CT);
	
	if (iHP_T == 0 || iHP_CT == 0 || iHP_T == iHP_CT)
		return Plugin_Continue;
	
	if(GetEventInt(event, "reason") == view_as<int>(CSRoundEnd_Draw))
	{
		if(iHP_T > iHP_CT)
		{
			SetEventInt(event, "winner", CS_TEAM_T);
			return Plugin_Changed;
		}
		else
		{
			SetEventInt(event, "winner", CS_TEAM_CT);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock int GetTeamTotalHP(int team)
{
	int iHp = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
		{
			iHp += GetClientHealth(i);
		}
	}
	return iHp;
}
