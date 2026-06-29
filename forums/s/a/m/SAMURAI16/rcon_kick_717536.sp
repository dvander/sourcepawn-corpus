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
}

public Action:OnClientCommand(client,args)
{
	new String:arg[32];
	GetCmdArg(1,arg,sizeof(arg));
	
	if(StrContains(arg,"rcon") != -1)
		KickClient(client);
	
}

