//SOURCEMOD INCLUDES
#include <sourcemod>
#include <geoip>
#include <cstrike>

//PRAGMA
#pragma tabsize 0

//GLOBALS
bool g_bMessagesShown[MAXPLAYERS + 1];

//cred to ariel vanguard for helping me remove the message loop.

public Plugin:myinfo = 
{
	name = "Team Join Announce",
	author = "Armin",
	description = "Provides info of the player when he/she selects a team",
	version = "1.0",
	url = "http://nerp.cf/"
};

public OnPluginStart()
{
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Post);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bMessagesShown[i] = false;
	}
}

public void Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0 || IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(0.2, Timer_DelayTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelayTeam(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client == 0 || !IsPlayerAlive(client) || g_bMessagesShown[client])
	{
		return Plugin_Continue;
	}
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		new String:name[99], String:IP[99], String:Country[99];
		
		GetClientName(client, name, sizeof(name));
		
		GetClientIP(client, IP, sizeof(IP), true);
		
		if(!GeoipCountry(IP, Country, sizeof Country))
		{
			Country = "Unknown Country";
		} 
	
		PrintToChatAll(" + \x03%s \x01has joined the \x0BCT-Team \x01from \x04%s", name, Country);
    }
	
	else if(GetClientTeam(client) == CS_TEAM_T)
	{	
        new String:name[99], String:IP[99], String:Country[99];
		
		GetClientName(client, name, sizeof(name));
		
		GetClientIP(client, IP, sizeof(IP), true);
		
		if(!GeoipCountry(IP, Country, sizeof Country))
		{
			Country = "Unknown Country";
		} 
	
		PrintToChatAll(" + \x03%s \x01has joined the \x07T-Team \x01from \x04%s", name, Country);
    }
	
	g_bMessagesShown[client] = true;
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	new String:name[99], String:IP[99], String:Country[99];
	
	GetClientName(client, name, sizeof(name));
	
	GetClientIP(client, IP, sizeof(IP), true);
	
	if(!GeoipCountry(IP, Country, sizeof Country))
	{
		Country = "Unknown Country";
	}  
	
	PrintToChatAll(" - \x03%s \x01has left the game.", name);
	
	g_bMessagesShown[client] = false;
}