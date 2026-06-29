#define PLUGIN_VERSION		"2.1"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MODEL_ERROR 	"models/error.mdl"
#define CVAR_FLAGS		FCVAR_NOTIFY
#define DEBUG 			0

enum ENTITY_INFO_LEVEL ( <<= 1 )
{
	ENTITY_INFO_NAME = 1,
	ENTITY_INFO_CLASS,
	ENTITY_INFO_MODEL,
	ENTITY_INFO_ORIGIN,
	ENTITY_INFO_INDEX,
	ENTITY_INFO_HAMMERID,
	ENTITY_INFO_ALL = -1
}

public Plugin myinfo =
{
	name = "[ANY] Entity Limits Logger",
	author = "Dragokas",
	description = "Analyse and logs entity classes delta when the total number of entities on the map exceeds a pre-prefined maximum",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

File g_hLog;

char g_sLogPath[PLATFORM_MAX_PATH+1];

bool g_bLogged;

int g_iEntityLimit = 99999;
int g_iSnapTime;

ConVar g_hCVarUnsafeLeft;
ConVar g_hCVarDelay;

StringMap g_hSnapEntity;
StringMap g_hSnapClass;

public void OnPluginStart()
{
	CreateConVar("sm_entity_limit_log_version", PLUGIN_VERSION, "Plugin Version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hCVarUnsafeLeft = CreateConVar("sm_entity_limit_unsafe_left", "150", "Plugin creates report when the number of free entities is less than this ConVar", CVAR_FLAGS );
	g_hCVarDelay = CreateConVar("sm_entity_limit_delay", "10.0", "Delay to be used after map start to create entities snapshot for calculating the entities delta when a leak happens", CVAR_FLAGS );
	
	AutoExecConfig(true, "sm_entity_limit");
	
	g_hCVarUnsafeLeft.AddChangeHook(ConVarChanged_Cvars);
	
	GetCvars();
	
	g_hSnapEntity = new StringMap();
	g_hSnapClass = new StringMap();
	
	RegAdminCmd("sm_entlog",	CmdEntityLog, 	ADMFLAG_ROOT, "Creates entities report");
	RegAdminCmd("sm_entsnap",	CmdEntitySnap, 	ADMFLAG_ROOT, "Creates entities snapshot which is to be used for calculating the entities delta (when leak happens or sm_entlog used)");
	
	#if DEBUG
		RegAdminCmd("sm_entcrash", CmdCreateEntities, ADMFLAG_ROOT, "Creates 300 dummy entities in attempt to crash the server for test purposes");
	#endif
}

public Action CmdEntityLog(int client, int args)
{
	LogAll(client);
	return Plugin_Handled;
}

public Action CmdEntitySnap(int client, int args)
{
	MakeSnapshot();
	ReplyToCommand(client, "Entity snapshot is created.");
	return Plugin_Handled;
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iEntityLimit = GetMaxEntities() - g_hCVarUnsafeLeft.IntValue;
}

#if DEBUG
public Action CmdCreateEntities(int client, int args)
{
	const int COUNT = 300;
	int entity;
	float vOrigin[3];
	
	if( client && GetClientTeam(client) != 1 && IsPlayerAlive(client) )
	{
		GetClientAbsOrigin(client, vOrigin);
	}
	for( int i = 0; i < COUNT; i++ )
	{
		entity = CreateEntityByName("prop_dynamic_override"); // CDynamicProp
		if (entity != -1) {
			DispatchKeyValue(entity, "spawnflags", "0");
			DispatchKeyValue(entity, "solid", "0");
			DispatchKeyValue(entity, "disableshadows", "1");
			DispatchKeyValue(entity, "disablereceiveshadows", "1");
			DispatchKeyValue(entity, "model", MODEL_ERROR);
			TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "TurnOn");
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 0, 0, 0);
		}
	}
	ReplyToCommand(client, "Created %i entities. Total: %i", COUNT, GetEntityCount());
	return Plugin_Handled;
}
#endif

