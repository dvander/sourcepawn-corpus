#include <sourcemod>

#define PLUGIN_VERSION "1.0"
  
public Plugin:myinfo =
{
	name = "TF2 Build Commands",
	author = "Tylerst",
	description = "Allows engineers to build with simple chat commands",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	RegConsoleCmd("sm_sentry", Command_Sentry)
	RegConsoleCmd("sm_dispenser", Command_Dispenser)
	RegConsoleCmd("sm_entrance", Command_Entrance)
	RegConsoleCmd("sm_exit", Command_Exit)
}

public Action:Command_Sentry(client, args)
{
	ClientCommand(client, "build 2")
	return Plugin_Handled;
}
public Action:Command_Dispenser(client, args)
{
	ClientCommand(client, "build 0")
	return Plugin_Handled;
}
public Action:Command_Entrance(client, args)
{
	ClientCommand(client, "build 1")
	return Plugin_Handled;
}
public Action:Command_Exit(client, args)
{
	ClientCommand(client, "build 3")
	return Plugin_Handled;
}
