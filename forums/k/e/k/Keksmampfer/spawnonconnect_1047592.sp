#include <sourcemod>
#include <cstrike>

//force a ; at the end of every command line for better structure (dont need this^^)
#pragma semicolon 1
#define PLUGIN_VERSION "1.1.0"

new Handle:Cvar_SOC_ENABLED = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Respawn on Join",
	author = "Alexander",
	description = "Allows players to respawn when they fist join the server.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	
	CreateConVar("sm_soc_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_SOC_ENABLED = CreateConVar("sm_soc_enabled", "1", "Enable/disable plugin 0/1", _, true, 0.0, true, 1.0);
	
	if(GetConVarBool(Cvar_SOC_ENABLED))
	{	
		HookEvent("player_team", EventJoinTeam);
	}
	HookConVarChange(Cvar_SOC_ENABLED, CB_enable );
}

/* This doesnt disable the respawn
public OnMapStart()
{
    if (GetConVarBool(Cvar_SOC_ENABLED)==false) return;
	*  if GetConVarBool(Cvar_SOC_ENABLED) is false the follwoing code in the function is ignored, but the plugins doesnt stop the work
}
*/

//this works
public CB_enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	//no change = no action
	if( oldVal[0] == newVal[0]) return ;
	
	switch (StringToInt(newVal))
	{
		case 0 : 
		{
			LogMessage("Disable.");
			UnhookEvent("player_team", EventJoinTeam);
		}
		case 1: 
		{
			LogMessage("Enable.");
			HookEvent("player_team", EventJoinTeam);
		}
	}
}

public EventJoinTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	/*Dont need console cant join team
	* 
	* if (client == 0)
	{
	return;
	}
	
	*/
	CreateTimer(1.0, SpawnThePlayer, client);
}

public Action:SpawnThePlayer(Handle:timer, any:client)
{
	// preventing an error because client could disconnect during waittime
	if(!IsClientInGame(client)) return;
	
	new team = GetClientTeam(client);
	if (!IsPlayerAlive(client) && (team == 2 || team == 3))
	{
		CS_RespawnPlayer(client);
	}
	
	/* dont need at one-time timers
	* return Plugin_Continue;
	*/
} 