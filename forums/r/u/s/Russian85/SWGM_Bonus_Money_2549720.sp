#include <sdktools_gamerules>
#include <cstrike>
#include <swgm>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[SWGM] Bonus Money",
	author = "Someone",
	version = "1.2",
	url = "http://hlmod.ru/"
};

int g_iBonus, g_iFirst;

public void OnPluginStart()
{
	//HookEvent("player_spawn", Event_PlayerSpawn);
	
	HookEvent("round_start", Event_RoundStart);
	
	ConVar CVAR;
	(CVAR	= CreateConVar("sm_swgm_bonus_money", "150", "Bonus money for Steam group users.", _, true, 0.0)).AddChangeHook(ChangeCvar_Bonus);
	g_iBonus = CVAR.IntValue;
	
	(CVAR	= CreateConVar("sm_swgm_change_side_round", "15", "Ignore this round.", _, true, 0.0)).AddChangeHook(ChangeCvar_Round);
	g_iFirst = CVAR.IntValue;
}

public void ChangeCvar_Bonus(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBonus = convar.IntValue;
}

public void ChangeCvar_Round(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iFirst = convar.IntValue;
}

/*
public void Event_PlayerSpawn(Event hEvent, const char[] sName, bool bDontBoradcast)
{
	int iScore;
	if(g_iBonus > 0 && GameRules_GetProp("m_bWarmupPeriod") == 0 && (iScore = CS_GetTeamScore(3) + CS_GetTeamScore(2)) != 1 && iScore != g_iFirst)	RequestFrame(FrameSpawn, GetClientOfUserId(hEvent.GetInt("userid")));
}
*/

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBoradcast)
{
	int iScore;
	if(g_iBonus > 0 && GameRules_GetProp("m_bWarmupPeriod") == 0 && (iScore = CS_GetTeamScore(3) + CS_GetTeamScore(2)) != 1 && iScore != g_iFirst)
	{
		//int iScore = CS_GetTeamScore(3) + CS_GetTeamScore(2);
		for(int i = 1; i <= MaxClients; i++)	if(IsClientInGame(i) && !IsFakeClient(i))
		{
			RequestFrame(FrameSpawn, i);
		}
	}
}

void FrameSpawn(int iClient)
{
	if(SWGM_InGroup(iClient))
	{
		SetEntProp(iClient, Prop_Send, "m_iAccount", GetEntProp(iClient, Prop_Send, "m_iAccount") + g_iBonus);
		PrintToChat(iClient, "[SWGM] You got $%i bonus for participating in our Steam group.", g_iBonus);
	}
	else PrintToChat(iClient, "[SWGM] You can got $%i bonus for participating in our Steam group.", g_iBonus);
}