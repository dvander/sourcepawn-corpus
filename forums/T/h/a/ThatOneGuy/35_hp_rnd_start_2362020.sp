#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_Post);
}

public Action:OnRoundStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	CreateTimer(3.0, TimerCB_GiveHealth, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerCB_GiveHealth(Handle:hTimer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i, true, false))
		{
			SetEntProp(i, Prop_Send, "m_iHealth", 35);
		}
	}
}

bool:IsValidClient(client, bool:bAllowBots = false, bool:bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!IsPlayerAlive(client) && !bAllowDead))
	{
		return false;
	}
	return true;
}