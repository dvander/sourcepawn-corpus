#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4.3"
#define TRANSLATION_NAME "mysqlt_bans.phrases"

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[ANY] MySQL-T Bans",
	author = "senseless",
	description = "Threaded steam id based mysql bans",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1759904"
};

enum DBTables
{
	DBTable_None = 0,			/**< Used for non-table queries */
	DBTable_MYBans,				/**< Used to verify the my_bans table */
	DBTable_MYIPBans,			/**< Used to verify the my_ipbans table */
	DBTable_MYBanlog,			/**< Used to verify the my_banlog table */
	DBTable_MYUnbanlog			/**< Used to verify the my_unbanlog table */
}

bool
	g_bMYBansVerified,
	g_bMYBanlogVerified,
	g_bMYUnbanlogVerified,
	g_bMYIPBansVerified,
	g_bConfigsAreExecuted,
	g_bDBLoaded
;

Database g_DB = null;

char g_sPrefix[32];

ConVar 
	cvar_LogBans,
	cvar_LogUnbans
;

public void OnPluginStart()
{
	Database.Connect(T_GetDatabase);
	CreateConVar("sm_mybans_version", PLUGIN_VERSION, "MYSQL-T Bans Version", FCVAR_SPONLY);
	cvar_LogBans = CreateConVar("sm_mybans_logbans", "0", "Create a database for logging bans");
	cvar_LogUnbans = CreateConVar("sm_mybans_logunbans", "0", "Create a database for logging unbans");
	cvar_LogBans.AddChangeHook(CH_OnLogBansChanged);
	cvar_LogUnbans.AddChangeHook(CH_OnLogUnbansChanged);
	LoadTranslations(TRANSLATION_NAME);
	AutoExecConfig();
}

public void OnConfigsExecuted()
{
	g_bConfigsAreExecuted = true;
	if (!g_bMYUnbanlogVerified && !g_bMYBanlogVerified && g_bDBLoaded)
	{
		VerifyBanlogTable();
	}
	Format(g_sPrefix, sizeof(g_sPrefix), "%T", "Chat reply prefix", LANG_SERVER);
}

void VerifyBansTable()
{
	char query[] =
	"CREATE TABLE IF NOT EXISTS `my_bans` ("...
		"`id` int(11) NOT NULL auto_increment,"...
		"`steam_id` varchar(32) NOT NULL,"...
		"`player_name` varchar(65) NOT NULL,"...
		"`ban_length` int(1) NOT NULL default '0',"...
		"`ban_reason` varchar(100) NOT NULL,"...
		"`banned_by` varchar(100) NOT NULL,"...
		"`timestamp` timestamp NOT NULL default '0000-00-00 00:00:00' on update CURRENT_TIMESTAMP,"...
		"PRIMARY KEY  (`id`),"...
		"UNIQUE KEY `steam_id` (`steam_id`)"...
	") ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;";

	g_DB.Query(T_DumpQuery, query, DBTable_MYBans);
}

void VerifyIPBansTable()
{
	char query[] =
	"CREATE TABLE IF NOT EXISTS `my_ipbans` ("...
		"`id` int(11) NOT NULL auto_increment,"...
		"`ip` varchar(32) NOT NULL,"...
		"`player_name` varchar(65) NOT NULL,"...
		"`ban_length` int(1) NOT NULL default '0',"...
		"`ban_reason` varchar(100) NOT NULL,"...
		"`banned_by` varchar(100) NOT NULL,"...
		"`timestamp` timestamp NOT NULL default '0000-00-00 00:00:00' on update CURRENT_TIMESTAMP,"...
		"PRIMARY KEY  (`id`),"...
		"UNIQUE KEY `ip` (`ip`)"...
	") ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;";
	
	g_DB.Query(T_DumpQuery, query, DBTable_MYIPBans);
}

