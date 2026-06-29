#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <morecolors> 
#define PLUGIN_VERSION "1.0"
//#define DEBUG true

public Plugin:myinfo = {
	name = "RulesOverlay",
	author = "Animalnots",
	description = "Force a Player to read & agree the Rules (overlay) on connect",
	version = PLUGIN_VERSION,
	url = "dasdas"
};

new Handle:g_hOverlayTriggerAgree; // Handle - Convar trigger to stop showing rules
new String:g_sTriggerAgree[256]; // String Value - the trigger to stop showing rules
new Handle:g_hOverlayTriggerAgree2; // Handle - Convar trigger to stop showing rules 2
new String:g_sTriggerAgree2[256]; // String Value - the trigger to stop showing rules 2
new Handle:g_hOverlayTriggerRulesShow; // Handle - Convar trigger to show rules
new String:g_sTriggerRulesShow[256]; // String Value - the trigger to show rules
new Handle:g_hOverlayPath; // Handle - Convar path to rules overlay
new String:g_sOverlayPath[PLATFORM_MAX_PATH]; // String Value - path to rules overlay

new Handle:Rules_Timers[MAXPLAYERS+1]; //CALLED ONCE AFTER CONNECTION
new bool:c_Agreed[MAXPLAYERS+1]; // DO WE NEED TO SHOW OVERLAYS (It's the main thing that determines to show overlay to a client or not)
new bool:c_OverlayShown[MAXPLAYERS+1]; // to tell when player is chatting and when he's agreeing (if true then he's agreeing)

new Handle:Loop_Timers[MAXPLAYERS+1]; // CALLED EVERY X SECOND TO RESHOW OVERLAY

