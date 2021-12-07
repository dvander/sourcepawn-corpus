#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = {
	name = "[ANY] MySQL-T Bans",
	author = "senseless",
	description = "Threaded steam id based mysql bans",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1759904"
};

new Handle:hDatabase = INVALID_HANDLE;

public OnPluginStart() {
	VerifyTable();
	StartSQL();
	CreateConVar("sm_mybans_version", PLUGIN_VERSION, "MYSQL-T Bans Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
}

StartSQL() {
	SQL_TConnect(GotDatabase);
}
 
public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE) {
		LogError("[MYBans] Database Connection Error: %s", error);
	} else {
		hDatabase = hndl;
	}
}

public T_AuthCheck(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
 	decl ban_length;	
	decl String:steam_id[32];
 	decl String:ban_reason[100];
 	decl ban_remaining;
	decl String:query[255];
		
	if ((client = GetClientOfUserId(data)) == 0) {
		return;
	}

	GetClientAuthString(client, steam_id, sizeof(steam_id));

	new buffer_len = strlen(steam_id) * 2 + 1
	new String:v_steam_id[buffer_len]
	SQL_EscapeString(hDatabase, steam_id, v_steam_id, buffer_len)
 
	if (hndl == INVALID_HANDLE) {
		LogError("[MYBans] Query failed! %s", error);
		KickClient(client, "Error: Reattempt connection");
	}

	if(SQL_FetchRow(hndl)) {
		ban_length = SQL_FetchInt(hndl,0);
		SQL_FetchString(hndl,1,ban_reason,sizeof(ban_reason));
		if (ban_length == 0) {
				KickClient(client,"You have been Banned for %s", ban_reason);
				return;
		}
		ban_remaining = SQL_FetchInt(hndl,2);
		if (ban_remaining <= ban_length) {
			KickClient(client,"You have been Banned for %s", ban_reason);
		} else {
			Format(query, sizeof(query), "DELETE FROM my_bans WHERE steam_id='%s'", v_steam_id);
			SQL_TQuery(hDatabase, T_MYUnBan, query);
			LogMessage("[MYBans] User %s has been unbanned by elapse of time.", v_steam_id);
		}
	}
}

public T_MYBan(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE) {
		LogError("[MYBans] Query failed! %s", error);
	}
	return;
}

public T_MYUnBan(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE) {
		LogError("[MYBans] Query failed! %s", error);
	}
	return;
}

public OnClientPostAdminCheck(client) {

	if(IsFakeClient(client)) {
		return;
	}
	
	decl String:steam_id[32];
	decl String:query[255];

	GetClientAuthString(client, steam_id, sizeof(steam_id));

	new buffer_len = strlen(steam_id) * 2 + 1
	new String:v_steam_id[buffer_len]
	SQL_EscapeString(hDatabase, steam_id, v_steam_id, buffer_len)

	Format(query, sizeof(query), "SELECT ban_length, ban_reason, (now()-timestamp)/60 FROM my_bans WHERE steam_id = '%s'", v_steam_id);
	SQL_TQuery(hDatabase, T_AuthCheck, query, GetClientUserId(client));
}                                                

public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:admin) {
	decl String:query[255];
	decl String:steam_id[32];
 	decl String:player_name[65];
 	decl String:source[65];

	GetClientAuthString(client, steam_id, sizeof(steam_id));
	GetClientName(client, player_name, sizeof(player_name));
	GetClientName(admin, source, sizeof(source));

	new buffer_len = strlen(steam_id) * 2 + 1
	new String:v_steam_id[buffer_len]
	SQL_EscapeString(hDatabase, steam_id, v_steam_id, buffer_len)

	buffer_len = strlen(reason) * 2 + 1
	new String:v_reason[buffer_len]
	SQL_EscapeString(hDatabase, reason, v_reason, buffer_len)

	buffer_len = strlen(source) * 2 + 1
	new String:v_source[buffer_len]
	SQL_EscapeString(hDatabase, source, v_source, buffer_len)

	buffer_len = strlen(player_name) * 2 + 1
	new String:v_player_name[buffer_len]
	SQL_EscapeString(hDatabase, player_name, v_player_name, buffer_len)

	Format(query, sizeof(query), "REPLACE INTO my_bans (player_name, steam_id, ban_length, ban_reason, banned_by, timestamp) VALUES ('%s','%s','%d','%s','%s',CURRENT_TIMESTAMP)", v_player_name, v_steam_id, time, v_reason, v_source);
	SQL_TQuery(hDatabase, T_MYBan, query);
	KickClient(client,"You have been Banned for %s", reason);
	ReplyToCommand(admin, "[MYBans] User %s has been banned for %d minutes", steam_id, time);
	LogMessage("[MYBans] User %s has been banned for %d minutes", steam_id, time);
	return Plugin_Stop;
}

public Action:OnRemoveBan(const String:steam_id[], flags, const String:command[], any:admin) {
	decl String:query[255];

	new buffer_len = strlen(steam_id) * 2 + 1
	new String:v_steam_id[buffer_len]
	SQL_EscapeString(hDatabase, steam_id, v_steam_id, buffer_len)

	Format(query, sizeof(query), "DELETE FROM my_bans WHERE steam_id='%s'", v_steam_id);
	SQL_TQuery(hDatabase, T_MYUnBan, query);
	ReplyToCommand(admin, "[MYBans] User %s has been unbanned", steam_id);
	LogMessage("[MYBans] User %s has been unbanned.", steam_id);
	return Plugin_Stop;
}

bool:VerifyTable() {

	decl String:error[255];
	decl String:query[512];

	new Handle:db = SQL_Connect("default", true, error, sizeof(error));
	if (db == INVALID_HANDLE) {
		LogError("[MYBans] Could Not Connect to Database, error: %s", error);
		return false;
	}
	
	Format(query,sizeof(query), "%s%s%s%s%s%s%s%s%s%s%s",
		"CREATE TABLE IF NOT EXISTS `my_bans` (",
		"  `id` int(11) NOT NULL auto_increment,",
		"  `steam_id` varchar(32) NOT NULL,",
		"  `player_name` varchar(65) NOT NULL,",
		"  `ban_length` int(1) NOT NULL default '0',",
		"  `ban_reason` varchar(100) NOT NULL,",
		"  `banned_by` varchar(100) NOT NULL,",
		"  `timestamp` timestamp NOT NULL default '0000-00-00 00:00:00' on update CURRENT_TIMESTAMP,",
		"  PRIMARY KEY  (`id`),",
		"  UNIQUE KEY `steam_id` (`steam_id`)",
		") ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1; ");

	new bool:success = SQL_FastQuery(db, query);
	if(!success) {
		SQL_GetError(db, error, sizeof(error));
		LogError("[MYBans] Unable to verify mysql_bans table:%s", query);
	}

	CloseHandle(db);
	return true;
}

