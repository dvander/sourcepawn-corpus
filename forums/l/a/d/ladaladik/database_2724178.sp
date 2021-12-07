#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>


#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};
int iValue[MAXPLAYERS + 1];
Database g_Database = null;

public void OnPluginStart()
{
	Database.Connect(Connect_Database, "Laff_DEV");
	RegConsoleCmd("sm_trydb", command_try);
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("L_SetClientValue", Native_SetValue);
	CreateNative("L_GetClientValue", Native_GetValue);
	return APLRes_Success;
}
public void OnClientDisconnect(int client)
{
	char steamid[32];
	char query[256];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	FormatEx(query, sizeof(query), "INSERT INTO Laff_DEV (value, steam64) VALUES ('%i', '%s') ON DUPLICATE KEY UPDATE value =  '%i'", iValue[client], steamid, iValue[client]);
	g_Database.Query(DB_DoQuery, query, GetClientUserId(client));
	iValue[client] = 0;
}
public Action command_try(int client, int args)
{
	char query[256];
	FormatEx(query, sizeof(query), "SELECT * FROM Laff_DEV");
	g_Database.Query(DB_PrintValues, query, 0);
}
public void DB_PrintValues(Database db, DBResultSet results, const char[] error, int data)
{
	char steamid[32]; int value;
	while (results.FetchRow())
	{
		value = results.FetchInt(0);
		results.FetchString(1, steamid, sizeof(steamid));
		PrintToChatAll("player %s, value %i", steamid, value);
	}
}
public void DB_DoQuery(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null || results == null)
	{
		LogError("DB_DEV returned error: %s", error);
		return;
	}
}
public void OnClientAuthorized(int client)
{
	if (!IsFakeClient(client))
	{
		char query[256], steamid[32];
		GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
		FormatEx(query, sizeof(query), "SELECT * FROM Laff_DEV WHERE steam64 = '%s'", steamid);
		g_Database.Query(DB_LoadValues, query, GetClientUserId(client));
	}
}

public void DB_LoadValues(Database db, DBResultSet results, const char[] error, int data)
{
	//If either are broken:
	if (db == null || results == null)
	{
		LogError("DB_DEV returned error: %s", error);
		return;
	}
	int client = GetClientOfUserId(data);
	if (results.FetchRow())
	{
		iValue[client] = results.FetchInt(0);
	} else {
		char steamid[32]; GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
		char query[256]; Format(query, sizeof(query), "INSERT INTO Laff_DEV (value, steam64) VALUES ('%i', '%s') ON DUPLICATE KEY UPDATE steam64 = '%s';",iValue[client], steamid, steamid);
		db.Query(DB_DoQuery, query);
	}
}
public void Connect_Database(Database db, const char[] error, int data)
{
	char query[256];
	if (db == null)
	{
		PrintToServer("[DATABASE DEV] invalid database handle");
		return;
	}
	g_Database = db;
	PrintToServer("[DATABASE DEV] SUCESFULLY CONNECTED TO DATABASE");
	Format(query, sizeof(query), 
		"CREATE TABLE IF NOT EXISTS `Laff_DEV` (`value` INT NOT NULL DEFAULT 0,`steam64` VARCHAR(18) NOT NULL,PRIMARY KEY(`steam64`)) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
		);
	
	g_Database.Query(DB_CreateTable, query, 12);
}
public void DB_CreateTable(Database db, DBResultSet results, const char[] error, int data)
{
	//If either are broken:
	if (db == null || results == null)
	{
		SetFailState("DB_DEV returned error: %s", error);
		return;
	} else {
		PrintToServer("[DATABASE DEV] SUCESFULLY CREATED TABLE!");
	}
}
public int Native_GetValue(Handle plugin, int NumParams)
{
	return iValue[GetNativeCell(1)];
}

public int Native_SetValue(Handle plugin, int NumParams)
{
	iValue[GetNativeCell(1)] = GetNativeCell(2);
}

