#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

new Handle:gH_Enabled = INVALID_HANDLE;

new bool:gB_Enabled;

public Plugin:myinfo = 
{
	name = "No Dependencies Noblock",
	author = "ml",
	description = "Simple \"Noblock\" plugin without any dependencies.",
	version = "1.0",
	url = "not vgames"
}

public OnPluginStart()
{
	CreateConVar("sm_noblock_good_version", PLUGIN_VERSION, "Noblock version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gH_Enabled = CreateConVar("sm_noblock_good_enabled", PLUGIN_VERSION, "Noblock is enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Enabled = true;
	
	HookConVarChange(gH_Enabled, OnConVarChanged);
	
	AutoExecConfig();
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	gB_Enabled = bool:StringToInt(newVal);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!IsValidClient(client, true))
	{
		return Plugin_Continue;
	}
	
	SetEntProp(client, Prop_Data, "m_CollisionGroup", gB_Enabled? 2:5);
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}
