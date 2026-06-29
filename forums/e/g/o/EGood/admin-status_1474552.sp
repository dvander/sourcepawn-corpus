
#pragma semicolon 1
#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "0.4"

new Handle:g_User = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Admin Status",
	author = "EGood",
	description = "Display players name, ip, steamid, country",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("sm_adm-status_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	RegConsoleCmd("sm_admstatus", Command_Users, "Show list players on a server");
	g_User = CreateConVar("sm_statusall", "0", "Access players to sm_statusall command", _, true, 0.0, true, 1.0);	
}

public Action:Command_Users(client, args)
{
        if(client && !GetConVarBool(g_User) && GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
                PrintToChat(client, "\x03[AdminStatus] \x01You don`t have access to this command!");
		return Plugin_Handled;
	}

	decl String:status_name[64], String:status_ip[24], String:status_steamid[24], String:status_country[10], String:code[4];

	Format(status_name, sizeof(status_name), "Nick");
	Format(status_ip, sizeof(status_ip), "IP");
	Format(status_steamid, sizeof(status_steamid), "SteamID");
	Format(status_country, sizeof(status_country), "Country");

	PrintToConsole(client, "+------------------------------------------------------------------------+");
	PrintToConsole(client, "#  %-21s %-16s %-10s %s", status_steamid, status_ip, status_country, status_name);
	PrintToConsole(client, "+------------------------------------------------------------------------+");

	new count = 0, bool:find;
	for (new i = 1; i <= MaxClients; i++)
	{
	       if(IsClientInGame(i) && !IsFakeClient(i))
	       {
		     count++;
		     GetClientName(i, status_name, sizeof(status_name));
		     GetClientIP(i, status_ip, sizeof(status_ip));
		     GetClientAuthString(i, status_steamid, sizeof(status_steamid));
		     find = GeoipCode3(status_ip, code);

		     if(!find) {
		           Format(status_country, sizeof(status_country), "not found");
                           PrintToConsole(client, "%d. %-21s %-16s %-10s %s", count, status_steamid, status_ip, status_country, status_name);
		     } else {
                           PrintToConsole(client, "%d. %-21s %-16s %-10s %s", count, status_steamid, status_ip, code, status_name);
		     }
	       }
	}

	PrintToConsole(client, "+------------------------------------------------------------------------+");

	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
		PrintToChat(client, "\x03[AdminStatus] \x01See console for output");
	
	return Plugin_Handled;
}