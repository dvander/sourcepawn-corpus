/*
* SourceMod Script
* 
* Developed by Mosalar
* April 2009
* http://www.budznetwork.com
*
*
* DESCRIPTION:
* 
* A general plugin to globally speed up
* player speed and weight/personal grav.
* Originally made for FoF, but can 
* be used in most source games.
* 
*/

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:g_hEnabled;
new Handle:g_Cvar_Speed
new Handle:g_Cvar_Weight

public Plugin:myinfo = 
{
	name = "SpeedUp",
	author = "Mosalar",
	description = "Speeds Up Gameplay",
	version = PLUGIN_VERSION,
	url = "http://www.budznetwork.com"
};


public OnPluginStart()
{
	CreateConVar("sm_speedup_version", PLUGIN_VERSION, "SpeedUp Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_hEnabled  = CreateConVar("sm_speedup_enabled", "0",  "Enable/disable plugin",           FCVAR_PLUGIN);
	g_Cvar_Speed    = CreateConVar("sm_speedup_speed", "1.1", " Sets the players speed ", FCVAR_PLUGIN)
	g_Cvar_Weight   = CreateConVar("sm_speedup_weight", "0.90", " Sets the players weight", FCVAR_PLUGIN)
	
	HookEvent("player_spawn", PlayerSpawnEvent)
	
	AutoExecConfig();
}


public Action:PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_hEnabled)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		if (client > 0 && IsClientInGame(client) && GetClientTeam(client) > 1) {
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_Cvar_Speed))
			SetEntityGravity(client, GetConVarFloat(g_Cvar_Weight))
		}
	}
	return Plugin_Continue;
}

