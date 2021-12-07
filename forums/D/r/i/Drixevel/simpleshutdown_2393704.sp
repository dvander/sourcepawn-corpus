#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Shutdown", 
	author = "Keith Warren (Drixevel)", 
	description = "Shuts down a server.", 
	version = "1.0.0", 
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_shutdown", Command_ShutdownServer, ADMFLAG_ROOT);
}

public Action Command_ShutdownServer(int client, int args)
{
	char sIP[32];
	GetConVarString(FindConVar("ip"), sIP, sizeof(sIP));
	PrintToChatAll("#### SERVER RESTART #####\n#### in 2 MINUTES #####\n#### SERVERIP: %s #####", sIP);
	CreateTimer(120.0, ShutdownServer);
}

public Action ShutdownServer(Handle timer)
{
	ServerCommand("_exit");
}