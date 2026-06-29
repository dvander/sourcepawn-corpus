#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Mithat Guner"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Mithat Guner",
	author = PLUGIN_AUTHOR,
	description = "Pick Random Player",
	version = PLUGIN_VERSION,
	url = "pluginler.com"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_pick", CEK, ADMFLAG_GENERIC);
}

public Action CEK(client, args)
{ 
    new kazanan = GetRandomPlayer(2); 
    PrintToChatAll("Winner Is : %s", kazanan);
    return Plugin_Continue; 
}  

stock GetRandomPlayer(team) { 

    new clients[MaxClients+1], clientCount; 
    for (new i = 1; i <= MaxClients; i++) 
        if (IsClientInGame(i) && (GetClientTeam(i) == team)) 
            clients[clientCount++] = i; 
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)]; 
}  