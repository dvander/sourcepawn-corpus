#include <sourcemod>

public Plugin:myinfo = 
{
	name = "SM Command Blocker",
	author = "exvel",
	description = "Blocks 'sm plugins' command",
	version = "1.0.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	RegConsoleCmd("sm", Command_SM);
}

public Action:Command_SM(client, args)
{
	if (client == 0)
		return Plugin_Continue;
	
	if (GetUserFlagBits(client))
		return Plugin_Continue;
	
	if (args < 1)
		return Plugin_Continue;
	
	decl String:szArg[32];
	GetCmdArg(1, szArg, sizeof(szArg));
	
	if (StrEqual(szArg, "plugins"))
		return Plugin_Handled;
	
	return Plugin_Continue;
}
