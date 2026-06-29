/**
* NameChanger by bl4nk
*
* Description:
*   Allows an admin with the 'f' flag to change a player's name.
*
* Usage:
*   sm_name <target's name> <name to change to>
*
* Thanks to:
*   Extreme_One for requesting the plugin.
*   theY4Kman for a fix with the single quote bug.
*
* Version 1.4
* Changelog at http://forums.alliedmods.net/showthread.php?t=58825
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

new bool:CanName;

public Plugin:myinfo = 
{
	name = "Name Changer",
	author = "bl4nk and Lebson506th",
	description = "Change the name of a player",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_namechanger_version", PLUGIN_VERSION, "Name Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_name", Command_Name, ADMFLAG_SLAY, "sm_name <user> <name>");

	new String:gamename[31];
	GetGameFolderName(gamename, sizeof(gamename));
	CanName = !(StrEqual(gamename,"tf",false) || StrEqual(gamename,"dod",false));
}

public Action:Command_Name(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_name <user> <name>");
		return Plugin_Handled;
	}

	decl String:target[64], String:name[64];
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, name, sizeof(name));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	decl String:playername[64];
	GetClientName(target_list[0], playername, sizeof(playername));
	ShowActivity(client, "Renamed \"%s\" to \"%s\"", playername, name);

	if(CanName)
	{
		ClientCommand(target_list[0], "name \"%s\"", name);
	}
	else
	{
		SetClientInfo(target_list[0], "name", name);
	}

	return Plugin_Handled;
}