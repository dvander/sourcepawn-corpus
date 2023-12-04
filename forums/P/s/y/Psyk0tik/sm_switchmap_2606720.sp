#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Map Switcher",
	author = "Psyk0tik (Crasher_3637)",
	description = "Switches to a specified map.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=308106"
};

public void OnPluginStart()
{
	// Register the admin command first.
	RegAdminCmd("sm_switchmap", cmdSwitchMap, ADMFLAG_CHANGEMAP, "Switch to a specified map.");
	// This registers the console command for any client to use. The RegAdminCmd() method is recommended over RegConsoleCmd() when changing the map.
	//RegConsoleCmd("sm_switchmap", cmdSwitchMap, "Switch to a specified map.");
}

public Action cmdSwitchMap(int client, int args)
{
	// Check if the client is in-game.
	if (!IsClientInGame(client))
	{
		ReplyToCommand(client, "[SM] You must be in-game to use this command.");
		return Plugin_Handled;
	}
	// Check if the command has 1 argument/parameter.
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] No map specified.");
		return Plugin_Handled;
	}
	else if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_switchmap <mapname>");
		return Plugin_Handled;
	}
	// The 1st argument/parameter is a string.
	char sMap[32];
	GetCmdArg(1, sMap, sizeof(sMap));
	// Change the map to the 1st argument/parameter specified.
	ForceChangeLevel(sMap, "Map change");
	return Plugin_Handled;
}