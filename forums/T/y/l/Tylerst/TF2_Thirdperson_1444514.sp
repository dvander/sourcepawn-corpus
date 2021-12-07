#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "TF2 Thirdperson",
	author = "Tylerst",
	description = "Activate thirdperson in TF2 without the need for sv_cheats to be active on the server",
	version = PLUGIN_VERSION,
};

public OnPluginStart()
{
	RegAdminCmd("sm_thirdperson", Command_Thirdperson, ADMFLAG_CHEATS);
	RegAdminCmd("sm_firstperson", Command_Firstperson, ADMFLAG_CHEATS);
}

public Action:Command_Thirdperson(client, args)
{	
	SendConVarValue(client, FindConVar("sv_cheats"), "1");
	ClientCommand(client,"thirdperson")
	return Plugin_Handled;		
}
public Action:Command_Firstperson(client, args)
{	
	SendConVarValue(client, FindConVar("sv_cheats"), "0");
	return Plugin_Handled;		
}