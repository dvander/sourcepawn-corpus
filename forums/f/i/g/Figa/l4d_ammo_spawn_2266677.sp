#define PLUGIN_VERSION 		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Ammo Pile Spawner
*	Author	:	SilverShot
*	Descrp	:	Spawns ammo piles.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=221111

========================================================================================
	Change Log:

1.2 (20-Jul-2013)
	- Fixed a bug which broke spawning some ammo piles.

1.1 (19-Jul-2013)
	- Added command "sm_ammo_spawn_clear" to remove ammo piles spawned by this plugin from the map.
	- Changed command "sm_ammo_spawn_kill" to "sm_ammo_spawn_wipe"
	- Removed Sort_Random workaround, plugin requires SourceMod version 1.4.7 or higher.

1.0 (18-Jul-2013)
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
#define CHAT_TAG			"\x04[\x05AmmoPile\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_ammo_spawn.cfg"
#define MAX_SPAWNS			32

#define MODEL_AMMO_L4D			"models/props_unique/spawn_apartment/coffeeammo.mdl"
#define MODEL_AMMO_L4D1			"models/props/terror/Ammo_Can.mdl"
#define MODEL_AMMO_L4D2			"models/props/terror/ammo_stack.mdl"
#define MODEL_AMMO_L4D3			"models/props/de_prodigy/ammo_can_02.mdl"

static	Handle:g_hCvarMPGameMode, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarAllow,
		Handle:g_hCvarGlow, Handle:g_hCvarGlowCol, Handle:g_hCvarRandom,
		bool:g_bCvarAllow, g_iCvarGlow, g_iCvarGlowCol, g_iCvarRandom,
		Handle:g_hMenuAng, Handle:g_hMenuPos, bool:g_bLeft4Dead2, bool:g_bLoaded, g_iPlayerSpawn, g_iRoundStart,
		g_iSpawnCount, g_iSpawns[MAX_SPAWNS][2];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D2] Ammo Pile Spawner",
	author = "SilverShot",
	description = "Spawns ammo piles.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=221111"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_ammo_spawn_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarGlow =		CreateConVar(	"l4d_ammo_spawn_glow",			"0",			"0=Off, Sets the max range at which the ammo pile glows.", CVAR_FLAGS );
	g_hCvarGlowCol =	CreateConVar(	"l4d_ammo_spawn_glow_color",	"255 0 0",		"0=Default glow color. Three values between 0-255 separated by spaces. RGB: Red Green Blue.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_ammo_spawn_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_ammo_spawn_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_ammo_spawn_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d_ammo_spawn_random",		"-1",			"-1=All, 0=None. Otherwise randomly select this many ammo piles to spawn from the maps confg.", CVAR_FLAGS );
	CreateConVar(						"l4d_ammo_spawn_version",		PLUGIN_VERSION, "Ammo Pile Spawner plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_ammo_spawn");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hCvarMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarRandom,			ConVarChanged_Cvars);

	RegAdminCmd("sm_ammo_spawn",			CmdSpawnerTemp,		ADMFLAG_ROOT, 	"Spawns a temporary ammo pile at your crosshair. Usage: sm_ammo_spawn [1=L4D model, 2=L4D2 model, 2=L4D2 Crate]");
	RegAdminCmd("sm_ammo_spawn_save",		CmdSpawnerSave,		ADMFLAG_ROOT, 	"Spawns an ammo pile at your crosshair and saves to config. Usage: sm_ammo_spawn_save [1=L4D model, 2=L4D2 model, 2=L4D2 Crate]");
	RegAdminCmd("sm_ammo_spawn_del",		CmdSpawnerDel,		ADMFLAG_ROOT, 	"Removes the ammo pile you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_ammo_spawn_clear",		CmdSpawnerClear,	ADMFLAG_ROOT, 	"Removes all ammo piles spawned by this plugin from the current map.");
	RegAdminCmd("sm_ammo_spawn_wipe",		CmdSpawnerWipe,		ADMFLAG_ROOT, 	"Removes all ammo piles from the current map and deletes them from the config.");
	RegAdminCmd("sm_ammo_spawn_glow",		CmdSpawnerGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all ammo piles to see where they are placed.");
	RegAdminCmd("sm_ammo_spawn_list",		CmdSpawnerList,		ADMFLAG_ROOT, 	"Display a list ammo pile positions and the total number of.");
	RegAdminCmd("sm_ammo_spawn_tele",		CmdSpawnerTele,		ADMFLAG_ROOT, 	"Teleport to an ammo pile (Usage: sm_ammo_spawn_tele <index: 1 to MAX_SPAWNS (32)>).");
	RegAdminCmd("sm_ammo_spawn_ang",		CmdSpawnerAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the ammo pile angles your crosshair is over.");
	RegAdminCmd("sm_ammo_spawn_pos",		CmdSpawnerPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the ammo pile origin your crosshair is over.");
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	PrecacheModel(MODEL_AMMO_L4D, true);
	PrecacheModel(MODEL_AMMO_L4D1, true);
	if( g_bLeft4Dead2 ) PrecacheModel(MODEL_AMMO_L4D2, true);
	if( g_bLeft4Dead2 ) PrecacheModel(MODEL_AMMO_L4D3, true);
}

public OnMapEnd()
{
	ResetPlugin(false);
}

GetColor(Handle:cvar)
{
	decl String:sTemp[12], String:sColors[3][4];
	GetConVarString(cvar, sTemp, sizeof(sTemp));
	ExplodeString(sTemp, " ", sColors, 3, 4);

	new color;
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	return color;
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
	g_iCvarGlow = GetConVarInt(g_hCvarGlow);
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
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

	// Retrieve how many ammo piles to display
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few ammo piles?
	new iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved ammo piles or create random
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

	// Get the ammo pile origins and spawn
	decl String:sTemp[10], Float:vPos[3], Float:vAng[3];
	new index, iMod;
	for( new i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetVector(hFile, "ang", vAng);
			KvGetVector(hFile, "pos", vPos);
			iMod = KvGetNum(hFile, "mod");

			if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index, iMod);
			KvGoBack(hFile);
		}
	}

	CloseHandle(hFile);
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
CreateSpawn(const Float:vOrigin[3], const Float:vAngles[3], index = 0, model = 0)
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

	new entity = CreateEntityByName("weapon_ammo_spawn");
	if( entity == -1 )
		ThrowError("Failed to create ammo pile.");

	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(entity);
	g_iSpawns[iSpawnIndex][1] = index;

	if( !g_bLeft4Dead2 ) model = 1;
	DispatchSpawn(entity);
	if( model == 2 )		SetEntityModel(entity, MODEL_AMMO_L4D2);
	else if( model == 3 )	SetEntityModel(entity, MODEL_AMMO_L4D3);
	else					SetEntityModel(entity, MODEL_AMMO_L4D);
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

	if( g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 1);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		AcceptEntityInput(entity, "StartGlowing");
	}

	g_iSpawnCount++;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_ammo_spawn
