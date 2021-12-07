#include <sourcemod>
//#include <sdktools>

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

ConVar g_cvLink = null;

public void OnPluginStart()
{
	RegConsoleCmd("sm_discord", Discord_Link, "Prints discord link to chat");

	g_cvLink = CreateConVar("sm_discord_link", "discord.com", "Discord server URL");
}

public Action Discord_Link(int client, int args)
{
	/*
	if(args > 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_discord");
		return Plugin_Handled;
	}
	*/

	char sURL[256];
	g_cvLink.GetString(sURL, sizeof(sURL));

	ReplyToCommand(client,"\x03%s", sURL);

	return Plugin_Handled;
}
