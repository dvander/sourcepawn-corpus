#include <swgm>

public Plugin myinfo = 
{
	name = "[SWGM] Bonus Money",
	author = "Someone",
	version = "1.0",
	url = "http://hlmod.ru/"
};

int g_iBonus;

public void OnPluginStart()
{
	//HookEvent("player_spawn", Event_PlayerSpawn);
	
	HookEvent("round_start", Event_RoundStart);
	
	ConVar CVAR;
	(CVAR	= CreateConVar("sm_swgm_bonus_money", "150", "Bonus money for Steam group users.", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_Bonus);
	g_iBonus = CVAR.IntValue;
}

public void ChangeCvar_Bonus(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBonus = convar.IntValue;
}

/*
public void Event_PlayerSpawn(Event hEvent, const char[] sName, bool bDontBoradcast)
{
	if(g_iBonus > 0)	RequestFrame(FrameSpawn, GetClientOfUserId(hEvent.GetInt("userid")));
}
*/

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBoradcast)
{
	if(g_iBonus > 0)
	{
		for(int i = 1; i <= MaxClients; i++)	if(IsClientInGame(i) && !IsFakeClient(i))
		{
			RequestFrame(FrameSpawn, i);
		}
	}
}

void FrameSpawn(int iClient)
{
	if(SWGM_InGroup(iClient))	SetEntProp(iClient, Prop_Send, "m_iAccount", GetEntProp(iClient, Prop_Send, "m_iAccount") + g_iBonus);
}