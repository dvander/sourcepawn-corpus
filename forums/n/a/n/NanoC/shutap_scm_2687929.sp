#include <sourcemod>
#include <colors>
#include <geoip>
#pragma tabsize 0

/* HANDLES */
Handle h_scm_joinmessage = INVALID_HANDLE;
Handle h_scm_leftmessage = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Server Conection Messages +",
	author = "ShutAP",
	description = "This plugin show a chat message and a hud message when a player connect/disconnect to the server.",
	version = "1.1",
	url = "https://steamcommunity.com/id/ShutAP1337"
};

public OnPluginStart()
{	
	h_scm_joinmessage = CreateConVar("sm_scm_join_enable", "1", "Shows a message when a player join the server.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	h_scm_leftmessage = CreateConVar("sm_scm_left_enable", "1", "Shows a message when a player left the server.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "plugin.shutap_scm");
}

public OnClientPutInServer(client)
{
	int Connect = GetConVarInt(h_scm_joinmessage);
	if(Connect == 1)
	{
		if(IsFakeClient(client))
			return;
		
		new String:name[99], String:authid[99], String:IP[99], String:Country[99];
		
		GetClientName(client, name, sizeof(name));
		
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		
		GetClientIP(client, IP, sizeof(IP), true);
		
   		if(!GeoipCountry(IP, Country, sizeof Country))
		{
			Country = "Unknown Country";
		}
		
		PrintToChatAll("\x01[\x04+\x01]\x01 \x04%s\x05<%s> \x01has joined the server from \x04[%s]", name, authid, Country);
		PrintToServer("Player %s <%s> has joined the server from [%s]", name, authid, Country);
		
	} else {
  
	CloseHandle(h_scm_joinmessage);
	
   }
}

public OnClientDisconnect(client)
{
	int Disconnect = GetConVarInt(h_scm_leftmessage);
	if(Disconnect == 1)
	{
		if(IsFakeClient(client))
			return;
		
		new String:name[99], String:authid[99], String:IP[99], String:Country[99];
		
		GetClientName(client, name, sizeof(name));
		
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		
		GetClientIP(client, IP, sizeof(IP), true);
		
   		if(!GeoipCountry(IP, Country, sizeof Country))
		{
			Country = "Unknown Country";
		}
	
		PrintToChatAll("\x01[\x07-\x01]\x01 \x0F%s\x07<%s> \x07has left the server from \x0F[%s]", name, authid, Country);	
		PrintToServer("Player %s <%s> has left the server from [%s]", name, authid, Country);		
		
	} else {  
		
		CloseHandle(h_scm_leftmessage);
		
	}
}