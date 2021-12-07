#include <sourcemod>

public Plugin:myinfo =
{
	name = "Delay alive player move spec",
	author = "Bacardi",
	description = "Delay player to move spectators when alive",
	version = "0.3",
	url = "www.sourcemod.net"
}

new Handle:movespec[MAXPLAYERS] = INVALID_HANDLE;
new Handle:sm_movespec_delay = INVALID_HANDLE;
new Float:movespec_delay;

public OnPluginStart()
{
	AddCommandListener(cmd_jointeam, "jointeam");
	AddCommandListener(cmd_jointeam, "spectate");
	sm_movespec_delay = CreateConVar("sm_movespec_delay", "5.0", "Delay player to move spectators when alive in seconds", FCVAR_NONE, true, 0.0, true, 10.0);
	movespec_delay = GetConVarFloat(sm_movespec_delay);
	HookConVarChange(sm_movespec_delay, ConVarChanged);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == sm_movespec_delay)
	{
		movespec_delay = StringToFloat(newValue);
	}
}

public Action:cmd_jointeam(client, const String:command[], argc)
{
	// Skip when these...
	if(movespec_delay < 1.0 || client == 0 || !IsClientInGame(client) || IsFakeClient(client) || CheckCommandAccess(client, "sm_spec_delay", ADMFLAG_GENERIC))
	{
		return Plugin_Continue;
	}

	decl team;
	if(StrEqual(command, "jointeam", false))
	{
		decl String:arg[3];
		arg[0] = '\0';
		GetCmdArg(1, arg, sizeof(arg))
		team = StringToInt(arg);
	}
	else // cmd spectate
	{
		team = 1;
	}

	if(team == 1)
	{
		if(IsPlayerAlive(client))
		{
			if(movespec[client] == INVALID_HANDLE)
			{
				movespec[client] = CreateTimer(movespec_delay, TimerMoveSpec, client);
				movespec_delay >= 2.0 ? PrintToChat(client, "[SM] You will be move to spectators within %0.1f seconds", movespec_delay):0;
			}
			return Plugin_Handled;
		}
		else
		{
			if(movespec[client] != INVALID_HANDLE)
			{
				KillTimer(movespec[client]);
				movespec[client] = INVALID_HANDLE;
			}
		}
	}
	return Plugin_Continue;
}

public Action:TimerMoveSpec(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		ChangeClientTeam(client, 1);
	}
	movespec[client] = INVALID_HANDLE;
}

public OnClientDisconnect(client)
{
	if(movespec[client] != INVALID_HANDLE)
	{
		KillTimer(movespec[client]);
		movespec[client] = INVALID_HANDLE;
	}
}