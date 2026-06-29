/*
*	[L4D2] Minigun Heat HUD
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

#define PLUGIN_VERSION		"1.0.3"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Minigun Heat HUD
*	Author	:	JustMe
*	Descrp	:	Shows heat percentage with visual bar when using minigun or 50cal.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=352191

========================================================================================
	Change Log:

1.0.3 (17-May-2026)
	- Replaced crash-prone info_gamemode entity with L4D_GetGameModeType native.

1.0.2 (05-Apr-2026)
    - Fixed % symbol not displaying correctly in critical and warning heat branches. Thanks to Harry for the report.
    
1.0.1 (02-Apr-2026)
	- Added cvar l4d2_minigun_heat_hint_type to choose display method:
		0 = env_instructor_hint (default, may cause beep sound)
		1 = PrintCenterText (no beep, always visible in center)

1.0 (2025)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

// Bar display characters
#define BAR_FILLED			"|"
#define BAR_EMPTY			"."
#define BAR_LENGTH			20

// Sound paths
#define SOUND_WARNING		"ui/beep07.wav"
#define SOUND_OVERHEAT		"ui/beep_error01.wav"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarUpdateInterval, g_hCvarWarningThreshold, g_hCvarCriticalThreshold;
ConVar g_hCvarSoundWarning, g_hCvarSoundInterval, g_hCvarDisplayMode;
ConVar g_hCvarHintType;

float g_fCvarUpdateInterval, g_fCvarSoundInterval;
int g_iCvarWarningThreshold, g_iCvarCriticalThreshold, g_iCvarDisplayMode;
int g_iHintType;                                // 0 = env_instructor_hint, 1 = PrintCenterText
bool g_bCvarAllow, g_bCvarSoundWarning;
int g_iCurrentMode;

// Per-client data
Handle g_hTimerHeat[MAXPLAYERS+1];
Handle g_hTimerScan;
int g_iHintEntity[MAXPLAYERS+1];
bool g_bUsingMinigun[MAXPLAYERS+1];
float g_fLastWarningSound[MAXPLAYERS+1];
bool g_bWasOverheated[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Minigun Heat HUD",
	author = "JustMe",
	description = "Shows heat percentage with visual bar when using minigun or 50cal.",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=thaivanco123&description=&search=1"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =				CreateConVar(	"l4d2_minigun_heat_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =				CreateConVar(	"l4d2_minigun_heat_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =			CreateConVar(	"l4d2_minigun_heat_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =			CreateConVar(	"l4d2_minigun_heat_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarUpdateInterval =		CreateConVar(	"l4d2_minigun_heat_interval",		"0.1",			"Heat display update interval in seconds.", CVAR_FLAGS, true, 0.05, true, 1.0 );
	g_hCvarWarningThreshold =	CreateConVar(	"l4d2_minigun_heat_warning",		"60",			"Heat percentage to start warning (yellow color).", CVAR_FLAGS, true, 0.0, true, 100.0 );
	g_hCvarCriticalThreshold =	CreateConVar(	"l4d2_minigun_heat_critical",		"85",			"Heat percentage for critical warning (red color + sound).", CVAR_FLAGS, true, 0.0, true, 100.0 );
	g_hCvarSoundWarning =		CreateConVar(	"l4d2_minigun_heat_sound",			"1",			"0=Off, 1=Play warning sounds when heat is critical.", CVAR_FLAGS );
	g_hCvarSoundInterval =		CreateConVar(	"l4d2_minigun_heat_sound_interval",	"0.5",			"Interval between warning sounds in seconds.", CVAR_FLAGS, true, 0.1, true, 2.0 );
	g_hCvarDisplayMode =		CreateConVar(	"l4d2_minigun_heat_display",		"1",			"Display mode. 0=Text only, 1=Bar + Text, 2=Bar only.", CVAR_FLAGS, true, 0.0, true, 2.0 );
	g_hCvarHintType =			CreateConVar(	"l4d2_minigun_heat_hint_type",		"1",			"Display type: 0=env_instructor_hint (may beep), 1=PrintCenterText (no beep).", CVAR_FLAGS, true, 0.0, true, 1.0 );
	CreateConVar(								"l4d2_minigun_heat_version",		PLUGIN_VERSION,	"Minigun Heat HUD plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD );
	AutoExecConfig(true,						"l4d2_minigun_heat_hud");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarUpdateInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWarningThreshold.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCriticalThreshold.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSoundWarning.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSoundInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDisplayMode.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHintType.AddChangeHook(ConVarChanged_Cvars);

	// Initialize arrays
	for( int i = 1; i <= MAXPLAYERS; i++ )
	{
		g_hTimerHeat[i] = null;
		g_iHintEntity[i] = INVALID_ENT_REFERENCE;
		g_bUsingMinigun[i] = false;
		g_fLastWarningSound[i] = 0.0;
		g_bWasOverheated[i] = false;
	}
}

public void OnPluginEnd()
{
	CleanupAll();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	PrecacheSound(SOUND_WARNING, true);
	PrecacheSound(SOUND_OVERHEAT, true);
}

public void OnMapEnd()
{
	CleanupAll();
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCvarUpdateInterval = g_hCvarUpdateInterval.FloatValue;
	g_fCvarSoundInterval = g_hCvarSoundInterval.FloatValue;
	g_iCvarWarningThreshold = g_hCvarWarningThreshold.IntValue;
	g_iCvarCriticalThreshold = g_hCvarCriticalThreshold.IntValue;
	g_iCvarDisplayMode = g_hCvarDisplayMode.IntValue;
	g_bCvarSoundWarning = g_hCvarSoundWarning.BoolValue;
	g_iHintType = g_hCvarHintType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("map_transition",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("mission_lost",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_leaving",	Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("player_death",			Event_PlayerDeath);
		HookEvent("player_team",			Event_PlayerTeam);

		StartScanTimer();
	}
	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("map_transition",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("mission_lost",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving",	Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("player_death",				Event_PlayerDeath);
		UnhookEvent("player_team",				Event_PlayerTeam);

		CleanupAll();
	}
}

bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_iCurrentMode == 0 )
		{
			if( !L4D_HasMapStarted() )
				return false;

			g_iCurrentMode = L4D_GetGameModeType();
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CleanupAll();
	StartScanTimer();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	CleanupAll();
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 && client <= MaxClients )
		StopHeatMonitor(client);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 && client <= MaxClients )
		StopHeatMonitor(client);
}

public void OnClientDisconnect(int client)
{
	StopHeatMonitor(client);
}



// ====================================================================================================
//					SCAN TIMER
// ====================================================================================================
void StartScanTimer()
{
	delete g_hTimerScan;
	g_hTimerScan = CreateTimer(0.5, Timer_ScanPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ScanPlayers(Handle timer)
{
	if( !g_bCvarAllow )
	{
		g_hTimerScan = null;
		return Plugin_Stop;
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( !IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) )
		{
			if( g_bUsingMinigun[i] )
				StopHeatMonitor(i);
			continue;
		}

		bool usingNow = IsUsingMinigun(i);

		if( usingNow && !g_bUsingMinigun[i] )
			StartHeatMonitor(i);
		else if( !usingNow && g_bUsingMinigun[i] )
			StopHeatMonitor(i);
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					HEAT MONITOR
// ====================================================================================================
void StartHeatMonitor(int client)
{
	if( client < 1 || client > MaxClients || !g_bCvarAllow )
		return;

	g_bUsingMinigun[client] = true;
	g_fLastWarningSound[client] = 0.0;
	g_bWasOverheated[client] = false;

	if( g_iHintType == 0 )
		CreateHintEntity(client);

	delete g_hTimerHeat[client];
	g_hTimerHeat[client] = CreateTimer(g_fCvarUpdateInterval, Timer_UpdateHeat, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void StopHeatMonitor(int client)
{
	if( client < 1 || client > MaxClients )
		return;

	g_bUsingMinigun[client] = false;
	g_bWasOverheated[client] = false;

	delete g_hTimerHeat[client];
	
	if( g_iHintType == 0 )
		DestroyHintEntity(client);
}

Action Timer_UpdateHeat(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if( client < 1 || !IsClientInGame(client) || !g_bCvarAllow )
	{
		if( client > 0 && client <= MaxClients )
		{
			g_hTimerHeat[client] = null;
			g_bUsingMinigun[client] = false;
			if( g_iHintType == 0 )
				DestroyHintEntity(client);
		}
		return Plugin_Stop;
	}

	if( !IsUsingMinigun(client) )
	{
		g_hTimerHeat[client] = null;
		g_bUsingMinigun[client] = false;
		if( g_iHintType == 0 )
			DestroyHintEntity(client);
		return Plugin_Stop;
	}

	int minigun = GetEntPropEnt(client, Prop_Send, "m_hUseEntity");
	if( minigun == -1 || !IsValidEntity(minigun) )
	{
		g_hTimerHeat[client] = null;
		g_bUsingMinigun[client] = false;
		if( g_iHintType == 0 )
			DestroyHintEntity(client);
		return Plugin_Stop;
	}

	float heat = GetEntPropFloat(minigun, Prop_Send, "m_heat");
	int heatPercent = RoundToFloor(heat * 100.0);
	if( heatPercent > 100 ) heatPercent = 100;
	if( heatPercent < 0 ) heatPercent = 0;

	bool overheated = GetEntProp(minigun, Prop_Send, "m_overheated") != 0;

	// Play warning sounds
	if( g_bCvarSoundWarning )
		PlayWarningSound(client, heatPercent, overheated);

	// Display heat
	ShowHeatDisplay(client, heatPercent, overheated);

	return Plugin_Continue;
}



// ====================================================================================================
//					WARNING SOUNDS
// ====================================================================================================
void PlayWarningSound(int client, int heatPercent, bool overheated)
{
	float currentTime = GetGameTime();

	if( overheated )
	{
		if( !g_bWasOverheated[client] )
		{
			EmitSoundToClient(client, SOUND_OVERHEAT, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
			g_bWasOverheated[client] = true;
		}
	}
	else
	{
		g_bWasOverheated[client] = false;

		if( heatPercent >= g_iCvarCriticalThreshold )
		{
			float adjustedInterval = g_fCvarSoundInterval * (1.0 - (float(heatPercent - g_iCvarCriticalThreshold) / float(100 - g_iCvarCriticalThreshold)) * 0.7);
			if( currentTime - g_fLastWarningSound[client] >= adjustedInterval )
			{
				float volume = 0.5 + (float(heatPercent - g_iCvarCriticalThreshold) / float(100 - g_iCvarCriticalThreshold)) * 0.5;
				EmitSoundToClient(client, SOUND_WARNING, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, volume);
				g_fLastWarningSound[client] = currentTime;
			}
		}
	}
}



// ====================================================================================================
//					HEAT DISPLAY
// ====================================================================================================
void ShowHeatDisplay(int client, int heatPercent, bool overheated)
{
	char sMessage[128];
	int color[3];
	char sBar[64];
	BuildHeatBar(sBar, sizeof(sBar), heatPercent);

	if( overheated )
	{
		static bool flash;
		flash = !flash;
		color[0] = flash ? 255 : 200;
		color[1] = 0;
		color[2] = 0;

		switch( g_iCvarDisplayMode )
		{
			case 0: FormatEx(sMessage, sizeof(sMessage), "!! OVERHEATED !!");
			case 1: FormatEx(sMessage, sizeof(sMessage), "!! OVERHEATED !!\n%s", sBar);
			case 2: FormatEx(sMessage, sizeof(sMessage), "!! %s !!", sBar);
		}
	}
	else if( heatPercent >= g_iCvarCriticalThreshold )
	{
		color[0] = 255;
		color[1] = 50;
		color[2] = 0;

		switch( g_iCvarDisplayMode )
		{
			case 0: FormatEx(sMessage, sizeof(sMessage), "HEAT: %d%%%%", heatPercent);
			case 1: FormatEx(sMessage, sizeof(sMessage), "HEAT: %d%%%%\n%s", heatPercent, sBar);
			case 2: FormatEx(sMessage, sizeof(sMessage), "%s %d%%%%", sBar, heatPercent);
		}
	}
	else if( heatPercent >= g_iCvarWarningThreshold )
	{
		float ratio = float(heatPercent - g_iCvarWarningThreshold) / float(g_iCvarCriticalThreshold - g_iCvarWarningThreshold);
		color[0] = 255;
		color[1] = RoundToFloor(255.0 * (1.0 - ratio * 0.8));
		color[2] = 0;

		switch( g_iCvarDisplayMode )
		{
			case 0: FormatEx(sMessage, sizeof(sMessage), "Heat: %d%%%%", heatPercent);
			case 1: FormatEx(sMessage, sizeof(sMessage), "Heat: %d%%%%\n%s", heatPercent, sBar);
			case 2: FormatEx(sMessage, sizeof(sMessage), "%s %d%%%%", sBar, heatPercent);
		}
	}
	else
	{
		float ratio = float(heatPercent) / float(g_iCvarWarningThreshold);
		color[0] = RoundToFloor(255.0 * ratio);
		color[1] = 255;
		color[2] = 0;

		switch( g_iCvarDisplayMode )
		{
			case 0: FormatEx(sMessage, sizeof(sMessage), "Heat: %d%%%%", heatPercent);
			case 1: FormatEx(sMessage, sizeof(sMessage), "Heat: %d%%%%\n%s", heatPercent, sBar);
			case 2: FormatEx(sMessage, sizeof(sMessage), "%s %d%%%%", sBar, heatPercent);
		}
	}

	if( g_iHintType == 0 )
	{
		if( !IsValidEntRef(g_iHintEntity[client]) )
			return;

		int hintEntity = EntRefToEntIndex(g_iHintEntity[client]);
		if( hintEntity == INVALID_ENT_REFERENCE || !IsValidEntity(hintEntity) )
			return;

		char sTargetName[32], sColor[32];
		FormatEx(sTargetName, sizeof(sTargetName), "heat_target_%d", client);
		FormatEx(sColor, sizeof(sColor), "%d %d %d", color[0], color[1], color[2]);

		SetEntPropString(client, Prop_Data, "m_iName", sTargetName);

		DispatchKeyValue(hintEntity, "hint_target", sTargetName);
		DispatchKeyValue(hintEntity, "hint_color", sColor);
		DispatchKeyValue(hintEntity, "hint_caption", sMessage);
		DispatchKeyValue(hintEntity, "hint_timeout", "0.0");
		DispatchKeyValue(hintEntity, "hint_static", "0");
		DispatchKeyValue(hintEntity, "hint_nooffscreen", "1");
		DispatchKeyValue(hintEntity, "hint_forcecaption", "1");
		DispatchKeyValue(hintEntity, "hint_range", "0");
		DispatchKeyValue(hintEntity, "hint_icon_onscreen", "");
		DispatchKeyValue(hintEntity, "hint_icon_offscreen", "");
		DispatchKeyValue(hintEntity, "hint_suppress_rest", "1");

		AcceptEntityInput(hintEntity, "ShowHint");
	}
	else // g_iHintType == 1
	{
		char sFlat[128];
		strcopy(sFlat, sizeof(sFlat), sMessage);
		ReplaceString(sFlat, sizeof(sFlat), "\n", " ", false);
		PrintCenterText(client, sFlat);
	}
}

void BuildHeatBar(char[] buffer, int maxlen, int heatPercent)
{
	int filledBars = RoundToFloor(float(heatPercent) / 100.0 * BAR_LENGTH);
	int emptyBars = BAR_LENGTH - filledBars;

	buffer[0] = '\0';
	StrCat(buffer, maxlen, "[");
	for( int i = 0; i < filledBars; i++ ) StrCat(buffer, maxlen, BAR_FILLED);
	for( int i = 0; i < emptyBars; i++ ) StrCat(buffer, maxlen, BAR_EMPTY);
	StrCat(buffer, maxlen, "]");
}



// ====================================================================================================
//					HINT ENTITY
// ====================================================================================================
void CreateHintEntity(int client)
{
	if( client < 1 || client > MaxClients || !g_bCvarAllow )
		return;

	DestroyHintEntity(client);

	int hintEntity = CreateEntityByName("env_instructor_hint");
	if( hintEntity == -1 )
		return;

	if( !DispatchSpawn(hintEntity) )
	{
		RemoveEntity(hintEntity);
		return;
	}

	g_iHintEntity[client] = EntIndexToEntRef(hintEntity);
}

void DestroyHintEntity(int client)
{
	if( client < 1 || client > MaxClients )
		return;

	if( IsValidEntRef(g_iHintEntity[client]) )
	{
		int hintEntity = EntRefToEntIndex(g_iHintEntity[client]);
		if( hintEntity != INVALID_ENT_REFERENCE && IsValidEntity(hintEntity) )
		{
			AcceptEntityInput(hintEntity, "EndHint");
			RemoveEntity(hintEntity);
		}
	}
	g_iHintEntity[client] = INVALID_ENT_REFERENCE;
}



// ====================================================================================================
//					CLEANUP
// ====================================================================================================
void CleanupAll()
{
	delete g_hTimerScan;
	for( int i = 1; i <= MaxClients; i++ )
		StopHeatMonitor(i);
}



// ====================================================================================================
//					UTILITY FUNCTIONS
// ====================================================================================================
bool IsValidEntRef(int entRef)
{
	return entRef != INVALID_ENT_REFERENCE && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE;
}