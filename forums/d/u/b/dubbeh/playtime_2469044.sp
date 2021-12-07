#pragma semicolon 1

//#define DEBUG

#define PLUGIN_VERSION 		"1.00"
#define MAX_AUTH_ID_SIZE 	64

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Playtime Tracker", 
	author = "dubbeh", 
	description = "Tracks a clients play time info on the current server or multiple if sharing the same database.", 
	version = PLUGIN_VERSION, 
	url = "https://dubbeh.net"
};

ConVar g_cVarEnable = null;
int g_iConnectTime[MAXPLAYERS + 1];
int g_iDatabasePlayTime[MAXPLAYERS + 1];
int g_iSteamIDs[MAXPLAYERS + 1];
Database g_hDB = null;

public void OnPluginStart()
{
	int iIndex = 0;
	
	CreateConVar("playtime_version", PLUGIN_VERSION, "Playtime Tracker version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cVarEnable = CreateConVar("playtime_tracker_enable", "1.0", "Enable Playtime Tracker", 0, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_playtime", Command_PlayTime, "Get the current playtime on the server");
	RegConsoleCmd("sm_pttop", Command_PlayTimeTop, "Get the top 10 players with the most playtime on the server");
	
	if (g_cVarEnable == null) {
		SetFailState("[Playtime Tracker] Error: Problem creating a console variable.");
	}
	
	for (iIndex = 0; iIndex <= MAXPLAYERS; iIndex++) {
		g_iConnectTime[iIndex] = 0;
		g_iDatabasePlayTime[iIndex] = 0;
		g_iSteamIDs[iIndex] = 0;
	}
}

public void OnMapStart()
{
	char szError[255];
	
	g_hDB = SQL_DefConnect(szError, sizeof(szError), true);
	
	if (g_hDB == null)
	{
		LogMessage("[Playtime Tracker] No MySQL database found.");
		LogMessage("[Playtime Tracker] Using SQLite for storage.");
		g_hDB = SQLite_UseDatabase("sourcemod-local", szError, sizeof(szError));
	} else {
		LogMessage("[Playtime Tracker] MySQL database found.");
	}
	
	if (g_hDB == null) {
		SetFailState("[Playtime Tracker] Error: Could not connect to any database system: %s", szError);
	} else {
		SQL_LockDatabase(g_hDB);
		SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS playtime_tracker (steam_id BIGINT, name VARCHAR(65) NOT NULL, playtime BIGINT, PRIMARY KEY (steam_id))");
		SQL_UnlockDatabase(g_hDB);
	}
}

public void OnMapEnd()
{
	CloseHandle(g_hDB);
}

public void OnClientAuthorized(int iClient, const char[] szAuth)
{
	char szQuery[256] = "";
	
	if (iClient && !IsFakeClient(iClient)) {
		g_iConnectTime[iClient] = GetTime();
		g_iSteamIDs[iClient] = SteamIDToInt(szAuth);
		Format(szQuery, sizeof(szQuery), "SELECT playtime FROM playtime_tracker WHERE steam_id='%d'", g_iSteamIDs[iClient]);
		SQL_TQuery(g_hDB, SelectPlaytime_Callback, szQuery, GetClientSerial(iClient), DBPrio_High);
	}
}

public void SelectPlaytime_Callback(Handle hDb, Handle hQuery, const char[] szError, any iClientSerial)
{
	int iClient = 0;
	char szClientName[MAX_NAME_LENGTH + 1] = "";
	char szEscapedName[MAX_NAME_LENGTH + 1] = "";
	char szQuery[512];
	
	if (hDb != INVALID_HANDLE && hQuery != INVALID_HANDLE && !strlen(szError)) {
		iClient = GetClientFromSerial(iClientSerial);
		
		if (iClient > 0 && IsClientConnected(iClient))
		{
			GetClientName(iClient, szClientName, sizeof(szClientName));
			
			if (SQL_FetchRow(hQuery))
			{
				g_iDatabasePlayTime[iClient] = SQL_FetchInt(hQuery, 0);
				
				if (SQL_EscapeString(g_hDB, szClientName, szEscapedName, sizeof(szEscapedName)))
				{
					Format(szQuery, sizeof(szQuery), "UPDATE playtime_tracker SET name='%s' WHERE steam_id='%d'", szEscapedName, g_iSteamIDs[iClient]);
					SQL_TQuery(g_hDB, ErrorCheck_CallBack, szQuery);
				}
			} else {
				if (SQL_EscapeString(g_hDB, szClientName, szEscapedName, sizeof(szEscapedName)))
				{
					g_iDatabasePlayTime[iClient] = 0;
					
					Format(szQuery, sizeof(szQuery), "INSERT INTO playtime_tracker ('steam_id','name','playtime') VALUES ('%d','%s','0')", g_iSteamIDs[iClient], szEscapedName);
					SQL_TQuery(g_hDB, ErrorCheck_CallBack, szQuery);
				}
			}
		} else {
			LogMessage("[Playtime Tracker] Error: Client appears to have disconnected before the SQL callback finished.");
		}
	} else {
		LogMessage("[Playtime Tracker] Error: Database or query returned an invalid handle inside SelectPlaytime_Callback.");
	}
}

