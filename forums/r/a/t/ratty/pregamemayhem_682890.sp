#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

new Roundstarts = 0;
new bool:Instaspawn = false;

public Plugin:myinfo =
{
	name = "TF2 FF on during waiting for players",
	author = "Ratty",
	description = "TF2 FF during waiting for players",
	version = PLUGIN_VERSION,
	url = "http://nom-nom-nom.us"
}

public OnPluginStart()
{
        CreateConVar("sm_pregamemayhem_ver", PLUGIN_VERSION, "Pregame Mayhem Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("teamplay_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnMapStart()
{
	Instaspawn = false;
	Roundstarts = 0;
}

public Action:Event_Roundstart(Handle:event,const String:name[],bool:dontBroadcast)
{

	if ( Roundstarts == 0 ) {
		Instaspawn = true;
		CreateTimer(10.0, Timer_Mayhem);
//		CreateTimer(20.0, Timer_Mayhem);
		ServerCommand("mp_friendlyfire 1");
	}

	if ( Roundstarts == 1 ) {
		Instaspawn = false;
		ServerCommand("mp_friendlyfire 0");
		PrintToChatAll("Game starting. Friendlyfire off.");
	}

	Roundstarts++;
}


public Action:Timer_Mayhem(Handle:timer, any:client)
{
	PrintToChatAll("Pregame mayhem is active. Friendlyfire and instaspawn active.");
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.1, Timer_Respawn, client);
    return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:timer, any:client) {
    if (Instaspawn && IsClientConnected(client) && IsClientInGame(client)) {
	    if (!IsFakeClient(client))
	       TF2_RespawnPlayer(client);
	}
}
