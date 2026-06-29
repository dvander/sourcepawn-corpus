/*
*	Heartbeat (Revive Fix - Post Revive Options)
*	Copyright (C) 2025 Silvers
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



#define PLUGIN_VERSION 		"1.17"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Heartbeat (Revive Fix - Post Revive Options)
*	Author	:	SilverShot
*	Descrp	:	Fixes survivor_max_incapacitated_count cvar increased values reverting black and white screen. Also some extra options.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322132
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.17 (21-May-2025)
	- Fixed client not in game errors. Thanks to "ioioio" for reporting.

1.16 (21-Apr-2024)
	- Fixed revive count increasing by 2 instead of 1 under certain circumstances. Thanks to "S.A.S" for reporting.

1.15 (16-Apr-2024)
	- Removed gamedata method patching the game which created a health bug. Thanks to "S.A.S" for reporting.
	- Fixed issues with "m_isGoingToDie" being set to 0 not damaging the player.

1.14 (12-Mar-2024)
	- Fixed native "Heartbeat_SetRevives" not setting the correct revive count if "reviveLogic" bool was set to false. Thanks to "little_froy" for reporting and testing.
	- Fixed clients not receiving damage from behind when on Easy difficulty, due to "m_isGoingToDie" being set to 0. Thanks to "little_froy" for reporting and testing.
	- Fixed client not in game error. Thanks to "HarryPotter" for reporting.
	- New GameData file required for the plugin to operate.

1.13 (10-Mar-2023)
	- Delayed revive logic by 1 frame to fix settings sometimes not being applied due to self revive plugins. Thanks to "Shao" for reporting.

1.12 (19-Feb-2023)
	- Added cvar "l4d_heartbeat_incap" to set black and white status when someone is incapped, not after revive. Requested by "Jestery".
	- Fixed heartbeat sound being stopped when other players respawn.

1.11 (03-Dec-2022)
	- Plugin now resets the heartbeat sound for spectators.

1.10 (15-Nov-2022)
	- Fixed the revive count not carrying over when switching to/from idle state. Thanks to "NoroHime" for reporting.

1.9 (02-Nov-2022)
	- Fixed screen turning black and white when they're not read to die. Thanks to "Iciaria" for reporting and lots of help testing.
	- Various changes to simplify the code.

1.8 (25-Aug-2022)
	- Changes to fix warnings when compiling on SM 1.11.
	- Fixed native "Heartbeat_GetRevives" return type wrongfully set as void instead of int.

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
#define DEBUG				0

#if DEBUG
#include <left4dhooks>
#endif


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarIncap, g_hCvarRevives, g_hCvarScreen, g_hCvarSound, g_hCvarVocal, g_hCvarMaxIncap, g_hCvarDecay;
bool g_bCvarAllow, g_bCvarIncap, g_bMapStarted, g_bLeft4Dead2;
float g_fDecayDecay, g_fTimeRevive;
int g_iCvarRevives, g_iCvarScreen, g_iCvarSound, g_iCvarVocal;
int g_iReviveCount[MAXPLAYERS+1];
bool g_bHookedDamage[MAXPLAYERS+1];
bool g_bIsGoingToDie[MAXPLAYERS+1];


/**
 * @brief Gets the revive count of a client.
 * @remarks Because this plugin overwrites "m_currentReviveCount" netprop in L4D1, this native allows you to get the actual revive value for clients.
 *
 * @param client			Client index to affect.
 *
 * @return					Number or revives
 */
native int Heartbeat_GetRevives(int client);

