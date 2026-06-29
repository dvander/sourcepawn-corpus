/*
*	HUD Stats
*	Copyright (C) 2025 JustMe
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#define PLUGIN_VERSION		"1.0.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] HUD Stats
*	Author	:	JustMe
*	Descrp	:	Display CI kills, SI kills, Tank damage and Time on Scripted HUD.
*	Link	:	
*	Plugins	:	

========================================================================================
	Change Log:

1.0.1 (01-May-2026)
	- Replaced crash-prone info_gamemode entity with L4D_GetGameModeType native.

1.0.0 (26-Feb-2026)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <clientprefs>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define HUD1				0
#define HUD2				1
#define HUD3				2
#define HUD4				3

#define HUD_FLAG_BLINK		8
#define HUD_FLAG_NOBG		64
#define HUD_FLAG_ALIGN_LEFT	256
#define HUD_FLAG_TEAM_SURV	1024
#define HUD_FLAG_TEXT		8192
#define HUD_FLAG_NOTVISIBLE	16384

#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define ZC_SMOKER			1
#define ZC_BOOMER			2
#define ZC_HUNTER			3
#define ZC_SPITTER			4
#define ZC_JOCKEY			5
#define ZC_CHARGER			6
#define ZC_TANK				8

#define MAX_DISPLAY			4
#define MAX_NAME_DISPLAY	10



// ====================================================================================================
//					STRUCTS
// ====================================================================================================
enum struct PlayerData
{
	int  client;
	int  value;
	char name[32];
}

enum struct TankData
{
	bool bAlive;
	int  iDmgTrack[MAXPLAYERS + 1];

	void Reset()
	{
		this.bAlive = false;
		for (int i = 0; i <= MAXPLAYERS; i++)
			this.iDmgTrack[i] = 0;
	}
}



// ====================================================================================================
//					GLOBALS
// ====================================================================================================
ConVar g_hCvarMPGameMode;

ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarInterval, g_hCvarBg, g_hCvarBlink;
ConVar g_hCvarHUD1_X, g_hCvarHUD1_Y, g_hCvarHUD1_W, g_hCvarHUD1_H;
ConVar g_hCvarHUD2_X, g_hCvarHUD2_Y, g_hCvarHUD2_W, g_hCvarHUD2_H;
ConVar g_hCvarHUD3_X, g_hCvarHUD3_Y, g_hCvarHUD3_W, g_hCvarHUD3_H;
ConVar g_hCvarHUD4_X, g_hCvarHUD4_Y, g_hCvarHUD4_W, g_hCvarHUD4_H;

bool  g_bCvarAllow, g_bMapStarted, g_bLateLoad;
bool  g_bCvarBg, g_bCvarBlink;
float g_fCvarInterval;
float g_fCvarHUD1_X, g_fCvarHUD1_Y, g_fCvarHUD1_W, g_fCvarHUD1_H;
float g_fCvarHUD2_X, g_fCvarHUD2_Y, g_fCvarHUD2_W, g_fCvarHUD2_H;
float g_fCvarHUD3_X, g_fCvarHUD3_Y, g_fCvarHUD3_W, g_fCvarHUD3_H;
float g_fCvarHUD4_X, g_fCvarHUD4_Y, g_fCvarHUD4_W, g_fCvarHUD4_H;

bool  g_bAliveTank;
int   g_iCIKills[MAXPLAYERS + 1];
int   g_iSIKills[MAXPLAYERS + 1];
int   g_iTankDamage[MAXPLAYERS + 1];
int   g_iMapNum, g_iTotalMaps;

TankData g_TankData[MAXPLAYERS + 1];

Handle g_tUpdateHUD;
Handle g_tTankCheck;
Handle g_hCookie_HUD;

bool  g_bHUDEnabled[MAXPLAYERS + 1] = { true, ... };

char  g_sHUD[4][128];
char  g_sHUDStr[512];
char  g_sSpaces[128] = "                                                                                                                               ";



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name        = "[L4D2] HUD Stats",
	author      = "JustMe",
	description = "Display CI kills, SI kills, Tank damage and Time on Scripted HUD.",
	version     = PLUGIN_VERSION,
	url         = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	CreateConVar(				"l4d2_hud_stats_version",			PLUGIN_VERSION,		"HUD Stats plugin version.",								FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarAllow =		CreateConVar("l4d2_hud_stats_allow",		"1",				"0=Plugin off, 1=Plugin on.",								CVAR_FLAGS);
	g_hCvarModes =		CreateConVar("l4d2_hud_stats_modes",		"",					"Enable in these game modes (comma-separated, empty=all).",	CVAR_FLAGS);
	g_hCvarModesOff =	CreateConVar("l4d2_hud_stats_modes_off",	"",					"Disable in these game modes (comma-separated, empty=none).",CVAR_FLAGS);
	g_hCvarModesTog =	CreateConVar("l4d2_hud_stats_modes_tog",	"0",				"Enable in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
	g_hCvarInterval =	CreateConVar("l4d2_hud_stats_interval",		"0.5",				"Interval in seconds to update the HUD.",					CVAR_FLAGS, true, 0.1);
	g_hCvarBg =			CreateConVar("l4d2_hud_stats_background",	"0",				"0=No background box, 1=Show background box.",				CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarBlink =		CreateConVar("l4d2_hud_stats_blink_tank",	"1",				"0=Off, 1=Blink HUD when Tank is alive.",					CVAR_FLAGS, true, 0.0, true, 1.0);

	g_hCvarHUD1_X =		CreateConVar("l4d2_hud_stats_hud1_x",		"0.02",				"HUD1 (CI) X position.",									CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD1_Y =		CreateConVar("l4d2_hud_stats_hud1_y",		"0.015",			"HUD1 (CI) Y position.",									CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD1_W =		CreateConVar("l4d2_hud_stats_hud1_width",	"1.5",				"HUD1 (CI) Width.",											CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hCvarHUD1_H =		CreateConVar("l4d2_hud_stats_hud1_height",	"0.026",			"HUD1 (CI) Height per line.",								CVAR_FLAGS, true, 0.0, true, 2.0);

	g_hCvarHUD2_X =		CreateConVar("l4d2_hud_stats_hud2_x",		"0.22",				"HUD2 (SI) X position.",									CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD2_Y =		CreateConVar("l4d2_hud_stats_hud2_y",		"0.015",			"HUD2 (SI) Y position.",									CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD2_W =		CreateConVar("l4d2_hud_stats_hud2_width",	"1.5",				"HUD2 (SI) Width.",											CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hCvarHUD2_H =		CreateConVar("l4d2_hud_stats_hud2_height",	"0.026",			"HUD2 (SI) Height per line.",								CVAR_FLAGS, true, 0.0, true, 2.0);

	g_hCvarHUD3_X =		CreateConVar("l4d2_hud_stats_hud3_x",		"0.42",				"HUD3 (Tank DMG) X position.",								CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD3_Y =		CreateConVar("l4d2_hud_stats_hud3_y",		"0.015",			"HUD3 (Tank DMG) Y position.",								CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD3_W =		CreateConVar("l4d2_hud_stats_hud3_width",	"1.5",				"HUD3 (Tank DMG) Width.",									CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hCvarHUD3_H =		CreateConVar("l4d2_hud_stats_hud3_height",	"0.026",			"HUD3 (Tank DMG) Height per line.",							CVAR_FLAGS, true, 0.0, true, 2.0);

	g_hCvarHUD4_X =		CreateConVar("l4d2_hud_stats_hud4_x",		"0.62",				"HUD4 (Time) X position.",									CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD4_Y =		CreateConVar("l4d2_hud_stats_hud4_y",		"0.015",			"HUD4 (Time) Y position.",									CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarHUD4_W =		CreateConVar("l4d2_hud_stats_hud4_width",	"1.5",				"HUD4 (Time) Width.",										CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hCvarHUD4_H =		CreateConVar("l4d2_hud_stats_hud4_height",	"0.026",			"HUD4 (Time) Height per line.",								CVAR_FLAGS, true, 0.0, true, 2.0);

	//AutoExecConfig(true, "l4d2_hud_stats");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);

	GetCvars();
	g_hCvarInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarBg.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarBlink.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD1_X.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD1_Y.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD1_W.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD1_H.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD2_X.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD2_Y.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD2_W.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD2_H.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD3_X.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD3_Y.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD3_W.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD3_H.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD4_X.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD4_Y.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD4_W.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHUD4_H.AddChangeHook(ConVarChanged_Cvars);

	// Commands
	RegAdminCmd("sm_resethudstats", CmdResetStats, ADMFLAG_ROOT, "Reset all HUD stats.");
	RegConsoleCmd("sm_hudstats",    CmdToggleHUD,               "Toggle HUD Stats display on/off.");

	// Cookie
	g_hCookie_HUD = RegClientCookie("l4d2_hud_stats", "HUD Stats Visibility", CookieAccess_Protected);

	// Late loading
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
				OnClientCookiesCached(i);
		}
	}
}

public void OnPluginEnd()
{
	ResetPlugin();

	if (g_bCvarAllow)
		UnhookEvents();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
	GameRules_SetProp("m_bChallengeModeActive", true, _, _, true);
	RequestFrame(OnFrame_GetMapInfo);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCvarInterval = g_hCvarInterval.FloatValue;
	g_bCvarBg       = g_hCvarBg.BoolValue;
	g_bCvarBlink    = g_hCvarBlink.BoolValue;

	g_fCvarHUD1_X = g_hCvarHUD1_X.FloatValue;
	g_fCvarHUD1_Y = g_hCvarHUD1_Y.FloatValue;
	g_fCvarHUD1_W = g_hCvarHUD1_W.FloatValue;
	g_fCvarHUD1_H = g_hCvarHUD1_H.FloatValue;

	g_fCvarHUD2_X = g_hCvarHUD2_X.FloatValue;
	g_fCvarHUD2_Y = g_hCvarHUD2_Y.FloatValue;
	g_fCvarHUD2_W = g_hCvarHUD2_W.FloatValue;
	g_fCvarHUD2_H = g_hCvarHUD2_H.FloatValue;

	g_fCvarHUD3_X = g_hCvarHUD3_X.FloatValue;
	g_fCvarHUD3_Y = g_hCvarHUD3_Y.FloatValue;
	g_fCvarHUD3_W = g_hCvarHUD3_W.FloatValue;
	g_fCvarHUD3_H = g_hCvarHUD3_H.FloatValue;

	g_fCvarHUD4_X = g_hCvarHUD4_X.FloatValue;
	g_fCvarHUD4_Y = g_hCvarHUD4_Y.FloatValue;
	g_fCvarHUD4_W = g_hCvarHUD4_W.FloatValue;
	g_fCvarHUD4_H = g_hCvarHUD4_H.FloatValue;
}

void IsAllowed()
{
	GetCvars();
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if (g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true)
	{
		g_bCvarAllow = true;
		HookEvents();

		delete g_tUpdateHUD;
		g_tUpdateHUD = CreateTimer(g_fCvarInterval, TimerUpdateHUD, _, TIMER_REPEAT);

		delete g_tTankCheck;
		g_tTankCheck = CreateTimer(1.0, TimerTankCheck, _, TIMER_REPEAT);
	}

	else if (g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false))
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvents();
	}
}

int g_iCurrentMode;

public void L4D_OnGameModeChange(int gamemode)
{
	g_iCurrentMode = gamemode;
}

bool IsAllowedGameMode()
{
	if (g_hCvarMPGameMode == null)
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if (iCvarModesTog != 0)
	{
		if( !L4D_HasMapStarted() )
			return false;
		
		if (g_iCurrentMode == 0)
			g_iCurrentMode = L4D_GetGameModeType();

		if (g_iCurrentMode == 0)
			return false;

		if (!(iCvarModesTog & g_iCurrentMode))
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
			return false;
	}

	return true;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("player_death",        Event_PlayerDeath);
	HookEvent("player_spawn",        Event_PlayerSpawn);
	HookEvent("tank_spawn",          Event_TankSpawn);
	HookEvent("round_start",         Event_RoundStart,        EventHookMode_PostNoCopy);
	HookEvent("mission_lost",        Event_RoundStart,        EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace",  Event_BotReplacedPlayer);
	HookEvent("bot_player_replace",  Event_PlayerReplacedBot);
}

void UnhookEvents()
{
	UnhookEvent("player_death",       Event_PlayerDeath);
	UnhookEvent("player_spawn",       Event_PlayerSpawn);
	UnhookEvent("tank_spawn",         Event_TankSpawn);
	UnhookEvent("round_start",        Event_RoundStart,        EventHookMode_PostNoCopy);
	UnhookEvent("mission_lost",       Event_RoundStart,        EventHookMode_PostNoCopy);
	UnhookEvent("player_bot_replace", Event_BotReplacedPlayer);
	UnhookEvent("bot_player_replace", Event_PlayerReplacedBot);
}

void ResetPlugin()
{
	delete g_tUpdateHUD;
	delete g_tTankCheck;

	g_bAliveTank = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_TankData[i].bAlive && IsClientInGame(i))
			SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTankTakeDamage);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllStats();

	for (int i = 0; i <= MaxClients; i++)
		g_TankData[i].Reset();

	g_bAliveTank = false;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(tank))
		return;

	if (g_bCvarBlink)
		g_bAliveTank = true;

	g_TankData[tank].Reset();
	g_TankData[tank].bAlive = true;

	SDKUnhook(tank, SDKHook_OnTakeDamageAlive, OnTankTakeDamage);
	SDKHook(tank, SDKHook_OnTakeDamageAlive, OnTankTakeDamage);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return;

	if (GetClientTeam(client) != TEAM_INFECTED)
		return;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK)
		return;

	g_TankData[client].Reset();
	g_TankData[client].bAlive = true;

	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTankTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTankTakeDamage);
}

void Event_BotReplacedPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	int bot    = GetClientOfUserId(event.GetInt("bot"));

	if (!IsValidClient(bot) || GetClientTeam(bot) != TEAM_INFECTED)
		return;

	if (GetEntProp(bot, Prop_Send, "m_zombieClass") != ZC_TANK)
		return;

	for (int i = 1; i <= MaxClients; i++)
		g_TankData[bot].iDmgTrack[i] += g_TankData[player].iDmgTrack[i];

	g_TankData[player].Reset();
	g_TankData[bot].bAlive = true;
}

void Event_PlayerReplacedBot(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	int bot    = GetClientOfUserId(event.GetInt("bot"));

	if (!IsValidClient(player) || GetClientTeam(player) != TEAM_INFECTED)
		return;

	if (GetEntProp(player, Prop_Send, "m_zombieClass") != ZC_TANK)
		return;

	for (int i = 1; i <= MaxClients; i++)
		g_TankData[player].iDmgTrack[i] += g_TankData[bot].iDmgTrack[i];

	g_TankData[bot].Reset();
	g_TankData[player].bAlive = true;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim   = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidSurvivor(attacker))
	{
		// Check victim is valid client and Tank
		if (victim && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == TEAM_INFECTED)
		{
			if (GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_TANK && g_TankData[victim].bAlive)
				FinalizeTankDamage(victim);
		}
		return;
	}

	// Non-client entity died (CI or Witch)
	if (victim == 0)
	{
		int entityid = event.GetInt("entityid");
		if (entityid > 0 && IsValidEntity(entityid))
		{
			static char cls[32];
			GetEntityClassname(entityid, cls, sizeof(cls));

			if (strcmp(cls, "witch") == 0)
				g_iSIKills[attacker]++;
			else
				g_iCIKills[attacker]++;
		}
		return;
	}

	// SI player died
	if (victim && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == TEAM_INFECTED)
	{
		int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

		if (zClass >= ZC_SMOKER && zClass <= ZC_CHARGER)
		{
			g_iSIKills[attacker]++;
		}
		else if (zClass == ZC_TANK)
		{
			g_iSIKills[attacker]++;

			if (g_TankData[victim].bAlive)
				FinalizeTankDamage(victim);
		}
	}
}



// ====================================================================================================
//					DAMAGE HOOK
// ====================================================================================================
Action OnTankTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damage <= 0.0)                                           return Plugin_Continue;
	if (!g_TankData[victim].bAlive)                              return Plugin_Continue;
	if (!IsValidSurvivor(attacker))                              return Plugin_Continue;
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 1) return Plugin_Continue;

	int iDmg    = RoundToFloor(damage);
	int iHealth = GetEntProp(victim, Prop_Data, "m_iHealth");

	if (iDmg > iHealth)
		iDmg = iHealth;

	g_TankData[victim].iDmgTrack[attacker] += iDmg;

	return Plugin_Continue;
}



// ====================================================================================================
//					TIMERS
// ====================================================================================================
Action TimerTankCheck(Handle timer)
{
	if (!g_bCvarAllow)
	{
		g_tTankCheck = null;
		return Plugin_Stop;
	}

	if (g_bAliveTank)
		g_bAliveTank = HasAnyTankAlive();

	return Plugin_Continue;
}

Action TimerUpdateHUD(Handle timer)
{
	if (!g_bCvarAllow)
	{
		g_tUpdateHUD = null;
		return Plugin_Stop;
	}

	UpdateHUD();
	return Plugin_Continue;
}



// ====================================================================================================
//					HUD
// ====================================================================================================
void UpdateHUD()
{
	if (!g_bMapStarted) return;

	int iBaseFlags = HUD_FLAG_TEXT | HUD_FLAG_ALIGN_LEFT | HUD_FLAG_TEAM_SURV;
	if (!g_bCvarBg)
		iBaseFlags |= HUD_FLAG_NOBG;

	int iBlinkFlags = iBaseFlags;
	if (g_bCvarBlink && g_bAliveTank)
		iBlinkFlags |= HUD_FLAG_BLINK;

	BuildHUD1_CI();
	BuildHUD2_SI();
	BuildHUD3_TankDmg();
	BuildHUD4_Time();

	// HUD1 - CI Kills
	int f1 = HasAnyStat(0) ? iBlinkFlags : (iBlinkFlags | HUD_FLAG_NOTVISIBLE);
	GameRules_SetProp(		"m_iScriptedHUDFlags",      f1, _, HUD1);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosX",       g_fCvarHUD1_X, HUD1);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosY",       g_fCvarHUD1_Y, HUD1);
	GameRules_SetPropFloat(	"m_fScriptedHUDWidth",      g_fCvarHUD1_W, HUD1);
	GameRules_SetPropFloat(	"m_fScriptedHUDHeight",     g_fCvarHUD1_H * (CountNewlines(g_sHUD[HUD1]) + 1), HUD1);

	// HUD2 - SI Kills
	int f2 = HasAnyStat(1) ? iBlinkFlags : (iBlinkFlags | HUD_FLAG_NOTVISIBLE);
	GameRules_SetProp(		"m_iScriptedHUDFlags",      f2, _, HUD2);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosX",       g_fCvarHUD2_X, HUD2);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosY",       g_fCvarHUD2_Y, HUD2);
	GameRules_SetPropFloat(	"m_fScriptedHUDWidth",      g_fCvarHUD2_W, HUD2);
	GameRules_SetPropFloat(	"m_fScriptedHUDHeight",     g_fCvarHUD2_H * (CountNewlines(g_sHUD[HUD2]) + 1), HUD2);

	// HUD3 - Tank Damage
	int f3 = HasAnyStat(2) ? iBlinkFlags : (iBlinkFlags | HUD_FLAG_NOTVISIBLE);
	GameRules_SetProp(		"m_iScriptedHUDFlags",      f3, _, HUD3);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosX",       g_fCvarHUD3_X, HUD3);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosY",       g_fCvarHUD3_Y, HUD3);
	GameRules_SetPropFloat(	"m_fScriptedHUDWidth",      g_fCvarHUD3_W, HUD3);
	GameRules_SetPropFloat(	"m_fScriptedHUDHeight",     g_fCvarHUD3_H * (CountNewlines(g_sHUD[HUD3]) + 1), HUD3);

	// HUD4 - Time
	GameRules_SetProp(		"m_iScriptedHUDFlags",      iBaseFlags, _, HUD4);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosX",       g_fCvarHUD4_X, HUD4);
	GameRules_SetPropFloat(	"m_fScriptedHUDPosY",       g_fCvarHUD4_Y, HUD4);
	GameRules_SetPropFloat(	"m_fScriptedHUDWidth",      g_fCvarHUD4_W, HUD4);
	GameRules_SetPropFloat(	"m_fScriptedHUDHeight",     g_fCvarHUD4_H * (CountNewlines(g_sHUD[HUD4]) + 1), HUD4);

	ImplodeStrings(g_sHUD, sizeof(g_sHUD), " ", g_sHUDStr, sizeof(g_sHUDStr));
	GameRules_SetPropString("m_szScriptedHUDStringSet", g_sHUDStr);
}

void BuildHUD1_CI()
{
	static char out[256];
	FormatEx(out, sizeof(out), "★ CI KILLS ★");

	PlayerData players[MAXPLAYERS + 1];
	int cnt     = GetSortedPlayers(players, 0);
	int display = (cnt < MAX_DISPLAY) ? cnt : MAX_DISPLAY;

	for (int i = 0; i < display; i++)
		Format(out, sizeof(out), "%s\n✦ %d  %s", out, players[i].value, players[i].name);

	for (int i = display; i < MAX_DISPLAY; i++)
		Format(out, sizeof(out), "%s\n", out);

	FormatEx(g_sHUD[HUD1], sizeof(g_sHUD[]), "%s%s", out, g_sSpaces);
}

void BuildHUD2_SI()
{
	static char out[256];
	FormatEx(out, sizeof(out), "★ SI KILLS ★");

	PlayerData players[MAXPLAYERS + 1];
	int cnt     = GetSortedPlayers(players, 1);
	int display = (cnt < MAX_DISPLAY) ? cnt : MAX_DISPLAY;

	for (int i = 0; i < display; i++)
		Format(out, sizeof(out), "%s\n✦ %d  %s", out, players[i].value, players[i].name);

	for (int i = display; i < MAX_DISPLAY; i++)
		Format(out, sizeof(out), "%s\n", out);

	FormatEx(g_sHUD[HUD2], sizeof(g_sHUD[]), "%s%s", out, g_sSpaces);
}

void BuildHUD3_TankDmg()
{
	static char out[256];
	FormatEx(out, sizeof(out), "★ TANK DMG ★");

	PlayerData players[MAXPLAYERS + 1];
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		int total = g_iTankDamage[i];
		for (int tank = 1; tank <= MaxClients; tank++)
		{
			if (g_TankData[tank].bAlive)
				total += g_TankData[tank].iDmgTrack[i];
		}

		players[count].client = i;
		GetClientName(i, players[count].name, sizeof(players[].name));
		TruncateName(players[count].name, MAX_NAME_DISPLAY);
		players[count].value = total;
		count++;
	}

	SortPlayers(players, count);

	int display = (count < MAX_DISPLAY) ? count : MAX_DISPLAY;

	for (int i = 0; i < display; i++)
		Format(out, sizeof(out), "%s\n✦ %d  %s", out, players[i].value, players[i].name);

	for (int i = display; i < MAX_DISPLAY; i++)
		Format(out, sizeof(out), "%s\n", out);

	FormatEx(g_sHUD[HUD3], sizeof(g_sHUD[]), "%s%s", out, g_sSpaces);
}

void BuildHUD4_Time()
{
	static char sDate[32], sTime[32], out[256];

	int iTime = GetTime();
	FormatTime(sDate, sizeof(sDate), "%d / %m / %Y", iTime);
	FormatTime(sTime, sizeof(sTime), "%H : %M : %S", iTime);

	FormatEx(out, sizeof(out), "★ TIME ★\n✦ %s\n✦ %s\n✦ %d / %d",
		sDate, sTime, g_iMapNum, g_iTotalMaps);

	FormatEx(g_sHUD[HUD4], sizeof(g_sHUD[]), "%s%s", out, g_sSpaces);
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
Action CmdResetStats(int client, int args)
{
	ResetAllStats();

	if (client && IsClientInGame(client))
		PrintToChat(client, "\x04[HUD Stats] \x01All stats have been reset.");

	return Plugin_Handled;
}

Action CmdToggleHUD(int client, int args)
{
	if (client < 1 || !IsClientInGame(client))
		return Plugin_Handled;

	g_bHUDEnabled[client] = !g_bHUDEnabled[client];

	if (!IsFakeClient(client))
		SetClientCookie(client, g_hCookie_HUD, g_bHUDEnabled[client] ? "1" : "0");

	PrintToChat(client, "\x04[HUD Stats] \x01HUD display: %s",
		g_bHUDEnabled[client] ? "\x04ON" : "\x05OFF");

	return Plugin_Handled;
}



// ====================================================================================================
//					COOKIES
// ====================================================================================================
public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;

	char sCookie[4];
	GetClientCookie(client, g_hCookie_HUD, sCookie, sizeof(sCookie));

	g_bHUDEnabled[client] = (sCookie[0] == '\0') ? true : !!StringToInt(sCookie);
}

public void OnClientConnected(int client)
{
	g_bHUDEnabled[client] = true;
}

public void OnClientDisconnect(int client)
{
	g_iCIKills[client]    = 0;
	g_iSIKills[client]    = 0;
	g_iTankDamage[client] = 0;

	g_TankData[client].Reset();

	for (int tank = 1; tank <= MaxClients; tank++)
		g_TankData[tank].iDmgTrack[client] = 0;

	g_bHUDEnabled[client] = true;
}



// ====================================================================================================
//					HELPERS
// ====================================================================================================
void OnFrame_GetMapInfo()
{
	g_iMapNum    = L4D_GetCurrentChapter();
	g_iTotalMaps = L4D_GetMaxChapters();

	if (g_iMapNum    < 1) g_iMapNum    = 1;
	if (g_iTotalMaps < 1) g_iTotalMaps = 1;
}

void FinalizeTankDamage(int tank)
{
	for (int i = 1; i <= MaxClients; i++)
		g_iTankDamage[i] += g_TankData[tank].iDmgTrack[i];

	g_TankData[tank].Reset();
}

void ResetAllStats()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iCIKills[i]    = 0;
		g_iSIKills[i]    = 0;
		g_iTankDamage[i] = 0;
	}
}

int GetSortedPlayers(PlayerData[] players, int statType)
{
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		players[count].client = i;
		GetClientName(i, players[count].name, sizeof(players[].name));
		TruncateName(players[count].name, MAX_NAME_DISPLAY);

		switch (statType)
		{
			case 0: players[count].value = g_iCIKills[i];
			case 1: players[count].value = g_iSIKills[i];
			case 2: players[count].value = g_iTankDamage[i];
		}

		count++;
	}

	SortPlayers(players, count);
	return count;
}

void SortPlayers(PlayerData[] players, int count)
{
	int limit = (count < MAX_DISPLAY) ? count : MAX_DISPLAY;

	for (int i = 0; i < limit; i++)
	{
		int maxIdx = i;
		for (int j = i + 1; j < count; j++)
		{
			if (players[j].value > players[maxIdx].value)
				maxIdx = j;
		}

		if (maxIdx != i)
		{
			PlayerData tmp;
			tmp             = players[i];
			players[i]      = players[maxIdx];
			players[maxIdx] = tmp;
		}
	}
}

bool HasAnyStat(int statType)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		switch (statType)
		{
			case 0: { if (g_iCIKills[i]   > 0) return true; }
			case 1: { if (g_iSIKills[i]   > 0) return true; }
			case 2:
			{
				int total = g_iTankDamage[i];
				for (int tank = 1; tank <= MaxClients; tank++)
					if (g_TankData[tank].bAlive)
						total += g_TankData[tank].iDmgTrack[i];

				if (total > 0) return true;
			}
		}
	}
	return false;
}

bool HasAnyTankAlive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))                                       continue;
		if (GetClientTeam(i) != TEAM_INFECTED)                        continue;
		if (!IsPlayerAlive(i))                                        continue;
		if (GetEntProp(i, Prop_Send, "m_zombieClass") != ZC_TANK)     continue;
		if (GetEntProp(i, Prop_Send, "m_isGhost") == 1)               continue;
		if (GetEntProp(i, Prop_Send, "m_isIncapacitated") == 1)       continue;

		return true;
	}

	return false;
}

int CountNewlines(const char[] str)
{
	int count, i;
	while (str[i] != '\0')
		if (str[i++] == '\n') count++;

	return count;
}

void TruncateName(char[] name, int maxChars)
{
	int len = strlen(name);
	if (len <= maxChars)
		return;

	int pos, chars;
	while (pos < len && chars < maxChars)
	{
		int c = name[pos] & 0xFF;
		if      (c < 0x80) pos += 1;
		else if (c < 0xE0) pos += 2;
		else if (c < 0xF0) pos += 3;
		else               pos += 4;

		chars++;
	}

	name[pos] = '\0';
}

bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client));
}

bool IsValidSurvivor(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR);
}