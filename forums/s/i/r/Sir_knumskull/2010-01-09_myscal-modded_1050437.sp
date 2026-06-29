/**
* Name:
*	M Y S Q L - S E R V E R - C O N F I G S & A D M I N - L O G G I N G
*	By Team MX | MoggieX
*
* Description:
*	Run your server configs remotely from a MySQL database
*	Log admin commands to a MySQL database also!	
*
* Thanks to:
* 	All the n00blets @ http://www.UKManDown.co.uk for putting up with my testing!
*	Tsunami, always extremely helpful to a wee pawn n00b
*	pRED* for SQL_EscapeString
*	sawce for the cunning 'quotedLen
*	
* Based upon:
*	MySQL Server Configs based upon an old AMX MOD plugin I thought was a great idea at:
*	http://djeyl.net/forum/index.php?showtopic=4624
*
*	MySQL Logging based upon 'Admin logging' by TSCDan
*	http://forums.alliedmods.net/showthread.php?p=527208
*  
* Version History
* 	1.0 - First Release
*	1.1 - Add the ability to run map.cfg files automatcially after MySCAL has finished
* 	
*/
//////////////////////////////////////////////////////////////////
// Defines, Includes, Handles & Plugin Info
//////////////////////////////////////////////////////////////////
#pragma semicolon 1
#include <sourcemod>
#define MS_VERSION "1.1"

new Handle:hDatabase = INVALID_HANDLE;
new Handle:MSCEnable;
//new Handle:ServerNumber;
new String:g_MapName[128];

// Define author information
public Plugin:myinfo = 
{
	name = "MySQL Server Configs & Logging",
	author = "MoggieX",
	description = "Control your servers configuation via MySQL & Admin Logging",
	version = MS_VERSION,
	url = "http://www.UKManDown.co.uk"
};

//////////////////////////////////////////////////////////////////
// Plugin Start
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("sm_myscal_version", MS_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	MSCEnable 		= 	CreateConVar("sm_myscal_enable","1","Enables and disables this plugin",FCVAR_PLUGIN);
	// ServerNumber 	=	CreateConVar("sm_myscal_server_no","1","Server Number", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	// This is left in as someone may turn the plugin ON when 1/2 way through a map
	CreateTimer(2.0, OnPluginStart_Delayed);
	
	StartSQL();
}

//////////////////////////////////////////////////////////////////
// OnConfigsExecuted - was OnMapStart - Added this as it won't load the configs without it
//////////////////////////////////////////////////////////////////
public OnMapStart()								// OnConfigsExecuted()
{
	CreateTimer(2.0, OnPluginStart_Delayed);
	
	// Get the map name for use a bit later
	GetCurrentMap(g_MapName, sizeof(g_MapName));

}

//////////////////////////////////////////////////////////////////
// Map END Close the DB
//////////////////////////////////////////////////////////////////
/*
public OnMapEnd()
{
	if (hDatabase != INVALID_HANDLE)
	{
		CloseHandle(hDatabase);
		hDatabase = INVALID_HANDLE;
	}
}

*/
//////////////////////////////////////////////////////////////////
// Start SQL DB
//////////////////////////////////////////////////////////////////
StartSQL()
{
	SQL_TConnect(GotDatabase);
}

//////////////////////////////////////////////////////////////////
// Connect to the DB
//////////////////////////////////////////////////////////////////
public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[MySCAL] Database failure: %s", error);
		ServerCommand("exec server_backup.cfg");				// Add option here to run server_backup.cfg
	}
	else
	{
		hDatabase = hndl;
		LogMessage("Database Init (CONNECTED)");					// Message Console
	}
}