/**
 * @brief Sets the revive count on a client.
 * @remarks Because this plugin overwrites "m_currentReviveCount" netprop in L4D1, this native allows you to set the actual revive value for clients.
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

	CreateNative("Heartbeat_GetRevives", Native_GetRevives);
	CreateNative("Heartbeat_SetRevives", Native_SetRevives);

	RegPluginLibrary("l4d_heartbeat");

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
	g_hCvarIncap =			CreateConVar(	"l4d_heartbeat_incap",			"0",				"0=Off. 1=Set black and white status when someone is incapped, not after revive.", CVAR_FLAGS );
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
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);
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

	#if DEBUG
	RegAdminCmd("sm_temphealth", CmdTempHealth, ADMFLAG_ROOT);
	#endif



	// ====================
	// LATE LOAD
	// ====================
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			g_iReviveCount[i] = GetEntProp(i, Prop_Send, "m_currentReviveCount");

			if( !g_bHookedDamage[i] && g_iReviveCount[i] >= g_iCvarRevives )
			{
				g_bHookedDamage[i] = true;
				SDKHook(i, g_bLeft4Dead2 ? SDKHook_OnTakeDamageAlive : SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			}
		}
	}
}

// DEBUG TESTING
#if DEBUG
Action CmdTempHealth(int client, int args)
{
	g_hCvarDecay.FloatValue = 0.0;

	L4D_ReviveSurvivor(client);

	SetTempHealth(client, 100.0);
	return Plugin_Handled;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}
#endif

Action CmdHeatbeat(int client, int args)
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
					ReviveLogic(target_list[i]);
				}
				else if( state != 1 && g_iReviveCount[target_list[i]] < g_iCvarScreen )
				{
					// Toggle main health to temp health:
					// SetEntPropFloat(target_list[i], Prop_Send, "m_healthBuffer", float(GetClientHealth(target_list[i])));
					// SetEntPropFloat(target_list[i], Prop_Send, "m_healthBufferTime", GetGameTime());
					// SetEntityHealth(target_list[i], 1);

					g_iReviveCount[target_list[i]] = g_iCvarScreen;
					ReviveLogic(target_list[i]);
				}
			}
		}
	}
	else
	{
		if( !client )
		{
			ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
			return Plugin_Handled;
		}

		// Heal
		if( g_iReviveCount[client] >= g_iCvarScreen )
		{
			// Toggle main health to temp health:
			// SetEntityHealth(client, RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer")));
			// SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			// SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());

			ResetCount(client);
			ReviveLogic(client);
		}
		else
		{
			// Toggle main health to temp health:
			// SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(GetClientHealth(client)));
			// SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			// SetEntityHealth(client, 1);

			g_iReviveCount[client] = g_iCvarScreen;
			ReviveLogic(client);
		}
	}

	return Plugin_Handled;
}

Action CommandListener(int client, const char[] command, int args)
{
	if( args > 0 )
	{
		char buffer[8];
		GetCmdArg(1, buffer, sizeof(buffer));

		if( strcmp(buffer, "health") == 0 )
		{
			g_fTimeRevive = GetGameTime() + 0.1;
			ResetCount(client);
		}
	}

	return Plugin_Continue;
}

int Native_GetRevives(Handle plugin, int numParams)
{
	return g_iReviveCount[GetNativeCell(1)];
}

int Native_SetRevives(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	g_iReviveCount[client] = GetNativeCell(2);

	if( numParams != 3 || GetNativeCell(3) )
	{
		ReviveLogic(client);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iReviveCount[client]);
	}

	return 0;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
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
	g_bCvarIncap = g_hCvarIncap.BoolValue;
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
		HookEvent("player_bot_replace",		Event_ReplaceBot);
		HookEvent("player_death",			Event_Spawned);
		HookEvent("player_spawn",			Event_Spawned);
		HookEvent("player_incapacitated",	Event_Incapped);
		HookEvent("heal_success",			Event_Healed);
		HookEvent("revive_success",			Event_Revive);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("bot_player_replace",	Event_BotReplace);
		UnhookEvent("player_bot_replace",	Event_ReplaceBot);
		UnhookEvent("player_death",			Event_Spawned);
		UnhookEvent("player_spawn",			Event_Spawned);
		UnhookEvent("player_incapacitated",	Event_Incapped);
		UnhookEvent("heal_success",			Event_Healed);
		UnhookEvent("revive_success",		Event_Revive);
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

void OnGamemode(const char[] output, int caller, int activator, float delay)
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
	g_fTimeRevive = 0.0;
	g_bMapStarted = true;
	PrecacheSound(SOUND_HEART);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

void ResetCount(int client)
{
	g_bIsGoingToDie[client] = false;
	g_iReviveCount[client] = 0;
	ResetSoundObs(client);
	ResetSound(client);

	if( g_bHookedDamage[client] )
	{
		g_bHookedDamage[client] = false;
		SDKUnhook(client, g_bLeft4Dead2 ? SDKHook_OnTakeDamageAlive : SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}
}

float GetTempHealth(int client)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fDecayDecay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype, int weapon, float damageForce[3], float damagePosition[3])
{
	// Prevent yelling
	if( g_iReviveCount[client] < g_iCvarVocal )
	{
		g_bIsGoingToDie[client] = GetEntProp(client, Prop_Send, "m_isGoingToDie") == 1;

		if( g_bIsGoingToDie[client] )
		{
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
		}
	}
}

Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Prevent yelling
	if( g_iReviveCount[client] < g_iCvarVocal )
	{
		if( g_bIsGoingToDie[client] )
		{
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		}
	}

	// Allow to die
	if( g_iReviveCount[client] >= g_iCvarRevives )
	{
		int health = GetClientHealth(client) + RoundToFloor(GetTempHealth(client));

		if( health <= 0.0 || (!g_bLeft4Dead2 && health - damage < 0.0) )
		{
			// PrintToServer("Heartbeat: Allow die %N (%d/%d)", client, g_iReviveCount[client], g_iCvarRevives);
			ResetSoundObs(client);
			ResetSound(client);

			// Allow to die
			if( g_bLeft4Dead2 )
				SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			else
				SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iCvarRevives);

			// Unhook
			if( g_bHookedDamage[client] )
			{
				g_bHookedDamage[client] = false;
				SDKUnhook(client, g_bLeft4Dead2 ? SDKHook_OnTakeDamageAlive : SDKHook_OnTakeDamage, OnTakeDamage);
				SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			}
		}
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void Event_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if( client )
	{
		ResetSound(client);
		ResetSound(client);
		ResetSound(client);
		ResetSoundObs(client);
	}

	g_iReviveCount[client] = g_iReviveCount[bot];
}

void Event_ReplaceBot(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_iReviveCount[bot] = g_iReviveCount[client];
}

void Event_Spawned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		ResetCount(client);
		ResetSound(client);
		ResetSound(client);
		ResetSound(client);
		ResetSoundObs(client);
	}
}

void Event_Incapped(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bCvarIncap )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		g_iReviveCount[client]++;
		ReviveLogic(client);
		g_iReviveCount[client]--;
	}
}

void Event_Healed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	ResetCount(client);
}

void Event_Revive(Event event, const char[] name, bool dontBroadcast)
{
	if( g_fTimeRevive >= GetGameTime() ) return;

	int userid;
	if( (userid = event.GetInt("subject")) && event.GetInt("ledge_hang") == 0 )
	{
		int client = GetClientOfUserId(userid);
		if( client )
		{
			RequestFrame(OnFrameRevive, userid);
		}
	}
}

void OnFrameRevive(int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		g_iReviveCount[client]++;
		ReviveLogic(client);
	}
}

void ReviveLogic(int client)
{
	// PrintToServer("Revives: %N (%d)", client, g_iReviveCount[client]);

	// Monitor for death
	if( !g_bHookedDamage[client] && g_iReviveCount[client] >= g_iCvarRevives )
	{
		g_bHookedDamage[client] = true;
		SDKHook(client, g_bLeft4Dead2 ? SDKHook_OnTakeDamageAlive : SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}

	if( g_bLeft4Dead2 )
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iReviveCount[client]);
	}

	// Set black and white or not
	if( g_iReviveCount[client] >= g_iCvarScreen )
	{
		if( g_bLeft4Dead2 )
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		else
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 2);
	}
	else
	{
		if( g_bLeft4Dead2 )
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		else
			SetEntProp(client, Prop_Send, "m_currentReviveCount", g_iReviveCount[client] == 2 ? 1 : g_iReviveCount[client]);
	}

	// Vocalize death
	if( g_iReviveCount[client] < g_iCvarVocal )
	{
		if( !g_bHookedDamage[client] )
		{
			g_bHookedDamage[client] = true;
			SDKHook(client, g_bLeft4Dead2 ? SDKHook_OnTakeDamageAlive : SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		}

		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
	}

	// Heartbeat sound, stop dupe sound bug, only way.
	RequestFrame(OnFrameSound, GetClientUserId(client));
	ResetSound(client);
	ResetSound(client);
	ResetSound(client);
	ResetSound(client);
	ResetSoundObs(client);

	if( g_iReviveCount[client] >= g_iCvarSound )
	{
		// if( g_bLeft4Dead2 && fromEvent && g_iReviveCount[client] == g_iCvarRevives ) return; // Game emits itself, would duplicate sound even with stop... Seems to work fine now with multiple resets..?
		CreateTimer(0.1, TimerSound, GetClientUserId(client));
	}
}

void ResetSoundObs(int client)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client )
		{
			RequestFrame(OnFrameSound, GetClientUserId(i));
			ResetSound(i);
			ResetSound(i);
			ResetSound(i);
			ResetSound(i);
		}
	}
}

void OnFrameSound(int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		ResetSound(client);
	}
}

void ResetSound(int client)
{
	StopSound(client, SNDCHAN_AUTO, SOUND_HEART);
	StopSound(client, SNDCHAN_STATIC, SOUND_HEART);
}

Action TimerSound(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		EmitSoundToClient(client, SOUND_HEART, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
	}

	return Plugin_Continue;
}
