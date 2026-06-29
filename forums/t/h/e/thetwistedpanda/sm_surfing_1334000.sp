/* 
	Fixed an error where sm_surfing_enable 1 resulted in the plugin always being enabled.
	Added forced sv_enablebunnyhopping support from X3S2's version.
	Optimized / properly coded a few areas of coding.
	Removed requirement of running CS:S (potential to run on other mods).
	Fixed an issue with the !boost command possibly not obeying strength.
	Replaced instances of RemoveEdict with AcceptEntityInput(_, "Kill") to resolve potential crashes.
	Fixed an issue where SDKHooks used a hardcoded value instead of a bit.
	Replaced internal variables with a proper naming scheme to improve readability.
	Added translations support.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.3.0"

#define MAX_CHAT_CMDS 8
#define MAX_CHAT_CMDS_LENGTH 32

#define HANDLE_DATA 3
//-=-=
#define HANDLE_RECALL 0
#define HANDLE_BOOST 1
#define HANDLE_SLOW 2
new Handle:g_hTimer_Players[MAXPLAYERS + 1][HANDLE_DATA];

#define PLAYER_DATA 7
//-=-=
#define PLAYER_RECALL_TIME 0
#define PLAYER_RECALL_COUNT 1
#define PLAYER_BOOST_TIME 2
#define PLAYER_BOOST_COUNT 3
#define PLAYER_SLOW_TIME 4
#define PLAYER_SLOW_COUNT 5
#define PLAYER_SLOW_LEFT 6
new g_iPlayerData[MAXPLAYERS + 1][PLAYER_DATA];

#define ACTION_DATA 2
//-=-=
#define ACTION_RECALL 0
#define ACTION_BOOST 1
new bool:g_bPlayerActions[MAXPLAYERS + 1][ACTION_DATA];

#define POSITION_DATA 3
//-=-=
#define POSITION_SPAWN 0
#define POSITION_RECALL 1
#define POSITION_BOOST 2
new Float:g_fPlayerPositions[MAXPLAYERS + 1][POSITION_DATA][3];

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hCheck = INVALID_HANDLE;
new Handle:g_hMapStrip = INVALID_HANDLE;
new Handle:g_hBlockSuicide = INVALID_HANDLE;
new Handle:g_hBlockRadio = INVALID_HANDLE;
new Handle:g_hForceBunny = INVALID_HANDLE;
new Handle:g_hForceAccelerate = INVALID_HANDLE;
new Handle:g_hEnableRecall = INVALID_HANDLE;
new Handle:g_hRecallRecovery = INVALID_HANDLE;
new Handle:g_hRecallCount = INVALID_HANDLE;
new Handle:g_hRecallDelay = INVALID_HANDLE;
new Handle:g_hRecallCancel = INVALID_HANDLE;
new Handle:g_hEnableBoost = INVALID_HANDLE;
new Handle:g_hBoostRecovery = INVALID_HANDLE;
new Handle:g_hBoostPower = INVALID_HANDLE;
new Handle:g_hBoostCount = INVALID_HANDLE;
new Handle:g_hBoostDelay = INVALID_HANDLE;
new Handle:g_hBoostCancel = INVALID_HANDLE;
new Handle:g_hSpawnCash = INVALID_HANDLE;
new Handle:g_hEnableSlow = INVALID_HANDLE;
new Handle:g_hSlowRecovery = INVALID_HANDLE;
new Handle:g_hSlowPercent = INVALID_HANDLE;
new Handle:g_hSlowDuration = INVALID_HANDLE;
new Handle:g_hSlowCount = INVALID_HANDLE;
new Handle:g_hTeleCmds = INVALID_HANDLE;
new Handle:g_hBoostCmds = INVALID_HANDLE;
new Handle:g_hSlowCmds = INVALID_HANDLE;
new Handle:g_hFallDamage = INVALID_HANDLE;
new Handle:g_hTeleTrie = INVALID_HANDLE;
new Handle:g_hBoostTrie = INVALID_HANDLE;
new Handle:g_hSlowTrie = INVALID_HANDLE;
new Handle:g_hAirAccelerate = INVALID_HANDLE;
new Handle:g_hEnableBunnyHopping = INVALID_HANDLE;

new bool:g_bLateLoad, bool:g_bEnabled, bool:g_bBlockSuicide, bool:g_bBlockRadio, bool:g_bRecall, bool:g_bSlow, bool:g_bBoost, bool:g_bForceBunny;
new Float:g_fRecallDelay, Float:g_fRecallCancel, Float:g_fBoostDelay, Float:g_fBoostCancel, Float:g_fSlowPercent, Float:g_fBoostPower;
new g_iMapStrip, g_iForceAccelerate, g_iRecall, g_iRecallRecovery, g_iRecallCount, g_iBoost, g_iBoostRecovery, g_iBoostCount, g_iCash, g_iSlow, g_iSlowRecovery, g_iSlowPercent, g_iSlowDuration, g_iSlowCount, g_iTotalMapChecks, g_iFalling;
new String:g_sTeleCmds[MAX_CHAT_CMDS][MAX_CHAT_CMDS_LENGTH], String:g_sBoostCmds[MAX_CHAT_CMDS][MAX_CHAT_CMDS_LENGTH], String:g_sSlowCmds[MAX_CHAT_CMDS][MAX_CHAT_CMDS_LENGTH], String:g_sMapChecks[32][128];

public Plugin:myinfo =
{
	name = "Surfing Config",
	author = "Twisted|Panda",
	description = "Plugin that provides various settings geared for Surf/Slide maps.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/index.php"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("sm_surfing.phrases");

	CreateConVar("sm_surfing_version", PLUGIN_VERSION, "Surfing Config: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_surfing_enable", "1", "Determines plugin functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Check Map)", FCVAR_NONE, true, -1.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	
	g_hCheck = CreateConVar("sm_surfing_enable_check", "surf_, slide_", "The maps that Surfing Config is enabled on, if sm_surfing_enable is set to 1. Separate multiple checks with \", \", up to 32 checks allowed.", FCVAR_NONE);
	HookConVarChange(g_hCheck, OnSettingsChange);
	
	g_hMapStrip = CreateConVar("sm_surfing_strip", "0", "Determines stripping functionality. (-1 = Strip Buyzones/Objectives, 0 = Disabled, 1 = Strip Buyzones, 2 = Strip Objectives)", FCVAR_NONE, true, -1.0, true, 2.0);
	HookConVarChange(g_hMapStrip, OnSettingsChange);
	
	g_hBlockSuicide = CreateConVar("sm_surfing_block_suicide", "1", "If enabled, players will be unable to kill themselves via kill/explode.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBlockSuicide, OnSettingsChange);
	
	g_hBlockRadio = CreateConVar("sm_surfing_block_radio", "1", "If enabled, player will not be able to issue any radio commands.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBlockRadio, OnSettingsChange);
	
	g_hForceAccelerate = CreateConVar("sm_surfing_air_accelerate", "1000", "If greater than 0, sv_airaccelerate is always forced to this value.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hForceAccelerate, OnSettingsChange);
	
	g_hForceBunny = CreateConVar("sm_surfing_bunny_hopping", "1", "If enabled, sv_enablebunnyhopping will be forced on.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hForceBunny, OnSettingsChange);
	
	g_hEnableRecall = CreateConVar("sm_surfing_teleport", "-1", "Determines teleport command functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Check Map)", FCVAR_NONE, true, -1.0, true, 1.0);
	HookConVarChange(g_hEnableRecall, OnSettingsChange);
	
	g_hRecallRecovery = CreateConVar("sm_surfing_teleport_recovery", "60.0", "The number of seconds a player must wait before being able to use sm_recall again.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hRecallRecovery, OnSettingsChange);
	
	g_hRecallCount = CreateConVar("sm_surfing_teleport_count", "3", "The number of recall usages players will receive upon spawn. (0 = Unlimited)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hRecallCount, OnSettingsChange);
	
	g_hRecallDelay = CreateConVar("sm_surfing_teleport_delay", "10.0", "If greater than 0, the delay in seconds between sm_recall usage and receiving the teleport to spawn.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hRecallDelay, OnSettingsChange);
	
	g_hRecallCancel = CreateConVar("sm_surfing_teleport_cancel", "150.0", "If greater than 0, the maximum distance a player can travel before sm_recall cancels, should sm_surfing_teleport_delay be greater than 0.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hRecallCancel, OnSettingsChange);
	
	g_hEnableBoost = CreateConVar("sm_surfing_boost", "-1", "Determines boost command functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Check Map)", FCVAR_NONE, true, -1.0, true, 1.0);
	HookConVarChange(g_hEnableBoost, OnSettingsChange);
	
	g_hBoostRecovery = CreateConVar("sm_surfing_boost_recovery", "30.0", "The number of seconds a player must wait before being able to use sm_boost again.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hBoostRecovery, OnSettingsChange);
	
	g_hBoostPower = CreateConVar("sm_surfing_boost_power", "1250.0", "The overall strength behind the sm_boost command. The larger the #, the stronger the effect.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hBoostPower, OnSettingsChange);
	
	g_hBoostCount = CreateConVar("sm_surfing_boost_count", "5", "The number of boost usages players will receive upon spawn. (0 = Unlimited)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hBoostCount, OnSettingsChange);
	
	g_hBoostDelay = CreateConVar("sm_surfing_boost_delay", "0.0", "If greater than 0, the delay in seconds between sm_boost usage and receiving the boost effect.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hBoostDelay, OnSettingsChange);
	
	g_hBoostCancel = CreateConVar("sm_surfing_boost_cancel", "0.0", "If greater than 0, the maximum distance a player can travel before sm_boost cancels, should sm_surfing_boost_delay be greater than 0.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hBoostCancel, OnSettingsChange);
	
	g_hSpawnCash = CreateConVar("sm_surfing_spawn_cash", "-1", "The amount of cash players will receive every time they spawn. (-1 = Disabled)", FCVAR_NONE, true, -1.0, true, 16000.0);
	HookConVarChange(g_hSpawnCash, OnSettingsChange);
	
	g_hEnableSlow = CreateConVar("sm_surfing_slow", "-1", "Determines slow command functionality. (-1 = Enabled on All, 0 = Disabled, 1 = Check Map)", FCVAR_NONE, true, -1.0, true, 1.0);
	HookConVarChange(g_hEnableSlow, OnSettingsChange);
	
	g_hSlowRecovery = CreateConVar("sm_surfing_slow_recovery", "30.0", "The number of seconds a player must wait before being able to use sm_slow again.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSlowRecovery, OnSettingsChange);
	
	g_hSlowPercent = CreateConVar("sm_surfing_slow_percent", "50", "The percent value to decrease a player's speed by. A percent of 33 will result in players going 66% of their normal speed while slowed.", FCVAR_NONE, true, 0.0, true, 100.0);
	HookConVarChange(g_hSlowPercent, OnSettingsChange);
	
	g_hSlowDuration = CreateConVar("sm_surfing_slow_duration", "7.0", "The number of seconds a player will be slowed for before returning to normal speed.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSlowDuration, OnSettingsChange);
	
	g_hSlowCount = CreateConVar("sm_surfing_slow_count", "3", "The number of slow usages players will receive upon spawn. (0 = Unlimited)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSlowCount, OnSettingsChange);
	
	g_hTeleCmds = CreateConVar("sm_surfing_commands_tele", "!recall, /recall, !tele, /tele", "The commands that can be used to access the Teleport feature, if enabled, separated by \", \", up to 8 commands allowed.", FCVAR_NONE);
	HookConVarChange(g_hTeleCmds, OnSettingsChange);
	
	g_hBoostCmds = CreateConVar("sm_surfing_commands_boost", "!boost, /boost", "The commands that can be used to access the Boost feature, if enabled, separated by \", \", up to 8 commands allowed.", FCVAR_NONE);
	HookConVarChange(g_hBoostCmds, OnSettingsChange);
	
	g_hSlowCmds = CreateConVar("sm_surfing_commands_slow", "!slow, /slow", "The commands that can be used to access Slow feature, if enabled, separated by \", \", up to 8 commands allowed.", FCVAR_NONE);
	HookConVarChange(g_hSlowCmds, OnSettingsChange);
	
	g_hFallDamage = CreateConVar("sm_surfing_fall_damage", "0", "Determines how the plugin will handle players' falling damage. (0 = No Change, 1 = Protect From Non-Fatal Only, 2 = Protect From All)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hFallDamage, OnSettingsChange);	
	AutoExecConfig(true, "sm_surfing_config");

	g_hAirAccelerate = FindConVar("sv_airaccelerate");
	HookConVarChange(g_hAirAccelerate, OnSettingsChange);
	
	g_hEnableBunnyHopping = FindConVar("sv_enablebunnyhopping");
	HookConVarChange(g_hEnableBunnyHopping, OnSettingsChange);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
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

	g_hTeleTrie = CreateTrie();
	g_hBoostTrie = CreateTrie();
	g_hSlowTrie = CreateTrie();

	Define_Defaults();
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i);
					SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
					
					if(g_bRecall)
					{
						g_iPlayerData[i][PLAYER_RECALL_TIME] = -1;
						if(g_iRecallCount)
							g_iPlayerData[i][PLAYER_RECALL_COUNT] = g_iRecallCount;

						g_bPlayerActions[i][ACTION_RECALL] = false;
						GetClientAbsOrigin(i, g_fPlayerPositions[i][POSITION_SPAWN]);
					}

					if(g_bBoost)
					{
						g_iPlayerData[i][PLAYER_BOOST_TIME] = -1;
						if(g_iBoostCount)
							g_iPlayerData[i][PLAYER_BOOST_COUNT] = g_iBoostCount;
							
						g_bPlayerActions[i][ACTION_BOOST] = false;
					}

					if(g_bSlow)
					{
						g_iPlayerData[i][PLAYER_SLOW_TIME] = -1;
						if(g_iSlowCount)
							g_iPlayerData[i][PLAYER_SLOW_COUNT] = g_iSlowCount;
							
						g_iPlayerData[i][PLAYER_SLOW_LEFT] = 0;
					}
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		for(new j = 0; j < HANDLE_DATA; j++)
			Void_ClearHandle(i, j);
}

public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		if(g_bRecall)
			g_iPlayerData[client][PLAYER_RECALL_TIME] = -1;
		
		if(g_bBoost)
			g_iPlayerData[client][PLAYER_BOOST_TIME] = -1;
		
		if(g_bSlow)
			g_iPlayerData[client][PLAYER_SLOW_TIME] = -1;
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
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
		if(g_iMapStrip)
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
					g_bPlayerActions[i][ACTION_RECALL] = false;
					g_iPlayerData[i][PLAYER_RECALL_TIME] = -1;
				}

				if(g_bBoost)
				{
					g_bPlayerActions[i][ACTION_BOOST] = false;
					g_iPlayerData[i][PLAYER_BOOST_TIME] = -1;
				}

				if(g_bSlow)
				{
					g_iPlayerData[i][PLAYER_SLOW_LEFT] = 0;
					g_iPlayerData[i][PLAYER_SLOW_TIME] = -1;
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
		if(g_iTeam[client] <= 1)
		{
			g_bAlive[client] = false;
			for(new j = 0; j < HANDLE_DATA; j++)
				Void_ClearHandle(client, j);
		}
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
				g_iPlayerData[client][PLAYER_RECALL_COUNT] = g_iRecallCount;

			g_bPlayerActions[client][ACTION_RECALL] = false;
			GetClientAbsOrigin(client, g_fPlayerPositions[client][POSITION_SPAWN]);
		}

		if(g_bBoost)
		{
			if(g_iBoostCount)
				g_iPlayerData[client][PLAYER_BOOST_COUNT] = g_iBoostCount;
				
			g_bPlayerActions[client][ACTION_BOOST] = false;
		}

		if(g_bSlow)
		{
			if(g_iSlowCount)
				g_iPlayerData[client][PLAYER_SLOW_COUNT] = g_iSlowCount;
				
			g_iPlayerData[client][PLAYER_SLOW_LEFT] = 0;
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

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled && client)
	{
		decl iIndex, String:sText[192];
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);

		if(GetTrieValue(g_hTeleTrie, sText, iIndex))
		{
			if(!g_bRecall)
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Disabled");
			else if(!g_bAlive[client])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Dead");
			else if(g_bPlayerActions[client][ACTION_RECALL])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Waiting");
			else if(g_iRecallCount && g_iPlayerData[client][PLAYER_RECALL_COUNT] <= 0)
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Used");
			else if(g_iRecallRecovery && g_iPlayerData[client][PLAYER_RECALL_TIME] > GetTime())
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Remaining", (g_iPlayerData[client][PLAYER_RECALL_TIME] - GetTime()));
			else
			{
				g_bPlayerActions[client][ACTION_RECALL] = true;
				if(g_fRecallDelay)
				{
					g_hTimer_Players[client][HANDLE_RECALL] = CreateTimer(g_fRecallDelay, Timer_Recall, client, TIMER_FLAG_NO_MAPCHANGE);
					if(g_fRecallCancel)
					{
						PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Notice_Moving", g_fRecallDelay);
						GetClientAbsOrigin(client, g_fPlayerPositions[client][POSITION_RECALL]);
					}
					else
						PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Notice", g_fRecallDelay);
				}
				else
					g_hTimer_Players[client][HANDLE_RECALL] = CreateTimer(0.1, Timer_Recall, client, TIMER_FLAG_NO_MAPCHANGE);
			}

			return Plugin_Stop;
		}
		else if(GetTrieValue(g_hBoostTrie, sText, iIndex))
		{
			if(!g_bBoost)
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Disabled");
			else if(!g_bAlive[client])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Dead");
			else if(g_bPlayerActions[client][ACTION_BOOST])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Waiting");
			else if(g_iBoostCount && g_iPlayerData[client][PLAYER_BOOST_COUNT] <= 0)
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Used");
			else if(g_iBoostRecovery && g_iPlayerData[client][PLAYER_BOOST_TIME] > GetTime())
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Remaining", (g_iPlayerData[client][PLAYER_BOOST_TIME] - GetTime()));
			else
			{
				g_bPlayerActions[client][ACTION_BOOST] = true;
				if(g_fBoostDelay)
				{
					g_hTimer_Players[client][HANDLE_BOOST] = CreateTimer(g_fBoostDelay, Timer_Boost, client, TIMER_FLAG_NO_MAPCHANGE);
					if(g_fBoostCancel)
					{
						PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Notice_Moving", g_fBoostDelay);
						GetClientAbsOrigin(client, g_fPlayerPositions[client][POSITION_BOOST]);
					}
					else
						PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Notice", g_fBoostDelay);
				}
				else
					g_hTimer_Players[client][HANDLE_BOOST] = CreateTimer(0.1, Timer_Boost, client, TIMER_FLAG_NO_MAPCHANGE);
			}

			return Plugin_Stop;
		}
		else if(GetTrieValue(g_hSlowTrie, sText, iIndex))
		{
			if(!g_bSlow)
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_Disabled");
			if(!g_bAlive[client])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_Dead");
			else if(g_iPlayerData[client][PLAYER_SLOW_LEFT])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_Waiting");
			else if(g_iSlowCount && g_iPlayerData[client][PLAYER_SLOW_COUNT] <= 0)
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_Used");
			else if(g_iSlowRecovery && g_iPlayerData[client][PLAYER_SLOW_TIME] > GetTime())
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_Remaining", (g_iPlayerData[client][PLAYER_SLOW_TIME] - GetTime()));
			else
			{
				g_iPlayerData[client][PLAYER_SLOW_LEFT] = g_iSlowDuration;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fSlowPercent);
				g_hTimer_Players[client][HANDLE_SLOW] = CreateTimer(1.0, Timer_Slow, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				
				PrintHintText(client, "%t", "Phrase_Panel_Duration", g_iSlowDuration);
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_Notice", (100 - g_iSlowPercent));
			}

			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_Recall(Handle:timer, any:client)
{
	if(g_bAlive[client] && IsClientInGame(client))
	{
		if(g_fRecallCancel)
		{
			decl Float:_fLocation[3], Float:_fDistance;
			GetClientAbsOrigin(client, _fLocation);
			_fDistance = GetVectorDistance(_fLocation, g_fPlayerPositions[client][POSITION_RECALL]);
			if(_fDistance >= g_fRecallCancel)
			{
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Terminated");
				
				g_hTimer_Players[client][HANDLE_RECALL] = INVALID_HANDLE;
				g_bPlayerActions[client][ACTION_RECALL] = false;
				return Plugin_Stop;
			}
		}

		TeleportEntity(client, g_fPlayerPositions[client][POSITION_SPAWN], NULL_VECTOR, NULL_VECTOR);
		if(g_iRecallCount)
		{
			g_iPlayerData[client][PLAYER_RECALL_COUNT]--;
			if(!g_iPlayerData[client][PLAYER_RECALL_COUNT])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Return_Empty");
			else
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Return_Remaining", g_iPlayerData[client][PLAYER_RECALL_COUNT], g_iRecallCount);
		}
		else
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Recall_Return");

		if(g_iRecallRecovery)
			g_iPlayerData[client][PLAYER_RECALL_TIME] = GetTime() + g_iRecallRecovery;
	}

	g_hTimer_Players[client][HANDLE_RECALL] = INVALID_HANDLE;
	g_bPlayerActions[client][ACTION_RECALL] = false;
	return Plugin_Stop;
}

public Action:Timer_Boost(Handle:timer, any:client)
{
	if(g_bAlive[client] && IsClientInGame(client))
	{
		if(g_fBoostCancel)
		{
			decl Float:_fLocation[3], Float:_fDistance;
			GetClientAbsOrigin(client, _fLocation);
			_fDistance = GetVectorDistance(_fLocation, g_fPlayerPositions[client][POSITION_BOOST]);
			if(_fDistance >= g_fBoostCancel)
			{
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Terminated");
				
				g_hTimer_Players[client][HANDLE_BOOST] = INVALID_HANDLE;
				g_bPlayerActions[client][ACTION_BOOST] = false;
				return Plugin_Stop;
			}
		}

		decl Float:_fAngles[3], Float:_fVectors[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", _fVectors);
		GetClientEyeAngles(client, _fAngles);

		for(new i = 0; i <= 1; i++)
			_fAngles[i] = DegToRad(_fAngles[i]);

		_fVectors[0] = (Cosine(_fAngles[1]) * g_fBoostPower) + _fVectors[0];
		_fVectors[1] = (Sine(_fAngles[1]) * g_fBoostPower) + _fVectors[1];
		_fVectors[2] = (Cosine(_fAngles[0]) * g_fBoostPower) + _fVectors[2];

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, _fVectors);

		if(g_iBoostCount)
		{
			g_iPlayerData[client][PLAYER_BOOST_COUNT]--;
			if(!g_iPlayerData[client][PLAYER_BOOST_COUNT])
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Activate_Empty");
			else
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Boost_Activate_Remaining", g_iPlayerData[client][PLAYER_BOOST_COUNT], g_iBoostCount);
		}

		if(g_iBoostRecovery)
			g_iPlayerData[client][PLAYER_BOOST_TIME] = GetTime() + g_iBoostRecovery;
	}

	g_hTimer_Players[client][HANDLE_BOOST] = INVALID_HANDLE;
	g_bPlayerActions[client][ACTION_BOOST] = false;
	return Plugin_Stop;
}

public Action:Timer_Slow(Handle:timer, any:client)
{
	if(g_bAlive[client] && IsClientInGame(client))
	{
		if(g_iPlayerData[client][PLAYER_SLOW_LEFT] > 1)
		{
			g_iPlayerData[client][PLAYER_SLOW_LEFT]--;
			PrintHintText(client, "%t", "Phrase_Panel_Duration", g_iPlayerData[client][PLAYER_SLOW_LEFT]);

			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fSlowPercent);
			return Plugin_Continue;
		}
		else
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			PrintHintText(client, "%t", "Phrase_Panel_Expire");

			if(g_iSlowRecovery)
				g_iPlayerData[client][PLAYER_SLOW_TIME] = GetTime() + g_iSlowRecovery;

			if(g_iSlowCount)
			{
				g_iPlayerData[client][PLAYER_SLOW_COUNT]--;
				if(!g_iPlayerData[client][PLAYER_SLOW_COUNT])
					PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_End_Empty");
				else
					PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Slow_End_Remaining", g_iPlayerData[client][PLAYER_SLOW_COUNT], g_iSlowCount);
			}
		}
	}

	g_hTimer_Players[client][HANDLE_SLOW] = INVALID_HANDLE;
	g_iPlayerData[client][PLAYER_SLOW_LEFT] = 0;
	return Plugin_Stop;
}

public Action:Command_Kill(client, const String:command[], argc)
{
	if(g_bEnabled && g_bBlockSuicide)
	{
		if(client && IsClientInGame(client))
		{
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Suicide_Disabled");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Radio(client, const String:command[], argc)
{
	if(g_bEnabled && g_bBlockRadio)
	{
		if(client && IsClientInGame(client))
		{
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Radio_Disabled");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_Strip(Handle:timer)
{
	decl String:_sTemp[64];
	new _iTemp = GetMaxEntities();
	for(new i = MaxClients + 1; i <= _iTemp; i++)
	{
		if(!IsValidEdict(i) || !IsValidEntity(i))
			continue;
		
		new _iContains = -1;
		GetEdictClassname(i, _sTemp, sizeof(_sTemp));
		switch(g_iMapStrip)
		{
			case -1:
				_iContains = StrContains("func_bomb_target|func_hostage_rescue|c4|hostage_entity|func_buyzone", _sTemp);
			case 1:
				_iContains = StrContains("func_buyzone", _sTemp);
			case 2:
				_iContains = StrContains("func_bomb_target|func_hostage_rescue|c4|hostage_entity", _sTemp);
		}

		if(_iContains >= 0)
			AcceptEntityInput(i, "Kill");
	}
}

Void_ClearHandle(client, index)
{
	if(g_hTimer_Players[client][index] != INVALID_HANDLE && CloseHandle(g_hTimer_Players[client][index]))
		g_hTimer_Players[client][index] = INVALID_HANDLE;
}

public Action:Hook_OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!g_bEnabled || !g_iFalling)
		return Plugin_Continue;

	if(0 < client <= MaxClients)
	{
		if(g_iFalling == 1)
		{
			if(!attacker && damagetype & DMG_FALL && damage <= GetEntProp(client, Prop_Data, "m_iHealth"))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		else
		{
			if(!attacker && damagetype & DMG_FALL)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

Define_Defaults()
{
	decl String:sBuffer[1024];	
	GetConVarString(g_hCheck, sBuffer, sizeof(sBuffer));
	g_iTotalMapChecks = ExplodeString(sBuffer, ", ", g_sMapChecks, 32, 32);

	switch(GetConVarInt(g_hEnabled))
	{
		case -1:
			g_bEnabled = true;
		case 0:
			g_bEnabled = false;
		case 1:
		{
			decl String:sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));
			
			g_bEnabled = false;
			for(new i = 0; i < g_iTotalMapChecks; i++)
			{
				if(StrContains(sTemp, g_sMapChecks[i], false) > 0)
				{
					g_bEnabled = true;
					break;
				}
			}
		}
	}

	g_iMapStrip = GetConVarInt(g_hMapStrip);
	g_bBlockSuicide = GetConVarBool(g_hBlockSuicide);
	g_bBlockRadio = GetConVarBool(g_hBlockRadio);
	g_iForceAccelerate = GetConVarInt(g_hForceAccelerate);
	g_bForceBunny = GetConVarBool(g_hForceBunny);
	g_iCash = GetConVarInt(g_hSpawnCash);
	g_iFalling = GetConVarInt(g_hFallDamage);
	
	g_iRecall = GetConVarInt(g_hEnableRecall);
	g_iRecallRecovery = GetConVarInt(g_hRecallRecovery);
	g_iRecallCount = GetConVarInt(g_hRecallCount);
	g_fRecallDelay = GetConVarFloat(g_hRecallDelay);
	g_fRecallCancel = GetConVarFloat(g_hRecallCancel);
	switch(g_iRecall)
	{
		case -1:
			g_bRecall = true;
		case 0:
			g_bRecall = false;
		case 1:
			g_bRecall = g_bEnabled;
	}

	g_iBoost = GetConVarInt(g_hEnableBoost);
	g_iBoostRecovery = GetConVarInt(g_hBoostRecovery);
	g_fBoostPower = GetConVarFloat(g_hBoostPower);
	g_iBoostCount = GetConVarInt(g_hBoostCount);
	g_fBoostDelay = GetConVarFloat(g_hBoostDelay);
	g_fBoostCancel = GetConVarFloat(g_hBoostCancel);
	switch(g_iBoost)
	{
		case -1:
			g_bBoost = true;
		case 0:
			g_bBoost = false;
		case 1:
			g_bBoost = g_bEnabled;
	}
	
	g_iSlow = GetConVarInt(g_hEnableSlow);
	g_iSlowRecovery = GetConVarInt(g_hSlowRecovery);
	g_iSlowPercent = GetConVarInt(g_hSlowPercent);
	g_fSlowPercent = float(100 - g_iSlowPercent) / 100.0;
	g_iSlowDuration = GetConVarInt(g_hSlowDuration);
	g_iSlowCount = GetConVarInt(g_hSlowCount);
	switch(g_iSlow)
	{
		case -1:
			g_bSlow = true;
		case 0:
			g_bSlow = false;
		case 1:
			g_bSlow = g_bEnabled;
	}

	if(g_iForceAccelerate && GetConVarInt(g_hAirAccelerate) != g_iForceAccelerate)
		SetConVarInt(g_hAirAccelerate, g_iForceAccelerate, true);
		
	if(g_bForceBunny && !GetConVarInt(g_hEnableBunnyHopping))
		SetConVarInt(g_hEnableBunnyHopping, g_bForceBunny, true);
	
	new iCount;
	GetConVarString(g_hTeleCmds, sBuffer, sizeof(sBuffer));
	ClearTrie(g_hTeleTrie);
	iCount = ExplodeString(sBuffer, ", ", g_sTeleCmds, MAX_CHAT_CMDS, MAX_CHAT_CMDS_LENGTH);
	for(new i = 0; i < iCount; i++)
		SetTrieValue(g_hTeleTrie, g_sTeleCmds[i], iCount);
		
	GetConVarString(g_hBoostCmds, sBuffer, sizeof(sBuffer));
	ClearTrie(g_hBoostTrie);
	iCount = ExplodeString(sBuffer, ", ", g_sBoostCmds, MAX_CHAT_CMDS, MAX_CHAT_CMDS_LENGTH);
	for(new i = 0; i < iCount; i++)
		SetTrieValue(g_hBoostTrie, g_sBoostCmds[i], iCount);
		
	GetConVarString(g_hSlowCmds, sBuffer, sizeof(sBuffer));
	ClearTrie(g_hSlowTrie);
	iCount = ExplodeString(sBuffer, ", ", g_sSlowCmds, MAX_CHAT_CMDS, MAX_CHAT_CMDS_LENGTH);
	for(new i = 0; i < iCount; i++)
		SetTrieValue(g_hSlowTrie, g_sSlowCmds[i], iCount);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
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
				for(new i = 0; i < g_iTotalMapChecks; i++)
				{
					if(StrContains(_sTemp, g_sMapChecks[i], false))
					{
						g_bEnabled = true;
						break;
					}
				}
			}
		}
	}
	else if(cvar == g_hMapStrip)
	{
		g_iMapStrip = StringToInt(newvalue);
		if(g_iMapStrip)
			CreateTimer(0.1, Timer_Strip, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(cvar == g_hBlockSuicide)
		g_bBlockSuicide = StringToInt(newvalue) ? false : false;
	else if(cvar == g_hBlockRadio)
		g_bBlockRadio = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hForceAccelerate)
	{
		g_iForceAccelerate = StringToInt(newvalue);
		if(GetConVarInt(g_hAirAccelerate) != g_iForceAccelerate)
			SetConVarInt(g_hAirAccelerate, g_iForceAccelerate, true);
	}
	else if(cvar == g_hForceBunny)
	{
		g_bForceBunny = StringToInt(newvalue) ? true : false;
		if(g_bForceBunny && !GetConVarInt(g_hEnableBunnyHopping))
			SetConVarInt(g_hEnableBunnyHopping, g_iForceAccelerate, true);
	}
	else if(cvar == g_hEnableRecall)
	{
		g_iRecall = StringToInt(newvalue);
		switch(g_iRecall)
		{
			case -1:
				g_bRecall = true;
			case 0:
				g_bRecall = false;
			case 1:
				g_bRecall = g_bEnabled;
		}

		if(g_bRecall)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bPlayerActions[i][ACTION_RECALL] = false;
					g_iPlayerData[i][PLAYER_RECALL_TIME] = -1;
				}
			}
		}
	}
	else if(cvar == g_hRecallRecovery)
		g_iRecallRecovery = StringToInt(newvalue);
	else if(cvar == g_hRecallCount)
		g_iRecallCount = StringToInt(newvalue);
	else if(cvar == g_hRecallDelay)
		g_fRecallDelay = StringToFloat(newvalue);
	else if(cvar == g_hRecallCancel)
		g_fRecallCancel = StringToFloat(newvalue);
	else if(cvar == g_hEnableBoost)
	{
		g_iBoost = StringToInt(newvalue);
		switch(g_iBoost)
		{
			case -1:
				g_bBoost = true;
			case 0:
				g_bBoost = false;
			case 1:
				g_bBoost = g_bEnabled;
		}

		if(g_bBoost)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bPlayerActions[i][ACTION_BOOST] = false;
					g_iPlayerData[i][PLAYER_BOOST_TIME] = -1;
				}
			}
		}
	}
	else if(cvar == g_hBoostRecovery)
		g_iBoostRecovery = StringToInt(newvalue);
	else if(cvar == g_hBoostPower)
		g_fBoostPower = StringToFloat(newvalue);
	else if(cvar == g_hBoostCount)
		g_iBoostCount = StringToInt(newvalue);
	else if(cvar == g_hBoostDelay)
		g_fBoostDelay = StringToFloat(newvalue);
	else if(cvar == g_hBoostCancel)
		g_fBoostCancel = StringToFloat(newvalue);
	else if(cvar == g_hSpawnCash)
		g_iCash = StringToInt(newvalue);
	else if(cvar == g_hEnableSlow)
	{
		g_iSlow = StringToInt(newvalue);
		switch(g_iSlow)
		{
			case -1:
				g_bSlow = true;
			case 0:
				g_bSlow = false;
			case 1:
				g_bSlow = g_bEnabled;
		}

		if(g_bSlow)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iPlayerData[i][PLAYER_SLOW_LEFT] = 0;
					g_iPlayerData[i][PLAYER_SLOW_TIME] = -1;
				}
			}
		}
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
	else if(cvar == g_hFallDamage)
		g_iFalling = StringToInt(newvalue);
	else if(cvar == g_hAirAccelerate)
	{
		if(GetConVarInt(g_hAirAccelerate) != g_iForceAccelerate)
			SetConVarInt(g_hAirAccelerate, g_iForceAccelerate, true);
	}
	else if(cvar == g_hEnableBunnyHopping)
	{
		if(g_bForceBunny && !GetConVarInt(g_hEnableBunnyHopping))
			SetConVarInt(g_hEnableBunnyHopping, g_bForceBunny, true);
	}
	else if(cvar == g_hTeleCmds)
	{
		ClearTrie(g_hTeleTrie);

		new iCount = ExplodeString(newvalue, ", ", g_sTeleCmds, MAX_CHAT_CMDS, MAX_CHAT_CMDS_LENGTH);
		for(new i = 0; i < iCount; i++)
			SetTrieValue(g_hTeleTrie, g_sTeleCmds[i], iCount);
	}
	else if(cvar == g_hBoostCmds)
	{
		ClearTrie(g_hBoostTrie);

		new iCount = ExplodeString(newvalue, ", ", g_sBoostCmds, MAX_CHAT_CMDS, MAX_CHAT_CMDS_LENGTH);
		for(new i = 0; i < iCount; i++)
			SetTrieValue(g_hBoostTrie, g_sBoostCmds[i], iCount);
	}
	else if(cvar == g_hSlowCmds)
	{
		ClearTrie(g_hSlowTrie);

		new iCount = ExplodeString(newvalue, ", ", g_sSlowCmds, MAX_CHAT_CMDS, MAX_CHAT_CMDS_LENGTH);
		for(new i = 0; i < iCount; i++)
			SetTrieValue(g_hSlowTrie, g_sSlowCmds[i], iCount);
	}
	else if(cvar == g_hCheck)
		g_iTotalMapChecks = ExplodeString(newvalue, ", ", g_sMapChecks, 32, 32);
}