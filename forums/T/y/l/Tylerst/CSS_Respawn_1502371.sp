#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = 
{
	
	name = "CSS Respawn",
	
	author = "Tylerst",

	description = "Type !respawn to respawn yourself or bind a key to sm_respawn",

	version = "1.0",
	
	url = "None"

};



public OnPluginStart()
{
	RegConsoleCmd("sm_respawn", Command_Respawn, "Type !respawn to respawn yourself or bind a key to sm_respawn");	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "cstrike"))
	{
		Format(error, err_max, "This plugin only works for Counter-Strike:Source");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Action:Command_Respawn(client, args)
{
	if(client == 0) return Plugin_Handled;
	if(IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You must be dead to use this command");
		return Plugin_Handled;
	}
	else
	{
		CS_RespawnPlayer(client);
		PrintToChat(client, "You have been respawned");
	}
	return Plugin_Handled;
}