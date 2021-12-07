/*  SM Most Active
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 *  Contributor: shanapu
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <mostactive>

#define IDAYS 26

#define VERSION "2.6"

int g_iPlayTimeSpec[MAXPLAYERS+1] = 0;
int g_iPlayTimeT[MAXPLAYERS+1] = 0;
int g_iPlayTimeCT[MAXPLAYERS+1] = 0;

bool g_bChecked[MAXPLAYERS + 1];

char g_sCmdLogPath[256];
char g_sSQLBuffer[3096];

bool g_bIsMySQl;

// DB handle
Handle g_hDB = INVALID_HANDLE;
Handle gF_OnInsertNewPlayer;

int g_iHours;
int g_iMinutes;
int g_iSeconds;

public Plugin myinfo = {
	name = "SM Most Active",
	author = "Franc1sco Steam: franug / shanapu",
	description = "A rank based in time played",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	CreateNative("MostActive_GetPlayTimeCT", Native_GetPlayTimeCT);
	CreateNative("MostActive_GetPlayTimeT", Native_GetPlayTimeT);
	CreateNative("MostActive_GetPlayTimeSpec", Native_GetPlayTimeSpec);
	CreateNative("MostActive_GetPlayTimeTotal", Native_GetPlayTimeTotal);

	gF_OnInsertNewPlayer = CreateGlobalForward("MostActive_OnInsertNewPlayer", ET_Event, Param_Cell);

	RegPluginLibrary("mostactive");

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_mostactive_version", VERSION, "version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_active", DOMenu);
	RegConsoleCmd("sm_wasted", Command_Wasted);
	
	for(int i=0;;i++)
	{
		BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), "logs/mostactive_%d.log", i);
		if( !FileExists(g_sCmdLogPath) )
			break;
	}
	
	SQL_TConnect(OnSQLConnect, "mostactive");
}

public int OnSQLConnect(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
		
		SetFailState("Databases dont work");
	}
	else
	{
		g_hDB = hndl;
		
		SQL_SetCharset(g_hDB, "utf8mb4");
		SQL_GetDriverIdent(SQL_ReadDriver(g_hDB), g_sSQLBuffer, sizeof(g_sSQLBuffer));
		g_bIsMySQl = StrEqual(g_sSQLBuffer,"mysql", false) ? true : false;
		
		if(g_bIsMySQl)
		{
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS `mostactive` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) PRIMARY KEY NOT NULL,`last_accountuse` int(64) NOT NULL, `timeCT` INT( 16 ), `timeTT` INT( 16 ),`timeSPE` INT( 16 ), `total` INT( 16 ))");
			
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
			LogToFileEx(g_sCmdLogPath, "Query %s", g_sSQLBuffer);
		}
		else
		{
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS mostactive (playername varchar(128) NOT NULL, steamid varchar(32) PRIMARY KEY NOT NULL,last_accountuse int(64) NOT NULL, timeCT INTEGER, timeTT INTEGER, timeSPE INTEGER, total INTEGER)");
			
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
			LogToFileEx(g_sCmdLogPath, "Query %s", g_sSQLBuffer);
		}
		PruneDatabase();
	}
}

public int OnSQLConnectCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

public void InsertSQLNewPlayer(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid));
	int userid = GetClientUserId(client);
	
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}
	
	Format(query, sizeof(query), "INSERT INTO mostactive(playername, steamid, last_accountuse, timeCT, timeTT, timeSPE, total) VALUES('%s', '%s', '%d', '0', '0', '0', '0');", SafeName, steamid, GetTime());
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, query, userid);
	LogToFileEx(g_sCmdLogPath, "Query %s", query);
	g_iPlayTimeCT[client] = 0;
	g_iPlayTimeT[client] = 0;
	g_iPlayTimeSpec[client] = 0;
	
	Call_StartForward(gF_OnInsertNewPlayer);
	Call_PushCell(client);
	Call_Finish();
	
	g_bChecked[client] = true;
}

public int Native_GetPlayTimeCT(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	
	return g_iPlayTimeCT[client];
}

public int Native_GetPlayTimeT(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	
	return g_iPlayTimeT[client];
}

public int Native_GetPlayTimeSpec(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	
	return g_iPlayTimeSpec[client];
}

public int Native_GetPlayTimeTotal(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	
	return g_iPlayTimeSpec[client]+g_iPlayTimeCT[client]+g_iPlayTimeT[client];
}

public int SaveSQLPlayerCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
	}
}

public void CheckSQLSteamID(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid) );
	
	Format(query, sizeof(query), "SELECT timeCT, timeTT, timeSPE FROM mostactive WHERE steamid = '%s'", steamid);
	SQL_TQuery(g_hDB, CheckSQLSteamIDCallback, query, GetClientUserId(client));
	LogToFileEx(g_sCmdLogPath, "Query %s", query);
}

public int CheckSQLSteamIDCallback(Handle owner, Handle hndl, char [] error, any data)
{
	int client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		InsertSQLNewPlayer(client);
		return;
	}
	
	g_iPlayTimeCT[client] = SQL_FetchInt(hndl, 0);
	g_iPlayTimeT[client] = SQL_FetchInt(hndl, 1);
	g_iPlayTimeSpec[client] = SQL_FetchInt(hndl, 2);
	g_bChecked[client] = true;
}

public void SaveSQLCookies(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid) );
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}	

	char buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE mostactive SET last_accountuse = %d, playername = '%s',timeCT = '%i',timeTT = '%i', timeSPE = '%i',total = '%i' WHERE steamid = '%s';",GetTime(), SafeName, g_iPlayTimeCT[client],g_iPlayTimeT[client],g_iPlayTimeSpec[client],g_iPlayTimeCT[client]+g_iPlayTimeT[client]+g_iPlayTimeSpec[client], steamid);
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, buffer);
	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	g_bChecked[client] = false;
}

public void OnPluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client) && g_bChecked[client]) SaveSQLCookies(client);
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client)) CheckSQLSteamID(client);
}

public void PruneDatabase()
{
	if(g_hDB == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Prune Database: No connection");
		return;
	}

	int maxlastaccuse;
	maxlastaccuse = GetTime() - (IDAYS * 86400);

	char buffer[1024];

	if(g_bIsMySQl)
		Format(buffer, sizeof(buffer), "DELETE FROM `mostactive` WHERE `last_accountuse`<'%d' AND `last_accountuse`>'0';", maxlastaccuse);
	else
		Format(buffer, sizeof(buffer), "DELETE FROM mostactive WHERE last_accountuse<'%d' AND last_accountuse>'0';", maxlastaccuse);

	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	SQL_TQuery(g_hDB, PruneDatabaseCallback, buffer);
}

public int PruneDatabaseCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
	}
	//LogMessage("Prune Database successful");
}

public void OnMapStart()
{
	CreateTimer(1.0, PlayTimeTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action PlayTimeTimer(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i))
		{
			int team = GetClientTeam(i);
			
			if(team == 2)
			{
				++g_iPlayTimeT[i];
			}
			else if(team == 3)
			{
				++g_iPlayTimeCT[i];
			}
			else
			{
				++g_iPlayTimeSpec[i];
			}
		}
	}
}

public void ShowTotal(int client)
{
	if(g_hDB != INVALID_HANDLE)
	{
		char buffer[200];
		Format(buffer, sizeof(buffer), "SELECT playername, total, steamid FROM mostactive ORDER BY total DESC LIMIT 999");
		SQL_TQuery(g_hDB, ShowTotalCallback, buffer, client);
	}
	else
	{
		PrintToChat(client, " \x03Rank System is now not avilable");
	}
}

public int ShowTotalCallback(Handle owner, Handle hndl, char [] error, any client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
	
	Menu menu2 = CreateMenu(DIDMenuHandler2);
	menu2.SetTitle("Top Total played");
	
	int order = 0;
	char number[64];
	char name[64];
	char textbuffer[128];
	char steamid[128];
	
	if(SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			order++;
			Format(number,64, "option%i", order);
			SQL_FetchString(hndl, 0, name, sizeof(name));
			SQL_FetchString(hndl, 2, steamid, sizeof(steamid));
			g_iHours = 0;
			g_iMinutes = 0;
			g_iSeconds = 0;
			ShowTimer2(SQL_FetchInt(hndl, 1));
			Format(textbuffer,128, "n%i %s - %d h. %d m. %d s.", order,name,g_iHours, g_iMinutes, g_iSeconds);
			menu2.AddItem(steamid, textbuffer);
		}
	}
	if(order < 1) 
	{
		menu2.AddItem("empty", "TOP is empty!");
	}
	
	menu2.ExitButton = true;
	menu2.ExitBackButton = true;
	menu2.Display(client,MENU_TIME_FOREVER);
}

public void ShowSpec(int client)
{
	if(g_hDB != INVALID_HANDLE)
	{
		char buffer[200];
		Format(buffer, sizeof(buffer), "SELECT playername, timeSPE, steamid FROM mostactive ORDER BY timeSPE DESC LIMIT 999");
		SQL_TQuery(g_hDB, ShowSpecCallback, buffer, client);
	}
	else
	{
		PrintToChat(client, " \x03Rank System is now not avilable");
	}
}

public void ShowSpecCallback(Handle owner, Handle hndl, char [] error, any client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
	
	Menu menu2 = CreateMenu(DIDMenuHandler2);
	menu2.SetTitle("Top Spectator");
	
	int order = 0;
	char number[64];
	char name[64];
	char textbuffer[128];
	char steamid[128];
	
	if(SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			order++;
			Format(number,64, "option%i", order);
			SQL_FetchString(hndl, 0, name, sizeof(name));
			SQL_FetchString(hndl, 2, steamid, sizeof(steamid));
			g_iHours = 0;
			g_iMinutes = 0;
			g_iSeconds = 0;
			ShowTimer2(SQL_FetchInt(hndl, 1));
			Format(textbuffer,128, "n%i %s - %d h. %d m. %d s.", order,name,g_iHours, g_iMinutes, g_iSeconds); 
			menu2.AddItem(steamid, textbuffer);
		}
	}
	if(order < 1)
	{
		menu2.AddItem("empty", "TOP is empty!");
	}
	
	menu2.ExitButton = true;
	menu2.ExitBackButton = true;
	menu2.Display(client,MENU_TIME_FOREVER);
}

public void ShowTerror(int client)
{
	if(g_hDB != INVALID_HANDLE)
	{
		char buffer[200];
		Format(buffer, sizeof(buffer), "SELECT playername, timeTT, steamid FROM mostactive ORDER BY timeTT DESC LIMIT 999");
		SQL_TQuery(g_hDB, ShowTerrorCallback, buffer, client);
	}
	else
	{
		PrintToChat(client, " \x03Rank System is now not avilable");
	}
}

public int ShowTerrorCallback(Handle owner, Handle hndl, char [] error, any client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
	
	Menu menu2 = CreateMenu(DIDMenuHandler2);
	menu2.SetTitle("Top T");
	
	int order = 0;
	char number[64];
	char name[64];
	char textbuffer[128];
	char steamid[128];
	
	if(SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			order++;
			Format(number,64, "option%i", order);
			SQL_FetchString(hndl, 0, name, sizeof(name));
			SQL_FetchString(hndl, 2, steamid, sizeof(steamid));
			g_iHours = 0;
			g_iMinutes = 0;
			g_iSeconds = 0;
			ShowTimer2(SQL_FetchInt(hndl, 1));
			Format(textbuffer,128, "n%i %s - %d h. %d m. %d s.", order,name,g_iHours, g_iMinutes, g_iSeconds);
			menu2.AddItem(steamid, textbuffer);
		}
	}
	if(order < 1)
	{
		menu2.AddItem("empty", "TOP is empty!");
	}
	
	menu2.ExitButton = true;
	menu2.ExitBackButton = true;
	menu2.Display(client,MENU_TIME_FOREVER);
}

public void ShowCT(int client)
{
	if(g_hDB != INVALID_HANDLE)
	{
		char buffer[200];
		Format(buffer, sizeof(buffer), "SELECT playername, timeCT, steamid FROM mostactive ORDER BY timeCT DESC LIMIT 999");
		SQL_TQuery(g_hDB, ShowCTCallback, buffer, client);
	}
	else
	{
		PrintToChat(client, " \x03Rank System is now not avilable");
	}
}

public int ShowCTCallback(Handle owner, Handle hndl, char [] error, any client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
	
	Menu menu2 = CreateMenu(DIDMenuHandler2);
	menu2.SetTitle("Top CT");
	
	
	int order = 0;
	char number[64];
	char name[64];
	char textbuffer[128];
	char steamid[128];
	
	if(SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			order++;
			Format(number,64, "option%i", order);
			SQL_FetchString(hndl, 0, name, sizeof(name));
			SQL_FetchString(hndl, 2, steamid, sizeof(steamid));
			g_iHours = 0;
			g_iMinutes = 0;
			g_iSeconds = 0;
			ShowTimer2(SQL_FetchInt(hndl, 1));
			Format(textbuffer,128, "n%i %s - %d h. %d m. %d s.", order,name,g_iHours, g_iMinutes, g_iSeconds); 
			menu2.AddItem(steamid, textbuffer);
		}
	}
	if(order < 1)
	{
		menu2.AddItem("empty", "TOP is empty!");
	}
	
	menu2.ExitButton = true;
	menu2.ExitBackButton = true;
	menu2.Display(client,MENU_TIME_FOREVER);
}

int ShowTimer(int Time, char[] buffer,int sizef)
{
	g_iHours = 0;
	g_iMinutes = 0;
	g_iSeconds = Time;
	
	while(g_iSeconds > 3600)
	{
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while(g_iSeconds > 60)
	{
		g_iMinutes++;
		g_iSeconds -= 60;
	}
	if(g_iHours >= 1)
	{
		Format(buffer, sizef, "%d hours %d minutes %d seconds", g_iHours, g_iMinutes, g_iSeconds );
	}
	else if(g_iMinutes >= 1)
	{
		Format(buffer, sizef, "%d minutes %d seconds", g_iMinutes, g_iSeconds );
	}
	else
	{
		Format(buffer, sizef, "%d seconds", g_iSeconds );
	}
}

void ShowTimer2(int Time)
{
	g_iHours = 0;
	g_iMinutes = 0;
	g_iSeconds = Time;
	
	while(g_iSeconds > 3600)
	{
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while(g_iSeconds > 60)
	{
		g_iMinutes++;
		g_iSeconds -= 60;
	}
}

bool GetCommunityID(char [] AuthID, char [] FriendID, int size)
{
	if(strlen(AuthID) < 11 || AuthID[0]!='S' || AuthID[6]=='I')
	{
		FriendID[0] = 0;
		return false;
	}
	int iUpper = 765611979;
	int iFriendID = StringToInt(AuthID[10])*2 + 60265728 + AuthID[8]-48;
	int iDiv = iFriendID/100000000;
	int iIdx = 9-(iDiv?iDiv/10+1:0);
	iUpper += iDiv;
	IntToString(iFriendID, FriendID[iIdx], size-iIdx);
	iIdx = FriendID[9];
	IntToString(iUpper, FriendID, size);
	FriendID[9] = iIdx;
	return true;
}

public int DIDMenuHandler2(Menu menu2, MenuAction action, int client, int itemNum) 
{
	if( action == MenuAction_Select ) 
	{
			char info[128], community[128];
		
			GetMenuItem(menu2, itemNum, info, sizeof(info));
			GetCommunityID(info, community, sizeof(community));
			
			Format(community, sizeof(community), "http://steamcommunity.com/profiles/%s", community);
			PrintToChat(client, community);
			PrintToConsole(client, community);
	}
	else if(action == MenuAction_Cancel) 
	{
		if(itemNum==MenuCancel_ExitBack)
		{
			DOMenu(client,0);
		}
		//PrintToServer("Client %d's menu was cancelled.Reason: %d", client, itemNum); 
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
}

public Action DOMenu(int client, int args)
{
	//PrintToChat(client, "number de arg %i", args);
	if(args > 0)
	{
		char steamid[64];
		GetCmdArgString(steamid, sizeof(steamid));
		//PrintToChat(client, "tengo %s", steamid);
		
		char buffer[200];
		Format(buffer, sizeof(buffer), "SELECT timeCT, timeTT, timeSPE, total, playername FROM mostactive WHERE steamid = '%s'", steamid);
		SQL_TQuery(g_hDB, SQLShowPlayTime, buffer, GetClientUserId(client));
		//LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	}
	else
	{
		Menu menu = CreateMenu(DIDMenuHandler);
		menu.SetTitle("Most Active");
		menu.AddItem("option1", "View your time");
		menu.AddItem("option2", "View Top total played");
		menu.AddItem("option4", "View Top T");
		menu.AddItem("option5", "View Top CT");
		menu.AddItem("option3", "View Top Spectator");
		menu.ExitButton = true;
		menu.Display(client,MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int SQLShowPlayTime(Handle owner, Handle hndl, char [] error, any data)
{
	int client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		PrintToChat(client, " \x03steamid not found in the database");
		return;
	}
	char name[124];
	SQL_FetchString(hndl, 4, name, 124);
	
	Menu menu = CreateMenu(DIDMenuHandlerHandler);
	menu.SetTitle("Time for the player %s", name);
	
	char buffer[124];
	
	ShowTimer(SQL_FetchInt(hndl, 2), buffer, sizeof(buffer));
	Format(buffer, 124, "Spectator: %s", buffer);
	menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	
	ShowTimer(SQL_FetchInt(hndl, 1), buffer, sizeof(buffer));
	Format(buffer, 124, "Terrorist: %s", buffer);
	menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	
	ShowTimer(SQL_FetchInt(hndl, 0), buffer, sizeof(buffer));
	Format(buffer, 124, "Counter-terrorist: %s", buffer);
	menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	
	ShowTimer(SQL_FetchInt(hndl, 3), buffer, sizeof(buffer));
	Format(buffer, 124, "Total played: %s", buffer);
	menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client,MENU_TIME_FOREVER);
}

public int DIDMenuHandler(Menu menu, MenuAction action, int client, int itemNum) 
{
	if( action == MenuAction_Select ) 
	{
		char info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if( strcmp(info,"option1") == 0 )
		{
			Menu menu2 = CreateMenu(DIDMenuHandlerHandler);
			menu2.SetTitle("Time for the player %N", client);
			
			char buffer[124];
			
			ShowTimer(g_iPlayTimeSpec[client], buffer, sizeof(buffer));
			Format(buffer, 124, "Spectator: %s", buffer);
			menu2.AddItem("", buffer, ITEMDRAW_DISABLED);
			
			ShowTimer(g_iPlayTimeT[client], buffer, sizeof(buffer));
			Format(buffer, 124, "Terrorist: %s", buffer);
			menu2.AddItem("", buffer, ITEMDRAW_DISABLED);
			
			ShowTimer(g_iPlayTimeCT[client], buffer, sizeof(buffer));
			Format(buffer, 124, "Counter-terrorist: %s", buffer);
			menu2.AddItem("", buffer, ITEMDRAW_DISABLED);
			
			int totalt = (g_iPlayTimeT[client] + g_iPlayTimeCT[client] + g_iPlayTimeSpec[client]);
			ShowTimer(totalt, buffer, sizeof(buffer));
			Format(buffer, 124, "Total played: %s", buffer);
			menu2.AddItem("", buffer, ITEMDRAW_DISABLED);
			menu2.ExitButton = true;
			menu2.ExitBackButton = true;
			menu2.Display(client,MENU_TIME_FOREVER);
			//DOMenu(client, 0);
			//DID(client);
		}
		else if( strcmp(info,"option2") == 0 ) 
		{
			ShowTotal(client);
			//DID(client);
		}
		else if( strcmp(info,"option3") == 0 ) 
		{
			ShowSpec(client);
			//DID(client);
		}
		else if( strcmp(info,"option4") == 0 ) 
		{
			ShowTerror(client);
			//DID(client);
		}
		else if( strcmp(info,"option5") == 0 ) 
		{
			ShowCT(client);
			//DID(client);
		}
	}
	if(action == MenuAction_Cancel)
	{
		if(itemNum==MenuCancel_ExitBack)
		{
			DOMenu(client,0);
		}
		//PrintToServer("Client %d's menu was cancelled.Reason: %d", client, itemNum); 
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int DIDMenuHandlerHandler(Menu menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Cancel) 
	{
		if(itemNum==MenuCancel_ExitBack)
		{
			DOMenu(client,0);
		}
		//PrintToServer("Client %d's menu was cancelled.Reason: %d", client, itemNum); 
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Command_Wasted(int client, int args)
{
	SQL_TQuery(g_hDB, SQLShowWasteTime, "SELECT sum(total) FROM mostactive");

	return Plugin_Handled;
}

public int SQLShowWasteTime(Handle owner, Handle hndl, char [] error, any client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
	{
		char buffer[124];
		ShowTimer(SQL_FetchInt(hndl, 0), buffer, sizeof(buffer));
		PrintToChatAll("[Most Active] Players wasted a total of %s on this server", buffer);
	}

	delete hndl;
}