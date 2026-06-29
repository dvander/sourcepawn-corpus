/* 
Planned Updates
~ Cvar to allow server operator to select which map prefixes to enable Surf Config on (rather than hardcoded values of "surf" and "slide"
~ Cvar to allow automatic deletion of weapons that are spawned and not picked up after ~x seconds
~ Cvar to allow automatic deletion of weapons that are dropped after ~x seconds
~ Cvar to allow server operator to modify the advert message that's shown, if enabled, rather than the hardcoded value.
~ Translation support, if there's any interest in it.
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <mapchooser>
#include <cstrike>

#define PLUGIN_VERSION "2.2.2"
#define PLUGIN_PREFIX "\x04Surfing: \x03"

#define NUM_MAP_CHECKS 2
static const String:_sMapChecks[NUM_MAP_CHECKS][] = { "surf", "slide" };

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];

#define HANDLE_RECALL 0
#define HANDLE_BOOST 1
#define HANDLE_SLOW 2
#define HANDLE_DATA 3
new Handle:g_hHandles[MAXPLAYERS + 1][HANDLE_DATA];

#define PLAYER_RECALL_TIME 0
#define PLAYER_RECALL_COUNT 1
#define PLAYER_BOOST_TIME 2
#define PLAYER_BOOST_COUNT 3
#define PLAYER_SLOW_TIME 4
#define PLAYER_SLOW_COUNT 5
#define PLAYER_SLOW_LEFT 6
#define PLAYER_DATA 7
new g_iData[MAXPLAYERS + 1][PLAYER_DATA];

#define ACTION_RECALL 0
#define ACTION_BOOST 1
#define ACTION_DATA 2
new bool:g_bActions[MAXPLAYERS + 1][ACTION_DATA];

#define POSITION_SPAWN 0
#define POSITION_RECALL 1
#define POSITION_BOOST 2
#define POSITION_DATA 3
new Float:g_fPositions[MAXPLAYERS + 1][POSITION_DATA][3];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hStrip = INVALID_HANDLE;
new Handle:g_hSuicide = INVALID_HANDLE;
new Handle:g_hRadio = INVALID_HANDLE;
new Handle:g_hForce = INVALID_HANDLE;
new Handle:g_hAir = INVALID_HANDLE;
new Handle:g_hHop = INVALID_HANDLE;
new Handle:g_hRecall = INVALID_HANDLE;
new Handle:g_hRecallRecovery = INVALID_HANDLE;
new Handle:g_hRecallCount = INVALID_HANDLE;
new Handle:g_hRecallDelay = INVALID_HANDLE;
new Handle:g_hRecallCancel = INVALID_HANDLE;
new Handle:g_hBoost = INVALID_HANDLE;
new Handle:g_hBoostRecovery = INVALID_HANDLE;
new Handle:g_hBoostPower = INVALID_HANDLE;
new Handle:g_hBoostCount = INVALID_HANDLE;
new Handle:g_hBoostDelay = INVALID_HANDLE;
new Handle:g_hBoostCancel = INVALID_HANDLE;
new Handle:g_hCash = INVALID_HANDLE;
new Handle:g_hSlow = INVALID_HANDLE;
new Handle:g_hSlowRecovery = INVALID_HANDLE;
new Handle:g_hSlowPercent = INVALID_HANDLE;
new Handle:g_hSlowDuration = INVALID_HANDLE;
new Handle:g_hSlowCount = INVALID_HANDLE;
new Handle:g_hAdvert = INVALID_HANDLE;

new bool:g_bLateLoad, bool:g_bEnabled, bool:g_bSuicide, bool:g_bRadio, bool:g_bForce, bool:g_bRecall, bool:g_bSlow, bool:g_bBoost, bool:g_bAdvert;
new Float:g_fRecallDelay, Float:g_fRecallCancel, Float:g_fBoostDelay, Float:g_fBoostCancel, Float:g_fSlowPercent;
new g_iStrip, g_iAir, g_iRecall, g_iRecallRecovery, g_iRecallCount, g_iBoost, g_iBoostRecovery, g_iBoostPower, g_iBoostCount, g_iCash, g_iSlow, g_iSlowRecovery, g_iSlowPercent, g_iSlowDuration, g_iSlowCount, g_iHop;
new String:g_sAdvert[256];
new Handle:g_hAirAccelerate = INVALID_HANDLE;
new Handle:g_henablebunnyhopping = INVALID_HANDLE;
new Handle:g_hTimerForce = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Surfing: Configuration",
	author = "Twisted|Panda edit by X3S2",
	description = "Plugin that provides various settings geared for Surf/Slide maps.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_surfing_version", PLUGIN_VERSION, "Surfing Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_surfing_enable", "1", "Determines plugin functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Enabled on Surf/Slide)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hStrip = CreateConVar("sm_surfing_strip", "0", "Determines stripping functionality. (-1 = Strip Buyzones/Objectives, 0 = Disabled, 1 = Strip Buyzones, 2 = Strip Objectives)", FCVAR_NONE, true, -1.0, true, 2.0);
	g_hSuicide = CreateConVar("sm_surfing_block_suicide", "1", "If enabled, players will be unable to kill themselves via kill/explode.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hRadio = CreateConVar("sm_surfing_block_radio", "1", "If enabled, player will not be able to issue any radio commands.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hForce = CreateConVar("sm_surfing_map_change", "1", "If enabled, the map will be forced to change at the end of mp_timelimit. Requires SM mapchooser.smx as well as its end of map vote.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hAir = CreateConVar("sm_surfing_air_accelerate", "1000", "If greater than 0, sv_airaccelerate is always forced to this value.", FCVAR_NONE, true, 0.0);
	g_hHop = CreateConVar("sm_surfing_enablebunnyhopping", "1", "If sm_surfing_enablebunnyhopping 0, you lose speed at water and land while BunnyHopping.", FCVAR_NONE, true, 0.0);
	g_hRecall = CreateConVar("sm_surfing_teleport", "-1", "Determines teleport command functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Enabled on Surf/Slide)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hRecallRecovery = CreateConVar("sm_surfing_teleport_recovery", "60.0", "The number of seconds a player must wait before being able to use sm_recall again.", FCVAR_NONE, true, 0.0);
	g_hRecallCount = CreateConVar("sm_surfing_teleport_count", "3", "The number of sm_recall usages players will receive upon spawn. (0 = Unlimited)", FCVAR_NONE, true, 0.0);
	g_hRecallDelay = CreateConVar("sm_surfing_teleport_delay", "10.0", "If greater than 0, the delay in seconds between sm_recall usage and receiving the teleport to spawn.", FCVAR_NONE, true, 0.0);
	g_hRecallCancel = CreateConVar("sm_surfing_teleport_cancel", "150.0", "If greater than 0, the maximum distance a player can travel before sm_recall cancels, should sm_surfing_teleport_delay be greater than 0.", FCVAR_NONE, true, 0.0);
	g_hBoost = CreateConVar("sm_surfing_boost", "-1", "Determines boost command functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Enabled on Surf/Slide)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hBoostRecovery = CreateConVar("sm_surfing_boost_recovery", "30.0", "The number of seconds a player must wait before being able to use sm_boost again.", FCVAR_NONE, true, 0.0);
	g_hBoostPower = CreateConVar("sm_surfing_boost_power", "1250.0", "The overall strength behind the sm_boost command. The larger the #, the stronger the effect.", FCVAR_NONE, true, 0.0);
	g_hBoostCount = CreateConVar("sm_surfing_boost_count", "5", "The number of sm_boost usages players will receive upon spawn. (0 = Unlimited)", FCVAR_NONE, true, 0.0);
	g_hBoostDelay = CreateConVar("sm_surfing_boost_delay", "0.0", "If greater than 0, the delay in seconds between sm_boost usage and receiving the boost effect.", FCVAR_NONE, true, 0.0);
	g_hBoostCancel = CreateConVar("sm_surfing_boost_cancel", "0.0", "If greater than 0, the maximum distance a player can travel before sm_boost cancels, should sm_surfing_boost_delay be greater than 0.", FCVAR_NONE, true, 0.0);
	g_hCash = CreateConVar("sm_surfing_spawn_cash", "-1", "The amount of cash players will receive every time they spawn. (-1 = Disabled)", FCVAR_NONE, true, -1.0, true, 16000.0);
	g_hSlow = CreateConVar("sm_surfing_slow", "-1", "Determines slow command functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Enabled on Surf/Slide)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hSlowRecovery = CreateConVar("sm_surfing_slow_recovery", "30.0", "The number of seconds a player must wait before being able to use sm_slow again.", FCVAR_NONE, true, 0.0);
	g_hSlowPercent = CreateConVar("sm_surfing_slow_percent", "50", "The percent value to decrease a player's speed by. A percent of 33 will result in players going 66% of their normal speed while slowed.", FCVAR_NONE, true, 0.0, true, 100.0);
	g_hSlowDuration = CreateConVar("sm_surfing_slow_duration", "7.0", "The number of seconds a player will be slowed for before returning to normal speed.", FCVAR_NONE, true, 0.0);
	g_hSlowCount = CreateConVar("sm_surfing_slow_count", "3", "The number of sm_slow usages players will receive upon spawn. (0 = Unlimited)", FCVAR_NONE, true, 0.0);
	g_hAdvert = CreateConVar("sm_surfing_advert", "1", "If enabled, players will be printed with the available commands upon spawning for the first time.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_surfing_config");

	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hStrip, Action_OnSettingsChange);
	HookConVarChange(g_hSuicide, Action_OnSettingsChange);
	HookConVarChange(g_hRadio, Action_OnSettingsChange);
	HookConVarChange(g_hForce, Action_OnSettingsChange);
	HookConVarChange(g_hAir, Action_OnSettingsChange);
	HookConVarChange(g_hHop, Action_OnSettingsChange);
	HookConVarChange(g_hRecall, Action_OnSettingsChange);
	HookConVarChange(g_hRecallRecovery, Action_OnSettingsChange);
	HookConVarChange(g_hRecallCount, Action_OnSettingsChange);
	HookConVarChange(g_hRecallDelay, Action_OnSettingsChange);
	HookConVarChange(g_hRecallCancel, Action_OnSettingsChange);
	HookConVarChange(g_hBoost, Action_OnSettingsChange);
	HookConVarChange(g_hBoostRecovery, Action_OnSettingsChange);
	HookConVarChange(g_hBoostPower, Action_OnSettingsChange);
	HookConVarChange(g_hBoostCount, Action_OnSettingsChange);
	HookConVarChange(g_hBoostDelay, Action_OnSettingsChange);
	HookConVarChange(g_hBoostCancel, Action_OnSettingsChange);
	HookConVarChange(g_hCash, Action_OnSettingsChange);
	HookConVarChange(g_hSlow, Action_OnSettingsChange);
	HookConVarChange(g_hSlowRecovery, Action_OnSettingsChange);
	HookConVarChange(g_hSlowPercent, Action_OnSettingsChange);
	HookConVarChange(g_hSlowDuration, Action_OnSettingsChange);
	HookConVarChange(g_hSlowCount, Action_OnSettingsChange);
	HookConVarChange(g_hAdvert, Action_OnSettingsChange);

	g_hAirAccelerate = FindConVar("sv_airaccelerate");
	HookConVarChange(g_hAirAccelerate, Action_OnSettingsChange);
	g_henablebunnyhopping = FindConVar("sv_enablebunnyhopping");
	HookConVarChange(g_henablebunnyhopping, Action_OnSettingsChange);

	RegConsoleCmd("sm_recall", Command_Recall);
	RegConsoleCmd("sm_boost", Command_Boost);
	RegConsoleCmd("sm_slow", Command_Slow);
	AddCommandListener(Command_Kill, "kill");
	AddCommandListener(Command_Kill, "explode");
	AddCommandListener(Command_Radio, "coverme");
	AddCommandListener(Command_Radio, "takepoint");
	AddCommandListener(Command_Radio, "holdpos");
	AddCommandListener(Command_Radio, "regroup");
	AddCommandListener(Command_Radio, "followme");
	AddCommandListener(Command_Radio, "takingfire");
	AddCommandListener(Command_Radio, "go");
	AddCommandListener(Command_Radio, "fallback");
	AddCommandListener(Command_Radio, "sticktog");
	AddCommandListener(Command_Radio, "getinpos");
	AddCommandListener(Command_Radio, "stormfront");
	AddCommandListener(Command_Radio, "report");
	AddCommandListener(Command_Radio, "roger");
	AddCommandListener(Command_Radio, "enemyspot");
	AddCommandListener(Command_Radio, "needbackup");
	AddCommandListener(Command_Radio, "sectorclear");
	AddCommandListener(Command_Radio, "inposition");
	AddCommandListener(Command_Radio, "reportingin");
	AddCommandListener(Command_Radio, "negative");
	AddCommandListener(Command_Radio, "enemydown");

	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
}

public OnPluginEnd()
{
	Void_ResetForce();
	
	for(new i = 1; i <= MaxClients; i++)
		for(new j = 0; j < HANDLE_DATA; j++)
			Void_ClearHandle(i, j);
}

public OnConfigsExecuted()
{
	if(g_bEnabled && g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
				
				if(g_bRecall)
				{
					g_iData[i][PLAYER_RECALL_TIME] = -1;
					if(g_iRecallCount)
						g_iData[i][PLAYER_RECALL_COUNT] = g_iRecallCount;

					g_bActions[i][ACTION_RECALL] = false;
					GetClientAbsOrigin(i, g_fPositions[i][POSITION_SPAWN]);
				}

				if(g_bBoost)
				{
					g_iData[i][PLAYER_BOOST_TIME] = -1;
					if(g_iBoostCount)
						g_iData[i][PLAYER_BOOST_COUNT] = g_iBoostCount;
						
					g_bActions[i][ACTION_BOOST] = false;
				}

				if(g_bSlow)
				{
					g_iData[i][PLAYER_SLOW_TIME] = -1;
					if(g_iSlowCount)
						g_iData[i][PLAYER_SLOW_COUNT] = g_iSlowCount;
						
					g_iData[i][PLAYER_SLOW_LEFT] = 0;
				}
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
			}
		}
	}
}

public OnMapStart()
{
	Void_SetDefaults();
	
	if(g_bEnabled)
	{
		PrecacheModel("models/Characters/Hostage_01.mdl");
		PrecacheModel("models/Characters/Hostage_02.mdl");
		PrecacheModel("models/Characters/Hostage_03.mdl");
		PrecacheModel("models/Characters/Hostage_04.mdl");
	}
}

public OnMapEnd()
{
	Void_ResetForce();
	
	for(new i = 1; i <= MaxClients; i++)
		for(new j = 0; j < HANDLE_DATA; j++)
			Void_ClearHandle(i, j);
}

public OnMapTimeLeftChanged()
{
	if(g_bEnabled && g_bForce)
	{
		Void_ResetForce();
		Void_StartForce();
	}
}

public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		if(g_bRecall)
			g_iData[client][PLAYER_RECALL_TIME] = -1;
		
		if(g_bBoost)
			g_iData[client][PLAYER_BOOST_TIME] = -1;
		
		if(g_bSlow)
			g_iData[client][PLAYER_SLOW_TIME] = -1;
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = false;
		
		for(new j = 0; j < HANDLE_DATA; j++)
			Void_ClearHandle(client, j);
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		if(g_iStrip)
			CreateTimer(0.1, Timer_Strip, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(g_bRecall)
				{
					g_bActions[i][ACTION_RECALL] = false;
					g_iData[i][PLAYER_RECALL_TIME] = -1;
				}

				if(g_bBoost)
				{
					g_bActions[i][ACTION_BOOST] = false;
					g_iData[i][PLAYER_BOOST_TIME] = -1;
				}

				if(g_bSlow)
				{
					g_iData[i][PLAYER_SLOW_LEFT] = 0;
					g_iData[i][PLAYER_SLOW_TIME] = -1;
				}
				
				for(new j = 0; j < HANDLE_DATA; j++)
					Void_ClearHandle(i, j);
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] == CS_TEAM_SPECTATOR)
		{
			g_bAlive[client] = false;
			for(new j = 0; j < HANDLE_DATA; j++)
				Void_ClearHandle(client, j);
		}
		if(GetEventInt(event, "oldteam") == CS_TEAM_NONE)
			PrintToChat(client, "%s", g_sAdvert);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= 1)
			return Plugin_Continue;

		g_bAlive[client] = true;
		if(g_bRecall)
		{
			if(g_iRecallCount)
				g_iData[client][PLAYER_RECALL_COUNT] = g_iRecallCount;

			g_bActions[client][ACTION_RECALL] = false;
			GetClientAbsOrigin(client, g_fPositions[client][POSITION_SPAWN]);
		}

		if(g_bBoost)
		{
			if(g_iBoostCount)
				g_iData[client][PLAYER_BOOST_COUNT] = g_iBoostCount;
				
			g_bActions[client][ACTION_BOOST] = false;
		}

		if(g_bSlow)
		{
			if(g_iSlowCount)
				g_iData[client][PLAYER_SLOW_COUNT] = g_iSlowCount;
				
			g_iData[client][PLAYER_SLOW_LEFT] = 0;
		}

		if(g_iCash >= 0)
			SetEntProp(client, Prop_Send, "m_iAccount", g_iCash);
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
		
		g_bAlive[client] = false;
		for(new j = 0; j < HANDLE_DATA; j++)
			Void_ClearHandle(client, j);
	}

	return Plugin_Continue;
}

public Action:Command_Recall(client, args)
{
	if (g_bEnabled)
	{
		if(!g_bRecall)
			PrintToChat(client, "%sSorry, but the recall command is currently disabled!", PLUGIN_PREFIX);
		else if(!g_bAlive[client])
			PrintToChat(client, "%sYou cannot recall while you're dead!", PLUGIN_PREFIX);
		else if(g_bActions[client][ACTION_RECALL])
			PrintToChat(client, "%sYou are already waiting on a recall!", PLUGIN_PREFIX);
		else if(g_iRecallCount && g_iData[client][PLAYER_RECALL_COUNT] <= 0)
			PrintToChat(client, "%sYou do not have any recall usages remaining!", PLUGIN_PREFIX);
		else if(g_iRecallRecovery && g_iData[client][PLAYER_RECALL_TIME] > GetTime())
		{
			new _iTime = (g_iData[client][PLAYER_RECALL_TIME] - GetTime());
			PrintToChat(client, "%sYou must wait %d more second%s before you can recall again!", PLUGIN_PREFIX, _iTime, _iTime == 1 ? "" : "s");
		}
		else
		{
			g_bActions[client][ACTION_RECALL] = true;
			if(g_fRecallDelay)
			{
				g_hHandles[client][HANDLE_RECALL] = CreateTimer(g_fRecallDelay, Timer_Recall, client, TIMER_FLAG_NO_MAPCHANGE);
				if(g_fRecallCancel)
				{
					PrintToChat(client, "%sYou'll be returned to your spawn position in %.1f seconds; moving may interrupt your recall!", PLUGIN_PREFIX, g_fRecallDelay);
					GetClientAbsOrigin(client, g_fPositions[client][POSITION_RECALL]);
				}
				else
					PrintToChat(client, "%sYou'll be returned to your spawn position in %.1f seconds!", PLUGIN_PREFIX, g_fRecallDelay);
			}
			else
				g_hHandles[client][HANDLE_RECALL] = CreateTimer(0.1, Timer_Recall, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Handled;
}

public Action:Timer_Recall(Handle:timer, any:client)
{
	if(g_bAlive[client] && IsClientInGame(client))
	{
		if(g_fRecallCancel)
		{
			decl Float:_fLocation[3], Float:_fDistance;
			GetClientAbsOrigin(client, _fLocation);
			_fDistance = GetVectorDistance(_fLocation, g_fPositions[client][POSITION_RECALL]);
			if(_fDistance >= g_fRecallCancel)
			{
				PrintToChat(client, "%sYour recall has been terminated as you moved too far away from your original position!", PLUGIN_PREFIX);
				
				g_hHandles[client][HANDLE_RECALL] = INVALID_HANDLE;
				g_bActions[client][ACTION_RECALL] = false;
				return Plugin_Stop;
			}
		}

		if(g_iRecallRecovery)
			g_iData[client][PLAYER_RECALL_TIME] = GetTime() + g_iRecallRecovery;

		TeleportEntity(client, g_fPositions[client][POSITION_SPAWN], NULL_VECTOR, NULL_VECTOR);
		if(g_iRecallCount)
		{
			g_iData[client][PLAYER_RECALL_COUNT]--;
			switch(g_iData[client][PLAYER_RECALL_COUNT])
			{
				case 0:
					PrintToChat(client, "%sYou've been returned to your spawn position, and you have no recall uses remaining!", PLUGIN_PREFIX);
				case 1:
					PrintToChat(client, "%sYou've been returned to your spawn position, and you have 1/%d recall use remaining!", PLUGIN_PREFIX, g_iRecallCount);
				default:
					PrintToChat(client, "%sYou've been returned to your spawn position, and you have %d/%d recall uses remaining!", PLUGIN_PREFIX, g_iData[client][PLAYER_RECALL_COUNT], g_iRecallCount);
			}
		}
		else
			PrintToChat(client, "%sYou've been returned to your spawn position!", PLUGIN_PREFIX);
	}

	g_hHandles[client][HANDLE_RECALL] = INVALID_HANDLE;
	g_bActions[client][ACTION_RECALL] = false;
	return Plugin_Stop;
}

public Action:Command_Boost(client, args)
{
	if (g_bEnabled)
	{
		if(!g_bBoost)
			PrintToChat(client, "%sSorry, but the boost command is currently disabled!", PLUGIN_PREFIX);
		else if(!g_bAlive[client])
			PrintToChat(client, "%sYou cannot boost while you're dead!", PLUGIN_PREFIX);
		else if(g_bActions[client][ACTION_BOOST])
			PrintToChat(client, "%sYou are already waiting on a boost!", PLUGIN_PREFIX);
		else if(g_iBoostCount && g_iData[client][PLAYER_BOOST_COUNT] <= 0)
			PrintToChat(client, "%sYou do not have any boost usages remaining!", PLUGIN_PREFIX);
		else if(g_iBoostRecovery && g_iData[client][PLAYER_BOOST_TIME] > GetTime())
		{
			new _iTime = (g_iData[client][PLAYER_BOOST_TIME] - GetTime());
			PrintToChat(client, "%sYou must wait %d more second%s before you can boost again!", PLUGIN_PREFIX, _iTime, _iTime == 1 ? "" : "s");
		}
		else
		{
			g_bActions[client][ACTION_BOOST] = true;
			if(g_fBoostDelay)
			{
				g_hHandles[client][HANDLE_BOOST] = CreateTimer(g_fBoostDelay, Timer_Boost, client, TIMER_FLAG_NO_MAPCHANGE);
				if(g_fBoostCancel)
				{
					PrintToChat(client, "%sYou'll receive your boost in %.1f seconds; moving may interrupt your boost!", PLUGIN_PREFIX, g_fBoostDelay);
					GetClientAbsOrigin(client, g_fPositions[client][POSITION_BOOST]);
				}
				else
					PrintToChat(client, "%sYou'll receive your boost in %.1f seconds!", PLUGIN_PREFIX, g_fBoostDelay);
			}
			else
				g_hHandles[client][HANDLE_BOOST] = CreateTimer(0.1, Timer_Boost, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Handled;
}

public Action:Timer_Boost(Handle:timer, any:client)
{
	if(g_bAlive[client] && IsClientInGame(client))
	{
		if(g_fBoostCancel)
		{
			decl Float:_fLocation[3], Float:_fDistance;
			GetClientAbsOrigin(client, _fLocation);
			_fDistance = GetVectorDistance(_fLocation, g_fPositions[client][POSITION_BOOST]);
			if(_fDistance >= g_fBoostCancel)
			{
				PrintToChat(client, "%sYour boost has been terminated as you moved too far away from your original position!", PLUGIN_PREFIX);
				
				g_hHandles[client][HANDLE_BOOST] = INVALID_HANDLE;
				g_bActions[client][ACTION_BOOST] = false;
				return Plugin_Stop;
			}
		}

		if(g_iBoostRecovery)
			g_iData[client][PLAYER_BOOST_TIME] = GetTime() + g_iBoostRecovery;

		if(g_iBoostCount)
		{
			g_iData[client][PLAYER_BOOST_COUNT]--;
			switch(g_iData[client][PLAYER_BOOST_COUNT])
			{
				case 0:
					PrintToChat(client, "%sYou have no boost uses remaining!", PLUGIN_PREFIX);
				case 1:
					PrintToChat(client, "%sYou have 1/%d boost use remaining!", PLUGIN_PREFIX, g_iBoostCount);
				default:
					PrintToChat(client, "%sYou have %d/%d boost uses remaining!", PLUGIN_PREFIX, g_iData[client][PLAYER_BOOST_COUNT], g_iBoostCount);
			}
		}

		decl Float:_fAngles[3], Float:_fVectors[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", _fVectors);
		GetClientEyeAngles(client, _fAngles);

		for(new i = 0; i <= 1; i++)
			_fAngles[i] = DegToRad(_fAngles[i]);
		_fVectors[0] = (Cosine(_fAngles[1]) * g_iBoostPower) + _fVectors[0];
		_fVectors[1] = (Sine(_fAngles[1]) * g_iBoostPower) + _fVectors[1];
		_fVectors[2] = (Cosine(_fAngles[0]) * g_iBoostPower) + _fVectors[2];
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, _fVectors);
	}

	g_hHandles[client][HANDLE_BOOST] = INVALID_HANDLE;
	g_bActions[client][ACTION_BOOST] = false;
	return Plugin_Stop;
}

public Action:Command_Slow(client, args)
{
	if (g_bEnabled)
	{
		if(!g_bSlow)
			PrintToChat(client, "%sSorry, but the slow command is currently disabled!", PLUGIN_PREFIX);
		if(!g_bAlive[client])
			PrintToChat(client, "%sYou cannot enter slow motion while you're dead!", PLUGIN_PREFIX);
		else if(g_iData[client][PLAYER_SLOW_LEFT])
			PrintToChat(client, "%sYou are already in slow motion!", PLUGIN_PREFIX);
		else if(g_iSlowCount && g_iData[client][PLAYER_SLOW_COUNT] <= 0)
			PrintToChat(client, "%sYou do not have any slow usages remaining!", PLUGIN_PREFIX);
		else if(g_iSlowRecovery && g_iData[client][PLAYER_SLOW_TIME] > GetTime())
		{
			new _iTime = (g_iData[client][PLAYER_SLOW_TIME] - GetTime());
			PrintToChat(client, "%sYou must wait %d more second%s before you can enter slow motion again!", PLUGIN_PREFIX, _iTime, _iTime == 1 ? "" : "s");
		}
		else
		{
			g_hHandles[client][HANDLE_SLOW] = CreateTimer(1.0, Timer_Slow, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			PrintHintText(client, "Slow Motion: %d Second%s Remaining", g_iSlowDuration, g_iSlowDuration == 1 ? "" : "s");

			g_iData[client][PLAYER_SLOW_LEFT] = g_iSlowDuration;
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fSlowPercent);
			PrintToChat(client, "%sYou've entered slow motion mode at %d%s normal speed!", PLUGIN_PREFIX, (100 - g_iSlowPercent), "%");
		}
	}

	return Plugin_Handled;
}

public Action:Timer_Slow(Handle:timer, any:client)
{
	if(g_bAlive[client] && IsClientInGame(client))
	{
		if(g_iData[client][PLAYER_SLOW_LEFT] > 1)
		{
			g_iData[client][PLAYER_SLOW_LEFT]--;
			PrintHintText(client, "Slow Motion: %d Second%s Remaining", g_iData[client][PLAYER_SLOW_LEFT], g_iData[client][PLAYER_SLOW_LEFT] == 1 ? "s" : "");

			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fSlowPercent);
			return Plugin_Continue;
		}
		else
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			PrintHintText(client, "Slow Motion: Expired");

			if(g_iSlowRecovery)
				g_iData[client][PLAYER_SLOW_TIME] = GetTime() + g_iSlowRecovery;

			if(g_iSlowCount)
			{
				g_iData[client][PLAYER_SLOW_COUNT]--;
				switch(g_iData[client][PLAYER_SLOW_COUNT])
				{
					case 0:
						PrintToChat(client, "%sYou have no slow motion uses remaining!", PLUGIN_PREFIX);
					case 1:
						PrintToChat(client, "%sYou have 1/%d slow motion use remaining!", PLUGIN_PREFIX, g_iSlowCount);
					default:
						PrintToChat(client, "%sYou have %d/%d slow motion uses remaining!", PLUGIN_PREFIX, g_iData[client][PLAYER_SLOW_COUNT], g_iSlowCount);
				}
			}
		}
	}

	g_hHandles[client][HANDLE_SLOW] = INVALID_HANDLE;
	g_iData[client][PLAYER_SLOW_LEFT] = 0;
	return Plugin_Stop;
}

public Action:Command_Kill(client, const String:command[], argc)
{
	if (g_bEnabled && g_bSuicide)
	{
		if(client && IsClientInGame(client))
		{
			PrintToChat(client, "%sSorry, but the ability to suicide has been disabled!", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Radio(client, const String:command[], argc)
{
	if (g_bEnabled && g_bRadio)
	{
		if(client && IsClientInGame(client))
		{
			PrintToChat(client, "%sSorry, but all radio commands have been disabled!", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

Void_ResetForce()
{
	if(g_hTimerForce != INVALID_HANDLE && CloseHandle(g_hTimerForce))
		g_hTimerForce = INVALID_HANDLE;
}

Void_StartForce()
{
	new _iTimeLeft;
	if(GetMapTimeLeft(_iTimeLeft) && _iTimeLeft > 0)
	{
		if((_iTimeLeft - 180) > 0)
			g_hTimerForce = CreateTimer(float(_iTimeLeft - 180), Timer_WarnForce, 3, TIMER_FLAG_NO_MAPCHANGE);
		else
		{
			PrintToChatAll("%sThe map will change in \x04%.1f\x03 minutes!", PLUGIN_PREFIX, float(_iTimeLeft / 60) + 1.0);
			g_hTimerForce = CreateTimer(float(_iTimeLeft), Timer_IssueForce, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_WarnForce(Handle:timer, any:step)
{
	if(!HasEndOfMapVoteFinished())
		g_hTimerForce = CreateTimer(60.0, Timer_WarnForce, step, TIMER_FLAG_NO_MAPCHANGE);
	else
	{
		if(step > 0)
		{
			PrintToChatAll("%sThe map will change in \x04%d\x03 minute%s!", PLUGIN_PREFIX, step, step == 1 ? "" : "s");
			g_hTimerForce = CreateTimer(60.0, Timer_WarnForce, (step - 1), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			g_hTimerForce = CreateTimer(0.1, Timer_IssueForce, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_IssueForce(Handle:timer)
{
	decl String:_sMap[64];
	if(GetNextMap(_sMap, sizeof(_sMap)))
		ForceChangeLevel(_sMap, "Forced Map Change");
	else
		LogError("Could not locate a valid next map. %s was the provided string.", _sMap);

	g_hTimerForce = INVALID_HANDLE;
}

public Action:Timer_Strip(Handle:timer)
{
	decl String:_sTemp[64];
	new _iTemp = GetMaxEntities();
	for(new i = MaxClients + 1; i <= _iTemp; i++)
	{
		if(!IsValidEdict(i) || !IsValidEntity(i))
			continue;
		
		new _iContains;
		GetEdictClassname(i, _sTemp, sizeof(_sTemp));
		switch(g_iStrip)
		{
			case -1:
				_iContains = StrContains("func_bomb_target|func_hostage_rescue|c4|hostage_entity|func_buyzone", _sTemp);
			case 1:
				_iContains = StrContains("func_buyzone", _sTemp);
			case 2:
				_iContains = StrContains("func_bomb_target|func_hostage_rescue|c4|hostage_entity", _sTemp);
		}
		 
		if(_iContains > -1 && i > MaxClients)
			RemoveEdict(i);
	}
}

Void_ClearHandle(client, index)
{
	if(g_hHandles[client][index] != INVALID_HANDLE && CloseHandle(g_hHandles[client][index]))
		g_hHandles[client][index] = INVALID_HANDLE;
}

Void_SetAdvert()
{
	if(!g_bRecall && !g_bBoost && !g_bSlow)
		g_bAdvert = false;
	else
	{
		new _iCount;
		decl String:_sBuffer[16];
		Format(g_sAdvert, sizeof(g_sAdvert), "%sThe following commands are currently available: {1}{2}{3}~!", PLUGIN_PREFIX);

		if(g_bRecall)
		{
			_iCount++;
			Format(_sBuffer, sizeof(_sBuffer), "{%d}", _iCount);
			ReplaceString(g_sAdvert, sizeof(g_sAdvert), _sBuffer, "!recall, ");
		}
		
		if(g_bBoost)
		{
			_iCount++;
			Format(_sBuffer, sizeof(_sBuffer), "{%d}", _iCount);
			ReplaceString(g_sAdvert, sizeof(g_sAdvert), _sBuffer, "!boost, ");
		}
		
		if(g_bSlow)
		{
			_iCount++;
			Format(_sBuffer, sizeof(_sBuffer), "{%d}", _iCount);
			ReplaceString(g_sAdvert, sizeof(g_sAdvert), _sBuffer, "!slow, ");
		}
		
		ReplaceString(g_sAdvert, sizeof(g_sAdvert), ", ~!", "!");
	}
}

Void_SetDefaults()
{
	switch(GetConVarInt(g_hEnabled))
	{
		case -1:
			g_bEnabled = true;
		case 0:
			g_bEnabled = false;
		case 1:
		{
			decl String:_sTemp[128];
			GetCurrentMap(_sTemp, sizeof(_sTemp));
			
			g_bEnabled = false;
			for(new i = 0; i < NUM_MAP_CHECKS; i++)
			{
				if(StrContains(_sTemp, _sMapChecks[i], false))
				{
					g_bEnabled = true;
					break;
				}
			}
		}
	}
	g_iStrip = GetConVarInt(g_hStrip);
	g_bSuicide = GetConVarInt(g_hSuicide) ? true : false;
	g_bRadio = GetConVarInt(g_hRadio) ? true :  false;
	g_bForce = GetConVarInt(g_hForce) ? true : false;
	if(g_bForce && EndOfMapVoteEnabled())
		Void_StartForce();
	else
		g_bForce = false;
	g_iAir = GetConVarInt(g_hAir);
	g_iHop = GetConVarInt(g_hHop);
	g_iRecall = GetConVarInt(g_hRecall);
	switch(g_iRecall)
	{
		case -1:
			g_bRecall = true;
		case 0:
			g_bRecall = false;
		case 1:
		{
			decl String:_sTemp[128];
			GetCurrentMap(_sTemp, sizeof(_sTemp));
			
			g_bRecall = false;
			for(new i = 0; i < NUM_MAP_CHECKS; i++)
			{
				if(StrContains(_sTemp, _sMapChecks[i], false))
				{
					g_bRecall = true;
					break;
				}
			}
		}
	}
	g_iRecallRecovery = GetConVarInt(g_hRecallRecovery);
	g_iRecallCount = GetConVarInt(g_hRecallCount);
	g_fRecallDelay = GetConVarFloat(g_hRecallDelay);
	g_fRecallCancel = GetConVarFloat(g_hRecallCancel);
	g_iBoost = GetConVarInt(g_hBoost);
	switch(g_iBoost)
	{
		case -1:
			g_bBoost = true;
		case 0:
			g_bBoost = false;
		case 1:
		{
			decl String:_sTemp[128];
			GetCurrentMap(_sTemp, sizeof(_sTemp));
			
			g_bBoost = false;
			for(new i = 0; i < NUM_MAP_CHECKS; i++)
			{
				if(StrContains(_sTemp, _sMapChecks[i], false))
				{
					g_bBoost = true;
					break;
				}
			}
		}
	}
	g_iBoostRecovery = GetConVarInt(g_hBoostRecovery);
	g_iBoostPower = GetConVarInt(g_hBoostPower);
	g_iBoostCount = GetConVarInt(g_hBoostCount);
	g_fBoostDelay = GetConVarFloat(g_hBoostDelay);
	g_fBoostCancel = GetConVarFloat(g_hBoostCancel);
	g_iCash = GetConVarInt(g_hCash);
	g_iSlow = GetConVarInt(g_hSlow);
	switch(g_iSlow)
	{
		case -1:
			g_bSlow = true;
		case 0:
			g_bSlow = false;
		case 1:
		{
			decl String:_sTemp[128];
			GetCurrentMap(_sTemp, sizeof(_sTemp));
			
			g_bSlow = false;
			for(new i = 0; i < NUM_MAP_CHECKS; i++)
			{
				if(StrContains(_sTemp, _sMapChecks[i], false))
				{
					g_bSlow = true;
					break;
				}
			}
		}
	}
	g_iSlowRecovery = GetConVarInt(g_hSlowRecovery);
	g_iSlowPercent = GetConVarInt(g_hSlowPercent);
	g_fSlowPercent = float(100 - g_iSlowPercent) / 100.0;
	g_iSlowDuration = GetConVarInt(g_hSlowDuration);
	g_iSlowCount = GetConVarInt(g_hSlowCount);
	
	g_bAdvert = GetConVarInt(g_hAdvert) ? true : false;
	if(g_bAdvert)
		Void_SetAdvert();

	if(g_iAir && GetConVarInt(g_hAirAccelerate) != g_iAir)
		SetConVarInt(g_hAirAccelerate, g_iAir, true);

	if(g_iHop && GetConVarInt(g_henablebunnyhopping) != g_iHop)
		SetConVarInt(g_henablebunnyhopping, g_iHop, true);
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		switch(StringToInt(newvalue))
		{
			case -1:
				g_bEnabled = true;
			case 0:
				g_bEnabled = false;
			case 1:
			{
				decl String:_sTemp[128];
				GetCurrentMap(_sTemp, sizeof(_sTemp));
				
				g_bEnabled = false;
				for(new i = 0; i < NUM_MAP_CHECKS; i++)
				{
					if(StrContains(_sTemp, _sMapChecks[i], false))
					{
						g_bEnabled = true;
						break;
					}
				}
			}
		}
		
		if(StringToInt(oldvalue))
		{
			PrecacheModel("models/Characters/Hostage_01.mdl");
			PrecacheModel("models/Characters/Hostage_02.mdl");
			PrecacheModel("models/Characters/Hostage_03.mdl");
			PrecacheModel("models/Characters/Hostage_04.mdl");
		}
	}
	else if(cvar == g_hStrip)
	{
		g_iStrip = StringToInt(newvalue);
		if(g_iStrip)
			CreateTimer(0.1, Timer_Strip, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(cvar == g_hSuicide)
		g_bSuicide = StringToInt(newvalue) ? false : false;
	else if(cvar == g_hRadio)
		g_bRadio = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hForce)
	{
		Void_ResetForce();

		g_bForce = StringToInt(newvalue) ? true : false;
		if(g_bForce && EndOfMapVoteEnabled())
			Void_StartForce();
		else
			g_bForce = false;
	}
	else if(cvar == g_hAir)
		g_iAir = StringToInt(newvalue);
	else if(cvar == g_hAir)
		g_iHop = StringToInt(newvalue);
	else if(cvar == g_hRecall)
	{
		g_iRecall = StringToInt(newvalue);
		switch(g_iRecall)
		{
			case -1:
				g_bRecall = true;
			case 0:
				g_bRecall = false;
			case 1:
			{
				decl String:_sTemp[128];
				GetCurrentMap(_sTemp, sizeof(_sTemp));
				
				g_bRecall = false;
				for(new i = 0; i < NUM_MAP_CHECKS; i++)
				{
					if(StrContains(_sTemp, _sMapChecks[i], false))
					{
						g_bRecall = true;
						break;
					}
				}
			}
		}

		if(g_bRecall)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bActions[i][ACTION_RECALL] = false;
					g_iData[i][PLAYER_RECALL_TIME] = -1;
				}
			}
		}
		
		if(g_bAdvert)
			Void_SetAdvert();
	}
	else if(cvar == g_hRecallRecovery)
		g_iRecallRecovery = StringToInt(newvalue);
	else if(cvar == g_hRecallCount)
		g_iRecallCount = StringToInt(newvalue);
	else if(cvar == g_hRecallDelay)
		g_fRecallDelay = StringToFloat(newvalue);
	else if(cvar == g_hRecallCancel)
		g_fRecallCancel = StringToFloat(newvalue);
	else if(cvar == g_hBoost)
	{
		g_iBoost = StringToInt(newvalue);
		switch(g_iBoost)
		{
			case -1:
				g_bBoost = true;
			case 0:
				g_bBoost = false;
			case 1:
			{
				decl String:_sTemp[128];
				GetCurrentMap(_sTemp, sizeof(_sTemp));
				
				g_bBoost = false;
				for(new i = 0; i < NUM_MAP_CHECKS; i++)
				{
					if(StrContains(_sTemp, _sMapChecks[i], false))
					{
						g_bBoost = true;
						break;
					}
				}
			}
		}

		if(g_bBoost)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bActions[i][ACTION_BOOST] = false;
					g_iData[i][PLAYER_BOOST_TIME] = -1;
				}
			}
		}
		
		if(g_bAdvert)
			Void_SetAdvert();
	}
	else if(cvar == g_hBoostRecovery)
		g_iBoostRecovery = StringToInt(newvalue);
	else if(cvar == g_hBoostPower)
		g_iBoostPower = StringToInt(newvalue);
	else if(cvar == g_hBoostCount)
		g_iBoostCount = StringToInt(newvalue);
	else if(cvar == g_hBoostDelay)
		g_fBoostDelay = StringToFloat(newvalue);
	else if(cvar == g_hBoostCancel)
		g_fBoostCancel = StringToFloat(newvalue);
	else if(cvar == g_hCash)
		g_iCash = StringToInt(newvalue);
	else if(cvar == g_hSlow)
	{
		g_iSlow = StringToInt(newvalue);
		switch(g_iSlow)
		{
			case -1:
				g_bSlow = true;
			case 0:
				g_bSlow = false;
			case 1:
			{
				decl String:_sTemp[128];
				GetCurrentMap(_sTemp, sizeof(_sTemp));
				
				g_bSlow = false;
				for(new i = 0; i < NUM_MAP_CHECKS; i++)
				{
					if(StrContains(_sTemp, _sMapChecks[i], false))
					{
						g_bSlow = true;
						break;
					}
				}
			}
		}

		if(g_bSlow)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iData[i][PLAYER_SLOW_LEFT] = 0;
					g_iData[i][PLAYER_SLOW_TIME] = -1;
				}
			}
		}

		if(g_bAdvert)
			Void_SetAdvert();
	}
	else if(cvar == g_hSlowRecovery)
		g_iSlowRecovery = StringToInt(newvalue);
	else if(cvar == g_hSlowPercent)
	{
		g_iSlowPercent = StringToInt(newvalue);
		g_fSlowPercent = float(100 - g_iSlowPercent) / 100.0;
	}
	else if(cvar == g_hSlowDuration)
		g_iSlowDuration = StringToInt(newvalue);
	else if(cvar == g_hSlowCount)
		g_iSlowCount = StringToInt(newvalue);
	else if(cvar == g_hAdvert)
	{
		g_bAdvert = StringToInt(newvalue) ? true : false;
		if(g_bAdvert)
			Void_SetAdvert();
	}
	else if(cvar == g_hAirAccelerate)
	{
		g_iAir = StringToInt(newvalue);
		if(StringToInt(oldvalue) != g_iAir)
			SetConVarInt(g_hAirAccelerate, g_iAir, true);
	}
	else if(cvar == g_henablebunnyhopping)
	{
		g_iHop = StringToInt(newvalue);
		if(StringToInt(oldvalue) != g_iHop)
			SetConVarInt(g_henablebunnyhopping, g_iHop, true);
	}
}