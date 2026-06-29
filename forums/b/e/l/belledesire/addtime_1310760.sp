#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.6"

new iRounds = 0;

// Functions
public Plugin:myinfo =
{
	name = "AddTime",
	author = "bl4nk (modified by belledesire)",
	description = "Add time to the clock via command",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnMapStart()
{
	iRounds = 0;
}

public OnPluginStart()
{
	CreateConVar("sm_addtime_version", PLUGIN_VERSION, "AddTime Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_addtime", Command_AddTime, ADMFLAG_CHANGEMAP, "sm_addtime <amount>");
	RegAdminCmd("sm_settime", Command_SetTime, ADMFLAG_CHANGEMAP, "sm_settime <amount>");

	HookEvent("teamplay_round_active", Event_Round_Start);
	HookEvent("arena_round_start", Event_ArenaRound_Start);
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	iRounds++; //First Round == "waiting for players"
}

public Action:Event_ArenaRound_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	iRounds++; //First Round == "waiting for players"
	iRounds++; //We don't have a "waiting for players", so compensate this
}

public Action:Command_AddTime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[%s] Usage: sm_addtime <amount>", "AddTime");
		return Plugin_Handled;
	}

	if (iRounds > 1)
	{
		decl String:cmdArg[32];
		GetCmdArg(1, cmdArg, sizeof(cmdArg));

		new bool:bEntityFound = false;

		new entityTimer = MaxClients+1;
		while((entityTimer = FindEntityByClassname(entityTimer, "team_round_timer"))!=-1)
		{
			bEntityFound = true;
		
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
	
		if (!bEntityFound)
		{
			new Handle:timelimit = FindConVar("mp_timelimit");
			SetConVarFloat(timelimit, GetConVarFloat(timelimit) + (StringToFloat(cmdArg) / 60));
			CloseHandle(timelimit);
		}
	
		PrintToChatAll("\x04[\x03%s\x04]\x01 Added %i second(s) to the time", "AddTime", StringToInt(cmdArg));
	}
	else
	{
		ReplyToCommand(client, "[%s] Cannot change time during wait-time", "AddTime");
	}

	return Plugin_Handled;
}

public Action:Command_SetTime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[%s] Usage: sm_settime <amount>", "AddTime");
		return Plugin_Handled;
	}

	if (iRounds > 1)
	{
		decl String:cmdArg[32];
		GetCmdArg(1, cmdArg, sizeof(cmdArg));

		new bool:bEntityFound = false;
	
		new entityTimer = MaxClients+1;
		while((entityTimer = FindEntityByClassname(entityTimer, "team_round_timer"))!=-1)
		{
			bEntityFound = true;

			SetVariantInt(StringToInt(cmdArg));
			AcceptEntityInput(entityTimer, "SetTime");
		}

		if (!bEntityFound)
		{
			new Handle:timelimit = FindConVar("mp_timelimit");
			SetConVarFloat(timelimit, StringToFloat(cmdArg) / 60);
			CloseHandle(timelimit);
		}

		PrintToChatAll("\x04[\x03%s\x04]\x01 Time was set to %i second(s)", "AddTime", StringToInt(cmdArg));
	}
	else
	{
		ReplyToCommand(client, "[%s] Cannot change time during wait-time", "AddTime");
	}

	return Plugin_Handled;
}