#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D2] Witch Precache",
	author = "CanadaRox",
	description = "Precaches both witch models so z_spawn witch/witch_bride doesn't crash the server.",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

ConVar g_hEnabled;

public void OnPluginStart()
{
	CreateConVar("l4d2_witchprecache_version", PLUGIN_VERSION, "[L4D2] Witch Precache plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("l4d2_witchprecache_enable", "1", "Toggle precaching of witch models to prevent crashes caused by z_spawn witch/witch_bride", FCVAR_NOTIFY);
}

public void OnMapStart()
{
	if (g_hEnabled.BoolValue)
	{
		if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl");
		if (!IsModelPrecached("models/infected/witch_bride.mdl")) PrecacheModel("models/infected/witch_bride.mdl");
	}
}