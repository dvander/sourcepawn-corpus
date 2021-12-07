#include <sourcemod>

public Plugin:myinfo = 
{
     name = "SteamID Reveal",
	 author = "kycocss",
	 description = "show steamid to everyone",
	 version = "1.0.0",
	 url = "http://forums.alliedmods.net/",
};

public OnPluginStart ()
{
     RegConsoleCmd("sm_steamid", CommandSteamid, "");
}

public Action:CommandSteamid(client, args)
{
     new String:name[32], String:authid[32];
	 
	 GetClientName(client, name, sizeof(name));
	 GetClientAuthString(client, authid, sizeof(authid));
	 
	 PrintToChatAll("\x04[SM] \x01Player \x04%s \x01has \x04%s \x01SteamID.", name, authid);
	 
	 return Plugin_Handled;
}