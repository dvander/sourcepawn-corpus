#define PLUGIN_VERSION 		"1.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Respawn Rescue Closet
*	Author	:	SilverShot
*	Descrp	:	Creates a rescue closet to respawn dead players, these can be temporary or saved for auto-spawning.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=223138

========================================================================================
	Change Log:

1.0 (10-Aug-2013)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	http://forums.alliedmods.net/showthread.php?t=109659

======================================================================================*/

#pragma semicolon 			1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Rescue Closet\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_closet.cfg"
#define MAX_SPAWNS			32
#define	MODEL_PROP			"models/props_unique/guncabinet01_main.mdl"
#define	MODEL_DOORL			"models/props_unique/guncabinet01_ldoor.mdl"
#define	MODEL_DOORR			"models/props_unique/guncabinet01_rdoor.mdl"

static	Handle:g_hCvarMPGameMode, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarAllow, Handle:g_hCvarRandom,
		Handle:g_hMenuPos, bool:g_bLoaded, bool:g_bCvarAllow, g_iCvarRandom, // bool:g_bLeft4Dead2, 
		g_iPlayerSpawn, g_iRoundStart, g_iSpawnCount, g_iSpawns[MAX_SPAWNS][5];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Respawn Rescue Closet",
	author = "SilverShot, Figa",
	description = "Creates a rescue closet to respawn dead players, these can be temporary or saved for auto-spawning.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=223138"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	// if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	// else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	// else
	if( strcmp(sGameName, "left4dead", false) && strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_closet_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_closet_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_closet_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_closet_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d_closet_random",		"-1",			"-1=All, 0=None. Otherwise randomly select this many Rescue Closets to spawn from the maps config.", CVAR_FLAGS );
	CreateConVar(						"l4d_closet_version",		PLUGIN_VERSION, "Respawn Rescue Closet plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_closet");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hCvarMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarRandom,			ConVarChanged_Cvars);

	RegAdminCmd("sm_closet_reload",		CmdSpawnerReload,	ADMFLAG_ROOT, 	"Removes all Rescue Closets and reloads the data config.");
	RegAdminCmd("sm_closet",			CmdSpawnerTemp,		ADMFLAG_ROOT, 	"Spawns a temporary Rescue Closet at your crosshair.");
	RegAdminCmd("sm_closet_save",		CmdSpawnerSave,		ADMFLAG_ROOT, 	"Spawns a Rescue Closet at your crosshair and saves to config.");
	RegAdminCmd("sm_closet_del",		CmdSpawnerDel,		ADMFLAG_ROOT, 	"Removes the Rescue Closet you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_closet_clear",		CmdSpawnerClear,	ADMFLAG_ROOT, 	"Removes all Rescue Closets spawned by this plugin from the current map.");
	RegAdminCmd("sm_closet_wipe",		CmdSpawnerWipe,		ADMFLAG_ROOT, 	"Removes all Rescue Closets from the current map and deletes them from the config.");
	RegAdminCmd("sm_closet_glow",		CmdSpawnerGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all Rescue Closets to see where they are placed.");
	RegAdminCmd("sm_closet_list",		CmdSpawnerList,		ADMFLAG_ROOT, 	"Display a list Rescue Closet positions and the total number of.");
	RegAdminCmd("sm_closet_tele",		CmdSpawnerTele,		ADMFLAG_ROOT, 	"Teleport to a Rescue Closet (Usage: sm_closet_tele <index: 1 to MAX_SPAWNS (32)>).");
	RegAdminCmd("sm_closet_pos",		CmdSpawnerPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the Rescue Closet origin your crosshair is over.");
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	PrecacheModel(MODEL_PROP);
	PrecacheModel(MODEL_DOORL);
	PrecacheModel(MODEL_DOORR);
}

public OnMapEnd()
{
	ResetPlugin(false);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	g_iCvarRandom = GetConVarInt(g_hCvarRandom);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		LoadSpawns();
		g_bCvarAllow = true;
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == INVALID_HANDLE )
		return false;

	new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		new entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hCvarMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
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
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetPlugin(false);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart);
	g_iRoundStart = 1;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart);
	g_iPlayerSpawn = 1;
}

public Action:tmrStart(Handle:timer)
{
	ResetPlugin();
	LoadSpawns();
}



