#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "2.04"

new Handle:g_hDatabase = INVALID_HANDLE;
new g_iServerId;
new g_iClientId[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Item Logger",
	author = "Geit",
	description = "Item Logger",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
};

public OnPluginStart()
{
	CreateConVar("sm_item_logger_version", PL_VERSION, "TF2 Item Logger", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Hook Events
	HookEvent("item_found", Event_Item_Found);
	
	Database_Init();
	
	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			decl String:strClientAuth[32];
			
			GetClientAuthString(client, strClientAuth, sizeof(strClientAuth));
			
			OnClientAuthorized(client, strClientAuth);
		}
	}
}

public OnClientAuthorized(client, const String:strClientAuth[])
{
	if(DatabaseIntact())
	{
		decl String:strClientAuthEsc[96], String:strClientName[32], String:strClientNameEsc[96], String:strQuery[512];
	
		GetClientName(client, strClientName, sizeof(strClientName));
		
		SQL_EscapeString(g_hDatabase, strClientName, strClientNameEsc, sizeof(strClientNameEsc));
		SQL_EscapeString(g_hDatabase, strClientAuth, strClientAuthEsc, sizeof(strClientAuthEsc));
		
		Format(strQuery, sizeof(strQuery), "INSERT IGNORE INTO `itemlogger2_players` (`steam_id`, `name`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE `name`='%s'", strClientAuthEsc, strClientNameEsc, strClientNameEsc);
		SQL_TQuery(g_hDatabase, T_PlayerInsert, strQuery, GetClientUserId(client));
	}
}

public OnClientDisconnect(client)
{
	g_iClientId[client] = 0;
}

public Action:Event_Item_Found(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new client = GetEventInt(hEvent, "player");
	new iMethod = GetEventInt(hEvent, "method");
	
	//Item Info
	new iItemDefIndex = GetEventInt(hEvent, "itemdef"); //signed int, 32 bit
	new iItemQuality = GetEventInt(hEvent, "quality");
	
	LogToFile("item_logger.log", "Item Found by client #%i on server #%i, of type %i via method #%i and of quality %i", g_iClientId[client], g_iServerId, iItemDefIndex, iMethod, iItemQuality);
	
	if (client > 0 && IsClientInGame(client) && iMethod < 20 && DatabaseIntact() && g_iClientId[client] > 0 && g_iServerId > 0)
	{
		decl String:strQuery[1024];

		Format(strQuery, sizeof(strQuery), "INSERT IGNORE INTO `itemlogger2_finds` (`player_id`, `server_id`, `player_count`, `item_index`, `method`, `quality`, `time`) VALUES (%i, %i, %i, %i, %i, %i, UNIX_TIMESTAMP())", g_iClientId[client], g_iServerId, GetClientCount(true), iItemDefIndex, iMethod, iItemQuality);
		SQL_TQuery(g_hDatabase, T_ErrorOnly, strQuery);
	}
}

public DatabaseIntact()
{
	if (g_hDatabase == INVALID_HANDLE)
	{
		return Database_Init();
	}
	return true;
}  

public T_ErrorOnly(Handle:hOwner, Handle:hResult, const String:strError[], any:client)
{
	if(hResult == INVALID_HANDLE)
	{
		LogError("[Item Logger] MYSQL ERROR (error: %s)", strError);
		PrintToChatAll("[Item Logger] MYSQL ERROR (error: %s)", strError);
	}
}

public T_ServerInsert(Handle:hOwner, Handle:hResult, const String:strError[], any:unused)
{
	if(hResult == INVALID_HANDLE)
	{
		LogError("[Item Logger] MYSQL ERROR (error: %s)", strError);
		PrintToChatAll("[Item Logger] MYSQL ERROR (error: %s)", strError);
	}
	else
	{
		if(DatabaseIntact())
		{
			decl String:strIP[24], String:strIPEsc[72], String:strQuery[512];

			//Work out the server's IP:Port Combo
			GetConVarString(FindConVar("ip"), strIP, sizeof(strIP));
			new iPort = GetConVarInt(FindConVar("hostport"));
		
			SQL_EscapeString(g_hDatabase, strIP, strIPEsc, sizeof(strIPEsc)); 
			
			Format(strQuery, sizeof(strQuery), "SELECT `id` FROM `itemlogger2_servers` WHERE `ip`='%s' AND `port` = %i LIMIT 1", strIPEsc, iPort);
			SQL_TQuery(g_hDatabase, T_ServerSelect, strQuery);
		}
	}
}

public T_ServerSelect(Handle:hOwner, Handle:hResult, const String:strError[], any:unused)
{
	if(hResult == INVALID_HANDLE)
	{
		LogError("[Item Logger] MYSQL ERROR (error: %s)", strError);
		PrintToChatAll("[Item Logger] MYSQL ERROR (error: %s)", strError);
	}
	else
	{
		if(SQL_FetchRow(hResult))
			g_iServerId =  SQL_FetchInt(hResult, 0);
	}
}

