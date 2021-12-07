/**
 * vim: set ts=4 :
 * =============================================================================
 * TF2 Workshop Map Loader
 * Add TF2 workshop maps to the tracked list on a delay, avoiding a crashing 
 * issue
 *
 * TF2 Workshop Map Loader (C)2015 Powerlord (Ross Bemrose).
 * All rights reserved.
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

ConVar g_Cvar_Enabled;
ConVar g_Cvar_Filename;
ConVar g_Cvar_Delay;

ArrayList g_hTrackedMaps;

public Plugin myinfo = {
	name			= "TF2 Workshop Map Loader",
	author			= "Powerlord",
	description		= "Add TF2 workshop maps to the tracked list on a delay, avoiding a crashing issue",
	version			= VERSION,
	url				= ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "This plugin is only supported on TF2.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("tf2_workshop_map_loader_version", VERSION, "TF2 Workshop Map Loader version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("tf2_workshop_map_loader_enable", "1", "Enable TF2 Workshop Map Loader?", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_Cvar_Filename = CreateConVar("tf2_workshop_map_loader_filename", "cfg/workshop_maps.txt", "Path to load Workshop Maps from.");
	g_Cvar_Delay = CreateConVar("tf2_workshop_map_loader_delay", "5.0", "How long, in seconds, should we wait to load non-tracked maps?", _, true, 5.0, true, 60.0);
	
	g_hTrackedMaps = new ArrayList();
	
	AutoExecConfig(false, "tf2_workshop_map_loader");
}

public void OnConfigsExecuted()
{
	if (g_Cvar_Enabled.BoolValue)
	{
		CreateTimer(g_Cvar_Delay.FloatValue, Timer_LoadWorkshopMaps, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_LoadWorkshopMaps(Handle timer)
{
	char filename[PLATFORM_MAX_PATH];
	g_Cvar_Filename.GetString(filename, sizeof(filename));
	
	if (!FileExists(filename, true))
	{
		LogError("File does note exist: %s", filename);
		return Plugin_Continue;
	}
	
	File file = OpenFile(filename, "rt", true);
	if (file == null)
	{
		LogError("Could not open file: %s", filename);
		return Plugin_Continue;
	}
	
	while (!file.EndOfFile())
	{
		// Workshop IDs are 9 characters plus line break and nul terminator... leaving 1 extra for future expansion
		char workshop[12];
		file.ReadLine(workshop, sizeof(workshop));
		TrimString(workshop);
		
		if (workshop[0] == '\0')
		{
			continue;
		}
		
		// Convert to int to prevent bad data
		int workshopID;
		workshopID = StringToInt(workshop);
		
		if (workshopID == 0)
		{
			LogError("Invalid map: %s", workshop);
			continue;
		}
		
		if (g_hTrackedMaps.FindValue(workshopID) == -1)
		{
			ServerCommand("tf_workshop_map_sync %d", workshopID);
			g_hTrackedMaps.Push(workshopID);
		}
	}
	
	file.Close();
	
	return Plugin_Continue;
}
