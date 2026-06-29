#define PLUGIN_NAME "[L4D2] Force L4D2 arms and icons"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Force L4D2 arms and icons for all maps"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=345947"
#define PLUGIN_NAME_SHORT "Force L4D2 arms and icons"
#define PLUGIN_NAME_TECH "forcel4d2_viewmdl"

#define ENFORCESET 1
#define smxFileName1 "forceset"
#define smxFileName2 "l4d_info_editor"

#define AUTOEXEC_CFG "L4D2_arms"

#include <sourcemod>
#include <sdktools>
#if ENFORCESET
#undef REQUIRE_PLUGIN
#include <left4dhooks>
#endif

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

ConVar g_cvForceSet;
bool g_bForceSet;
ConVar mp_gamemode, sv_consistency, sv_disable_glow_survivors, sv_disable_glow_faritems;
bool g_bIsC2M2 = false;
bool g_bDontForceSet = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public void OnAllPluginsLoaded()
{
	Handle hFoundPlugin = FindPluginByFile(smxFileName1);
	if (hFoundPlugin != INVALID_HANDLE)
	{
		PrintToServer("L4D2Arms: %s plugin found, L4D2 Arms plugin's forceset functionality disabled", smxFileName1);
		g_bDontForceSet = true;
	}

	hFoundPlugin = FindPluginByFile(smxFileName2);
	if (hFoundPlugin != INVALID_HANDLE)
	{
		PrintToServer("L4D2Arms: %s plugin found, L4D2 Arms plugin's forceset functionality disabled", smxFileName2);
		g_bDontForceSet = true;
	}
}

public void OnPluginStart()
{
	ConVar version_cvar = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_version", PLUGIN_VERSION, PLUGIN_NAME_SHORT..." version.", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	#if ENFORCESET
	g_cvForceSet = CreateConVar("sm_"...PLUGIN_NAME_TECH..."_forceset2", "1", "(REQUIRES LEFT 4 DHOOKS)\nForces survivor set to 2.\nDisables itself if l4d_info_editor.smx OR forceset.smx plugins are loaded.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvForceSet.AddChangeHook(CC_2ARMS_ForceSet);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
	#endif
	
	mp_gamemode = FindConVar("mp_gamemode");
	if ( mp_gamemode == null )
		SetFailState("mp_gamemode ConVar not found");
	sv_consistency = FindConVar("sv_consistency");
	if ( sv_consistency == null )
		PrintToServer("sv_consistency ConVar not found");
	sv_disable_glow_survivors = FindConVar("sv_disable_glow_survivors");
	if ( sv_disable_glow_survivors == null )
		PrintToServer("sv_disable_glow_survivors ConVar not found");
	sv_disable_glow_faritems = FindConVar("sv_disable_glow_faritems");
	if ( sv_disable_glow_faritems == null )
		PrintToServer("sv_disable_glow_faritems ConVar not found");
	
	OnMapStart();
	
	HookEvent("player_first_spawn", gamemode_restore, EventHookMode_Post);
	HookEvent("player_transitioned", gamemode_restore, EventHookMode_Post);
}

#if ENFORCESET
void CC_2ARMS_ForceSet(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_bForceSet =		convar.BoolValue;	}
void SetCvarValues()
{
	CC_2ARMS_ForceSet(g_cvForceSet, "", "");
}
#endif

public void OnMapStart()
{
	// ShootZones has one available map that it's set to work on
	// It doesn't seem to have the improper L4D1 arms + icons problem, but
	// just in case use a different mode
	char mapName[18];
	GetCurrentMap(mapName, sizeof(mapName));
	if (strcmp(mapName, "c2m2_fairgrounds", false) == 0)
		g_bIsC2M2 = true;
}

void gamemode_restore(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid", 0);
	int client = GetClientOfUserId(userid);
	if (client == 0 || IsFakeClient(client)) return;
	
	// RF helped with alternative method - previous method relied on player_connect_full
	// with 5 sec delay but wasn't reliable enough
	// https://steamcommunity.com/profiles/76561198039186809/
	CreateTimer(5.0, ResetGameModeDelay, userid);
}

Action ResetGameModeDelay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0 || IsFakeClient(client)) return Plugin_Continue;
	char oldGamemode[128];
	mp_gamemode.GetString(oldGamemode, sizeof(oldGamemode));
	
	PrintToServer("L4D2Arms: Setting gamemode of %N to %s", client, oldGamemode);
	SendConVarValue(client, mp_gamemode, oldGamemode);
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if (client == 0 || IsFakeClient(client)) return;
	
	switch (g_bIsC2M2)
	{
		case true:
		{
			PrintToServer("L4D2Arms: Setting gamemode of %N to dash", client);
			SendConVarValue(client, mp_gamemode, "dash");
		}
		default:
		{
			PrintToServer("L4D2Arms: Setting gamemode of %N to shootzones", client);
			SendConVarValue(client, mp_gamemode, "shootzones");
		}
	}
	char strVal[8];
	sv_consistency.GetString(strVal, sizeof(strVal));
	SendConVarValue(client, sv_consistency, strVal);
	sv_disable_glow_survivors.GetString(strVal, sizeof(strVal));
	SendConVarValue(client, sv_disable_glow_survivors, strVal);
	sv_disable_glow_faritems.GetString(strVal, sizeof(strVal));
	SendConVarValue(client, sv_disable_glow_faritems, strVal);
}

#if ENFORCESET
public Action L4D_OnGetSurvivorSet(int& retVal)
{
	if (g_bDontForceSet)
		return Plugin_Continue;
	
	if (g_bForceSet)
	{
		retVal = 2;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action L4D_OnFastGetSurvivorSet(int& retVal)
{
	if (g_bDontForceSet)
		return Plugin_Continue;
	
	if (g_bForceSet)
	{
		retVal = 2;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
#endif
