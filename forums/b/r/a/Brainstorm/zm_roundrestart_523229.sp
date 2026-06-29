/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#pragma semicolon 1

#include <sourcemod>

#define MAX_LINE_LENGTH			   192		// maximum length of a single line of text
#define ZOMBIEMASTER_TEAM_ID		 3		// team number of the zombie master

public Plugin:myinfo = 
{
	name = "Zombie Master Roundrestart",
	author = "Brainstorm",
	description = "Allows the Zombie master to restart the round by saying 'roundrestart'.",
	version = "1.1",
	url = "http://forums.alliedmods.net/showthread.php?t=60034"	
};

public OnPluginStart()
{
	// load translation files
	LoadTranslations("common.phrases");

	// listen for commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:Command_Say(client, args)
{
	// ingnore commands from console
	if (client < 1)
	{
		return Plugin_Continue;
	}
	
	// get the command name
	decl String:command[20];
	GetCmdArg(1, command, sizeof(command));
	
	// trim the command again
	TrimString(command);
	
	// does it say roundrestart
	if (strcmp(command, "roundrestart", false) == 0)
	{
		// check the team of the client, which should be the zombie master team (team #3)
		new teamId = GetClientTeam(client);
		if (teamId == ZOMBIEMASTER_TEAM_ID)
		{
			ServerCommand("roundrestart");
		}
		else
		{
			// client not allowed to restart
			PrintToChat(client, "[RESTART] You are not allowed to restart the round, only the Zombie Master can do that.");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
