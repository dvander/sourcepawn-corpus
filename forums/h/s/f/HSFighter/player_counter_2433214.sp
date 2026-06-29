//////////////////////////////////////////////////////////////////
// Player Counter By HSFighter / http://hsfighter.net
//////////////////////////////////////////////////////////////////
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "1.1.0"
#define SQL_DB_CONF "sourcebans"
#define UPDATE_URL	"http://update.hsfighter.net/sourcemod/player_counter/player_counter.txt"

//////////////////////////////////////////////////////////////////
// Declaring variables, handles and load other stuff
//////////////////////////////////////////////////////////////////


new Handle:g_hPluginEnabled;
new Handle:g_hCheckRate;
new Handle:g_hCleandays;


new bool:g_bLateLoad;

new Handle:g_hHostPort;
new g_iHostPort;

new Handle:g_hHostIP;
new g_iHostIP;

new Handle:g_hSourceTV ;
new g_iSourceTV;


new Handle:g_hInGameOnly;

new g_iStartTime;



new String:g_sHostIP[16];

// Dbstuff
new Handle:g_hDbHandle;
new bool:g_bDBDelayedLoad;



//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
	name = "Player Counter",
	author = "HSFighter",
	description = "Count Players",
	version = PLUGIN_VERSION,
	url = "http://hsfighter.net"
}

//////////////////////////////////////////////////////////////////
// Start plugin
//////////////////////////////////////////////////////////////////

