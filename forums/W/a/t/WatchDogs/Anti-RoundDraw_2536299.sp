#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.1.1 - Debug"

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
}

public void OnMapEnd()
{
	if (h_Timer != INVALID_HANDLE)
	{
		KillTimer(h_Timer);
		h_Timer = INVALID_HANDLE;
		#if defined DEBUG
			LogMessage("OnMapEnd - Timer killed.");
		#endif
	}
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (h_Timer != INVALID_HANDLE)
	{
		KillTimer(h_Timer);
		h_Timer = INVALID_HANDLE;
		#if defined DEBUG
			LogMessage("OnRoundStart - Timer killed.");
		#endif
	}
	
	float fRoundTime = (GetConVarFloat(FindConVar("mp_roundtime")) * 60) - 2.0;
	h_Timer = CreateTimer(fRoundTime, Timer_BeforeRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
	#if defined DEBUG
		LogMessage("OnRoundStart - fRoundTime: %f (Timer Created)", fRoundTime);
	#endif
}

public Action Timer_BeforeRoundEnd(Handle timer)
{
	
	int iHP_T = GetTeamTotalHP(CS_TEAM_T);
	int iHP_CT = GetTeamTotalHP(CS_TEAM_CT);
	
	#if defined DEBUG
		LogMessage("Timer_BeforeRoundEnd - iHP_T: %i , iHP_CT: %i");
	#endif
	
	if (iHP_T == 0 || iHP_CT == 0 || iHP_T == iHP_CT)
		return Plugin_Handled;
	
	if (iHP_T > iHP_CT)
	{
		#if defined DEBUG
			LogMessage("Timer_BeforeRoundEnd - T Win !");
		#endif
		CS_TerminateRound(0.0, CSRoundEnd_TerroristWin);
	}
	else
	{
		#if defined DEBUG
			LogMessage("Timer_BeforeRoundEnd - CT Win !");
		#endif
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
