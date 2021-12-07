#include <sourcemod>

public Plugin:myinfo =
{
	name = "My SteamID",
	author = "Silent MorningStar",
	description = "Get user's SteamID",
	version = "1.0.0.0",
	url = "http://steamcommunity.com/profiles/76561198043117800"
}
 
public OnPluginStart()
{
	RegConsoleCmd("sm_mysteamid", Command_MySID);
}
 
public Action:Command_MySID(client, args)
{
	new String:steamid[64];
	
	if(GetClientAuthString(client, steamid, 64))
		PrintToChat(client, "Your SteamID is %s",steamid);
	else
		PrintToChat(client, "Couldn't get your SteamID");
	
	return Plugin_Handled;
}