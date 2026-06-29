#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
public Plugin:myinfo = {
	name = "l4d2 painter downloads table",
	author = "gamemann",
	description = "makes people download l4d2 all infected file!",
	version = "1.0.0",
	url = "http://games223.com"
};

public OnPluginStart()
{
	CreateTimer(3.0, Painter);
}

public OnMapStart()
{
AddFileToDownloadsTable("addons\\specialallowcoloring.vpk");
}

public Action:Painter(Handle:timer)
{
	PrintToChatAll("\x02 You are downloading a vpk that lets you have colored special infected!");
	return Plugin_Handled;
}