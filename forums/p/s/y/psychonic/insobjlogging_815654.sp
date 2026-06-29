/**
 * Insurgency Objective Capture Logging
 * http://www.hlxcommunity.com/
 * Copyright (C) 2009 Nicholas Hastings
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

 
#pragma semicolon 1
#include <sourcemod>
#define VERSION "1.0.2"

new String:g_teamlist[4][17] = { "Unassigned", "", "", "SPECTATOR" };
 
public Plugin:myinfo = {
	name = "Insurgency Objective Capture Logging",
	author = "psychonic",
	description = "Logs a team action to the game log in Valve standard logging format when a team captures an objective point.",
	version = VERSION,
	url = "http://www.hlxcommunity.com"
};
 
public OnPluginStart()
{
	CreateConVar("insobjlogging_version", VERSION, "Insurgency Objective Capture Logging", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	GetTeams();
	HookUserMessage(GetUserMessageId("ObjMsg"), objmsg);
}

public OnMapStart()
{
	GetTeams();
}
 
public Action:objmsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new byte1;
	new byte2;
	new byte3;

	byte1 = BfReadByte(bf); // Objective Point: 1 = point A, 2 = point B, 3 = point C, etc.
	byte2 = BfReadByte(bf); // Capture Status: 1 on starting capture, 2 on finished capture
	byte3 = BfReadByte(bf); // Team Index: 1 = Marines, 2 = Insurgents
	
	if (byte2 == 2)
	{
		decl String:pointname[2];
		switch (byte1)
		{
			case 1:
				strcopy(pointname, 2, "a");
			case 2:
				strcopy(pointname, 2, "b");
			case 3:
				strcopy(pointname, 2, "c");
			case 4:
				strcopy(pointname, 2, "d");
			case 5:
				strcopy(pointname, 2, "e");
		}
		
		LogToGame("Team \"%s\" triggered \"captured_%s\"", g_teamlist[byte3], pointname);
	}
	
	return Plugin_Continue;
}

GetTeams()
{
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if (strcmp(mapname, "ins_karam") == 0 || strcmp(mapname, "ins_baghdad") == 0)
	{
		g_teamlist[1] = "Iraqi Insurgents";
		g_teamlist[2] = "U.S. Marines";
	}
	else
	{
		g_teamlist[1] = "U.S. Marines";
		g_teamlist[2] = "Iraqi Insurgents";
	}
}