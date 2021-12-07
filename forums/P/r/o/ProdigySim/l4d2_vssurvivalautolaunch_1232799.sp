#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.4p"

//#define _DEBUG

public Plugin:myinfo =
{
	name = "L4D2 VS Survival Autolaunch",
	author = " AtomicStryker + ProdigySim",
	description = " Auto Launch for Versus Survival ",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=131266"
};

static const Float:SPAWNDELAY = 1.0;
static const Float:RESTART_DELAY = 4.0;

static bool:isVersusSurvival = false;
static bool:roundHandled = false;
static bool:inRound = false;
static Handle:countDownTimer = INVALID_HANDLE;
static Handle:countDownCvar = INVALID_HANDLE;
static Handle:repeatMapCvar = INVALID_HANDLE;
static countDownTimeLeft;

public OnPluginStart()
{
	CreateConVar("l4d2_vs_sv_autolaunch_version", PLUGIN_VERSION, "L4D2 VS Survival Autolaunch Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	countDownCvar = CreateConVar("l4d2_vs_sv_autolaunch_time", "60", " Time after which an Auto Launch is done ", FCVAR_PLUGIN|FCVAR_REPLICATED);
	repeatMapCvar = CreateConVar("l4d2_vs_sv_repeat_map", "1", " Restart the map instead of returning to lobby (Sometimes buggy!)", FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	new Handle:mp_gamemode = FindConVar("mp_gamemode");
	HookConVarChange(mp_gamemode, _MpGameMode_Change);	
	new String:buffer[36];
	GetConVarString(mp_gamemode, buffer, sizeof(buffer));
	isVersusSurvival = StrEqual(buffer, "mutation15");
	
	HookEvent("item_pickup", _ItemPickup_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", _RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", _RoundEnd_Event, EventHookMode_Post);
	HookEvent("survival_round_start", _SurvivalRoundStart_Event, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	countDownTimer = INVALID_HANDLE;
	roundHandled = false;
}

public _MpGameMode_Change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	isVersusSurvival = StrEqual(newValue, "mutation15");
}

public Action:_ItemPickup_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (inRound && !roundHandled && isVersusSurvival && countDownTimer == INVALID_HANDLE)
	{	
		countDownTimer = CreateTimer(SPAWNDELAY, _Spawn_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
		roundHandled = true;
	}
}

public Action:_RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	inRound = true;
}

public Action:_SurvivalRoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(isVersusSurvival) PrintHintTextToAll("Game is LIVE!");
	if(countDownTimer != INVALID_HANDLE)
	{
		KillTimer(countDownTimer);
		countDownTimer = INVALID_HANDLE;
	}
}

public Action:_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	inRound = false;
	
	DebugPrintToChatAll("End of round. Winner: %d Reason: %d Time: %f",
		GetEventInt(event, "winner"), GetEventInt(event, "reason"), GetEventFloat(event, "time"));
	
	roundHandled = false;
	if (countDownTimer != INVALID_HANDLE)
	{
		KillTimer(countDownTimer);
		countDownTimer = INVALID_HANDLE;
	}
	
	if(isVersusSurvival && GetEventInt(event, "reason") == 15 && GetConVarBool(repeatMapCvar))
	{
		PrintToChatAll("Versus Survival Match Ended! Restarting map in 4 seconds!");
		CreateTimer(RESTART_DELAY, _RestartMap_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:_Spawn_Timer(Handle:timer)
{
	countDownTimeLeft = GetConVarInt(countDownCvar);

	PrintToChatAll("Auto Starting Versus Survival Round in %i seconds", countDownTimeLeft);
	countDownTimer = CreateTimer(1.0, _CountdownTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public Action:_CountdownTimer(Handle:timer)
{
	if(countDownTimeLeft)
	{
		PrintHintTextToAll("Versus Survival Autostart\nin %i Seconds", countDownTimeLeft);
		--countDownTimeLeft;
	}
	else
	{
		SurvivalAutoStart();
		countDownTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:_RestartMap_Timer(Handle:timer)
{
	RestartMap();
}

static RestartMap()
{	
	decl String:currentMap[256];
	
	GetCurrentMap(currentMap, sizeof(currentMap));
	ForceChangeLevel(currentMap, "VS Survival Auto Restart");
	//ServerCommand("changelevel %s", currentMap);
}

static SurvivalAutoStart()
{
	new trigger = FindSurvivalButton();
	if (trigger == -1)
	{
		PrintToChatAll("[VSSURV] Couldn't find start trigger button!");
		return;
	}
	
	AcceptEntityInput(trigger, "Press");
	PrintToChatAll("Versus Survival Auto Start!");
}

static FindSurvivalButton()
{
	decl String:buffer[96];
	
	#if defined _DEBUG
	for(new i = 0; i < GetMaxEntities(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if(StrContains(buffer, "survival") != -1)
			{
				LogMessage("[VSSURV] Entlist: %s", buffer);
			}
		}		
	}
	#endif
	
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "func_button")) != -1)
	{
		if (ent)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrContains(buffer, "survival", true) != -1)
			{
				return ent;
			}
			else
			{
				DebugPrintToChatAll("Found an unknown button %s", buffer);
			}
		}
	}

	return -1;
}

DebugPrintToChatAll(const String:format[], any:...)
{
	#if defined _DEBUG
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	PrintToChatAll("[DEBUG VSSURV] %s", buffer);
		
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}