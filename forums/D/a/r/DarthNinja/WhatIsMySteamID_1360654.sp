#include <sourcemod>
#define PLUGIN_VERSION		"1.0.1"


public Plugin:myinfo = 
{
	name = "[Any] What is my SteamID",
	author = "DarthNinja",
	description = "Easy way for 'users' to find their steamids",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_steamid_version", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	RegConsoleCmd("mysteam", FindMySteam, "Prints the user's steamid");
	RegConsoleCmd("whatismysteamid", FindMySteam, "Prints the user's steamid");
	RegConsoleCmd("steamid", FindOtherPlayersSteam, "Prints a user's steamid");
}


public Action:FindMySteam(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "http://www.youtube.com/watch?v=gvdf5n-zI14");
		return Plugin_Handled;
	}
	if (IsClientAuthorized(client))
	{
		decl String:steamid[64];
		GetClientAuthString(client, steamid, sizeof(steamid));
		ReplyToCommand(client, "\x04[\x03SteamID\x04]\x01: Hey there \x05%N!\x01  Your SteamID is \x04%s\x01", client, steamid);
	}
	
	return Plugin_Handled;
}

public Action:FindOtherPlayersSteam(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Please choose a player! Example: !steamid gaben");
		return Plugin_Handled;
	}
	decl String:buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client, buffer, true, false);

	if (target == 0)
	{
		ReplyToCommand(client, "http://www.youtube.com/watch?v=gvdf5n-zI14");
		return Plugin_Handled;
	}
		
	if (IsClientAuthorized(target))
	{
		decl String:steamid[64];
		GetClientAuthString(target, steamid, sizeof(steamid));
		ReplyToCommand(client, "\x04[\x03SteamID\x04]\x01: Hey there!  \x05%N's\x01 SteamID is \x04%s\x01", target, steamid);
	}
	
	return Plugin_Handled;
}