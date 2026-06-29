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
new Handle:MALEnable;
new Handle:ServerNumber;
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
	ServerNumber 	=	CreateConVar("sm_myscal_server_no","1","Server Number", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	MALEnable 		= 	CreateConVar("sm_myscal_log_enable","1","Enables/Disables Admin Command Logging",FCVAR_PLUGIN);
	
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

/**
		// Make the table
		decl String:maketable[256];
		Format(maketable, 
		sizeof(maketable), 
	
		// Mine
		"CREATE TABLE IF NOT EXISTS `sm_servercfg` (`ID` int(11) NOT NULL auto_increment,`Server_ID` int(11) NOT NULL,`Key` varchar(255) collate utf8_bin NOT NULL,`Value` varchar(255) collate utf8_bin NOT NULL,`Time_Modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,PRIMARY KEY  (`ID`)) ENGINE=MyISAM;");
	
		if (!SQL_FastQuery(hDatabase, maketable)) {
    	   		 LogError("FATAL: Could not create table");
    	  		 SetFailState("Could not create table");

		}
**/
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
		new ServerNo = GetConVarInt(ServerNumber);				// Check the server number

		Format(query, sizeof(query), "SELECT Command_Name, Command_Value from sm_servercfg WHERE Server_ID = %i", ServerNo);

		// Error Checking LogAction(0, -1, "[MySCAL] Server No: %i, Query: %s", ServerNo, query);

		SQL_TQuery(hDatabase, T_RunConfigs, query);	

	}
}

//////////////////////////////////////////////////////////////////
// Run the confgs
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
		ServerCommand("%s %s",cmd, cmd2);

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
// Admin Logging to MySQL
//////////////////////////////////////////////////////////////////
public Action:OnLogAction(Handle:source, Identity:ident, client, target, const String:message[])
{
	// If there is no client or they're not an admin, we don't care.
	if (client < 1 || GetUserAdmin(client) == INVALID_ADMIN_ID || GetConVarInt(MALEnable) == 0)
	{
		return Plugin_Continue;
	}
	
	decl String:logtag[64];
	
	// At the moment extensions can't be passed through here yet,  so we only bother with plugins, and use "SM" for anything else.
	if (ident == Identity_Plugin)
	{
		GetPluginFilename(source, logtag, sizeof(logtag));

		// Make sure that its not us making it fail and causing an endless loop of logging
		//if (StrContains (logtag[], "myscal.smx")
		//{
		//	return Plugin_Handled;
		//}
	} 
	else 
	{
		strcopy(logtag, sizeof(logtag), "SM");
	}

	decl String:steamid[32];
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	// This is no longer needed as MySQL Supports ':', plus in the admins database we can use this to cross reference as needed
	// ':' is not a valid filesystem token on Windows so we replace it with '-' to keep the file names readable.
	// ReplaceString(steamid, sizeof(steamid), ":", "-")
	// But guess what! MySQL does not like ' bummer will have to check that now	
	
	//@@ReplaceString(message, sizeof(message), "\'", ".")
	//Allocate a new string big enough to handle a message entirely made up of '. +1 for the 'null' char (end of string marker)
	
	new quotedLen = (strlen(message) * 2) + 1;
	decl String:quotedMessage[quotedLen];

//	new String:quotedMessage[strlen(message)*2 + 1];

	//Did this from memory, params may not be right - you get the idea
	//SQL_EscapeString(hDatabase, quotedMessage, quotedLen, message);

	SQL_EscapeString(hDatabase, message, quotedMessage, quotedLen);

/**
native bool:SQL_EscapeString(Handle:database, 
                             const String:string[], 
                             String:buffer[], 
                             maxlength, 
                             &written=0);

**/

	if (hDatabase == INVALID_HANDLE)
	{
		LogError("[MySCAL] Database Error");
		return Plugin_Handled;
	}
		
	decl String:query[255];									// For Query
	new ServerNo = GetConVarInt(ServerNumber);				// Check the server number

	Format(query, 
	sizeof(query), 
	"INSERT INTO sm_logging (Server_ID, steamid, logtag, message) VALUES ('%i', '%s', '%s', '%s')", ServerNo, steamid, logtag, quotedMessage);

	SQL_TQuery(hDatabase, T_RanLogging, query);	
		
	// Error Checking
	//PrintToChatAll("\x04[MySCAL]\x03 SN: %i, Steam ID: %s, LogTag: %s", ServerNo, steamid, logtag);
	//PrintToChatAll("\x04[MySCAL]\x03 Query: %s", quotedMessage);

	// Stop from running twice
	return Plugin_Handled;
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

Server Files

CREATE TABLE IF NOT EXISTS sm_servercfg(
ID              int(11) PRIMARY KEY auto_increment,
Server_ID       int(11),
Command_Name    varchar(255) NOT NULL default '',
Command_Value   varchar(255) NOT NULL default '',
Value_Key       varchar(255) NOT NULL default '',
Default_Key     varchar(255) NOT NULL default '',
Type            varchar(16) NULL,
time_modified   timestamp(14) NOT NULL default
CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP
)TYPE=MyISAM;

 Logging

 CREATE TABLE `smwa`.`sm_logging` (
`ID` INT( 11 ) NOT NULL AUTO_INCREMENT ,
`Server_ID` INT( 11 ) NOT NULL ,
`steamid` VARCHAR( 100 ) NOT NULL ,
`logtag` VARCHAR( 100 ) NOT NULL ,
`message` VARCHAR( 255 ) NOT NULL ,
`time_modified` TIMESTAMP( 14 ) ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY ( `ID` )
) ENGINE = MYISAM 

**/