/*
 * SteamID Checker Plugin by : kycocss
 * SourceMod (c) 2015.
 * No Copyright Disclaimed. All rights reserved.
*/

#include <sourcemod>

public Plugin:myinfo = 
{
     name = "SteamID Checker",
	 author = "kycocss",
	 description = "check steamid by typing in chat",
	 version = "2.5.0",
	 url = "http://forums.alliedmods.net/",
};

public OnPluginStart ()
{
     RegConsoleCmd("sm_steamid", CommandSteamid, "");
}

public Action:CommandSteamid(client, args)
{
     new String:authid[32];
	 
	 GetClientAuthString(client, authid, sizeof(authid));
	 PrintToChat(client, "\x04[SM] \x01Here is your \x04%s \x01SteamID.", authid);
	 
	 return Plugin_Handled;
}