// ====================================================================================================
public Action:CmdSpawnerTemp(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Ammo Pile Spawner] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore ammo piles. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	new Float:vPos[3], Float:vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place ammo pile, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}

	new iMod = 0;
	if( args == 1 )
	{
		decl String:sNum[8];
		GetCmdArg(1, sNum, sizeof(sNum));
		iMod = StringToInt(sNum);
	}

	CreateSpawn(vPos, vAng, 0, iMod);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_ammo_spawn_save
// ====================================================================================================
public Action:CmdSpawnerSave(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Ammo Pile Spawner] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore ammo piles. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
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
		PrintToChat(client, "%sError: Cannot read the ammo pile config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);
	if( !KvJumpToKey(hFile, sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to ammo pile spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many ammo piles are saved
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore ammo piles. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
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
		// Set player position as ammo pile spawn location
		if( !SetTeleportEndPoint(client, vPos, vAng) )
		{
			PrintToChat(client, "%sCannot place ammo pile, please try again.", CHAT_TAG);
			CloseHandle(hFile);
			return Plugin_Handled;
		}

		new iMod = 0;
		if( args == 1 )
		{
			decl String:sNum[8];
			GetCmdArg(1, sNum, sizeof(sNum));
			iMod = StringToInt(sNum);
		}

		// Save angle / origin
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);
		KvSetNum(hFile, "mod", iMod);

		CreateSpawn(vPos, vAng, iCount, iMod);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save ammo pile.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_ammo_spawn_del
// ====================================================================================================
public Action:CmdSpawnerDel(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Ammo Pile Spawner] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Ammo Pile Spawner] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	new cfgindex, index = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	cfgindex = g_iSpawns[index][1];
	if( cfgindex == 0 )
	{
		RemoveSpawn(index);
		return Plugin_Handled;
	}

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][1] > cfgindex )
			g_iSpawns[i][1]--;
	}

	g_iSpawnCount--;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the ammo pile config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the ammo pile config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the ammo pile config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many ammo piles
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

		PrintToChat(client, "%s(\x05%d/%d\x01) - ammo pile removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove ammo pile from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_ammo_spawn_clear
// ====================================================================================================
public Action:CmdSpawnerClear(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Ammo Pile Spawner] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All ammo piles removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_ammo_spawn_wipe
// ====================================================================================================
public Action:CmdSpawnerWipe(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Ammo Pile Spawner] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the ammo pile config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the ammo pile config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the ammo pile config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	KvDeleteThis(hFile);
	ResetPlugin();

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(0/%d) - All ammo piles removed from config, add with \x05sm_ammo_spawn_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_ammo_spawn_glow
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
			SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
			SetEntProp(ent, Prop_Send, "m_glowColorOverride", 65535);
			SetEntProp(ent, Prop_Send, "m_nGlowRange", glow ? 0 : 50);
			ChangeEdictState(ent, FindSendPropOffs("prop_dynamic", "m_nGlowRange"));
		}
	}
}

