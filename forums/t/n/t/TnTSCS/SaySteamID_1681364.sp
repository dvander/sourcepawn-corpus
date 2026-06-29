#pragma semicolon 1
#include <sourcemod>
#include <scp>

#define PLUGIN_VERSION		"1.1"

public Plugin:myinfo =
{
	name = "Say SteamID",
	author = "fezh, mINI",
	description = "This plugin provides your steam id to everyone when you write something in chat",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart()
{
	CreateConVar("say_steamid_version", PLUGIN_VERSION, "Say SteamID version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	decl String:name2[MAXLENGTH_NAME], String:steamid[64];
	strcopy(name2, sizeof(name2), name);
	GetClientAuthString(author, steamid, sizeof(steamid));
	Format(name, MAXLENGTH_NAME, "(%s) %s", steamid, name2);
	return Plugin_Changed;
}