#include <sourcemod>
#include <smlib>
#include <sdkhooks>

#pragma semicolon 1

#pragma newdecls required

bool g_bRoundEnd;

public Plugin myinfo =
{
	name = "Regen HP",
	author = "Headline",
	description = "Regens a player HP",
	version = "1.0",
	url = "http://www.michaelwflaherty.com"
};

public void OnPluginStart() 
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	g_bRoundEnd = false;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) 
{
	g_bRoundEnd = true;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client)
{
	if (!CheckCommandAccess(client, "", ADMFLAG_RESERVATION))
	{
		return Plugin_Continue;
	}
	
	if (!IsValidClient(client, false, false))
	{
		return Plugin_Continue;
	}
	int iHealth = Entity_GetHealth(client);
	if (iHealth <= 10)
	{
		CreateTimer(1.5, Timer_Hurt, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	return Plugin_Changed;
}

public Action Timer_Hurt(Handle hTimer, any client)
{
	if (!IsValidClient(client, false, false))
	{
		return Plugin_Stop;
	}
	if (g_bRoundEnd)
	{
		return Plugin_Stop;
	}
	int iHealth = Entity_GetHealth(client);
	if (iHealth >= 100)
	{
		return Plugin_Stop;
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iHealth", iHealth + 10);
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}