public void OnMapStart()
{
	g_bLogged = false;
	CreateTimer(g_hCVarDelay.FloatValue, Timer_CreateSnapshot, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CreateSnapshot(Handle timer)
{
	MakeSnapshot();
}

void MakeSnapshot()
{
	char data[300];
	int count;
	int ent = -1;

	g_iSnapTime = GetTime();
	
	g_hSnapEntity.Clear();
	g_hSnapClass.Clear();
	
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			data = GetEntityInfoString(ent, ENTITY_INFO_INDEX | ENTITY_INFO_CLASS | ENTITY_INFO_NAME);
			g_hSnapEntity.SetValue(data, 0, false);
			
			GetEntityClassname(ent, data, sizeof(data));
			count = 0;
			g_hSnapClass.GetValue(data, count);
			++ count;
			g_hSnapClass.SetValue(data, count, true);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( GetEntityCount() > g_iEntityLimit )
	{
		if( !g_bLogged )
		{
			g_bLogged = true; // log only once per map
			LogAll();
		}
	}
}

void LogAll(int client = 0)
{
	char sTime[32], sMap[64];
	FormatTime(sTime, sizeof(sTime), "%F_%H-%M-%S", GetTime());
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/entity_limit_%s.log", sTime);
	GetCurrentMap(sMap, sizeof(sMap));
	
	LogTo("Logfile of 'Entity Limit Logger' v.%s\n", PLUGIN_VERSION);
	LogTo("----------------------------------------------");
	LogTo("Map:             %s", sMap);
	FormatTime(sTime, sizeof(sTime), "%H h. %M m. %S s.", GetTime());
	LogTo("Current time:    %s", sTime);
	FormatTime(sTime, sizeof(sTime), "%H h. %M m. %S s.", g_iSnapTime);
	LogTo("Snapshot time:   %s", sTime);
	LogTo("Time passed:     %i min.", (GetTime() - g_iSnapTime) / 60);
	LogTo("----------------------------------------------");
	
	ReportDelta();
	ReportEntityTotal();
	ReportPrecacheInfo();
	ReportClientWeapon();
	
	LogTo("\nEnd of Report.");
	
	CloseLog();
	
	if( client )
		ReplyToCommand(client, "Entities log is saved to: %s", g_sLogPath);
}

void ReportDelta()
{
	LogTo("\nDELTA - {Class Count}\n" ...
		"*\n" ...
			"\tThis section describes the number of entity classes, which increased since the latest snapshot" ...
		"\n*\n");
	ReportDelta_ClassCount();
	
	LogTo("\nDELTA - {Entity List}\n" ...
		"*\n" ...
			"\tThis section describes each separate entity, created since the latest snapshot" ...
		"\n*\n");
	ReportDelta_Entities();
}

void ReportDelta_ClassCount()
{
	StringMap hSnapClassNew;
	StringMapSnapshot hEnum;
	char sClass[64];
	int count, count_old;
	
	hSnapClassNew = new StringMap();
	
	int ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			GetEntityClassname(ent, sClass, sizeof(sClass));
			count = 0;
			hSnapClassNew.GetValue(sClass, count);
			++ count;
			hSnapClassNew.SetValue(sClass, count, true);
		}
	}
	hEnum = hSnapClassNew.Snapshot();
	
	for( int i = 0; i < hEnum.Length; i++ )
	{
		hEnum.GetKey(i, sClass, sizeof(sClass));
		
		hSnapClassNew.GetValue(sClass, count);
		g_hSnapClass.GetValue(sClass, count_old);
		
		if( count > count_old )
		{
			LogTo("+%i\t%s", count - count_old, sClass);
		}
	}
	delete hEnum;
	delete hSnapClassNew;
}

void ReportDelta_Entities()
{
	char data[300];
	int ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			data = GetEntityInfoString(ent, ENTITY_INFO_INDEX | ENTITY_INFO_CLASS | ENTITY_INFO_NAME);
			
			if( !StringMap_ContainsKey(g_hSnapEntity, data) )
			{
				LogTo(GetEntityInfoString(ent, ENTITY_INFO_ALL &~ ENTITY_INFO_INDEX));
			}
		}
	}
}

void ReportEntityTotal()
{
	LogTo("\n***********************" ...
			"     TOTAL ENTITIES    " ...
			"***********************\n");
	int ent = -1, cnt = 0;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		cnt++;
	}
	LogTo("All:       %i", cnt);
	LogTo("Networked: %i", GetEntityCount());
	LogTo("");
	
	ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			LogTo(GetEntityInfoString(ent, ENTITY_INFO_ALL &~ ENTITY_INFO_INDEX));
		}
	}
}

char[] GetEntityInfoString(int entity, ENTITY_INFO_LEVEL info_level)
{
	static char sClass[64], sName[128], sIndex[8];
	static char sModel[PLATFORM_MAX_PATH];
	static float pos[3];
	
	char result[300];
	int iHammerID;
	
	pos[0] = 0.0;
	pos[1] = 0.0;
	pos[2] = 0.0;
	sModel[0] = 0;
	sName[0] = 0;
	sClass[0] = 0;
	sIndex[0] = 0;
	
	if( info_level & ENTITY_INFO_ORIGIN )
	{
		if( HasEntProp(entity, Prop_Data, "m_vecOrigin"))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
		}
	}
	if( info_level & ENTITY_INFO_MODEL )
	{
		if( HasEntProp(entity, Prop_Data, "m_ModelName") )
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		}
	}
	if( info_level & ENTITY_INFO_NAME )
	{
		if( HasEntProp(entity, Prop_Data, "m_iName") )
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
		}
	}
	if( info_level & ENTITY_INFO_CLASS )
	{
		GetEntityClassname(entity, sClass, sizeof(sClass));
	}
	if( info_level & ENTITY_INFO_INDEX )
	{
		IntToString(entity, sIndex, sizeof(sIndex));
	}
	if( info_level & ENTITY_INFO_HAMMERID )
	{
		if( HasEntProp(entity, Prop_Data, "m_iHammerID") )
		{
			iHammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
		}
	}
	FormatEx(result, sizeof(result), "%s. Name: %s. Model: %s. Origin: %.1f %.1f %.1f %s%s HammerId: %i", 
		sClass, sName, sModel, pos[0], pos[1], pos[2], sIndex[0] != 0 ? sIndex : "", IsInSafeRoom(entity) ? " (IN SAFEROOM)" : "", iHammerID);
	return result;
}

