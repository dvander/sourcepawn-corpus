#pragma semicolon			1

#include <sdktools>

#define PLUGIN_VERSION		"1.2"
#define CHAT_TAG			"\x05[Health Cabinet] \x01"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CONFIG_SPAWNS		"data/l4d_cabinet.cfg"
#define MODEL_CABINET		"models/props_interiors/medicalcabinet02.mdl"
#define MAX_ALLOWED			16

static 	Handle:g_hCvarAllow, Handle:g_hCvarGlow, Handle:g_hCvarMax, Handle:g_hCvarMin, Handle:g_hCvarModes, Handle:g_hCvarRandom, Handle:g_hCvarType,
		Handle:g_hCvarType1, Handle:g_hCvarType2, bool:g_bCvarAllow, g_iCvarGlow, g_iCvarMax, g_iCvarMin, g_iCvarRandom, g_iCvarType, g_iCvarType1, g_iCvarType2,
		Handle:g_hMPGameMode, bool:g_bLeft4Dead, bool:g_bLoaded, g_iRoundStart, g_iPlayerSpawn, g_iOffsetGlow;
static	g_iEntities[MAX_ALLOWED], g_iCabinetType[MAX_ALLOWED][3], g_iCabinetItems[MAX_ALLOWED][4];

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Health Cabinet",
	author = "SilverShot",
	description = "Auto-Spawns Health Cabinets.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=175154"
}

public OnPluginStart()
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead = false;
	else if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead = true;
	else SetFailState("Plugin only supports Left4Dead 1 & 2.");

	g_hCvarAllow =	CreateConVar("l4d_cabinet_allow",		"1",	"0=Plugin off, 1=Plugin on.",						CVAR_FLAGS);
	if( g_bLeft4Dead == false )
		g_hCvarGlow =	CreateConVar("l4d_cabinet_glow",	"50",	"0=Off. Range the cabinet glow.",					CVAR_FLAGS);
	g_hCvarMax =	CreateConVar("l4d_cabinet_max",			"4",	"Maximum number of first aid kits or pills.",		CVAR_FLAGS, true, 0.0, true, 4.0);
	g_hCvarMin =	CreateConVar("l4d_cabinet_min",			"0",	"Minimum number of first aid kits or pills.",		CVAR_FLAGS, true, 0.0, true, 4.0);
	g_hCvarModes =	CreateConVar("l4d_cabinet_modes",		"",		"Which game modes to enable the plugin.",			CVAR_FLAGS);
	g_hCvarRandom =	CreateConVar("l4d_cabinet_random",		"2",	"-1=All, 0=Off, other value randomly spawns that many from the config.",				CVAR_FLAGS);
	g_hCvarType =	CreateConVar("l4d_cabinet_type",		"90",	"Chance out of 100 to spawn pills/adrenaline, remainder to spawn first aid kits/defibrillators.",		CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarType1 =	CreateConVar("l4d_cabinet_type1",		"90",	"Chance out of 100 to select pills, remainder to select adrenaline.",					CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarType2 =	CreateConVar("l4d_cabinet_type2",		"90",	"Chance out of 100 to select first aid kits, remainder to select defibrillators.",		CVAR_FLAGS, true, 0.0, true, 100.0);
	CreateConVar("l4d_cabinet_version", PLUGIN_VERSION, "Health Cabinet plugin version.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_cabinet");

	LoadTranslations("common.phrases");

	if( g_bLeft4Dead == false )
		g_iOffsetGlow = FindSendPropOffs("prop_physics", "m_nGlowRange");
	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode, ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,	ConVarChanged_Allow);
	if( g_bLeft4Dead == false )
		HookConVarChange(g_hCvarGlow,	ConVarChanged_Changed);
	HookConVarChange(g_hCvarMax,	ConVarChanged_Changed);
	HookConVarChange(g_hCvarMin,	ConVarChanged_Changed);
	HookConVarChange(g_hCvarRandom,	ConVarChanged_Changed);
	HookConVarChange(g_hCvarType,	ConVarChanged_Changed);
	HookConVarChange(g_hCvarType1,	ConVarChanged_Changed);
	HookConVarChange(g_hCvarType2,	ConVarChanged_Changed);

	RegAdminCmd("sm_cabinet",			CmdCabinet,			ADMFLAG_ROOT,	"Spawns a temporary Health Cabinet at your crosshair.");
	RegAdminCmd("sm_cabinetsave",		CmdCabinetSave,		ADMFLAG_ROOT, 	"Spawns a Health Cabinet at your crosshair and saves to config.");
	RegAdminCmd("sm_cabinetlist",		CmdCabinetList,		ADMFLAG_ROOT, 	"Displays a list of Health Cabinets spawned by the plugin and their locations.");
	RegAdminCmd("sm_cabinetdel",		CmdCabinetDelete,	ADMFLAG_ROOT, 	"Removes the Health Cabinet you are nearest to and deletes from the config if saved.");
	RegAdminCmd("sm_cabinetclear",		CmdCabinetClear,	ADMFLAG_ROOT, 	"Removes all Health Cabinets from the current map.");
	RegAdminCmd("sm_cabinetwipe",		CmdCabinetWipe,		ADMFLAG_ROOT, 	"Removes all Health Cabinets from the current map and deletes them from the config.");
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	PrecacheModel(MODEL_CABINET);
}

