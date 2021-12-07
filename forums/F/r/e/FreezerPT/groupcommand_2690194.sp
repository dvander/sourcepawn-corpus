#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Rafa"
#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "group command",
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	description = "!group in chat to show the group link",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_group", cmd_group);
}

public Action cmd_group(int client, int args)
{
	PrintToChat(client, "YOUR MESSAGE HERE");
}