public OnPluginStart()
{	
	SQL_Pluginstart();
	
	CreateConVar("sm_playercounter_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	g_hPluginEnabled    = CreateConVar("sm_playercounter_enable",	  		"1",    "Enable/Disable Plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCheckRate 		= CreateConVar("sm_playercounter_intervall",	 	"15.0", "Intervall in minutes at players are checked", FCVAR_PLUGIN, true, 1.00, true, 60.00);
	g_hCleandays 		= CreateConVar("sm_playercounter_cleandays", 		"7", 	"Cleans the database input rows older than set value days. Set to 0 to leave all uncleaned.", FCVAR_PLUGIN);
	g_hInGameOnly       = CreateConVar("sm_playercounter_ignore_bots",	  	"1",    "Ignore bots on count", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_playercounter_clean", Command_CleanDays, ADMFLAG_ROOT, "sm_chatlogex_clean [days] - cleans the datebase rows older than days given in parameter (default value set by sm_layercounter_cleandays)");
	RegAdminCmd("sm_playercounter_save", SaveCount,ADMFLAG_ROOT, "Save Count to DB");
	
	AddCommandListener(MapChangeCallback, "map");
	
	CreateTimer(GetConVarFloat(g_hCheckRate) * 60.0, Checktime, _, TIMER_REPEAT);
	
	// Updater
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	AutoExecConfig(true, "plugin.playercounter");
	
	
	g_hSourceTV = FindConVar("tv_enable");
	
	g_iSourceTV = GetConVarInt(g_hSourceTV);
	HookConVarChange(g_hSourceTV, OnCvarChanged);
		
	g_iHostPort = GetConVarInt(g_hHostPort);
	HookConVarChange(g_hHostPort, OnCvarChanged);
	
	g_iHostIP = GetConVarInt(g_hHostIP);
	LongToIp(g_iHostIP, g_sHostIP, sizeof(g_sHostIP));
	HookConVarChange(g_hHostIP, OnCvarChanged);
	
	
	
}


//////////////////////////////////////////////////////////////////
// Start map
//////////////////////////////////////////////////////////////////

public OnMapStart()
{
	g_iStartTime = GetTime();
	CreateTimer(10.0, Timer_PluginStart, TIMER_FLAG_NO_MAPCHANGE);
}

//////////////////////////////////////////////////////////////////
// End Map
//////////////////////////////////////////////////////////////////

public OnMapEnd()
{
	
	new iMapTime = GetTime() - g_iStartTime;
	SaveMaptime(iMapTime);

	// Clean the logs	
	new clean_days = GetConVarInt(g_hCleandays);
	CleanDB(clean_days);
}


//////////////////////////////////////////////////////////////////
// Chnage Map
//////////////////////////////////////////////////////////////////

public Action:MapChangeCallback(client, const String:command[], argc)
{
   	new iMapTime = GetTime() - g_iStartTime;
	SaveMaptime(iMapTime);
}

//////////////////////////////////////////////////////////////////
// Action: Timer Pluginstart
//////////////////////////////////////////////////////////////////

public Action:Timer_PluginStart(Handle:timer)
{
	SaveCount(-1,0);
}

	
//////////////////////////////////////////////////////////////////
// Action: Timerloop
//////////////////////////////////////////////////////////////////

public Action:Checktime(Handle:timer)
{
	SaveCount(-1,0);
	return Plugin_Handled;
}


public Action: SaveCount(client, args)
{
	
	// Check if plugin is disbaled
	if(GetConVarInt(g_hPluginEnabled) != 1) return Plugin_Continue;	
	
	
	if(g_hDbHandle != INVALID_HANDLE)
	{	
		decl String:mapname[64];
		GetCurrentMap(mapname, sizeof(mapname));
		
		// Buffer ist extra 
		SQL_EscapeString(g_hDbHandle, mapname, mapname, sizeof(mapname));
		
		new String:query[1024];
		Format(query, sizeof(query), "INSERT INTO sm_playercounter\
													(ServerIP, ServerPort, Count, Map)\
											VALUES\	
												('%s', '%d', '%d', '%s')",
													g_sHostIP, g_iHostPort, GetRealClientCount(), mapname);
														
		SQL_TQuery(g_hDbHandle, SQLT_ErrorCheckCallback, query);
		
		
	}
	return Plugin_Continue;
}

public Action: SaveMaptime(maptime)
{
	
	// Check if plugin is disbaled
	if(GetConVarInt(g_hPluginEnabled) != 1) return Plugin_Continue;	
	
	
	if(g_hDbHandle != INVALID_HANDLE)
	{	
		decl String:mapname[64];
		GetCurrentMap(mapname, sizeof(mapname));
		
		// Buffer ist extra 
		SQL_EscapeString(g_hDbHandle, mapname, mapname, sizeof(mapname));
		
		new String:query[1024];
		Format(query, sizeof(query), "INSERT INTO sm_maptimes\
													(ServerIP, ServerPort, Time, Map)\
											VALUES\	
												('%s', '%d', '%d', '%s')",
													g_sHostIP, g_iHostPort, maptime, mapname);
														
		SQL_TQuery(g_hDbHandle, SQLT_ErrorCheckCallback, query);
		
		
	}
	return Plugin_Continue;
}


public Action:Command_CleanDays(client, args)
{
	if (args > 1)
		return Plugin_Continue;
	
	new clean_days;
	
	if (args > 0)
	{
		decl String:text[257];
		GetCmdArgString(text, sizeof(text));
		clean_days = StringToInt(text);
	}
	else
	{
		clean_days = GetConVarInt(g_hCleandays);
	}

	CleanDB(clean_days);
	
	PrintToConsole(client, "Player_Counter: Messages older than %d days were cleaned from the database.", clean_days);

	return Plugin_Continue;
}


public OnLibraryAdded(const String:name[])
{	
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

CleanDB(clean_days)
{
	if (clean_days > 0 )
	{
		decl String:query[512];
		Format(query, sizeof(query),
			"delete low_priority from `sm_playercounter` where `date` < subdate(now(), %d);",
			clean_days
		);
		SQL_TQuery(g_hDbHandle, SQLT_ErrorCheckCallback, query);
				
		Format(query, sizeof(query),
			"delete low_priority from `sm_maptimes` where `date` < subdate(now(), %d);",
			clean_days
		);
		SQL_TQuery(g_hDbHandle, SQLT_ErrorCheckCallback, query);
	}
}


public GetRealClientCount()
{
	new clients = 0;	
	
	if (GetConVarBool(g_hInGameOnly))
	{
		for( new i = 1; i <= GetMaxClients(); i++ ) 
		{
			// if( IsClientInGame( i ) && IsClientConnected( i ) && !IsFakeClient( i ) ) clients++;			
			if( IsClientConnected( i ) && !IsFakeClient( i ) ) clients++;			
		}
	}
	else
	{		
		clients = GetClientCount(true);		
		if (g_iSourceTV) clients -= 1;		
	}
	
	return clients;	
}




public SQLT_ErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("QueryErr: %s", error);
	}
}



public OnCvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if(cvar == g_hHostPort)
	{
		g_iHostPort = GetConVarInt(g_hHostPort);
	}
	else if(cvar == g_hHostIP)
	{
		g_iHostIP = GetConVarInt(g_hHostIP);		
		LongToIp(g_iHostIP, g_sHostIP, sizeof(g_sHostIP));
	}
	else if(cvar == g_hSourceTV)
	{
		g_iSourceTV = GetConVarInt(g_hSourceTV);
		
	}	
}