void VerifyBanlogTable()
{
	char query[] =
	"CREATE TABLE IF NOT EXISTS `my_banlog` ("...
		"`id` int(11) NOT NULL auto_increment,"...
		"`steam_id` varchar(32) NOT NULL,"...
		"`player_name` varchar(65) NOT NULL,"...
		"`ban_length` int(1) NOT NULL default '0',"...
		"`ban_reason` varchar(100) NOT NULL,"...
		"`banned_by` varchar(100) NOT NULL,"...
		"`timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,"...
		"PRIMARY KEY (`id`),"...
		"UNIQUE KEY `steam_id` (`steam_id`)"...
	") ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;";

	g_DB.Query(T_DumpQuery, query, DBTable_MYBanlog);
}

void VerifyUnbanlogTable()
{
	char query[] =
	"CREATE TABLE IF NOT EXISTS `my_unbanlog` ("...
		"`id` int(11) NOT NULL auto_increment,"...
		"`steam_id` varchar(32) NOT NULL,"...
		"`unbanned_by` varchar(100) NOT NULL,"...
		"`timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,"...
		"PRIMARY KEY  (`id`),"...
		"UNIQUE KEY `steam_id` (`steam_id`)"...
	")ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;";

	g_DB.Query(T_DumpQuery, query, DBTable_MYUnbanlog);
}

void CH_OnLogBansChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue && !g_bMYBanlogVerified && g_bConfigsAreExecuted && g_bDBLoaded)
	{
		VerifyBanlogTable();
	}
}

void CH_OnLogUnbansChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue && !g_bMYUnbanlogVerified && g_bConfigsAreExecuted && g_bDBLoaded)
	{
		VerifyUnbanlogTable();
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		char steam_id[32];
		char query[255];
	
		if (!GetClientAuthId(client, AuthId_Engine, steam_id, sizeof(steam_id)))
		{
			return;
		}
		if (g_bMYBansVerified)
		{
			g_DB.Format(query, sizeof(query), "SELECT ban_length, ban_reason, TIMESTAMPDIFF(MINUTE, timestamp, now()) FROM my_bans WHERE steam_id = '%s'", steam_id);
			g_DB.Query(T_AuthCheck, query, GetClientUserId(client));
		}
		
		char ip[32];
		if (!GetClientIP(client, ip, sizeof(ip)))
		{
			return;
		}
		if (g_bMYIPBansVerified)
		{
			query[0] = '\0';
			g_DB.Format(query, sizeof(query), "SELECT ban_length, ban_reason, TIMESTAMPDIFF(MINUTE, timestamp, now()) FROM my_ipbans WHERE ip = '%s'", ip);
			g_DB.Query(T_IPCheck, query, GetClientUserId(client));
		}
	}
}                                        

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source)
{
	if (g_bMYBansVerified)
	{
		char query[255];
		char steam_id[32];
		char ban_length[32];
		
		if (time > 0)
		{
			char sTime[32];
			IntToString(time, sTime, sizeof(sTime));
			Format(ban_length, sizeof(ban_length), "%s minute", sTime);
		}
		else
		{
			ban_length = "permanent";
		}
	
		GetClientAuthId(client, AuthId_Engine, steam_id, sizeof(steam_id));
	
		g_DB.Format(query, sizeof(query), "REPLACE INTO my_bans (player_name, steam_id, ban_length, ban_reason, banned_by, timestamp) VALUES ('%N','%s','%d','%s','%N',CURRENT_TIMESTAMP)", client, steam_id, time, reason, source);
		g_DB.Query(T_DumpQuery, query);
		
		if (g_bMYBanlogVerified)
		{
			query[0] = '\0';
			g_DB.Format(query, sizeof(query), "REPLACE INTO my_banlog (player_name, steam_id, ban_length, ban_reason, banned_by, timestamp) VALUES ('%N','%s','%d','%s','%N',CURRENT_TIMESTAMP)", client, steam_id, time, reason, source);
			g_DB.Query(T_DumpQuery, query);
		}
		
		KickClient(client, "%t", "Client is banned", ban_length, reason);
		ReplyToCommand(source, "%s %T", g_sPrefix, "Ban success", source, steam_id, ban_length);
		LogMessage("%s %T", g_sPrefix, "Ban success", LANG_SERVER, steam_id, ban_length);
	}
	else
	{
		char steam_id[32];
		GetClientAuthId(client, AuthId_Engine, steam_id, sizeof(steam_id));
		ReplyToCommand(source, "%s %T", g_sPrefix, "Database failed to verify", source, "my_bans");
		ReplyToCommand(source, "%s %T", g_sPrefix, "Ban failed", source, steam_id);
	}
	return Plugin_Stop; // We do not want bans to be added to the server itself, only the database.
}

