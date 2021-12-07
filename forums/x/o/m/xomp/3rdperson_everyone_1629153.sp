//Includes:
#include <sourcemod>
#include <sdktools>

new bool:ThirdEnabled[MAXPLAYERS+1] = false;


#define PLUGIN_VERSION "1.0"


public Plugin:myinfo = 

{
	name = "Donor Thirdperson",
	author = "EHG",
	description = "Donor Thirdperson",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_thirdperson", Command_thirdperson, "Usage: sm_thirdperson");
	HookEvent("player_spawn", Event_PlayerSpawn);
}


public OnClientPostAdminCheck(client)
{
	ThirdEnabled[client] = false;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ThirdEnabled[client])
	{
		SendConVarValue(client, FindConVar("sv_cheats"), "0");
		ThirdEnabled[client] = false;
	}
}


public Action:Command_thirdperson(client, args)
{
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[Thirdperson] Must be alive to use command");
		return Plugin_Handled;
	}
	
	if (ThirdEnabled[client] == true)
	{
		SendConVarValue(client, FindConVar("sv_cheats"), "0");
		ThirdEnabled[client] = false;
		PrintToChat(client, "\x01[ Thirdperson Disabled ]");
		return Plugin_Handled;
	}
	
	SendConVarValue(client, FindConVar("sv_cheats"), "1");
	ClientCommand(client, "thirdperson");
	
	ThirdEnabled[client] = true;
	PrintToChat(client, "\x01[ Thirdperson Enabled ]");
	return Plugin_Handled;
}
