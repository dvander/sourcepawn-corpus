//Sourcemod Includes
#include <sourcemod>

//Pragma
#pragma semicolon 1
#pragma newdecls required

//Globals
bool g_bMessagesShown[MAXPLAYERS + 1];

ConVar g_cServerLink;
ConVar g_cWebsiteLink;

public Plugin myinfo = 
{
	name = "Conmessage", 
	author = "Markie", 
	description = "Connect Message.", 
	version = "1.0.0", 
	url = "https://nerp.cf/"
};

public void OnPluginStart()
{
	g_cServerLink = CreateConVar("sm_cmsg_serverlink", "Your sourceban link", "Your sourceban link");
	g_cWebsiteLink = CreateConVar("sm_cmsg_websitelink", "Your Server Link", "Your Server Link");

	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bMessagesShown[i] = false;
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0 || IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(0.2, Timer_DelaySpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelaySpawn(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client == 0 || !IsPlayerAlive(client) || g_bMessagesShown[client])
	{
		return Plugin_Continue;
	}

	char sServerLink[128];
	char sWebsiteLink[128];

	g_cServerLink.GetString(sServerLink, sizeof(sServerLink));
	g_cWebsiteLink.GetString(sWebsiteLink, sizeof(sWebsiteLink));
	
	PrintToChat(client, "PenguinsLordsKingdom \x07~ \x01Welcome, \x03%N", client);
	PrintToChat(client, "PenguinsLordsKingdom \x07~ \x01Check our website: \x0B[yourwebsite] ", client);
	PrintToChat(client, "PenguinsLordsKingdom \x07~ \x01Feel free to join our discord server too :\x0E[yourdiscord] ", client);
	PrintToChat(client, "PenguinsLordsKingdom \x07~ \x07[Updates]\x01: \x10New Songs\x01Added !", client);
	g_bMessagesShown[client] = true;
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	g_bMessagesShown[client] = false;
}