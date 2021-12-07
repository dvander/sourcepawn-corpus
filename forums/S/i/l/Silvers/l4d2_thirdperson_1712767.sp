/*
*	Survivor Thirdperson
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.8"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Survivor Thirdperson
*	Author	:	SilverShot
*	Descrp	:	Creates a command for survivors to use thirdperson view.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=185664
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.8 (23-Feb-2021)
	- Fixed the Charger resetting a Survivors thirdperson view after punching them. Thanks to "psisan" for reporting.

1.7 (24-Sep-2020)
	- Fixed the Charger resetting a Survivors thirdperson view after charging into them. Thanks to "Pelee" for reporting.

1.6 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Fixed the commands not following the allow cvars.
	- Various changes to tidy up code.

1.5 (06-Apr-2020)
	- Fixed mounted guns causing the players model to rotate in thirdperson. Thanks to "Alex101192" for reporting.

1.4 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.3 (12-Oct-2019)
	- Added commands "sm_3rdon" and "sm_3rdoff" to explicitly set the view.

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.1 (21-May-2012)
	- Removed admin only access from the commands, they are now usable by all survivors.

1.0 (20-May-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Thirdperson\x04] \x01"

#define SEQUENCE_NI			667	// Nick
#define SEQUENCE_RO			674	// Rochelle, Adawong
#define SEQUENCE_CO			656	// Coach
#define SEQUENCE_EL			671	// Ellis
#define SEQUENCE_BI			759	// Bill
#define SEQUENCE_ZO			819	// Zoey
#define SEQUENCE_FR			762	// Francis
#define SEQUENCE_LO			759	// Louis


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bMapStarted, g_bThirdView[MAXPLAYERS+1], g_bMountedGun[MAXPLAYERS+1];
Handle g_hTimerReset[MAXPLAYERS+1], g_hTimerGun;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Survivor Thirdperson",
	author = "SilverShot",
	description = "Creates a command for survivors to use thirdperson view.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=185664"
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
	LoadTranslations("common.phrases");

	g_hCvarAllow =		CreateConVar(	"l4d2_third_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_third_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_third_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_third_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d2_third_version",	PLUGIN_VERSION, "Survivor Thirdperson plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_third");

	RegConsoleCmd("sm_3rdoff",		CmdTP_Off,		"Turns thirdperson view off.");
	RegConsoleCmd("sm_3rdon",		CmdTP_On,		"Turns thirdperson view on.");
	RegConsoleCmd("sm_3rd",			CmdThird,		"Toggles thirdperson view.");
	RegConsoleCmd("sm_tp",			CmdThird,		"Toggles thirdperson view.");
	RegConsoleCmd("sm_third",		CmdThird,		"Toggles thirdperson view.");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsPlayerAlive(i) )
		{
			g_bMountedGun[i] = false;
			g_bThirdView[i] = false;
			SetEntPropFloat(i, Prop_Send, "m_TimeForceExternalView", 0.0);
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}

		HookEvent("player_spawn",			Event_PlayerSpawn);
		HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("mounted_gun_start",		Event_MountedGun);
		HookEvent("charger_impact",			Event_ChargerImpact);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;

		delete g_hTimerGun;

		UnhookEvent("player_spawn",			Event_PlayerSpawn);
		UnhookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("mounted_gun_start",	Event_MountedGun);
		UnhookEvent("charger_impact",		Event_ChargerImpact);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
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

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bThirdView[client] = false;
	g_bMountedGun[client] = false;

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimerGun;

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_bThirdView[i] = false;
		g_bMountedGun[i] = false;
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimerGun;
}

public void Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("victim");
	int client = GetClientOfUserId(userid);
	if( client )
	{
		if( g_bThirdView[client] )
		{
			SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
		}
	}
}

public void OnClientDisconnect(int client)
{
	delete g_hTimerReset[client];
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( g_bThirdView[victim] && damagetype == DMG_CLUB && victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3 )
	{
		delete g_hTimerReset[victim];
		g_hTimerReset[victim] = CreateTimer(1.0, TimerReset, GetClientUserId(victim), TIMER_REPEAT);
		SetEntPropFloat(victim, Prop_Send, "m_TimeForceExternalView", 99999.3);
	}
}

public Action TimerReset(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if( client && g_bThirdView[client] )
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);

		// Repeat timer if still in stumble animation
		static char sModel[32];

		GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		int anim = GetEntProp(client, Prop_Send, "m_nSequence");

		switch( sModel[29] )
		{
			case 'b': // Nick
			{
				if( anim == SEQUENCE_NI ) return Plugin_Continue;
			}
			case 'd', 'w': // Rochelle, Adawong
			{
				if( anim == SEQUENCE_RO ) return Plugin_Continue;
			}
			case 'c': // Coach
			{
				if( anim == SEQUENCE_CO ) return Plugin_Continue;
			}
			case 'h': // Ellis
			{
				if( anim == SEQUENCE_EL ) return Plugin_Continue;
			}
			case 'v': // Bill
			{
				if( anim == SEQUENCE_BI ) return Plugin_Continue;
			}
			case 'n': // Zoey
			{
				if( anim == SEQUENCE_ZO ) return Plugin_Continue;
			}
			case 'e': // Francis
			{
				if( anim == SEQUENCE_FR ) return Plugin_Continue;
			}
			case 'a': // Louis
			{
				if( anim == SEQUENCE_LO ) return Plugin_Continue;
			}
		}
	}

	g_hTimerReset[client] = null;
	return Plugin_Stop;
}

public void Event_MountedGun(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( g_bThirdView[client] )
	{
		g_bMountedGun[client] = true;
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);

		if( g_hTimerGun == null )
		{
			g_hTimerGun = CreateTimer(0.5, TimerCheck, _, TIMER_REPEAT);
		}
	}
}

public Action TimerCheck(Handle timer)
{
	int count;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_bMountedGun[i] && IsClientInGame(i) && IsPlayerAlive(i) )
		{
			if( GetEntProp(i, Prop_Send, "m_usingMountedWeapon") )
			{
				count++;
			}
			else
			{
				SetEntPropFloat(i, Prop_Send, "m_TimeForceExternalView", 99999.3);
				g_bMountedGun[i] = false;
			}
		}
	}

	if( count )
		return Plugin_Continue;

	g_hTimerGun = null;
	return Plugin_Stop;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
public Action CmdTP_Off(int client, int args)
{
	if( g_bCvarAllow && client && IsPlayerAlive(client) )
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
		PrintToChat(client, "%s%t", CHAT_TAG, "Off");
	}
}

public Action CmdTP_On(int client, int args)
{
	if( g_bCvarAllow && client && IsPlayerAlive(client) )
	{
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
		PrintToChat(client, "%s%t", CHAT_TAG, "On");
	}
}

public Action CmdThird(int client, int args)
{
	// if( g_bCvarAllow && client && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	if( g_bCvarAllow && client && IsPlayerAlive(client) )
	{
		// Goto third
		if( g_bThirdView[client] == false )
		{
			g_bThirdView[client] = true;
			SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
			PrintToChat(client, "%s%t", CHAT_TAG, "On");
		}
		// Goto first
		else
		{
			g_bThirdView[client] = false;
			SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
			PrintToChat(client, "%s%t", CHAT_TAG, "Off");
		}
	}

	return Plugin_Handled;
}