
#include <sdktools>
#include <sourcemod>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "[L4D2] SI Coop Limit Bypass",
	author = "MI 5",
	description = "Allows admins to spawn SI that can get around the SI coop limit with a command",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/index.php"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	// This plugin will only work on L4D2
	decl String:GameName[64]
	GetGameFolderName(GameName, sizeof(GameName))
	if (!StrEqual(GameName, "left4dead2", false))
		return APLRes_Failure
	else
	return APLRes_Success
}

public OnPluginStart()
{
	CreateConVar("l4d_si_limit_bypass_version", PLUGIN_VERSION, "Version of L4D2 SI Coop Limit Removal", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	
	RegAdminCmd("sm_ibspawn", Command_SpawnSI, ADMFLAG_CHEATS, "sm_ibspawn <hunter|smoker|boomer|spitter|charger|jockey> <auto> <ragdoll> <area> - Spawns an Infected bot that can bypass the coop limit")
}


public Action:Command_SpawnSI(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ibspawn <hunter|smoker|boomer|spitter|charger|jockey> <auto> <ragdoll> <area> - Spawns an Infected bot that can bypass the coop limit");
		return Plugin_Handled;
	}
	
	decl String:infected[64], String:parameter[64];
	
	GetCmdArg(1, infected, sizeof(infected));
	GetCmdArg(2, parameter, sizeof(parameter));
	
	new bot = CreateFakeClient("Infected Bot");
	if (bot != 0)
	{
		ChangeClientTeam(bot,3);
		CreateTimer(0.1,kickbot,bot);
	}
	
	new anyclient = GetAnyValidClient();
	
	CheatCommand(anyclient, "z_spawn", infected, parameter);
	
	return Plugin_Handled;
}

stock GetAnyValidClient() 
{ 
    for (new target = 1; target <= MaxClients; target++) 
    { 
        if (IsClientInGame(target)) return target; 
    } 
    return -1; 
} 

public Action:kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}
}


stock CheatCommand(client, String:command[], String:argument1[], String:argument2[])
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

