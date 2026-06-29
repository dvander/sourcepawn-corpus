#include <sourcemod>
#include <sdktools>
#include <tf2>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "TF2 Instantrespawn",
	author = "R-Hehl",
	description = "TF2 Instantrespawn",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};
public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath)
	CreateConVar("sm_respawner_version", PLUGIN_VERSION, "TF2 instant respawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	}
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(victimId)
	CreateTimer(1.0, Timer_spawn, client, TIMER_REPEAT);
}
public Action:Timer_spawn(Handle:timer, any:client)
{
	TF2_RespawnPlayer(client)
	CloseHandle(timer)
}