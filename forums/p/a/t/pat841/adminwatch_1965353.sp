/*
 * SourceMod adminWatch
 * by:Pat841 @ www.amitygaming.org
 *
 * This file is part of SM adminWatch.
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
 * this program.  If not, see <http://www.gnu.org/licenses/>
 * 
 * CHANGELOG:
 * 
 * 	1.2.2
 * 		- Fixed updater being required, now optional
 * 		- Fixed checkout bug
 * 		- Fixed web script bug
 * 
 * 	1.2.1
 * 		- Fixed bug for DateTime in web script
 * 
 * 	1.2
 * 		- Added support for the updater plugin
 * 		- Added hostname tracking for admin logs
 * 		- Updated web script to display server hostnames
 * 
 * 	1.1
 * 		- Fixed a warning for date() on the web script
 * 		- Added cvar to enable logging admin commands
 * 		- Added LogAction () method to log admin commands
 * 		- Updated web script to display admin commands
 * 
 * 	1.0.3
 * 		- Changed how play time is recorded to fix some issues
 * 		- Added storing admin name and last time connected (UNIX) in the database
 * 		- Updated web script to display new info
 * 
 * 	1.0.2
 * 		- Fixed some bugs.
 * 		- Added a php script to display stats
 * 	
 * 	1.0.1:
 * 		- Added sm_adminwatch_precision flag to allow poll tracking every minute or every second.
 * 
 * 	1.0
 * 		- Initial release.
 */
 
#define PLUGIN_VERSION "1.2.2"

#pragma semicolon 1

#define _DEBUG 0
#define UPDATE_URL    "http://pat841.amitygaming.org/adminwatch/updater.txt"

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

// DB Handles
new Handle:hDatabase = INVALID_HANDLE;
//new Handle:hQuery = INVALID_HANDLE;

