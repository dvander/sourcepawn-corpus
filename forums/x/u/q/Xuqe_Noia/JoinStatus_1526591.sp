#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Join Status",
	author = "Xuqe Noia",
	description = "Shows the player name and steamid when he joins the game",
	version = PLUGIN_VERSION,
	url = "www.LiquidBR.com"
};

public OnPluginStart() {
	CreateConVar( "sm_joinstatus", PLUGIN_VERSION, "Join Status");
	HookEvent("player_connect", OnPlayerConnect);
	HookEvent("player_disconnect", OnPlayerDisconnect);
}


public Action:OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:steamid[32];
	decl String:cname[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	GetClientName(client, cname, sizeof(cname));
	PrintToChatAll("\x04Player \x01[%s]\x04 SteamID \x01[%s]\x04 joined the game.", cname, steamid);
}

public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:steamid[32];
	decl String:cname[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	GetClientName(client, cname, sizeof(cname));
	PrintToChatAll("\x04Player \x01[%s]\x04 SteamID \x01[%s]\x04 left the game.", cname, steamid);
}