public OnPluginStart()
{
	// Translations
	LoadTranslations("rulesoverlays.phrases");

	// Convars
	CreateConVar("sm_rulesoverlays", "1.0", "Version of RulesOverlays plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hOverlayTriggerAgree = CreateConVar("sm_ro_triggeragree", "!agree", "Trigger to agree rules");
	GetConVarString(g_hOverlayTriggerAgree, g_sTriggerAgree, sizeof(g_sTriggerAgree)); // String Value - the trigger to stop showing rules
	g_hOverlayTriggerAgree2 = CreateConVar("sm_ro_triggeragree2", "!согласен", "Alternative Trigger to agree rules");
	GetConVarString(g_hOverlayTriggerAgree2, g_sTriggerAgree2, sizeof(g_sTriggerAgree2)); // String Value - the trigger to stop showing rules	
	g_hOverlayTriggerRulesShow = CreateConVar("sm_ro_triggerrules", "!rules", "Trigger to show rules");
	GetConVarString(g_hOverlayTriggerRulesShow, g_sTriggerRulesShow, sizeof(g_sTriggerRulesShow)); // String Value - the trigger to show rules
	g_hOverlayPath = CreateConVar("sm_ro_path", "overlays/rulesoverlays/rules", "Path to overlay without extensions at the end and materials folder at the beginning. Without starting slash!");
	GetConVarString(g_hOverlayPath, g_sOverlayPath, sizeof(g_sOverlayPath)); // String Value - the trigger to show rules

	// Cmds & triggers
	RegConsoleCmd("say", Say_callback, "For catching rules & agree triggers");
	RegConsoleCmd("say2", Say_callback,"For catching rules & agree triggers");
	RegConsoleCmd("say_team", Say_callback, "For catching rules & agree triggers");
	RegAdminCmd("sm_ro", Command_Help, ADMFLAG_ROOT, "Show all possible commands for root and hadles them");
	
	// Exec Config
	AutoExecConfig(true);

	// SQL initialization: Creating rulesoverlays table to store users agreements if does not exist
	new String:error[255];
	new String:querystr[255];
	new Handle:db = SQL_Connect("storage-local", false, error, sizeof(error));
	if (db == INVALID_HANDLE)
	{
		PrintToServer("Could not connect: %s", error);
	} else {
		Format(querystr, sizeof(querystr), "CREATE TABLE IF NOT EXISTS `rulesoverlay` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `authid` varchar(256) NOT NULL UNIQUE,	`agreed` int(3) NOT NULL DEFAULT '0');");
		new Handle:query = SQL_Query(db, querystr);
		if (query == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		CloseHandle(query);
		CloseHandle(db);
	}	
}

public Action:Command_Help(client, args)
{
	new String:buffer[256]; // FOR loading translations
	new argsnum = GetCmdArgs(); // numargs: 0 = OverlayClean, 1 = show overlay with number mentioned in 1-st argument
	
	// DEBUG
	#if defined DEBUG
		GetClientName(client, buffer, sizeof(buffer));
		LogAction(client, -1, "[AO]: Player %s triggered sm_ro command, Total args - %d", buffer, argsnum);
		PrintToServer("[AO]: Player %s triggered sm_ro command, Total args - %d", buffer, argsnum);
	#endif
	// END DEBUG
	
	
	if (argsnum != 1) {
		// If command not mentioned, show help
		Format(buffer, sizeof(buffer), "%T", "[RO]: sm_ro reset, force all clients disagree the rules.", client);
		CPrintToChat(client, buffer);
		
		// DEBUG
		#if defined DEBUG
			Format(buffer, sizeof(buffer), "%T", "[RO]: sm_ro drop, Makes all clients disagreed(drops table).", client);
			CPrintToChat(client, buffer);
			GetClientName(client, buffer, sizeof(buffer));
			LogAction(client, -1, "[RO]: Calling showhelp for %s", buffer);
			PrintToServer("[RO]: Calling showhelp for %s", buffer);
		#endif
		// END DEBUG
	} else {
		// Execute possible command
		new String:arg[256];
		new String:cmd[256];
		GetCmdArg(1,arg,sizeof(arg));
		
		if(Client_IsIngame(client) && Client_IsValid(client)) {
			// Reset command
			Format(cmd, sizeof(cmd), "reset");
			if (StrEqual(arg,cmd,false)) {
				// DEBUG
				#if defined DEBUG
					GetClientName(client, buffer, sizeof(buffer));
					LogAction(client, -1, "[RO]: Calling Command_TotalDbReset for %s", buffer);
					PrintToServer("[RO]: Calling Command_TotalDbReset for %s", buffer);
				#endif
				// END DEBUG
				Command_TotalDbReset();
				Format(buffer, sizeof(buffer), "%T", "[RO]: The Rules Table has been reset! All clients must agree the rules again!", client);
				CPrintToChat(client, buffer);
			}
			// Drop command
			#if defined DEBUG
				Format(cmd, sizeof(cmd), "drop");
				if (StrEqual(arg,cmd,false)) {
				GetClientName(client, buffer, sizeof(buffer));
				LogAction(client, -1, "[RO]: Calling Command_TotalDbDrop for %s", buffer);
				PrintToServer("[RO]: Calling Command_TotalDbDrop for %s", buffer);
				Command_TotalDbDrop();
				Format(buffer, sizeof(buffer), "%T", "[RO]: The Rules Table has been dropped! All clients are new from this moment!", client);
				CPrintToChat(client, buffer);
			#endif
		}
	}
	return Plugin_Continue;
}

Command_TotalDbReset()
{
	//UPDATES table and sets ageed=0 (false) to all clients
	new String:error[255];
	new String:querystr[255];
	new Handle:db = SQL_Connect("storage-local", false, error, sizeof(error));
	if (db == INVALID_HANDLE)
	{
		PrintToServer("Could not connect: %s", error);
	} else {
		Format(querystr, sizeof(querystr), "SELECT * FROM `rulesoverlay`;");
		new Handle:query = SQL_Query(db, querystr);
		new num = 0;
		if (query != INVALID_HANDLE)
		{
			num = SQL_GetRowCount(query);
		}
		CloseHandle(query);
		
		Format(querystr, sizeof(querystr), "UPDATE `rulesoverlay` SET agreed = 0 WHERE agreed = 1;");
		new Handle:query2 = SQL_Query(db, querystr);
		if (query2 == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		} else {
			Format(error, sizeof(error), "Rulesoverlay DB Successfully reset affected rows:%d",num); 
			PrintToChatAll(error);
		}
		CloseHandle(query2);
		CloseHandle(db);
	}
}

public OnClientPostAdminCheck(client)
{
	new String:steamid[256];
	new String:querystr[256];
	new String:error[256];
	GetClientAuthString(client, steamid, sizeof(steamid));
	new Handle:db = SQL_Connect("storage-local", false, error, sizeof(error));
	Format(querystr, sizeof(querystr), "SELECT * FROM rulesoverlay WHERE `authid` = '%s'", steamid);
	new Handle:query = SQL_Query(db, querystr);
	if (query == INVALID_HANDLE)
	{
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	} else {
		if (SQL_GetRowCount(query) == 0) 
		{
			Format(querystr, sizeof(querystr), "INSERT INTO rulesoverlay (`authid`) VALUES ('%s');", steamid);
			query = SQL_Query(db, querystr);
			if (query == INVALID_HANDLE)
			{
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
			} 
		}
	}
	Format(querystr, sizeof(querystr), "SELECT * FROM rulesoverlay WHERE authid = '%s' AND agreed = 1", steamid);
	query = SQL_Query(db, querystr);
	if (query == INVALID_HANDLE)
	{
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	} else {
		if (SQL_GetRowCount(query) == 1) 
		{
			c_Agreed[client] = true;
		} else {
			c_Agreed[client] = false;
		}
	}
	CloseHandle(query);
	CloseHandle(db);
	new userid = GetClientUserId(client);
	Rules_Timers[client] = CreateTimer(10.0, ClientAgreeCheck, userid);
}

public OnClientDisconnect(client)
{
	c_Agreed[client] = false;
	c_OverlayShown[client] = false;
	if (Rules_Timers[client] != INVALID_HANDLE)
	{
		KillTimer(Rules_Timers[client]);
		Rules_Timers[client] = INVALID_HANDLE;
	}
	if (Loop_Timers[client] != INVALID_HANDLE)
	{
		KillTimer(Loop_Timers[client]);
		Loop_Timers[client] = INVALID_HANDLE;
	}
}

public Action:ClientAgreeCheck(Handle:timer, any:userid)
{
	new client;
	client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client)) {
		// check agreed or not
		if (!c_Agreed[client]) {
			// client not agreed, call OverlayCheck until he agrees
			Loop_Timers[client] = CreateTimer(3.0, OverlayCheck, userid);
		}
	} else {
		// Destroying timers, resetting values and similiar stuff is handled with OnClientDisconnect
		// else case is supposed to be never triggered
	}
	// Timer being Destroyed
	Rules_Timers[client]  = INVALID_HANDLE;
}

public Action:OverlayCheck(Handle:timer, any:userid)
{
	// Shows overlay every 3.0 seconds (because overlays are automatically reset at round start)
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		if (!c_Agreed[client]) {
			// client still not agreed, show overlay and continue checking
			new String:buffer[255]; // reply to client
			Format(buffer, sizeof(buffer), "%T", "[RO]: You must agree the rules.", client);
			CPrintToChat(client, buffer);
			OverlaySet(userid, g_sOverlayPath);
			if (Loop_Timers[client] != INVALID_HANDLE)
			{
				KillTimer(Loop_Timers[client]);
				Loop_Timers[client] = INVALID_HANDLE;
			}
			Loop_Timers[client] = CreateTimer(3.0, OverlayCheck, userid);
		}
	} else {
		// Destroying timers, resetting values and similiar stuff is handled with OnClientDisconnect
		// else case is supposed to be never triggered
	}
}

