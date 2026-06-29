#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 		"1.0"

public Plugin:myinfo = 
{
	name 			= "[L4D(2)] MW2 Nick",
	author 			= "SwiftReal",
	description 	= "Renames COD Modern Warfare 2 nicknames to readable nicknames",
	version 		= PLUGIN_VERSION,
	url 			= "http://forums.alliedmods.net/showthread.php?p=1117983"
}

public OnPluginStart()
{
	// Register Cmds and Cvars
	CreateConVar("mw2nick_version", PLUGIN_VERSION, "MW2 Nick Rename version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(FindConVar("mw2nick_version"), PLUGIN_VERSION)

	//Execute or create cfg and set currect version
	//AutoExecConfig(true, "mw2nickchange")
	SetConVarString(FindConVar("mw2nick_version"), PLUGIN_VERSION)
}

public OnClientPutInServer(client)
{
	if(client)
	{
		if(!IsFakeClient(client))
		{
			decl String:PlayerName[100]
			GetClientName(client, PlayerName, sizeof(PlayerName))		
			new String:CodeString[5]
			for (new i = 0; i <= 9; i++)
			{
				Format(CodeString, sizeof(CodeString), "^%d", i)
				ReplaceString(PlayerName, sizeof(PlayerName), CodeString, "")
			}			
			ClientCommand(client, "setinfo name \"%s\"", PlayerName)
		}
	}
}