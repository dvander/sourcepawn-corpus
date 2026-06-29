#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

int g_Round;

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsgHook);
}

public void OnMapStart()
{
	g_Round = 0;
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1 || g_Round < 3) 
	{
		return Plugin_Continue;
	}
	if(StrContains(weapon, "awp", false) != -1 || StrContains(weapon, "scar20", false) != -1 || StrContains(weapon, "g3sg1", false) != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnRoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
	if(GameRules_GetProp("m_bWarmupPeriod") == 0) 
	{ 
		g_Round++;
	}
}

public Action TextMsgHook(UserMsg umId, Handle hMsg, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
{
	//Thank you SM9(); for this!!
	char name[128], szValue[128]; 
	PbReadString(hMsg, "params", szValue, sizeof(szValue), 1);
	PbReadString(hMsg, "params", name, sizeof(name), 0);   
	if (StrEqual(name, "#SFUI_Notice_Game_will_restart_in", false)) 
	{
		CreateTimer(StringToFloat(szValue), Timer_GameRestarted);
	}
	return Plugin_Continue;
}

public Action Timer_GameRestarted(Handle hTimer)
{
	g_Round = 1;
}