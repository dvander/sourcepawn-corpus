#include <sourcemod>
#include <clients>

public Plugin:myinfo = 
{
	name = "Test",
	author = "Hengen",
	description = "Test",
	version = "1.0"
}

public OnPluginStart()
{
	RegAdminCmd("sm_hook", Command_sm_hook, ADMFLAG_RCON, "Give Hook.")
}

public Action:Command_sm_hook(client, args, target)
{
	ServerCommand("sm_hgr_givehook %d", target);
}
