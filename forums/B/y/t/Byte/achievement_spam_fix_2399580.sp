#include <sourcemod>

#pragma semicolon 1
#define PLUGIN_VERSION "1.00"

public Plugin:myinfo = {
	name = "Achievement Spam Fix",
	author = "Invex | Byte",
	description = "Fix achievement spam in chat.",
	version = PLUGIN_VERSION,
	url = "http://www.invexgaming.com.au/"
};

public Action OnClientCommand(int client, int args)
{
  char cmd[64];
  GetCmdArg(0, cmd, sizeof(cmd));
  
  if (StrEqual(cmd, "achievement_earned", false)) {
    LogAction(client, -1, "\"%L\" is using achievement_earned command. Possible spam attempt.", client);
    return Plugin_Handled;
  }
    
  return Plugin_Continue;
}

