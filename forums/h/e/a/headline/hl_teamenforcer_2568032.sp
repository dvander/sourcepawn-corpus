/*  hl_teamenforcer.sp - Forces clients who've left to rejoin their old team.
 *
 *  Copyright (C) 2017 Michael Flaherty // michaelwflaherty.com
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 
#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

StringMap map;

bool connecting[MAXPLAYERS + 1];

public Plugin myinfo =    
{    
    name = "[ANY] Team Enforcer",    
    author = "Headline",    
    description = "Forces clients who've left to rejoin their old team",    
    version = "1.0.1",    
    url = "http://www.michaelwflaherty.com"    
}

public void OnPluginStart()
{
	AddCommandListener(Event_JoinTeam, "jointeam");
}

public void OnMapStart()
{
	delete map;
	map = new StringMap();
}

public void OnClientPutInServer(int client)
{
	connecting[client] = true;
}

public void OnClientDisconnect(int client)
{
	int team = GetClientTeam(client);
	if (team == 1)
	{
		return;
	}
	
	char team_string[8];
	IntToString(team, team_string, sizeof(team_string));

	char steamid[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		return;
	}

	map.SetString(steamid, team_string);
}

public Action Event_JoinTeam(int client, const char[] command, int argc)
{
	if (CheckCommandAccess(client, "hl_teamenforcer_override", ADMFLAG_GENERIC, false))
	{
		return Plugin_Continue;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	int team = StringToInt(arg1);
	if (team == 1)
	{
		return Plugin_Continue;
	}

	char steamid[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		return Plugin_Continue;
	}

	if (!connecting[client])
	{
		return Plugin_Continue;
	}

	connecting[client] = false;

	char team_str[8];
	map.GetString(steamid, team_str, sizeof(team_str));

	int team_int = StringToInt(team_str);
	if (team == team_int)
	{
		return Plugin_Continue;
	}

	ChangeClientTeam(client, team_int);

	PrintToChat(client, "[SM] You have been automatically moved to the team before you left!");
	return Plugin_Handled;
}
