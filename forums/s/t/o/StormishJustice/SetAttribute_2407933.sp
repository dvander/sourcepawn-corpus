#pragma semicolon 1

#include <tf2>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0.2"

//	Credits:
//Deathreus (solving me stuff about making the set attributes and remove attributes code wrong)
//Tylerst (original code [TF2_AddCond.smx])

public Plugin:myinfo =
{
	name = "[TF2] Set Client Attribute",
	author = "StormishJustice",
	description = "Sets an attribute to the target(s)",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2407933"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_setattribclient", Command_SetAttribClient, ADMFLAG_GENERIC, "Sets an attribute to the target(s), Usage: sm_setattribclient \"target\" \"attribute name\" \"value\"");
	RegAdminCmd("sm_removeattribclient", Command_RemoveAttribClient, ADMFLAG_GENERIC, "Removes an attribute from the target(s), Usage: sm_removeattribclient \"target\" \"attribute name\"");
	RegAdminCmd("sm_removeallattribsclient", Command_RemoveAllAttribsClient, ADMFLAG_GENERIC, "Removes all attributes from the target(s), Usage: sm_removeallattribsclient \"target\"");
}

public Action:Command_SetAttribClient(client, args)
{

	if(args != 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setattribclient \"target\" \"attribute index\" \"value\"");
		return Plugin_Handled;
	}

	new String:strBuffer[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new String:strAttrib[64], Float:flValue;

	GetCmdArg(2, strAttrib, sizeof(strBuffer));

	GetCmdArg(3, strBuffer, sizeof(strBuffer));
	flValue = StringToFloat(strBuffer);	

	for(new i = 0; i < target_count; i++)
	{
		TF2Attrib_SetByName(target_list[i], strAttrib, flValue);
	}
	return Plugin_Handled;
}

public Action:Command_RemoveAttribClient(client, args)
{

	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removeattribclient \"target\" \"attribute index\"");
		return Plugin_Handled;
	}

	new String:strBuffer[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new String:strAttrib[64];

	GetCmdArg(2, strAttrib, sizeof(strBuffer));

	for(new i = 0; i < target_count; i++)
	{
		TF2Attrib_RemoveByName(target_list[i], strAttrib);
	}
	return Plugin_Handled;
}

public Action:Command_RemoveAllAttribsClient(client, args)
{

	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removeallattribsclient \"target\"");
		return Plugin_Handled;
	}

	new String:strBuffer[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		TF2Attrib_RemoveAll(target_list[i]);
	}
	return Plugin_Handled;
}