/*
*	Lock Doors
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION 		"1.21"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Lock Doors
*	Author	:	SilverShot
*	Descrp	:	Replicates an old feature Valve removed, allowing players to lock and unlock doors. Also sets open/closed/locked doors health.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322899
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.21 (11-Dec-2022)
	- Fixed an invalid handle error.

1.20 (09-Jul-2022)
	- Fixed sometimes ignoring blocked door models when using random doors. Thanks to "gongo" for reporting.

1.19 (05-Jul-2022)
	- Fixed random doors not working in L4D1 and throwing errors. Thanks to "gongo" for reporting.
	- Fixed bug detecting tanks in L4D1 or regarding Jockey's as tanks in L4D2.

1.18 (26-Jun-2022)
	- Added command "sm_doors_random" to randomly open or close doors based on the random cvar settings.
	- Increased the range of rescue door detection to prevent opening some rescue closets. Thanks to "gongo" for reporting.
	- Blocked another model from being by used the plugin (c5m2_park) which prevented common spawning. Thanks to "gongo" for reporting.

1.17 (24-Jun-2022)
	- Fixed health bugs under certain conditions. Thanks to "gongo" for reporting.
	- Fixed bots from locking doors. They can still unlock them instead of teleporting through locked doors.
	- Now supports all 3rd party maps for the "random" feature of opening/closing doors on round start.
	- Now fully supports unloading and late loading the plugin. Random doors will not change when late loading.
	- Renamed command "sm_lock_doors_health" to "sm_doors_health".

1.16 (16-Jun-2022)
	- Added more models to be ignored by the plugins features.
	- Plugin now ignores outhouse and gun cabinet doors.
	- Added an optional data config to specify maps the plugin should be allowed or blocked on, depending on the new cvar value.
	- Added cvar "l4d_lock_doors_map_block" to allow or block the plugin working on the maps listed in the data config.
	- Fixed rare bug causing all doors to be unusable.
	- Fixed setting double doors health to the wrong values when using the random cvar.
	- L4D2: Fixed random doors not working on the 3rd party map "The Hive" chapter 1.
	- L4D2: Fixed the map "CEDA Fever" chapter 1 intro missing the "gameinstructor_draw" event, which prevented random doors from working.
	- Thanks to "gongo" for reporting and lots of help testing.

1.15 (05-Jun-2022)
	- Added commands "sm_doors_close", "sm_doors_open" and "sm_doors_tog" to control all doors.

1.14 (03-Jun-2022)
	- Changed cvar "l4d_lock_doors_keys" to accept the value of "0" to disable the locking and unlocking doors feature.
	- Really fixed doors not randomly opening or closing on new campaigns. Thanks to "gongo" for help.

1.13 (01-Jun-2022)
	- Added command "sm_doors_glow" to make doors glow, for debug testing.
	- Fixed potentially not finding some relative double doors.

1.12 (01-Jun-2022)
	- Fixed not finding relative double doors that used only identical targetnames to match. Thanks to "gongo" for reporting.

1.11 (01-Jun-2022)
	- Added cvar "l4d_lock_doors_random_type" to set if doors should be randomly opened or closed only, or toggled by their current state.
	- Fixed not always opening or closing doors on round restarts. Thanks to "gongo" for reporting.
	- Restored ability to lock alarmed doors, but plugin no longer randomly opens them. Thanks to "Toranks" for reporting.

1.10 (30-May-2022)
	- Added cvar "l4d_lock_doors_invincible" to control if invincible doors should be allowed (stock game function).
	- Fixed affecting some doors which should be closed for events etc.
	- Fixed double doors not always opening in the same direction.
	- Fixed potentially not working on some round restarts.

1.9 (30-May-2022)
	- Added cvar "l4d_lock_doors_damage_tank" to control a Tanks shove damage on doors.
	- Now requires double doors to be closed before locking.
	- Fixed the damage cvars not following the "0" value to use default game damage.
	- Fixed some doors sometimes becoming invincible and not breaking.
	- Fixed another case where random doors were not set after server start.

1.8 (29-May-2022)
	- Added cvars "l4d_lock_doors_damage_common", "l4d_lock_doors_damage_infected" and "l4d_lock_doors_damage_survivor" to control shove damage on doors. Thanks to "Maur0" for reporting.
	- Added support for competitive Versus to open/close the same doors for both teams.
	- Now ignores randomly opening a door if it's near an "info_survivor_rescue" entity. Thanks to "gongo" for reporting.
	- Better handling for opening double doors in the same direction, should work in most cases/maps.
	- Fixed accidental additional character in printing message.
	- Fixed not randomly opening or closing doors on server start.

1.7 (29-May-2022)
	- Fixed cvar "l4d_lock_doors_random" not setting random door positions on round restart. Thanks to "gongo" for reporting.

1.6 (29-May-2022)
	- Added command "sm_lock_doors_health" to check a doors health.
	- Added cvar "l4d_lock_doors_random" to randomly open or close doors on round start.
	- Fixed the health not being consistently set correctly.
	- Fixed locking or unlocking from opening or closing the door.
	- Fixed issues with double doors not being handled together.
	- Change cvar "l4d_lock_doors_text" description and default value for hint messages printing to all instead of an individual client and vice versa.

	- Thanks to "gongo" for reporting issues and testing.
	- Thanks to "Toranks" for help testing.

1.5 (20-Jul-2021)
	- Blocked some door models that are missing the door knob animation. Thanks to "sonic155" for reporting.

1.4 (21-Jun-2021)
	- Added door handle animation and sound when attempting to open a locked door. Requested by "The Renegadist".

1.3 (18-Aug-2020)
	- Added cvar "l4d_lock_doors_range" to set the distance players must be to lock or unlock doors.

1.2 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.1 (08-Apr-2020)
	- Changed the lock sound and increased volume.
	- Fixed server start or when the plugin was enabled again. Thanks to "Cuba" for reporting.

1.0 (07-Apr-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define DATA_CONFIG				"data/l4d_lock_doors.cfg"
#define SOUND_LOCK				"doors/default_locked.wav" // door_lock_1
#define SOUND_LOCKED			"doors/latchlocked2.wav"
#define SOUND_UNLOCK			"doors/door_latch3.wav"

#define DOOR_NEAR_RESCUE		170		// Range to info_survivor_rescue
#define DOOR_NEAR_VERSUS		10		// Range to match the same door on round 2 - value of 0 would probably be fine
#define DEBUG_PRINT				0


// Testing: l4d_lock_doors_health_open 1.0; l4d_lock_doors_health_shut 2.0; l4d_lock_doors_health_lock 3.0;

// From left4dhooks, optional native if left4dhooks is detected:
native bool L4D_IsFirstMapInScenario();


// Thanks to "Dragokas":
enum // m_eDoorState
{
	DOOR_STATE_CLOSED,
	DOOR_STATE_OPENING_IN_PROGRESS,
	DOOR_STATE_OPENED,
	DOOR_STATE_CLOSING_IN_PROGRESS
}

// Thanks to "Dragokas":
enum // m_spawnflags
{
	DOOR_FLAG_STARTS_OPEN		= 1,
	DOOR_FLAG_STARTS_LOCKED		= 2048,
	DOOR_FLAG_SILENT			= 4096,
	DOOR_FLAG_USE_CLOSES		= 8192,
	DOOR_FLAG_SILENT_NPC		= 16384,
	DOOR_FLAG_IGNORE_USE		= 32768,
	DOOR_FLAG_UNBREAKABLE		= 524288
}

enum
{
	TYPE_COMMON,
	TYPE_INFECTED,
	TYPE_SURVIVOR,
	TYPE_TANK,
}

enum
{
	BLOCK_UNKNOWN,
	BLOCK_ALLOWED,
	BLOCK_RANDOM,
	BLOCK_PLUGIN,
}


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDamageC, g_hCvarDamageI, g_hCvarDamageS, g_hCvarDamageT, g_hCvarHealthL, g_hCvarHealthO, g_hCvarHealthS, g_hCvarHealthT, g_hCvarInvin, g_hCvarKeys, g_hCvarMapBlock, g_hCvarRandom, g_hCvarRandomT, g_hCvarRange, g_hCvarText, g_hCvarVoca;
float g_fCvarHealthL, g_fCvarHealthO, g_fCvarHealthS, g_fCvarRange;
int g_iPlayerSpawn, g_iRoundStart, g_iRoundNumber, g_iBlockedMap, g_iClassTank, g_iCvarDamageC, g_iCvarDamageI, g_iCvarDamageS, g_iCvarDamageT, g_iCvarKeys, g_iCvarMapBlock, g_iCvarRandom, g_iCvarRandomT, g_iCvarText, g_iCvarVoca, g_iCvarHealthT;

bool g_bCvarAllow, g_bCvarInvin, g_bBootedServer, g_bIntro, g_bMapStarted, g_bRoundStarted, g_bRandomDoors, g_bLeft4DHooks, g_bLeft4Dead2, g_bGlow;
float g_fLastUse[MAXPLAYERS+1], g_fLastPrint;
float g_vPos[2048][3];
int g_iEntity[2048];
int g_iState[2048];
int g_iDoors[2048];
int g_iFlags[2048];
int g_iHealth[2048];
int g_iRelative[2048];

Handle g_hTimerRandom;
StringMap g_hBlockedMaps;


// Block door models
char g_sBlockedModels[6][] =
{
	"models/props_urban/outhouse_door001.mdl",
	"models/props_unique/guncabinet01_ldoor.mdl",
	"models/props_unique/guncabinet01_rdoor.mdl",
	"models/props_waterfront/footlocker01.mdl",
	"models/props_windows/window_urban_sash_32_72_full_gib08.mdl",
	"models/props_vehicles/ceda_door_rotating.mdl"
};

// Vocalize for Left 4 Dead 2
static const char g_sCoach[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoorc101", "closethedoorc102"
};
static const char g_sEllis[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoorc101", "closethedoorc102"
};
static const char g_sNick[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07", "closethedoor08", "closethedoor09", "closethedoorc101", "closethedoorc102"
};
static const char g_sRochelle[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoorc101", "closethedoorc102", "closethedoorc103", "closethedoorc104", "closethedoorc105"
};

// Vocalize for Left 4 Dead 1
static const char g_sBill[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07", "closethedoor08", "closethedoor09", "closethedoor10", "closethedoor11", "closethedoor12", "closethedoor13"
};
static const char g_sFrancis[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07", "closethedoor08", "closethedoor09", "closethedoor10", "closethedoor11", "closethedoor12"
};
static const char g_sLouis[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07"
};
static const char g_sZoey[][] =
{
	"closethedoor01", "closethedoor07", "closethedoor08", "closethedoor11", "closethedoor16", "closethedoor17", "closethedoor19", "closethedoor22", "closethedoor28", "closethedoor29", "closethedoor33", "closethedoor41", "closethedoor42", "closethedoor45", "closethedoor50"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Lock Doors",
	author = "SilverShot",
	description = "Replicates an old feature Valve removed, allowing players to lock and unlock doors. Also sets open/closed/locked doors health.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322899"
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

	if( late )
	{
		g_bBootedServer = true;
		g_iPlayerSpawn = 1;
	}

	MarkNativeAsOptional("L4D_IsFirstMapInScenario");

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bLeft4DHooks = GetFeatureStatus(FeatureType_Native, "L4D_IsFirstMapInScenario") == FeatureStatus_Available;
}

public void OnPluginStart()
{
	g_iClassTank = g_bLeft4Dead2 ? 8 : 5;

	// Cvars
	g_hCvarAllow =		CreateConVar("l4d_lock_doors_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar("l4d_lock_doors_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar("l4d_lock_doors_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar("l4d_lock_doors_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDamageC =	CreateConVar("l4d_lock_doors_damage_common",	"250",				"0=Default game damage. Amount of damage to cause to doors when shoved by a Common Infected.", CVAR_FLAGS );
	g_hCvarDamageI =	CreateConVar("l4d_lock_doors_damage_infected",	"250",				"0=Default game damage. Amount of damage to cause to doors when shoved by a Special Infected.", CVAR_FLAGS );
	g_hCvarDamageS =	CreateConVar("l4d_lock_doors_damage_survivor",	"250",				"0=Default game damage. Amount of damage to cause to doors when shoved by a Survivor.", CVAR_FLAGS );
	g_hCvarDamageT =	CreateConVar("l4d_lock_doors_damage_tank",		"0",				"0=Default game damage. Amount of damage to cause to doors when shoved by a Tank.", CVAR_FLAGS );
	g_hCvarHealthL =	CreateConVar("l4d_lock_doors_health_lock",		"2.0",				"0=Off. Percentage of health to set when the door is locked.", CVAR_FLAGS );
	g_hCvarHealthO =	CreateConVar("l4d_lock_doors_health_open",		"0.5",				"0=Off. Percentage of health to set when the door is open.", CVAR_FLAGS );
	g_hCvarHealthS =	CreateConVar("l4d_lock_doors_health_shut",		"1.0",				"0=Off. Percentage of health to set when the door is shut.", CVAR_FLAGS );
	g_hCvarHealthT =	CreateConVar("l4d_lock_doors_health_total",		"840",				"0=Off. How much health doors have on spawn (840 game default on some maps).", CVAR_FLAGS );
	g_hCvarInvin =		CreateConVar("l4d_lock_doors_invincible",		"0",				"0=No invincible doors. 1=Allow doors which are damaged when shot etc but don't break (default game behaviour).", CVAR_FLAGS );
	g_hCvarKeys =		CreateConVar("l4d_lock_doors_keys",				"1",				"0=Off (no locking doors). 1=Shift (walk) + E (use). 2=Ctrl (duck) + E (use). Which key combination to lock/unlock doors.", CVAR_FLAGS );
	g_hCvarMapBlock =	CreateConVar("l4d_lock_doors_map_block",		"2",				"0=Off. 1=Maps listed in the data config will allow the plugin to work. 2=Maps listed in the data config will block the plugin from working.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar("l4d_lock_doors_random",			"0",				"0=Off. On round start the chance out of 100 to randomly open or close a door. Versus 2nd round will open/close the same doors. Requires the Left4DHooks plugin.", CVAR_FLAGS );
	g_hCvarRandomT =	CreateConVar("l4d_lock_doors_random_type",		"1",				"1=Open doors only. 2=Close doors only. 3=Open doors that are closed, and close doors that are open. When used with the random cvar.", CVAR_FLAGS );
	g_hCvarRange =		CreateConVar("l4d_lock_doors_range",			"150",				"0=Any distance. How close a player must be to the door they're trying to lock or unlock.", CVAR_FLAGS );
	g_hCvarText =		CreateConVar("l4d_lock_doors_text",				"11",				"0=Off. Display a chat message when: 1=Locking doors. 2=Unlocking doors. 4=To all players. 8=To self. Add numbers together.", CVAR_FLAGS );
	g_hCvarVoca =		CreateConVar("l4d_lock_doors_vocalize",			"1",				"0=Off. 1=-Vocalize when locking doors.", CVAR_FLAGS );
	CreateConVar(					"l4d_lock_doors_version",			PLUGIN_VERSION,		"Lock Doors plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_lock_doors");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDamageC.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageI.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageS.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageT.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthL.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthO.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthS.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthT.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarInvin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarKeys.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMapBlock.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarText.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandomT.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVoca.AddChangeHook(ConVarChanged_Cvars);



	// Commands
	if( g_bLeft4Dead2 && CommandExists("sm_doors_glow") == false ) // Shared with "Barricades - Doors and Windows" plugin
	{
		RegAdminCmd("sm_doors_glow", CmdDoorsGlow, ADMFLAG_ROOT, "Debug testing command to show all doors.");
	}

	RegAdminCmd("sm_doors_random", CmdDoorsRandom, ADMFLAG_ROOT, "Randomly opens or closes doors based on the random cvar settings. This will mess up Versus saving and restoring.");
	RegAdminCmd("sm_doors_health", CmdHealth, ADMFLAG_ROOT, "Returns the health of the door you're aiming at.");
	RegAdminCmd("sm_doors_close", CmdDoorsClose, ADMFLAG_ROOT, "Closes all doors on the map.");
	RegAdminCmd("sm_doors_open", CmdDoorsOpen, ADMFLAG_ROOT, "Opens all doors on the map.");
	RegAdminCmd("sm_doors_tog", CmdDoorsTog, ADMFLAG_ROOT, "Toggle state of all doors on the map.");
	RegAdminCmd("sm_doors_vs", CmdDoorsVS, ADMFLAG_ROOT, "Toggle all doors testing for Versus save and restore.");



	// Config - Blocked maps
	g_hBlockedMaps = new StringMap();
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), DATA_CONFIG);
	if( FileExists(sPath) )
	{
		File hFile = OpenFile(sPath, "r");
		if( hFile )
		{
			while( !hFile.EndOfFile() && hFile.ReadLine(sPath, sizeof(sPath)) )
			{
				ReplaceString(sPath, sizeof(sPath), "\n", "");
				ReplaceString(sPath, sizeof(sPath), "\r", "");

				if( sPath[0] && strncmp(sPath, "//", 2) ) // Ignore empty lines and lines starting with comments
				{
					sPath[1] = 0;
					g_hBlockedMaps.SetValue(sPath[2], StringToInt(sPath[0]));
				}
			}
		}
	}
}

public void OnPluginEnd()
{
	int entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		int health = GetEntProp(entity, Prop_Data, "m_iHealth");
		int state = GetEntProp(entity, Prop_Data, "m_eDoorState");

		if( (state == DOOR_STATE_CLOSED || state == DOOR_STATE_OPENING_IN_PROGRESS) && g_fCvarHealthS )
		{
			int setting = RoundFloat(g_fCvarHealthS > 1.0 ? health / g_fCvarHealthS : health * g_fCvarHealthS);
			if( setting )
			{
				SetEntProp(entity, Prop_Data, "m_iHealth", setting);
			}
		}
		else if( (state == DOOR_STATE_OPENED || state == DOOR_STATE_CLOSING_IN_PROGRESS) && g_fCvarHealthO )
		{
			int setting = RoundFloat(g_fCvarHealthO < 1.0 ? health / g_fCvarHealthO : health * g_fCvarHealthO);
			if( setting )
			{
				SetEntProp(entity, Prop_Data, "m_iHealth", setting);
			}
		}
	}
}

void BlockMapCheck()
{
	// Check if random doors allowed on this map
	if( g_iBlockedMap == BLOCK_UNKNOWN )
	{
		char sMap[128];
		GetCurrentMap(sMap, sizeof(sMap));

		g_hBlockedMaps.GetValue(sMap, g_iBlockedMap);

		if( g_iCvarMapBlock == 1 ) // Allow only on listed maps
		{
			switch( g_iBlockedMap )
			{
				case 0:		g_iBlockedMap = BLOCK_PLUGIN; // Not listed, block plugin
				case 1:		g_iBlockedMap = BLOCK_RANDOM; // Block random doors
				case 2:		g_iBlockedMap = BLOCK_ALLOWED; // Allow plugin
				default:	g_iBlockedMap = BLOCK_ALLOWED;
			}
		}
		else if( g_iCvarMapBlock == 2 ) // Block only on listed maps
		{
			switch( g_iBlockedMap )
			{
				case 0:		g_iBlockedMap = BLOCK_ALLOWED; // Not listed, allow plugin
				case 1:		g_iBlockedMap = BLOCK_RANDOM; // Block random doors
				case 2:		g_iBlockedMap = BLOCK_PLUGIN; // Block plugin
				default:	g_iBlockedMap = BLOCK_ALLOWED;
			}
		}
		else
		{
			g_iBlockedMap = BLOCK_ALLOWED;
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
	g_iCvarDamageC = g_hCvarDamageC.IntValue;
	g_iCvarDamageI = g_hCvarDamageI.IntValue;
	g_iCvarDamageS = g_hCvarDamageS.IntValue;
	g_iCvarDamageT = g_hCvarDamageT.IntValue;
	g_fCvarHealthL = g_hCvarHealthL.FloatValue;
	g_fCvarHealthO = g_hCvarHealthO.FloatValue;
	g_fCvarHealthS = g_hCvarHealthS.FloatValue;
	g_iCvarHealthT = g_hCvarHealthT.IntValue;
	g_bCvarInvin = g_hCvarInvin.BoolValue;
	g_iCvarKeys = g_hCvarKeys.IntValue;
	g_iCvarMapBlock = g_hCvarMapBlock.IntValue;
	g_iCvarText = g_hCvarText.IntValue;
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_iCvarRandomT = g_hCvarRandomT.IntValue;
	g_fCvarRange = g_hCvarRange.FloatValue;
	g_iCvarVoca = g_hCvarVoca.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		ResetPlugin();

		if( g_iPlayerSpawn == 1 )
		{
			SearchForDoors();
		}

		HookEvent("player_spawn",				Event_PlayerSpawn);
		HookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",					Event_RoundEnd,		EventHookMode_PostNoCopy);
		if( !g_bLeft4Dead2 )
		{
			HookEvent("gameinstructor_draw",	Event_Draw,			EventHookMode_PostNoCopy);
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		OnPluginEnd();

		UnhookEvent("player_spawn",				Event_PlayerSpawn);
		UnhookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		if( !g_bLeft4Dead2 )
		{
			UnhookEvent("gameinstructor_draw",	Event_Draw,			EventHookMode_PostNoCopy);
		}

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			UnhookSingleEntityOutput(entity, "OnFullyOpen", Door_Moved);
			UnhookSingleEntityOutput(entity, "OnFullyClosed", Door_Moved);
		}
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
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

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
		}

	if( g_hCvarMPGameMode == null )
		return false;

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
//					EVENTS
// ====================================================================================================
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	// Block plugin operating on this map
	BlockMapCheck();
	if( g_iBlockedMap == BLOCK_PLUGIN ) return;

	// Search doors
	if( !g_bBootedServer ) // First server boot to find doors and randomize doors, otherwise they won't open
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client && !IsFakeClient(client) )
		{
			CreateTimer(5.0, TimerStart, true, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if( g_bBootedServer && g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
	{
		#if DEBUG_PRINT
		PrintToChatAll("\x03Event_PlayerSpawn");
		PrintToServer("\x03Event_PlayerSpawn");
		#endif

		CreateTimer(1.0, TimerStart, false, TIMER_FLAG_NO_MAPCHANGE);
	}

	g_iPlayerSpawn = 1;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Block plugin operating on this map
	BlockMapCheck();
	if( g_iBlockedMap == BLOCK_PLUGIN ) return;



	// Search doors
	if( g_bBootedServer && g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
	{
		#if DEBUG_PRINT
		PrintToChatAll("\x03Event_RoundStart");
		PrintToServer("\x03Event_RoundStart");
		#endif

		CreateTimer(1.0, TimerStart, false, TIMER_FLAG_NO_MAPCHANGE);
	}

	g_iRoundStart = 1;



	// Versus related, to open the same doors as previous team
	g_iRoundNumber++;

	#if DEBUG_PRINT
	if( g_iRoundNumber > 2 ) g_iRoundNumber = 1; // For debugging, to allow multiple round restarts with mp_restartgame 1
	#endif

	if( g_iCurrentMode <= 2 || g_iRoundNumber == 1 ) ResetPlugin();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bGlow = false;
	g_bIntro = false;
	g_bRandomDoors = false;
	g_bRoundStarted = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_fLastPrint = 0.0;
}

void Event_Draw(Event event, const char[] name, bool dontBroadcast)
{
	g_bIntro = false;
}

Action TimerStart(Handle timer, any boot)
{
	g_hTimerRandom = null;

	if( boot && g_bBootedServer ) return Plugin_Continue;

	SearchForDoors();
	g_bBootedServer = true;
	g_bRoundStarted = true;



	// Random doors
	if( g_iCvarRandom && g_bLeft4DHooks )
	{
		BlockMapCheck();

		if( g_iBlockedMap == BLOCK_ALLOWED )
		{
			if( L4D_IsFirstMapInScenario() )
			{
				g_bIntro = true; // Only used for L4D1

				delete g_hTimerRandom;
				g_hTimerRandom = CreateTimer(1.0, TimerRandom, _, TIMER_REPEAT);
			}
			else
			{
				g_bIntro = false; // Only used for L4D1

				g_hTimerRandom = CreateTimer(1.0, TimerRandom);
			}
		}
	}

	return Plugin_Continue;
}

public void OnMapStart()
{
	delete g_hTimerRandom;

	g_bMapStarted = true;

	PrecacheSound(SOUND_LOCK);
	PrecacheSound(SOUND_LOCKED);
	PrecacheSound(SOUND_UNLOCK);
}

public void OnMapEnd()
{
	g_bGlow = false;
	g_bIntro = false;
	g_bMapStarted = false;
	g_bRoundStarted = false;
	g_iRoundNumber = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_iBlockedMap = 0;

	ResetPlugin();
}

void ResetPlugin(bool state = false)
{
	#if DEBUG_PRINT
	PrintToChatAll("\x05ResetPlugin: %d", state);
	PrintToServer("\x05ResetPlugin: %d", state);
	#endif

	g_bRandomDoors = false;
	g_fLastPrint = 0.0;

	for( int i = 0; i <= MaxClients; i++ )
	{
		g_fLastUse[i] = 0.0;
	}

	for( int i = 0; i < 2048; i++ )
	{
		// Return doors to original position, only used for versus test command
		if( state )
		{
			if( g_iEntity[i] && EntRefToEntIndex(g_iEntity[i]) != INVALID_ENT_REFERENCE )
			{
				#if DEBUG_PRINT
				PrintToChatAll("\x03Reset state: %d to %s", i, g_iState[i] -1 == DOOR_STATE_CLOSED ? "CLOSED" : "OPEN");
				PrintToServer("\x03Reset state: %d to %s", i, g_iState[i] -1 == DOOR_STATE_CLOSED ? "CLOSED" : "OPEN");
				#endif

				switch( g_iState[i] -1 )
				{
					case DOOR_STATE_OPENED:		OpenOrClose(i, DOOR_STATE_CLOSED);
					case DOOR_STATE_CLOSED:		OpenOrClose(i, DOOR_STATE_OPENED);
				}
			}
		}

		if( !state || g_iCurrentMode <= 2 ) // Reset all vars and in coop/survival
		{
			g_iEntity[i] = 0;
			g_iState[i] = 0;
			g_iRelative[i] = 0;
			g_vPos[i][0] = 0.0;
			g_vPos[i][1] = 0.0;
			g_vPos[i][2] = 0.0;
		}
	}
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
Action CmdDoorsRandom(int client, int args)
{
	if( g_iCvarRandom )
	{
		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
		{
			g_iState[entity] = 0;

			if( GetEntProp(entity, Prop_Data, "m_bLocked") == 0 )
			{
				// Ignore certain models used on doors
				static char sModel[64];
				GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

				for( int i = 0; i < sizeof(g_sBlockedModels); i++ )
				{
					if(	strcmp(sModel[6], g_sBlockedModels[i][6], false) == 0 )
					{
						#if DEBUG_PRINT
						PrintToChatAll("\x04IGNORING BLOCKED DOOR MODEL CR: %d (%s)", entity, sModel);
						PrintToServer("IGNORING BLOCKED DOOR MODEL CR: %d (%s)", entity, sModel);
						#endif

						return Plugin_Handled;
					}
				}

				RandomDoor(entity);
			}
		}

		ReplyToCommand(client, "[Doors] Randomly opened or closed doors.");
	}
	else
	{
		ReplyToCommand(client, "[Doors] Random doors not enabled.");
	}

	return Plugin_Handled;
}

Action CmdHealth(int client, int args)
{
	if( client )
	{
		int entity = GetClientAimTarget(client, false);
		if( entity != -1 )
		{
			char sTemp[32];
			GetEdictClassname(entity, sTemp, sizeof(sTemp));
			if( strcmp(sTemp, "prop_door_rotating") == 0 )
			{
				ReplyToCommand(client, "Door %d health = %d", entity, GetEntProp(entity, Prop_Data, "m_iHealth"));
				return Plugin_Handled;
			}
		}
	} else {
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ReplyToCommand(client, "Invalid door or no entity.");

	return Plugin_Handled;
}

Action CmdDoorsGlow(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Doors] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	g_bGlow = !g_bGlow;

	int entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 255);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_bGlow ? 0 : 9999);
		SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 20);
		if( g_bGlow )
			AcceptEntityInput(entity, "StartGlowing");
		else
			AcceptEntityInput(entity, "StopGlowing");

		ChangeEdictState(entity, 0);
	}

	PrintToChat(client, "\x04[Doors] \x01Doors glow turned: \x05%s", g_bGlow ? "On" : "Off");

	return Plugin_Handled;
}

Action CmdDoorsClose(int client, int args)
{
	int entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		OpenOrClose(entity, DOOR_STATE_CLOSED);
	}

	return Plugin_Handled;
}

Action CmdDoorsOpen(int client, int args)
{
	int entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		OpenOrClose(entity, DOOR_STATE_OPENED);
	}

	return Plugin_Handled;
}

Action CmdDoorsTog(int client, int args)
{
	int entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		if( GetEntProp(entity, Prop_Data, "m_eDoorState") == DOOR_STATE_OPENED )
			OpenOrClose(entity, DOOR_STATE_CLOSED);
		else
			OpenOrClose(entity, DOOR_STATE_OPENED);
	}

	return Plugin_Handled;
}

Action CmdDoorsVS(int client, int args)
{
	if( g_iCurrentMode != 4 )
	{
		ReplyToCommand(client, "[DOORS] Not versus mode");
		return Plugin_Handled;
	}

	g_iRoundNumber++;

	if( g_iRoundNumber > 2 )
	{
		ResetPlugin(false);
		g_iRoundNumber = 1;
	}

	if( g_iRoundNumber == 2 )
	{
		ReplyToCommand(client, "[DOORS] Restoring versus doors (round %d). Please wait...", g_iRoundNumber);
	}
	else
	{
		ReplyToCommand(client, "[DOORS] Saving versus doors (round %d). Please wait...", g_iRoundNumber);
	}

	ResetPlugin(true);

	delete g_hTimerRandom;
	g_hTimerRandom = CreateTimer(1.0, TimerRandom);

	return Plugin_Handled;
}



// ====================================================================================================
//					DOOR SPAWN
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bCvarAllow && g_bRoundStarted )
	{
		// Block plugin operating on this map
		BlockMapCheck();

		if( g_iBlockedMap != BLOCK_PLUGIN && strcmp(classname, "prop_door_rotating") == 0 )
		{
			SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
		}
	}
}

void SpawnPost(int entity)
{
	SpawnPostMain(entity);
}

void SpawnPostMain(int entity)
{
	// Ignore certain models used on doors
	static char sModel[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	for( int i = 0; i < sizeof(g_sBlockedModels); i++ )
	{
		if(	strcmp(sModel[6], g_sBlockedModels[i][6], false) == 0 )
		{
			#if DEBUG_PRINT
			PrintToChatAll("\x04IGNORING BLOCKED DOOR MODEL: %d (%s)", entity, sModel);
			PrintToServer("IGNORING BLOCKED DOOR MODEL: %d (%s)", entity, sModel);
			#endif

			return;
		}
	}

	if( GetEntProp(entity, Prop_Data, "m_bLocked") == 0 )
	{
		g_iDoors[entity] = EntIndexToEntRef(entity);

		g_iFlags[entity] = -1;
		g_iHealth[entity] = GetEntProp(entity, Prop_Data, "m_iHealth");

		// Find double doors
		MatchRelatives(entity);

		// Health
		SetDoorHealth(entity, true);

		// Random door opening
		if( g_bRandomDoors )
			RandomDoor(entity);

		// Hooks
		HookSingleEntityOutput(entity, "OnFullyOpen", Door_Moved);
		HookSingleEntityOutput(entity, "OnFullyClosed", Door_Moved);
	}
}



// ====================================================================================================
//					FIND DOORS
// ====================================================================================================
void SearchForDoors()
{
	// Block plugin operating on this map
	BlockMapCheck();
	if( g_iBlockedMap == BLOCK_PLUGIN ) return;

	// Already checked, ignore
	if( g_bRoundStarted ) return;

	#if DEBUG_PRINT
	PrintToChatAll("\x03SearchForDoors");
	PrintToServer("\x03SearchForDoors");
	#endif

	int entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		SpawnPostMain(entity);
	}
}

void MatchRelatives(int entity)
{
	static char sTemp[128], sTarget[128];
	int target = -1;

	// Match relative doors by "m_SlaveName"
	GetEntPropString(entity, Prop_Data, "m_SlaveName", sTemp, sizeof(sTemp));

	if( sTemp[0] != 0 )
	{
		while( (target = FindEntityByClassname(target, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
		{
			if( target != entity )
			{
				GetEntPropString(target, Prop_Data, "m_iName", sTarget, sizeof(sTarget));
				if( strcmp(sTemp, sTarget) == 0 )
				{
					g_iRelative[target] = EntIndexToEntRef(entity);
					g_iRelative[entity] = EntIndexToEntRef(target);
					return;
				}
			}
		}
	}

	// Match relative doors by "m_iName"
	GetEntPropString(entity, Prop_Data, "m_iName", sTemp, sizeof(sTemp));

	if( sTemp[0] != 0 )
	{
		target = -1;

		while( (target = FindEntityByClassname(target, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
		{
			if( target != entity )
			{
				GetEntPropString(target, Prop_Data, "m_iName", sTarget, sizeof(sTarget));
				if( strcmp(sTemp, sTarget) == 0 )
				{
					g_iRelative[target] = EntIndexToEntRef(entity);
					g_iRelative[entity] = EntIndexToEntRef(target);
					return;
				}
			}
		}
	}
}



// ====================================================================================================
//					RANDOM OPEN/CLOSE
// ====================================================================================================
Action TimerRandom(Handle timer)
{
	if( g_bLeft4Dead2 ? GameRules_GetProp("m_bInIntro") == 0 : g_bIntro == false ) // Must wait until intro has finished, doors don't move during it
	{
		g_hTimerRandom = CreateTimer(1.0, TimerRandom2);

		return Plugin_Stop;
	}

	if( g_hTimerRandom == timer )
		g_hTimerRandom = null;

	return Plugin_Continue;
}

Action TimerRandom2(Handle timer)
{
	g_hTimerRandom = null;

	int entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		if( GetEntProp(entity, Prop_Data, "m_bLocked") == 0 )
		{
			// Ignore certain models used on doors
			static char sModel[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			for( int i = 0; i < sizeof(g_sBlockedModels); i++ )
			{
				if(	strcmp(sModel[6], g_sBlockedModels[i][6], false) == 0 )
				{
					#if DEBUG_PRINT
					PrintToChatAll("\x04IGNORING BLOCKED DOOR MODEL TR2: %d (%s)", entity, sModel);
					PrintToServer("IGNORING BLOCKED DOOR MODEL TR2: %d (%s)", entity, sModel);
					#endif

					return Plugin_Continue;
				}
			}

			RandomDoor(entity);
		}
	}

	g_bRandomDoors = true;

	return Plugin_Continue;
}

void RandomDoor(int entity)
{
	BlockMapCheck();

	if( g_iCvarRandom && g_iBlockedMap == BLOCK_ALLOWED )
	{
		int flags = GetEntProp(entity, Prop_Send, "m_spawnflags");
		if( flags == 0 ) flags = GetEntProp(entity, Prop_Data, "m_spawnflags");

		// Many doors have the value "65535" which is all flags included, but they should be accessible, so allowing these to be modified
		// It seems doors with DOOR_FLAG_UNBREAKABLE flag are to trigger events, alarmed doors. c1m2_streets - supermarket doors. c1m3_mall - alarmed door into the mall gauntlet.
		// Ignoring those so they stay randomly closed
		if( flags == 65535 || flags & DOOR_FLAG_UNBREAKABLE == 0 )
		{
			g_iEntity[entity] = EntIndexToEntRef(entity);

			// Versus, restore door states from previous round
			if( g_iCurrentMode == 4 && g_iRoundNumber == 2 )
			{
				float vPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				// Loop through saved doors
				for( int i = 0; i < 2048; i++ )
				{
					// Has a saved position
					if( g_vPos[i][0] != 0.0 && g_vPos[i][1] != 0.0 && g_vPos[i][2] != 0.0 )
					{
						// Match to the same door
						if( GetVectorDistance(vPos, g_vPos[i]) < DOOR_NEAR_VERSUS )
						{
							if( g_iState[i] -1 == DOOR_STATE_OPENED )
							{
								#if DEBUG_PRINT
								PrintToChatAll("\x05VERSUS RESTORE DOOR OPEN: %d (%f) %0.1f %0.1f %0.1f /  %0.1f %0.1f %0.1f", entity, GetVectorDistance(vPos, g_vPos[i]), vPos[0], vPos[1], vPos[2], g_vPos[i][0], g_vPos[i][1], g_vPos[i][2]);
								PrintToServer("\x05VERSUS RESTORE DOOR OPEN: %d (%f) %0.1f %0.1f %0.1f / %0.1f %0.1f %0.1f", entity, GetVectorDistance(vPos, g_vPos[i]), vPos[0], vPos[1], vPos[2], g_vPos[i][0], g_vPos[i][1], g_vPos[i][2]);
								#endif

								OpenOrClose(entity, DOOR_STATE_OPENED);
							}
							else if( g_iState[i] -1 == DOOR_STATE_CLOSED )
							{
								#if DEBUG_PRINT
								PrintToChatAll("\x05VERSUS RESTORE DOOR CLOSED: %d (%f) %0.1f %0.1f %0.1f /  %0.1f %0.1f %0.1f", entity, GetVectorDistance(vPos, g_vPos[i]), vPos[0], vPos[1], vPos[2], g_vPos[i][0], g_vPos[i][1], g_vPos[i][2]);
								PrintToServer("\x05VERSUS RESTORE DOOR CLOSED: %d (%f) %0.1f %0.1f %0.1f / %0.1f %0.1f %0.1f", entity, GetVectorDistance(vPos, g_vPos[i]), vPos[0], vPos[1], vPos[2], g_vPos[i][0], g_vPos[i][1], g_vPos[i][2]);
								#endif

								OpenOrClose(entity, DOOR_STATE_CLOSED);
							}

							g_vPos[i][0] = 0.0;
							g_vPos[i][1] = 0.0;
							g_vPos[i][2] = 0.0;
						}
					}
				}
			}
			else if( g_iCvarRandom == 100 || GetRandomInt(1, 100) <= g_iCvarRandom )
			{
				float vPos[3], vLoc[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				// Ignore doors to rescue rooms
				int target = -1;
				while( (target = FindEntityByClassname(target, "info_survivor_rescue")) != INVALID_ENT_REFERENCE )
				{
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", vLoc);
					if( GetVectorDistance(vPos, vLoc) <= DOOR_NEAR_RESCUE )
					{
						#if DEBUG_PRINT
						PrintToChatAll("\x04IGNORING RESCUE DOOR: %d (%f)", entity, GetVectorDistance(vPos, vLoc));
						PrintToServer("IGNORING RESCUE DOOR: %d (%f)", entity, GetVectorDistance(vPos, vLoc));
						#endif
						return;
					}
				}

				// Door is open, close it
				if( g_iCvarRandomT & 2 && GetEntProp(entity, Prop_Data, "m_eDoorState") == DOOR_STATE_OPENED )
				{
					if( g_iState[entity] == 0 )
					{
						// Relative (double doors)
						target = g_iRelative[entity];
						if( target && (target = EntRefToEntIndex(target)) != INVALID_ENT_REFERENCE )
						{
							g_iState[target] = DOOR_STATE_CLOSED + 1;

							// Save for VS
							if( g_iCurrentMode == 4 )
							{
								GetEntPropVector(target, Prop_Send, "m_vecOrigin", g_vPos[target]);

								#if DEBUG_PRINT
								PrintToChatAll("\x05VERSUS SAVE DBL DOOR CLOSED (%d): %0.1f %0.1f %0.1f", target, g_vPos[target][0], g_vPos[target][1], g_vPos[target][2]);
								PrintToServer("\x05VERSUS SAVE DBL DOOR CLOSED (%d): %0.1f %0.1f %0.1f", target, g_vPos[target][0], g_vPos[target][1], g_vPos[target][2]);
								#endif
							}

							#if DEBUG_PRINT
							PrintToChatAll("\x04RandomDoors DBL CLOSE %d", target);
							PrintToServer("RandomDoors DBL CLOSE %d", target);
							#endif

							OpenOrClose(target, DOOR_STATE_CLOSED);
						}

						// Door set
						g_iState[entity] = DOOR_STATE_CLOSED + 1;

						// Save for VS
						if( g_iCurrentMode == 4 )
						{
							g_vPos[entity] = vPos;

							#if DEBUG_PRINT
							PrintToChatAll("\x05VERSUS SAVE DOOR CLOSED (%d): %0.1f %0.1f %0.1f", entity, g_vPos[entity][0], g_vPos[entity][1], g_vPos[entity][2]);
							PrintToServer("\x05VERSUS SAVE DOOR CLOSED (%d): %0.1f %0.1f %0.1f", entity, g_vPos[entity][0], g_vPos[entity][1], g_vPos[entity][2]);
							#endif
						}

						#if DEBUG_PRINT
						PrintToChatAll("\x04RandomDoors CLOSE %d", entity);
						PrintToServer("RandomDoors CLOSE %d", entity);
						#endif

						OpenOrClose(entity, DOOR_STATE_CLOSED);
					}
				}
				// Door is closed, open it
				else if( g_iCvarRandomT & 1 && GetEntProp(entity, Prop_Data, "m_eDoorState") == DOOR_STATE_CLOSED )
				{
					if( g_iState[entity] == 0 )
					{
						// Relative (double doors)
						target = g_iRelative[entity];
						if( target && (target = EntRefToEntIndex(target)) != INVALID_ENT_REFERENCE )
						{
							g_iState[target] = DOOR_STATE_OPENED + 1;

							// Save for VS
							if( g_iCurrentMode == 4 )
							{
								GetEntPropVector(target, Prop_Send, "m_vecOrigin", g_vPos[target]);

								#if DEBUG_PRINT
								PrintToChatAll("\x05VERSUS SAVE DOOR DBL OPEN (%d): %0.1f %0.1f %0.1f", target, g_vPos[target][0], g_vPos[target][1], g_vPos[target][2]);
								PrintToServer("\x05VERSUS SAVE DOOR DBL OPEN (%d): %0.1f %0.1f %0.1f", target, g_vPos[target][0], g_vPos[target][1], g_vPos[target][2]);
								#endif
							}

							#if DEBUG_PRINT
							PrintToChatAll("\x04RandomDoors DBL OPEN %d", target);
							PrintToServer("RandomDoors DBL OPEN %d", target);
							#endif

							OpenOrClose(target, DOOR_STATE_OPENED);
						}

						// Door set
						g_iState[entity] = DOOR_STATE_OPENED + 1;

						// Save for VS
						if( g_iCurrentMode == 4 )
						{
							g_vPos[entity] = vPos;

							#if DEBUG_PRINT
							PrintToChatAll("\x05VERSUS SAVE DOOR OPEN (%d): %0.1f %0.1f %0.1f", entity, g_vPos[entity][0], g_vPos[entity][1], g_vPos[entity][2]);
							PrintToServer("\x05VERSUS SAVE DOOR OPEN (%d): %0.1f %0.1f %0.1f", entity, g_vPos[entity][0], g_vPos[entity][1], g_vPos[entity][2]);
							#endif
						}

						#if DEBUG_PRINT
						PrintToChatAll("\x04RandomDoors OPEN %d", entity);
						PrintToServer("RandomDoors OPEN %d", entity);
						#endif

						OpenOrClose(entity, DOOR_STATE_OPENED);
					}
				}
			}
		}
		else
		{
			#if DEBUG_PRINT
			PrintToChatAll("\x04IGNORING FLAGS DOOR: %d (%d %d)", entity, GetEntProp(entity, Prop_Send, "m_spawnflags"), GetEntProp(entity, Prop_Data, "m_spawnflags"));
			PrintToServer("IGNORING FLAGS DOOR: %d (%d %d)", entity, GetEntProp(entity, Prop_Send, "m_spawnflags"), GetEntProp(entity, Prop_Data, "m_spawnflags"));
			#endif
		}
	}
}

void OpenOrClose(int entity, int state)
{
	static int director = -1;
	static char sTarget[128];

	if( state == DOOR_STATE_CLOSED )
	{
		#if DEBUG_PRINT
		PrintToChatAll("OpenOrClose: CLOSE: %d", entity);
		PrintToServer("OpenOrClose: CLOSE: %d", entity);
		#endif

		AcceptEntityInput(entity, "Close");
	} else {
		#if DEBUG_PRINT
		PrintToChatAll("OpenOrClose: OPEN: %d", entity);
		PrintToServer("OpenOrClose: OPEN: %d", entity);
		#endif

		// Open away from (to make double doors open in the same direction)
		if( director == -1 || EntRefToEntIndex(director) == INVALID_ENT_REFERENCE )
		{
			director = FindEntityByClassname(-1, "info_director");
			if( director != -1 )
			{
				director = EntIndexToEntRef(director);
			}
		}

		sTarget[0] = 0; // Reset string

		if( director != -1 )
		{
			GetEntPropString(director, Prop_Data, "m_iName", sTarget, sizeof(sTarget));
		}

		if( sTarget[0] == 0 )
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sTarget, sizeof(sTarget));
		}

		if( sTarget[0] != 0 )
		{
			SetVariantString(sTarget);
			AcceptEntityInput(entity, "OpenAwayFrom"); // Support for double doors and doors opening in the correct direction
		} else {
			AcceptEntityInput(entity, "Open");
		}
	}
}



// ====================================================================================================
//					DOOR HEALTH
// ====================================================================================================
void SetDoorHealth(int entity, bool spawned = false)
{
	if( spawned )
	{
		int health = g_iCvarHealthT ? g_iCvarHealthT : GetEntProp(entity, Prop_Data, "m_iHealth");
		if( health )
		{
			int state = GetEntProp(entity, Prop_Data, "m_eDoorState");

			if( (state == DOOR_STATE_CLOSED || state == DOOR_STATE_CLOSING_IN_PROGRESS) && g_fCvarHealthS )				SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthS)); // Closed
			else if( (state == DOOR_STATE_OPENED || state == DOOR_STATE_OPENING_IN_PROGRESS) && g_fCvarHealthO )		SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthO)); // Opened

			#if DEBUG_PRINT
			PrintToChatAll(">> SetDoorHealth SPAWNED: (%d) (%d) %s %d > %d", entity, state, (state == DOOR_STATE_CLOSED || state == DOOR_STATE_CLOSING_IN_PROGRESS) ? "CLOSED" : "OPENED", health, GetEntProp(entity, Prop_Data, "m_iHealth"));
			PrintToServer("SetDoorHealth SPAWNED: (%d) (%d) %s %d > %d", entity, state, (state == DOOR_STATE_CLOSED || state == DOOR_STATE_CLOSING_IN_PROGRESS) ? "CLOSED" : "OPENED", health, GetEntProp(entity, Prop_Data, "m_iHealth"));
			#endif

			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	else if( g_fCvarHealthO || g_fCvarHealthS )
	{
		int health = GetEntProp(entity, Prop_Data, "m_iHealth");
		if( health )
		{
			int state = GetEntProp(entity, Prop_Data, "m_eDoorState");

			if( (state == DOOR_STATE_CLOSED || state == DOOR_STATE_CLOSING_IN_PROGRESS) && g_fCvarHealthS )				SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthS / (g_fCvarHealthO ? g_fCvarHealthO : 1.0))); // Closed
			else if( (state == DOOR_STATE_OPENED || state == DOOR_STATE_OPENING_IN_PROGRESS) && g_fCvarHealthO )		SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthO / (g_fCvarHealthS ? g_fCvarHealthS : 1.0))); // Opened

			#if DEBUG_PRINT
			PrintToChatAll(">> SetDoorHealth MOVED (%d) %s (%d) %d > %d", state, (state == DOOR_STATE_CLOSED || state == DOOR_STATE_CLOSING_IN_PROGRESS) ? "CLOSED" : "OPENED", entity, health, GetEntProp(entity, Prop_Data, "m_iHealth"));
			PrintToServer("SetDoorHealth MOVED (%d) %s (%d) %d > %d", state, (state == DOOR_STATE_CLOSED || state == DOOR_STATE_CLOSING_IN_PROGRESS) ? "CLOSED" : "OPENED", entity, health, GetEntProp(entity, Prop_Data, "m_iHealth"));
			#endif

			BlockDoorUse(entity);
		}
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	#if DEBUG_PRINT
	PrintToChatAll("OnTakeDamage (%d) HEALTH %d DMG %f", victim, GetEntProp(victim, Prop_Data, "m_iHealth"), damage);
	PrintToServer("OnTakeDamage (%d) HEALTH %d DMG %f", victim, GetEntProp(victim, Prop_Data, "m_iHealth"), damage);
	#endif

	if( damagetype == DMG_CLUB )
	{
		int type;

		if( attacker > MaxClients )
		{
			type = TYPE_COMMON;
		}
		else if( attacker <= MaxClients && inflictor <= MaxClients ) // inflictor can be melee weapon which is also DMG_CLUB
		{
			if( GetClientTeam(attacker) == 3 )
			{
				int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
				if( class == g_iClassTank )
					type = TYPE_TANK;
				else
					type = TYPE_INFECTED;
			}
			else
			{
				type = TYPE_SURVIVOR;
			}
		}

		switch( type )
		{
			case TYPE_COMMON:		if( !g_iCvarDamageC ) type = 0;
			case TYPE_INFECTED:		if( !g_iCvarDamageI ) type = 0;
			case TYPE_SURVIVOR:		if( !g_iCvarDamageS ) type = 0;
			case TYPE_TANK:			if( !g_iCvarDamageT ) type = 0;
		}

		if( type )
		{
			int health = GetEntProp(victim, Prop_Data, "m_iHealth");

			// Must set health on frame, after 1 hit the game sets the doors health to 0
			DataPack dPack = new DataPack();
			dPack.WriteCell(EntIndexToEntRef(victim));
			dPack.WriteCell(health);
			dPack.WriteCell(type);
			RequestFrame(OnFrameHealth, dPack);
		}
	}
	else if( !g_bCvarInvin )
	{
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");

		if( health - damage > 0 )
			SetEntProp(victim, Prop_Data, "m_iHealth", RoundFloat(health - damage));
		else
			SetEntProp(victim, Prop_Data, "m_iHealth", 0);
	}

	return Plugin_Continue;
}

void OnFrameHealth(DataPack dPack)
{
	dPack.Reset();

	int entity = dPack.ReadCell();
	int health = dPack.ReadCell();
	int type = dPack.ReadCell();
	delete dPack;

	if( EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
	{
		switch( type )
		{
			case TYPE_COMMON:		health = health - g_iCvarDamageC;
			case TYPE_INFECTED:		health = health - g_iCvarDamageI;
			case TYPE_SURVIVOR:		health = health - g_iCvarDamageS;
			case TYPE_TANK:			health = health - g_iCvarDamageT;
		}

		#if DEBUG_PRINT
		PrintToChatAll("(%d) SHOVE HEALTH %d SET %d", EntRefToEntIndex(entity), GetEntProp(entity, Prop_Data, "m_iHealth"), health);
		PrintToServer("(%d) SHOVE HEALTH %d SET %d", EntRefToEntIndex(entity), GetEntProp(entity, Prop_Data, "m_iHealth"), health);
		#endif

		if( health > 0 )
			SetEntProp(entity, Prop_Data, "m_iHealth", health);
		else
			SetEntProp(entity, Prop_Data, "m_iHealth", 0);
	}
}

void Door_Moved(const char[] output, int caller, int activator, float delay)
{
	SetDoorHealth(caller);
}



// ====================================================================================================
//					TEMP BLOCK DOOR USE
// ====================================================================================================
// Prevent open/close spam which could cause health changing bugs
void BlockDoorUse(int entity)
{
	if( g_iFlags[entity] == -1 )
	{
		g_iFlags[entity] = GetEntProp(entity, Prop_Send, "m_spawnflags");

		SetEntProp(entity, Prop_Send, "m_spawnflags", DOOR_FLAG_IGNORE_USE); // Prevent +USE
		CreateTimer(0.2, TimerDoorSet, EntIndexToEntRef(entity));
	}
}

Action TimerDoorSet(Handle timer, any entity)
{
	entity = EntRefToEntIndex(entity);
	if( entity != INVALID_ENT_REFERENCE )
	{
		SetEntProp(entity, Prop_Send, "m_spawnflags", g_iFlags[entity]);
		g_iFlags[entity] = -1;
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					KEYBINDS
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow && g_iCvarKeys && buttons & IN_USE && g_iBlockedMap != BLOCK_PLUGIN && GetGameTime() > g_fLastUse[client] )
	{
		if( GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			int entity = GetClientAimTarget(client, false);
			if( entity > MaxClients && g_iDoors[entity] == EntIndexToEntRef(entity) )
			{
				// Door not rotating
				if( GetEntProp(entity, Prop_Data, "m_eDoorState") == DOOR_STATE_CLOSED )
				{
					// Range text
					if( g_fCvarRange )
					{
						float vPos[3], vEnd[3];
						GetClientAbsOrigin(client, vPos);
						GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vEnd);
						if( GetVectorDistance(vPos, vEnd) > g_fCvarRange ) return Plugin_Continue;
					}

					// Door locked
					if( GetEntProp(entity, Prop_Data, "m_bLocked") )
					{
						// Attempting to lock/unlock
						if( ((g_iCvarKeys == 1 && buttons & IN_SPEED) || (g_iCvarKeys == 2 && buttons & IN_DUCK)) )
						{
							// Relative (double doors)
							int target = g_iRelative[entity];
							if( target && (target = EntRefToEntIndex(target)) != INVALID_ENT_REFERENCE )
							{
								// Action
								AcceptEntityInput(target, "InputUnlock");
								SetEntProp(target, Prop_Data, "m_bLocked", 0);
								ChangeEdictState(target, 0);

								// Health
								int health = GetEntProp(target, Prop_Data, "m_iHealth");
								SetEntProp(target, Prop_Data, "m_iHealth", RoundFloat(health / g_fCvarHealthL)); // Divide by locked health

								#if DEBUG_PRINT
								PrintToChatAll("UNLOCK RELATIVE (%d) %d > %d", target, health, GetEntProp(target, Prop_Data, "m_iHealth"));
								PrintToServer("UNLOCK RELATIVE (%d) %d > %d", target, health, GetEntProp(target, Prop_Data, "m_iHealth"));
								#endif

								// Prevent opening
								BlockDoorUse(target);
							}

							// Action
							AcceptEntityInput(entity, "InputUnlock");
							SetEntProp(entity, Prop_Data, "m_bLocked", 0);
							ChangeEdictState(entity, 0);

							// Health
							int health = GetEntProp(entity, Prop_Data, "m_iHealth");
							SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health / g_fCvarHealthL)); // Divide by locked health

							#if DEBUG_PRINT
							PrintToChatAll("UNLOCK (%d) %d > %d", entity, health, GetEntProp(entity, Prop_Data, "m_iHealth"));
							PrintToServer("UNLOCK (%d) %d > %d", entity, health, GetEntProp(entity, Prop_Data, "m_iHealth"));
							#endif

							// Prevent opening
							BlockDoorUse(entity);

							// Text
							if( g_iCvarText & 2 )
							{
								if( g_fLastPrint != GetGameTime() )
								{
									g_fLastPrint = GetGameTime();
									if( g_iCvarText & 4 )			PrintToChatAll("\x04%N \x01unlocked a door", client);
									else if( g_iCvarText & 8 )		PrintToChat(client, "\x04%N \x01unlocked a door", client);
								}
							}

							// Sound
							PlaySound(entity, 2);

						// Pressing use, attempting to open a locked door
						} else {
							PlaySound(entity, 3);

							g_fLastUse[client] = GetGameTime() + 0.3;

							static char model[64];
							GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

							// These doors have no animation
							if(	strcmp(model, "models/props_downtown/metal_door_112.mdl") &&
								strncmp(model, "models/props_doors/shack", 24) &&
								strcmp(model, "models/props_downtown/door_interior_112_01.mdl")
							)
							{
								SetVariantString("KnobTurnFail");
								AcceptEntityInput(entity, "SetAnimation");
							}

							return Plugin_Continue;
						}
					}
					// Not locked
					else
					{
						if( ((g_iCvarKeys == 1 && buttons & IN_SPEED) || (g_iCvarKeys == 2 && buttons & IN_DUCK)) && !IsFakeClient(client) )
						{
							bool closed = true;

							// Relative (double doors)
							int target = g_iRelative[entity];
							if( target && (target = EntRefToEntIndex(target)) != INVALID_ENT_REFERENCE )
							{
								closed = GetEntProp(target, Prop_Data, "m_eDoorState") == DOOR_STATE_CLOSED;

								if( closed )
								{
									// Action
									AcceptEntityInput(target, "InputLock");
									SetEntProp(target, Prop_Data, "m_bLocked", 1);
									ChangeEdictState(target, 0);

									// Health
									int health = GetEntProp(target, Prop_Data, "m_iHealth");
									SetEntProp(target, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthL));

									#if DEBUG_PRINT
									PrintToChatAll("LOCK RELATIVE (%d) %d > %d", target, health, GetEntProp(target, Prop_Data, "m_iHealth"));
									PrintToServer("LOCK RELATIVE (%d) %d > %d", target, health, GetEntProp(target, Prop_Data, "m_iHealth"));
									#endif

									// Prevent opening
									BlockDoorUse(target);
								}
							}

							if( closed ) // Relative door must be closed
							{
								// Action
								AcceptEntityInput(entity, "InputLock");
								SetEntProp(entity, Prop_Data, "m_bLocked", 1);
								ChangeEdictState(entity, 0);

								// Health
								int health = GetEntProp(entity, Prop_Data, "m_iHealth");
								SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthL));

								#if DEBUG_PRINT
								PrintToChatAll("LOCK (%d) %d > %d", entity, health, GetEntProp(entity, Prop_Data, "m_iHealth"));
								PrintToServer("LOCK (%d) %d > %d", entity, health, GetEntProp(entity, Prop_Data, "m_iHealth"));
								#endif

								// Prevent opening
								BlockDoorUse(entity);

								// Text
								if( g_iCvarText & 1 )
								{
									if( g_fLastPrint != GetGameTime() )
									{
										g_fLastPrint = GetGameTime();
										if( g_iCvarText & 4 )			PrintToChatAll("\x04%N \x01locked a door", client);
										else if( g_iCvarText & 8 )		PrintToChat(client, "\x04%N \x01locked a door", client);
									}
								}

								// Sound, vocalize
								if( g_iCvarVoca )
								{
									PlayVocalize(client);
								}

								PlaySound(entity, 1);
							}
						}
					}
				}
			}
		}

		g_fLastUse[client] = GetGameTime() + 0.3; // Avoid spamming resources
	}

	return Plugin_Continue;
}

void PlaySound(int entity, int type)
{
	EmitSoundToAll(type == 1 ? SOUND_LOCK : type == 2 ? SOUND_UNLOCK : SOUND_LOCKED, entity, SNDCHAN_AUTO, type == 1 ? SNDLEVEL_AIRCRAFT : SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}



// ====================================================================================================
//					VOCALIZE SCENE
// ====================================================================================================
void PlayVocalize(int client)
{
	// Declare variables
	int surv, max;
	static char model[40];

	// Get survivor model
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));

	switch( model[29] )
	{
		case 'c': { model = "coach";		surv = 1; }
		case 'b': { model = "gambler";	surv = 2; }
		case 'h': { model = "mechanic";	surv = 3; }
		case 'd': { model = "producer";	surv = 4; }
		case 'v': { model = "NamVet";		surv = 5; }
		case 'e': { model = "Biker";		surv = 6; }
		case 'a': { model = "Manager";	surv = 7; }
		case 'n': { model = "TeenGirl";	surv = 8; }
		default:
		{
			int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");

			if( g_bLeft4Dead2 )
			{
				switch( character )
				{
					case 0:	{ model = "gambler";		surv = 2; } // Nick
					case 1:	{ model = "producer";		surv = 4; } // Rochelle
					case 2:	{ model = "coach";			surv = 1; } // Coach
					case 3:	{ model = "mechanic";		surv = 3; } // Ellis
					case 4:	{ model = "NamVet";			surv = 5; } // Bill
					case 5:	{ model = "TeenGirl";		surv = 8; } // Zoey
					case 6:	{ model = "Biker";			surv = 6; } // Francis
					case 7:	{ model = "Manager";		surv = 7; } // Louis
				}
			} else {
				switch( character )
				{
					case 0:	 { model = "TeenGirl";		surv = 8; } // Zoey
					case 1:	 { model = "NamVet";		surv = 5; } // Bill
					case 2:	 { model = "Biker";			surv = 6; } // Francis
					case 3:	 { model = "Manager";		surv = 7; } // Louis
				}
			}
		}
	}

	// Failed for some reason? Should never happen.
	if( surv == 0 )
		return;

	// Lock
	switch( surv )
	{
		case 1: max = sizeof(g_sCoach);		// Coach
		case 2: max = sizeof(g_sNick);		// Nick
		case 3: max = sizeof(g_sEllis);		// Ellis
		case 4: max = sizeof(g_sRochelle);	// Rochelle
		case 5: max = sizeof(g_sBill);		// Bill
		case 6: max = sizeof(g_sFrancis);	// Francis
		case 7: max = sizeof(g_sLouis);		// Louis
		case 8: max = sizeof(g_sZoey);		// Zoey
	}

	// Random number
	int random = GetRandomInt(0, max - 1);

	// Select random vocalize
	static char sTemp[40];
	switch( surv )
	{
		case 1: Format(sTemp, sizeof(sTemp), g_sCoach[random]);
		case 2: Format(sTemp, sizeof(sTemp), g_sNick[random]);
		case 3: Format(sTemp, sizeof(sTemp), g_sEllis[random]);
		case 4: Format(sTemp, sizeof(sTemp), g_sRochelle[random]);
		case 5: Format(sTemp, sizeof(sTemp), g_sBill[random]);
		case 6: Format(sTemp, sizeof(sTemp), g_sFrancis[random]);
		case 7: Format(sTemp, sizeof(sTemp), g_sLouis[random]);
		case 8: Format(sTemp, sizeof(sTemp), g_sZoey[random]);
	}

	// Create scene location and call
	Format(sTemp, sizeof(sTemp), "scenes/%s/%s.vcd", model, sTemp);
	VocalizeScene(client, sTemp);
}

// Taken from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// https://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
void VocalizeScene(int client, const char[] scenefile)
{
	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", scenefile);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}