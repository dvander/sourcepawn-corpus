#pragma newdecls required
#pragma semicolon 1
#define PLUGIN_VERSION "2.3.1"
#include <sourcemod>
#include <sdktools>

enum {
	OBJ_DISPENSER,
	OBJ_TELEPORTER,
	OBJ_SENTRY
}

ConVar
	  cvarEnabled
	, cvarSentryLevel
	, cvarDispenserLevel
	, cvarTeleportLevel
	, cvarDisableTeleCollision
	, cvarAdminOnly;
Handle
	  g_hSDKStartBuilding
	, g_hSDKFinishBuilding
	, g_hSDKStartUpgrading
	, g_hSDKFinishUpgrading;

public Plugin myinfo = {
	name = "Sentry Quick Build", 
	author = "JoinedSenses", 
	description = "Enable quick build of sentries", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/JoinedSenses"
};

// --------------- SM API

public void OnPluginStart() {
	CreateConVar("sm_quickbuild_version", PLUGIN_VERSION, "Sentry Quickbuild Version",  FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_quickbuild_enable", "1", "Enables/disables engineer quick build", FCVAR_NOTIFY);
	cvarSentryLevel = CreateConVar("qb_sentrylevel", "1", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	cvarDispenserLevel = CreateConVar("qb_dispenserlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	cvarTeleportLevel = CreateConVar("qb_teleportlevel", "3", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	cvarDisableTeleCollision = CreateConVar("qb_disabletelecollision", "1", "Prevents other players from colliding with teles", FCVAR_NOTIFY);
	cvarAdminOnly = CreateConVar("qb_adminonly", "0", "Should admins only be able to quick build?");
	
	RegAdminCmd("sm_quickbuild", cmdQuickBuild, ADMFLAG_ROOT);
	RegAdminCmd("sm_sentrylevel", cmdSentryLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_dispenserlevel", cmdDispenserLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_teleportlevel", cmdTeleportLevel, ADMFLAG_ROOT);
	
	cvarEnabled.AddChangeHook(cvarEnableChanged);
	cvarSentryLevel.AddChangeHook(cvarChanged);
	cvarDispenserLevel.AddChangeHook(cvarChanged);
	cvarTeleportLevel.AddChangeHook(cvarChanged);
	
	HookEvent("player_builtobject", eventObjectBuilt);
	HookEvent("player_upgradedobject", eventUpgradedObject);
	
	FindConVar("tf_cheapobjects").SetInt(1);
	
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/buildings.txt");
	if(FileExists(sFilePath)) {
		Handle hGameConf = LoadGameConfigFile("buildings");
		if(hGameConf != INVALID_HANDLE ) {
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::StartBuilding");
			g_hSDKStartBuilding = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::FinishedBuilding");
			g_hSDKFinishBuilding = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::StartUpgrading");
			g_hSDKStartUpgrading = EndPrepSDKCall();
			
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::FinishUpgrading");
			g_hSDKFinishUpgrading = EndPrepSDKCall();
			
			delete hGameConf;
		}
		if (g_hSDKStartBuilding == null || g_hSDKFinishBuilding == null || g_hSDKStartUpgrading == null || g_hSDKFinishUpgrading == null) {
			LogError("Failed to load gamedata/buildings.txt. Instant building and upgrades will not be available.");
		}
	}
}

// --------------- CVAR Hook

public void cvarEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (StringToInt(newValue) == 1) {
		return;
	}
	convar.SetInt(0);
}

public void cvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (0 < StringToInt(newValue) <= 3) {
		return;
	}
	convar.SetInt(1);
}

// --------------- Commands

public Action cmdQuickBuild(int client, int args) {
	if (args == 0) {
		cvarEnabled.SetInt(!cvarEnabled.BoolValue);
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	if (StrEqual(sArg, "enable") || StrEqual(sArg, "enabled") || StrEqual(sArg, "1")) {
		cvarEnabled.SetInt(1);
	}
	else if (StrEqual(sArg, "disable") || StrEqual(sArg, "disabled") || StrEqual(sArg, "0")) {
		cvarEnabled.SetInt(0);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Try enable, disable, 0, or 1");
	}
	return Plugin_Handled;
}

public Action cmdSentryLevel(int client, int args) {
	if (args == 0) {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if ( 0 < iArg <= 3) {
		cvarSentryLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}
	return Plugin_Handled;
}

public Action cmdDispenserLevel(int client, int args) {
	if (args == 0) {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if ( 0 < iArg <= 3) {
		cvarDispenserLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}
	return Plugin_Handled;
}

public Action cmdTeleportLevel(int client, int args) {
	if (args == 0) {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArgString(sArg, sizeof(sArg));

	int iArg = StringToInt(sArg);

	if ( 0 < iArg <= 3) {
		cvarTeleportLevel.SetInt(iArg);
	}
	else {
		ReplyToCommand(client, "Incorrect parameters. Requires 1, 2, or 3");
	}
	return Plugin_Handled;
}

// --------------- Events

public Action eventObjectBuilt(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarEnabled.BoolValue) {
		return Plugin_Continue;
	}
	
	int owner = GetClientOfUserId(event.GetInt("userid"));
	int obj = event.GetInt("object");
	int index = event.GetInt("index");
	
	if (g_hSDKStartBuilding == null || g_hSDKFinishBuilding == null || g_hSDKStartUpgrading == null || g_hSDKFinishUpgrading == null) {
		return Plugin_Continue;
	}

	if (cvarAdminOnly.BoolValue && !CheckCommandAccess(owner, "sm_quickbuild", ADMFLAG_GENERIC)) {
		return Plugin_Continue;
	}
		
	RequestFrame(FrameCallback_StartBuilding, index);
	RequestFrame(FrameCallback_FinishBuilding, index);
	
	int maxupgradelevel = GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel");
	switch (obj) {
		case OBJ_DISPENSER: {
			if (maxupgradelevel >  cvarDispenserLevel.IntValue) {
				SetEntProp(index, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
				RequestFrame(FrameCallback_FinishUpgrading, index);
			}
			else if(cvarDispenserLevel.IntValue != 1) {
				SetEntProp(index, Prop_Send, "m_iUpgradeLevel", cvarDispenserLevel.IntValue-1);
				SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", cvarDispenserLevel.IntValue-1);
				RequestFrame(FrameCallback_StartUpgrading, index);
				RequestFrame(FrameCallback_FinishUpgrading, index);
			}
		}
		case OBJ_TELEPORTER: {
			if (maxupgradelevel >  cvarTeleportLevel.IntValue) {
				SetEntProp(index, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
				RequestFrame(FrameCallback_FinishUpgrading, index);
			}
			else if(cvarTeleportLevel.IntValue != 1) {
				SetEntProp(index, Prop_Send, "m_iUpgradeLevel", cvarTeleportLevel.IntValue-1);
				SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", cvarTeleportLevel.IntValue-1);
				RequestFrame(FrameCallback_StartUpgrading, index);
				RequestFrame(FrameCallback_FinishUpgrading, index);
			}
			if (cvarDisableTeleCollision.BoolValue) {
				SetEntProp(index, Prop_Send, "m_CollisionGroup", 2);	
			}
		}
		case OBJ_SENTRY: {
			int mini = GetEntProp(index, Prop_Send, "m_bMiniBuilding");
			if (mini == 1) {
				return Plugin_Continue;
			}
			if (maxupgradelevel >  cvarSentryLevel.IntValue) {
				SetEntProp(index, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
				RequestFrame(FrameCallback_FinishUpgrading, index);
			}
			else if(cvarSentryLevel.IntValue != 1) {
				SetEntProp(index, Prop_Send, "m_iUpgradeLevel", cvarSentryLevel.IntValue-1);
				SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", cvarSentryLevel.IntValue-1);
				RequestFrame(FrameCallback_StartUpgrading, index);
				RequestFrame(FrameCallback_FinishUpgrading, index);
			}
		}
	}

	SetEntProp(index, Prop_Send, "m_iUpgradeMetalRequired", 0);
	SetVariantInt(GetEntProp(index, Prop_Data, "m_iMaxHealth"));
	AcceptEntityInput(index, "SetHealth");
	return Plugin_Continue;
}

public Action eventUpgradedObject(Event event, const char[] sName, bool bDontBroadcast) {
	if (!cvarEnabled.BoolValue) {
		return Plugin_Continue;
	}
	int owner = GetClientOfUserId(event.GetInt("userid"));
	if (cvarAdminOnly.BoolValue && !CheckCommandAccess(owner, "sm_quickbuild", ADMFLAG_GENERIC)) {
		return Plugin_Continue;
	}
	if (g_hSDKFinishUpgrading != null) {
		int entity = event.GetInt("index");
		RequestFrame(FrameCallback_FinishUpgrading, entity);
	}
	return Plugin_Continue;
}

// --------------- VFunction Callbacks

public void FrameCallback_StartBuilding(any entity) {
	SDKCall(g_hSDKStartBuilding, entity);
}

public void FrameCallback_FinishBuilding(any entity) {
	SDKCall(g_hSDKFinishBuilding, entity);
}

public void FrameCallback_StartUpgrading(any entity) {
	SDKCall(g_hSDKStartUpgrading, entity);
}

public void FrameCallback_FinishUpgrading(any entity) {
	SDKCall(g_hSDKFinishUpgrading, entity);
}