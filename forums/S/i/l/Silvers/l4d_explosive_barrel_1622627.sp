/*
*	Explosive Barrel
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



#define PLUGIN_VERSION		"1.8"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Explosive Barrel
*	Author	:	SilverShot
*	Descrp	:	Auto-spawns Explosive Barrels
*	Link	:	https://forums.alliedmods.net/showthread.php?t=175164
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:
	
1.8 (15-Feb-2021) - by Marttt
	- Added precache for the "barrel_fly" particle to prevent lag on first spawn in some maps.

1.7 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.6 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.5.2 (03-Jul-2019)
	- Minor changes to code, has no affect and not required.

1.5.1 (21-Jul-2018)
	- Flipped lines to avoid potential crash, correct order: TeleportEntity then DispatchSpawn.

1.5 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_barrel_modes_tog" now supports L4D1.

1.4 (21-Jul-2013)
	- Removed Sort_Random work-around. This was fixed in SourceMod 1.4.7, all should update or spawning issues will occur.

1.3 (10-May-2012)
	- Added cvar "l4d_barrel_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_barrel_modes_tog" same as above, but only works for L4D2.
	- Saves barrel angle to the config for auto spawning.

1.2 (14-Jan-2012)
	- Increased the max number of Barrels to 48.

1.1 (14-Jan-2012)
	- Removed useless code.

1.0 (31-Dec-2011)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x05[Explosive Barrel] \x01"
#define CONFIG_SPAWNS		"data/l4d_barrel.cfg"
#define MAX_ALLOWED			48

#define MODEL_BARREL		"models/props_industrial/barrel_fuel.mdl"
#define MODEL_BARRELA		"models/props_industrial/barrel_fuel_parta.mdl"
#define MODEL_BARRELB		"models/props_industrial/barrel_fuel_partb.mdl"

#define PARTICLE_BARREL_FLY	"barrel_fly"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom;
int g_iCvarRandom, g_iEntities[MAX_ALLOWED], g_iPlayerSpawn, g_iRoundStart;
bool g_bCvarAllow, g_bMapStarted, g_bLoaded;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Explosive Barrel",
	author = "SilverShot",
	description = "Auto-Spawns Explosive Barrels.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=175164"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =	CreateConVar(		"l4d_barrel_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes = CreateConVar(		"l4d_barrel_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_barrel_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d_barrel_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =	CreateConVar(		"l4d_barrel_random",		"2",			"-1=All, 0=Off, other value randomly spawns that many from the config.", CVAR_FLAGS);
	CreateConVar(						"l4d_barrel_version",		PLUGIN_VERSION,	"Explosive Barrel plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_barrel");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_barrel",			CmdBarrel,			ADMFLAG_ROOT,	"Spawns a temporary Explosive Barrel at your crosshair.");
	RegAdminCmd("sm_barrelsave",		CmdBarrelSave,		ADMFLAG_ROOT, 	"Spawns a Explosive Barrel at your crosshair and saves to config.");
	RegAdminCmd("sm_barrellist",		CmdBarrelList,		ADMFLAG_ROOT, 	"Displays a list of Explosive Barrels spawned by the plugin and their locations.");
	RegAdminCmd("sm_barreldel",			CmdBarrelDelete,	ADMFLAG_ROOT, 	"Removes the Explosive Barrel you are nearest to and deletes from the config if saved.");
	RegAdminCmd("sm_barrelclear",		CmdBarrelClear,		ADMFLAG_ROOT, 	"Removes all Explosive Barrels from the current map.");
	RegAdminCmd("sm_barrelwipe",		CmdBarrelWipe,		ADMFLAG_ROOT, 	"Removes all Explosive Barrels from the current map and deletes them from the config.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheParticle(PARTICLE_BARREL_FLY);
	PrecacheModel(MODEL_BARREL, true);
	PrecacheModel(MODEL_BARRELA, true);
	PrecacheModel(MODEL_BARRELB, true);
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
		g_iEntities[i] = 0;
	}
}

void DeleteEntity(int index)
{
	int entity = g_iEntities[index];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");
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
	g_iCvarRandom =	g_hCvarRandom.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LoadBarrels();
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
	HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

void UnhookEvents()
{
	UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	ResetPlugin();
	LoadBarrels();
}

void LoadBarrels()
{
	if( g_bLoaded == true ) return;
	g_bLoaded = true;

	if( g_iCvarRandom == 0 )
		return;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("barrel");
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

	// Retrieve how many to create
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

	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		Format(sTemp, sizeof(sTemp), "origin_%d", index);
		hFile.GetVector(sTemp, vPos);
		Format(sTemp, sizeof(sTemp), "angles_%d", index);
		hFile.GetVector(sTemp, vAng);

		if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
			LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
		else
			SpawnBarrel(vPos, vAng);
	}

	delete hFile;
}

void SetupBarrel(int client, float vPos[3] = NULL_VECTOR)
{
	float vAng[3];
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vAng);

		float vDir[3];
		GetVectorAngles(vAng, vDir);
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] -= vDir[0] * 20.0;
		vPos[1] -= vDir[1] * 20.0;
		vPos[2] += 5.0;

		SpawnBarrel(vPos, vAng);
	}

	delete trace;
}

public bool TraceFilter(int entity, int contentsMask, any client)
{
	if( entity == client )
		return false;
	return true;
}

void SpawnBarrel(float vPos[3], float vAng[3])
{
	int index = -1;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef(g_iEntities[i]) )
		{
			index = i;
			break;
		}
	}

	if( index == -1 ) return;


	int entity = CreateEntityByName("prop_fuel_barrel");
	g_iEntities[index] = EntIndexToEntRef(entity);
	DispatchKeyValue(entity, "model", MODEL_BARREL);
	DispatchKeyValue(entity, "BasePiece", MODEL_BARRELB);
	DispatchKeyValue(entity, "FlyingPiece01", MODEL_BARRELA);
	DispatchKeyValue(entity, "FlyingParticles", "barrel_fly");
	DispatchKeyValue(entity, "DetonateParticles", "weapon_pipebomb");
	DispatchKeyValue(entity, "DetonateSound", "BaseGrenade.Explode");
	vAng[1] = GetRandomFloat(0.0, 360.0);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);
}



// ====================================================================================================
//					COMMANDS - TEMP, SAVE, LIST, DELETE, CLEAR, WIPE
// ====================================================================================================

// ====================================================================================================
//					sm_barrel
// ====================================================================================================
public Action CmdBarrel(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Explosive Barrel] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3];
	SetupBarrel(client, vPos);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_barrelsave
// ====================================================================================================
public Action CmdBarrelSave(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Explosive Barrel] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
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
	KeyValues hFile = new KeyValues("barrel");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Explosive Barrel config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Explosive Barrel spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_ALLOWED )
	{
		PrintToChat(client, "%sError: Cannot add anymore Explosive Barrels. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_ALLOWED);
		delete hFile;
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	SetupBarrel(client, vPos);

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);
	
	// Save angle / origin
	char sTemp[10];
	Format(sTemp, sizeof(sTemp), "origin_%d", iCount);
	hFile.SetVector(sTemp, vPos);
	Format(sTemp, sizeof(sTemp), "angles_%d", iCount);
	hFile.SetVector(sTemp, vAng);

	// Save cfg
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_barrellist
// ====================================================================================================
public Action CmdBarrelList(int client, int args)
{
	float vPos[3];
	int i, ent, count;

	for( i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iEntities[i];

		if( IsValidEntRef(ent) )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			if( client == 0 )
				ReplyToCommand(client, "[Explosive Barrel] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		PrintToChat(client, "[Explosive Barrel] Total: %d.", count);
	else
		ReplyToCommand(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_barreldel
// ====================================================================================================
public Action CmdBarrelDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Explosive Barrel] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int ent; int index = -1; float vDistance; float vDistanceLast = 250.0;
	float vEntPos[3], vPos[3], vPos2[3];
	GetClientAbsOrigin(client, vPos2);

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iEntities[i];
		if( IsValidEntRef(ent) )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
			vDistance = GetVectorDistance(vPos, vPos2);
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
		PrintToChat(client, "%sCannot find a Explosive Barrel nearby to delete!", CHAT_TAG);
		return Plugin_Handled;
	}

	DeleteEntity(index);

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot find the Explosive Barrel config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("barrel");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot load the Explosive Barrel config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sWarning: Current map not in the Explosive Barrel config.", CHAT_TAG);
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
	float vAng[3];

	// Move the other entries down
	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "origin_%d", i);
		hFile.GetVector(sTemp, vPos);

		if( !bMove )
		{
			if( GetVectorDistance(vPos, vEntPos) <= 5.0 )
			{
				bMove = true;
			}
			else if( i == iCount ) // None... exit
			{
				PrintToChat(client, "%sWarning: Cannot find the Explosive Barrel inside the config.", CHAT_TAG);
				delete hFile;
				return Plugin_Handled;
			}
		}
		else
		{
			// Delete above key
			hFile.DeleteKey(sTemp);

			// Save data to previous id
			Format(sTemp, sizeof(sTemp), "origin_%d", i-1);
			hFile.SetVector(sTemp, vPos);

			Format(sTemp, sizeof(sTemp), "angles_%d", i);
			hFile.GetVector(sTemp, vAng);
			Format(sTemp, sizeof(sTemp), "angles_%d", i-1);
			hFile.SetVector(sTemp, vAng);
		}
	}

	iCount--;
	hFile.SetNum("num", iCount);

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(\x05%d/%d\x01) - Explosive Barrel removed from config.", CHAT_TAG, iCount, MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_barrelclear
// ====================================================================================================
public Action CmdBarrelClear(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	ResetPlugin();
	PrintToChat(client, "%sAll Explosive Barrels removed from the map.", CHAT_TAG);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_barrelwipe
// ====================================================================================================
public Action CmdBarrelWipe(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Explosive Barrel] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Explosive Barrel config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("barrel");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Explosive Barrel config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Explosive Barrel config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	ResetPlugin();
	PrintToChat(client, "%s(0/%d) - All Explosive Barrels removed from config, add new with \x05sm_barrelsave\x01.", CHAT_TAG, MAX_ALLOWED);
	return Plugin_Handled;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

stock void PrecacheParticle(const char[] sEffectName)
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