// ====================================================================================================
//					LOAD SPAWNS
// ====================================================================================================
LoadSpawns()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many Rescue Closets to display
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few Rescue Closets?
	new iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved Rescue Closets or create random
	new iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( new i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the Rescue Closet origins and spawn
	decl String:sTemp[10], Float:vPos[3], Float:vAng[3];
	new index;

	for( new i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetVector(hFile, "ang", vAng);
			KvGetVector(hFile, "pos", vPos);

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index);
			KvGoBack(hFile);
		}
	}

	CloseHandle(hFile);
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
CreateSpawn(const Float:vOrigin[3], const Float:vAngles[3], index)
{
	if( g_iSpawnCount >= MAX_SPAWNS )
		return;

	new iSpawnIndex = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == 0 )
		{
			iSpawnIndex = i;
			break;
		}
	}

	if( iSpawnIndex == -1 )
		return;

	decl Float:vPos[3];
	new entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_PROP);
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	DispatchSpawn(entity);

	new entity_door = CreateEntityByName("prop_door_rotating");
	DispatchKeyValue(entity_door, "solid", "6");
	DispatchKeyValue(entity_door, "disableshadows", "1");
	DispatchKeyValue(entity_door, "distance", "100");
	DispatchKeyValue(entity_door, "spawnpos", "0");
	DispatchKeyValue(entity_door, "opendir", "1");
	DispatchKeyValue(entity_door, "spawnflags", "532480");
	SetEntityModel(entity_door, MODEL_DOORL);
	TeleportEntity(entity_door, vOrigin, vAngles, NULL_VECTOR);
	DispatchSpawn(entity_door);
	SetVariantString("!activator");
	AcceptEntityInput(entity_door, "SetParent", entity);
	TeleportEntity(entity_door, Float:{11.5, -23.0, 0.00}, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity_door, "ClearParent", entity);
	HookSingleEntityOutput(entity_door, "OnOpen", OnOpen_Func, true);
	
	new entity_door_2 = CreateEntityByName("prop_door_rotating");
	DispatchKeyValue(entity_door_2, "solid", "6");
	DispatchKeyValue(entity_door_2, "disableshadows", "1");
	DispatchKeyValue(entity_door_2, "distance", "100");
	DispatchKeyValue(entity_door_2, "spawnpos", "0");
	DispatchKeyValue(entity_door_2, "opendir", "1");
	DispatchKeyValue(entity_door_2, "spawnflags", "532580");
	SetEntityModel(entity_door_2, MODEL_DOORR);
	TeleportEntity(entity_door_2, vOrigin, vAngles, NULL_VECTOR);
	DispatchSpawn(entity_door_2);
	SetVariantString("!activator");
	AcceptEntityInput(entity_door_2, "SetParent", entity);
	TeleportEntity(entity_door_2, Float:{11.5, 23.0, 0.00}, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity_door_2, "ClearParent", entity);

	new entity_rescue = CreateEntityByName("info_survivor_rescue");
	DispatchKeyValue(entity_rescue, "solid", "0");
	DispatchKeyValue(entity_rescue, "model", "models/editor/playerstart.mdl");
	SetEntPropVector(entity_rescue, Prop_Send, "m_vecMins", Float:{-5.0, -5.0, -5.0});
	SetEntPropVector(entity_rescue, Prop_Send, "m_vecMaxs", Float:{-5.0, -5.0, 50.0});
	vPos[2] += 1.0;
	DispatchSpawn(entity_rescue);
	AcceptEntityInput(entity_rescue, "TurnOn");
	SetVariantString("!activator");
	AcceptEntityInput(entity_rescue, "SetParent", entity);
	TeleportEntity(entity_rescue, Float:{1.0, 0.0, 5.5}, vAngles, NULL_VECTOR);

	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(entity);
	g_iSpawns[iSpawnIndex][1] = EntIndexToEntRef(entity_door);
	g_iSpawns[iSpawnIndex][2] = EntIndexToEntRef(entity_door_2);
	g_iSpawns[iSpawnIndex][3] = EntIndexToEntRef(entity_rescue);
	g_iSpawns[iSpawnIndex][4] = index;

	g_iSpawnCount++;
}