public OnMapEnd()
{
	ResetPlugin();
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

ResetPlugin()
{
	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		DeleteEntity(i);

		g_iEntities[i] = 0;
		g_iCabinetItems[i][0] = 0;
		g_iCabinetItems[i][1] = 0;
		g_iCabinetItems[i][2] = 0;
		g_iCabinetItems[i][3] = 0;
	}
}

DeleteEntity(index)
{
	new entity = g_iEntities[index];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	entity = g_iCabinetItems[index][0];
	if( IsValidEntRef(entity) )
	{
		if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1 )
			AcceptEntityInput(entity, "Kill");
	}
	entity = g_iCabinetItems[index][1];
	if( IsValidEntRef(entity) )
	{
		if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1 )
			AcceptEntityInput(entity, "Kill");
	}
	entity = g_iCabinetItems[index][2];
	if( IsValidEntRef(entity) )
	{
		if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1 )
			AcceptEntityInput(entity, "Kill");
	}
	entity = g_iCabinetItems[index][3];
	if( IsValidEntRef(entity) )
	{
		if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1 )
			AcceptEntityInput(entity, "Kill");
	}
}



// ====================================================================================================
//					C V A R S
// ====================================================================================================
public OnConfigsExecuted()
{
	GetCvars();
	IsAllowed();
}

GetCvars()
{
	if( g_bLeft4Dead == false )
		g_iCvarGlow =	GetConVarInt(g_hCvarGlow);
	g_iCvarMax =	GetConVarInt(g_hCvarMax);
	g_iCvarMin =	GetConVarInt(g_hCvarMin);
	g_iCvarRandom =	GetConVarInt(g_hCvarRandom);
	g_iCvarType =	GetConVarInt(g_hCvarType);
	g_iCvarType1 =	GetConVarInt(g_hCvarType1);
	g_iCvarType2 =	GetConVarInt(g_hCvarType2);
}

public ConVarChanged_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

IsAllowed()
{
	new bool:bAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		g_bLoaded = false;
		GetCvars();
		LoadCabinets();
		HookEvents();
	}
	else if( g_bCvarAllow == true && (bAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
		UnhookEvents();
	}
}

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	// Get game mode cvars, if empty allow.
	decl String:sGameMode[32], String:sGameModes[64];
	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strlen(sGameModes) == 0 )
		return true;

	// Better game mode check: ",versus," instead of "versus", which would return true for "teamversus" for example.
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	return (StrContains(sGameModes, sGameMode, false) != -1);
}



// ====================================================================================================
//					E V E N T S
// ====================================================================================================
HookEvents()
{
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd);
	HookEvent("player_spawn",			Event_PlayerSpawn);
	HookEvent("player_use",				Event_PlayerUse);
}

UnhookEvents()
{
	UnhookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	UnhookEvent("round_end",			Event_RoundEnd);
	UnhookEvent("player_spawn",			Event_PlayerSpawn);
	UnhookEvent("player_use",			Event_PlayerUse);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetPlugin();

	if( g_iRoundStart == 0 && g_iPlayerSpawn == 1 )
		LoadCabinets();
	g_iRoundStart = 1;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iRoundStart == 1 && g_iPlayerSpawn == 0 )
		LoadCabinets();
	g_iPlayerSpawn = 1;
}

LoadCabinets()
{
	if( g_bLoaded == true ) return;
	g_bLoaded = true;

	if( g_iCvarRandom == 0 )
		return;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	new Handle:hFile = CreateKeyValues("cabinet");
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
	new index, i, iRandom = g_iCvarRandom;
	new iIndexes[MAX_ALLOWED+1];
	if( iCount > MAX_ALLOWED )
		iCount = MAX_ALLOWED;

	// Spawn all saved cabinets or create random
	if( iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( i = 1; i <= iCount; i++ )
			iIndexes[i] = i;

		SortIntegers(iIndexes, iCount+1, Sort_Random);
		iCount = iRandom;
	}

	// Get the cabinets origins and spawn
	decl String:sTemp[10], Float:vPos[3], Float:vAng[3];
	new type, type1, type2;

	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i];
		else index = i;

		Format(sTemp, sizeof(sTemp), "angle_%d", index);
		KvGetVector(hFile, sTemp, vAng);
		Format(sTemp, sizeof(sTemp), "origin_%d", index);
		KvGetVector(hFile, sTemp, vPos);
		Format(sTemp, sizeof(sTemp), "type_%d", index);
		type = KvGetNum(hFile, sTemp);
		Format(sTemp, sizeof(sTemp), "type1_%d", index);
		type1 = KvGetNum(hFile, sTemp);
		Format(sTemp, sizeof(sTemp), "type2_%d", index);
		type2 = KvGetNum(hFile, sTemp);

		if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
			LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
		else
			SpawnCabinet(vAng, vPos, type, type1, type2);
	}

	CloseHandle(hFile);
}

