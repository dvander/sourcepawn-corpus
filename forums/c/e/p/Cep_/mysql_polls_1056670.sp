/**
 * =============================================================================
 * Cep>|< - Russian BugTrack Group - MySQL Votes Plugin
 * MySQL polls plugin
 * Cep>|< - Russian BugTrack Group (C) 2010
 * =============================================================================
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

public Plugin:myinfo =
{
	name = "MySQL Polls",
	author = "Cep>|< - Russian BugTrack Group",
	description = "MySQL Polls",
	version = PLUGIN_VERSION,
	url = "http://www.alliedmods.net/"
};

new Handle:db = INVALID_HANDLE;
new Handle:g_Enabled = INVALID_HANDLE;
new Handle:g_Prefix = INVALID_HANDLE;
new Handle:g_ServerId = INVALID_HANDLE;
new Handle:g_DatabaseConfig = INVALID_HANDLE;
new Handle:g_CheckClientBy = INVALID_HANDLE;
new Handle:PollsTimers[MAXPLAYERS+1];

new String:sm_mysql_polls_prefix[32];
new String:sm_mysql_polls_server_id[32];
new String:sm_mysql_polls_dbconfig[32];

new client_current_poll[MAXPLAYERS+1];
new asked[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
   	g_Enabled = CreateConVar("sm_mysql_polls_enable", "1", "Enables this plugin");
   	g_Prefix = CreateConVar("sm_mysql_polls_prefix", "sm_mysql_p", "Table prefix in database");
   	g_ServerId = CreateConVar("sm_mysql_polls_server_id", "1", "Server ID");
   	g_DatabaseConfig = CreateConVar("sm_mysql_polls_dbconfig", "mysql_polls", "Name of database config in database.cfg");
   	g_CheckClientBy = CreateConVar("sm_mysql_polls_check_client_by", "0", "Checking voted client by SteamID or IP. 0 - SteamID, 1 - IP");
	CreateConVar("sm_mysql_polls_version", PLUGIN_VERSION, "MySQL Polls version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "mysql_polls");
    }
public OnConfigsExecuted()
{
	GetConVarString(g_Prefix, sm_mysql_polls_prefix, 32);
	GetConVarString(g_ServerId, sm_mysql_polls_server_id, 32);
	GetConVarString(g_DatabaseConfig, sm_mysql_polls_dbconfig, 32);
        if(db == INVALID_HANDLE) ConnectToMysql();
}
public OnPluginEnd()
{
    if(db != INVALID_HANDLE){
        CloseHandle(db);
    }
}
stock ConnectToMysql(){
    if(!GetConVarBool(g_Enabled))
	{
        return;
    }
    SQL_TConnect(OnSqlConnect,sm_mysql_polls_dbconfig);
}
public Action:CheckClient(Handle:timer, any:client)
{   PollsTimers[client] = INVALID_HANDLE;
    decl String:AuthStr[32];
    if(!IsClientInGame(client)) return;
    if(IsFakeClient(client)) return;
    if(!GetClientAuthString(client, AuthStr, 32)) return;
    new String:buffer[256],String:query[256],String:ip[30];
    GetClientIP(client, ip, sizeof(ip));
    Format(query, sizeof(query), "SELECT id FROM %s_polls WHERE stat = 1 AND server_id='%s' ORDER BY time ASC", sm_mysql_polls_prefix, sm_mysql_polls_server_id);
    new Handle:hQuery = SQL_Query(db, query);
    if (hQuery == INVALID_HANDLE) return;
    while (SQL_FetchRow(hQuery)) {
        client_current_poll[client] = SQL_FetchInt(hQuery, 0);
        if (!GetConVarBool(g_CheckClientBy)) {
            Format(buffer, sizeof(buffer), "SELECT steam FROM %s_votes WHERE (poll_id = '%i' AND steam = '%s')", sm_mysql_polls_prefix, client_current_poll[client], AuthStr);
        }else{
            Format(buffer, sizeof(buffer), "SELECT steam FROM %s_votes WHERE (poll_id = '%i' AND ip = '%s')", sm_mysql_polls_prefix, client_current_poll[client], ip);
        }
        new Handle:hQuery2 = SQL_Query(db, buffer);
        if (hQuery2 == INVALID_HANDLE)
        {
	    	LogError("Query failed! %s", buffer);
        } else if (!SQL_GetRowCount(hQuery2)) {
            CloseHandle(hQuery2);
            Menu_Vote(client);
            break;
        }
    }
    CloseHandle(hQuery);
    return;
}
public OnClientPutInServer(client)
{
	asked[client] = 0;
}
public OnClientDisconnect(client)
{
	if(!GetConVarBool(g_Enabled))
	{
		return true;
	}
	if (PollsTimers[client] != INVALID_HANDLE)
	{
		KillTimer(PollsTimers[client]);
		PollsTimers[client] = INVALID_HANDLE;
	} return true;
}
public VoteMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
        decl String:AuthStr[32];
        if(!IsClientInGame(client)) return;
        if(IsFakeClient(client)) return;
        if(!GetClientAuthString(client, AuthStr, 32)) return;
        new String:info[32],String:name[128],String:nameb[128],String:ip[30],String:query[256];
        GetClientIP(client, ip, sizeof(ip));
        GetClientName(client, name, sizeof(name));
        GetMenuItem(menu, param2, info, sizeof(info));
	if(strcmp(info, "-1") != 0){
            SQL_EscapeString(db, name, nameb, sizeof(nameb));
            Format(query, sizeof(query), "INSERT INTO %s_votes (poll_id,variant,steam,ip,name,time) VALUES ('%i','%s','%s','%s','%s','%i')", sm_mysql_polls_prefix, client_current_poll[client], info, AuthStr, ip, nameb, GetTime());
            SQL_FastQuery(db, query);
	}
    }
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action:Menu_Vote(client)
{
    new Handle:menu = CreateMenu(VoteMenuHandler);
    decl String:query[512];
    Format(query, sizeof(query), "SELECT title FROM %s_polls WHERE id = '%i'", sm_mysql_polls_prefix, client_current_poll[client]);
    new Handle:hQuery = SQL_Query(db, query);
    if (hQuery == INVALID_HANDLE) {
        LogError("Query failed! %s", query);
    } else {
    new String:sql[512];
    new String:name[128];
    new String:id[8];
    SQL_FetchRow(hQuery);
    SQL_FetchString(hQuery, 0, name, sizeof(name));
    SetMenuTitle(menu, name);
    Format(sql, sizeof(sql), "SELECT id, name FROM %s_variants WHERE poll_id = '%i' ORDER BY id", sm_mysql_polls_prefix, client_current_poll[client]);
    new Handle:hQuery2 = SQL_Query(db, sql);
    if (hQuery2 == INVALID_HANDLE) {
        LogError("Query failed! %s", sql);
    } else {
    AddMenuItem(menu, "-1", "Ask Me Later");
    while (SQL_FetchRow(hQuery2))
	{
        SQL_FetchString(hQuery2, 0, id, sizeof(id));
        SQL_FetchString(hQuery2, 1, name, sizeof(name));
       	AddMenuItem(menu, id, name);
    }   SetMenuExitButton(menu, false);
    CloseHandle(hQuery);
    CloseHandle(hQuery2);
    DisplayMenu(menu,client,50);
    }
    }   return Plugin_Handled;
}
public OnSqlConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
	{
		LogError("Database connect failure %s", error);
	} else {
        db = hndl;
        decl String:buffer[1024];
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `%s_polls` (`id` int(11) NOT NULL AUTO_INCREMENT,`name` varchar(128) NOT NULL,`title` varchar(128) NOT NULL,`time`  int(11) NOT NULL,`stat` int(1) NOT NULL,`server_id` varchar(32) NOT NULL,PRIMARY KEY (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8;", sm_mysql_polls_prefix);
        SQL_FastQuery(db, buffer);
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `%s_variants` (`id` int(11) NOT NULL AUTO_INCREMENT,`poll_id` int(11) NOT NULL,`name` varchar(128) NOT NULL,PRIMARY KEY (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8;", sm_mysql_polls_prefix);
        SQL_FastQuery(db, buffer);
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `%s_votes` (`id` int(11) NOT NULL AUTO_INCREMENT,`poll_id` int(11) NOT NULL,`time` int(11) NOT NULL,`variant` int(11) NOT NULL,`steam` varchar(32) NOT NULL,`ip` varchar(15) NOT NULL,`name` varchar(128) NOT NULL,PRIMARY KEY (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8;", sm_mysql_polls_prefix);
        SQL_FastQuery(db, buffer);
    	FormatEx(buffer, sizeof(buffer), "SET NAMES \"UTF8\"");
        SQL_Query(db, buffer);
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new ff = GetConVarInt(FindConVar("mp_friendlyfire"));
	if(ff == 1) return true;
	new client = GetClientOfUserId(victimId);
	if(!GetConVarBool(g_Enabled))
	{
		return true;
	} if(IsFakeClient(client)) return true;
	if(asked[client] < 2){
        	PollsTimers[client] = CreateTimer(3.0, CheckClient, client);
		asked[client]++;
	}
        return true;
}