#define PLUGIN_VERSION		"1.6"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Health Cabinet
*	Author	:	SilverShot
*	Descrp	:	Auto-Spawns Health Cabinets.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=175154

========================================================================================
	Change Log:

1.6 (18-Jul-2013)
	- Fixed spawning issues.

1.5.1 (05-Jun-2012)
	- Fixed print to chat error from the command "sm_cabinetglow".

1.5.0 (01-Jun-2012)
	- Added cvar "l4d_cabinet_glow_color" to set the glow color, L4D2 only.
	- Fixed bugs with deleting Cabinets.
	- Prevention for empty Cabinets, now spawns 1 second after opening when bugged.
	- Versus games now spawn the same cabinets and items for both teams - Requested by "Dont Fear The Reaper"

1.4 (10-May-2012)
	- Added command "sm_cabinetglow" to see where cabinets are placed.
	- Added command "sm_cabinettele" to teleport to a cabinet.
	- Added command "sm_cabinetang" to change the cabinet angle.
	- Added command "sm_cabinetpos" to change the cabinet origin.
	- Fixed a bug causing errors when deleting cabinets.

1.3 (03-Mar-2012)
	- Added cvar "l4d_cabinet_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_cabinet_modes_tog" same as above, but only works for L4D2.
	- Added cvar "l4d_cabinet_spawn_adren" to set the chance of spawning adrenaline.
	- Added cvar "l4d_cabinet_spawn_defib" to set the chance of spawning defibrillators.
	- Added cvar "l4d_cabinet_spawn_first" to set the chance of spawning first aid kits.
	- Added cvar "l4d_cabinet_spawn_pills" to set the chance of spawning pain pills.
	- Changed command "sm_cabinet" and "sm_cabinetsave" usage: sm_cabinetsave <first> <pills> <adren> <defib>.
	- Changed default values of some cvars.
	- Changed the data config format. Please use the "sm_silvercfg" plugin to convert reformat the config.
	- Removed cvar "l4d_cabinet_type"
	- Removed cvar "l4d_cabinet_type1"
	- Removed cvar "l4d_cabinet_type2"

1.2 (02-Jan-2012)
	- Temporary update:
	- Fixed bots auto-grabbing items from closed cabinets.
	- Added cvar "l4d_cabinet_type1".
	- Added cvar "l4d_cabinet_type2".
	- Changed command "sm_cabinet" and "sm_cabinetsave" usage.

1.1 (31-Dec-2011)
	- Removed useless code.

1.0 (31-Dec-2011)
	- Initial Release.

======================================================================================*/

#pragma semicolon			1

#include <sdktools>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x05[Health Cabinet] \x01"
#define CONFIG_SPAWNS		"data/l4d_cabinet.cfg"
#define MAX_ALLOWED			16

#define MODEL_CABINET		"models/props_interiors/medicalcabinet02.mdl"

