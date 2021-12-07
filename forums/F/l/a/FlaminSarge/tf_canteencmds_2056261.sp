#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_NAME		"[TF2] Canteen Commands"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.0"
#define PLUGIN_CONTACT		"https://forums.alliedmods.net/showthread.php?t=229183"
#define PLUGIN_DESCRIPTION	"A set of commands for messing with the Powerup Canteens"

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};
public OnPluginStart()
{
	CreateConVar("tf_canteencommands_version", PLUGIN_VERSION, "[TF2] Canteen Commands version", FCVAR_NOTIFY|FCVAR_PLUGIN);
	RegAdminCmd("sm_setcanteen", Cmd_SetPowerBottle, ADMFLAG_CHEATS, "Sets the number of charges on a client's canteen. An extra parameter will remove all powerups from it and set a new powerup.");
	RegAdminCmd("sm_addcanteen", Cmd_AddPowerBottle, ADMFLAG_CHEATS, "Adds a powerup to a client's canteen.");
	LoadTranslations("common.phrases");
}
public Action:Cmd_SetPowerBottle(client, args)
{
	if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcanteen <target> <charges> [powerup]");
		return Plugin_Handled;
	}
	decl String:arg1[32];
	decl String:arg2[32];
	decl String:arg3[64];
	if (args > 2)
	{
		GetCmdArgString(arg3, sizeof(arg3));
		new idx = BreakString(arg3, arg1, sizeof(arg1));
		strcopy(arg3, sizeof(arg3), arg3[idx]);
		idx = BreakString(arg3, arg1, sizeof(arg1));
		strcopy(arg3, sizeof(arg3), arg3[idx]);
		StripQuotes(arg3);
	}
	if (args > 2
		&& !StrEqual(arg3, "recall")
		&& !StrEqual(arg3, "ubercharge")
		&& !StrEqual(arg3, "critboost")
		&& !StrEqual(arg3, "building instant upgrade")
		&& !StrEqual(arg3, "refill_ammo"))
	{
		ReplyToCommand(client, "[SM] Invalid powerup '%s'. Valid powerups are 'recall', 'ubercharge', 'critboost', 'building instant upgrade', and 'refill_ammo'.", arg3);
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new charges = StringToInt(arg2);
	if (charges < 0) charges = 0;
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			(args <= 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new bottle = FindBottle(target_list[i]);
		if (bottle != -1)
		{
			SetEntProp(bottle, Prop_Send, "m_usNumCharges", charges);
			if (args <= 2
				&& TF2Attrib_GetByName(bottle, "recall") == Address_Null
				&& TF2Attrib_GetByName(bottle, "ubercharge") == Address_Null
				&& TF2Attrib_GetByName(bottle, "critboost") == Address_Null
				&& TF2Attrib_GetByName(bottle, "building instant upgrade") == Address_Null
				&& TF2Attrib_GetByName(bottle, "refill_ammo") == Address_Null)
			{
				TF2Attrib_SetByName(bottle, "recall", 1.0);
			}
			if (args > 2)
			{
				TF2Attrib_RemoveByName(bottle, "recall");
				TF2Attrib_RemoveByName(bottle, "ubercharge");
				TF2Attrib_RemoveByName(bottle, "critboost");
				TF2Attrib_RemoveByName(bottle, "building instant upgrade");
				TF2Attrib_RemoveByName(bottle, "refill_ammo");
				TF2Attrib_SetByName(bottle, arg3, 1.0);
			}
		}
	}
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "set canteen charges on %t to %d%s%s", target_name, charges, args > 2 ? ", with powerup " : "", args > 2 ? arg3 : "");
	else
		ShowActivity2(client, "[SM] ", "set canteen charges on %s to %d%s%s", target_name, charges, args > 2 ? ", with powerup " : "", args > 2 ? arg3 : "");
	return Plugin_Handled;
}

public Action:Cmd_AddPowerBottle(client, args)
{
	if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcanteen <target> <powerup>\nValid powerups are 'recall', 'ubercharge', 'critboost', 'building instant upgrade', and 'refill_ammo'.");
		return Plugin_Handled;
	}
	decl String:arg1[32];
	decl String:arg3[64];
	GetCmdArgString(arg3, sizeof(arg3));
	new idx = BreakString(arg3, arg1, sizeof(arg1));
	strcopy(arg3, sizeof(arg3), arg3[idx]);
	if (!StrEqual(arg3, "recall")
		&& !StrEqual(arg3, "ubercharge")
		&& !StrEqual(arg3, "critboost")
		&& !StrEqual(arg3, "building instant upgrade")
		&& !StrEqual(arg3, "refill_ammo"))
	{
		ReplyToCommand(client, "[SM] Invalid powerup '%s'. Valid powerups are 'recall', 'ubercharge', 'critboost', 'building instant upgrade', and 'refill_ammo'.", arg3);
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			(args <= 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new bottle = FindBottle(target_list[i]);
		if (bottle != -1)
		{
			TF2Attrib_SetByName(bottle, arg3, 1.0);
		}
	}
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "added powerup %s to canteen of %t", arg3, target_name);
	else
		ShowActivity2(client, "[SM] ", "added powerup %s to canteen of %s", arg3, target_name);
	return Plugin_Handled;
}

stock FindBottle(client)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable"))
		{
			return i;
		}
	}
	return -1;
}