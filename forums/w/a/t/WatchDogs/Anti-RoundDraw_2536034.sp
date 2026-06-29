#pragma semicolon 1

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.1.0"

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

Handle h_Timer;

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
	HookEvent("round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("round_end", OnRoundEnd, EventHookMode_Post);
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	Handle h_RoundTime = FindConVar("mp_roundtime");
	float fRoundTime = (GetConVarFloat(h_RoundTime) * 60) - 0.5;
	CloseHandle(h_RoundTime);
	
	h_Timer = CreateTimer(fRoundTime, Timer_BeforeRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(h_Timer != INVALID_HANDLE)
	{
		KillTimer(h_Timer);
		h_Timer = INVALID_HANDLE;
	}
}

public Action Timer_BeforeRoundEnd(Handle timer)
{
	int iHP_T = GetTeamTotalHP(CS_TEAM_T);
	int iHP_CT = GetTeamTotalHP(CS_TEAM_CT);
	
	if (iHP_T == 0 || iHP_CT == 0 || iHP_T == iHP_CT)
		return Plugin_Handled;
		
	if (iHP_T > iHP_CT)
	{
		CS_TerminateRound(0.0, CSRoundEnd_TerroristWin);
	}
	else
	{
		CS_TerminateRound(0.0, CSRoundEnd_CTWin);
	}
	return Plugin_Handled;
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
