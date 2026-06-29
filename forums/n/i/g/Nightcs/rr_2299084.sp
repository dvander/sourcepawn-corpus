#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[CSGO] Restart Round",
	author = "NiGhT_CSGO",
	description = "Restart Round",
	version = "1.0"
}

public OnPluginStart()
{
	RegAdminCmd("sm_rr", Command_rr, ADMFLAG_RCON, "Restarting one Match.")
}


public Action:Command_rr(client, args)
{
	ServerCommand("mp_restartgame 3");
}