public Action OnRemoveBan(const char[] steam_id, int flags, const char[] command, any source)
{
	if (g_bMYBansVerified)
	{
		bool isIP = false;
		if ((strncmp(steam_id, "STEAM_", 6) != 0 || steam_id[7] != ':'))
		{
			if (!IsValidIP(steam_id))
			{
				ReplyToCommand(source, "%s %t", g_sPrefix, "Invalid id/ip");
				return Plugin_Stop;
			}
			isIP = true;
		}
		char query[255];
		
		if (isIP)
		{
			g_DB.Format(query, sizeof(query), "DELETE FROM my_ipbans WHERE ip='%s'", steam_id);
			g_DB.Query(T_DumpQuery, query);
		}
		else
		{
			g_DB.Format(query, sizeof(query), "DELETE FROM my_bans WHERE steam_id='%s'", steam_id);
			g_DB.Query(T_DumpQuery, query);
		}
		
		
		if (g_bMYUnbanlogVerified)
		{
			query[0] = '\0';
			g_DB.Format(query, sizeof(query), "REPLACE INTO my_unbanlog (steam_id, unbanned_by, timestamp) VALUES ('%s','%N',CURRENT_TIMESTAMP)", steam_id, source);
			g_DB.Query(T_DumpQuery, query);
		}
		ReplyToCommand(source, "%s %t", g_sPrefix, "Unban success", steam_id);
		LogMessage("%s %T", g_sPrefix, "Unban success", LANG_SERVER, steam_id);
	}
	else
	{
		ReplyToCommand(source, "%s %t", g_sPrefix, "Database failed to verify", "my_bans");
		ReplyToCommand(source, "%s %t", g_sPrefix, "Unban failed", steam_id);
	}
	return Plugin_Continue; // We are preventing any bans from occurring on server already. But, if bans which were present beforehand need to be removed, we'll allow it.
}

