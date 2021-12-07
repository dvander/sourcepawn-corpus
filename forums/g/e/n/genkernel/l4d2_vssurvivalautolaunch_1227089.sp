#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo =
{
	name = "L4D2 VS Survival Autolaunch Fixed?",
	author = "AtomicStryker + GK",
	description = " Auto Launch for Versus Survival ",
	version = PLUGIN_VERSION,
	url = ""
};

static bool:isVersusSurvival = false;
static bool:roundHandled = false;
static Handle:countDownTimer = INVALID_HANDLE;
static Handle:countDownCvar = INVALID_HANDLE;

new g_countdown = 0;

public OnPluginStart()
{
	CreateConVar("l4d2_vs_sv_autolaunch_version", PLUGIN_VERSION, "L4D2 VS Survival Autolaunch Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	countDownCvar = CreateConVar("l4d2_vs_sv_autolaunch_time", "45", " Time after which an Auto Launch is done ", FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	// round start doesn't seem to be a good choice has it is called before players are fully in game
	//HookEvent("round_start", _Player_Left_Start_Area, EventHookMode_PostNoCopy);
	
	// This should start the timer on all maps
	HookEvent("player_spawn", _Player_Spawn);
		
	HookEvent("round_end", _RoundEnd_Event);
	HookEvent("survival_round_start", _Survival_Round_Start);
}

public OnMapStart()
{
	decl String:mode[36];
	GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));
	isVersusSurvival = StrEqual(mode, "mutation15");
}

public Action:_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client, userid, team; 
	
	userid = GetEventInt(event, "userid");
	
	if ((client = GetClientOfUserId(userid)) == 0)
	{
		return Plugin_Continue;
	}
	
	team = GetClientTeam(client);
	
	if (team == 2 && !roundHandled && isVersusSurvival && countDownTimer == INVALID_HANDLE)
	{
		g_countdown = GetConVarInt(countDownCvar);
		countDownTimer = CreateTimer(1.0, _AutoStart_Timer, _, TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public Action:_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundHandled = false;
	_StopTimer(countDownTimer);
	countDownTimer = INVALID_HANDLE;
}

public Action:_Survival_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	_StopTimer(countDownTimer);
	countDownTimer = INVALID_HANDLE;
	
	return Plugin_Continue;
}

_StopTimer(Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
	}
}

public Action:_AutoStart_Timer(Handle:timer)
{
	g_countdown--;
	
	new trigger = FindSurvivalButton();
	if (trigger == -1)
	{
		countDownTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (g_countdown > 0)
	{
		PrintHintTextToAll("Auto Starting in %i secs", g_countdown);
	}
	else if ( g_countdown == 0 )
	{
		AcceptEntityInput(trigger, "Press");
		PrintHintTextToAll("Versus Survival Auto Start!");
		countDownTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

static FindSurvivalButton()
{
	decl String:buffer[96];
	
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "func_button")) != -1)
	{
		if (ent)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "survival_alarm_button", false) ||
				StrEqual(buffer, "survival_button", false))
			{
				return ent;
			}
		}
	}

	return -1;
}