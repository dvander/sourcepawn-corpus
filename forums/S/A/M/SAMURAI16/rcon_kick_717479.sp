#include <sourcemod>

public Plugin:myinfo = 
{
	name = "rcon kick",
	author = "SAMURAI",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("rcon",cmd_hook_rcon);
	RegConsoleCmd("rcon_password",cmd_hook_rcon);
}

public Action:cmd_hook_rcon(id,args)
{
	KickClient(id);
}