SetupCabinet(client, Float:vAng[3] = NULL_VECTOR, Float:vPos[3] = NULL_VECTOR, type = 0, type1 = 0, type2 = 0)
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

		SpawnCabinet(vAng, vPos, type, type1, type2);
	}
	else
	{
		CloseHandle(trace);
	}
}

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )
		return false;
	return true;
}

SpawnCabinet(Float:vAng[3], Float:vPos[3], type = 0, type1 = 0, type2 = 0)
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

	if( index == -1 ) return;


	new entity = CreateEntityByName("prop_health_cabinet");
	g_iEntities[index] = EntIndexToEntRef(entity);
	SetEntityModel(entity, MODEL_CABINET);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);

	g_iCabinetType[index][0] = type;
	g_iCabinetType[index][1] = type1;
	g_iCabinetType[index][2] = type2;

	if( g_iCvarGlow && g_bLeft4Dead == false )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		ChangeEdictState(entity, g_iOffsetGlow);
		AcceptEntityInput(entity, "StartGlowing");
	}
}

public Action:Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new target = GetEventInt(event, "targetid");

	if( target > 0 && IsValidEntity(target) )
	{
		new entity = EntIndexToEntRef(target);
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

		new random = GetRandomInt(g_iCvarMin, g_iCvarMax);
		if( random )
		{
			new type = g_iCabinetType[index][0];
			if( type == 0 )
				type = g_iCvarType;
			new type1 = g_iCabinetType[index][1];
			if( type1 == 0 )
				type1 = g_iCvarType1;
			new type2 = g_iCabinetType[index][2];
			if( type2 == 0 )
				type2 = g_iCvarType2;

			decl Float:vTempPos[3], Float:vAng[3], Float:vPos[3];
			new select[5], selected;
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);

			for( new u = 1; u <= 4; u++ )
				select[u] = u;
			SortIntegers(select, 5, Sort_Random);

			for( new i = 0; i < random; i++ )
			{
				if(GetRandomInt(2, 100) <= type )
				{
					if( GetRandomInt(2, 100) <= type1 )
						entity = CreateEntityByName("weapon_pain_pills");
					else
						entity = CreateEntityByName("weapon_adrenaline");
				}
				else
				{
					if( GetRandomInt(2, 100) <= type2 )
						entity = CreateEntityByName("weapon_first_aid_kit");
					else
						entity = CreateEntityByName("weapon_defibrillator");
				}
				DispatchKeyValue(entity, "solid", "0");

				g_iCabinetItems[index][i] = EntIndexToEntRef(entity);

				selected = select[i+1];
				vTempPos = vPos;
				MoveForward(vTempPos, vAng, vTempPos, 3.0);

				if( selected == 1 )
				{
					MoveSideway(vTempPos, vAng, vTempPos, -9.0);
					vTempPos[2] += 37.0;
				}
				else if( selected == 2 )
				{
					MoveSideway(vTempPos, vAng, vTempPos, 9.0);
					vTempPos[2] += 37.0;
				}
				else if( selected == 3 )
				{
					MoveSideway(vTempPos, vAng, vTempPos, 9.0);
					vTempPos[2] += 51.0;
				}
				else if( selected == 4 )
				{
					MoveSideway(vTempPos, vAng, vTempPos, -9.0);
					vTempPos[2] += 51.0;
				}

				DispatchSpawn(entity);
				TeleportEntity(entity, vTempPos, vAng, NULL_VECTOR);
				SetEntityMoveType(entity, MOVETYPE_PUSH);
			}
		}
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
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new type, type1, type2;
	if( args == 1 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
	}
	else if( args == 2 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
	}
	else if( args == 3 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
	}

	decl Float:vAng[3], Float:vPos[3];
	SetupCabinet(client, vAng, vPos, type, type1, type2);
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
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server..");
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
	new Handle:hFile = CreateKeyValues("cabinet");
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


	new type, type1, type2;
	if( args == 1 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
	}
	else if( args == 2 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
	}
	else if( args == 3 )
	{
		decl String:sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
	}

	decl Float:vAng[3], Float:vPos[3];
	SetupCabinet(client, vAng, vPos, type, type1, type2);

	// Save count
	iCount++;
	KvSetNum(hFile, "num", iCount);
	
	// Save angle / origin
	decl String:sTemp[12];
	Format(sTemp, sizeof(sTemp), "angle_%d", iCount);
	KvSetVector(hFile, sTemp, vAng);
	Format(sTemp, sizeof(sTemp), "origin_%d", iCount);
	KvSetVector(hFile, sTemp, vPos);
	if( type )
	{
		Format(sTemp, sizeof(sTemp), "type_%d", iCount);
		KvSetNum(hFile, sTemp, type);
	}
	if( type1 )
	{
		Format(sTemp, sizeof(sTemp), "type1_%d", iCount);
		KvSetVector(hFile, sTemp, vPos);
		KvSetNum(hFile, sTemp, type1);
	}
	if( type2 )
	{
		Format(sTemp, sizeof(sTemp), "type2_%d", iCount);
		KvSetVector(hFile, sTemp, vPos);
		KvSetNum(hFile, sTemp, type2);
	}

	// Save cfg
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
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
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new ent, index = -1, Float:vDistance, Float:vDistanceLast = 250.0;
	decl Float:vEntPos[3], Float:vPos[3], Float:vAng[3];
	GetClientAbsOrigin(client, vAng);

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iEntities[i];
		if( IsValidEntRef(ent) )
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
		PrintToChat(client, "%sCannot find a Health Cabinet nearby to delete!", CHAT_TAG);
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

	new Handle:hFile = CreateKeyValues("cabinet");
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

	new bool:bMove, type, type1,type2;
	decl String:sTemp[10];

	// Move the other entries down
	for( new i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "origin_%d", i);
		KvGetVector(hFile, sTemp, vPos);

		if( !bMove )
		{
			if( GetVectorDistance(vPos, vEntPos) <= 1.0 )
			{
				KvDeleteKey(hFile, sTemp);
				Format(sTemp, sizeof(sTemp), "angle_%d", i);
				KvDeleteKey(hFile, sTemp);
				Format(sTemp, sizeof(sTemp), "type_%d", i);
				KvDeleteKey(hFile, sTemp);
				Format(sTemp, sizeof(sTemp), "type1_%d", i);
				KvDeleteKey(hFile, sTemp);
				Format(sTemp, sizeof(sTemp), "type2_%d", i);
				KvDeleteKey(hFile, sTemp);

				DeleteEntity(index);
				bMove = true;
			}
			else if ( i == iCount ) // None... exit
			{
				PrintToChat(client, "%sWarning: Cannot find the Health Cabinet inside the config.", CHAT_TAG);
				CloseHandle(hFile);
				return Plugin_Handled;
			}
		}
		else
		{
			// Delete above key
			KvDeleteKey(hFile, sTemp);
			Format(sTemp, sizeof(sTemp), "angle_%d", i);
			KvGetVector(hFile, sTemp, vAng);
			KvDeleteKey(hFile, sTemp);
			Format(sTemp, sizeof(sTemp), "type_%d", i);
			type = KvGetNum(hFile, sTemp);
			KvDeleteKey(hFile, sTemp);
			Format(sTemp, sizeof(sTemp), "type1_%d", i);
			type1 = KvGetNum(hFile, sTemp);
			KvDeleteKey(hFile, sTemp);
			Format(sTemp, sizeof(sTemp), "type2_%d", i);
			type2 = KvGetNum(hFile, sTemp);
			KvDeleteKey(hFile, sTemp);

			// Save data to previous id
			Format(sTemp, sizeof(sTemp), "angle_%d", i-1);
			KvSetVector(hFile, sTemp, vAng);
			Format(sTemp, sizeof(sTemp), "origin_%d", i-1);
			KvSetVector(hFile, sTemp, vPos);

			if( type )
			{
				Format(sTemp, sizeof(sTemp), "type_%d", i-1);
				KvSetNum(hFile, sTemp, type);
			}
			if( type1 )
			{
				Format(sTemp, sizeof(sTemp), "type1_%d", i-1);
				KvSetNum(hFile, sTemp, type1);
			}
			if( type2 )
			{
				Format(sTemp, sizeof(sTemp), "type2_%d", i-1);
				KvSetNum(hFile, sTemp, type2);
			}
		}
	}

	iCount--;
	KvSetNum(hFile, "num", iCount);

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(\x05%d/%d\x01) - Health Cabinet removed from config.", CHAT_TAG, iCount, MAX_ALLOWED);
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
	PrintToChat(client, "%sAll Health Cabinets removed from the map.", CHAT_TAG);
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
		ReplyToCommand(client, "[Health Cabinet] Commands may only be used in-game on a dedicated server..");
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
	new Handle:hFile = CreateKeyValues("cabinet");
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

IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}