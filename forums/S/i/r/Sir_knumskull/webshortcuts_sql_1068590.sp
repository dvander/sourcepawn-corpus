#pragma semicolon 1
#include <sourcemod>
#define WS_VERSION "1.0.1"
new Handle:hDatabase = INVALID_HANDLE;
new Handle:WSCSQL_ENABLE;
// Define author information
public Plugin:myinfo = 
{
	name = "Web Shortcuts SQL",
	author = "James \"sslice\" Gray, Sir_knumskull",
	description = "Provides chat-triggered web shortcuts stored in SQL database",
	version = WS_VERSION,
	url = "http://www.sourcemod.net"
};
new Handle:g_Shortcuts;
new Handle:g_Titles;
new Handle:g_Links;
new String:g_ServerIp [32];
new String:g_ServerPort [16];

public OnPluginStart()
{

	CreateConVar( "sm_webshortcutssql_version", WS_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED );

	RegConsoleCmd( "say", OnSay );
	RegConsoleCmd( "say_team", OnSay );
	WSCSQL_ENABLE = CreateConVar("sm_webshortcutssql_enable","1","Enables and disables this plugin",FCVAR_PLUGIN);

	g_Shortcuts = CreateArray( 32 );
	g_Titles = CreateArray( 64 );
	g_Links = CreateArray( 512 );

	new Handle:cvar = FindConVar( "hostip" );
	new hostip = GetConVarInt( cvar );
	FormatEx( g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
		(hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF );

	cvar = FindConVar( "hostport" );
	GetConVarString( cvar, g_ServerPort, sizeof(g_ServerPort) );

	CreateTimer(4.0, OnPluginStart_Delayed);
	StartSQL();
}

public OnMapStart()
{
	CreateTimer(4.0, OnPluginStart_Delayed);
}

StartSQL()
{
	SQL_TConnect(GotDatabase);
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[WebShortcuts] Database failure: %s", error);
	}
	else
	{
		hDatabase = hndl;
		LogMessage("[WebShortcuts] Database Init (CONNECTED)");
	}
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (hDatabase == INVALID_HANDLE)
	{
		LogError("[WebShortcuts] Database Error");
	}

	decl String:query[255];

	Format(query, sizeof(query), "SELECT shortcuts, titles, links FROM ws_webshortcuts INNER JOIN ws_servers ON ws_webshortcuts.Server_ID = ws_servers.sid WHERE ws_servers.ip = \"%s\" AND ws_servers.port = \"%s\"", g_ServerIp, g_ServerPort);
	SQL_TQuery(hDatabase, T_RunConfigs, query);
}


public T_RunConfigs(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogError("[WebShortcuts] Error Returning Results: %s", error);
		return;
	}
	if((hndl == INVALID_HANDLE) || (!SQL_GetRowCount(hndl)))
	{
		LogError("[WebShortcuts] No results, your database is empty");
		return;
	}
	if(SQL_GetRowCount(hndl) > 0)
	{	
		PrintToServer("[WebShortcuts] %i rows found", SQL_GetRowCount(hndl));

		ClearArray( g_Shortcuts );
		ClearArray( g_Titles );
		ClearArray( g_Links );

		decl String:shortcuts[255];
		decl String:titles[255];
		decl String:links[255];
		while (SQL_FetchRow(hndl))
		{

			SQL_FetchString(hndl, 0, shortcuts, sizeof(shortcuts));
			SQL_FetchString(hndl, 1, titles, sizeof(titles));
			SQL_FetchString(hndl, 2, links, sizeof(links));

			PushArrayString( g_Shortcuts, shortcuts );
			PushArrayString( g_Titles, titles );
			PushArrayString( g_Links, links );

			PrintToServer("[WebShortcuts] Shortcut: %s, Title: %s, Link: %s", shortcuts, titles, links);
		}
		CloseHandle(hndl);
		CloseHandle(owner);
	}
}

public Action:OnSay(client, args)
{
	if(GetConVarInt(WSCSQL_ENABLE) > 0)
	{
		decl String:text [512];
		GetCmdArgString( text, sizeof(text) );
		
		new start;
		new len = strlen(text);
		if ( text[len-1] == '"' )
		{
			text[len-1] = '\0';
			start = 1;
		}
		
		decl String:shortcut [32];
		BreakString( text[start], shortcut, sizeof(shortcut) );
		
		new size = GetArraySize( g_Shortcuts );
		for (new i; i != size; ++i)
		{
			GetArrayString( g_Shortcuts, i, text, sizeof(text) );
			
			if ( strcmp( shortcut, text, false ) == 0 )
			{
				decl String:title [64];
				decl String:steamId [64];
				decl String:userId [16];
				decl String:name [64];
				decl String:clientIp [32];
				
				GetArrayString( g_Titles, i, title, sizeof(title) );
				GetArrayString( g_Links, i, text, sizeof(text) );
				
				GetClientAuthString( client, steamId, sizeof(steamId) );
				FormatEx( userId, sizeof(userId), "%u", GetClientUserId( client ) );
				GetClientName( client, name, sizeof(name) );
				GetClientIP( client, clientIp, sizeof(clientIp) );
				
				ReplaceString( title, sizeof(title), "{SERVER_IP}", g_ServerIp);
				ReplaceString( title, sizeof(title), "{SERVER_PORT}", g_ServerPort);
				ReplaceString( title, sizeof(title), "{STEAM_ID}", steamId);
				ReplaceString( title, sizeof(title), "{USER_ID}", userId);
				ReplaceString( title, sizeof(title), "{NAME}", name);
				ReplaceString( title, sizeof(title), "{IP}", clientIp);
				
				ReplaceString( text, sizeof(text), "{SERVER_IP}", g_ServerIp);
				ReplaceString( text, sizeof(text), "{SERVER_PORT}", g_ServerPort);
				ReplaceString( text, sizeof(text), "{STEAM_ID}", steamId);
				ReplaceString( text, sizeof(text), "{USER_ID}", userId);
				ReplaceString( text, sizeof(text), "{NAME}", name);
				ReplaceString( text, sizeof(text), "{IP}", clientIp);
				
				ShowMOTDPanel( client, title, text, MOTDPANEL_TYPE_URL );
			}
		}
	}
	
	return Plugin_Continue;	
}


/** 
-- 
-- Tabellenstruktur für Tabelle `sc_servercfg`
-- 

CREATE TABLE IF NOT EXISTS `ws_webshortcuts` (
  `ID` int(11) NOT NULL auto_increment,
  `Server_ID` int(11) default NULL,
  `shortcuts` varchar(255) NOT NULL default '',
  `titles` varchar(255) NOT NULL default '',
  `links` varchar(255) NOT NULL,
  `time_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;


-- 
-- Tabellenstruktur für Tabelle `sc_servers`
-- 

CREATE TABLE IF NOT EXISTS `ws_servers` (
  `sid` int(6) NOT NULL auto_increment,
  `ip` varchar(64) NOT NULL,
  `port` int(5) NOT NULL,
  PRIMARY KEY  (`sid`),
  UNIQUE KEY `ip` (`ip`,`port`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

**/