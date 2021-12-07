#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[L4D2] Time Contoller",
	author = "McFlurry",
	description = "host_timescale functionality for Left 4 Dead 2.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("sm_timescale_version", PLUGIN_VERSION, "Version of time controller", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_timescale", TimeScale, ADMFLAG_CHEATS ,"Change timescale of game");
}	
	
public Action:TimeScale(client, args)
{
	decl i_Ent, String:arg[12];
	if(args == 1)
	{
		GetCmdArg(1, arg, sizeof(arg));
		new Float:scale = StringToFloat(arg);
		if(scale == 0.0)
		{
			ReplyToCommand(client, "[SM] Invalid Float!");
			return;
		}	
		i_Ent = CreateEntityByName("func_timescale");
		DispatchKeyValue(i_Ent, "desiredTimescale", arg);
		DispatchKeyValue(i_Ent, "acceleration", "2.0");
		DispatchKeyValue(i_Ent, "minBlendRate", "1.0");
		DispatchKeyValue(i_Ent, "blendDeltaMultiplier", "2.0");
		DispatchSpawn(i_Ent);
		AcceptEntityInput(i_Ent, "Start");
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_timescale <float>");
	}	
}