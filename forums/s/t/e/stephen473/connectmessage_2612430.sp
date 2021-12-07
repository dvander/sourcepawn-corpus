#include <sourcemod>
#include <geoip>

#pragma newdecls required

ConVar g_cFlag;
public Plugin myinfo = 
{
	name = "Connect/disconnect message", 
	author = "stephen473(Hardy`)", 
	description = "Shows info about connecting/disconnecting players", 
	version = "1.0", 
	url = "https://pluginsatis.com"
}

public void OnPluginStart()
{
	g_cFlag = CreateConVar("cd_message_adminflag", "b", "Enter a certain flag");
	AutoExecConfig(true, "cd_message");
}

public void OnClientPostAdminCheck(int client)
{
	if(IsClientAdmin(client))
	{
		char authid[64], country[46], ip[46];
		
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		GetClientIP(client, ip, sizeof(ip));
		
		if (!GeoipCountry(ip, country, sizeof(country))) {
			Format(country, sizeof(country), "Unknown Country");
		}
		PrintToChatAll(" \x04%N \x05[%s] \x01connected from %s", client, authid, country);
	}
}

public void OnClientDisconnect(int client)
{
	if(IsClientAdmin(client))
	{	
		char authid[64], country[46], ip[46];
	
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		GetClientIP(client, ip, sizeof(ip));
		
		if (!GeoipCountry(ip, country, sizeof(country))) {
			Format(country, sizeof(country), "Unknown Country");
		}
	
		PrintToChatAll(" \x04%N \x05[%s] \x01disconnected from %s", client, authid, country);
	}
}

bool IsClientAdmin(int client)
{
	char flag[4];
	g_cFlag.GetString(flag, sizeof(flag));
	
	int iFlag = ReadFlagString(flag);
	
	if ((GetUserFlagBits(client) & iFlag) == iFlag) {
		return true;
	}
	
	return false;
} 