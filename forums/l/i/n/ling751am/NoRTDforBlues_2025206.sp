//Include
#include <rtd>

//Definitions
#define PLUGIN_VERSION "1.0"

//Info
public Plugin:myinfo = {
	name = "[TF2] Restrict RTD for Blue Team",
	author = "ddhoward",
	description = "Restrict Blue Team Can't RTD",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=75561&page=122"
}

//Script
public Action:RTD_CanRollDice(client) {
    if (GetClientTeam(client) == 3) return Plugin_Handled;
    return Plugin_Continue;
}