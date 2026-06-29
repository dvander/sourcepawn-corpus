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
* Version 1.3
* Changelog at http://forums.alliedmods.net/showthread.php?t=58825
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "Name Changer",
	author = "bl4nk",
	description = "Change the name of a player",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("namechanger.phrases");
	
	CreateConVar("sm_namechanger_version", PLUGIN_VERSION, "Name Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_name", Command_Name, ADMFLAG_SLAY, "sm_name <user> <name>");
}

public Action:Command_Name(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_name <user> <name>");
		return Plugin_Handled;
	}

	new String:target[64];
	GetCmdArg(1, target, sizeof(target));

	new String:name[64];
	GetCmdArg(2, name, sizeof(name));

	new player;
	if(target[0] == '#' && (player = StringToInt(target[1]))  )
	{
		if( !(player = GetClientOfUserId(player)) )
		{
			PrintToConsole(client, "Invalid user id: %i", StringToInt(target[1])  );
			return Plugin_Handled;
		}
	}
	else if( player = StringToInt(target) )
	{
		if( !(player = GetClientOfUserId(player)) )
		{
			PrintToConsole(client, "Invalid user id: %i", StringToInt(target[1])  );
			return Plugin_Handled;
		}
	}
	else
	{
		new clients[2];
		SearchForClients(target, clients, 2);
	
		if (!FindTarget(client, target) || clients[1])
		{
			return Plugin_Handled;
		}

		player = clients[0];
	}

	PrintToChat(player, "[SM] %t", "Name Changed");
	PrintToConsole(client, "[SM] %t", "Name Changed");
	ClientCommand(player, "name \"%s\"", name);

	return Plugin_Handled;
}