// Timer Handles
new Handle:hTimerTotal[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:hTimerPlayed[MAXPLAYERS + 1] = INVALID_HANDLE;

// Cvar Handles
new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarLoggingEnabled = INVALID_HANDLE;
new Handle:cvarAdminFlag = INVALID_HANDLE;
new Handle:cvarPrecision = INVALID_HANDLE;

// Globals
new bool:gEnabled;
new bool:gLoggingEnabled;
new String:gAdminFlag[MAXPLAYERS + 1];
new gAdminFlagBits = 0;
new bool:gPrecision;

// Trackers
new gTrackTotal[MAXPLAYERS + 1] = 0;
new gTrackPlayed[MAXPLAYERS + 1] = 0;

// Database Queries
new const String:DBQueries[4][] =
{
	"CREATE TABLE IF NOT EXISTS `adminwatch` (`id` INT(10) NOT NULL AUTO_INCREMENT, `steam` VARCHAR(50) NOT NULL, `name` VARCHAR(50) NOT NULL, `total` INT(11) NOT NULL DEFAULT '0', `played` INT(11) NOT NULL DEFAULT '0', `last_played` VARCHAR(50) NOT NULL, PRIMARY KEY (`id`)) COLLATE='latin1_swedish_ci' ENGINE=MyISAM;",
	"SELECT * FROM `adminwatch` WHERE `steam` = '%s'",
	"UPDATE `adminwatch` SET `total` = '%i', `played` = '%i', `last_played` = '%i' WHERE `steam` = '%s'",
	"INSERT INTO `adminwatch` (`steam`, `name`, `total`, `played`, `last_played`) VALUES ('%s', '%s', '0', '0', '')"
};

new const String:DBQueriesLogs[2][] =
{
	"CREATE TABLE IF NOT EXISTS `adminwatch_logs` (`id` INT(10) NOT NULL AUTO_INCREMENT, `hostname` VARCHAR(50) NOT NULL, `name` VARCHAR(50) NOT NULL, `steam` VARCHAR(50) NOT NULL, `command` VARCHAR(100) NOT NULL, `time` VARCHAR(50) NOT NULL, PRIMARY KEY (`id`)) COLLATE='latin1_swedish_ci' ENGINE=MyISAM;",
	"INSERT INTO `adminwatch_logs` (`hostname`, `steam`, `name`, `command`, `time`) VALUES ('%s', '%s', '%s', '%s', '%i')"
};

// Plugin Info
public Plugin:myinfo = 
{
	name = "adminWatch",
	author = "Pat841",
	description = "Tracks play time and server idle time for a specific admin flag and stores results in a database.",
	version = PLUGIN_VERSION,
	url = "http://www.amitygaming.org/"
};

public OnPluginStart ()
{
	// Hook Events
	//HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	// Create ConVars
	CreateConVar("sm_adminwatch_version", PLUGIN_VERSION, "adminWatch plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cvarEnabled = CreateConVar("sm_adminwatch_enabled", "1", "Enables or disables the plugin: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gEnabled = true;
	
	cvarLoggingEnabled = CreateConVar("sm_adminwatch_logging", "1", "Enables or disables logging commands: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gLoggingEnabled = true;
	
	cvarAdminFlag = CreateConVar("sm_adminwatch_adminflag", "1", "The admin flag to track: 1 - All admins, flag values: abcdefghijklmnopqrst");
	Format(gAdminFlag, sizeof(gAdminFlag), "z");
	
	cvarPrecision = CreateConVar("sm_adminwatch_precision", "0", "Timer precision. Careful, use 0 if rounds end in less than 1 minute: 0 - Seconds, 1 - Minutes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gPrecision = false;
	
	// Hook Cvar Changes
	HookConVarChange(cvarEnabled, HandleCvars);
	HookConVarChange(cvarAdminFlag, HandleCvars);
	HookConVarChange(cvarPrecision, HandleCvars);
	
	// Updater?
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	// Connect to Database
	new String:error[255];
	hDatabase = SQL_Connect("adminwatch", true, error, sizeof(error));
	
	if (hDatabase == INVALID_HANDLE)
	{
		LogError("Unable to connect to the database. Error: %s", error);
		LogMessage("[adminWatch] - Unable to connect to the database.");
	}
	
#if _DEBUG
	LogMessage("[adminWatch DEBUG] - Connected to the database in OnPluginStart().");
#endif
	
	// Autoload Config
	AutoExecConfig(true, "adminwatch");
	
	// If needed, create tables
	if (gEnabled)
	{
		SQL_TQuery(hDatabase, DBNoAction, DBQueries[0], DBPrio_High);
	}
	if (gLoggingEnabled)
	{
		SQL_TQuery(hDatabase, DBNoAction, DBQueriesLogs[0], DBPrio_High);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnPluginEnd ()
{
	CloseHandle(hDatabase);
	hDatabase = INVALID_HANDLE;
}

public OnConfigsExecuted ()
{
	gEnabled = GetConVarBool(cvarEnabled);
	gLoggingEnabled = GetConVarBool(cvarLoggingEnabled);
	GetConVarString(cvarAdminFlag, gAdminFlag, sizeof(gAdminFlag));
	gPrecision = GetConVarBool(cvarPrecision);
	RefreshFlags();
	ResetTrackers();
	
#if _DEBUG
	LogMessage("[adminWatch DEBUG] - Fetched ConVars and refreshed flags in OnConfigsExecuted().");
#endif
}

public OnClientPostAdminCheck (client)
{
	// Reset client
	ResetClient(client);
	
	// Check if client has flags
	if (gEnabled && (GetUserFlagBits(client) & gAdminFlagBits))
	{
		// Add to database if needed
		decl String:query[255], String:authid[32];
		GetClientAuthString(client, authid, sizeof(authid));
		
		Format(query, sizeof(query), DBQueries[1], authid);
		SQL_TQuery(hDatabase, DBInsert, query, client, DBPrio_High);
		
		// Is admin, start timer to track total time in server
		if (gPrecision && hTimerTotal[client] == INVALID_HANDLE)
		{
			hTimerTotal[client] = CreateTimer(60.0, TimerAddTotal, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (hTimerTotal[client] == INVALID_HANDLE)
		{
			hTimerTotal[client] = CreateTimer(1.0, TimerAddTotal, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		
#if _DEBUG
		LogMessage("[adminWatch DEBUG] - Total timer started in OnClientPostAdminCheck().");
#endif
	}
}

public OnClientDisconnect (client)
{
	if (gEnabled && (GetUserFlagBits(client) & gAdminFlagBits))
	{
		CheckoutClient(client);
#if _DEBUG
		LogMessage("[adminWatch DEBUG] - Checked client out in OnClientDisconnect().");
#endif
	}
	
	ResetClient(client);
}

// Events
public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (gEnabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (GetUserFlagBits(i) & gAdminFlagBits) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 3) && hTimerPlayed[i] == INVALID_HANDLE)
			{
				if (gPrecision)
				{
					hTimerPlayed[i] = CreateTimer(60.0, TimerAddPlayed, i, TIMER_REPEAT);
				}
				else
				{
					hTimerPlayed[i] = CreateTimer(1.0, TimerAddPlayed, i, TIMER_REPEAT);
				}
			}
		}
	}
}

public Action:Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (gEnabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (GetUserFlagBits(i) & gAdminFlagBits) && hTimerPlayed[i] != INVALID_HANDLE)
			{
				CloseHandle(hTimerPlayed[i]);
				hTimerPlayed[i] = INVALID_HANDLE;
			}
		}
#if _DEBUG
		LogMessage("[adminWatch DEBUG] - Round ended, closed handles in Event_RoundEnd().");
#endif		
	}
}

// Credit: Modified TSCDan's function
public Action:OnLogAction (Handle:source, Identity:ident, client, target, const String:message[])
{
	/* If there is no client or they're not an admin, we don't care. */
	if (!gLoggingEnabled || client < 1 || !(GetUserFlagBits(client) & gAdminFlagBits))
	{
		LogMessage("[adminWatch DEBUG] - Client: %d, Target: %d inside OnLogAction().", client, target);
		return Plugin_Continue;
	}
	
	// Get steam
	new String:query[400], String:authid[32];
	GetClientAuthString(client, authid, sizeof(authid));
	
	// Get name
	new String:name[30];
	GetClientName(client, name, sizeof(name));
	
	// Get hostname
	new String:hostname[60];
	new Handle:cvarHostname = INVALID_HANDLE;
	cvarHostname = FindConVar("hostname");
	GetConVarString(cvarHostname, hostname, sizeof(hostname));
	
	// Escape
	new String:bName[61];
	new String:bHost[121];
	
	SQL_EscapeString(hDatabase, name, bName, sizeof(bName));
	SQL_EscapeString(hDatabase, hostname, bHost, sizeof(bHost));
	
	new time = GetTime();
	
	Format(query, sizeof(query), DBQueriesLogs[1], bHost, authid, bName, message, time);
	
	SQL_TQuery(hDatabase, DBNoAction, query, client, DBPrio_High);
	
	return Plugin_Handled;
}

public CheckoutClient (client)
{
	// Get authid (steamid)
	new String:query[255], String:authid[32];
	GetClientAuthString(client, authid, sizeof(authid));
	
	Format(query, sizeof(query), DBQueries[1], authid);
	
	SQL_TQuery(hDatabase, DBCheckout, query, client, DBPrio_High);
	
	return true;
}

// Database Threads
public DBCheckout (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[adminWatch] - DB Query Failed. Error: %s", error);
	}
	else
	{
		new String:query[255];
		
		if (SQL_FetchRow(hndl))
		{
			new String:steam[30];
			SQL_FetchString(hndl, 1, steam, sizeof(steam));
			
			new time = GetTime();
			
			new total = 0;
			new played = 0;
			
			total = SQL_FetchInt(hndl, 3);
			played = SQL_FetchInt(hndl, 4);
			
			total += gTrackTotal[data];
			played += gTrackPlayed[data];
#if _DEBUG
			LogMessage("[adminWatch DEBUG] - Updating client in database for total values (Total: %i, Played: %i) and session values (Total: %i, Played: %i) in DBCheckout().", total, played, gTrackTotal[data], gTrackPlayed[data]);
#endif
			
			Format(query, sizeof(query), DBQueries[2], total, played, time, steam);
			SQL_TQuery(hDatabase, DBNoAction, query, DBPrio_High);
		}
		else
		{
			LogMessage("[adminWatch] - Unable to update admin times.");
		}
	}
}

public DBInsert (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogMessage("[adminWatch] - DB Query Failed. Error: %s", error);
	}
	else
	{
		if (SQL_GetRowCount(hndl) <= 0)
		{
			// Not found, insert
			decl String:query[255], String:authid[32];
			GetClientAuthString(data, authid, sizeof(authid));
			
			new String:name[60], String:buffer[30];
			GetClientName(data, buffer, sizeof(buffer));
			
			SQL_EscapeString(hDatabase, buffer, name, sizeof(name));
			
			Format(query, sizeof(query), DBQueries[3], authid, name);
			SQL_TQuery(hDatabase, DBNoAction, query, DBPrio_High);
		}
	}
}

public DBNoAction (Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
}

// Tracker Functions
public Action:TimerAddTotal (Handle:timer, any:client)
{
	if (hTimerTotal[client] != INVALID_HANDLE)
	{
#if _DEBUG
		LogMessage("[adminWatch DEBUG] - Adding a minute to total tracker in TimerAddTotal().");
#endif
		gTrackTotal[client] += 1;
	}
}

public Action:TimerAddPlayed (Handle:timer, any:client)
{
	if (hTimerPlayed[client] != INVALID_HANDLE)
	{
#if _DEBUG
		LogMessage("[adminWatch DEBUG] - Adding a minute to played tracker in TimerAddPlayed().");
#endif
		gTrackPlayed[client] += 1;
	}
}

// Helper Functions
public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == cvarEnabled && StrEqual(newValue, "1"))
	{
		gEnabled = true;
	}
	else if (cvar == cvarEnabled && StrEqual(newValue, "0"))
	{
		gEnabled = false;
	}
	if (cvar == cvarLoggingEnabled && StrEqual(newValue, "1"))
	{
		gLoggingEnabled = true;
	}
	else if (cvar == cvarLoggingEnabled && StrEqual(newValue, "0"))
	{
		gLoggingEnabled = false;
	}
	else if (cvar == cvarAdminFlag)
	{
		Format(gAdminFlag, sizeof(gAdminFlag), newValue);
		RefreshFlags();
	}
	else if (cvar == cvarPrecision && StrEqual(newValue, "1"))
	{
		gPrecision = true;
	}
	else if (cvar == cvarPrecision && StrEqual(newValue, "0"))
	{
		gPrecision = false;
	}
		
