#pragma semicolon 1

#include <sourcemod> 
#include <multicolors>

#define DISCORD_URL "https://discord.gg/mKEkypk"

#pragma newdecls required

public Plugin myinfo =
{
	name		= "Show discord",
	description	= "Show a discord server in the chat.",
	author		= "Nano",
	version		= "1.0",
	url			= "http://steamcommunity.com/id/marianzet1"
}

public void OnPluginStart() 
{
	RegConsoleCmd("sm_discord", Command_Discord);
}

//The lines below will print the message only for who type !discord [its a client message]

public Action Command_Discord(int client, int args)
{
	CPrintToChat(client, "{green}[DISCORD]{purple} Join in our Discord server!");
	CPrintToChat(client, "{green}[DISCORD]{purple} %s", DISCORD_URL); 
	return Plugin_Handled;
}

//The lines below will print the message for EVERYONE. For example if i type !discord, every people in the server will see the printed message 
//Delete the lines above (26, 27, 28, 29, 30, 31) if you want to use the following system
//Also delete the // before the functions

//public Action Command_Discord(int client, int args)
//{
//	CPrintToChatAll("{green}[DISCORD]{purple} Join in our Discord server!");
//	CPrintToChatAll("{green}[DISCORD]{purple} %s", DISCORD_URL); 
//	return Plugin_Handled;
//}