static 	Handle:g_hCvarAllow, Handle:g_hCvarGlow, Handle:g_hCvarGlowCol, Handle:g_hCvarMax, Handle:g_hCvarMin, Handle:g_hCvarModes, Handle:g_hCvarModesOff,
		Handle:g_hCvarModesTog, Handle:g_hCvarRandom, Handle:g_hCvarSpawn1, Handle:g_hCvarSpawn2,  Handle:g_hCvarSpawn3, Handle:g_hCvarSpawn4,

		bool:g_bCvarAllow, g_iCvarGlow, g_iCvarGlowCol, g_iCvarMax, g_iCvarMin, g_iCvarRandom, g_iCvarSpawn1, g_iCvarSpawn2, g_iCvarSpawn3, g_iCvarSpawn4,

		Handle:g_hMPGameMode, Handle:g_hTimerLoad, Handle:g_hMenuAng, Handle:g_hMenuPos, bool:g_bLeft4Dead2, bool:g_bLoaded, g_iRoundStart, g_iOrder, bool:g_bGlow,
		g_iEntities[MAX_ALLOWED], g_iCfgIndex[MAX_ALLOWED], g_iCabinetType[MAX_ALLOWED][4], g_iCabinetItems[MAX_ALLOWED][4], g_iCabinetRandom[MAX_ALLOWED],
		g_iSpawned[MAX_ALLOWED], Float:g_vCabinetAng[MAX_ALLOWED][3], Float:g_vCabinetPos[MAX_ALLOWED][3], g_iCount;

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Health Cabinet",
	author = "SilverShot",
	description = "Auto-Spawns Health Cabinets.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=175154"
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

	if( late )
		g_iRoundStart = 1;

	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarAllow = CreateConVar(		"l4d_cabinet_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes =	CreateConVar(		"l4d_cabinet_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff =	CreateConVar(	"l4d_cabinet_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	if( g_bLeft4Dead2 == true )
	{
		g_hCvarModesTog = CreateConVar(	"l4d_cabinet_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
		g_hCvarGlow = CreateConVar(		"l4d_cabinet_glow",				"150",			"0=Off. Range the cabinet glows.", CVAR_FLAGS);
		g_hCvarGlowCol = CreateConVar(	"l4d_cabinet_glow_color",		"255 0 0",		"0=Default glow color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	}
	g_hCvarMax = CreateConVar(			"l4d_cabinet_max",				"4",			"Maximum number of items.", CVAR_FLAGS, true, 0.0, true, 4.0);
	g_hCvarMin = CreateConVar(			"l4d_cabinet_min",				"4",			"Minimum number of items.", CVAR_FLAGS, true, 0.0, true, 4.0);
	g_hCvarRandom =	CreateConVar(		"l4d_cabinet_random",			"2",			"-1=All, 0=Off, other value randomly spawns that many Cabinets from the config.", CVAR_FLAGS);
	g_hCvarSpawn3 =	CreateConVar(		"l4d_cabinet_spawn_adren",		"0",			"Chance out of 100 to spawn adrenaline.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarSpawn4 =	CreateConVar(		"l4d_cabinet_spawn_defib",		"0",			"Chance out of 100 to spawn defibrillators.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarSpawn1 =	CreateConVar(		"l4d_cabinet_spawn_first",		"100",			"Chance out of 100 to spawn first aid kits.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarSpawn2 =	CreateConVar(		"l4d_cabinet_spawn_pills",		"0",			"Chance out of 100 to spawn pain pills.", CVAR_FLAGS, true, 0.0, true, 100.0);
	CreateConVar(						"l4d_cabinet_version",			PLUGIN_VERSION,	"Health Cabinet plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_cabinet");


	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	if( g_bLeft4Dead2 )
	{
		HookConVarChange(g_hCvarModesTog,	ConVarChanged_Allow);
		HookConVarChange(g_hCvarGlow,		ConVarChanged_Glow);
		HookConVarChange(g_hCvarGlowCol,	ConVarChanged_Glow);
	}
	HookConVarChange(g_hCvarMax,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMin,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRandom,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpawn1,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpawn2,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpawn3,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpawn4,			ConVarChanged_Cvars);


	RegAdminCmd(		"sm_cabinet",			CmdCabinet,			ADMFLAG_ROOT,	"Spawns a temporary Health Cabinet at your crosshair.  Usage: sm_cabinetsave <first> <pills> <adren> <defib>.");
	RegAdminCmd(		"sm_cabinetsave",		CmdCabinetSave,		ADMFLAG_ROOT, 	"Spawns a Health Cabinet at your crosshair and saves to config. Usage: sm_cabinetsave <first> <pills> <adren> <defib>.");
	RegAdminCmd(		"sm_cabinetlist",		CmdCabinetList,		ADMFLAG_ROOT, 	"Displays a list of Health Cabinets spawned by the plugin and their locations.");
	if( g_bLeft4Dead2 == true )
		RegAdminCmd(	"sm_cabinetglow",		CmdCabinetGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all cabinets to see where they are placed.");
	RegAdminCmd(		"sm_cabinettele",		CmdCabinetTele,		ADMFLAG_ROOT, 	"Teleport to a cabinet (Usage: sm_cabinettele <index: 1 to MAX_CABINETS>).");
	RegAdminCmd(		"sm_cabinetdel",		CmdCabinetDelete,	ADMFLAG_ROOT, 	"Removes the Health Cabinet you are aiming at and deletes from the config if saved.");
	RegAdminCmd(		"sm_cabinetclear",		CmdCabinetClear,	ADMFLAG_ROOT, 	"Removes all Health Cabinets from the current map.");
	RegAdminCmd(		"sm_cabinetwipe",		CmdCabinetWipe,		ADMFLAG_ROOT, 	"Removes all Health Cabinets from the current map and deletes them from the config.");
	RegAdminCmd(		"sm_cabinetang",		CmdCabinetAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the cabinet angles your crosshair is over.");
	RegAdminCmd(		"sm_cabinetpos",		CmdCabinetPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the cabinet origin your crosshair is over.");
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	PrecacheModel(MODEL_CABINET, true);
}

public OnMapEnd()
{
	ResetPlugin(true);
}

ResetPlugin(bool:all = false)
{
	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		DeleteEntity(i);
	}

	if( all == true )
	{
		g_bLoaded = false;
		g_iRoundStart = 0;
		g_iOrder = 0;
		g_iCount = 0;
	}
}

DeleteEntity(index)
{
	g_iCfgIndex[index] = 0;

	new entity = g_iEntities[index];
	g_iEntities[index] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	for( new i = 0; i < 4; i++ )
	{
		entity = g_iCabinetItems[index][i];
		g_iCabinetItems[index][i] = 0;

		if( IsValidEntRef(entity) )
		{
			if( GetEntProp(entity, Prop_Send, "m_hOwnerEntity") == -1 )
				AcceptEntityInput(entity, "Kill");
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Glow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarGlow = GetConVarInt(g_hCvarGlow);
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	ToggleGlow(g_bGlow);
}

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

GetColor(Handle:hCvar)
{
	decl String:sTemp[12];
	GetConVarString(hCvar, sTemp, sizeof(sTemp));

	if( strcmp(sTemp, "") == 0 )
		return 0;

	decl String:sColors[3][4];
	new color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

GetCvars()
{
	if( g_bLeft4Dead2 == true )
	{
		g_iCvarGlow =	GetConVarInt(g_hCvarGlow);
		g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	}

	g_iCvarMax =	GetConVarInt(g_hCvarMax);
	g_iCvarMin =	GetConVarInt(g_hCvarMin);
	g_iCvarRandom =	GetConVarInt(g_hCvarRandom);
	g_iCvarSpawn1 =	GetConVarInt(g_hCvarSpawn1);
	g_iCvarSpawn2 =	GetConVarInt(g_hCvarSpawn2);
	g_iCvarSpawn3 =	GetConVarInt(g_hCvarSpawn3);
	g_iCvarSpawn4 =	GetConVarInt(g_hCvarSpawn4);
}

IsAllowed()
{
	new bool:bAllowCvar = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bAllowCvar == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		g_bLoaded = false;
		LoadCabinets();
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bAllowCvar == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin(true);
		UnhookEvents();

		if( g_hTimerLoad != INVALID_HANDLE )
		{
			CloseHandle(g_hTimerLoad);
			g_hTimerLoad = INVALID_HANDLE;
		}
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	if( g_bLeft4Dead2 )
	{
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
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
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
HookEvents()
{
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_use",				Event_PlayerUse);
}

UnhookEvents()
{
	UnhookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	UnhookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
	UnhookEvent("player_use",			Event_PlayerUse);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bGlow = false;

	if(	g_iOrder == 0 )
	{
		ResetPlugin();
		g_iOrder = 0;
		g_iCount = 0;
	}
	else
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

		if( g_iCurrentMode != 4 && g_iCurrentMode != 8 )
		{
			ResetPlugin();
			g_iOrder = 0;
			g_iCount = 0;
		}
	}

	g_hTimerLoad = CreateTimer(60.0, tmrLoad);
	g_iRoundStart = 1;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bLoaded = false;

	if( g_iRoundStart == 0 )
		return;

	g_iRoundStart = 0;

	if( g_iOrder == 1 )
		g_iOrder = 0;
	else
		g_iOrder = 1;
}

public Action:tmrLoad(Handle:timer)
{
	g_hTimerLoad = INVALID_HANDLE;
	LoadCabinets();
}

LoadCabinets()
{
	if( g_bLoaded == true ) return;
	g_bLoaded = true;

	if( g_iCvarRandom == 0 )
		return;

	if( g_iOrder == 1 )
	{
		for( new i = 0; i < g_iCount; i++ )
		{
			SpawnCabinet(g_vCabinetAng[i], g_vCabinetPos[i], g_iCabinetType[i][0], g_iCabinetType[i][1], g_iCabinetType[i][2], g_iCabinetType[i][3], g_iCfgIndex[i]);
		}

		return;
	}

	g_iCount = 0;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	new Handle:hFile = CreateKeyValues("cabinets");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !KvJumpToKey(hFile, sMap) )
	{
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many to display
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few?
	new index, i;
	new iIndexes[MAX_ALLOWED+1];
	if( iCount > MAX_ALLOWED )
		iCount = MAX_ALLOWED;


	// Spawn saved cabinets or create random
	new iRandom = g_iCvarRandom;
	if( iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( i = 0; i < iCount; i++ )
			iIndexes[i] = i + 1;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the cabinets origins and spawn
	decl String:sTemp[10], Float:vPos[3], Float:vAng[3];
	new type1, type2, type3, type4;

	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetVector(hFile, "angle", vAng);
			KvGetVector(hFile, "origin", vPos);
			type1 = KvGetNum(hFile, "adren", -1);
			type2 = KvGetNum(hFile, "defib", -1);
			type3 = KvGetNum(hFile, "first", -1);
			type4 = KvGetNum(hFile, "pills", -1);

			KvGoBack(hFile);

			if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
			{
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
			}
			else
			{
				g_vCabinetAng[g_iCount] = vAng;
				g_vCabinetPos[g_iCount] = vPos;
				g_iCount++;
				SpawnCabinet(vAng, vPos, type1, type2, type3, type4, index);
			}
		}
	}

	CloseHandle(hFile);
}

SetupCabinet(client, Float:vAng[3] = NULL_VECTOR, Float:vPos[3] = NULL_VECTOR, type1, type2, type3, type4)
{
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vAng);
		GetVectorAngles(vAng, vAng);
		CloseHandle(trace);

		decl Float:vDir[3];
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0];
		vPos[1] += vDir[1];
		vPos[2] -= 50.0;

		return SpawnCabinet(vAng, vPos, type1, type2, type3, type4);
	}
	else
	{
		CloseHandle(trace);
	}

	return -1;
}

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )
		return false;
	return true;
}

SpawnCabinet(Float:vAng[3], Float:vPos[3], type1, type2, type3, type4, cfgindex = 0)
{
	new index = -1;

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef(g_iEntities[i]) )
		{
			index = i;
			break;
		}
	}

	if( index == -1 ) return -1;


	new entity = CreateEntityByName("prop_health_cabinet");
	g_iEntities[index] = EntIndexToEntRef(entity);
	g_iCfgIndex[index] = cfgindex;
	g_iSpawned[index] = 0;

	DispatchKeyValue(entity, "model", MODEL_CABINET);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);
	SetEntityMoveType(entity, MOVETYPE_NONE);

	g_iCabinetType[index][0] = type1;
	g_iCabinetType[index][1] = type2;
	g_iCabinetType[index][2] = type3;
	g_iCabinetType[index][3] = type4;

	if( g_bLeft4Dead2 && g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 1);
	}

	HookSingleEntityOutput(entity, "OnAnimationDone", OnAnimationDone, true);

	return index;
}

public OnAnimationDone(const String:output[], entity, activator, Float:delay)
{
	SpawnItems(entity);
}

public Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "targetid");

	if( entity > MaxClients && IsValidEntity(entity) == true )
	{
		SpawnItems(entity);
	}
}

