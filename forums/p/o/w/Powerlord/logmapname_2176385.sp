/**
 * vim: set ts=4 :
 * =============================================================================
 * Log Map Name
 * Diagnostics plugin to print the map name to the SourceMod log
 *
 * Log Map Name (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
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

#define VERSION "1.0.0"

public Plugin:myinfo = {
	name			= "Log Map Name",
	author			= "Powerlord",
	description		= "Diagnostics plugin to print the map name to the SourceMod log",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?p=2176373#post2176373"
};

public OnPluginStart()
{
	CreateConVar("logmapname_version", VERSION, "Log Map Name version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
}

public OnMapStart()
{
	new String:mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	
	LogMessage("SM says current map is: \"%s\"", mapName);
}
