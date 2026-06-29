#include <sourcemod>
#include <geoip>
#pragma semicolon 1

bool g_bMessageShown[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Team Join Announce",
	author = "Armin, modified by Potatoz",
	description = "Provides info of the player when he/she selects a team",
	version = "1.0.1",
	url = "http://nerp.cf/"
};

public OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam);
}

public OnClientPutInServer(client) 
{	
	g_bMessageShown[client] = false;
}

public Action Event_PlayerTeam(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || IsFakeClient(client)) return;

	CreateTimer(0.2, Timer_DelayTeam, client);
}

public Action Timer_DelayTeam(Handle timer, int client)
{	
	if (g_bMessageShown[client]) return Plugin_Continue;
	
	char ip[16], country[25];		
	GetClientIP(client, ip, sizeof(ip), true);
	
	if(!GeoipCountry(ip, country, sizeof(country)))
		Format(country, sizeof(country), "Unkown Country");
	
	if(GetClientTeam(client) == 3)
		PrintToChatAll(" \x06+ %N \x01has joined the \x06CT-Team \x01from \x06%s", client, country);
	else if(GetClientTeam(client) == 2)
		PrintToChatAll(" \x06+ %N \x01has joined the \x06T-Team \x01from \x06%s", client, country);
	
	g_bMessageShown[client] = true;
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{	
	PrintToChatAll(" \x07- %N \x01has left the game.", client);
}