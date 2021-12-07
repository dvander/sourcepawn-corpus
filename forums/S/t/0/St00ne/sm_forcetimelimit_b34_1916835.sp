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
#define PLUGIN_VERSION "1.1.203b34"

// Handles
new Handle:g_Enable 	= INVALID_HANDLE;
new Handle:g_Nextmap 	= INVALID_HANDLE;
new Handle:g_MapTimer 	= INVALID_HANDLE;
new Handle:g_TimeLimit 	= INVALID_HANDLE;
new Handle:g_WMCTimer 	= INVALID_HANDLE;

new g_totalmaptime;
new Float:g_MapStart;

public Plugin:myinfo = 
{
	name = "Force Timelimit",
	author = "<eVa>Dog, Bacardi, St00ne",
	description = "Forces a map to end if timelimit has been reached.",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_forcetimelimit_version", PLUGIN_VERSION, "Version of Force Timelimit", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Enable  = CreateConVar("sm_forcetimelimit_enable", "0", "- enables/disables the plugin", _, true, 0.0, true, 1.0);
	
	g_TimeLimit = FindConVar("mp_timelimit");
	HookConVarChange(g_TimeLimit, TimeLimitChanged);
}

public OnMapStart()
{
	g_MapStart = GetGameTime();
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
		
		if (GetConVarInt(g_TimeLimit) > 0)
		{
			// Grab mp_timelimit and set timer to warn 1 min before map change
			g_totalmaptime = GetConVarInt(g_TimeLimit);
			
			new maptime = g_totalmaptime * 60;
			
			g_MapTimer = CreateTimer(float(maptime - 60), WarnMapChange, 60.0, TIMER_FLAG_NO_MAPCHANGE);
			//PrintToServer("[SM] Default time limit for this map: %i mins", g_totalmaptime);
		}
	}
}

public TimeLimitChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	if (g_MapTimer != INVALID_HANDLE)
	{
		//KillTimer(g_MapTimer);
		g_MapTimer = INVALID_HANDLE;
	}
	
	if (g_WMCTimer != INVALID_HANDLE)
	{
		KillTimer(g_WMCTimer);
		g_WMCTimer = INVALID_HANDLE;
	}
	
	if (GetConVarInt(g_Enable) == 1)
	{
		new Float:CurrentTime = GetGameTime();
		new Float:TimeElapsed = CurrentTime - g_MapStart;
		
		new newmaptime = GetConVarInt(g_TimeLimit);
		
		if (newmaptime > g_totalmaptime && newmaptime > 0)
		{
			new Float:time = (newmaptime * 60) - TimeElapsed;
			g_MapTimer = CreateTimer(time - 60.0, WarnMapChange, 60.0, TIMER_FLAG_NO_MAPCHANGE);
			//PrintToServer("[SM] Time limit changed");
		}
		
		else if (newmaptime <= g_totalmaptime && newmaptime > 0)
		{
			if (TimeElapsed < (newmaptime * 60))
			{
				new Float:time = (newmaptime * 60) - TimeElapsed;
				g_MapTimer = CreateTimer(time - 60.0, WarnMapChange, 60.0, TIMER_FLAG_NO_MAPCHANGE);
				//PrintToServer("[SM] Time limit changed");
			}
			else
			{
				g_MapTimer = CreateTimer(1.0, WarnMapChange, 1.0, TIMER_FLAG_NO_MAPCHANGE);
				//The comment below will be false with this version, because we check one last time at MapChanger if the timelimit has been changed again.
				//PrintToServer("[SM] Time limit changed to a lower value than time elapsed... Map will change in a few seconds.");
			}
		}
	}
}

public Action:WarnMapChange(Handle:timer, any:timedelay)
{
	g_MapTimer = INVALID_HANDLE;
	
	g_WMCTimer = CreateTimer(timedelay, MapChanger, _, TIMER_FLAG_NO_MAPCHANGE);
	new String:newmap[65];
	GetNextMap(newmap, sizeof(newmap));
	if (timedelay >= 60.0)
	{
		PrintToChatAll("[SM] Map will change to %s in 60 secs", newmap);
		//LogMessage("[SM] Map will change to %s in 60 secs", newmap);
	}
}

public Action:MapChanger(Handle:timer)
{
	g_WMCTimer = INVALID_HANDLE;
	
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

/**END**/