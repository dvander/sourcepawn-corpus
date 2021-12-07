#pragma semicolon 1

#include <sourcemod>

#define VERSION "1.1"

public Plugin:myinfo =
{
	name = "Steam Announce",
	author = "Rizla",
	description = "Announce Steam IDs on Connect and Disconnect",
	version = VERSION,
	url = "http://www.tmfgaming.com"
};

public OnPluginStart()
{
	CreateConVar("sm_steam_announce_version", VERSION, "Steam Announce Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Pre);	
}

public OnClientPostAdminCheck(client) 
{     
	if (!IsFakeClient(client))
	{
		decl String:steamid[32],String:clientname[24];
		
		GetClientName(client, clientname, sizeof(clientname));
		GetClientAuthString(client,steamid,sizeof(steamid));

		PrintToChatAll("\x01[CON] \x04%s : \x03%s", clientname, steamid);
	}
}


public Action:event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsFakeClient(client)) 
	{
		new String:clientname[24];
		GetClientName(client, clientname, sizeof(clientname));
		new String:steamid[35];
		GetClientAuthString(client,steamid,sizeof(steamid));
		
		PrintToChatAll("\x01[DC] \x04%s : \x03%s", clientname, steamid);
	}
	return Plugin_Continue;
}