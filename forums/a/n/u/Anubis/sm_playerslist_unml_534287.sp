/*
*    Plugin display players list in console like Mani`s ma_users
* 
*    Here two ways to get it list:
*    sm_plist - public console command for all players (enabled/disabled by cvar sm_plistpub)
*    sm_plist - command for admin only (with flag b)
*   
*/

#include <sourcemod>

#define PLUGIN_VERSION "0.2_Fixed by Anubis"

new Handle:g_UserSayList;

public Plugin:myinfo = 
{
	name = "PlayersList",
	author = "O!KAK",
	description = "Display players name, ip, steamid",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{	
	
	RegAdminCmd("sm_plist", Command_Users, ADMFLAG_GENERIC, "Show list players on a server.");

	g_UserSayList = CreateConVar("sm_plistpub","1","Access players to sm_plist command");
	
}

public Action:OnClientCommand(client, args)
{
        new String:usrlist[16]
	GetCmdArg(0, usrlist, sizeof(usrlist));

	if (StrEqual(usrlist, "sm_plist"))
	{
	        if (GetConVarInt(g_UserSayList) == 0)
                {
                return Plugin_Handled;
                }

		decl String:t_name[16], String:t_ip[16], String:t_steamid[16];
		Format(t_name, sizeof(t_name), "Nick");
		Format(t_ip, sizeof(t_ip), "IP");
		Format(t_steamid, sizeof(t_steamid), "SteamID");

		PrintToConsole(client, "#  %-25s %-20.5s %s", t_name, t_ip, t_steamid);

		/* List all players */
		new maxClients = GetMaxClients();

		for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			decl String:name[65], String:ip[32], String:steamid[32];
			GetClientName(i, name, sizeof(name));
			GetClientIP(i, ip, sizeof(ip));
			GetClientAuthString(i, steamid, sizeof(steamid));
			PrintToConsole(client, "%d. %-24.35s %-20s %s", i, name, ip, steamid);
		}
		return Plugin_Stop;
	}
 
	return Plugin_Continue;
}

public Action:Command_Users(client,args)
{

		/* Display header */
		decl String:t_name[16], String:t_ip[16], String:t_steamid[16];
		Format(t_name, sizeof(t_name), "Nick");
		Format(t_ip, sizeof(t_ip), "IP");
		Format(t_steamid, sizeof(t_steamid), "SteamID");

		PrintToConsole(client, "#  %-25s %-20.5s %s", t_name, t_ip, t_steamid);

		/* List all players */
		new maxClients = GetMaxClients();

		for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			decl String:name[65], String:ip[32], String:steamid[32];
			GetClientName(i, name, sizeof(name));
			GetClientIP(i, ip, sizeof(ip));
			GetClientAuthString(i, steamid, sizeof(steamid));
			PrintToConsole(client, "%d. %-24.35s %-20s %s", i, name, ip, steamid);
		}

		if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
		{
			ReplyToCommand(client, "[SM] See console for output");
		}
	
}