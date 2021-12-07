#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:Is_Plugin_Enabled;

public Plugin:myinfo = 
{
	name = "L4D Remove weapon spawn points",
	author = "Jonny",
	description = "Remove all weapon spawn points",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("l4d_comp_version", PLUGIN_VERSION, "L4D Remove weapon spawn points plugins version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Is_Plugin_Enabled = CreateConVar("l4d_remove_weapons", "1", "Enable L4D Remove weapon spawn points plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	RegAdminCmd("sm_removespawn", RemoveSpawn, ADMFLAG_BAN);
	HookEvent("round_start_post_nav", Event_RoundStart);
	HookEvent("nav_generate", Event_NavGenerate);
}

public OnMapStart()
{
	if (GetConVarInt(Is_Plugin_Enabled) == 0)
	{
		return;
	}
	else
	{
		RemoveAllEntityes();
		return;
	}
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

public RemoveAllEntityByName(const String:EntityName[64])
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, EntityName)) != -1)
	{
		RemoveEdict(entity);
	}
}

public RemoveAllEntityes()
{
	new entity = -1;

	while ((entity = FindEntityByClassname2(entity, "weapon_autoshotgun_spawn")) != -1)
	{
		RemoveEdict(entity);	
	}
	
	while ((entity = FindEntityByClassname2(entity, "weapon_rifle_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_hunting_rifle_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_pumpshotgun_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_smg_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_pain_pills_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_first_aid_kit_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_pipe_bomb_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_molotov_spawn")) != -1)
	{
		RemoveEdict(entity);
	}
//	while ((entity = FindEntityByClassname2(entity, "weapon_ammo_spawn")) != -1)
//	{
//		RemoveEdict(entity);
//	}
}

public Action:TimedRemoveAllEntityes(Handle:timer, any:client)
{
	RemoveAllEntityes();
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) == 0)
		return Plugin_Continue;
		
	RemoveAllEntityes();
	CreateTimer(1.0, TimedRemoveAllEntityes);
	CreateTimer(5.0, TimedRemoveAllEntityes);
	CreateTimer(15.0, TimedRemoveAllEntityes);
	
	return Plugin_Continue;
}

public Action:Event_NavGenerate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) == 0)
		return Plugin_Continue;
		
	RemoveAllEntityes();
	
	return Plugin_Continue;
}

public Action:RemoveSpawn(client, args) //Admin forced a pause
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removespawn <spawn>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	RemoveAllEntityByName(arg);
	
	return Plugin_Continue;
}