#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Discord Link",
	author = "XerM",
	description = "A simple plugin for discord link",
	version = "1.0",
	url = "forums.alliedmods.net"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_discord", Discord_Link, "Prints discord link to chat");
}

public Action Discord_Link(int client, int args)
{
	if(args > 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_discord");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client,"\x03yourserverlink");
	return Plugin_Handled;
}
