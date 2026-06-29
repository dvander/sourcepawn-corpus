/**
 * vim: set ts=4 :
 * =============================================================================
 * Steam ID Converter
 * Convert Steam ID 2 to 3 or vice versa
 * THIS IS AN ACADEMIC EXERCISE ONLY, use GetClientAuthId in a plugin
 *
 * Steam ID Converter (C)2015 Powerlord (Ross Bemrose).  All rights reserved.
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

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.0.0"

public Plugin myinfo = {
	name			= "Steam ID Converter",
	author			= "Powerlord",
	description		= "Convert Steam ID 2 to 3 or vice versa",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=273169"
};

public void OnPluginStart()
{
	CreateConVar("steamidconverter_version", VERSION, "Steam ID Converter version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	RegConsoleCmd("steam2to3", Cmd_Steam2to3, "Convert a SteamID2 to a SteamID3");
	RegConsoleCmd("steam3to2", Cmd_Steam3to2, "Convert a SteamID3 to a SteamID2");
}

public Action Cmd_Steam2to3(int client, int args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: steam2to3 STEAM_0:x:yyyyyy");
		return Plugin_Handled;
	}
	
	char steam2[20];
	char steam3[17];
	char parts[3][10];
	int universe;
	int steamid32;
	
	GetCmdArgString(steam2, sizeof(steam2));
	
	if (IsSteamIDSpecial(steam2))
	{
		strcopy(steam3, sizeof(steam3), steam2);
	}
	else
	{
		ExplodeString(steam2, ":", parts, sizeof(parts), sizeof(parts[]));
		
		ReplaceString(parts[0], sizeof(parts[]), "STEAM_", "");
		
		universe = StringToInt(parts[0]);
		if (universe == 0)
			universe = 1;
	
		steamid32 = StringToInt(parts[1]) + (StringToInt(parts[2]) << 1);
		
		Format(steam3, sizeof(steam3), "U:%d:%d", universe, steamid32);
	}
	
	ReplyToCommand(client, "Steam2: \"%s\" = Steam3: \"%s\"", steam2, steam3);
	return Plugin_Handled;
}

public Action Cmd_Steam3to2(int client, int args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: steam3to2 U:x:yyyyyy");
		return Plugin_Handled;
	}

	char steam3[17];
	char steam2[2][20];
	char parts[3][10];
	int universe;
	int steamid32;
	
	GetCmdArgString(steam3, sizeof(steam3));

	if (IsSteamIDSpecial(steam3))
	{
		strcopy(steam2[0], sizeof(steam2[]), steam3);
	}
	else
	{
		ExplodeString(steam3, ":", parts, sizeof(parts), sizeof(parts[]));
		
		if (!StrEqual(parts[0], "U"))
		{
			ReplyToCommand(client, "Only \"U\" type accounts are convertible to Steam2");
			return Plugin_Handled;
		}
		
		universe = StringToInt(parts[1]);
		
		steamid32 = StringToInt(parts[2]);
		
		Format(steam2[0], sizeof(steam2[]), "STEAM_%d:%d:%d", universe, steamid32 & (1 << 0), steamid32 >>> 1);
		
		if (universe == 1)
			Format(steam2[1], sizeof(steam2[]), "STEAM_%d:%d:%d", 0, steamid32 & (1 << 0), steamid32 >>> 1);
	}
	
	if (universe == 1)
	{
		ReplyToCommand(client, "OR Steam3: \"%s\" = Steam2: \"%s\" OR \"%s\"", steam3, steam2[0], steam2[1]);
	}
	else
	{
		ReplyToCommand(client, "Steam3: \"%s\" = Steam2: \"%s\"", steam3, steam2[0]);
	}
	
	return Plugin_Handled;
}

bool IsSteamIDSpecial(const char[] steamid)
{
	if (StrEqual(steamid, "STEAM_ID_PENDING") || StrEqual(steamid, "BOT") || StrEqual(steamid, "UNKNOWN"))
	{
		return true;
	}
	
	return false;
}