#if _DEBUG
	new String:cvarName[32];
	GetConVarName(cvar, cvarName, sizeof(cvarName)); 
	LogMessage("[adminWatch DEBUG] - Cvar (%s) changed from \"%s\" to \"%s\" in HandleCvars().", cvarName, oldValue, newValue);
#endif
}

public RefreshFlags ()
{
	if (StrEqual(gAdminFlag, "1"))
	{
		// Include all but reserved slot flag
		Format(gAdminFlag, sizeof(gAdminFlag), "bcdefghijklmnopqrstz");
	}
	gAdminFlagBits = ReadFlagString(gAdminFlag);
	
#if _DEBUG
	LogMessage("[adminWatch DEBUG] - Refreshed flags in RefreshFlags().");
#endif
	
	return true;
}

public ResetTrackers ()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		gTrackTotal[i] = 0;
		gTrackPlayed[i] = 0;
		
		if (hTimerTotal[i] != INVALID_HANDLE)
		{
			CloseHandle(hTimerTotal[i]);
			hTimerTotal[i] = INVALID_HANDLE;
		}
		
		if (hTimerPlayed[i] != INVALID_HANDLE)
		{
			CloseHandle(hTimerPlayed[i]);
			hTimerPlayed[i] = INVALID_HANDLE;
		}
	}
}

public ResetClient (client)
{
	if (hTimerTotal[client] != INVALID_HANDLE)
	{
		CloseHandle(hTimerTotal[client]);
		hTimerTotal[client] = INVALID_HANDLE;
	}
	if (hTimerPlayed[client] != INVALID_HANDLE)
	{
		CloseHandle(hTimerPlayed[client]);
		hTimerPlayed[client] = INVALID_HANDLE;
	}
	
	gTrackTotal[client] = 0;
	gTrackPlayed[client] = 0;
	
	return true;
}