SpawnItems(entity)
{
	entity = EntIndexToEntRef(entity);
	new index = -1;

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( entity == g_iEntities[i] )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
	{
		return;
	}

	
	UnhookSingleEntityOutput(entity, "OnAnimationDone", OnAnimationDone);

	if( g_iSpawned[index] == 1 )
	{
		return;
	}

	g_iSpawned[index] = 1;

	new random;

	if( g_iOrder == 0 || g_iCabinetRandom[index] == 0 )
	{
		if( g_iCvarMin == 0 )
		{
			random = GetRandomInt(g_iCvarMin, g_iCvarMax * 2);
			if( random > 2 )
				random = (random + 1) / 2;
		}
		else
		{
			random = GetRandomInt(g_iCvarMin, g_iCvarMax);
		}

		if( random == 0 )
		{
			g_iCabinetRandom[index] = -1;
			return;
		}
		else
		{
			g_iCabinetRandom[index] = random;
		}
	}
	else
	{
		random = g_iCabinetRandom[index];
		if( random == -1 )
			random = 0;
	}


	if( random == 0 )
		return;

	new type1 = g_iCabinetType[index][0];
	if( type1 == -1 ) type1 = g_iCvarSpawn1;
	new type2 = g_iCabinetType[index][1];
	if( type2 == -1 ) type2 = g_iCvarSpawn2;
	new type3 = g_iCabinetType[index][2];
	if( type3 == -1 ) type3 = g_iCvarSpawn3;
	new type4 = g_iCabinetType[index][3];
	if( type4 == -1 ) type4 = g_iCvarSpawn4;

	if( g_bLeft4Dead2 == false )
	{
		type3 = 0;
		type4 = 0;
	}

	decl Float:vTempPos[3], Float:vTempAng[3], Float:vAng[3], Float:vPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);

	new place[5] = { 1, 2, 3, 4 }, placed;
	SortIntegers(place, 4, Sort_Random);

	new randomselect, selected;
	for( new i = 0; i < random; i++ )
	{
		if( g_iOrder == 0 || g_iCabinetType[index][i] >= 0 )
		{
			randomselect = type1 + type2 + type3 + type4;
			selected = GetRandomInt(1, randomselect);

			if( selected <= type1 )
				selected = 1;
			else if( selected <= type1 + type2 )
				selected = 2;
			else if( selected <= type1 + type2 + type3 )
				selected = 3;
			else if( selected <= randomselect )
				selected = 4;

			g_iCabinetType[index][i] = selected - 5;
		}
		else
		{
			selected = g_iCabinetType[index][i] + 5;
		}

		if( selected == 1 )
			entity = CreateEntityByName("weapon_first_aid_kit");
		else if( selected == 2 )
			entity = CreateEntityByName("weapon_pain_pills");
		else if( selected == 3 )
			entity = CreateEntityByName("weapon_adrenaline");
		else if( selected == 4 )
			entity = CreateEntityByName("weapon_defibrillator");
		DispatchKeyValue(entity, "solid", "0");
		DispatchKeyValue(entity, "disableshadows", "1");

		g_iCabinetItems[index][i] = EntIndexToEntRef(entity);

		vTempPos = vPos;
		MoveForward(vTempPos, vAng, vTempPos, 3.0);

		placed = place[i];

		if( placed == 1 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, -9.0);
			vTempPos[2] += 37.0;
		}
		else if( placed == 2 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, 9.0);
			vTempPos[2] += 37.0;
		}
		else if( placed == 3 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, 9.0);
			vTempPos[2] += 51.0;
		}
		else if( placed == 4 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, -9.0);
			vTempPos[2] += 51.0;
		}
		vTempAng = vAng;
		vTempAng[1] += 180.0;

		DispatchSpawn(entity);
		TeleportEntity(entity, vTempPos, vTempAng, NULL_VECTOR);
		SetEntityMoveType(entity, MOVETYPE_PUSH);
	}
}

