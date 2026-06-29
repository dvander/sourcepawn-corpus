#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "L4D SM Set Model",
	author = "AtomicStryker",
	description = "Set a Players Survivor Model",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_setmodel", Command_SetModel, ADMFLAG_BAN, "sm_setmodel <player> <survivorname> - set a Players Survivor Model");
	RegAdminCmd("sm_leetme", Command_LeetMe, ADMFLAG_BAN, "sm_leetme - sets your checkpoint Zombie Killcount to 1337");
}

public Action:Command_SetModel(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmodel <player> <character> - set a Players Survivor Model");
		return Plugin_Handled;
	}
	
	new survoffset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
	
	decl String:player[64], String:model[64];
	
	GetCmdArg(1, player, sizeof(player));
	GetCmdArg(2, model, sizeof(model));
	
	new player_id = FindTarget(client, player);
	
	
	if (StrEqual(model, "Zoey", false))
	{
		if (GetClientTeam(player_id)==2) SetEntData(player_id, survoffset, 1, 1, true);	
		SetEntityModel(player_id, "models/survivors/survivor_teenangst.mdl");
	}
	if (StrEqual(model, "Francis", false))
	{
		if (GetClientTeam(player_id)==2) SetEntData(player_id, survoffset, 2, 1, true);			
		SetEntityModel(player_id, "models/survivors/survivor_biker.mdl");
	}
	if (StrEqual(model, "Louis", false))
	{
		if (GetClientTeam(player_id)==2) SetEntData(player_id, survoffset, 3, 1, true);				
		SetEntityModel(player_id, "models/survivors/survivor_manager.mdl");
	}
	if (StrEqual(model, "Bill", false))
	{
		if (GetClientTeam(player_id)==2) SetEntData(player_id, survoffset, 4, 1, true);
		SetEntityModel(player_id, "models/survivors/survivor_namvet.mdl");
	}
	if (StrEqual(model, "Smoker", false))
	{
		SetEntityModel(player_id, "models/infected/smoker.mdl");
	}
	if (StrEqual(model, "Hunter", false))
	{
		SetEntityModel(player_id, "models/infected/hunter.mdl");
	}
	if (StrEqual(model, "Boomer", false))
	{
		SetEntityModel(player_id, "models/infected/boomer.mdl");
	}
	if (StrEqual(model, "Tank", false))
	{
		SetEntityModel(player_id, "models/infected/hulk.mdl");
	}
	if (StrEqual(model, "Witch", false))
	{
		SetEntityModel(player_id, "models/infected/witch.mdl");
	}
	
	return Plugin_Handled;
}

public Action:Command_LeetMe(client, args)
{
	new killoffset = FindSendPropInfo("CTerrorPlayer", "m_checkpointZombieKills");
	SetEntData(client, killoffset, 1337, 2);
	ReplyToCommand(client, "You got 1337, you hero.");
	return Plugin_Handled;
}