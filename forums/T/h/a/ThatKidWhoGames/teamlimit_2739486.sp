#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>

ConVar g_cvEnable = null;
ConVar g_cvRatio  = null;

public void OnPluginStart()
{
	g_cvEnable = CreateConVar("sm_team_limit_enable", "1",   "Enable/Disable the plugin", _, true, 0.0, true, 1.0);
	g_cvRatio  = CreateConVar("sm_team_limit_ratio",  "3.0", "Ratio of CT's to T's");

	g_cvEnable.AddChangeHook(ConVar_Update);
	g_cvRatio.AddChangeHook(ConVar_Update);

	HookEvent("player_team", Event_PlayerTeam);
}

public void OnConfigsExecuted()
{
	if (g_cvEnable.BoolValue && !CheckTeamRatio())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				ChangeTeamToCT(i);

				if (CheckTeamRatio())
				{
					break;
				}
			}
		}
	}
}

public void ConVar_Update(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	OnConfigsExecuted();
}

public void Event_PlayerTeam(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (hEvent.GetInt("team") == CS_TEAM_T)
	{
		RequestFrame(Frame_PlayerTeam, hEvent.GetInt("userid"));
	}
}

public void Frame_PlayerTeam(any data)
{
	if (g_cvEnable.BoolValue && !CheckTeamRatio())
	{
		int iClient = GetClientOfUserId(data);
		if (iClient != 0 && GetClientTeam(iClient) == CS_TEAM_T)
		{
			ChangeTeamToCT(iClient);
		}
	}
}

stock int GetCTCount()
{
	return GetTeamClientCount(CS_TEAM_CT);
}

stock int GetTCount()
{
	return GetTeamClientCount(CS_TEAM_T);
}

stock float GetTeamRatio()
{
	return float(GetCTCount() / GetTCount());
}

stock bool CheckTeamRatio()
{
	return GetTeamRatio() >= g_cvRatio.FloatValue;
}

stock void ChangeTeamToCT(int iClient)
{
	CS_SwitchTeam(iClient, CS_TEAM_CT);

	if (IsPlayerAlive(iClient))
	{
		CS_RespawnPlayer(iClient);
	}
}