/*
*    Plugin display players list in console like Mani`s ma_users
* 
*    sm_plistpub 0 - sm_plist command works for admins only
*    sm_plistpub 1 - sm_plist command works for all players  
*/

#pragma semicolon 1
#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "0.4"

new Handle:g_UserSayList = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "PlayersList",
	author = "O!KAK",
	description = "Display players name, ip, steamid, country",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("sm_plist_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	RegConsoleCmd("sm_plist", Command_Users, "Show list players on a server");
	g_UserSayList = CreateConVar("sm_plistpub", "0", "Access players to sm_plist command", _, true, 0.0, true, 1.0);	
}

public Action:Command_Users(client, args)
{
        if(client && !GetConVarBool(g_UserSayList) && GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
                PrintToConsole(client, "[SM] You don`t have access to this command!");
		return Plugin_Handled;
	}

	decl String:t_name[64], String:t_ip[24], String:t_steamid[24], String:t_country[10], String:code[4];

	Format(t_name, sizeof(t_name), "Nick");
	Format(t_ip, sizeof(t_ip), "IP");
	Format(t_steamid, sizeof(t_steamid), "SteamID");
	Format(t_country, sizeof(t_country), "Country");

	PrintToConsole(client, "+------------------------------------------------------------------------+");
	PrintToConsole(client, "#  %-21s %-16s %-10s %s", t_steamid, t_ip, t_country, t_name);
	PrintToConsole(client, "+------------------------------------------------------------------------+");

	new count = 0, bool:find;
	for (new i = 1; i <= MaxClients; i++)
	{
	       if(IsClientInGame(i) && !IsFakeClient(i))
	       {
		     count++;
		     GetClientName(i, t_name, sizeof(t_name));
		     GetClientIP(i, t_ip, sizeof(t_ip));
		     GetClientAuthString(i, t_steamid, sizeof(t_steamid));
		     find = GeoipCode3(t_ip, code);

		     if(!find) {
		           Format(t_country, sizeof(t_country), "not found");
                           PrintToConsole(client, "%d. %-21s %-16s %-10s %s", count, t_steamid, t_ip, t_country, t_name);
		     } else {
                           PrintToConsole(client, "%d. %-21s %-16s %-10s %s", count, t_steamid, t_ip, code, t_name);
		     }
	       }
	}

	PrintToConsole(client, "+------------------------------------------------------------------------+");

	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
		PrintToChat(client, "[SM] See console for output");
	
	return Plugin_Handled;
}