public Action OnBanIdentity(const char[] identity, int time, int flags, const char[] reason, const char[] command, any source)
{
	if (strcmp(command, "sm_addban") == 0)
	{
		if (g_bMYBansVerified)
		{		
			char query[255];
			char ban_length[32];
			
			if (time > 0)
			{
				char sTime[32];
				IntToString(time, sTime, sizeof(sTime));
				Format(ban_length, sizeof(ban_length), "%s minute", sTime);
			}
			else
			{
				ban_length = "permanent";
			}
		
			char steam_id[32];
			char player_name[64] = "steamid_only";
			for (int i = 1; i <= MaxClients; ++i)
			{
				steam_id[0] = '\0';
				if (IsClientInGame(i) && GetClientAuthId(i, AuthId_Engine, steam_id, sizeof(steam_id)) && strcmp(steam_id, identity, false) == 0)
				{
					player_name[0] = '\0';
					GetClientName(i, player_name, sizeof(player_name));
					KickClient(i, "%t", "Client is banned", ban_length, reason);
					break;
				}
			}
		
			g_DB.Format(query, sizeof(query), "REPLACE INTO my_bans (player_name, steam_id, ban_length, ban_reason, banned_by, timestamp) VALUES ('%s','%s','%d','%s','%N',CURRENT_TIMESTAMP)", player_name, identity, time, reason, source);
			g_DB.Query(T_DumpQuery, query);
			
			if (g_bMYBanlogVerified)
			{
				query[0] = '\0';
				g_DB.Format(query, sizeof(query), "REPLACE INTO my_banlog (player_name, steam_id, ban_length, ban_reason, banned_by, timestamp) VALUES ('%s','%s','%d','%s','%N',CURRENT_TIMESTAMP)", player_name, identity, time, reason, source);
				g_DB.Query(T_DumpQuery, query);
			}
			
			ReplyToCommand(source, "%s %t", g_sPrefix, "Ban success", identity, ban_length);
			LogMessage("%s %T", g_sPrefix, "Ban success", LANG_SERVER, identity, ban_length);
		}
		else
		{
			ReplyToCommand(source, "%s %t", g_sPrefix, "Database failed to verify", "my_bans");
			ReplyToCommand(source, "%s %t", g_sPrefix, "Ban failed", identity);
		}
		return Plugin_Stop;
	}
	else if (strcmp(command, "sm_banip") == 0)
	{
		if (g_bMYIPBansVerified)
		{
			char target_name[MAX_TARGET_LENGTH];
			int target_list[1];
			bool tn_is_ml;
			if (!IsValidIP(identity) && ProcessTargetString(identity, source, target_list, sizeof(target_list), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI, target_name, sizeof(target_name), tn_is_ml) != 1)
			{
				ReplyToCommand(source, "%s %t", g_sPrefix, "Invalid id/ip");
				return Plugin_Stop;
			}
			char query[255];
			char ban_length[32];
			
			if (time > 0)
			{
				char sTime[32];
				IntToString(time, sTime, sizeof(sTime));
				Format(ban_length, sizeof(ban_length), "%s minute", sTime);
			}
			else
			{
				ban_length = "permanent";
			}
		
			char ip[32];
			char player_name[64] = "ip_only";
			for (int i = 1; i <= MaxClients; ++i)
			{
				ip[0] = '\0';
				if (IsClientInGame(i) && GetClientIP(i, ip, sizeof(ip)) && strcmp(ip, identity, false) == 0)
				{
					player_name[0] = '\0';
					GetClientName(i, player_name, sizeof(player_name));
					KickClient(i, "%t", "Client is banned", ban_length, reason);
					break;
				}
			}
		
			g_DB.Format(query, sizeof(query), "REPLACE INTO my_ipbans (player_name, ip, ban_length, ban_reason, banned_by, timestamp) VALUES ('%s','%s','%d','%s','%N',CURRENT_TIMESTAMP)", player_name, identity, time, reason, source);
			g_DB.Query(T_DumpQuery, query);
			
			if (g_bMYBanlogVerified)
			{
				query[0] = '\0';
				g_DB.Format(query, sizeof(query), "REPLACE INTO my_banlog (player_name, steam_id, ban_length, ban_reason, banned_by, timestamp) VALUES ('%s','%s','%d','%s','%N',CURRENT_TIMESTAMP)", player_name, identity, time, reason, source);
				g_DB.Query(T_DumpQuery, query);
			}
			
			ReplyToCommand(source, "%s %t", g_sPrefix, "Ban success", identity, ban_length);
			LogMessage("%s %T", g_sPrefix, "Ban success", LANG_SERVER, identity, ban_length);
		}
		else
		{
			ReplyToCommand(source, "%s %t", g_sPrefix, "Database failed to verify", "my_bans");
			ReplyToCommand(source, "%s %t", g_sPrefix, "Ban failed", identity);
		}
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

void T_AuthCheck(Database db, DBResultSet results, const char[] error, int userid)
{
	int client;
	if ((client = GetClientOfUserId(userid)) == 0)
	{
		return;
	}
	
	if (results == null)
	{
		LogError("%s %T: %s", g_sPrefix, "Query failed", LANG_SERVER, error);
		return;
	}
	
	char steam_id[32];

	GetClientAuthId(client, AuthId_Engine, steam_id, sizeof(steam_id));

	if(results.FetchRow())
	{
		int ban_length = results.FetchInt(0);
		int ban_passed = results.FetchInt(2);
		char ban_reason[100];
		char query[255];
		char sban_remaining[32];
		int ban_remaining = ban_length - ban_passed;
		results.FetchString(1, ban_reason, sizeof(ban_reason));
		
		if (ban_length == 0 || ban_remaining > 0)
		{
			if (ban_remaining > 0)
			{
				char sTime[32];
				IntToString(ban_remaining, sTime, sizeof(sTime));
				Format(sban_remaining, sizeof(sban_remaining), "%s minute", sTime);
			}
			else
			{
				sban_remaining = "permanent";
			}
			KickClient(client, "%t", "Client is banned", sban_remaining, ban_reason);
		}
		else
		{
			g_DB.Format(query, sizeof(query), "DELETE FROM my_bans WHERE steam_id='%s'", steam_id);
			g_DB.Query(T_DumpQuery, query);
			if (g_bMYUnbanlogVerified)
			{
				query[0] = '\0';
				g_DB.Format(query, sizeof(query), "REPLACE INTO my_unbanlog (steam_id, unbanned_by, timestamp) VALUES ('%s','%s',CURRENT_TIMESTAMP)", steam_id, "server");
				g_DB.Query(T_DumpQuery, query);
			}
			LogMessage("%s %T", g_sPrefix, "Auto unban", LANG_SERVER, steam_id);
		}
	}
}


void T_IPCheck(Database db, DBResultSet results, const char[] error, int userid)
{
	int client;
	if ((client = GetClientOfUserId(userid)) == 0)
	{
		return;
	}
	
	if (results == null)
	{
		LogError("%s %T: %s", g_sPrefix, "Query failed", LANG_SERVER, error);
		return;
	}
	
	char ip[32];

	GetClientIP(client, ip, sizeof(ip));

	if(results.FetchRow())
	{
		int ban_length = results.FetchInt(0);
		int ban_passed = results.FetchInt(2);
		char ban_reason[100];
		char query[255];
		char sban_remaining[32];
		int ban_remaining = ban_length - ban_passed;
		results.FetchString(1, ban_reason, sizeof(ban_reason));
		
		if (ban_length == 0 || ban_remaining > 0)
		{
			if (ban_remaining > 0)
			{
				char sTime[32];
				IntToString(ban_remaining, sTime, sizeof(sTime));
				Format(sban_remaining, sizeof(sban_remaining), "%s minute", sTime);
			}
			else
			{
				sban_remaining = "permanent";
			}
			KickClient(client, "%t", "Client is banned", sban_remaining, ban_reason);
		}
		else
		{
			g_DB.Format(query, sizeof(query), "DELETE FROM my_ipbans WHERE ip='%s'", ip);
			g_DB.Query(T_DumpQuery, query);
			if (g_bMYUnbanlogVerified)
			{
				query[0] = '\0';
				g_DB.Format(query, sizeof(query), "REPLACE INTO my_unbanlog (steam_id, unbanned_by, timestamp) VALUES ('%s','%s',CURRENT_TIMESTAMP)", ip, "server");
				g_DB.Query(T_DumpQuery, query);
			}
			LogMessage("%s %T", g_sPrefix, "Auto unban", LANG_SERVER, ip);
		}
	}
}

void T_DumpQuery(Database db, DBResultSet results, const char[] error, DBTables table=DBTable_None)
{
	if (results == null)
	{
		LogError("%s %T: %s", g_sPrefix, "Query failed", LANG_SERVER, error);
		return;
	}
	else
	{
		switch(table)
		{
			case DBTable_None:
			{
				
			}
			case DBTable_MYBans:
			{
				g_bMYBansVerified = true;
			}
			case DBTable_MYBanlog:
			{
				g_bMYBanlogVerified = true;
			}
			case DBTable_MYUnbanlog:
			{
				g_bMYUnbanlogVerified = true;
			}
			case DBTable_MYIPBans:
			{
				g_bMYIPBansVerified = true;
			}
		}
	}
}

void T_GetDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("%s %T: %s", g_sPrefix, "Database connection error", LANG_SERVER, error);
		return;
	}
	else
	{
		g_DB = db;
		g_bDBLoaded = true;
		VerifyBansTable();
		VerifyIPBansTable();
		if (cvar_LogBans.BoolValue && !g_bMYBanlogVerified && g_bConfigsAreExecuted)
		{
			VerifyBanlogTable();
		}
		if (cvar_LogUnbans.BoolValue && !g_bMYUnbanlogVerified && g_bConfigsAreExecuted)
		{
			VerifyUnbanlogTable();
		}
	}
}

bool IsValidIP(const char[] ip)
{
	char splitIP[5][4];
	int splitSize = ExplodeString(ip, ".", splitIP, 5, 4, false);
	if (splitSize != 4)
	{
		return false;
	}
	int num = 0;
	for (int i = 0; i < 4; i++)
	{
		num = StringToInt(splitIP[i]);
		if (num < 0 || num > 255)
		{
			return false;
		}
	}
	return true;
}