MoveSideway(const Float:vPos[3], const Float:vAng[3], Float:vReturn[3], Float:fDistance)
{
	fDistance *= -1.0;
	decl Float:vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

MoveForward(const Float:vPos[3], const Float:vAng[3], Float:vReturn[3], Float:fDistance)
{
	decl Float:vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}



// ====================================================================================================
//					COMMANDS - TEMP, SAVE, LIST, DELETE, CLEAR, WIPE
// ====================================================================================================

// ====================================================================================================
//					sm_cabinet
// ====================================================================================================
public Action:CmdCabinet(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

	new type1 = -1, type2 = -1, type3 = -1, type4 = -1;
	if( args == 1 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
	}
	else if( args == 2 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
	}
	else if( args == 3 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
	}
	else if( args == 4 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
		GetCmdArg(4, sTemp, sizeof(sTemp));
		type4 = StringToInt(sTemp);
	}

	decl Float:vAng[3], Float:vPos[3];
	SetupCabinet(client, vAng, vPos, type1, type2, type3, type4);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetsave
// ====================================================================================================
public Action:CmdCabinetSave(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server.");
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
	new Handle:hFile = CreateKeyValues("cabinets");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Health Cabinet config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !KvJumpToKey(hFile, sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Health Cabinet spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many are saved
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount >= MAX_ALLOWED )
	{
		PrintToChat(client, "%sError: Cannot add anymore Health Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_ALLOWED);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	new type1 = -1, type2 = -1, type3 = -1, type4 = -1;
	if( args == 1 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
	}
	else if( args == 2 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
	}
	else if( args == 3 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
	}
	else if( args == 4 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
		GetCmdArg(4, sTemp, sizeof(sTemp));
		type4 = StringToInt(sTemp);
	}

	decl Float:vAng[3], Float:vPos[3];
	new index = SetupCabinet(client, vAng, vPos, type1, type2, type3, type4);

	if( index != -1 )
	{
		g_iCfgIndex[index] = iCount + 1;
	}

	// Save count
	iCount++;
	KvSetNum(hFile, "num", iCount);

	decl String:sTemp[10];

	IntToString(iCount, sTemp, sizeof(sTemp));
	if( KvJumpToKey(hFile, sTemp, true) )
	{
		KvSetVector(hFile, "angle", vAng);
		KvSetVector(hFile, "origin", vPos);

		if( type1 != -1 )
			KvSetNum(hFile, "adren", type1);
		if( type2 != -1 )
			KvSetNum(hFile, "defib", type2);
		if( type3 != -1 )
			KvSetNum(hFile, "first", type3);
		if( type4 != -1 )
			KvSetNum(hFile, "pills", type4);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Cabinet", CHAT_TAG, iCount, MAX_ALLOWED);

	CloseHandle(hFile);

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetlist
// ====================================================================================================
public Action:CmdCabinetList(client, args)
{
	decl Float:vPos[3];
	new i,  ent, count;

	for( i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iEntities[i];

		if( IsValidEntRef(ent) )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			if( client == 0 )
				ReplyToCommand(client, "[Health Cabinet] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		PrintToChat(client, "[Health Cabinet] Total: %d.", count);
	else
		ReplyToCommand(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetglow
// ====================================================================================================
public Action:CmdCabinetGlow(client, args)
{
	g_bGlow = !g_bGlow;
	ToggleGlow(g_bGlow);

	if( client )
		PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, g_bGlow ? "on" : "off");
	else
		ReplyToCommand(client, "[Cabinet] Glow has been turned %s", g_bGlow ? "on" : "off");
	return Plugin_Handled;
}

ToggleGlow(glow)
{
	new entity;

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i];
		if( IsValidEntRef(entity) )
		{
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", glow ? 0 : g_iCvarGlow);
			SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 20);
			if( glow )
				AcceptEntityInput(entity, "StartGlowing");
			else if( !glow && !g_iCvarGlow )
				AcceptEntityInput(entity, "StopGlowing");
		}
	}
}

// ====================================================================================================
//					sm_cabinettele
// ====================================================================================================
public Action:CmdCabinetTele(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

	if( args == 1 )
	{
		decl String:arg[16];
		GetCmdArg(1, arg, 16);
		new index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_ALLOWED && IsValidEntRef(g_iEntities[index]) )
		{
			decl Float:vPos[3], Float:vAng[3];
			GetEntPropVector(g_iEntities[index], Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(g_iEntities[index], Prop_Data, "m_angRotation", vAng);
			MoveForward(vPos, vAng, vPos, 35.0);

			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_cabinettele <index 1-%d>.", CHAT_TAG, MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetdel
// ====================================================================================================
public Action:CmdCabinetDelete(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

	new entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	new index = -1;
	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iEntities[i] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	new cfgindex = g_iCfgIndex[index];
	if( cfgindex == 0 )
	{
		DeleteEntity(index);
		return Plugin_Handled;
	}

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot find the Health Cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	new Handle:hFile = CreateKeyValues("cabinets");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot load the Health Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sWarning: Current map not in the Health Cabinet config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many
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
				for( new u = 0; u < MAX_ALLOWED; u++ )
				{
					if( g_iCfgIndex[u] >= cfgindex )
					{
						g_iCfgIndex[u]--;
					}
				}
				DeleteEntity(index);

				bMove = true;
				KvDeleteThis(hFile);
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

		PrintToChat(client, "%s(\x05%d/%d\x01) - Health Cabinet removed from config.", CHAT_TAG, iCount, MAX_ALLOWED);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Cabinet from config.", CHAT_TAG, iCount, MAX_ALLOWED);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetclear
// ====================================================================================================
public Action:CmdCabinetClear(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	ResetPlugin();
	if( client )
		PrintToChat(client, "%sAll Health Cabinets removed from the map.", CHAT_TAG);
	else
		ReplyToCommand(client, "[Helth Cabinet] All Health Cabinets removed from the map.");
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetwipe
// ====================================================================================================
public Action:CmdCabinetWipe(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Health Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	new Handle:hFile = CreateKeyValues("cabinets");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Health Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !KvJumpToKey(hFile, sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Health Cabinet config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	KvDeleteThis(hFile);

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	ResetPlugin();
	PrintToChat(client, "%s(0/%d) - All Health Cabinets removed from config, add new with \x05sm_cabinetsave\x01.", CHAT_TAG, MAX_ALLOWED);
	return Plugin_Handled;
}



// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action:CmdCabinetAng(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

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

		for( new i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iEntities[i];

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
public Action:CmdCabinetPos(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

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

		for( new i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iEntities[i];

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

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i];

		if( entity == aim  )
		{
			index = g_iCfgIndex[i];
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
		PrintToChat(client, "%sError: Cannot find the cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	new Handle:hFile = CreateKeyValues("cabinets");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the cabinet config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	decl Float:vAng[3], Float:vPos[3], String:sTemp[32];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
	if( KvJumpToKey(hFile, sTemp) )
	{
		KvSetVector(hFile, "angle", vAng);
		KvSetVector(hFile, "origin", vPos);

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

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}