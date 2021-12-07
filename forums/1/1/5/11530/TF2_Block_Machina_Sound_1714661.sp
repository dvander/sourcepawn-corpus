#pragma semicolon 1
#include <sourcemod> 

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "TF2 Block Machina Sound",
	author = "Tylerst",
	description = "Stops the Machina sound from playing on a penetration kill",
	version = PLUGIN_VERSION,
	url = "none"
}

new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_blockmachinasound_version", PLUGIN_VERSION, "Stops the Machina sound from playing on a penetration kill", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_blockmachinasound_enabled", "1", "Enable/Disable the plugin", 0, true, 0.0, true, 1.0);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookConVarChange(g_hEnabled, CvarChanged);
}

public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		g_bEnabled = false;
	}
	else
	{
		g_bEnabled = true;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (g_bEnabled)
	{
		SetEventInt(event, "playerpenetratecount", 0);
	}
	return Plugin_Continue; 
}  