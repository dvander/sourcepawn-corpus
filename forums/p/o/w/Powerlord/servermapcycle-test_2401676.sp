/**
 * vim: set ts=4 :
 * =============================================================================
 * ServerMapCycle Test
 * Check the contents of the ServerMapCycle string table
 *
 * ServerMapCycle Test (C)2016 Powerlord (Ross Bemrose).  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.0.0"

public Plugin myinfo = {
	name			= "ServerMapCycle Test",
	author			= "Powerlord",
	description		= "Check the contents of the ServerMapCycle string table",
	version			= VERSION,
	url				= ""
};

public void OnPluginStart()
{
	CreateConVar("servermapcycletest_version", VERSION, "ServerMapCycle Test version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	RegAdminCmd("mapcycle", Cmd_CheckMapCycle, ADMFLAG_GENERIC, "Check the server map cycle");
}

public Action Cmd_CheckMapCycle(int client, int args)
{
	int mapCycleTable = FindStringTable("ServerMapCycle");
	if (mapCycleTable == INVALID_STRING_TABLE)
	{
		ReplyToCommand(client, "Could not find ServerMapCycle string table");
		return Plugin_Handled;
	}
	
	int mapCycleEntry = FindStringIndex(mapCycleTable, "ServerMapCycle");
	
	int mapCycleLength = GetStringTableDataLength(mapCycleTable, mapCycleEntry);
	
	char[] data = new char[mapCycleLength];
	GetStringTableData(mapCycleTable, mapCycleEntry, data, mapCycleLength);
	
	char map[PLATFORM_MAX_PATH];
	
	int index = 0;
	int counter = 1;
	int oldIndex = 0;
	
	while ((index = SplitString(data[oldIndex], "\n", map, sizeof(map))) != -1)
	{
		oldIndex += index;
		ReplyToCommand(client, "%d. %s", counter, map);
		counter++;
	}
	
	return Plugin_Handled;
}
