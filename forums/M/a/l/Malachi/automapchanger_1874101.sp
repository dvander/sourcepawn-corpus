/*
* Summary: If the server is empty AND remains empty for 10 minutes, change to default map
* 
* Based on "Auto change map v1.3 by "Mleczam"
* https://forums.alliedmods.net/showthread.php?p=1204093
* 
* Changelog (date/version/description):
* 2013-01-14	-	0.1.1	-	initial internal dev version
* 2013-01-14	-	0.1.2	-	initial testing complete, enabled map chg
* 2013-01-14	-	0.1.3	-	ADD TIME TO LOG, CHG MAP TO NUCLEUS, del commented out code
* 2013-01-14	-	0.1.4	-	add cvar for default map
* 2013-01-14	-	0.1.5	-	chk when cvar is set if its valid
* 2013-01-14	-	0.1.6	-	elminate extra code, tidy up names, add comments
*
*/


#pragma semicolon 1
#include <sourcemod>


// Defines
#define PLUGIN_VERSION		"0.1.6"
#define DEFAULT_NEXT_MAP	"koth_nucleus"	// Map to change to after time limit reached
#define MAP_IDLE_TIME		10				// Time (minutes) between empty server and map change


// Global variables
new Handle:g_hTimer = INVALID_HANDLE; 
new Handle:g_hNextMap = INVALID_HANDLE; 


public Plugin:myinfo =
{
	name = "Auto Map Changer",
	author = "Malachi",
	description = "Change the map if the server is empty for over 10 minutes.",
	version = PLUGIN_VERSION,
	url = "http://www.necrophix.com/"
}


// Initialization:
// Create and hook our cvar
public OnPluginStart()
{
	g_hNextMap = CreateConVar("sm_automapchanger_map", DEFAULT_NEXT_MAP, "Name of the map to change to (without .bsp)", FCVAR_PLUGIN);
	if (g_hNextMap != INVALID_HANDLE)
	{
		HookConVarChange(g_hNextMap, Ong_hNextMapChange);
	}
}


// After every map change, start a timer that checks for players
// We assume g_hTimer is not in use b/c of TIMER_FLAG_NO_MAPCHANGE flag
public OnMapStart()
{
	new String:sFormattedTime[22];

	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%m/%d/%Y - %H:%M:%S", GetTime());
	PrintToServer("L %s: [automapchanger.smx] Map changed, starting timer.", sFormattedTime);

	g_hTimer = CreateTimer(60.0, IsServerEmpty ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


// If this cvar changes, make sure its to a valid map name
// IsMapValid logs its own error msg
// Since the cvar is already changed, we have to set it back on invalid map name
public Ong_hNextMapChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if( !IsMapValid(newVal) ) 
	{
		SetConVarString(cvar, oldVal);
	}
}


// Look at # players connected, if zero start timer
public Action:IsServerEmpty(Handle:Timer)
{
	new ccount=0;
	new String:sFormattedTime[22];
	
	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%m/%d/%Y - %H:%M:%S", GetTime());

	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
            ccount++;
		}
		 
	if (ccount > 0)
	{
		PrintToServer("L %s: [automapchanger.smx] Detected %d clients, continuing.", sFormattedTime, ccount);
		return Plugin_Handled;
	}
	else
	{
		PrintToServer("L %s: [automapchanger.smx] Detected %d clients, starting empty server countdown.", sFormattedTime, ccount);

		if (g_hTimer != INVALID_HANDLE)
		{
			KillTimer(g_hTimer); 
			g_hTimer = INVALID_HANDLE;
		}
		
		g_hTimer = CreateTimer( MAP_IDLE_TIME * 60.0, IsTimeLimitReached);
		return Plugin_Handled;
	}
}

// If a player joins kill/recreate the timer
public OnClientPostAdminCheck(iClient)
{
	new String:sFormattedTime[22];
	
	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%m/%d/%Y - %H:%M:%S", GetTime());
	PrintToServer("L %s: [automapchanger.smx] Detected client connect (index=%d), resetting.", sFormattedTime, iClient);
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer); 
		g_hTimer = INVALID_HANDLE;
	}
	g_hTimer = CreateTimer(60.0, IsServerEmpty ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


// We reached the empty server time limit
// If server still empty and we're not already on chosen map, then change map
public Action:IsTimeLimitReached(Handle:Timer)
{
	new String:sCurrentMapName[128];	  
	new String:sCvarMapName[128];	  
	new ccount=0;
	new String:sFormattedTime[22];
	
	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%m/%d/%Y - %H:%M:%S", GetTime());
	  
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer); 
		g_hTimer = INVALID_HANDLE;
	}
	
	// Check # of players
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
            ccount++;
		}
      
	// If we have players again, reset everything and start over
	if (ccount > 0)
	{
		PrintToServer("L %s: [automapchanger.smx] Detected %d clients, aborting empty server countdown.", sFormattedTime, ccount);
		g_hTimer = CreateTimer(60.0, IsServerEmpty, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	else
	{
		GetConVarString(g_hNextMap, sCvarMapName, sizeof(sCvarMapName));
		GetCurrentMap(sCurrentMapName, sizeof(sCurrentMapName));
		
		// If we are already on the default map, no map change
		if( strcmp(sCurrentMapName, sCvarMapName, false) )
		{ 
			PrintToServer("L %s: [automapchanger.smx] Time limit reached, commencing map change to %s.", sFormattedTime, sCvarMapName);
			LogMessage("Time limit reached, commencing map change to %s.", sCvarMapName);
			if( IsMapValid(sCvarMapName) ) 
			{
				ServerCommand("changelevel %s", sCvarMapName);
				return Plugin_Handled;
			}
			else
			{
//				PrintToServer("L %s: [automapchanger.smx] Error: %s is not a valid map name.", sFormattedTime, sCvarMapName);
				return Plugin_Handled;
			}
		}
		else
		{
			PrintToServer("L %s: [automapchanger.smx] Time limit reached, map change aborted - already on default map (%s).", sFormattedTime, sCvarMapName);
		}
	}
	return Plugin_Handled;
}
