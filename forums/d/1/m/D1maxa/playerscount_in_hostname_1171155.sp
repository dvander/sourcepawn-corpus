#include <sourcemod>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Players count in hostname",
	author = "D1maxa",
	description = "Showing number of players in name of server",
	version = "1.11",
	url = "http://forums.alliedmods.net/showthread.php?t=126060"
};

new g_NumClients=0;
new Handle:hostname = INVALID_HANDLE;
new Handle:sv_visiblemaxplayers = INVALID_HANDLE;
new Handle:formatted_hostname = INVALID_HANDLE;

public OnPluginStart()
{
	hostname = FindConVar("hostname");
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");	
	formatted_hostname=CreateConVar("sm_formatted_hostname", "My Server %d/%d", "Formatted string for dynamic hostname",FCVAR_PLUGIN);
}

public OnMapStart()
{
	g_NumClients=0;
}
 
 public OnConfigsExecuted()
{
	SetNumberOfPlayersInHostname();
}
 
public OnClientConnected(client)
{
	if(!IsFakeClient(client))
	{
		g_NumClients++;
		SetNumberOfPlayersInHostname();
	}
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{		
		g_NumClients--;
		SetNumberOfPlayersInHostname();
	}
}

SetNumberOfPlayersInHostname()
{
	decl String:my_buf[64];
	decl String:f_hostname[64];
	GetConVarString(formatted_hostname,f_hostname,sizeof(f_hostname));
	Format(my_buf,sizeof(my_buf),f_hostname,g_NumClients,GetConVarInt(sv_visiblemaxplayers));
	SetConVarString(hostname,my_buf);
	ServerCommand("heartbeat");
}