//////////////////////////////////////////////////////////////////
// Delayed Start
//////////////////////////////////////////////////////////////////
public Action:OnPluginStart_Delayed(Handle:timer)
{
	if(GetConVarInt(MSCEnable) > 0)
	{
		if (hDatabase == INVALID_HANDLE)
		{
			LogError("[MySCAL] Database Error");
			LogError("[MySCAL] Attempting to run server_backup.cfg");
			ServerCommand("exec server_backup.cfg");			// Add option here to run server_backup.cfg
		}
		
		decl String:query[255];									// For Query
		//new ServerNo = GetConVarInt(ServerNumber);				// Check the server number
		
		// Get server ip from this server
		decl String:ServerIp[128];
 		GetConVarString(FindConVar("ip"), ServerIp, sizeof(ServerIp));

		// Get server port from this server
		decl String:ServerPort[128];
 		GetConVarString(FindConVar("hostport"), ServerPort, sizeof(ServerPort));
		
		// SQL Query
		Format(query, sizeof(query), "SELECT Command_Name, Command_Value FROM sc_servercfg INNER JOIN sb_servers ON sc_servercfg.Server_ID = sb_servers.sid WHERE sb_servers.ip = \"%s\" AND sb_servers.port = \"%s\"", ServerIp, ServerPort);
		// old: Format(query, sizeof(query), "SELECT Command_Name, Command_Value from sc_servercfg WHERE Server_ID = %i", ServerNo);
		
		// Error Checking LogAction(0, -1, "[MySCAL] Server No: %i, Query: %s", ServerNo, query);

		SQL_TQuery(hDatabase, T_RunConfigs, query);	

	}
}

//////////////////////////////////////////////////////////////////
// Run the configs
//////////////////////////////////////////////////////////////////
public T_RunConfigs(Handle:owner, Handle:hndl, const String:error[], any:data)
{
        if(!StrEqual("", error))
	{
		LogError("[MySCAL] Error Returning Results: %s", error);
		return;
	}
	
	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
                LogError("[MySCAL] Cannot find Server ID in database or there are no configs for the server");
                return;
	}
        
	// Error Checking LogAction(0, -1, "[MySCAL] Starting!");
	
	decl String:cmd[255];
	decl String:cmd2[255];
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, cmd, sizeof(cmd));
		SQL_FetchString(hndl, 1, cmd2, sizeof(cmd2));
		ServerCommand("%s \"%s\"",cmd, cmd2);

		//Error Checking LogAction(0, -1, "[MySCAL] Ran: %s %s", cmd, cmd2);
	}

	// Error Checking
	//LogAction(0, -1, "[MySCAL] completed!");

	// Added support for per map configs
	ServerCommand("exec %s.cfg", g_MapName);

	CloseHandle(hndl);
	CloseHandle(owner);
}

//////////////////////////////////////////////////////////////////
// Ran Logging Function
//////////////////////////////////////////////////////////////////
public T_RanLogging(Handle:owner2, Handle:hndl2, const String:error[], any:data)
{
        if(!StrEqual("", error))
	{
	//	LogError("[MySCAL] Error Returning Results: %s", error);
		PrintToChatAll("\x04[MySCAL]\x03 Error: %s", error);
		return;
	}
	
	if(hndl2 == INVALID_HANDLE || !SQL_GetRowCount(hndl2))
	{
         //       LogError("[MySCAL] Cannot find Server ID in database or there are no configs for the server");
                return;
	}

        // Error CheckingLogAction(0, -1, "[MySCAL] completed!");

	CloseHandle(hndl2);
	CloseHandle(owner2);
}





/** 
-- 
-- Tabellenstruktur für Tabelle `sc_servercfg`
-- 

CREATE TABLE IF NOT EXISTS `sc_servercfg` (
  `ID` int(11) NOT NULL auto_increment,
  `Server_ID` int(11) default NULL,
  `Command_Name` varchar(255) NOT NULL default '',
  `Command_Value` varchar(255) NOT NULL default '',
  `Comment` varchar(255) NOT NULL,
  `time_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;


-- 
-- Tabellenstruktur für Tabelle `sc_servers`
-- 

CREATE TABLE IF NOT EXISTS `sc_servers` (
  `sid` int(6) NOT NULL auto_increment,
  `ip` varchar(64) NOT NULL,
  `port` int(5) NOT NULL,
  PRIMARY KEY  (`sid`),
  UNIQUE KEY `ip` (`ip`,`port`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;


**/