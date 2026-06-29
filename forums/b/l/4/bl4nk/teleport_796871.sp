#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new bool:locSaved;
new Float:savedLoc[3];

// Functions
public Plugin:myinfo =
{
	name = "Teleport",
	author = "bl4nk",
	description = "Teleport to a saved location or the specified coordinates",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("teleport.phrases");

	RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_RCON, "sm_teleport <#userid|name> [x] [y] [z]");
	RegAdminCmd("sm_saveloc", Command_SaveLoc, ADMFLAG_RCON);
	RegConsoleCmd("sm_getloc", Command_GetLoc);
}

public OnMapStart()
{
	locSaved = false;
}

public Action:Command_Teleport(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teleport <#userid|name> [x] [y] [z]");
		return Plugin_Handled;
	}

	new Float:origin[3];
	switch (args)
	{
		case 1:
		{
			if (!locSaved)
			{
				ReplyToCommand(client, "[SM] Either save a location or provide coordinates of where to teleport.");
				return Plugin_Handled;
			}
			else
			{
				origin[0] = savedLoc[0];
				origin[1] = savedLoc[1];
				origin[2] = savedLoc[2];
			}
		}
		case 2:
		{
			decl String:buffer[12];
			GetCmdArg(2, buffer, sizeof(buffer));
			origin[0] = StringToFloat(buffer);

			origin[1] = 0.0;
			origin[2] = 0.0;
		}
		case 3:
		{
			decl String:buffer[12];
			GetCmdArg(2, buffer, sizeof(buffer));
			origin[0] = StringToFloat(buffer);

			GetCmdArg(3, buffer, sizeof(buffer));
			origin[1] = StringToFloat(buffer);

			origin[2] = 0.0;
		}
		case 4:
		{
			decl String:buffer[12];
			GetCmdArg(2, buffer, sizeof(buffer));
			origin[0] = StringToFloat(buffer);

			GetCmdArg(3, buffer, sizeof(buffer));
			origin[1] = StringToFloat(buffer);

			GetCmdArg(4, buffer, sizeof(buffer));
			origin[2] = StringToFloat(buffer);
		}
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		PerformTeleport(client, target_list[i], origin);
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Teleport target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Teleport target", "_s", target_name);
	}

	return Plugin_Handled;
}

public Action:Command_GetLoc(client, args)
{
	new Float:origin[3];
	GetClientAbsOrigin(client, origin);

	ReplyToCommand(client, "%f %f %f", origin[0], origin[1], origin[2]);
	return Plugin_Handled;
}

public Action:Command_SaveLoc(client, args)
{
	GetClientAbsOrigin(client, savedLoc);
	locSaved = true;

	return Plugin_Handled;
}

PerformTeleport(client, target, Float:origin[3])
{
	LogAction(client, target, "\"%L\" teleported \"%L\"", client, target);
	TeleportEntity(target, origin, NULL_VECTOR, NULL_VECTOR);
}