// ====================================================================================================
//					sm_ammo_spawn_list
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
//					sm_ammo_spawn_tele
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
		PrintToChat(client, "%sUsage: sm_ammo_spawn_tele <index 1-%d>.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action:CmdSpawnerAng(client, args)
{
	ShowMenuAng(client);
	return Plugin_Handled;
}

ShowMenuAng(client)
{
	CreateMenus();
	DisplayMenu(g_hMenuAng, client, MENU_TIME_FOREVER);
}

public AngMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}
}

SetAngle(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vAng[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				if( index == 0 ) vAng[0] += 5.0;
				else if( index == 1 ) vAng[1] += 5.0;
				else if( index == 2 ) vAng[2] += 5.0;
				else if( index == 3 ) vAng[0] -= 5.0;
				else if( index == 4 ) vAng[1] -= 5.0;
				else if( index == 5 ) vAng[2] -= 5.0;

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
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
		if( index == 6 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

SetOrigin(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vPos[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				if( index == 0 ) vPos[0] += 0.5;
				else if( index == 1 ) vPos[1] += 0.5;
				else if( index == 2 ) vPos[2] += 0.5;
				else if( index == 3 ) vPos[0] -= 0.5;
				else if( index == 4 ) vPos[1] -= 0.5;
				else if( index == 5 ) vPos[2] -= 0.5;

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}

SaveData(client)
{
	new entity, index;
	new aim = GetClientAimTarget(client, false);
	if( aim == -1 )
		return;

	aim = EntIndexToEntRef(aim);

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		entity = g_iSpawns[i][0];

		if( entity == aim  )
		{
			index = g_iSpawns[i][1];
			break;
		}
	}

	if( index == 0 )
		return;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the ammo pile spawner config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the ammo pile spawner config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the ammo pile spawner config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	decl Float:vAng[3], Float:vPos[3], String:sTemp[32];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
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
	if( g_hMenuAng == INVALID_HANDLE )
	{
		g_hMenuAng = CreateMenu(AngMenuHandler);
		AddMenuItem(g_hMenuAng, "", "X + 5.0");
		AddMenuItem(g_hMenuAng, "", "Y + 5.0");
		AddMenuItem(g_hMenuAng, "", "Z + 5.0");
		AddMenuItem(g_hMenuAng, "", "X - 5.0");
		AddMenuItem(g_hMenuAng, "", "Y - 5.0");
		AddMenuItem(g_hMenuAng, "", "Z - 5.0");
		AddMenuItem(g_hMenuAng, "", "SAVE");
		SetMenuTitle(g_hMenuAng, "Set Angle");
		SetMenuExitButton(g_hMenuAng, true);
	}

	if( g_hMenuPos == INVALID_HANDLE )
	{
		g_hMenuPos = CreateMenu(PosMenuHandler);
		AddMenuItem(g_hMenuPos, "", "X + 0.5");
		AddMenuItem(g_hMenuPos, "", "Y + 0.5");
		AddMenuItem(g_hMenuPos, "", "Z + 0.5");
		AddMenuItem(g_hMenuPos, "", "X - 0.5");
		AddMenuItem(g_hMenuPos, "", "Y - 0.5");
		AddMenuItem(g_hMenuPos, "", "Z - 0.5");
		AddMenuItem(g_hMenuPos, "", "SAVE");
		SetMenuTitle(g_hMenuPos, "Set Position");
		SetMenuExitButton(g_hMenuPos, true);
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
	new entity = g_iSpawns[index][0];
	g_iSpawns[index][0] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
SetTeleportEndPoint(client, Float:vPos[3], Float:vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if(TR_DidHit(trace))
	{
		decl Float:vNorm[3];
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vNorm);
		new Float:angle = vAng[1];
		GetVectorAngles(vNorm, vAng);

		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] += angle;
		}
		else
		{
			vAng[0] = 0.0;
			vAng[1] += angle - 90.0;
		}
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