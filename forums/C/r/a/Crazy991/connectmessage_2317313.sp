#include <sourcemod>
#include <geoip>
#pragma tabsize 0

new Handle:h_connectmsg = INVALID_HANDLE;
new Handle:h_disconnectmsg = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Connect MSG",
	author = "Crazy",
	description = "Provides Info of the player when he joins",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{	
	h_connectmsg = CreateConVar("sm_connectmsg", "1", "Shows a connect message in the chat once a player joins.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	h_disconnectmsg = CreateConVar("sm_disconnectmsg", "1", "Shows a disconnect message in the chat once a player leaves.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public OnClientPutInServer(client)
{
	new Connect = GetConVarInt(h_connectmsg);
	if(Connect == 1)
	{
		new String:name[99], String:authid[99], String:IP[99], String:Country[99];
		
		GetClientName(client, name, sizeof(name));
		
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		
		GetClientIP(client, IP, sizeof(IP), true);
		
    if(!GeoipCountry(IP, Country, sizeof Country))
    {
        Country = "Unknown Country";
    }  
        PrintToChatAll(" \x04[CONNECT]\x03 %s (%s) has joined the server from [%s]", name, authid, Country);
        
    } else {
  
    CloseHandle(h_connectmsg);
   }
}

public OnClientDisconnect(client)
{
	new Disconnect = GetConVarInt(h_disconnectmsg);
	if(Disconnect == 1)
	
	{
		new String:name[99], String:authid[99], String:IP[99], String:Country[99];
		
		GetClientName(client, name, sizeof(name));
		
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		
		GetClientIP(client, IP, sizeof(IP), true);
		
	if(!GeoipCountry(IP, Country, sizeof Country))
	
    {
        Country = "Unknown Country";
    }
    
        PrintToChatAll(" \x04[DISCONNECT]\x03 %s (%s) has left the server from [%s]", name, authid, Country);
        
    } else {
    
    CloseHandle(h_disconnectmsg);
}

}