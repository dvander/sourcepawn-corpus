#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PLUGIN_NAME "Reject connection | Serverside connection limiter"
#define PLUGIN_AUTHOR "Deco (Desktop)"
#define PLUGIN_DESCRIPTION "Reject client connection when server is full"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_CONTACT "www.piu-games.com"


int iOnlineClients;
int iMaxPlayers;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public void OnPluginStart(){
	
	CreateConVar("sm_rejectconnection_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	
	iOnlineClients = 0;
	iMaxPlayers = GetMaxHumanPlayers();
}

public void OnClientConnected(int client){
	iOnlineClients++;
}

public void OnClientPostAdminCheck(int client){
	
	if (iOnlineClients > iMaxPlayers){
		KickClient(client, "Server is full");
	}
}

public void OnClientDisconnect_Post(int client){
	iOnlineClients--;
}