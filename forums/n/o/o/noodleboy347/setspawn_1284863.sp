#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.13"

new bool:pSpawnSet[MAXPLAYERS+1];
new Float:pSpawn[MAXPLAYERS+1][3];

new Handle:cEnabled;

public Plugin:myinfo = 
{
	name = "Player Spawns",
	author = "noodleboy347",
	description = "Sets player spawns",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_setspawn", Command_Setspawn);
	RegConsoleCmd("sm_clearspawn", Command_Clearspawn);
	RegAdminCmd("sm_setplayerspawn", Command_Setplayerspawn, ADMFLAG_GENERIC);
	RegAdminCmd("sm_clearplayerspawn", Command_Clearplayerspawn, ADMFLAG_GENERIC);
	CreateConVar("sm_playerspawns_version", PLUGIN_VERSION, "Player Spawns plugin version", FCVAR_NOTIFY);
	cEnabled = CreateConVar("sm_playerspawns_enable", "1", "Enables plugin");
	HookConVarChange(cEnabled, Cvar_Toggle);
	HookEvent("player_spawn", Event_Spawn);
}

public Cvar_Toggle(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(StringToInt(newVal) == 0)
	{
		for(new i=1; i < GetMaxClients(); i++)
		{
			pSpawnSet[i] = false;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	pSpawnSet[client] = false;
}

public Action:Command_Setspawn(client, args)
{
	if(GetConVarBool(cEnabled) && IsPlayerAlive(client))
	{
		GetClientAbsOrigin(client, pSpawn[client]);
		pSpawnSet[client] = true;
		ReplyToCommand(client, "[SM] Spawn location set.");
	}
	return Plugin_Handled;
}

public Action:Command_Clearspawn(client, args)
{
	if(GetConVarBool(cEnabled))
	{
		if(!pSpawnSet[client])
			ReplyToCommand(client, "[SM] You haven't set your spawn yet.");
		else
		{
			ReplyToCommand(client, "[SM] Spawn location cleared.");
			pSpawnSet[client] = false;
		}
	}
	return Plugin_Handled;
}

public Action:Command_Setplayerspawn(client, args)
{
	if(GetConVarBool(cEnabled))
	{
		if(args != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_setplayerspawn <player>");
			return Plugin_Handled;
		}
		decl String:arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if((target_count = ProcessTargetString(
				arg,
				client, 
				target_list, 
				MAXPLAYERS, 
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(new i = 0; i < target_count; i++)
		{
			GetClientAbsOrigin(client, pSpawn[target_list[i]]);
			pSpawnSet[target_list[i]] = true;
		}
		if(tn_is_ml)
			ShowActivity2(client, "[SM]", "Set the spawn of %s", target_name);
		else
			ShowActivity2(client, "[SM]", "Set the spawn of %s", target_name);
	}
	return Plugin_Handled;	
}

public Action:Command_Clearplayerspawn(client, args)
{
	if(GetConVarBool(cEnabled))
	{
		if(args != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_clearplayerspawn <player>");
			return Plugin_Handled;
		}
		decl String:arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if((target_count = ProcessTargetString(
				arg,
				client, 
				target_list, 
				MAXPLAYERS, 
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(new i = 0; i < target_count; i++)
			pSpawnSet[target_list[i]] = false;
		if(tn_is_ml)
			ShowActivity2(client, "[SM]", "Cleared the spawn of %s", target_name);
		else
			ShowActivity2(client, "[SM]", "Cleared the spawn of %s", target_name);
	}
	return Plugin_Handled;	
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(pSpawnSet[client])
		CreateTimer(0.1, Timer_Spawn, client);
}

public Action:Timer_Spawn(Handle:timer, any:client)
{
	TeleportEntity(client, pSpawn[client], NULL_VECTOR, NULL_VECTOR);
}