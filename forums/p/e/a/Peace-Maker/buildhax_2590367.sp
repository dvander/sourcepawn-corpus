#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <dhooks>

#define PLUGIN_VERSION "0.4"

#define BUILDING_DISPENSER				(1 << 1)
#define BUILDING_SENTRY					(1 << 2)
#define BUILDING_TELEPORTER_ENTRANCE	(1 << 3)
#define BULIDING_TELEPORTER_EXIT		(1 << 4)

#define DISPENSER 0
#define TELEPORTER 1
#define SENTRY 2

#define MODE_ENTRANCE 0
#define MODE_EXIT 1

ConVar g_Enabled;
ConVar g_TeamCheck;

bool g_bOverride = false;
int g_iCurrentTeam;
int g_nOffsetType;
int g_nOffsetMode;
int g_nOffsetTeamObject;

public Plugin myinfo = 
{
	name = "Building Hacks",
	author = "linux_lover",
	description = "Detours building placement in respawn.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=102731",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "Cannot run on other mods than TF2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("building_version", PLUGIN_VERSION, "Building Hacks Version", FCVAR_NOTIFY);
	g_Enabled = CreateConVar("building_enabled", "14");
	g_TeamCheck = CreateConVar("building_teamcheck", "1");

	Handle hGameConf = LoadGameConfigFile("teleport");
	if (!hGameConf)
		SetFailState("Could not read teleport.txt");

	g_nOffsetType = FindSendPropInfo("CBaseObject", "m_iObjectType");
	if (g_nOffsetType <= 0)
		SetFailState("Could not find offset for m_iObjectType.");
	LogMessage("Offset for m_iObjectType: %d", g_nOffsetType);

	g_nOffsetMode = FindSendPropInfo("CBaseObject", "m_iObjectMode");
	if (g_nOffsetMode <= 0)
		SetFailState("Could not find offset for m_iObjectMode.");
	LogMessage("Offset for m_iObjectMode: %d", g_nOffsetMode);

	g_nOffsetTeamObject = FindSendPropInfo("CBaseEntity", "m_iTeamNum");
	if (g_nOffsetTeamObject <= 0)
		SetFailState("Could not find offset for m_iTeamNum.");
	LogMessage("Offset for m_iTeamNum: %d", g_nOffsetTeamObject);


	// Detour for bool CBaseObject::EstimateValidBuildPos(void)
	Handle hBuildingDetour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_Address);
	if (!hBuildingDetour)
		SetFailState("Could not initalize EstimateValidBuildPos detour.");

	if (!DHookSetFromConf(hBuildingDetour, hGameConf, SDKConf_Signature, "EstimateValidBuildPos"))
		SetFailState("Failed to find CBaseObject::EstimateValidBuildPos signature.");

	if (!DHookEnableDetour(hBuildingDetour, false, Detour_OnEstimateValidBuildPos))
		SetFailState("Failed to detour CBaseObject::EstimateValidBuildPos.");

	if (!DHookEnableDetour(hBuildingDetour, true, Detour_OnEstimateValidBuildPos_Post))
		SetFailState("Failed to detour CBaseObject::EstimateValidBuildPos post.");

	LogMessage("EstimateValidBuildPos detour enabled.");

	// Detour for bool CBaseTrigger::PointIsWithin(Vector  const&)
	Handle hRespawnDetour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_Address);
	if (!hRespawnDetour)
		SetFailState("Could not initalize PointIsWithin detour.");

	if (!DHookSetFromConf(hRespawnDetour, hGameConf, SDKConf_Signature, "PointIsWithin"))
		SetFailState("Failed to find CBaseTrigger::PointIsWithin signature.");

	DHookAddParam(hRespawnDetour, HookParamType_VectorPtr);

	if (!DHookEnableDetour(hRespawnDetour, false, Detour_OnPointIsWithin))
		SetFailState("Failed to detour CBaseTrigger::PointIsWithin.");

	LogMessage("PointIsWithin detour enabled.");

	// TODO: SentryPatch
}

MRESReturn Detour_OnEstimateValidBuildPos(Address pThis, Handle hReturn)
{
	Address addrType = pThis + view_as<Address>(g_nOffsetType);
	int nType = LoadFromAddress(addrType, NumberType_Int8);
	Address addrMode = pThis + view_as<Address>(g_nOffsetMode);
	int nMode = LoadFromAddress(addrMode, NumberType_Int8);
	Address addrTeam = pThis + view_as<Address>(g_nOffsetTeamObject);
	g_iCurrentTeam = LoadFromAddress(addrTeam, NumberType_Int8);

	// LogMessage("m_iObjectType : %d m_iObjectMode : %d m_iTeamNum: %d", nType, nMode, g_iCurrentTeam);

	int nValue = g_Enabled.IntValue;
	g_bOverride = false;

	if (nValue & BUILDING_TELEPORTER_ENTRANCE && nType == TELEPORTER && nMode == MODE_ENTRANCE)
	{
		g_bOverride = true;
	}
	else if (nValue & BUILDING_DISPENSER && nType == DISPENSER)
	{
		g_bOverride = true;
	}
	else if (nValue & BUILDING_SENTRY && nType == SENTRY)
	{
		g_bOverride = true;
	}
	else if (nValue & BULIDING_TELEPORTER_EXIT && nType == TELEPORTER && nMode == MODE_EXIT)
	{
		g_bOverride = true;
	}

	return MRES_Ignored;
}

MRESReturn Detour_OnEstimateValidBuildPos_Post(Address pThis, Handle hReturn)
{
	g_bOverride = false;
	return MRES_Ignored;
}

MRESReturn Detour_OnPointIsWithin(Address pThis, Handle hReturn, Handle hParams)
{
	if (!g_bOverride)
		return MRES_Ignored;

	Address addrTeam = pThis + view_as<Address>(g_nOffsetTeamObject);
	int iTeam = LoadFromAddress(addrTeam, NumberType_Int8);
	if (g_TeamCheck.BoolValue && g_iCurrentTeam != iTeam)
		return MRES_Ignored;

	DHookSetReturn(hReturn, false);
	return MRES_Supercede;
}
