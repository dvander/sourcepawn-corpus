#define PLUGIN_VERSION "1.2"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define DEBUG 0
#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] Health Preserve Fix & Give Start Health",
	author = "Alex Dragokas",
	description = "Correctly preserves the player's health on map transition & optionally give start health",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	ChangeLog:

	1.0 (14-Jan-2022)
	 - First commit.
	 
	1.1 (02-Jul-2022)
	 - Fixed lot of stupid mistakes.
	 - Added separate ConVars for bots.
	 - Added ConVar "l4d_health_preserve_start_force" - Set health from configs even if it is < (less) than preserved on the previous map? (1 - Yes, 0 - No)
	 - Compatibility with SM 1.11.
	 
	1.2 (03-Jul-2022)
	 - Follow z_survivor_respawn_health ConVar when survivor dead on the round end (thanks Toranks for reporting).
	 - Code simplified.
*/

enum struct Player
{
	bool SpawnedBefore;
	int Health;
	float TempHealth;
	int ReviveCount;
	int GoingToDie;
}

ConVar g_hCvarDecayRate, g_hCvarMaxIncapCount, g_hCvarDeadRespawnHealth;
ConVar g_hCvarEnable, g_hCvarStartHealth, g_hCvarStartTempHealth, g_hCvarStartRevives, g_hCvarStartForce;
ConVar g_hCvarStartHealthBot, g_hCvarStartTempHealthBot, g_hCvarStartRevivesBot;
bool g_bEnabled, g_bCvarStartForce;
int g_iCvarAllHealth, g_iCvarAllRevives, g_iCvarAllHealthBot, g_iCvarAllRevivesBot;
float g_fCvarAllTempHealth, g_fCvarAllTempHealthBot;
Player g_player[MAXPLAYERS+1];

public void OnPluginStart()
{
	CreateConVar("l4d_health_preserve_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hCvarEnable				= CreateConVar("l4d_health_preserve_enable", 					"1", 		"Enable this plugin? (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_hCvarStartHealth			= CreateConVar("l4d_health_preserve_start_health", 				"-1", 		"Health of all human survivors on round start (-1 - to preserve, > 0 - to set concrete health)", CVAR_FLAGS);
	g_hCvarStartTempHealth		= CreateConVar("l4d_health_preserve_start_temphealth", 			"-1.0", 	"Temp Health of all human survivors on round start (-1.0 - to preserve, >= 0.0 - to set concrete temp health)", CVAR_FLAGS);
	g_hCvarStartRevives			= CreateConVar("l4d_health_preserve_start_revive_count", 		"-1", 		"Revive count of all human survivors on round start (-1 - to preserve, 0 - to erase, > 0 is also allowed)", CVAR_FLAGS);
	g_hCvarStartHealthBot		= CreateConVar("l4d_health_preserve_start_health_bot",			"-1", 		"Health of all bot survivors on round start (-1 - to preserve, > 0 - to set concrete health)", CVAR_FLAGS);
	g_hCvarStartTempHealthBot	= CreateConVar("l4d_health_preserve_start_temphealth_bot",		"-1.0", 	"Temp Health of all bot survivors on round start (-1.0 - to preserve, >= 0.0 - to set concrete temp health)", CVAR_FLAGS);
	g_hCvarStartRevivesBot		= CreateConVar("l4d_health_preserve_start_revive_count_bot",	"-1", 		"Revive count of all bot survivors on round start (-1 - to preserve, 0 - to erase, > 0 is also allowed)", CVAR_FLAGS);
	g_hCvarStartForce			= CreateConVar("l4d_health_preserve_start_force", 				"1", 		"Set health from configs even if it is < less than preserved on the previous map? (1 - Yes, 0 - No)", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_health_preserve");
	
	g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
	g_hCvarMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_hCvarDeadRespawnHealth = FindConVar("z_survivor_respawn_health");
	
	#if DEBUG
		RegAdminCmd("sm_health", 	CmdHEStatus, 	ADMFLAG_ROOT);
	#endif
	
	GetCvars();
	
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStartHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStartTempHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStartRevives.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStartHealthBot.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStartTempHealthBot.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStartRevivesBot.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStartForce.AddChangeHook(ConVarChanged_Cvars);
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_iCvarAllHealth = g_hCvarStartHealth.IntValue;
	g_fCvarAllTempHealth = g_hCvarStartTempHealth.FloatValue;
	g_iCvarAllRevives = g_hCvarStartRevives.IntValue;
	g_iCvarAllHealthBot = g_hCvarStartHealthBot.IntValue;
	g_fCvarAllTempHealthBot = g_hCvarStartTempHealthBot.FloatValue;
	g_iCvarAllRevivesBot = g_hCvarStartRevivesBot.IntValue;
	g_bCvarStartForce = g_hCvarStartForce.BoolValue;
	
	InitHook();
}

void InitHook()
{
	static bool bHooked, bSpawnHooked;

	if( g_bEnabled )
	{
		if( !bHooked )
		{
			HookEvent("player_transitioned", 		Event_PlayerTransitioned);
			HookEvent("round_start", 				Event_RoundStart);
			HookEvent("map_transition", 			Event_MapTransition,		EventHookMode_PostNoCopy);
			bHooked = true;
		}
		if( !bSpawnHooked )
		{
			if( g_iCvarAllHealth != -1 || g_fCvarAllTempHealth != -1.0 || g_iCvarAllRevives != -1 )
			{
				HookEvent("player_spawn", 				Event_PlayerSpawn);
				bSpawnHooked = true;
			}
		}
	} else {
		if( bHooked )
		{
			UnhookEvent("player_transitioned", 		Event_PlayerTransitioned);
			UnhookEvent("round_start", 				Event_RoundStart);
			UnhookEvent("map_transition", 			Event_MapTransition,		EventHookMode_PostNoCopy);
			bHooked = false;
		}
		if( bSpawnHooked )
		{
			UnhookEvent("player_spawn", 			Event_PlayerSpawn);
			bSpawnHooked = false;
		}
	}
}

#if DEBUG
public Action CmdHEStatus(int client, int args)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			PrintToChat(client, "Saved health of \x05%N \x01is: \x03%i", i, g_player[i].Health);
		}
	}
	return Plugin_Handled;
}
#endif

