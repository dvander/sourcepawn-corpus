#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"


public Plugin:myinfo = 

{
	name = "Thirdperson",
	author = "Dr. McKay",
	description = "Allows clients to use !thirdperson in games that support ClientCommand",
	version = PLUGIN_VERSION,
	url = "http://www.doctormckay.com"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_thirdperson", Command_Thirdperson, "Type !thirdperson to go into thirdperson");
}

public Action:Command_Thirdperson(client, args)
{
	SendConVarValue(client, FindConVar("sv_cheats"), "1");
	ClientCommand(client, "thirdperson");
}