stock LongToIp(long, String:str[], maxlen)
{
	new pieces[4];
	
	pieces[0] = (long >>> 24 & 255);
	pieces[1] = (long >>> 16 & 255);
	pieces[2] = (long >>> 8 & 255);
	pieces[3] = (long & 255); 
	
	Format(str, maxlen, "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]); 
}



stock Handle:GetHost()
{
	g_hHostPort   = FindConVar("hostport");
	g_hHostIP     = FindConVar("hostip");
	
	// Shouldn't happen
	if(g_hHostPort == INVALID_HANDLE)
	{
		SetFailState("Couldn't find cvar 'hostport'");
	}
	if(g_hHostIP == INVALID_HANDLE)
	{
		SetFailState("Couldn't find cvar 'hostip'");
	}
}

stock Handle:SQL_Pluginstart()
{
	if(!SQL_CheckConfig(SQL_DB_CONF))
	{
		SetFailState("Couldn't find database config");
	}
	
	// We only connect directly if it was a lateload, else we connect when configs were executed to grab the cvars
	// Configs might've not been excuted and we can't grab the hostname/hostport else
	if(g_bLateLoad)
	{
		InitDB();
	}
	
	GetHost();
}


InitDB()
{
	SQL_TConnect(SQLT_ConnectCallback, SQL_DB_CONF);
}

public OnConfigsExecuted()
{
	if(g_bDBDelayedLoad)
	{
		InitDB();
		g_bDBDelayedLoad = false;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;

	if(!g_bLateLoad)
	{
		g_bDBDelayedLoad = true;
	}
	
	return APLRes_Success;
}

public SQLT_ConnectCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("ConErr: %s", error);
	}
	else
	{
		g_hDbHandle = hndl;
		
		// Set utf-8 encodings
		SQL_TQuery(g_hDbHandle, SQLT_ErrorCheckCallback, "SET NAMES 'utf8'");
														
		// Create table
		SQL_TQuery(g_hDbHandle, SQLT_ErrorCheckCallback, "CREATE TABLE IF NOT EXISTS `sm_playercounter` (\
															`ID` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,\
															`ServerIP` VARCHAR(15) NOT NULL,\
															`ServerPort` SMALLINT(5) UNSIGNED NOT NULL,\
															`Count`  INT(3) UNSIGNED NOT NULL,\
															`Map` VARCHAR(64) NOT NULL,\
															`date` timestamp NOT NULL default CURRENT_TIMESTAMP,\
															PRIMARY KEY (`ID`))\
															COLLATE='utf8_general_ci'\
															ENGINE=InnoDB\
															");
															
		SQL_TQuery(g_hDbHandle, SQLT_ErrorCheckCallback, "CREATE TABLE IF NOT EXISTS `sm_maptimes` (\
															`ID` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,\
															`ServerIP` VARCHAR(15) NOT NULL,\
															`ServerPort` SMALLINT(5) UNSIGNED NOT NULL,\
															`Time`  INT(11) UNSIGNED NOT NULL,\
															`Map` VARCHAR(64) NOT NULL,\
															`date` timestamp NOT NULL default CURRENT_TIMESTAMP,\
															PRIMARY KEY (`ID`))\
															COLLATE='utf8_general_ci'\
															ENGINE=InnoDB\
															");
	}
}

//////////////////////////////////////////////////////////////////
// Plugin end
//////////////////////////////////////////////////////////////////