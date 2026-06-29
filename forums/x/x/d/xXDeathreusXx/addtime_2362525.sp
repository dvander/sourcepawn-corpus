#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.71"

new bWaiting = false;
ConVar hConVar_GlobalTime;
ConVar hConVar_GlobalMaxTime;

// Functions
public Plugin:myinfo =
{
	name = "AddTime",
	author = "bl4nk (modified by belledesire, FlaminSarge, JoBarfCreepy)",
	description = "Add time to the clock via command",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnMapStart()
{
	bWaiting = false;
	FindArena(true);
}
public TF2_OnWaitingForPlayersStart()
{
	if (FindArena()) return;
	bWaiting = true;
}
public TF2_OnWaitingForPlayersEnd()
{
	OnMapEnd();
}
public OnPluginEnd()
{
	OnMapEnd();
}
public OnMapEnd()
{
	bWaiting = false;
}

public OnPluginStart()
{
	CreateConVar("sm_addtime_version", PLUGIN_VERSION, "AddTime Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hConVar_GlobalTime = CreateConVar("sm_addtime_globaltime", "0", "A global time setting to make rounds last this long", FCVAR_PLUGIN);
	hConVar_GlobalMaxTime = CreateConVar("sm_addtime_globalmaxtime", "0", "A global time setting to change max round time", FCVAR_PLUGIN);
	
	HookEvent("teamplay_setup_finished", Event_RoundStart);
	HookEvent("arena_round_start", Event_RoundStart);
	
	RegAdminCmd("sm_addtime", Command_AddTime, ADMFLAG_CHANGEMAP, "sm_addtime <amount>");
	RegAdminCmd("sm_settime", Command_SetTime, ADMFLAG_CHANGEMAP, "sm_settime <amount>");
	RegAdminCmd("sm_maxtime", Command_MaxTime, ADMFLAG_CHANGEMAP, "sm_maxtime <amount>");
}

public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(hConVar_GlobalTime.IntValue)
	{
		decl String:command[32];
		Format(command, sizeof(command), "sm_settime %i", hConVar_GlobalTime.IntValue);
		ServerCommand(command);
	}
	if(hConVar_GlobalTime.IntValue)
	{
		decl String:command[32];
		Format(command, sizeof(command), "sm_maxtime %i", hConVar_GlobalMaxTime.IntValue);
		ServerCommand(command);
	}
}

public Action:Command_AddTime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[%s] Usage: sm_addtime <amount>", "AddTime");
		return Plugin_Handled;
	}

	if (!bWaiting)
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

	if (!bWaiting)
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

public Action:Command_MaxTime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[%s] Usage: sm_maxtime <amount>", "AddTime");
		return Plugin_Handled;
	}

	decl String:cmdArg[32];
	GetCmdArg(1, cmdArg, sizeof(cmdArg));

	new bool:bEntityFound = false;

	new entityTimer = MaxClients + 1;
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
			AcceptEntityInput(entityTimer, "SetMaxTime");
		}
		else
		{
			SetVariantInt(StringToInt(cmdArg));
			AcceptEntityInput(entityTimer, "SetMaxTime");
		}
	}
	if (!bEntityFound)
	{
		new Handle:timelimit = FindConVar("mp_timelimit");
		SetConVarFloat(timelimit, GetConVarFloat(timelimit) + (StringToFloat(cmdArg) / 60));
		CloseHandle(timelimit);
	}
	PrintToChatAll("\x04[\x03%s\x04]\x01 Max time was set to %i second(s)", "AddTime", StringToInt(cmdArg));
	return Plugin_Handled;
}
stock bool:FindArena(bool:forceRecalc = false)
{
	static bool:arena = false;
	static bool:found = false;
	if (forceRecalc)
	{
		found = false;
		arena = false;
	}
	if (!found)
	{
		new i = -1;
		while ((i = FindEntityByClassname2(i, "tf_logic_arena")) != -1)
		{
			arena = true;
		}
		found = true;
	}
	return arena;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}