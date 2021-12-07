/*
	[SPAWN<>TOOLS<>7]
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define VERSION "0.9bs"

public Plugin:myinfo =
{
	name = "spawntools7",
	author = "meng",
	description = "spawn point reading tool",
	version = VERSION,
	url = ""
}

new Handle:KillSpawnsADT;
new Handle:CustSpawnsADT;
new String:MapCfgPath[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	CreateConVar("sm_spawntools7_version", VERSION, "Spawn Tools 7 Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	decl String:configspath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configspath, sizeof(configspath), "configs/spawntools7");
	if (!DirExists(configspath))
		CreateDirectory(configspath, 0x0265);

	KillSpawnsADT = CreateArray(3);
	CustSpawnsADT = CreateArray(5);
}

public OnMapStart()
{
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	BuildPath(Path_SM, MapCfgPath, sizeof(MapCfgPath), "configs/spawntools7/%s.cfg", mapName);
	ReadConfig();
}

ReadConfig()
{
	new Handle:kv = CreateKeyValues("ST7Root");
	if (FileToKeyValues(kv, MapCfgPath))
	{
		new num;
		decl String:sBuffer[32], Float:fVec[3], Float:DataFloats[5];
		if (KvGetNum(kv, "remdefsp"))
		{
			RemoveAllDefaultSpawns();
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", num);
			KvGetVector(kv, sBuffer, fVec);
			while (fVec[0] != 0.0)
			{
				RemoveSingleDefaultSpawn(fVec);
				PushArrayArray(KillSpawnsADT, fVec);
				num++;
				Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", num);
				KvGetVector(kv, sBuffer, fVec);
			}
		}
		num = 0;
		Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", num);
		KvGetVector(kv, sBuffer, fVec);
		while (fVec[0] != 0.0)
		{
			DataFloats[0] = fVec[0];
			DataFloats[1] = fVec[1];
			DataFloats[2] = fVec[2];
			Format(sBuffer, sizeof(sBuffer), "ns:%d:ang", num);
			DataFloats[3] = KvGetFloat(kv, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "ns:%d:team", num);
			DataFloats[4] = KvGetFloat(kv, sBuffer);
			CreateSpawn(DataFloats, false);
			PushArrayArray(CustSpawnsADT, DataFloats);
			num++;
			Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", num);
			KvGetVector(kv, sBuffer, fVec);
		}
	}

	CloseHandle(kv);
}

RemoveAllDefaultSpawns()
{
	new maxent = GetMaxEntities();
	decl String:sClassName[64];
	for (new i = MaxClients; i < maxent; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)) &&
		(StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
			RemoveEdict(i);
	}
}

RemoveSingleDefaultSpawn(Float:fVec[3])
{
	new maxent = GetMaxEntities();
	decl String:sClassName[64], Float:ent_fVec[3];
	for (new i = MaxClients; i < maxent; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)) &&
		(StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
		{
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", ent_fVec);
			if (fVec[0] == ent_fVec[0])
			{
				RemoveEdict(i);
				break;
			}
		}
	}
}

CreateSpawn(Float:DataFloats[5], bool:isNew)
{
	decl Float:posVec[3], Float:angVec[3];
	posVec[0] = DataFloats[0];
	posVec[1] = DataFloats[1];
	posVec[2] = DataFloats[2];
	angVec[0] = 0.0;
	angVec[1] = DataFloats[3];
	angVec[2] = 0.0;

	new entity = CreateEntityByName(DataFloats[4] == 2.0 ? "info_player_terrorist" : "info_player_counterterrorist");
	if (DispatchSpawn(entity))
	{
		TeleportEntity(entity, posVec, angVec, NULL_VECTOR);
		if (isNew)
			PushArrayArray(CustSpawnsADT, DataFloats);

		return true;
	}

	return false;
}

public OnMapEnd()
{
	ClearArray(KillSpawnsADT);
	ClearArray(CustSpawnsADT);
}