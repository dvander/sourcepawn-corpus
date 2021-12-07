/*
*	Heartbeat (Revive Fix - Post Revive Options)
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



#define PLUGIN_VERSION 		"1.7"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Heartbeat (Revive Fix - Post Revive Options)
*	Author	:	SilverShot
*	Descrp	:	Fixes survivor_max_incapacitated_count cvar increased values reverting black and white screen. Also some extra options.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322132
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (31-Mar-2021)
	- Added command "sm_heartbeat" to toggle or specify someone as black and white health status.

1.6 (15-Feb-2021)
	- Fixed heartbeat sound playing when replacing a bot. Thanks to "Endoyurei Shirokuro" for reporting.

1.5 (15-Jul-2020)
	- Added more StopSound calls on player spawn. Thanks to "Endoyurei Shirokuro" for reporting.

1.4 (10-May-2020)
	- Various changes to tidy up code.

1.3 (26-Apr-2020)
	- Added native "Heartbeat_GetRevives" for 3rd party plugins to get a players current incap count.
	- Added native "Heartbeat_SetRevives" for 3rd party plugins to set a players current incap count.
	- Changes to prevent duplicate heartbeat sounds playing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.2 (11-Apr-2020)
	- Fixed not resetting the heartbeat sound on player death.

1.1 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (17-Mar-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define SOUND_HEART			"player/heartbeatloop.wav"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRevives, g_hCvarScreen, g_hCvarSound, g_hCvarVocal, g_hCvarMaxIncap, g_hCvarDecay;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
float g_fDecayDecay;
int g_iCvarRevives, g_iCvarScreen, g_iCvarSound, g_iCvarVocal;
int g_iReviveCount[MAXPLAYERS+1];
bool g_bHookedDamageMain[MAXPLAYERS+1];
bool g_bHookedDamagePost[MAXPLAYERS+1];


/**
 * Gets the revive count of a client.
 * @remarks:				Because this plugin overwrites "m_currentReviveCount" netprop in L4D1, this native allows you to get the actual revive value for clients.
 *
 * @param client			Client index to affect.
 *
 * @noreturn
 */
native void Heartbeat_GetRevives(int client);

/**
 * Sets the revive count on a client.
 * @remarks:				Because this plugin overwrites "m_currentReviveCount" netprop in L4D1, this native allows you to set the actual revive value for clients.
 *
 * @param client			Client index to affect.
 * @param reviveCount		The Survivors revive count.
 * @param reviveLogic		Triggers the revive logic which determines if someones screen is black and white, if the heartbeat should play etc.
 *							Setting to false would only set their revive count and the Heartbeat settings would not be followed. Should probably always be default: true.
 *
 * @noreturn
 */
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

/*
// 3rd party respawn style plugins can optionally use this native when the Heartbeat plugin is detected with the following code:

// Globals
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true); // To allow calling the native
bool g_bHeartbeatPlugin;

// Plugin start detect
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("Heartbeat_SetRevives");
}

public void OnAllPluginsLoaded()
{
	if( GetFeatureStatus(FeatureType_Native, "Heartbeat_SetRevives") != FeatureStatus_Unknown )
	{
		g_bHeartbeatPlugin = true;
	}
}

// Code to put in your function.
void YourFunction()
{
	if( g_bHeartbeatPlugin )
	{
		// Set to specific value;
		Heartbeat_SetRevives(client, 2); // Set the number of current revives, 0 or greater

		// Increment
		int revives = Heartbeat_GetRevives(client);
		Heartbeat_SetRevives(client, revives + 1);
	}
}
// */



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Heartbeat (Revive Fix - Post Revive Options)",
	author = "SilverShot",
	description = "Fixes survivor_max_incapacitated_count cvar increased values reverting black and white screen. Also some extra options.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322132"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("l4d_heartbeat");

	CreateNative("Heartbeat_GetRevives", Native_GetRevives);
	CreateNative("Heartbeat_SetRevives", Native_SetRevives);

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	// ====================
	// CVARS
	// ====================
	g_hCvarAllow =			CreateConVar(	"l4d_heartbeat_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_heartbeat_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_heartbeat_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_heartbeat_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRevives =		CreateConVar(	"l4d_heartbeat_revives",		"2",				"How many revives are allowed before a player is killed (wrapper to overwrite survivor_max_incapacitated_count cvar).", CVAR_FLAGS );
	g_hCvarScreen =			CreateConVar(	"l4d_heartbeat_screen",			"2",				"How many revives until the black and white screen overlay starts.", CVAR_FLAGS );
	g_hCvarSound =			CreateConVar(	"l4d_heartbeat_sound",			"2",				"How many revives until the heartbeat sound starts playing.", CVAR_FLAGS );
	g_hCvarVocal =			CreateConVar(	"l4d_heartbeat_vocalize",		"2",				"How many revives until the player starts vocalizing that they're about to die.", CVAR_FLAGS );
	CreateConVar(							"l4d_heartbeat_version",		PLUGIN_VERSION,		"Heartbeat plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_heartbeat");

	g_hCvarDecay = FindConVar("pain_pills_decay_rate");
	g_hCvarMaxIncap = FindConVar("survivor_max_incapacitated_count");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRevives.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarScreen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSound.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVocal.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDecay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxIncap.AddChangeHook(ConVarChanged_Cvars);

	IsAllowed();

	// ====================
	// COMMANDS
	// ====================
	AddCommandListener(CommandListener, "give");

	RegAdminCmd("sm_heartbeat", CmdHeatbeat, ADMFLAG_ROOT, "Set someone as black and white health status or toggle their state. Usage: sm_heartbeat [#userid|name] [state: 0=Healed. 1=Black and white.]");
}

