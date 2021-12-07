/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2fastteleports.sp
 * Description: Change the time the teleport takes to recharge (completly rewrited tf2teleporter by Nican132)
 * Author(s): kim_perm
 */           

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define TF_CLASS_SCOUT			1
#define PL_VERSION "0.1"

public Plugin:myinfo = 
{
    name = "Block Scouts from Teleporters",
    author = "MoggieX",
    description = "Punish Scouts for using a teleporter",
    version = PL_VERSION,
    url = "http://www.ukmandown.co.uk/"
};       

/* ------------------------------------------------------ */
public OnPluginStart() {

	CreateConVar("sm_tf_scout_blockering", PL_VERSION, "Punish Scouts for using a teleporter", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_teleported", event_player_teleported);
}


public Action:event_player_teleported(Handle:event, const String:name[], bool:dontBroadcast) {

	new iClient;
	iClient 		= GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(TF2_GetPlayerClass(iClient) == TF_CLASS_SCOUT)
	{
		SlapPlayer(iClient, 25);
		SlapPlayer(iClient, 25);
		SlapPlayer(iClient, 25);
		SlapPlayer(iClient, 25);
		PrintToChat(iClient, "\x03[SCOUTS!!]\x04 Oh no you don't Scouts can run faster than any class\x01, run next time!");
	}

	return Plugin_Continue;
}