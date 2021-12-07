/**
 * =============================================================================
 * Cep>|< - Russian BugTrack Group - IP range ban based on MySQL
 * IP range ban based on MySQL plugin
 * Cep>|< - Russian BugTrack Group (C) 2009
 * =============================================================================
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "IP range ban on MySQL",
	author = "Cep>|< - Russian BugTrack Group",
	description = "IP range ban based on MySQL",
	version = PLUGIN_VERSION,
	url = "http://www.alliedmods.net/"
};

#define MAX_BANS 64
#define MAX_WHITE_IP 128
#define MAX_WHITE_STEAM_ID 128

new Handle:db = INVALID_HANDLE;
new Handle:g_Enabled = INVALID_HANDLE;
new Handle:g_Prefix = INVALID_HANDLE;
new Handle:g_DatabaseConfig = INVALID_HANDLE;
new Handle:g_useWhiteListIP = INVALID_HANDLE;
new Handle:g_useWhiteListSteamID = INVALID_HANDLE;
new Handle:g_LoggingKickedPlayers = INVALID_HANDLE;

new String:sm_iprangeban_mysql_prefix[32];
new String:sm_iprangeban_mysql_dbconfig[32];

new BansCount = 0;
new WhiteIPCount = 0;
new WhiteIDCount = 0;
new Long:IPStartArray[MAX_BANS];
new Long:IPEndArray[MAX_BANS];
new String:KickReason[MAX_BANS][128];
new String:WhiteIP[MAX_WHITE_IP][20];
new String:WhiteSteamID[MAX_WHITE_STEAM_ID][64];

public OnPluginStart()
{
	CreateConVar("sm_iprangeban_mysql_version", PLUGIN_VERSION, "IP range ban on MySQL", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
   	g_Enabled = CreateConVar("sm_iprangeban_mysql_enable", "1", "Enables this plugin");
   	g_Prefix = CreateConVar("sm_iprangeban_mysql_prefix", "sm_iprangeban", "Table prefix in database");
   	g_DatabaseConfig = CreateConVar("sm_iprangeban_mysql_dbconfig", "ip_range_ban", "Name of database config in database.cfg");
   	g_useWhiteListIP = CreateConVar("sm_iprangeban_mysql_uwl_ip", "0", "Use white list IP's");
   	g_useWhiteListSteamID = CreateConVar("sm_iprangeban_mysql_uwl_id", "0", "Use white list SteamID's");
   	g_LoggingKickedPlayers = CreateConVar("sm_iprangeban_mysql_logging", "1", "Logging kicked players");
   	AutoExecConfig(true, "iprangeban_mysql");
    }
public OnConfigsExecuted()
{
	GetConVarString(g_Prefix, sm_iprangeban_mysql_prefix, 32);
	GetConVarString(g_DatabaseConfig, sm_iprangeban_mysql_dbconfig, 32);
        if (db != INVALID_HANDLE) CloseHandle(db);
        ConnectToMysql();
}
stock MysqlStart()
{
    BansCount = 0;
    WhiteIPCount = 0;
    WhiteIDCount = 0;
    new String:sql[128];
    Format(sql, sizeof(sql), "SELECT start,end,text_to_kick FROM %s_ip_range", sm_iprangeban_mysql_prefix);
    new Handle:hQuery = SQL_Query(db, sql);
    if (hQuery == INVALID_HANDLE) {
        LogError("Query failed! %s", sql);
    } else {
    new String:ip[20];
    while (SQL_FetchRow(hQuery))
	{
        SQL_FetchString(hQuery, 0, ip, 20);
        IPStartArray[BansCount] = ip2long(ip);
        SQL_FetchString(hQuery, 1, ip, 20);
        IPEndArray[BansCount] = ip2long(ip);
        SQL_FetchString(hQuery, 2, KickReason[BansCount], 128);
        BansCount++;
    }
    }
    if (GetConVarBool(g_useWhiteListIP)) {
    Format(sql, sizeof(sql), "SELECT ip FROM %s_white_list_ip", sm_iprangeban_mysql_prefix);
    hQuery = SQL_Query(db, sql);
    if (hQuery == INVALID_HANDLE) {
        LogError("Query failed! %s", sql);
    } else {
    while (SQL_FetchRow(hQuery))
	{
        SQL_FetchString(hQuery, 0, WhiteIP[WhiteIPCount], 20);
        WhiteIPCount++;
    }
    }

    }
    if (GetConVarBool(g_useWhiteListSteamID)) {
    Format(sql, sizeof(sql), "SELECT steam FROM %s_white_list_id", sm_iprangeban_mysql_prefix);
    hQuery = SQL_Query(db, sql);
    if (hQuery == INVALID_HANDLE) {
        LogError("Query failed! %s", sql);
    } else {
    while (SQL_FetchRow(hQuery))
	{
        SQL_FetchString(hQuery, 0, WhiteSteamID[WhiteIDCount], 64);
        WhiteIDCount++;
    }
    }
    }
}
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    if (!GetConVarBool(g_Enabled))
    {
        return true;
    }
    if (!GetConVarBool(g_useWhiteListSteamID)) {
    new String:ip[20], i;
    GetClientIP(client, ip, sizeof(ip));
    if (GetConVarBool(g_useWhiteListIP)) {
        for (i = 0; i < WhiteIPCount; i++) {
          if (StrEqual(ip,WhiteIP[i])) return true;
        }
    }
    for (i = 0; i < BansCount; i++) {
        if ((ip2long(ip) >= IPStartArray[i]) && (ip2long(ip) <= IPEndArray[i])) {
                if (GetConVarBool(g_LoggingKickedPlayers)) {
                    new String:name[128],String:query[256];
                    GetClientName(client, name, sizeof(name));
                    Format(query, sizeof(query), "SELECT name FROM %s_kicked_players WHERE (name = '%s' AND time > '%i')", sm_iprangeban_mysql_prefix, name, (GetTime()-30));
                    new Handle:hQuery = SQL_Query(db, query);
                    if (hQuery == INVALID_HANDLE)
                    {
            	    	LogError("Query failed! %s", query);
                    } else if (!SQL_GetRowCount(hQuery)) {
                    Format(query, sizeof(query), "INSERT INTO %s_kicked_players (ip,name,time) VALUES ('%s','%s','%i')", sm_iprangeban_mysql_prefix, ip, name, GetTime());
                    SQL_FastQuery(db, query);
                    }
                }
                strcopy(rejectmsg, maxlen, KickReason[i]);
                return false;
        }
    }
    }
    return true;
}
public OnClientAuthorized(client, const String:auth[])
{
    if (!GetConVarBool(g_Enabled)) return true;
    new String:ip[20], String:AuthStr[32], i;
    GetClientAuthString(client, AuthStr, 32);
    GetClientIP(client, ip, sizeof(ip));
    if (GetConVarBool(g_useWhiteListIP)) {
        for (i = 0; i < WhiteIPCount; i++) {
          if (StrEqual(ip,WhiteIP[i])) return true;
        }
    }
    if (GetConVarBool(g_useWhiteListSteamID)) {
        for (i = 0; i < WhiteIDCount; i++) {
          if (StrEqual(AuthStr,WhiteSteamID[i])) return true;
        }
    }

    for (i = 0; i < BansCount; i++) {
        if ((ip2long(ip) >= IPStartArray[i]) && (ip2long(ip) <= IPEndArray[i])) {
             if (IsClientConnected(client))
             {
                if (GetConVarBool(g_LoggingKickedPlayers)) {
                    new String:name[128],String:query[256];
                    GetClientName(client, name, sizeof(name));
                    Format(query, sizeof(query), "SELECT steam FROM %s_kicked_players WHERE (steam = '%s' AND time > '%i')", sm_iprangeban_mysql_prefix, AuthStr, (GetTime()-30));
                    new Handle:hQuery = SQL_Query(db, query);
                    if (hQuery == INVALID_HANDLE)
                    {
            	    	LogError("Query failed! %s", query);
                    } else if (!SQL_GetRowCount(hQuery)) {
                        Format(query, sizeof(query), "INSERT INTO %s_kicked_players (steam,ip,name,time) VALUES ('%s','%s','%s','%i')", sm_iprangeban_mysql_prefix, AuthStr, ip, name, GetTime());
                        SQL_FastQuery(db, query);
                    }
                }
                KickClient(client, KickReason[i]);
               	return false;
             }
        }
    }
    return true;
}

public Long:ip2long(const String:ip[])
{
    decl String:iparray[4][16];
    ExplodeString(ip, ".", iparray, 4, sizeof(iparray[]));
    new long = (StringToInt(iparray[0]) * 16777216) + (StringToInt(iparray[1]) * 65536) + (StringToInt(iparray[2]) * 256) + (StringToInt(iparray[3]));
    return Long:long;
}
public OnPluginEnd()
{
    if(db != INVALID_HANDLE){
        CloseHandle(db);
    }
}
stock ConnectToMysql(){
    SQL_TConnect(OnSqlConnect,sm_iprangeban_mysql_dbconfig);
}
public OnSqlConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
	{
		LogError("Database connect failure: %s", error);
		LogError("plugins/ip_range_ban_mysql.smx was unloaded");
 		ServerCommand("sm plugins unload ip_range_ban_mysql");
	} else {
        db = hndl;
        decl String:buffer[1024];
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `%s_ip_range` (`id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,`start` varchar(20) NOT NULL,`end` varchar(20) NOT NULL,`text_to_kick` varchar(256) NOT NULL,`comment` text NOT NULL,PRIMARY KEY (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8;", sm_iprangeban_mysql_prefix);
        SQL_FastQuery(db, buffer);
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `%s_kicked_players` (`id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,`ip` varchar(20) NOT NULL,`steam` varchar(64) NOT NULL,`name` varchar(128) NOT NULL,`time` int(10) NOT NULL,PRIMARY KEY (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8;", sm_iprangeban_mysql_prefix);
        SQL_FastQuery(db, buffer);
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `%s_white_list_id` (`steam` varchar(64) NOT NULL,PRIMARY KEY (`steam`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;", sm_iprangeban_mysql_prefix);
        SQL_FastQuery(db, buffer);
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `%s_white_list_ip` (`ip` varchar(20) NOT NULL,PRIMARY KEY (`ip`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;", sm_iprangeban_mysql_prefix);
        SQL_FastQuery(db, buffer);
     	FormatEx(buffer, sizeof(buffer), "SET NAMES \"UTF8\"");
        SQL_Query(db, buffer);
        MysqlStart();
	}
}