stock OverlaySet(any:userid, String:overlay[])
{
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		c_OverlayShown[client] = true;
		Client_SetScreenOverlay(client, overlay);
	}
}

public Action:Say_callback(client, args)
{
	new String:error[255]; // sql error
	new String:buffer[255]; // reply to client
	new String:arg[256]; // chat trigger
	new String:authid[256]; // steamid for sql
	new String:querystr[256]; // sql query
	GetCmdArg(1,arg,sizeof(arg));
	
	// check if a trigger
	new String:trigger[256];
	new String:trigger2[256];
	new userid = GetClientUserId(client);
	
	Format(trigger, sizeof(trigger), g_sTriggerRulesShow);
	if (StrEqual(arg,trigger,false)) {
		// player triggered "rules", show overlay to him
		OverlaySet(userid, g_sOverlayPath);
		// Kill timer if exists
		if (Loop_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(Loop_Timers[client]);
			Loop_Timers[client] = INVALID_HANDLE;
		}
	}
	
	Format(trigger, sizeof(trigger), g_sTriggerAgree);
	Format(trigger2, sizeof(trigger2), g_sTriggerAgree2);
	if ((StrEqual(arg,trigger,false) || StrEqual(arg,trigger2,false)) && c_OverlayShown[client]) {
		// player "agrees" cause c_OverlayShown[client] = true and it means an overlay is shown to him at the moment
		c_Agreed[client] = true;	
		Format(buffer, sizeof(buffer), "%T", "[RO]: Thank you for agreement.", client);
		CPrintToChat(client, buffer);
		OverlayStop(userid);
		// update sql table
		new Handle:db = SQL_Connect("storage-local", false, error, sizeof(error));
		GetClientAuthString(client, authid, sizeof(authid));
		if (db == INVALID_HANDLE)
		{
			PrintToServer("Could not connect Say_callback: %s", error);
		} else {
			Format(querystr, sizeof(querystr), "UPDATE rulesoverlay SET agreed = 1 WHERE authid = '%s'", authid);
			new Handle:query = SQL_Query(db, querystr);
			if (query == INVALID_HANDLE)
			{
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
			}
		}

	}
	return Plugin_Continue;
}

