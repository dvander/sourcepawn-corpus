#include <sourcemod>
#include <lvl_ranks>
#include <colors>

#define PLUGIN_NEV	"minrank"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314084"
#define PLUGIN_AUTHOR	"Nexd"

int iStats = ST_VALUE

public Plugin myinfo = 
{
	name = PLUGIN_NEV,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
};

public OnPluginStart()
{
	AddCommandListener(Command_BlockCmd, "sm_ws");
	AddCommandListener(Command_BlockCmd, "sm_knife");
	AddCommandListener(Command_BlockCmd, "sm_gloves");
}

public Action:Command_BlockCmd(client, const String:command[], args)
{
	LR_GetClientInfo(client, iStats);
	if (iStats >= 750) {
		return Plugin_Continue;
	} else {
		PrintToChat(client, "You need to be atleast \x0BMG1 \x01to use this command.");
		return Plugin_Stop;
	}
}