public Action CmdHeatbeat(int client, int args)
{
	int state;

	if( args )
	{
		char sArg[32], target_name[MAX_TARGET_LENGTH];

		if( args == 2 )
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			state = StringToInt(sArg) + 1;
		}

		GetCmdArg(1, sArg, sizeof(sArg));

		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			sArg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		GetCmdArgString(sArg, sizeof(sArg));
		for( int i = 0; i < target_count; i++ )
		{
			if( GetClientTeam(target_list[i]) == 2 )
			{
				// Heal
				if( state != 2 && g_iReviveCount[target_list[i]] >= g_iCvarScreen )
				{
					// Toggle main health to temp health:
					// SetEntityHealth(target_list[i], RoundToCeil(GetEntPropFloat(target_list[i], Prop_Send, "m_healthBuffer")));
					// SetEntPropFloat(target_list[i], Prop_Send, "m_healthBuffer", 0.0);
					// SetEntPropFloat(target_list[i], Prop_Send, "m_healthBufferTime", GetGameTime());

					ResetCount(target_list[i]);
					ReviveLogic(target_list[i], GetClientUserId(target_list[i]));
				}
				else if( state != 1 && g_iReviveCount[target_list[i]] < g_iCvarScreen )
				{
					// Toggle main health to temp health:
					// SetEntPropFloat(target_list[i], Prop_Send, "m_healthBuffer", float(GetClientHealth(target_list[i])));
					// SetEntPropFloat(target_list[i], Prop_Send, "m_healthBufferTime", GetGameTime());
					// SetEntityHealth(target_list[i], 1);

					g_iReviveCount[target_list[i]] = g_iCvarScreen;
					ReviveLogic(target_list[i], GetClientUserId(target_list[i]));
				}
			}
		}
	} else {
		// Heal
		if( g_iReviveCount[client] >= g_iCvarScreen )
		{
			// Toggle main health to temp health:
			// SetEntityHealth(client, RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer")));
			// SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			// SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());

			ResetCount(client);
			ReviveLogic(client, GetClientUserId(client));
		}
		else
		{
			// Toggle main health to temp health:
			// SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(GetClientHealth(client)));
			// SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			// SetEntityHealth(client, 1);

			g_iReviveCount[client] = g_iCvarScreen;
			ReviveLogic(client, GetClientUserId(client));
		}
	}

	return Plugin_Handled;
}

public Action CommandListener(int client, const char[] command, int args)
{
	if( args > 0 )
	{
		char buffer[8];
		GetCmdArg(1, buffer, sizeof(buffer));

		if( strcmp(buffer, "health") == 0 )
		{
			ResetCount(client);
		}
	}
}

public int Native_GetRevives(Handle plugin, int numParams)
{
	return g_iReviveCount[GetNativeCell(1)];
}

