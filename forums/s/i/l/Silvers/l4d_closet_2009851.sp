/*
*	Respawn Rescue Closet
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



#define PLUGIN_VERSION 		"1.11"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Respawn Rescue Closet
*	Author	:	SilverShot
*	Descrp	:	Creates a rescue closet to respawn dead players, these can be temporary or saved for auto-spawning.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=223138
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.11 (24-Dec-2022)
	- Fixed any potential invalid timer errors that were bound to happen with the previous version.

1.10 (24-Dec-2022)
	- Fixed the rescue models becoming non-solid when simply opening the door and not rescuing someone. Thanks to "replay_84" for reporting.
	- Using a backup event to set the respawn count, if the "survivor_rescued" event does not trigger.
	- Increased how far players must be from the rescue model to make it solid again.

1.9 (21-Dec-2022)
	- Closets will become non-solid when someone is rescued, until players are no longer nearby.
	- Doors will automatically close when a player is not nearby and the rescue entity will respawn if allowed.
	- Raised the rescue entity slightly to prevent players falling through the world. Thanks to "replay_84" for reporting.
	- Changed command "sm_closet_pos" to allow targeting any/invisible closets within 100 units distance. Requested by "replay_84".
	- Fixed command "sm_closet_list" not showing the correct type as relative to the "sm_closet" command.
	- Invisible types will delete the temporary model after 30 seconds.
	- Thanks to "replay_84" for lots of help testing.

1.8 (15-Jan-2022)
	- Fixed cvar "l4d_closet_respawn" not allowing a single closet to respawn multiple times. Thanks to "maclarens" for reporting.
	- This will close the doors and re-create the rescue entity after 9 seconds. Players may get stuck if they don't move out before.
	- Bots usually auto teleport if stuck.
	- Should be able to close the door manually to allow more rescues, up to the cvar limit.

1.7 (15-Feb-2021)
	- Fixed "Invalid game event handle". Thanks to "maclarens" for reporting.

1.6 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.5 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.4 (24-Nov-2019)
	- Fixes for the outhouse closet type:
	- Changed angles of players inside the box to face the correct way.
	- Changed origin of players spawning to prevent getting stuck inside the model.

1.3 (23-Oct-2019)
	- Added cvar "l4d_closet_force" to force allow respawning in closets on any map.
	- This cvar only works in L4D2. This should allow respawning on maps that disabled the possibility.

1.2 (03-Jun-2019)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Added support again for L4D1.
	- Added option to use Gun Cabinet model - Thanks to "Figa" for coding it in.
	- Added option to use invisible model - Thanks to "Shadowysn" for suggesting.
	- Changed cvar "l4d_closet_modes_tog" now supports L4D1.
	- Fixed PreCache errors - Thanks to "Accelerator74" for reporting.

1.1 (14-Jun-2015)
	- Changed to only support L4D2 because L4D does not have the rescue closet model.

1.0 (10-Aug-2013)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	https://forums.alliedmods.net/showthread.php?t=109659

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Rescue Closet\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_closet.cfg"

#define MAX_SPAWNS			32			// Maximum rescue closets allowed on the map
#define RANGE_SOLID			200.0		// Furthest range players must be for the model to become solid again

#define DOOR_MINS			-35.0		// m_vecMins (suggest not changing)
#define DOOR_MAXS			35.0		// m_vecMaxs (suggest not changing)

#define	MODEL_PROP			"models/props_urban/outhouse002.mdl"
#define	MODEL_DOOR			"models/props_urban/outhouse_door001.mdl"
#define	MODEL_DOORM			"models/props_unique/guncabinet01_main.mdl"
#define	MODEL_DOORL			"models/props_unique/guncabinet01_ldoor.mdl"
#define	MODEL_DOORR			"models/props_unique/guncabinet01_rdoor.mdl"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarForce, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom, g_hCvarRespawn;
int g_iCvarRandom, g_iCvarRespawn, g_iPlayerSpawn, g_iRoundStart, g_iSpawnCount, g_iSpawns[MAX_SPAWNS][7];
float g_fLastRescue[MAX_SPAWNS];
Handle g_hTimerReset[MAX_SPAWNS];
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2, g_bLoaded, g_bBlockOpen, g_bForceOpen, g_bCvarForce;
Menu g_hMenuPos;

enum
{
	INDEX_MODEL,
	INDEX_DOOR1,
	INDEX_DOOR2,
	INDEX_RESCUE,
	INDEX_INDEX,
	INDEX_TYPE,
	INDEX_COUNT
}

enum
{
	TYPE_TOILET,
	TYPE_CABINET,
	TYPE_INVISIBLE,
	TYPE_TEMP_MODEL
}

// Thanks to "Dragokas" (taken from Left4DHooks:
enum // m_eDoorState
{
	DOOR_STATE_CLOSED,
	DOOR_STATE_OPENING_IN_PROGRESS,
	DOOR_STATE_OPENED,
	DOOR_STATE_CLOSING_IN_PROGRESS
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Respawn Rescue Closet",
	author = "SilverShot, Figa",
	description = "Creates a rescue closet to respawn dead players, these can be temporary or saved for auto-spawning.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=223138"
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
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_closet_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarForce =	CreateConVar(	"l4d_closet_force",			"1",			"(L4D2 only). 0=Off. 1=Force allow players to respawn in closets on any map via VScript director settings.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_closet_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_closet_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_closet_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d_closet_random",		"-1",			"-1=All, 0=None. Otherwise randomly select this many Rescue Closets to spawn from the maps config.", CVAR_FLAGS );
	g_hCvarRespawn =	CreateConVar(	"l4d_closet_respawn",		"2",			"0=Infinite. Number of times to allow a closet to respawn players.", CVAR_FLAGS );
	CreateConVar(						"l4d_closet_version",		PLUGIN_VERSION, "Respawn Rescue Closet plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_closet");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	if( g_bLeft4Dead2 )
		g_hCvarForce.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRespawn.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_closet",			CmdSpawnerTemp,		ADMFLAG_ROOT, 	"Spawns a temporary Rescue Closet at your crosshair. <Model: 0=Toilet, 1=Gun Cabinet. 2=Invisible model.>");
	RegAdminCmd("sm_closet_save",		CmdSpawnerSave,		ADMFLAG_ROOT, 	"Spawns a Rescue Closet at your crosshair and saves to config. <Model: 0=Toilet, 1=Gun Cabinet. 2=Invisible model.>");
	RegAdminCmd("sm_closet_del",		CmdSpawnerDel,		ADMFLAG_ROOT, 	"Removes the Rescue Closet you are pointing at and deletes from the config if saved. Must be nearby to delete invisible closets.");
	RegAdminCmd("sm_closet_clear",		CmdSpawnerClear,	ADMFLAG_ROOT, 	"Removes all Rescue Closets spawned by this plugin from the current map.");
	RegAdminCmd("sm_closet_reload",		CmdSpawnerReload,	ADMFLAG_ROOT, 	"Removes all Rescue Closets and reloads the data config.");
	RegAdminCmd("sm_closet_wipe",		CmdSpawnerWipe,		ADMFLAG_ROOT, 	"Removes all Rescue Closets from the current map and deletes them from the config.");
	if( g_bLeft4Dead2 )
		RegAdminCmd("sm_closet_glow",	CmdSpawnerGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all Rescue Closets to see where they are placed. Does not edit invisible ones.");
	RegAdminCmd("sm_closet_list",		CmdSpawnerList,		ADMFLAG_ROOT, 	"Display a list Rescue Closet positions and the total number of.");
	RegAdminCmd("sm_closet_tele",		CmdSpawnerTele,		ADMFLAG_ROOT, 	"Teleport to a Rescue Closet (Usage: sm_closet_tele <index: 1 to MAX_SPAWNS (32)>).");
	RegAdminCmd("sm_closet_pos",		CmdSpawnerPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the Rescue Closet origin your crosshair is over. Does not edit invisible ones.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheModel(MODEL_DOORM);
	PrecacheModel(MODEL_DOORL);
	PrecacheModel(MODEL_DOORR);
	PrecacheModel(MODEL_DOOR);
	PrecacheModel(MODEL_PROP);
	PrecacheModel("models/props_urban/outhouse_door001_dm01_01.mdl");
	PrecacheModel("models/props_urban/outhouse_door001_dm02_01.mdl");
	PrecacheModel("models/props_urban/outhouse_door001_dm03_01.mdl");
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin(false);
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
	if( g_bLeft4Dead2 )
		g_bCvarForce = g_hCvarForce.BoolValue;
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_iCvarRespawn = g_hCvarRespawn.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		LoadSpawns();
		g_bCvarAllow = true;
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("survivor_rescued",	Event_PlayerRescue);
		HookEvent("award_earned",		Event_AwardEarned);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("survivor_rescued",	Event_PlayerRescue);
		UnhookEvent("award_earned",		Event_AwardEarned);
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
//					EVENTS - Spawn
// ====================================================================================================
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin(false);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

Action TimerStart(Handle timer)
{
	ResetPlugin();
	LoadSpawns();

	if( g_bCvarForce )
		DoVScript();

	return Plugin_Continue;
}

void DoVScript()
{
	int entity = CreateEntityByName("logic_script");
	DispatchSpawn(entity);

	// The \ at end of lines allows for multi-line strings in SourcePawn.
	// Probably requires challenge mode to be on.
	char sTemp[256];
	Format(sTemp, sizeof(sTemp), "DirectorOptions <-\
	{\
		cm_AllowSurvivorRescue = 1\
	}");

	SetVariantString(sTemp);
	AcceptEntityInput(entity, "RunScriptCode");
	RemoveEntity(entity);
}



// ====================================================================================================
//					LOAD SPAWNS
// ====================================================================================================
void LoadSpawns()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many Rescue Closets to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few Rescue Closets?
	int iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved Rescue Closets or create random
	int iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( int i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the Rescue Closet origins and spawn
	char sTemp[4];
	float vPos[3], vAng[3];
	int index, type;

	for( int i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetVector("ang", vAng);
			hFile.GetVector("pos", vPos);
			type = hFile.GetNum("type");

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index, type);
			hFile.GoBack();
		}
	}

	delete hFile;
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
void CreateSpawn(const float vOrigin[3], float vAngles[3], int index, int type)
{
	if( g_iSpawnCount >= MAX_SPAWNS )
		return;

	int iSpawnIndex = -1;
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][INDEX_RESCUE] == 0 )
		{
			iSpawnIndex = i;
			break;
		}
	}

	if( iSpawnIndex == -1 )
		return;

	int entity_door;
	int entity;

	if( type != TYPE_INVISIBLE )
	{
		entity = CreateEntityByName("prop_dynamic_override");

		DispatchKeyValue(entity, "solid", "6");
		if( type == TYPE_CABINET )
		{
			SetEntityModel(entity, MODEL_DOORM);
			vAngles[1] += 180.0;
		}
		else
			SetEntityModel(entity, MODEL_PROP);

		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		DispatchSpawn(entity);

		if( !g_bLeft4Dead2 )
		{
			// SetEntProp(entity, Prop_Send, "m_CollisionGroup", 6);
			SetEntProp(entity, Prop_Send, "m_usSolidFlags", 2048);
			SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
		}

		if( type == TYPE_TEMP_MODEL )
		{
			CreateTimer(30.0, TimerDelete, EntIndexToEntRef(entity));
		}

		if( type != TYPE_CABINET )
		{
			if( type != TYPE_TEMP_MODEL )
			{
				entity_door = CreateEntityByName("prop_door_rotating");
				DispatchKeyValue(entity_door, "solid", "6");
				DispatchKeyValue(entity_door, "disableshadows", "1");
				DispatchKeyValue(entity_door, "distance", "100");
				DispatchKeyValue(entity_door, "spawnpos", "0");
				DispatchKeyValue(entity_door, "opendir", "1");
				DispatchKeyValue(entity_door, "spawnflags", "8192");
				SetEntityModel(entity_door, MODEL_DOOR);
				TeleportEntity(entity_door, vOrigin, vAngles, NULL_VECTOR);
				DispatchSpawn(entity_door);
				SetVariantString("!activator");
				AcceptEntityInput(entity_door, "SetParent", entity);
				TeleportEntity(entity_door, view_as<float>({27.5, -17.0, 3.49}), NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(entity_door, "ClearParent", entity);
				HookSingleEntityOutput(entity_door, "OnOpen", OnOpen_Func, false);
			}
		}
		else
		{
			entity_door = CreateEntityByName("prop_door_rotating");
			DispatchKeyValue(entity_door, "solid", "6");
			DispatchKeyValue(entity_door, "disableshadows", "1");
			DispatchKeyValue(entity_door, "distance", "100");
			DispatchKeyValue(entity_door, "spawnpos", "0");
			DispatchKeyValue(entity_door, "opendir", "1");
			DispatchKeyValue(entity_door, "spawnflags", "8192");
			SetEntityModel(entity_door, MODEL_DOORL);
			TeleportEntity(entity_door, vOrigin, vAngles, NULL_VECTOR);
			DispatchSpawn(entity_door);
			SetVariantString("!activator");
			AcceptEntityInput(entity_door, "SetParent", entity);
			TeleportEntity(entity_door, view_as<float>({11.5, -23.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(entity_door, "ClearParent", entity);
			HookSingleEntityOutput(entity_door, "OnOpen", OnOpen_Func, false);

			int entity_door_2 = CreateEntityByName("prop_door_rotating");
			DispatchKeyValue(entity_door_2, "solid", "6");
			DispatchKeyValue(entity_door_2, "disableshadows", "1");
			DispatchKeyValue(entity_door_2, "distance", "100");
			DispatchKeyValue(entity_door_2, "spawnpos", "0");
			DispatchKeyValue(entity_door_2, "opendir", "1");
			DispatchKeyValue(entity_door_2, "spawnflags", "8192");
			SetEntityModel(entity_door_2, MODEL_DOORR);
			TeleportEntity(entity_door_2, vOrigin, vAngles, NULL_VECTOR);
			DispatchSpawn(entity_door_2);
			SetVariantString("!activator");
			AcceptEntityInput(entity_door_2, "SetParent", entity);
			TeleportEntity(entity_door_2, view_as<float>({11.5, 23.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(entity_door_2, "ClearParent", entity);
			HookSingleEntityOutput(entity_door_2, "OnOpen", OnOpen_Func, false);

			g_iSpawns[iSpawnIndex][INDEX_DOOR2] = EntIndexToEntRef(entity_door_2);
		}
	}



	// Rescue entity
	int entity_rescue = CreateEntityByName("info_survivor_rescue");

	DispatchKeyValue(entity_rescue, "solid", "0");
	DispatchKeyValue(entity_rescue, "model", "models/editor/playerstart.mdl");
	SetEntPropVector(entity_rescue, Prop_Send, "m_vecMins", view_as<float>({DOOR_MINS, DOOR_MINS, 0.0}));
	SetEntPropVector(entity_rescue, Prop_Send, "m_vecMaxs", view_as<float>({DOOR_MAXS, DOOR_MAXS, 25.0}));
	DispatchSpawn(entity_rescue);

	static float vPos[3];
	vPos = vOrigin;
	vPos[2] += 5.0;
	TeleportEntity(entity_rescue, vPos, vAngles, NULL_VECTOR);



	// Store data
	g_iSpawns[iSpawnIndex][INDEX_MODEL] = entity ? EntIndexToEntRef(entity) : 0;
	g_iSpawns[iSpawnIndex][INDEX_DOOR1] = entity_door ? EntIndexToEntRef(entity_door) : 0;
	g_iSpawns[iSpawnIndex][INDEX_RESCUE] = EntIndexToEntRef(entity_rescue);
	g_iSpawns[iSpawnIndex][INDEX_TYPE] = type;
	g_iSpawns[iSpawnIndex][INDEX_INDEX] = index;

	g_iSpawnCount++;
}

Action TimerDelete(Handle timer, int entity)
{
	if( IsValidEntRef(entity) )
	{
		RemoveEntity(entity);
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					EVENTS - SPAWN (non-guncabinet, for respawn count)
// ====================================================================================================
void Event_AwardEarned(Event event, const char[] name, bool dontBroadcast)
{
	// Detect rescue in case the "survivor_rescued" event does not fire
	if( event.GetInt("award") == 80 )
	{
		int client = event.GetInt("subjectentid"); // Match respawn closet to player being rescued

		if( client > 0 )
		{
			int entity;

			for( int index = 0; index < MAX_SPAWNS; index++ )
			{
				entity = g_iSpawns[index][INDEX_RESCUE];
				if( IsValidEntRef(entity) )
				{
					if( GetEntPropEnt(entity, Prop_Send, "m_survivor") == client )
					{
						if( GetGameTime() - g_fLastRescue[index] > 2.0 )
						{
							// Set last rescue time, used to make models non-solid when someone is rescued
							g_fLastRescue[index] = GetGameTime();
							RequestFrame(OnFrameDoorState, index);

							// Spawn count
							g_iSpawns[index][INDEX_COUNT]++;
						}

						break;
					}
				}
			}
		}
	}
}

void Event_PlayerRescue(Event event, const char[] name, bool dontBroadcast)
{
	// Strange this event is being returned as 0 sometimes... see post#40
	// Using this to set spawn count
	if( event && g_iCvarRespawn > 0 )
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));

		if( client && IsClientInGame(client) && GetClientTeam(client) == 2 )
		{
			int entity, index = -1;
			float vClient[3], vPos[3], distance = 100.0;
			GetClientAbsOrigin(client, vClient);

			for( int i = 0; i < MAX_SPAWNS; i++ )
			{
				entity = g_iSpawns[i][INDEX_RESCUE];
				if( IsValidEntRef(entity) )
				{
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
					if( GetVectorDistance(vPos, vClient) <= distance )
					{
						distance = GetVectorDistance(vPos, vClient);
						index = i;
					}
				}
			}

			if( index != -1 )
			{
				if( GetGameTime() - g_fLastRescue[index] > 2.0 )
				{
					// Set last rescue time, used to make models non-solid when someone is rescued
					g_fLastRescue[index] = GetGameTime();
					RequestFrame(OnFrameDoorState, index);

					// Spawn count
					g_iSpawns[index][INDEX_COUNT]++;
				}
			}
		}
	}
}

void OnFrameDoorState(int index)
{
	// Fix bug if auto-rescued and door hasn't opened
	int entity = g_iSpawns[index][INDEX_DOOR1];
	if( IsValidEntRef(entity) )
	{
		if( GetEntProp(entity, Prop_Send, "m_eDoorState") == DOOR_STATE_CLOSED )
		{
			g_bForceOpen = true;
			AcceptEntityInput(entity, "Open");
			g_bForceOpen = false;
		}
	}

	entity = g_iSpawns[index][INDEX_DOOR2];
	if( IsValidEntRef(entity) )
	{
		if( GetEntProp(entity, Prop_Send, "m_eDoorState") == DOOR_STATE_CLOSED )
		{
			g_bForceOpen = true;
			AcceptEntityInput(entity, "Open");
			g_bForceOpen = false;
		}
	}
}



// ====================================================================================================
//					OUTPUT - OPEN DOOR
// ====================================================================================================
void OnOpen_Func(const char[] output, int caller, int activator, float delay)
{
	if( g_bBlockOpen ) return;

	caller = EntIndexToEntRef(caller);

	// Find index from rescue door
	int index = -1;
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][INDEX_DOOR1] == caller || g_iSpawns[i][INDEX_DOOR2] == caller )
		{
			index = i;
			break;
		}
	}

	if( index != -1 )
	{
		int rescue = g_iSpawns[index][INDEX_RESCUE];
		if( IsValidEntRef(rescue) )
		{
			if( GetEntPropEnt(rescue, Prop_Send, "m_survivor") != -1 )
			{
				g_fLastRescue[index] = GetGameTime();
			}

			AcceptEntityInput(rescue, "Rescue");
		}

		// Set non-solid state on rescue only which is when g_fLastRescue < 2.0
		if( g_iSpawns[index][INDEX_DOOR1] == caller )
		{
			if( GetGameTime() - g_fLastRescue[index] < 2.0 )
			{
				if( !g_bForceOpen )
					SetEntProp(caller, Prop_Send, "m_eDoorState", DOOR_STATE_OPENING_IN_PROGRESS);

				SetEntProp(caller, Prop_Send, "m_CollisionGroup", 1);
			}

			HookSingleEntityOutput(caller, "OnFullyOpen", OnOpened_Func, true);
		}
		else
		{
			int entity = g_iSpawns[index][INDEX_DOOR1];
			if( IsValidEntRef(entity) )
			{
				g_bBlockOpen = true;
				AcceptEntityInput(entity, "Open");
				g_bBlockOpen = false;

				if( GetGameTime() - g_fLastRescue[index] < 2.0 )
				{
					if( !g_bForceOpen )
						SetEntProp(entity, Prop_Send, "m_eDoorState", DOOR_STATE_OPENING_IN_PROGRESS);

					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
				}
			}
		}

		if( g_iSpawns[index][INDEX_DOOR2] == caller )
		{
			if( GetGameTime() - g_fLastRescue[index] < 2.0 )
			{
				if( !g_bForceOpen )
					SetEntProp(caller, Prop_Send, "m_eDoorState", DOOR_STATE_OPENING_IN_PROGRESS);

				SetEntProp(caller, Prop_Send, "m_CollisionGroup", 1);
			}

			HookSingleEntityOutput(caller, "OnFullyOpen", OnOpened_Func, true);
		}
		else
		{
			int entity = g_iSpawns[index][INDEX_DOOR2];
			if( IsValidEntRef(entity) )
			{
				g_bBlockOpen = true;
				AcceptEntityInput(entity, "Open");
				g_bBlockOpen = false;

				if( GetGameTime() - g_fLastRescue[index] < 2.0 )
				{
					if( !g_bForceOpen )
						SetEntProp(entity, Prop_Send, "m_eDoorState", DOOR_STATE_OPENING_IN_PROGRESS);

					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
				}
			}
		}

		if( GetGameTime() - g_fLastRescue[index] < 2.0 )
		{
			int entity = g_iSpawns[index][INDEX_MODEL];
			if( IsValidEntRef(entity) )
			{
				SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
			}
		}
	}
}

void OnOpened_Func(const char[] output, int caller, int activator, float delay)
{
	caller = EntIndexToEntRef(caller);

	int index = -1;
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][INDEX_DOOR1] == caller || g_iSpawns[i][INDEX_DOOR2] == caller )
		{
			index = i;
			break;
		}
	}

	if( index != -1 )
	{
		// Prevent getting stuck
		if( g_iSpawns[index][INDEX_TYPE] != TYPE_INVISIBLE )
		{
			int entity;
			bool set;

			entity = g_iSpawns[index][INDEX_DOOR1];
			if( IsValidEntRef(entity) )
			{
				set = true;

				if( GetGameTime() - g_fLastRescue[index] < 2.0 )
				{
					SetEntProp(entity, Prop_Send, "m_eDoorState", DOOR_STATE_CLOSING_IN_PROGRESS);
					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
				}

				if( caller != entity )
				{
					UnhookSingleEntityOutput(entity, "OnFullyOpen", OnOpened_Func);
				}
			}

			entity = g_iSpawns[index][INDEX_DOOR2];
			if( IsValidEntRef(entity) )
			{
				set = true;

				if( GetGameTime() - g_fLastRescue[index] < 2.0 )
				{
					SetEntProp(entity, Prop_Send, "m_eDoorState", DOOR_STATE_CLOSING_IN_PROGRESS);
					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
				}

				if( caller != entity )
				{
					UnhookSingleEntityOutput(entity, "OnFullyOpen", OnOpened_Func);
				}
			}

			entity = g_iSpawns[index][INDEX_MODEL];
			if( IsValidEntRef(entity) )
			{
				if( GetGameTime() - g_fLastRescue[index] < 2.0 )
				{
					set = true;
					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
				}
			}

			if( set )
			{
				delete g_hTimerReset[index];
				g_hTimerReset[index] = CreateTimer(1.0, TimerSolidAdd, index, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			CreateTimer(5.0, TimerRespawnRescue, index);
		}
	}
}

Action TimerSolidAdd(Handle timer, int index)
{
	g_hTimerReset[index] = null;

	// Find index
	int entity = g_iSpawns[index][INDEX_MODEL];
	if( IsValidEntRef(entity) )
	{
		float vClient[3], vPos[3];

		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) )
			{
				GetClientAbsOrigin(i, vClient);
				if( GetVectorDistance(vPos, vClient) < RANGE_SOLID )
				{
					return Plugin_Continue;
				}
			}
		}
	}

	// Reset solid doors
	entity = g_iSpawns[index][INDEX_DOOR1];
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_eDoorState", DOOR_STATE_OPENED);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);

		// Respawn?
		if( !g_iCvarRespawn || g_iSpawns[index][INDEX_COUNT] < g_iCvarRespawn )
		{
			AcceptEntityInput(entity, "Close");
			HookSingleEntityOutput(entity, "OnFullyClosed", OnClosed_Func);
		}
	}

	entity = g_iSpawns[index][INDEX_DOOR2];
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_eDoorState", DOOR_STATE_OPENED);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);

		// Respawn?
		if( !g_iCvarRespawn || g_iSpawns[index][INDEX_COUNT] < g_iCvarRespawn )
		{
			AcceptEntityInput(entity, "Close");
			HookSingleEntityOutput(entity, "OnFullyClosed", OnClosed_Func);
		}
	}

	// Reset solid model
	entity = g_iSpawns[index][INDEX_MODEL];
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	}

	return Plugin_Stop;
}



// ====================================================================================================
//					RESPAWN CLOSET
// ====================================================================================================
void OnClosed_Func(const char[] output, int caller, int activator, float delay)
{
	caller = EntIndexToEntRef(caller);

	int index = -1;
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][INDEX_DOOR1] == caller || g_iSpawns[i][INDEX_DOOR2] == caller )
		{
			index = i;
			break;
		}
	}

	if( index != -1 )
	{
		bool pass;
		int door1 = g_iSpawns[index][INDEX_DOOR1];
		int door2 = g_iSpawns[index][INDEX_DOOR2];

		if( door1 == caller )
		{
			if( IsValidEntRef(door2) )
			{
				if( GetEntProp(door2, Prop_Send, "m_eDoorState") == DOOR_STATE_CLOSED )
				{
					pass = true;
					UnhookSingleEntityOutput(door2, "OnFullyClosed", OnClosed_Func);
				}
			}
			else
			{
				pass = true;
			}
		}
		else if( door2 == caller )
		{
			if( IsValidEntRef(door1) )
			{
				if( GetEntProp(door1, Prop_Send, "m_eDoorState") == DOOR_STATE_CLOSED )
				{
					pass = true;
					UnhookSingleEntityOutput(door1, "OnFullyClosed", OnClosed_Func);
				}
			}
			else
			{
				pass = true;
			}
		}

		if( pass )
		{
			UnhookSingleEntityOutput(caller, "OnFullyClosed", OnClosed_Func);
			CreateTimer(0.1, TimerRespawnRescue, index);
		}
	}
}

Action TimerRespawnRescue(Handle timer, int index)
{
	int rescue = g_iSpawns[index][INDEX_RESCUE];
	g_iSpawns[index][INDEX_RESCUE] = 0;

	// Respawn?
	if( !g_iCvarRespawn || g_iSpawns[index][INDEX_COUNT] < g_iCvarRespawn )
	{
		if( IsValidEntRef(rescue) )
		{
			float vPos[3], vAng[3];

			GetEntPropVector(rescue, Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(rescue, Prop_Data, "m_angRotation", vAng);

			int entity_rescue = CreateEntityByName("info_survivor_rescue");

			DispatchKeyValue(entity_rescue, "solid", "0");
			DispatchKeyValue(entity_rescue, "model", "models/editor/playerstart.mdl");
			SetEntPropVector(entity_rescue, Prop_Send, "m_vecMins", view_as<float>({DOOR_MINS, DOOR_MINS, 0.0}));
			SetEntPropVector(entity_rescue, Prop_Send, "m_vecMaxs", view_as<float>({DOOR_MAXS, DOOR_MAXS, 25.0}));
			DispatchSpawn(entity_rescue);

			TeleportEntity(entity_rescue, vPos, vAng, NULL_VECTOR);

			g_iSpawns[index][INDEX_RESCUE] = EntIndexToEntRef(entity_rescue);
		}
	}

	// Remove rescue entity
	if( IsValidEntRef(rescue) ) RemoveEntity(rescue);

	return Plugin_Continue;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_closet_reload
// ====================================================================================================
Action CmdSpawnerReload(int client, int args)
{
	g_bCvarAllow = false;
	ResetPlugin(true);
	IsAllowed();
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet
// ====================================================================================================
Action CmdSpawnerTemp(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Rescue Closets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}
	else if( args == 0 )
	{
		PrintToChat(client, "%sUsage: sm_closet <Model: 0=Toilet, 1=Gun Cabinet. L4D1 uses Gun Cabinet only. 2=Invisible model.>", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos) )
	{
		PrintToChat(client, "%sCannot place Rescue Closet, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}

	// Type of model
	char sBuff[3];
	int type;
	if( args == TYPE_CABINET )
	{
		GetCmdArg(1, sBuff, sizeof(sBuff));
		type = StringToInt(sBuff);
		if( type < TYPE_TOILET || type > TYPE_INVISIBLE ) type = 0;
	}

	if( type == TYPE_TOILET ) vAng[1] += 180.0;
	CreateSpawn(vPos, vAng, 0, type);

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_save
// ====================================================================================================
Action CmdSpawnerSave(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Rescue Closets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}
	else if( args == 0 )
	{
		PrintToChat(client, "%sUsage: sm_closet <Model: 0=Toilet, 1=Gun Cabinet. L4D1 uses Gun Cabinet only. 2=Invisible model.>", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}


	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Load config
	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Rescue Closet config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Rescue Closet spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many Rescue Closets are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Rescue Closets. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
		delete hFile;
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	char sTemp[4];
	IntToString(iCount, sTemp, sizeof(sTemp));

	if( hFile.JumpToKey(sTemp, true) )
	{
		// Set player position as Rescue Closet spawn location
		float vPos[3], vAng[3];
		if( !SetTeleportEndPoint(client, vPos) )
		{
			PrintToChat(client, "%sCannot place Rescue Closet, please try again.", CHAT_TAG);
			delete hFile;
			return Plugin_Handled;
		}

		// Type of model
		char sBuff[3];
		int type;
		if( args == TYPE_CABINET )
		{
			GetCmdArg(1, sBuff, sizeof(sBuff));
			type = StringToInt(sBuff);
			if( type < TYPE_TOILET || type > TYPE_INVISIBLE ) type = 0;
			hFile.SetNum("type", type);
		}

		// Save angle / origin
		if( type == TYPE_TOILET ) vAng[1] += 180.0;
		hFile.SetVector("ang", vAng);
		hFile.SetVector("pos", vPos);

		// Spawn
		if( type == TYPE_INVISIBLE ) type = TYPE_TEMP_MODEL; // So the model spawns to allow adjusting position. Reload to make invisible.
		CreateSpawn(vPos, vAng, iCount, type);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Rescue Closet.", CHAT_TAG, iCount, MAX_SPAWNS);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_del
// ====================================================================================================
Action CmdSpawnerDel(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Rescue Closet] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int index = -1;
	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		// Search by crosshair
		entity = EntIndexToEntRef(entity);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			if( g_iSpawns[i][INDEX_MODEL] == entity || g_iSpawns[i][INDEX_DOOR1] == entity )
			{
				index = i;
				break;
			}
		}
	}

	if( index == -1 )
	{
		// Search by distance
		float vClient[3], vPos[3], distance = 100.0;
		GetClientAbsOrigin(client, vClient);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][INDEX_RESCUE];
			if( IsValidEntRef(entity) )
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
				if( GetVectorDistance(vPos, vClient) <= distance )
				{
					distance = GetVectorDistance(vPos, vClient);
					index = i;
				}
			}
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sCannot find nearby or under crosshair.", CHAT_TAG);
		return Plugin_Handled;
	}

	int cfgindex = g_iSpawns[index][INDEX_INDEX];
	if( cfgindex == 0 )
	{
		RemoveSpawn(index);
		return Plugin_Handled;
	}

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][INDEX_INDEX] > cfgindex )
			g_iSpawns[i][INDEX_INDEX]--;
	}

	g_iSpawnCount--;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Rescue Closet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Rescue Closet config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many Rescue Closets
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[4];

	// Move the other entries down
	for( int i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			if( !bMove )
			{
				bMove = true;
				hFile.DeleteThis();
				RemoveSpawn(index);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				hFile.SetSectionName(sTemp);
			}
		}

		hFile.Rewind();
		hFile.JumpToKey(sMap);
	}

	if( bMove )
	{
		iCount--;
		hFile.SetNum("num", iCount);

		// Save to file
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Rescue Closet removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Rescue Closet from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_clear
// ====================================================================================================
Action CmdSpawnerClear(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Rescue Closets removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_wipe
// ====================================================================================================
Action CmdSpawnerWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Rescue Closet config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();
	ResetPlugin();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(0/%d) - All Rescue Closets removed from config, add with \x05sm_closet_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_glow
// ====================================================================================================
Action CmdSpawnerGlow(int client, int args)
{
	static bool glow;
	glow = !glow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, glow ? "on" : "off");

	ClosetGlow(glow);
	return Plugin_Handled;
}

void ClosetGlow(int glow)
{
	int ent;

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		ent = g_iSpawns[i][INDEX_MODEL];
		if( IsValidEntRef(ent) )
		{
			SetEntProp(ent, Prop_Send, "m_iGlowType", glow ? 3 : 0);
			if( glow )
			{
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 255);
				SetEntProp(ent, Prop_Send, "m_nGlowRange", glow ? 0 : 50);
			}
		}
	}
}

// ====================================================================================================
//					sm_closet_list
// ====================================================================================================
Action CmdSpawnerList(int client, int args)
{
	char sModel[64];
	float vPos[3];
	int count, type, ent;

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		type = -1;

		ent = g_iSpawns[i][INDEX_MODEL];
		if( IsValidEntRef(ent) )
		{
			type = TYPE_TOILET;

			GetEntPropString(ent, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			if( strcmp(sModel, MODEL_DOORM) == 0 )
				type = TYPE_CABINET;
		}
		else
		{
			ent = g_iSpawns[i][INDEX_RESCUE];
			if( IsValidEntRef(ent) )
				type = TYPE_INVISIBLE;
		}

		if( type != -1 )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%s%d) Type: %d. Pos: %f %f %f", CHAT_TAG, i+1, type, vPos[0], vPos[1], vPos[2]);
		}
	}
	PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_tele
// ====================================================================================================
Action CmdSpawnerTele(int client, int args)
{
	if( args == 1 )
	{
		char arg[16];
		GetCmdArg(1, arg, sizeof(arg));
		int index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_SPAWNS && IsValidEntRef(g_iSpawns[index][INDEX_RESCUE]) )
		{
			float vPos[3];
			GetEntPropVector(g_iSpawns[index][INDEX_RESCUE], Prop_Data, "m_vecOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_closet_tele <index 1-%d>.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
Action CmdSpawnerPos(int client, int args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

void ShowMenuPos(int client)
{
	CreateMenus();
	g_hMenuPos.Display(client, MENU_TIME_FOREVER);
}

int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 8 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}

	return 0;
}

void SetOrigin(int client, int menuindex)
{
	int index = -1;
	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		// Search by crosshair
		entity = EntIndexToEntRef(entity);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			if( g_iSpawns[i][INDEX_MODEL] == entity || g_iSpawns[i][INDEX_DOOR1] == entity )
			{
				index = i;
				break;
			}
		}
	}

	if( index == -1 )
	{
		// Search by distance
		float vClient[3], vPos[3], distance = 100.0;
		GetClientAbsOrigin(client, vClient);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][INDEX_RESCUE];
			if( IsValidEntRef(entity) )
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
				if( GetVectorDistance(vPos, vClient) <= distance )
				{
					distance = GetVectorDistance(vPos, vClient);
					index = i;
				}
			}
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sCannot find nearby or under crosshair.", CHAT_TAG);
		return;
	}

	float vAng[3], vPos[3];
	int entity_model = g_iSpawns[index][INDEX_MODEL];
	int entity_door = g_iSpawns[index][INDEX_DOOR1];

	// Parent doors to model
	if( IsValidEntRef(entity_model) )
	{
		entity = entity_model;

		if( IsValidEntRef(entity_door) )
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity_door, "SetParent", entity_model);
		}

		entity_door = g_iSpawns[index][INDEX_DOOR2];
		if( IsValidEntRef(entity_door) )
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity_door, "SetParent", entity_model);
		}
	}

	// Teleport
	if( menuindex == 6 || menuindex == 7 )
		GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
	else
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

	switch( menuindex )
	{
		case 0: vPos[0] += 0.5;
		case 1: vPos[1] += 0.5;
		case 2: vPos[2] += 0.5;
		case 3: vPos[0] -= 0.5;
		case 4: vPos[1] -= 0.5;
		case 5: vPos[2] -= 0.5;
		case 6: vAng[1] -= 90.0;
		case 7: vAng[1] += 90.0;
	}

	if( menuindex == 6 || menuindex == 7 )
	{
		TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
		PrintToChat(client, "%sNew angle: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
	} else {
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
	}

	// Clear parent
	entity_door = g_iSpawns[index][INDEX_DOOR1];
	if( IsValidEntRef(entity_door) )
	{
		AcceptEntityInput(entity_door, "ClearParent");
	}

	entity_door = g_iSpawns[index][INDEX_DOOR2];
	if( IsValidEntRef(entity_door) )
	{
		AcceptEntityInput(entity_door, "ClearParent");
	}
}

void SaveData(int client)
{
	int cfgindex;
	int index = -1;
	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		// Search by crosshair
		entity = EntIndexToEntRef(entity);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			if( g_iSpawns[i][INDEX_MODEL] == entity || g_iSpawns[i][INDEX_DOOR1] == entity || g_iSpawns[i][INDEX_DOOR2] == entity )
			{
				index = i;
				entity = g_iSpawns[i][INDEX_MODEL];
				cfgindex = g_iSpawns[i][INDEX_INDEX];
				break;
			}
		}
	}

	if( index == -1 )
	{
		// Search by distance
		float vClient[3], vPos[3], distance = 100.0;
		GetClientAbsOrigin(client, vClient);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][INDEX_RESCUE];
			if( IsValidEntRef(entity) )
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
				if( GetVectorDistance(vPos, vClient) <= distance )
				{
					cfgindex = g_iSpawns[i][INDEX_INDEX];
					distance = GetVectorDistance(vPos, vClient);
					index = i;
				}
			}
		}

		if( index != -1 )
		{
			if( IsValidEntRef(g_iSpawns[index][INDEX_MODEL]) )
			{
				entity = g_iSpawns[index][INDEX_MODEL];
			}
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sCannot find nearby or under crosshair.", CHAT_TAG);
		return;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Rescue Closet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Rescue Closet config.", CHAT_TAG);
		delete hFile;
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[4];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(cfgindex, sTemp, sizeof(sTemp));
	if( hFile.JumpToKey(sTemp) )
	{
		if( g_iSpawns[index][INDEX_TYPE] == TYPE_CABINET )
		{
			vAng[1] -= 180.0;
		}

		hFile.SetVector("ang", vAng);
		hFile.SetVector("pos", vPos);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s%d) Saved origin and angles to the data config", CHAT_TAG, cfgindex);
	}
}

void CreateMenus()
{
	if( g_hMenuPos == null )
	{
		g_hMenuPos = new Menu(PosMenuHandler);
		g_hMenuPos.AddItem("", "X + 0.5");
		g_hMenuPos.AddItem("", "Y + 0.5");
		g_hMenuPos.AddItem("", "Z + 0.5");
		g_hMenuPos.AddItem("", "X - 0.5");
		g_hMenuPos.AddItem("", "Y - 0.5");
		g_hMenuPos.AddItem("", "Z - 0.5");
		g_hMenuPos.AddItem("", "Rotate Left");
		g_hMenuPos.AddItem("", "Rotate Right");
		g_hMenuPos.AddItem("", "SAVE");
		g_hMenuPos.SetTitle("Set Position");
		g_hMenuPos.Pagination = MENU_NO_PAGINATION;
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void ResetPlugin(bool all = true)
{
	g_bBlockOpen = false;
	g_bForceOpen = false;
	g_bLoaded = false;
	g_iSpawnCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		g_fLastRescue[i] = 0.0;
		delete g_hTimerReset[i];

		if( all )
			RemoveSpawn(i);
	}
}

void RemoveSpawn(int index)
{
	int entity;

	entity = g_iSpawns[index][INDEX_MODEL];
	g_iSpawns[index][INDEX_MODEL] = 0;
	if( IsValidEntRef(entity) )	RemoveEntity(entity);

	entity = g_iSpawns[index][INDEX_DOOR1];
	g_iSpawns[index][INDEX_DOOR1] = 0;
	if( IsValidEntRef(entity) )	RemoveEntity(entity);

	entity = g_iSpawns[index][INDEX_DOOR2];
	g_iSpawns[index][INDEX_DOOR2] = 0;
	if( IsValidEntRef(entity) )	RemoveEntity(entity);

	entity = g_iSpawns[index][INDEX_RESCUE];
	g_iSpawns[index][INDEX_RESCUE] = 0;
	if( IsValidEntRef(entity) )	RemoveEntity(entity);

	g_iSpawns[index][INDEX_INDEX] = 0;
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
float GetGroundHeight(float vPos[3])
{
	float vAng[3];

	Handle trace = TR_TraceRayFilterEx(vPos, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_ALL, RayType_Infinite, _TraceFilter);
	if( TR_DidHit(trace) )
		TR_GetEndPosition(vAng, trace);

	delete trace;
	return vAng[2];
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
bool SetTeleportEndPoint(int client, float vPos[3])
{
	float vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		GetGroundHeight(vPos);
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}