public OnOpen_Func(const String:output[], caller, activator, Float:delay) 
{
	caller = EntIndexToEntRef(caller);
	new arrindex;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if(g_iSpawns[i][1] == caller)
		{
			arrindex = i;
			break;
		}
	}
	new entity = g_iSpawns[arrindex][0];
	if (IsValidEntRef(entity)) AcceptEntityInput(entity, "DisableCollision");
	
	entity = g_iSpawns[arrindex][1];
	if (IsValidEntRef(entity)) AcceptEntityInput(entity, "DisableCollision");
	
	entity = g_iSpawns[arrindex][2];
	if (IsValidEntRef(entity)) AcceptEntityInput(entity, "DisableCollision");
	
	entity = g_iSpawns[arrindex][3];
	if (IsValidEntRef(entity)) AcceptEntityInput(entity, "OnKilled");
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_closet_reload
// ====================================================================================================
public Action:CmdSpawnerReload(client, args)
{
	g_bCvarAllow = false;
	ResetPlugin(true);
	IsAllowed();
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet
// ====================================================================================================
public Action:CmdSpawnerTemp(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Rescue Closets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Rescue Closets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	new Float:vPos[3], Float:vAng[3];
	if( !SetTeleportEndPoint(client, vPos) )
	{
		PrintToChat(client, "%sCannot place Rescue Closet, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}

	CreateSpawn(vPos, vAng, 0);

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_save
// ====================================================================================================
public Action:CmdSpawnerSave(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Rescue Closets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}


	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		new Handle:hCfg = OpenFile(sPath, "w");
		WriteFileLine(hCfg, "");
		CloseHandle(hCfg);
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Rescue Closet config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);
	if( !KvJumpToKey(hFile, sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Rescue Closet spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many Rescue Closets are saved
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Rescue Closets. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	KvSetNum(hFile, "num", iCount);

	decl String:sTemp[10];

	IntToString(iCount, sTemp, sizeof(sTemp));

	if( KvJumpToKey(hFile, sTemp, true) )
	{
		new Float:vPos[3], Float:vAng[3];
		// Set player position as Rescue Closet spawn location
		if( !SetTeleportEndPoint(client, vPos) )
		{
			PrintToChat(client, "%sCannot place Rescue Closet, please try again.", CHAT_TAG);
			CloseHandle(hFile);
			return Plugin_Handled;
		}

		// Save angle / origin
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);

		CreateSpawn(vPos, vAng, iCount);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Rescue Closet.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_del
// ====================================================================================================
public Action:CmdSpawnerDel(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Rescue Closet] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	new index = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == entity || g_iSpawns[i][1] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	new cfgindex = g_iSpawns[index][4];
	if( cfgindex == 0 )
	{
		RemoveSpawn(index);
		return Plugin_Handled;
	}

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][4] > cfgindex )
			g_iSpawns[i][4]--;
	}

	g_iSpawnCount--;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Rescue Closet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Rescue Closet config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many Rescue Closets
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	new bool:bMove;
	decl String:sTemp[16];

	// Move the other entries down
	for( new i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			if( !bMove )
			{
				bMove = true;
				KvDeleteThis(hFile);
				RemoveSpawn(index);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				KvSetSectionName(hFile, sTemp);
			}
		}

		KvRewind(hFile);
		KvJumpToKey(hFile, sMap);
	}

	if( bMove )
	{
		iCount--;
		KvSetNum(hFile, "num", iCount);

		// Save to file
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Rescue Closet removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Rescue Closet from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_clear
// ====================================================================================================
public Action:CmdSpawnerClear(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Rescue Closets removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_wipe
// ====================================================================================================
public Action:CmdSpawnerWipe(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Rescue Closet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Rescue Closet config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	KvDeleteThis(hFile);
	ResetPlugin();

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(0/%d) - All Rescue Closets removed from config, add with \x05sm_closet_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_glow
// ====================================================================================================
public Action:CmdSpawnerGlow(client, args)
{
	static bool:glow;
	glow = !glow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, glow ? "on" : "off");

	VendorGlow(glow);
	return Plugin_Handled;
}

VendorGlow(glow)
{
	new ent;

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		ent = g_iSpawns[i][0];
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
public Action:CmdSpawnerList(client, args)
{
	decl Float:vPos[3];
	new count;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( IsValidEntRef(g_iSpawns[i][0]) )
		{
			count++;
			GetEntPropVector(g_iSpawns[i][0], Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}
	PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_closet_tele
// ====================================================================================================
public Action:CmdSpawnerTele(client, args)
{
	if( args == 1 )
	{
		decl String:arg[16];
		GetCmdArg(1, arg, 16);
		new index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_SPAWNS && IsValidEntRef(g_iSpawns[index][0]) )
		{
			decl Float:vPos[3];
			GetEntPropVector(g_iSpawns[index][0], Prop_Data, "m_vecOrigin", vPos);
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
public Action:CmdSpawnerPos(client, args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

ShowMenuPos(client)
{
	CreateMenus();
	DisplayMenu(g_hMenuPos, client, MENU_TIME_FOREVER);
}

public PosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( index == 8 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

SetOrigin(client, index)
{
	new entity = GetClientAimTarget(client, false);
	if( entity == -1 )
		return;

	entity = EntIndexToEntRef(entity);

	new arrindex;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == entity || g_iSpawns[i][1] == entity )
		{
			entity = g_iSpawns[i][0];
			arrindex = i;
			break;
		}
	}

	decl Float:vAng[3], Float:vPos[3];
	new entity_door = g_iSpawns[arrindex][1];
	entity_door = EntRefToEntIndex(entity_door);
	SetVariantString("!activator");
	AcceptEntityInput(entity_door, "SetParent", entity);

	if( index == 6 || index == 7 )
		GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
	else
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

	if( index == 0 ) vPos[0] += 0.5;
	else if( index == 1 ) vPos[1] += 0.5;
	else if( index == 2 ) vPos[2] += 0.5;
	else if( index == 3 ) vPos[0] -= 0.5;
	else if( index == 4 ) vPos[1] -= 0.5;
	else if( index == 5 ) vPos[2] -= 0.5;
	else if( index == 6 ) vAng[1] -= 90.0;
	else if( index == 7 ) vAng[1] += 90.0;

	if( index == 6 || index == 7 )
	{
		TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
		PrintToChat(client, "%sNew angle: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
	} else {
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
	}

	AcceptEntityInput(entity_door, "ClearParent");
}

SaveData(client)
{
	new entity;
	entity = GetClientAimTarget(client, false);
	if( entity == -1 )
		return;

	entity = EntIndexToEntRef(entity);

	new cfgindex, index = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == entity || g_iSpawns[i][1] == entity )
		{
			index = i;
			entity = g_iSpawns[i][0];
			cfgindex = g_iSpawns[i][4];
			break;
		}
	}

	if( index == -1 )
		return;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Rescue Closet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Rescue Closet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Rescue Closet config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	decl Float:vAng[3], Float:vPos[3], String:sTemp[32];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(cfgindex, sTemp, sizeof(sTemp));
	if( KvJumpToKey(hFile, sTemp) )
	{
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%sSaved origin and angles to the data config", CHAT_TAG);
	}
}

CreateMenus()
{
	if( g_hMenuPos == INVALID_HANDLE )
	{
		g_hMenuPos = CreateMenu(PosMenuHandler);
		AddMenuItem(g_hMenuPos, "", "X + 0.5");
		AddMenuItem(g_hMenuPos, "", "Y + 0.5");
		AddMenuItem(g_hMenuPos, "", "Z + 0.5");
		AddMenuItem(g_hMenuPos, "", "X - 0.5");
		AddMenuItem(g_hMenuPos, "", "Y - 0.5");
		AddMenuItem(g_hMenuPos, "", "Z - 0.5");
		AddMenuItem(g_hMenuPos, "", "Rotate Left");
		AddMenuItem(g_hMenuPos, "", "Rotate Right");
		AddMenuItem(g_hMenuPos, "", "SAVE");
		SetMenuTitle(g_hMenuPos, "Set Position");
		SetMenuPagination(g_hMenuPos, MENU_NO_PAGINATION);
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

ResetPlugin(bool:all = true)
{
	g_bLoaded = false;
	g_iSpawnCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	if( all )
		for( new i = 0; i < MAX_SPAWNS; i++ )
			RemoveSpawn(i);
}

RemoveSpawn(index)
{
	new entity;

	entity = g_iSpawns[index][0];
	g_iSpawns[index][0] = 0;
	if( IsValidEntRef(entity) )	AcceptEntityInput(entity, "kill");

	entity = g_iSpawns[index][1];
	g_iSpawns[index][1] = 0;
	if( IsValidEntRef(entity) )	AcceptEntityInput(entity, "kill");
	
	entity = g_iSpawns[index][2];
	g_iSpawns[index][2] = 0;
	if( IsValidEntRef(entity) )	AcceptEntityInput(entity, "kill");

	entity = g_iSpawns[index][3];
	g_iSpawns[index][3] = 0;
	if( IsValidEntRef(entity) )	AcceptEntityInput(entity, "kill");

	g_iSpawns[index][4] = 0;
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
Float:GetGroundHeight(Float:vPos[3])
{
	new Float:vAng[3], Handle:trace = TR_TraceRayFilterEx(vPos, Float:{ 90.0, 0.0, 0.0 }, MASK_ALL, RayType_Infinite, _TraceFilter);
	if( TR_DidHit(trace) )
		TR_GetEndPosition(vAng, trace);

	CloseHandle(trace);
	return vAng[2];
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
SetTeleportEndPoint(client, Float:vPos[3])
{
	decl Float:vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vPos, trace);
		GetGroundHeight(vPos);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

public bool:_TraceFilter(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}