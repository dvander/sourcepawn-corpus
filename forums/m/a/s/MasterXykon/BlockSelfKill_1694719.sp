// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1				  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME				"Block Self Kill"
#define PLUGIN_AUTHOR			"Master Xykon"
#define PLUGIN_VERSION			"1.0.0"
#define PLUGIN_CONTACT			"http://forums.alliedmods.net/"
#define CVAR_FLAGS				FCVAR_PLUGIN|FCVAR_NOTIFY



new SM_SelfKill;
new SM_SelfExplode;


public OnPluginStart()
{
	SM_SelfKill = CreateConVar("block_selfkill",  "0",  "Block Self Kill - 0 = disabled, 1 = enabled");
	SM_SelfExplode = CreateConVar("block_selfexplode",  "0",  "Block Self Explode - 0 = disabled, 1 = enabled");
	AddCommandListener(Admin_Kill,  "kill");
	AddCommandListener(Admin_Explode,  "explode");
}

public Action:Admin_Kill(client,  const String:command[],  argc)
{
	if(GetConVarInt(SM_SelfKill) == 1)
	{
		PrintToChat(client,  "Self Kill is now Blocked");
		return Plugin_Handled;
	}
}

public Action:Admin_Explode(client,  const String:command[],  argc)
{
	if(GetConVarInt(SM_SelfExplode) == 1)
	{
		PrintToChat(client,  "Self Explode is now Blocked");
		return Plugin_Handled;
	}
}

