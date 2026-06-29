#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"


public Plugin:myinfo = 
{
	name = "rablock",
	author = "Shango",
	description = "blocks r_aspectratio",
	version = PLUGIN_VERSION,
	url = "http:\\www.stompfest.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("r_aspectratio",Command_r_aspectratio,"Removed from use.");
}

public OnEventShutdown()
{
}

public Action:Command_r_aspectratio(client,args)
{
	ReplyToCommand(client, "Not Allowed.");
	return Plugin_Handled;
}