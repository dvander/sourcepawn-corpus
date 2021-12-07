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

//
// SourceMod Script
//
// Developed by <eVa>Dog
// December 2008
// http://www.theville.org
// Fixed by Bacardi and St00ne
// https://forums.alliedmods.net/showthread.php?p=734701
//

#include <sourcemod>

#include <sdktools>

// Plugin Version
#define PLUGIN_VERSION "1.1.203b32plr"

// Handles
new Handle:g_Enable 			= INVALID_HANDLE;
new Handle:g_Nextmap 			= INVALID_HANDLE;
new Handle:g_MapTimer 			= INVALID_HANDLE;
new Handle:g_WMCTimer 			= INVALID_HANDLE;

new Handle:g_TimeLimitOverride 	= INVALID_HANDLE;
new g_totalmaptime;

public Plugin:myinfo = 
{
	name = "Force Timelimit (plr)",
	author = "<eVa>Dog, Bacardi, St00ne",
	description = "Forces a map to end if timelimit has been reached - fixed for some plr maps.",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_forcetimelimit_plr_version", PLUGIN_VERSION, "Version of Force Timelimit", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Enable  = CreateConVar("sm_forcetimelimit_plr_enable", "0", "Enables/disables the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_TimeLimitOverride = CreateConVar("sm_forcetimelimit_plr_override", "30", "Timelimit override in minutes", FCVAR_PLUGIN, true, 2.0, true, 1440.0);
}

public OnAutoConfigsBuffered()
{
	// Let's set mp_timelimit according to sm_forcetimelimit_plr_override, so that if players type 'timeleft', they will have a correct reply.
	// Note that even if the game or an admin changes mp_timelimit, the map will change after the amount of time chosen via sm_forcetimelimit_override.
	ServerCommand("mp_timelimit %s", GetConVarInt(g_TimeLimitOverride));
}

public OnConfigsExecuted()
{
	if (GetConVarInt(g_Enable) == 1)
	{
		g_Nextmap = FindConVar("sm_nextmap");
		
		if (g_Nextmap == INVALID_HANDLE)
		{
			LogError("FATAL: Cannot find sm_nextmap cvar. sm_forcetimelimit.smx not loaded");
			SetFailState("sm_nextmap not found");
		}
		
		// Grab sm_forcetimelimit_override and set timer to warn 1 min before map change
		g_totalmaptime = GetConVarInt(g_TimeLimitOverride);
		
		new maptime = g_totalmaptime * 60;
		g_MapTimer = CreateTimer(float(maptime - 60), WarnMapChange, 60.0, TIMER_FLAG_NO_MAPCHANGE);
		//PrintToServer("[SM] Default time limit for this map: %i mins", g_totalmaptime);
	}
}

public Action:WarnMapChange(Handle:timer)
{
	if (g_MapTimer != INVALID_HANDLE)
	{
		g_MapTimer = INVALID_HANDLE;
	}
	
	g_WMCTimer = CreateTimer(60.0, MapChanger, _, TIMER_FLAG_NO_MAPCHANGE);
	new String:newmap[65];
	GetNextMap(newmap, sizeof(newmap));
	PrintToChatAll("[SM] Map will change to %s in 60 secs", newmap);
	//LogMessage("[SM] Map will change to %s in 60 secs", newmap);
}

public Action:MapChanger(Handle:timer)
{
	if (g_WMCTimer != INVALID_HANDLE)
	{
		g_WMCTimer = INVALID_HANDLE;
	}
	
	if (GetConVarInt(g_Enable) == 1)
	{
		//Routine by Tsunami to end the map
		new iGameEnd  = FindEntityByClassname(-1, "game_end");
		if (iGameEnd == -1 && (iGameEnd = CreateEntityByName("game_end")) == -1) 
		{
			LogError("Unable to create entity \"game_end\"!");
		}
		else 
		{
			AcceptEntityInput(iGameEnd, "EndGame");
		}		
		//PrintToChatAll("[SM] Map changing...")
		//PrintToServer("[SM] Map changing...")
		//new String:newmap[65]
		//GetNextMap(newmap, sizeof(newmap))
		//ForceChangeLevel(newmap, "Enforced Map TimeLimit")
	}
}

public OnMapEnd()
{
	if (g_WMCTimer != INVALID_HANDLE)
	{
		g_WMCTimer = INVALID_HANDLE;
	}
	if (g_MapTimer != INVALID_HANDLE)
	{
		g_MapTimer = INVALID_HANDLE;
	}
}

//***END***//