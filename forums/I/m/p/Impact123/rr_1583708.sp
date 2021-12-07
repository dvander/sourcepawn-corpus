#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Restart Round",
	author = "Impact",
	description = "Restart Round",
	version = "0.1"
}

public OnPluginStart()
{
	RegAdminCmd("sm_rr", Command_rr, ADMFLAG_RCON, "Restarts the Round.")
}


public Action:Command_rr(client, args)
{
	ServerCommand("mp_restartgame 3");
	PrintToChatAll("Round will restart in 3 seconds")
}