public T_PlayerInsert(Handle:hOwner, Handle:hResult, const String:strError[], any:iUserId)
{
	new client = GetClientOfUserId(iUserId);
	if ( client == 0 )
	{
		return;
	}
	
	if(hResult == INVALID_HANDLE)
	{
		LogError("[Item Logger] MYSQL ERROR (error: %s)", strError);
		PrintToChatAll("[Item Logger] MYSQL ERROR (error: %s)", strError);
	}
	else
	{
		if(DatabaseIntact())
		{
			decl String:strClientAuth[32], String:strClientAuthEsc[96], String:strQuery[512];

			GetClientAuthString(client, strClientAuth, sizeof(strClientAuth));
			
			SQL_EscapeString(g_hDatabase, strClientAuth, strClientAuthEsc, sizeof(strClientAuthEsc)); 
			
			Format(strQuery, sizeof(strQuery), "SELECT `id` FROM `itemlogger2_players` WHERE `steam_id`='%s'", strClientAuthEsc);
			SQL_TQuery(g_hDatabase, T_PlayerSelect, strQuery, iUserId);
		}
	}
}

public T_PlayerSelect(Handle:hOwner, Handle:hResult, const String:strError[], any:iUserId)
{
	new client = GetClientOfUserId(iUserId);
	if ( client == 0)
	{
		return;
	}
	
	if(hResult == INVALID_HANDLE)
	{
		LogError("[Item Logger] MYSQL ERROR (error: %s)", strError);
		PrintToChatAll("[Item Logger] MYSQL ERROR (error: %s)", strError);
	}
	else
	{
		if(SQL_FetchRow(hResult))
			g_iClientId[client] =  SQL_FetchInt(hResult, 0);
	}
}


stock Database_Init()
{
	
	decl String:strError[255];	
	g_hDatabase = SQL_Connect("itemlogger2", true, strError, sizeof(strError));
	
	if(g_hDatabase != INVALID_HANDLE)
	{
		SQL_FastQuery(g_hDatabase, "SET NAMES UTF8");
		
		if ( !SQL_FastQuery(g_hDatabase, "CREATE TABLE IF NOT EXISTS `itemlogger2_finds` (`id` int(11) unsigned NOT NULL AUTO_INCREMENT,`player_id` int(11) unsigned NOT NULL DEFAULT '0',`server_id` int(11) unsigned NOT NULL DEFAULT '0',`player_count` tinyint(3) unsigned NOT NULL DEFAULT '0',`item_index` int(11) NOT NULL DEFAULT '0' COMMENT 'signed int, 32 bit',`method` tinyint(2) NOT NULL DEFAULT '0',`quality` tinyint(2) NOT NULL DEFAULT '0',`time` int(11) unsigned NOT NULL DEFAULT '0',PRIMARY KEY (`id`),KEY `actual_time` (`time`)) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;")
			|| !SQL_FastQuery(g_hDatabase, "CREATE TABLE IF NOT EXISTS `itemlogger2_items` (`id` int(11) unsigned NOT NULL DEFAULT '0',`item_name` tinytext,`proper_name` tinyint(1) DEFAULT NULL,`item_slot` varchar(16) DEFAULT NULL,`image_url` tinytext,`material_type` varchar(16) DEFAULT NULL,PRIMARY KEY (`id`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;")
			|| !SQL_FastQuery(g_hDatabase, "CREATE TABLE IF NOT EXISTS `itemlogger2_players` (`id` int(11) unsigned NOT NULL AUTO_INCREMENT,`steam_id` varchar(25) NOT NULL DEFAULT '',`name` varchar(32) DEFAULT NULL,`avatar` tinytext,`avatar_last_updated` int(11) DEFAULT NULL,PRIMARY KEY (`id`),UNIQUE KEY `steam_id` (`steam_id`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;")
			|| !SQL_FastQuery(g_hDatabase, "CREATE TABLE IF NOT EXISTS `itemlogger2_qualities` (`id` tinyint(3) unsigned NOT NULL,`name` varchar(32) DEFAULT '0',`raw_name` varchar(32) DEFAULT '0',PRIMARY KEY (`id`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;")
			|| !SQL_FastQuery(g_hDatabase, "CREATE TABLE IF NOT EXISTS `itemlogger2_servers` (`id` int(11) unsigned NOT NULL AUTO_INCREMENT,`ip` varchar(16) DEFAULT '127.0.0.1',`port` smallint(5) unsigned DEFAULT '27015',`name` tinytext,PRIMARY KEY (`id`),UNIQUE KEY `ip_port` (`ip`,`port`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;"))
		{
			SQL_GetError(g_hDatabase, strError, sizeof(strError));
			PrintToServer("[Item Logger] MYSQL ERROR: ", strError);
		}
		
		decl String:strIP[24], String:strIPEsc[72], String:strHostname[128], String:strHostnameEsc[384], String:strQuery[1024];

		//Work out the server's IP:Port Combo
		GetConVarString(FindConVar("ip"), strIP, sizeof(strIP));
		GetConVarString(FindConVar("hostname"), strHostname, sizeof(strHostname));
		new iPort = GetConVarInt(FindConVar("hostport"));
		
		SQL_EscapeString(g_hDatabase, strHostname, strHostnameEsc, sizeof(strHostnameEsc)); 
		SQL_EscapeString(g_hDatabase, strIP, strIPEsc, sizeof(strIPEsc)); 
		
		Format(strQuery, sizeof(strQuery), "INSERT INTO `itemlogger2_servers` (`ip`, `port`, `name`) VALUES ('%s', '%i', '%s') ON DUPLICATE KEY UPDATE `name`='%s'", strIPEsc, iPort, strHostnameEsc, strHostnameEsc);
		SQL_TQuery(g_hDatabase, T_ServerInsert, strQuery);
		return true;
	} 
	else 
	{
		PrintToServer("Connection Failed for item logger: %s", strError);
		return false;
	}
}