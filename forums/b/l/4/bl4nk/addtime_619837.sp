#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Global Definitions
#define PLUGIN_VERSION "1.0.4"

// Functions
public Plugin:myinfo =
{
	name = "AddTime",
	author = "bl4nk",
	description = "Add time to the clock via command",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_addtime_version", PLUGIN_VERSION, "AddTime Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_addtime", Command_AddTime, ADMFLAG_CHANGEMAP, "sm_addtime <amount>");
	RegAdminCmd("sm_settime", Command_SetTime, ADMFLAG_CHANGEMAP, "sm_settime <amount>");
}

public Action:Command_AddTime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addtime <amount>");
		return Plugin_Handled;
	}

	decl String:cmdArg[32];
	GetCmdArg(1, cmdArg, sizeof(cmdArg));

	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		decl String:mapName[32];
		GetCurrentMap(mapName, sizeof(mapName));

		if (strncmp(mapName, "pl_", 3) == 0)
		{
			decl String:buffer[32];
			Format(buffer, sizeof(buffer), "0 %i", StringToInt(cmdArg));

			SetVariantString(buffer);
			AcceptEntityInput(entityTimer, "AddTeamTime");
		}
		else
		{
			SetVariantInt(StringToInt(cmdArg));
			AcceptEntityInput(entityTimer, "AddTime");
		}
	}
	else
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, GetConVarFloat(timelimit) + (StringToFloat(cmdArg) / 60));
		CloseHandle(timelimit);
	}

	return Plugin_Handled;
}

public Action:Command_SetTime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_settime <amount>");
		return Plugin_Handled;
	}

	decl String:cmdArg[32];
	GetCmdArg(1, cmdArg, sizeof(cmdArg));

	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		SetVariantInt(StringToInt(cmdArg));
		AcceptEntityInput(entityTimer, "SetTime");
	}
	else
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, StringToFloat(cmdArg) / 60);
		CloseHandle(timelimit);
	}

	return Plugin_Handled;
}