/*
*	Mini Gun Flamethrowers
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



#define PLUGIN_VERSION		"1.6"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Mini Gun Flamethrowers
*	Author	:	SilverShot
*	Descrp	:	Save and auto-spawn the mini guns: .50 Calibre or L4D1 Mini Gun and makes them into Flamethrowers.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=222624
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.6 (01-Mar-2021)
	- Fixed "l4d_mini_gun_fire_friendly" value of "0" breaking damage to non-survivors. Thanks to "Xada" for reporting.

1.5 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.4 (15-May-2020)
	- Replaced "point_hurt" entity with "SDKHooks_TakeDamage" function.

1.3 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.2 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.1.2 (28-Jun-2019)
	- Changed PrecacheParticle method.

1.1.1 (05-Sep-2018)
	- Added cvar "l4d_mini_gun_fire_friendly" for damage against survivors.
	- Change cvar "l4d_mini_gun_fire_damage" to only affect non-survivors.

1.1 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_mini_gun_fire_modes_tog" now supports L4D1.
	- Fixed L4D1 to use both Machine and Mini Gun models.
	- Removed unused particle which showed a single error line in L4D1.

1.0 (05-Aug-2013)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified the SetTeleportEndPoint()
	https://forums.alliedmods.net/showthread.php?t=109659

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function to rotate ground flares
	https://forums.alliedmods.net/showthread.php?t=93716

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x05[Mini Gun Flamethrower] \x01"
#define CONFIG_SPAWNS		"data/l4d_mini_gun_flamethrower.cfg"
#define MAX_ALLOWED			32

#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"
#define MODEL_50CAL			"models/w_models/weapons/50cal.mdl"
#define MODEL_MINIGUN		"models/w_models/weapons/w_minigun.mdl"
#define PARTICLE_FIRE1		"fire_jet_01_flame"
#define PARTICLE_FIRE2		"fire_small_02"
#define PARTICLE_FIRE3		"weapon_molotov_thrown"
#define SOUND_FIRE_L4D1		"ambient/Spacial_Loops/CarFire_Loop.wav"
#define SOUND_FIRE_L4D2		"ambient/fire/interior_fire02_stereo.wav"


Handle g_hTimer;
ConVar g_hCvarAllow, g_hCvarChange, g_hCvarDamage, g_hCvarFreq, g_hCvarFiendly, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom, g_hCvarRange;
int g_iButtons[MAXPLAYERS+1], g_iCvarChange, g_iCvarDamage, g_iCvarFiendly, g_iCvarRandom, g_iIndex[MAXPLAYERS+1], g_iPlayerSpawn, g_iRoundStart, g_iSpawned[MAX_ALLOWED][4];
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2, g_bLoaded;
float g_fCvarFreq, g_fCvarRange;

enum
{
	INDEX_ENTITY,
	INDEX_EFFECTS,
	INDEX_PARTICLE,
	INDEX_TYPE
}

enum
{
	TYPE_PARTMAP,
	TYPE_SPAWNED
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Mini Gun Flamethrowers",
	author = "SilverShot",
	description = "Save and auto-spawn the mini guns: .50 Calibre or L4D1 Mini Gun and makes them into Flamethrowers.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=222624"
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
	g_hCvarAllow =			CreateConVar(	"l4d_mini_gun_fire_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes =			CreateConVar(	"l4d_mini_gun_fire_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_mini_gun_fire_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_mini_gun_fire_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarChange =			CreateConVar(	"l4d_mini_gun_fire_change",		"25",			"0=Off, The chance out of 100 to make pre-existing miniguns on the map into Flamethrowers.", CVAR_FLAGS);
	g_hCvarDamage =			CreateConVar(	"l4d_mini_gun_fire_damage",		"1",			"How much damage against non-survivors per touch when fired. Triggered according to frequency cvar.", CVAR_FLAGS);
	g_hCvarFreq =			CreateConVar(	"l4d_mini_gun_fire_frequency",	"0.1",			"How often the damage trace fires, igniting entities etc. In seconds (lower = faster/more hits).", CVAR_FLAGS);
	g_hCvarFiendly =		CreateConVar(	"l4d_mini_gun_fire_friendly",	"1",			"How much damage against survivors per touch when fired. Triggered according to frequency cvar.", CVAR_FLAGS);
	g_hCvarRandom =			CreateConVar(	"l4d_mini_gun_fire_random",		"-1",			"-1=All, 0=Off, other value randomly spawns that many from the config.", CVAR_FLAGS);
	g_hCvarRange =			CreateConVar(	"l4d_mini_gun_fire_range",		"250",			"How far the flamethrower can burn entities.", CVAR_FLAGS);
	CreateConVar(							"l4d_mini_gun_fire_version",	PLUGIN_VERSION, "Mini Gun plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_mini_gun_fire");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDamage.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFreq.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFiendly.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarChange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRange.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_mgfire",		CmdMachineGun,			ADMFLAG_ROOT,	"Spawns a temporary Mini Gun at your crosshair. Usage: sm_mgfire <0|1> (0=.50 Cal / 1=Minigun).");
	RegAdminCmd("sm_mgfire_save",	CmdMachineGunSave,		ADMFLAG_ROOT, 	"Spawns a Mini Gun at your crosshair and saves to config. Usage: sm_mgfire_save <0|1> (0=.50 Cal / 1=Minigun).");
	RegAdminCmd("sm_mgfire_list",	CmdMachineGunList,		ADMFLAG_ROOT, 	"Display a list Mini Gun positions and the total amount.");
	RegAdminCmd("sm_mgfire_del",	CmdMachineGunDelete,	ADMFLAG_ROOT, 	"Removes the Mini Gun you are nearest to and deletes from the config if saved.");
	RegAdminCmd("sm_mgfire_clear",	CmdMachineGunClear,		ADMFLAG_ROOT, 	"Removes all Mini Guns from the current map.");
	RegAdminCmd("sm_mgfire_wipe",	CmdMachineGunWipe,		ADMFLAG_ROOT, 	"Removes all Mini Guns from the current map and deletes them from the config.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel(MODEL_PROPANE, true);
	PrecacheModel(MODEL_50CAL, true);
	PrecacheModel(MODEL_MINIGUN, true);

	PrecacheParticle(PARTICLE_FIRE1);
	PrecacheParticle(PARTICLE_FIRE2);
	PrecacheParticle(PARTICLE_FIRE3);

	PrecacheSound(g_bLeft4Dead2 ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1, true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		DeleteEntity(i);
	}

	delete g_hTimer;

	for( int i = 1; i <= MaxClients; i++ )
	{
		SDKUnhook(i, SDKHook_PostThink, OnPreThink);
		g_iButtons[i] = 0;
		g_iIndex[i] = 0;
		if( IsClientInGame(i) )
			g_iButtons[i] = GetClientButtons(i);
	}
}

void DeleteEntity(int index)
{
	int owner;
	int entity = g_iSpawned[index][INDEX_ENTITY];
	int type = g_iSpawned[index][INDEX_TYPE];
	g_iSpawned[index][INDEX_ENTITY] = 0;
	g_iSpawned[index][INDEX_TYPE] = 0;

	if( IsValidEntRef(entity) )
	{
		DeleteEffects(index);

		owner = GetEntPropEnt(entity, Prop_Send, "m_owner");
		if( owner > -1 && owner <= MaxClients )
		{
			if( IsClientInGame(owner) )
			{
				SetEntPropEnt(owner, Prop_Send, "m_usingMountedWeapon", 0);
				SetEntPropEnt(owner, Prop_Send, "m_hUseEntity", -1);
			}
			SetEntPropEnt(entity, Prop_Send, "m_owner", -1);
		}
		if( type == TYPE_SPAWNED ) AcceptEntityInput(entity, "Kill");
		else SDKUnhook(EntRefToEntIndex(entity), SDKHook_UsePost, OnUse);
	}

	entity = g_iSpawned[index][INDEX_EFFECTS];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	entity = g_iSpawned[index][INDEX_PARTICLE];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	g_iSpawned[index][INDEX_EFFECTS] = 0;
	g_iSpawned[index][INDEX_PARTICLE] = 0;
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
	g_iCvarDamage =		g_hCvarDamage.IntValue;
	g_fCvarFreq =		g_hCvarFreq.FloatValue;
	g_iCvarFiendly =	g_hCvarFiendly.IntValue;
	g_iCvarChange =		g_hCvarChange.IntValue;
	g_iCvarRandom =		g_hCvarRandom.IntValue;
	g_fCvarRange =		g_hCvarRange.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
		UnhookEvents();
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
void HookEvents()
{
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

void UnhookEvents()
{
	UnhookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action TimerStart(Handle timer)
{
	ResetPlugin();
	if( g_bLoaded == true ) return;
	g_bLoaded = true;

	if( g_iCvarChange )
	{
		int count, entity = -1;
		int entities[MAX_ALLOWED];
		char sTargetname[16];

		while( count < MAX_ALLOWED && (entity = FindEntityByClassname(entity, "prop_minigun")) != INVALID_ENT_REFERENCE )
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

			if( strcmp(sTargetname, "louis_holdout") ) // Prevent taking over MG from Holdout plugin
			{
				entities[count] = entity;
				count++;
			}
		}
		while( count < MAX_ALLOWED && (entity = FindEntityByClassname(entity, "prop_minigun_l4d1")) != INVALID_ENT_REFERENCE )
		{
			entities[count] = entity;
			count++;
		}

		if( count )
		{
			SortIntegers(entities, count, Sort_Random);
			float vAng[3], vPos[3];

			for( int i = 1; i <= count; i++ )
			{
				if( GetRandomInt(1, 100) <= g_iCvarChange )
				{
					entity = entities[i-1];
					GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
					g_iSpawned[i][INDEX_TYPE] = TYPE_PARTMAP;
					SpawnEffects(i, entity, vAng, vPos);
				}
			}
		}
	}

	LoadGuns();
}

void LoadGuns()
{
	if( g_iCvarRandom == 0 )
		return;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("mg");
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

	// Retrieve how many to spawn
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few?
	int index, i, iRandom = g_iCvarRandom;
	int iIndexes[MAX_ALLOWED+1];
	if( iCount > MAX_ALLOWED )
		iCount = MAX_ALLOWED;

	// Spawn all saved or create random
	if( iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the origins and spawn
	char sTemp[10];
	float vPos[3], vAng[3];
	int type;

	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		Format(sTemp, sizeof(sTemp), "angle_%d", index);
		hFile.GetVector(sTemp, vAng);
		Format(sTemp, sizeof(sTemp), "origin_%d", index);
		hFile.GetVector(sTemp, vPos);
		Format(sTemp, sizeof(sTemp), "type_%d", index);
		type = hFile.GetNum(sTemp);

		if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
			LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
		else
			SpawnMG(vAng, vPos, type);
	}

	delete hFile;
}



// ====================================================================================================
//					COMMANDS - TEMP, SAVE, LIST, DELETE, CLEAR, WIPE
// ====================================================================================================

// ====================================================================================================
//					sm_mg
// ====================================================================================================
public Action CmdMachineGun(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Mini Gun] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int type;
	if( args == 1 )
	{
		char sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
	}

	float vAng[3], vPos[3];
	SetupMG(client, vAng, vPos, type);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_mgsave
// ====================================================================================================
public Action CmdMachineGunSave(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Mini Gun] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
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
	KeyValues hFile = new KeyValues("mg");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Mini Gun config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Mini Gun spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_ALLOWED )
	{
		PrintToChat(client, "%sError: Cannot add anymore machine guns. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_ALLOWED);
		delete hFile;
		return Plugin_Handled;
	}


	int type;
	if( args == 1 )
	{
		char sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
	}

	float vAng[3], vPos[3];
	SetupMG(client, vAng, vPos, type);

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	// Save angle / origin
	char sTemp[10];
	Format(sTemp, sizeof(sTemp), "angle_%d", iCount);
	hFile.SetVector(sTemp, vAng);
	Format(sTemp, sizeof(sTemp), "origin_%d", iCount);
	hFile.SetVector(sTemp, vPos);
	Format(sTemp, sizeof(sTemp), "type_%d", iCount);
	hFile.SetNum(sTemp, type);

	// Save cfg
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_mglist
// ====================================================================================================
public Action CmdMachineGunList(int client, int args)
{
	float vPos[3];
	int i, ent, count;

	if( client )
		PrintToChat(client, "%sAuto Spawned:", CHAT_TAG);
	else
		PrintToChat(client, "[Mini Gun] Auto Spawned:");

	for( i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iSpawned[i][INDEX_ENTITY];

		if( g_iSpawned[i][INDEX_TYPE] == TYPE_SPAWNED && IsValidEntRef(ent) )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client )
		PrintToChat(client, "%sPart of the map:", CHAT_TAG);
	else
		PrintToChat(client, "[Mini Gun] Part of the map:");

	for( i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iSpawned[i][INDEX_ENTITY];

		if( g_iSpawned[i][INDEX_TYPE] == TYPE_PARTMAP && IsValidEntRef(ent) )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client )
		PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	else
		PrintToChat(client, "[Mini Gun] Total: %d.", count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_mgdel
// ====================================================================================================
public Action CmdMachineGunDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Mini Gun] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int ent; int index = -1; float vDistance; float vDistanceLast = 250.0;
	float vEntPos[3], vPos[3], vAng[3];
	GetClientAbsOrigin(client, vAng);

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iSpawned[i][INDEX_ENTITY];
		if( g_iSpawned[i][INDEX_TYPE] == TYPE_SPAWNED && IsValidEntRef(ent) )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
			vDistance = GetVectorDistance(vPos, vAng);
			if( vDistance < vDistanceLast )
			{
				vDistanceLast = vDistance;
				vEntPos = vPos;
				index = i;
			}
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sCannot find a Mini Gun nearby to delete!", CHAT_TAG);
		return Plugin_Handled;
	}

	DeleteEntity(index);

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot find the Mini Gun config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("mg");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot load the Mini Gun config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sWarning: Current map not in the Mini Gun config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[10];

	// Move the other entries down
	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "origin_%d", i);
		hFile.GetVector(sTemp, vPos);

		if( !bMove )
		{
			if( GetVectorDistance(vPos, vEntPos) <= 1.0 )
			{
				hFile.DeleteKey(sTemp);
				Format(sTemp, sizeof(sTemp), "angle_%d", i);
				hFile.DeleteKey(sTemp);

				bMove = true;
			}
			else if( i == iCount ) // None... exit
			{
				PrintToChat(client, "%sWarning: Cannot find the Mini Gun inside the config.", CHAT_TAG);
				delete hFile;
				return Plugin_Handled;
			}
		}
		else
		{
			// Delete above key
			hFile.DeleteKey(sTemp);
			Format(sTemp, sizeof(sTemp), "angle_%d", i);
			hFile.GetVector(sTemp, vAng);
			hFile.DeleteKey(sTemp);

			// Save data to previous id
			Format(sTemp, sizeof(sTemp), "angle_%d", i-1);
			hFile.SetVector(sTemp, vAng);
			Format(sTemp, sizeof(sTemp), "origin_%d", i-1);
			hFile.SetVector(sTemp, vPos);
		}
	}

	iCount--;
	hFile.SetNum("num", iCount);

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(\x05%d/%d\x01) - Mini Gun removed from config.", CHAT_TAG, iCount, MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_mgclear
// ====================================================================================================
public Action CmdMachineGunClear(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	ResetPlugin();
	PrintToChat(client, "%sAll machine guns removed from the map.", CHAT_TAG);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_mgwipe
// ====================================================================================================
public Action CmdMachineGunWipe(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Mini Gun] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Mini Gun config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("mg");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Mini Gun config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Mini Gun config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	ResetPlugin();
	PrintToChat(client, "%s(0/%d) - All machine guns removed from config, add new with \x05sm_mgsave\x01.", CHAT_TAG, MAX_ALLOWED);
	return Plugin_Handled;
}

void SetupMG(int client, float vAng[3] = NULL_VECTOR, float vPos[3] = NULL_VECTOR, int type = 0)
{
	SetTeleportEndPoint(client, vPos, vAng);
	SpawnMG(vAng, vPos, type);
}

void SpawnMG(float vAng[3], float vPos[3], int type)
{
	int index = -1;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef(g_iSpawned[i][INDEX_ENTITY]) )
		{
			index = i;
			break;
		}
	}

	if( index == -1 ) return;


	int minigun;
	if( type == 0 )
	{
		if( g_bLeft4Dead2 )
			minigun = CreateEntityByName("prop_minigun");
		else
			minigun = CreateEntityByName("prop_mounted_machine_gun");
		SetEntityModel(minigun, MODEL_50CAL);
	}
	else
	{
		if( g_bLeft4Dead2 == false )
			minigun = CreateEntityByName ("prop_minigun");
		else
			minigun = CreateEntityByName ("prop_minigun_l4d1");
		SetEntityModel(minigun, MODEL_MINIGUN);
	}

	g_iSpawned[index][INDEX_TYPE] = TYPE_SPAWNED;
	SpawnEffects(index, minigun, vAng, vPos);
}

void SpawnEffects(int index, int minigun, float vAng[3], float vPos[3])
{
	g_iSpawned[index][INDEX_ENTITY] = EntIndexToEntRef(minigun);

	DispatchKeyValueFloat(minigun, "MaxPitch", 45.00);
	DispatchKeyValueFloat(minigun, "MinPitch", -45.00);
	DispatchKeyValueFloat(minigun, "MaxYaw", 90.00);
	TeleportEntity(minigun, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(minigun);

	SDKHook(minigun, SDKHook_UsePost, OnUse);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_FIRE3);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", minigun);
	SetVariantString("muzzle_flash");
	AcceptEntityInput(particle, "SetParentAttachment");
	g_iSpawned[index][INDEX_PARTICLE] = EntIndexToEntRef(particle);
}

public Action OnUse(int weapon, int client, int caller, UseType type, float value)
{
	if( type != Use_Toggle ) return;

	int index = -1;
	int entref = EntIndexToEntRef(weapon);
	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iSpawned[i][INDEX_ENTITY] == entref )
		{
			index = i;
			break;
		}
	}

	if( index == -1 ) return;

	g_iIndex[client] = index +1;
	g_iButtons[client] = 0;
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

void StopPreThink(int client, int index)
{
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	DeleteEffects(index);
	g_iIndex[client] = 0;
}

public void OnPreThink(int client)
{
	int entity;
	int index = g_iIndex[client];

	if( index == 0 )
	{
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		return;
	}

	index--;

	entity = g_iSpawned[index][INDEX_ENTITY];
	if( entity == 0 || EntRefToEntIndex(entity) != GetEntPropEnt(client, Prop_Send, "m_hUseEntity") )
	{
		StopPreThink(client, index);
		return;
	}

	int buttons = GetClientButtons(client);
	if( buttons & IN_ATTACK && !(g_iButtons[client] & IN_ATTACK) )
	{
		if( g_iSpawned[index][INDEX_EFFECTS] == 0 )
		{
			CreateEffects(index);
		}
	}
	else if( !(buttons & IN_ATTACK) && g_iButtons[client] & IN_ATTACK )
	{
		if( g_iSpawned[index][INDEX_EFFECTS] != 0 )
		{
			DeleteEffects(index);
		}
	}

	g_iButtons[client] = buttons;

	if( buttons & IN_ATTACK )
	{
		buttons &= ~IN_ATTACK;
		SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	}
}

void CreateEffects(int index)
{
	int minigun = g_iSpawned[index][INDEX_ENTITY];
	int particle = CreateEntityByName("info_particle_system");
	g_iSpawned[index][INDEX_EFFECTS] = EntIndexToEntRef(particle);
	DispatchKeyValue(particle, "effect_name", PARTICLE_FIRE1);
	AcceptEntityInput(particle, "start");
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", minigun);
	SetVariantString("muzzle_flash");
	AcceptEntityInput(particle, "SetParentAttachment");
	TeleportEntity(particle, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }), NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);

	EmitSoundToAll(g_bLeft4Dead2 ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1, particle, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	if( g_hTimer == null )
	{
		g_hTimer = CreateTimer(g_fCvarFreq, TimerTrace, _, TIMER_REPEAT);
	}
}

public Action TimerTrace(Handle timer)
{
	if( g_bCvarAllow == false )
	{
		g_hTimer = null;
		return Plugin_Stop;
	}

	static bool bHullTrace;
	int count, index, entity;
	Handle trace;
	float vPos[3], vAng[3], vEnd[3], vMins[3], vMaxs[3];

	bHullTrace = !bHullTrace;
	if( bHullTrace )
	{
		vMins = view_as<float>(  { -15.0, -15.0, -15.0 });
		vMaxs = view_as<float>(  { 15.0, 15.0, 15.0 });
	}

	for( int client = 1; client <= MaxClients; client++ )
	{
		index = g_iIndex[client];
		if( index )
		{
			index--;
			entity = g_iSpawned[index][INDEX_EFFECTS];
			if( IsValidEntRef(entity) )
			{
				count++;
				GetClientEyePosition(client, vPos);
				GetClientEyeAngles(client, vAng);

				if( bHullTrace )
				{
					GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
					MoveForward(vPos, vAng, vEnd, g_fCvarRange);

					trace = TR_TraceHullFilterEx(vPos, vEnd, vMins, vMaxs, MASK_SHOT, FilterExcludeSelf, client);
				}
				else
				{
					trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, FilterExcludeSelf, client);
				}

				if( TR_DidHit(trace) )
				{
					TR_GetEndPosition(vEnd, trace);

					if( GetVectorDistance(vPos, vEnd) <= g_fCvarRange )
					{
						int target = TR_GetEntityIndex(trace);
						if( target > 0 && target <= MaxClients )
						{
							HurtEntity(target, client, GetClientTeam(target) != 2 );
						}
						else
						{
							char classname[16];
							GetEdictClassname(target, classname, sizeof(classname));

							if( strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 || strcmp(classname, "prop_physics") == 0 )
							{
								HurtEntity(target, client, true);
							}
						}
					}
				}

				delete trace;
			}
		}
	}

	if( count == 0 )
	{
		g_hTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void HurtEntity(int target, int client, bool infected)
{
	if( infected && !g_iCvarDamage || !infected && !g_iCvarFiendly ) return;

	SDKHooks_TakeDamage(target, client, client, infected ? float(g_iCvarDamage) : float(g_iCvarFiendly), DMG_BURN);
}

void DeleteEffects(int index)
{
	int entity = g_iSpawned[index][INDEX_EFFECTS];
	g_iSpawned[index][INDEX_EFFECTS] = 0;

	if( IsValidEntRef(entity) )
	{
		StopSound(entity, SNDCHAN_AUTO, g_bLeft4Dead2 ? SOUND_FIRE_L4D2 : SOUND_FIRE_L4D1);
		AcceptEntityInput(entity, "Kill");
	}
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		float vNorm[3];
		float degrees = vAng[1];
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);
		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] = degrees;
		}
		else
		{
			if( degrees > vAng[1] )
				degrees = vAng[1] - degrees;
			else
				degrees = degrees - vAng[1];
			vAng[0] += 90.0;
			RotateYaw(vAng, degrees);
		}
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}



//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
void RotateYaw(float angles[3], float degree)
{
	float direction[3], normal[3];
	GetAngleVectors( angles, direction, NULL_VECTOR, normal );

	float sin = Sine( degree * 0.01745328 );	 // Pi/180
	float cos = Cosine( degree * 0.01745328 );
	float a = normal[0] * sin;
	float b = normal[1] * sin;
	float c = normal[2] * sin;
	float x = direction[2] * b + direction[0] * cos - direction[1] * c;
	float y = direction[0] * c + direction[1] * cos - direction[2] * a;
	float z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles( direction, angles );

	float up[3];
	GetVectorVectors( direction, NULL_VECTOR, up );

	float roll = GetAngleBetweenVectors( up, normal, direction );
	angles[2] += roll;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
float GetAngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3])
{
	float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
	NormalizeVector( direction, direction_n );
	NormalizeVector( vector1, vector1_n );
	NormalizeVector( vector2, vector2_n );
	float degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct( vector1_n, vector2_n, cross );

	if( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

public bool FilterExcludeSelf(int entity, int contentsMask, any client)
{
	if( entity == client )
		return false;
	else
	{
		int index = g_iIndex[client];
		if( index )
		{
			index--;
			entity = EntIndexToEntRef(entity);
			if( g_iSpawned[index][INDEX_ENTITY] == entity )
				return false;
		}
	}
	return true;
}