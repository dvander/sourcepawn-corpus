/*
 * by: shanapu
 * https://github.com/shanapu/
 * 
 * Copyright (C) 2017 Thomas Schmidt (shanapu)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <sdkhooks>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

int TimerCount = 0;

public Plugin myinfo = 
{
	name = "FF Time",
	author = "shanapu",
	description = "Activate FF after a certain time",
	version = "1.1",
	url = "https://github.com/shanapu/"
};

// Start
public void OnPluginStart()
{
	RegConsoleCmd("sm_fftime", Command_FriendlyFire, "Activate friendly fire after e certrain time");

	HookEvent("round_end", Event_RoundEnd);
}

public Action Command_FriendlyFire(int client, int args)
{
	if (args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "Use: sm_fftime <seconds>");
		return Plugin_Handled;
	}

	char arg[10];
	GetCmdArg(1, arg, sizeof(arg));
	int fftime = StringToInt(arg);
	TimerCount = fftime;

	CreateTimer (1.0, Timer_FF, _, TIMER_REPEAT);
	PrintToChatAll("FF will be opened after %i seconds", fftime);

	return Plugin_Handled;
}


public Action Timer_FF(Handle timer, any client)
{
	TimerCount--;

	if (TimerCount >= 1)
	{
		PrintHintTextToAll("FF will be opened after %i seconds", TimerCount);

		return Plugin_Continue;
	}

	SetCvar("mp_teammates_are_enemies", 1);
	PrintHintTextToAll("FF Opened");
	PrintToChatAll("FF Opened");

	return Plugin_Stop;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	SetCvar("mp_teammates_are_enemies", 0);
	PrintToChatAll("FF Closed");
}

// Silent ConVar change
void SetCvar(char cvarName[64], int value)
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null) return;

	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);

	SetConVarInt(IntCvar, value);

	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}