public void ErrorCheck_CallBack(Handle hDb, Handle hQuery, const char[] szError, any data)
{
	if (hDb == INVALID_HANDLE || hQuery == INVALID_HANDLE || strlen(szError) > 0) {
		LogError(szError);
		SetFailState(szError);
	}
}

public void OnClientDisconnect(int iClient)
{
	char szQuery[512] = "";
	
	if (iClient && !IsFakeClient(iClient)) {
		Format(szQuery, sizeof(szQuery), "UPDATE playtime_tracker SET playtime='%d' WHERE steam_id='%d'", g_iDatabasePlayTime[iClient] + (GetTime() - g_iConnectTime[iClient]), g_iSteamIDs[iClient]);
		SQL_TQuery(g_hDB, ErrorCheck_CallBack, szQuery);
		
		g_iSteamIDs[iClient] = 0;
		g_iDatabasePlayTime[iClient] = 0;
		g_iConnectTime[iClient] = 0;
	}
}

int SteamIDToInt(const char[] szSteamID)
{
	char szBuffer[128] = "";
	
	strcopy(szBuffer, sizeof(szBuffer), szSteamID);
	ReplaceString(szBuffer, sizeof(szBuffer), "STEAM", "", false);
	ReplaceString(szBuffer, sizeof(szBuffer), "_", "", false);
	ReplaceString(szBuffer, sizeof(szBuffer), ":", "", false);
	ReplaceString(szBuffer, sizeof(szBuffer), "'", "", false);
	ReplaceString(szBuffer, sizeof(szBuffer), "\"", "", false);
	ReplaceString(szBuffer, sizeof(szBuffer), "+", "", false);
	ReplaceString(szBuffer, sizeof(szBuffer), "-", "", false);
	return StringToInt(szBuffer);
}

public Action Command_PlayTime(int iClient, int iArgs)
{
	if (iClient > 0 && !IsFakeClient(iClient))
	{
		ShowPlayTime(iClient);
	}
}

void ShowPlayTime(int iClient)
{
	char szBuffer[256] = "";
	int iPlayTime;
	int iHours = 0;
	int iMinutes = 0;
	int iSeconds = 0;
	
	iPlayTime = g_iDatabasePlayTime[iClient] + (GetTime() - g_iConnectTime[iClient]);
	
	if (iPlayTime >= 3600) {
		iHours = iPlayTime / 3600;
		iMinutes = (iPlayTime % 3600) / 60;
		iSeconds = iMinutes % 60;
	} else if (iPlayTime >= 60) {
		iHours = 0;
		iMinutes = iPlayTime / 60;
		iSeconds = iPlayTime % 60;
	} else {
		iHours = 0;
		iMinutes = 0;
		iSeconds = iPlayTime;
	}
	
	Format(szBuffer, sizeof(szBuffer), "You've played on this server for:\n\t Hours:%d Minutes:%d Seconds:%d", iHours, iMinutes, iSeconds);
	ReplyToCommand(iClient, szBuffer);
}

public Action Command_PlayTimeTop(int iClient, int iArgs)
{
	if (iClient > 0 && !IsFakeClient(iClient))
	{
		SQL_TQuery(g_hDB, TopTenPlaytime_Callback, "SELECT name,playtime FROM playtime_tracker ORDER BY playtime DESC LIMIT 10", GetClientSerial(iClient));
	}
}

public void TopTenPlaytime_Callback(Handle hDb, Handle hQuery, const char[] szError, any iClientSerial)
{
	int iClient = 0;
	int iPlayTime = 0;
	int iPlacement = 0;
	int iHours = 0;
	int iMinutes = 0;
	int iSeconds = 0;
	
	char szName[MAX_NAME_LENGTH + 1] = "";
	
	if (hDb != INVALID_HANDLE && hQuery != INVALID_HANDLE && !strlen(szError)) {
		iClient = GetClientFromSerial(iClientSerial);
		if (iClient > 0 && IsClientConnected(iClient)) {
			iPlacement = 1;
			PrintToChat(iClient, "Listing players with the top 10 play time on the server:");
			while (SQL_FetchRow(hQuery)) {
				if (SQL_FetchString(hQuery, 0, szName, sizeof(szName)) > 0 && (iPlayTime = SQL_FetchInt(hQuery, 1)) > 0) {
					if (iPlayTime >= 3600) {
						iHours = iPlayTime / 3600;
						iMinutes = (iPlayTime % 3600) / 60;
						iSeconds = iMinutes % 60;
					} else if (iPlayTime >= 60) {
						iHours = 0;
						iMinutes = iPlayTime / 60;
						iSeconds = iPlayTime % 60;
					} else {
						iHours = 0;
						iMinutes = 0;
						iSeconds = iPlayTime;
					}
					
					PrintToChat(iClient, "%d: %s -  Hours:%d Minutes:%d Seconds:%d", iPlacement, szName, iHours, iMinutes, iSeconds);
				} else {
					PrintToChat(iClient, "[Playtime Tracker] Error: Unable to get top 10 players from the database.");
				}
				
				iPlacement++;
			}
		}
	} else {
		LogError(szError);
		SetFailState(szError);
	}
}
