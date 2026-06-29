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
int iClientLevel[MAXPLAYERS + 1];
Database g_Database = null;

public void OnPluginStart()
{
	Database.Connect(Connect_Database, "Laff_DEV");
	RegConsoleCmd("sm_topclickers", command_top);
}
public Action command_top(int client, int value)
{
	char query[254];
	FormatEx(query, sizeof(query), "SELECT value, level, name FROM Laff_DEV ORDER BY level DESC LIMIT 10");
	g_Database.Query(DB_ShowMenu, query, GetClientUserId(client));
}

public void DB_ShowMenu(Database db, DBResultSet results, const char[] error, int data)
{
	char temp[128];
	char steam64[32];
	if (db == null || results == null)
	{
		LogError("DB_DEV returned error: %s", error);
		return;
	}
	int client = GetClientOfUserId(data);
	Menu menu = new Menu(mMenu);
	menu.SetTitle("TOP 10 COOKIE CLICKERS");
	while (results.FetchRow())
	{
		results.FetchString(2, steam64, sizeof(steam64));
		Format(temp, sizeof(temp), "%s \n---LEVEL : %i", steam64, results.FetchInt(1));
		menu.AddItem("", temp);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}
public int mMenu(Menu menu, MenuAction mAction, int param1, int param2)
{
	if (mAction == MenuAction_End)
	{
		delete menu;
	}
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("L_SetClientValue", Native_SetValue);
	CreateNative("L_GetClientValue", Native_GetValue);
	CreateNative("L_GetClientLevel", Native_GetLevel);
	CreateNative("L_SetClientLevel", Native_SetLevel);
	return APLRes_Success;
}
public void OnClientDisconnect(int client)
{
	char steamid[32];
	char query[256];
	char name[64];
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	FormatEx(query, sizeof(query), "INSERT INTO Laff_DEV (value, level, name, steam64) VALUES ('%i','%i','%s', '%s') ON DUPLICATE KEY UPDATE value =  '%i', level = '%i'", iValue[client], iClientLevel[client], name, steamid, iValue[client], iClientLevel[client]);
	g_Database.Query(DB_DoQuery, query, GetClientUserId(client));
	iValue[client] = 0;
	iClientLevel[client] = 0;
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
	char name[32];
	//If either are broken:
	if (db == null || results == null)
	{
		LogError("DB_DEV returned error: %s", error);
		return;
	}
	int client = GetClientOfUserId(data);
	GetClientName(client, name, sizeof(name));
	if (results.FetchRow())
	{
		iValue[client] = results.FetchInt(0);
		iClientLevel[client] = results.FetchInt(1);
	} else {
		PrintToChatAll("else happened");
		char steamid[32]; GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
		char query[256]; Format(query, sizeof(query), "INSERT INTO Laff_DEV (value, level, name, steam64) VALUES ('%i', '%i', '%s', '%s') ON DUPLICATE KEY UPDATE steam64 = '%s';", iValue[client], iClientLevel[client], name, steamid, steamid);
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
		"CREATE TABLE IF NOT EXISTS `Laff_DEV` (`value` INT NOT NULL DEFAULT 0,`level` INT NOT NULL DEFAULT 0,`name` VARCHAR(32) NOT NULL,`steam64` VARCHAR(18) NOT NULL, PRIMARY KEY(`steam64`)) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
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

public int Native_GetLevel(Handle plugin, int NumParams)
{
	return iClientLevel[GetNativeCell(1)];
}

public int Native_SetLevel(Handle plugin, int NumParams)
{
	iClientLevel[GetNativeCell(1)] = GetNativeCell(2);
}

