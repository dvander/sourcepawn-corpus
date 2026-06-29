#pragma semicolon 1
#pragma newdecls required

#define TAG "[SM]"

#include <sourcemod>

ConVar convar_DiscordLink;

public Plugin myinfo =
{
	name = "Discord Link",
	author = "Keith Warren (Drixevel)",
	description = "Posts a discord link in chat on command.",
	version = "1.0.0",
	url = "https://github.com/drixevel"
};

public void OnPluginStart()
{
	convar_DiscordLink = CreateConVar("sm_discord_link", "", "Link to post into chat.");
	RegConsoleCmd("sm_discord", Command_DiscordLink, "Show the Discord link in chat.");
}

public Action Command_DiscordLink(int client, int args)
{
	RequestFrame(Frame_ShowLink, GetClientUserId(client));
	return Plugin_Handled;
}

public void Frame_ShowLink(any userid)
{
	int client;
	if ((client = GetClientOfUserId(userid)) > 0)
	{
		char sLink[512];
		convar_DiscordLink.GetString(sLink, sizeof(sLink));
		PrintToConsole(client, "%s Join our Discord: %s", TAG, sLink);
		PrintToChat(client, "%s Join our Discord: %s", TAG, sLink);
	}
}