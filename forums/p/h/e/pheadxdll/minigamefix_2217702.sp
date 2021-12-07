#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new bool:g_bEnabled;
new Float:g_flTimeMinigame;

#define TFCond_BumperCars 82

public OnPluginStart()
{
	HookEvent("teamplay_round_active", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_win", Event_RoundWin);

	RegAdminCmd("minigame_start", Command_Start, ADMFLAG_GENERIC);
}

public OnMapStart()
{
	g_flTimeMinigame = 0.0;

	g_bEnabled = false;
	decl String:strMap[24];
	GetCurrentMap(strMap, sizeof(strMap));
	if(strcmp(strMap, "sd_doomsday_event") == 0)
	{
		g_bEnabled = true;
	}
}

public Action:Command_Start(client, args)
{
	if(g_bEnabled && g_flTimeMinigame == 0.0)
	{
		new iBellRinger = Entity_FindEntityByName("bell_ringer_activated", "logic_relay");
		if(iBellRinger != -1)
		{
			LogMessage("Found \"bell_ringer_activated\": %d!", iBellRinger);

			AcceptEntityInput(iBellRinger, "Trigger");
		}		
	}

	return Plugin_Handled;
}

public Event_RoundWin(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	g_flTimeMinigame = 0.0;
}

public Event_RoundStart(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	g_flTimeMinigame = 0.0;
	if(!g_bEnabled) return;

	new iBellRinger = Entity_FindEntityByName("bell_ringer_activated", "logic_relay");
	if(iBellRinger != -1)
	{
		LogMessage("Found \"bell_ringer_activated\": %d!", iBellRinger);

		HookSingleEntityOutput(iBellRinger, "OnTrigger", EntityOutput_Ringer, false);
	}
}

public Event_PlayerDeath(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	if(g_bEnabled && g_flTimeMinigame != 0.0 && GetEngineTime() > g_flTimeMinigame)
	{
		new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
		{
			// Player spawned during a minigame so turn them into a ghost
			CreateTimer(0.1, Timer_Ghostify, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_Ghostify(Handle:hTimer, any:iRef)
{
	new client = EntRefToEntIndex(iRef);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond:TFCond_BumperCars))
	{
		PrintToConsole(client, "Making you a ghost since the minigame is active..");
		TF2_AddCondition(client, TFCond_HalloweenGhostMode, TFCondDuration_Infinite);
	}

	return Plugin_Handled;
}

public EntityOutput_Ringer(const String:output[], caller, activator, Float:delay)
{
	LogMessage("\"bell_ringer_activated\" %s %d %d %1.2f", output, caller, activator, delay);

	// After 5.25 seconds, the minigame will start
	g_flTimeMinigame = GetEngineTime()+5.25;
}

Entity_FindEntityByName(const String:strTargetName[], const String:strClassname[])
{
	decl String:strName[100];
	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, strClassname)) != -1)
	{
		GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strTargetName, strName, false) == 0)
		{
			return iEntity;
		}
	}

	return -1;
}