public int Native_SetRevives(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	g_iReviveCount[client] = GetNativeCell(2);

	if( numParams != 3 || GetNativeCell(3) )
	{
		ReviveLogic(client, GetClientUserId(client));
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

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarRevives = g_hCvarRevives.IntValue;
	g_iCvarScreen = g_hCvarScreen.IntValue;
	g_iCvarSound = g_hCvarSound.IntValue;
	g_iCvarVocal = g_hCvarVocal.IntValue;

	g_fDecayDecay = g_hCvarDecay.FloatValue;

	SetConVarInt(g_hCvarMaxIncap, g_iCvarRevives, true);
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("bot_player_replace",		Event_BotReplace);
		HookEvent("player_death",		Event_Spawned);
		HookEvent("player_spawn",		Event_Spawned);
		HookEvent("heal_success",		Event_Healed);
		HookEvent("revive_success",		Event_Revive);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("bot_player_replace",	Event_BotReplace);
		UnhookEvent("player_death",		Event_Spawned);
		UnhookEvent("player_spawn",		Event_Spawned);
		UnhookEvent("heal_success",		Event_Healed);
		UnhookEvent("revive_success",	Event_Revive);
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
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame

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
//					STUFF
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheSound(SOUND_HEART);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

void ResetCount(int client)
{
	g_iReviveCount[client] = 0;
	ResetSound(client);

	if( g_bHookedDamageMain[client] )	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamageMain);
	if( g_bHookedDamagePost[client] )	SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);

	g_bHookedDamageMain[client] = false;
	g_bHookedDamagePost[client] = false;
}

float GetTempHealth(int client)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fDecayDecay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

public Action OnTakeDamagePost(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( g_iReviveCount[client] < g_iCvarVocal )
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	} else {
		SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
		g_bHookedDamagePost[client] = false;
	}
}

public Action OnTakeDamageMain(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int health = GetClientHealth(client) + RoundToFloor(GetTempHealth(client));

	if( damage >= health )
	{
		if( g_iReviveCount[client] >= g_iCvarRevives )
		{
			// PrintToServer("Heartbeat: Allow die %N (%d/%d)", client, g_iReviveCount[client], g_iCvarRevives);
			ResetSound(client);

			// Allow to die
			if( g_bLeft4Dead2 )
				SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			else
				SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iCvarRevives);

			// Unhook
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamageMain);
			g_bHookedDamageMain[client] = false;

			if( g_bHookedDamagePost[client] )
			{
				SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
				g_bHookedDamagePost[client] = false;
			}
		}
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void Event_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		ResetSound(client);
		ResetSound(client);
		ResetSound(client);
	}
}

public void Event_Spawned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		ResetCount(client);
		ResetSound(client);
		ResetSound(client);
		ResetSound(client);
	}
}

public void Event_Healed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	ResetCount(client);
}

public void Event_Revive(Event event, const char[] name, bool dontBroadcast)
{
	int userid;
	if( (userid = event.GetInt("subject")) && event.GetInt("ledge_hang") == 0 )
	{
		int client = GetClientOfUserId(userid);
		if( client )
		{
			g_iReviveCount[client]++;
			// ReviveLogic(client, userid, true);
			ReviveLogic(client, userid);
		}
	}
}

// void ReviveLogic(int client, int userid, bool fromEvent = false)
void ReviveLogic(int client, int userid)
{
	// PrintToServer("Revives: %N (%d)", client, g_iReviveCount[client]);

	// Monitor for death
	if( g_iReviveCount[client] == g_iCvarRevives && !g_bHookedDamageMain[client] )
	{
		g_bHookedDamageMain[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageMain);
	}

	// Set black and white or not
	if( g_iReviveCount[client] >= g_iCvarScreen )
	{
		if( g_bLeft4Dead2 )
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		else
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 2);
	} else {
		if( g_bLeft4Dead2 )
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		else
			SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iReviveCount[client] == 2 ? 1 : g_iReviveCount[client]);
	}

	// Vocalize death
	if( g_iReviveCount[client] < g_iCvarVocal )
	{
		if( !g_bHookedDamagePost[client] )
		{
			g_bHookedDamagePost[client] = true;
			SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
		}

		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	}

	// Heartbeat sound, stop dupe sound bug, only way.
	ResetSound(client);
	ResetSound(client);
	ResetSound(client);
	ResetSound(client);

	if( g_iReviveCount[client] >= g_iCvarSound )
	{
		// if( g_bLeft4Dead2 && fromEvent && g_iReviveCount[client] == g_iCvarRevives ) return; // Game emits itself, would duplicate sound even with stop... Seems to work fine now with multiple resets..?
		RequestFrame(OnFrameSound, userid);
	}
}

void ResetSound(int client)
{
	StopSound(client, SNDCHAN_STATIC, SOUND_HEART);
}

void OnFrameSound(int client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		EmitSoundToClient(client, SOUND_HEART, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
	}
}