#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo =
{
	name = "L4D2 Set Survivor Model",
	author = "AtomicStryker",
	description = "Set a Players Survivor Model",
	version = PLUGIN_VERSION,
	url = ""
}

new Handle:MyModelAllowedCvar = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_setmodel", Command_SetModel, ADMFLAG_CHEATS, "sm_setmodel <player> <nick|rochelle|coach|ellis> - set a Players Survivor Model");
	RegAdminCmd("sm_getmodel", Command_GetModel, ADMFLAG_CHEATS, "sm_getmodel <player> - get a Players Model and character value");
	RegConsoleCmd("sm_setmymodel", Command_SetMyModel, "sm_setmymodel <nick|rochelle|coach|ellis|bill|zoey|louis|francis> - choose the Survivor you'd like to be");
	
	CreateConVar("l4d2_setsurvivormodel_version", PLUGIN_VERSION, "The version of L4D2 Set Survivor Model on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	MyModelAllowedCvar = CreateConVar("l4d2_setsurvivormodel_freechoice", "0", "Do you allow players to use the sm_setmymodel command", FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public Action:Command_GetModel(client, args)
{
	new survoffset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");

	decl String:player[64], String:model[256];
	GetCmdArg(1, player, sizeof(player));
	new player_id = FindTarget(client, player);
	
	PrintToChat(client, "His or her current m_survivorCharacter offset: %i", GetEntData(player_id, survoffset, 1));
	
	GetClientModel(player_id, model, sizeof(model));
	PrintToChat(client, "His or her current character model: %s", model);
	
	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl")) PrecacheModel("models/survivors/survivor_teenangst.mdl", true);
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl")) PrecacheModel("models/survivors/survivor_biker.mdl", true);
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl")) PrecacheModel("models/survivors/survivor_manager.mdl", true);
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl")) PrecacheModel("models/survivors/survivor_namvet.mdl", true);
	
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl")) PrecacheModel("models/survivors/survivor_gambler.mdl", true);
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl")) PrecacheModel("models/survivors/survivor_mechanic.mdl", true);
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl")) PrecacheModel("models/survivors/survivor_producer.mdl", true);
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl")) PrecacheModel("models/survivors/survivor_coach.mdl", true);
}

public Action:Command_SetModel(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmodel <player> <nick|rochelle|coach|ellis|bill|zoey|louis|francis> - set a Players Survivor Model");
		return Plugin_Handled;
	}
	
	new survoffset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
	
	decl String:player[64], String:model[64];
	
	GetCmdArg(1, player, sizeof(player));
	GetCmdArg(2, model, sizeof(model));
	
	new player_id = FindTarget(client, player);
	
	if (StrEqual(model, "Nick", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 0, 1, true);	
		SetEntityModel(player_id, "models/survivors/survivor_gambler.mdl");
	}
	else if (StrEqual(model, "Rochelle", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 1, 1, true);			
		SetEntityModel(player_id, "models/survivors/survivor_producer.mdl");
	}
	else if (StrEqual(model, "Coach", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 2, 1, true);				
		SetEntityModel(player_id, "models/survivors/survivor_coach.mdl");
	}
	else if (StrEqual(model, "Ellis", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 3, 1, true);
		SetEntityModel(player_id, "models/survivors/survivor_mechanic.mdl");
	}
	else if (StrEqual(model, "Bill", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 0, 1, true);
		SetEntityModel(player_id, "models/survivors/survivor_namvet.mdl");
	}
	else if (StrEqual(model, "Zoey", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 1, 1, true);	
		SetEntityModel(player_id, "models/survivors/survivor_teenangst.mdl");
	}
	else if (StrEqual(model, "Louis", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 2, 1, true);				
		SetEntityModel(player_id, "models/survivors/survivor_manager.mdl");
	}
	else if (StrEqual(model, "Francis", false))
	{
		if (GetClientTeam(player_id) == 2) SetEntData(player_id, survoffset, 3, 1, true);			
		SetEntityModel(player_id, "models/survivors/survivor_biker.mdl");
	}
	
	return Plugin_Handled;
}

public Action:Command_SetMyModel(client, args)
{
	if (!GetConVarBool(MyModelAllowedCvar))
	{
		ReplyToCommand(client, "The Admin has disallowed using this command");
		return Plugin_Handled;		
	}

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmymodel <nick|rochelle|coach|ellis|bill|zoey|louis|francis> - set your Survivor Model");
		return Plugin_Handled;
	}
	
	new survoffset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
	
	decl String:model[64];
	
	GetCmdArg(1, model, sizeof(model));
	
	if (StrEqual(model, "Nick", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 0, 1, true);	
		SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
	}
	else if (StrEqual(model, "Rochelle", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 1, 1, true);			
		SetEntityModel(client, "models/survivors/survivor_producer.mdl");
	}
	else if (StrEqual(model, "Coach", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 2, 1, true);				
		SetEntityModel(client, "models/survivors/survivor_coach.mdl");
	}
	else if (StrEqual(model, "Ellis", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 3, 1, true);
		SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
	}
	else if (StrEqual(model, "Bill", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 0, 1, true);
		SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
	}
	else if (StrEqual(model, "Zoey", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 1, 1, true);	
		SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
	}
	else if (StrEqual(model, "Louis", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 2, 1, true);				
		SetEntityModel(client, "models/survivors/survivor_manager.mdl");
	}
	else if (StrEqual(model, "Francis", false))
	{
		if (GetClientTeam(client) == 2) SetEntData(client, survoffset, 3, 1, true);			
		SetEntityModel(client, "models/survivors/survivor_biker.mdl");
	}
	
	return Plugin_Handled;
}