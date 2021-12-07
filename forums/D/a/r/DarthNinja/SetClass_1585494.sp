#include <sourcemod>
#include <tf2_stocks>

#define VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "[TF2] Set Player Class",
	author = "DarthNinja",
	description = "Changes a player's class",
	version = VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_setplayerclass_version", VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_setplayerclass", SetPlayerClass, ADMFLAG_CHEATS, "Set a player's class");
}

public Action:SetPlayerClass(client, args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "Usage: sm_setplayerclass <client> [class]");
		return Plugin_Handled;
	}

	decl String:buffer[64];
	decl String:classbuffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));

	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new TFClassType:iClass;
	if (args > 1)
	{
		GetCmdArg(2, classbuffer, sizeof(classbuffer));
		iClass = TF2_GetClass(classbuffer);
		if (iClass == TFClass_Unknown)
		{
			ReplyToCommand(client, "Unknown class %s! Using a random class!", classbuffer);
			iClass = TFClassType:GetRandomInt(1, 9);
		}
	}
	else
		iClass = TFClassType:GetRandomInt(1, 9);
	
	new count = 0;
	for (new i = 0; i < target_count; i ++)
	{
		if (TF2_GetPlayerClass(target_list[i]) != iClass)
		{
			TF2_SetPlayerClass(target_list[i], iClass, false, false);
			count ++;
		}
	}
	
	if (count == 0)
		ReplyToCommand(client, "\x04[\x03SM\x04]\x01: Target player is already that class!");
	else if (count == 1)
		ReplyToCommand(client, "\x04[\x03SM\x04]\x01: Set \x04%s's\x01 class to \x05'%s'\x01!", target_name, classbuffer);
	else
		ReplyToCommand(client, "\x04[\x03SM\x04]\x01: Changed \x04%i\x01 players to \x05'%s'\x01!", count, classbuffer);
		
	return Plugin_Handled
}