bool OverrideHealthInfoStruct(int client)
{
	bool bChanged;
	if( IsFakeClient(client) )
	{
		if( g_iCvarAllHealthBot != -1 && (g_bCvarStartForce || g_iCvarAllHealthBot > g_player[client].Health) )
		{
			g_player[client].Health = g_iCvarAllHealthBot;
			bChanged = true;
		}
		if( g_fCvarAllTempHealthBot != -1.0 && (g_bCvarStartForce || g_fCvarAllTempHealthBot > g_player[client].TempHealth) )
		{
			g_player[client].TempHealth = g_fCvarAllTempHealthBot;
			bChanged = true;
		}
		if( g_iCvarAllRevivesBot != -1 )
		{
			g_player[client].ReviveCount = g_iCvarAllRevivesBot;
		
			if( g_iCvarAllRevivesBot < g_hCvarMaxIncapCount.IntValue )
			{
				g_player[client].GoingToDie = 0;
			}
			bChanged = true;
		}
	}
	else {
		if( g_iCvarAllHealth != -1 && (g_bCvarStartForce || g_iCvarAllHealth > g_player[client].Health) )
		{
			g_player[client].Health = g_iCvarAllHealth;
			bChanged = true;
		}
		if( g_fCvarAllTempHealth != -1.0 && (g_bCvarStartForce || g_fCvarAllTempHealth > g_player[client].TempHealth) )
		{
			g_player[client].TempHealth = g_fCvarAllTempHealth;
			bChanged = true;
		}
		if( g_iCvarAllRevives != -1 )
		{
			g_player[client].ReviveCount = g_iCvarAllRevives;
		
			if( g_iCvarAllRevives < g_hCvarMaxIncapCount.IntValue )
			{
				g_player[client].GoingToDie = 0;
			}
			bChanged = true;
		}
	}
	return bChanged;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_player[i].SpawnedBefore = false;
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && !g_player[client].SpawnedBefore )
	{
		g_player[client].SpawnedBefore = true;
		
		// On Player First Spawn
		if( IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			// delay to write values after engine write its own initial values
			CreateTimer(0.1, Timer_GiveHealth, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_GiveHealth(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		GetHealthInfo(client, g_player[client].Health, g_player[client].TempHealth);
		
		bool bChanged = OverrideHealthInfoStruct(client);
		if( bChanged )
		{
			SetHealth(client, g_player[client].Health, g_player[client].TempHealth, g_player[client].ReviveCount, g_player[client].GoingToDie);
		}
		#if DEBUG
			PrintToChatAll("[Start] Health of \x03%N: \x05%i", client, g_player[client].Health);
		#endif
	}
	return Plugin_Continue;
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast) // Saving health state
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			if( IsPlayerAlive(i) )
			{
				GetHealthInfo(i, g_player[i].Health, g_player[i].TempHealth, g_player[i].ReviveCount, g_player[i].GoingToDie);
			}
			else {
				g_player[i].Health = g_hCvarDeadRespawnHealth.IntValue;
				g_player[i].TempHealth = 0.0;
				g_player[i].ReviveCount = 0;
				g_player[i].GoingToDie = 0;
			}
		}
	}
}

public void Event_PlayerTransitioned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		if( !g_player[client].SpawnedBefore && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			g_player[client].SpawnedBefore = true;

			OverrideHealthInfoStruct(client);
			
			SetHealth(client, g_player[client].Health, g_player[client].TempHealth, g_player[client].ReviveCount, g_player[client].GoingToDie);
			#if DEBUG
				PrintToChatAll("[Transi] Health of \x03%N: \x05%i", client, g_player[client].Health);
			#endif
		}
	}
}

stock void GetHealthInfo(int client, int &iHealth = 0, float &fTempHealth = 0.0, int &iReviveCount = 0, int &iGoingToDie = 0)
{
	iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	fTempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float delta = (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
	fTempHealth -= delta;
	if( fTempHealth < 0.0 )
	{
		fTempHealth = 0.0;
	}
	iReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	iGoingToDie = GetEntProp(client, Prop_Send, "m_isGoingToDie");
}

stock void SetHealth(int client, int iHealth, float fTempHealth = -1.0, int iReviveCount = -1, int iGoingToDie = -1, float fBufferTime = 0.0)
{
	SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
	if( fTempHealth >= 0.0 )
	{
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fBufferTime == 0.0 ? GetGameTime() : fBufferTime);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTempHealth);
	}
	if( iReviveCount != -1 )
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount);
	}
	if( iGoingToDie != -1 )
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", iGoingToDie);
	}
}
