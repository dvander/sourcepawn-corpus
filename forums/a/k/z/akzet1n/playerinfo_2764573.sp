#include <sourcemod>
#include <geoip>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvTableName;
ConVar g_cvUpdateNames;
Database g_dbDatabase = null;

char table[32];
bool update;

public Plugin myinfo =
{
    name = "Player Info Database",
    author = "akz",
    description = "Saves some information of each player into a database.",
    version = "2.1",
    url = "https://github.com/akzet1n/playerinfo-database"
};

public void OnPluginStart()
{
    g_cvTableName = CreateConVar("sm_playerinfo_table", "data", "Name of the table where the SQL queries will be executed");
    g_cvUpdateNames = CreateConVar("sm_playerinfo_update", "1", "Update the player name on every connect or keep the name of his first join");
    Database.Connect(ConnectToDb, "playerinfo");
    AutoExecConfig(true, "playerinfo");
}

public void ConnectToDb(Database db, const char[] failure, any data)
{
    if (db == null)
    {
        SetFailState("Failed to connect to database: %s", failure);
    }
    else
    {
        LogMessage("Connection to database succesfully");
        g_dbDatabase = db;
        SQL_SetCharset(db, "UTF8");
        char query[512];
        g_cvTableName.GetString(table, sizeof(table));  
        Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (name varchar(%i) NOT NULL, steamid varchar(32) NOT NULL, address varchar(16) NOT NULL, country varchar(2) NOT NULL, first_join datetime NOT NULL, last_seen datetime NOT NULL, connections int NOT NULL DEFAULT 0, time int NOT NULL DEFAULT 0, CONSTRAINT pk PRIMARY KEY (steamid, address))", table, MAX_NAME_LENGTH);
        if (!SQL_FastQuery(g_dbDatabase, query))
        {
            char error[256];
            SQL_GetError(g_dbDatabase, error, sizeof(error));
            SetFailState("Failed to create table: %s", error);
        }
    }
}

public void OnClientAuthorized(int client)
{
    if (!IsFakeClient(client) && g_dbDatabase != null)
    {
        char name[MAX_NAME_LENGTH], steamid[32], address[16], country[3];
        GetClientName(client, name, sizeof(name));
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
        GetClientIP(client, address, sizeof(address));
        GeoipCode2(address, country);
        QuerySql(name, steamid, address, country, 0, 1);
    }
}

public void QuerySql(char[] name, char[] steamid, char[] address, char[] country, int seconds, int option)
{
    char query[256];
    if (option)
    {
        Format(query, sizeof(query), "INSERT INTO %s (name, steamid, address, country, first_join) VALUES ('%s', '%s', '%s', '%s', NOW()) ON DUPLICATE KEY UPDATE steamid = '%s'", table, name, steamid, address, country, steamid);
    }
    else
    {
        update = g_cvUpdateNames.BoolValue;
        if (update)
        {
            Format(query, sizeof(query), "UPDATE %s SET name = '%s', last_seen = NOW(), connections = connections + 1, time = time + %i WHERE steamid = '%s' AND address = '%s'", table, name, seconds, steamid, address);
        }
        else
        {
            Format(query, sizeof(query), "UPDATE %s SET last_seen = NOW(), connections = connections + 1, time = time + %i WHERE steamid = '%s' AND address = '%s'", table, seconds, steamid, address);
        }
    }
    if (!SQL_FastQuery(g_dbDatabase, query))
    {
        char error[256];
        SQL_GetError(g_dbDatabase, error, sizeof(error));
        LogError("Query failed: %s", error);
    }
}

public void OnClientDisconnect(int client)
{
    if (!IsFakeClient(client) && g_dbDatabase != null)
    {   
        char name[MAX_NAME_LENGTH], steamid[32], address[16];
        GetClientName(client, name, sizeof(name));
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
        GetClientIP(client, address, sizeof(address));
        QuerySql(name, steamid, address, "", RoundToNearest(GetClientTime(client)), 0);
    }
}
