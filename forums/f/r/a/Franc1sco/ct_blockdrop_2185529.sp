#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
	name = "SM CT Block Drop",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://www.zeuszombie.com/"
};

public OnPluginStart()
{
	RegConsoleCmd("drop", Command_Drop);
}

public Action:Command_Drop(client, args)
{
	if(GetClientTeam(client) == CS_TEAM_CT) return Plugin_Handled;
	
	return Plugin_Continue;
}