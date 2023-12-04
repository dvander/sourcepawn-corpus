#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdkhooks>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_gamerules>

Handle
	hTimer;
bool
	bCheck,
	bBlock;

public Plugin myinfo =
{
	name		= "Bomb plant control",
	version		= "1.0.0_01.09.2023",
	description	= "Prevents the bomb from being planted after the round ends",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public void OnMapStart()
{
	hTimer = null;

	if(bCheck == !!GameRules_GetProp("m_bMapHasBombTarget"))
		return;

	if((bCheck ^= true))
	{
		HookEvent("round_start", Event_Toggle, EventHookMode_PostNoCopy);
		HookEvent("round_end", Event_Toggle, EventHookMode_PostNoCopy);
		HookEvent("bomb_planted", Event_Toggle, EventHookMode_PostNoCopy);
	}
	else
	{
		UnhookEvent("round_start", Event_Toggle, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", Event_Toggle, EventHookMode_PostNoCopy);
		UnhookEvent("bomb_planted", Event_Toggle, EventHookMode_PostNoCopy);
	}
}

public void Event_Toggle(Event event, const char[] name, bool dontBroadcast)
{
	if(!(bBlock = name[6] != 's'))
	{
		if(hTimer) CloseHandle(hTimer);
		hTimer = null;

		return;
	}

	int i = MaxClients+1;
	while((i = FindEntityByClassname(i, "weapon_c4")) != -1) AcceptEntityInput(i, "Kill");
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(bCheck) hTimer = CreateTimer(delay, Timer_Reset, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Timer_Reset(Handle timer)
{
	bBlock = false;

	hTimer = null;
	return Plugin_Stop;
}

public void OnEntityCreated(int ent, const char[] cls)
{
	if(bCheck && bBlock && !strcmp(cls, "weapon_c4")) SDKHook(ent, SDKHook_SpawnPost, C4_Spawn);
}

public void C4_Spawn(int ent)
{
	if(bBlock) AcceptEntityInput(ent, "Kill");
}