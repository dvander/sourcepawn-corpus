#include <sourcemod>


public Plugin:myinfo = 
{
	name = "RR",
	author = "Dk--",
	description = "Dar restart Round",
	version = "v2.0",
};

public OnPluginStart()
{
	RegConsoleCmd("sm_rr", RR)
}
		
public Action:RR(client, args)
{
	ServerCommand("mp_restartgame 1");
	PrintCenterTextAll(" RESTART ROUND ");
}
