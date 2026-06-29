#include <sourcemod>
#include <string>
#include <clients>

public Plugin:myinfo = 
{
name = "Server Status",
author = "Dutchmeat",
description = "Shows server status",
version = "1.0.0",
url = "www.sourcemod.net"
};


public OnPluginStart()
	RegAdminCmd("server_status",	Status,ADMFLAG_KICK,"Shows the server status");


public Action:Status(client, args)
{
	new maxplayers;
 
	PrintToConsole(client, "Server Status:\n");
	PrintToConsole(client, "Name\tFrags\tRate\tSteamID\tIpAddr:\n");
	maxplayers = GetMaxClients();
	for (new i=1; i<=maxplayers; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}
		decl String:name[32],String:ipaddr[22],String:auth[64],frags,rate;
		
		GetClientName(i, name, sizeof(name));
		GetClientIP(i, ipaddr, 21);
		GetClientAuthString(i, auth, 64);
		frags = GetClientFrags(i);
		rate = GetClientDataRate(i);
		
		PrintToConsole(client, "'%s'\t'%d'\t'%d'\t'%s'\t'%s'\n", name,frags,rate,auth,ipaddr);
	}
 
	return Plugin_Handled;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1043\\ f0\\ fs16 \n\\ par }
*/