public OnMapStart()
{
	decl String:vmt[PLATFORM_MAX_PATH];
	decl String:vtf[PLATFORM_MAX_PATH];
	PrintToServer("[RO]: Found cvar ad:materials/%s ",g_sOverlayPath);
	LogAction(-1, -1, "[RO]: Found cvar ad:materials/%s ",g_sOverlayPath);
	// Adds overlays to downloads table and prechaches them
	Format(vtf, sizeof(vtf), "materials/%s.vtf", g_sOverlayPath);
	Format(vmt, sizeof(vmt), "materials/%s.vmt", g_sOverlayPath);
	AddFileToDownloadsTable(vtf);
	AddFileToDownloadsTable(vmt);
	PrecacheDecal(vtf, true);
	PrintToServer("[RO]: Precached %s",vtf);
	LogAction(-1, -1, "[RO]: Precached %s",vtf);
}

public Action:OverlayClean(any:userid)
{
	// Prepare User Screen (cleans) To Show Next Overlay
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		Client_SetScreenOverlay(client, "off");
		Client_SetScreenOverlay(client, "");	
		c_OverlayShown[client] = false; 
	} else {
		// Destroying timers, resetting values and similiar stuff is handled with OnClientDisconnect
		// else case is supposed to be never triggered
	}
}

public Action:OverlayStop(any:userid)
{
	// Stops showing overlays
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		OverlayClean(userid);
		// Kill connect timer if client left too early
		if (Rules_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(Rules_Timers[client]);
			Rules_Timers[client] = INVALID_HANDLE;
		}
		// Kill any ad rotation timer (loop_timer)
		if (Loop_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(Loop_Timers[client]);
			Loop_Timers[client] = INVALID_HANDLE;
		}
	}
}

Command_TotalDbDrop()
{
	//Drops all data and creates a new table
	new String:error[255];
	new String:querystr[255];
	new Handle:db = SQL_Connect("storage-local", false, error, sizeof(error));
	if (db == INVALID_HANDLE)
	{
		PrintToServer("Could not connect: %s", error);
	} else {
		Format(querystr, sizeof(querystr), "DROP TABLE IF EXISTS rulesoverlay;");
		new Handle:query = SQL_Query(db, querystr);
		if (query == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		Format(querystr, sizeof(querystr), "CREATE TABLE IF NOT EXISTS `rulesoverlay` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `authid` varchar(256) NOT NULL UNIQUE,	`agreed` int(3) NOT NULL DEFAULT '0');");
		query = SQL_Query(db, querystr);
		if (query == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		CloseHandle(query);
		CloseHandle(db);
	}
}