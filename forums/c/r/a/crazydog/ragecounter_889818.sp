/*
* Rage counter (c) 2009 Jonah Hirsch
* 
* 
* Counts ragequits in l4d, displays on quit
* 
*  
* Changelog								
* ------------		
* 1.1
*  - Timeouts are no longer counted
*  - Kicks are no longer counted
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"
new raged

public Plugin:myinfo = 
{
	name = "Rage Counter",
	author = "Crazydog",
	description = "Counts ragequits in l4d",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

new rages

public OnPluginStart(){
	HookEvent("player_disconnect", RageCount, EventHookMode_Pre)
	HookEvent("player_connect", ResetRaged)
	RegConsoleCmd("sm_rages", Command_Rages, "Gets # of rages")
	CreateConVar("sm_rage_version", PLUGIN_VERSION, "Rage Counter Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	rages = 0;
}


public RageCount(Handle:event, const String:name[], bool:dontBroadcast){
	new client_id = GetEventInt(event, "userid")
	new client = GetClientOfUserId(client_id)
	if (client == 0){
			return
	}
	if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientTimingOut(client) && !IsClientInKickQueue(client)){
		if(client != raged){
			rages++;
			if(rages == 1){
				PrintToChatAll("\x04[Rage Counter]\x01 There has been \x04%i\x01 rage quit.", rages)
			}else{	
				PrintToChatAll("\x04[Rage Counter]\x01 There have been \x04%i\x01 rage quits.", rages)
			}
			raged = client
		}
	}
}

public Action:Command_Rages(client, args){
	if(rages == 1){
		PrintToChat(client, "\x04[Rage Counter]\x01 There has been \x04%i\x01 rage quit.", rages)
	}else{	
		PrintToChat(client, "\x04[Rage Counter]\x01 There have been \x04%i\x01 rage quits.", rages)
	}
}

public ResetRaged(Handle:event, const String:name[], bool:dontBroadcast){
	new client_id = GetEventInt(event, "userid")
	new client = GetClientOfUserId(client_id)
	if (client == 0){
			return
	}
	if(raged == client){
		raged = 0
	}
}