bool StringMap_ContainsKey(StringMap hMap, char[] sKey)
{
	int value;
	return hMap.GetValue (sKey, value);
}

void ReportClientWeapon()
{
	LogTo("\n***********************" ...
			"     WEAPON REPORT     " ...
			"***********************");
	LogTo("\n{Spectators}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 1 )
		{
			LogTo("%i. %N", i, i);
		}
	}
	LogTo("\n{Team 2}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
			if( IsPlayerAlive(i))
			{
				WeaponInfo(i);
			}
		}
	}
	LogTo("\n{Team 3}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
		}
	}
}

void WeaponInfo(int client)
{
	int weapon;
	char sName[32];
	for( int i = 0; i < 5; i++ )
	{
		weapon = GetPlayerWeaponSlot(client, i);
		
		if( weapon == -1 )
		{
			LogTo("Slot #%i: EMPTY", i);
		}
		else {
			GetEntityClassname(weapon, sName, sizeof(sName));
			LogTo("Slot #%i: %s", i, sName);
		}
	}
}

void ReportPrecacheInfo()
{
	LogTo("\n***********************" ...
			"     STRINGTABLE     " ...
			"***********************\n");
	
	int iTable = FindStringTable("modelprecache");
	if( iTable != INVALID_STRING_TABLE )
	{
		int iNum = GetStringTableNumStrings(iTable);
		LogTo("'modelprecache' count: %i", iNum);
	}
}

bool IsInSafeRoom(int entity)
{
	int chl = -1;
	chl = FindEntityByClassname(-1, "info_changelevel");
	if (chl == -1)
	{
		chl = FindEntityByClassname(-1, "trigger_changelevel");
		if (chl == -1)
			return false;
	}
	
	float min[3], max[3], pos[3], me[3], maxme[3];

	GetEntPropVector(chl, Prop_Send, "m_vecMins", min);
	GetEntPropVector(chl, Prop_Send, "m_vecMaxs", max);
	
	// zone expanding by Y-axis
	min[2] -= 15.0;
	max[2] += 40.0;
	
	GetEntPropVector(chl, Prop_Send, "m_vecOrigin", pos);
	
	AddVectors(min, pos, min);
	AddVectors(max, pos, max);
	
	if( HasEntProp(entity, Prop_Send, "m_vecOrigin") )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", me);
	}
	else {
		return false;
	}
	
	char g_sMap[64];
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	
	if (strcmp(g_sMap, "l4d_smalltown03_ranchhouse") == 0)
	{
		if (me[0] > -2442.0 && (175.0 < me[2] < 200.0) )
			return false;
	}
	else if (strcmp(g_sMap, "l4d_smalltown04_mainstreet") == 0)
	{
		max[2] += 20.0;
	}
	
	if( HasEntProp(entity, Prop_Send, "m_vecMaxs") )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxme);
	}
	else {
		return false;
	}
	
	AddVectors(maxme, me, maxme);
	
	return IsDotInside(me, min, max) && maxme[2] < max[2];
}

bool IsDotInside(float dot[3], float min[3], float max[3])
{
	if(	min[0] < dot[0] < max[0] &&
		min[1] < dot[1] < max[1] &&
		min[2] < dot[2] < max[2]) {
		return true;
	}
	return false;
}

void OpenLog(char[] access)
{
	g_hLog = OpenFile(g_sLogPath, access);
	if( g_hLog == null )
	{
		LogError("Failed to open or create log file: %s (access: %s)", g_sLogPath, access);
		return;
	}
}

void CloseLog()
{
	if (g_hLog) {
		g_hLog.Close();
		g_hLog = null;
	}
}

void LogTo(const char[] format, any ...)
{
	static char buffer[300];
	VFormat(buffer, sizeof(buffer), format, 2);
	if (g_hLog == null) {
		OpenLog("a+");
	}
	if (g_hLog) {
		g_hLog.WriteLine(buffer);
	}
}