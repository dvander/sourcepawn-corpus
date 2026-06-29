#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new bool:g_bClass[MAXPLAYERS + 1] = {false, ...};
new bool:g_bSpawning = false;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hTime = INVALID_HANDLE;
new Handle:g_hFreeze = INVALID_HANDLE;
new Handle:g_hDisable = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "No Late Spawns",
	author = "Twisted|Panda",
	description = "Prevents players from spawning after round_freeze_end or a specific # of seconds from round_start.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public OnPluginStart()
{
	CreateConVar("sm_nolatespawns", PLUGIN_VERSION, "No Late Spawns Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_nolatespawns_enabled", "1", "Enables/Disables the Late Spawns.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hTime = CreateConVar("sm_nolatespawns_time", "0.0", "Determines how long until spawning is disabled. (0 = On Freeze End, # = # of Seconds)", FCVAR_NONE, true, 0.0);
	
	g_hFreeze = FindConVar("mp_freezetime");
	HookConVarChange(g_hFreeze, OnSettingsChange);

	if(!GetConVarInt(g_hFreeze))
		HookEvent("round_freeze", OnFreezeEnd, EventHookMode_PostNoCopy);
	else
		HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	AddCommandListener(OnCommandJoin, "jointeam");
}

public OnClientConnected(client)
{
	g_bClass[client] = false;
}

public Action:OnFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bSpawning = false;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bSpawning = true;
	if(GetConVarFloat(g_hTime))
		g_hDisable = CreateTimer(GetConVarFloat(g_hTime), TurnOffSpawns, _, TIMER_FLAG_NO_MAPCHANGE);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_bClass[i])
			FakeClientCommand(i, "joinclass %d", GetRandomInt(1, 4));

		g_bClass[i] = false;	
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bSpawning = true;
	if(GetConVarFloat(g_hTime) && g_hDisable != INVALID_HANDLE)
	{
		CloseHandle(g_hDisable);
		g_hDisable = INVALID_HANDLE;
	}
}

public Action:TurnOffSpawns(Handle:timer)
{
	g_bSpawning = false;
	g_hDisable = INVALID_HANDLE;
}

public Action:OnCommandJoin(client, const String:command[], argc)
{
	if(GetConVarInt(g_hEnabled))
	{
		if(!g_bSpawning)
		{
			g_bClass[client] = true;
			return Plugin_Handled;
		}
		else
		{
			g_bClass[client] = false;
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hFreeze)
	{
		if(!StringToInt(oldvalue))
			UnhookEvent("round_freeze", OnFreezeEnd, EventHookMode_PostNoCopy);
		else
			UnhookEvent("round_start", OnRoundStart, EventHookMode_Pre);

		if(!StringToInt(newvalue))
			HookEvent("round_freeze", OnFreezeEnd, EventHookMode_PostNoCopy);
		else
			HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
	}
}