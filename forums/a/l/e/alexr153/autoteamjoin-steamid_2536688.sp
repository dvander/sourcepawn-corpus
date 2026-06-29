#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.2"
#define Default 0x01
#define limeGREEN 0x06

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

EngineVersion g_Game;

ConVar atj_chatMessage;
ConVar atj_changeteamifspawn;
ConVar atj_holder;
ConVar atj_ServerID;

Handle g_hKV;
Handle g_hDB;
char szKvFile[PLATFORM_MAX_PATH];
int g_iWhatTeam[MAXPLAYERS + 1];
char steamidHolder[2][32];

char sql_createTables[] = "CREATE TABLE IF NOT EXISTS `atj_steamids` ( `steamid` VARCHAR(32) NOT NULL , `team` VARCHAR(5) NOT NULL, ServerID INT NOT NULL)";
char sql_selectSID[] = "SELECT steamid, team, ServerID FROM `atj_steamids` WHERE steamid='%s';";
char sql_insertPlayer[] = "INSERT INTO atj_steamids SET steamid='%s', team='%s', ServerID='%i'";
char sql_updatePlayer[] = "UPDATE atj_steamids SET steamid='%s', team='%s', ServerID='%i' WHERE steamid='%s'";
char sql_deletePlayer[] = "DELETE FROM atj_steamids WHERE steamid='%s'";

public Plugin myinfo = 
{
	name = "STEAMID Auto team join", 
	author = PLUGIN_AUTHOR, 
	description = "Sets a given STEAMID to a specified team.", 
	version = PLUGIN_VERSION, 
	url = "NUN"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");
	}
	
	atj_chatMessage = CreateConVar("atj_chatMessage", "1", "Shows chat message when player spawnes by ATJ");
	atj_changeteamifspawn = CreateConVar("atj_changeteamifswitch", "0", "Sets the players team back if they change teams.");
	atj_holder = CreateConVar("atj_holder", "1", "(0) KV file (1) MySQL Database", _, true, 0.0, true, 1.0);
	
	if (GetConVarBool(atj_holder))
	{
		connectToDB();
		atj_ServerID = CreateConVar("atj_ServerID", "1", "The ServerID to look for in your database. (atj_holder must be 1 for this) || If (0) ServerIDS in database are obsolete to this server.", _, true, 0.0, false);
	}
	
	AutoExecConfig(true, "plugin.atj");
	
	RegAdminCmd("sm_addplayer", CMD_addplayer, ADMFLAG_RCON, "Sets a players team to the database for this server.");
	
	HookEvent("player_team", playerTeam);
	HookEvent("cs_intermission", matchEnd);
	HookEvent("announce_phase_end", halfTime);
}

public Action CMD_addplayer(int client, int args)
{
	if (args < 1)
	{
		PrintToChat(client, "[%cATJ%c] Please specify a player. sm_addplayer <name> [team]", limeGREEN, Default);
		return Plugin_Handled;
	}
	else if (args < 2)
	{
		PrintToChat(client, "[%cATJ%c] Please specify a team. sm_addplayer <name> [team]{1 -T, 2 - CT, 3 - SPEC}", limeGREEN, Default);
		return Plugin_Handled;
	} else if (args == 2)
	{
		PrintToChat(client, "[%cATJ%c] Adding player to database...", limeGREEN, Default);
		
		char arg1[32], arg2[5];
		GetCmdArg(1, arg1, 32);
		GetCmdArg(2, arg2, 5);
		int target = FindTarget(client, arg1, true, false);
		
		char szSteamid[32];
		GetClientAuthId(target, AuthId_Steam3, szSteamid, 32);
		
		char szQuery[150];
		Format(szQuery, 120, sql_selectSID, szSteamid);
		
		Handle ci = CreateDataPack();
		WritePackCell(ci, client);
		WritePackCell(ci, target);
		WritePackString(ci, arg2);
		
		SQL_TQuery(g_hDB, SQL_CheckPlayerCallback, szQuery, ci, DBPrio_Low);
		
	}
	return Plugin_Handled;
}

public int SQL_CheckPlayerCallback(Handle owner, Handle hndl, char[] error, any data)
{
	int client, target;
	char team[5];
	
	ResetPack(data);
	
	client = ReadPackCell(data);
	target = ReadPackCell(data);
	ReadPackString(data, team, 5);
	
	char szSteamid[32];
	
	GetClientAuthId(target, AuthId_Steam3, szSteamid, 32);
	
	if (hndl != INVALID_HANDLE)
	{
		if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		{
			char szSteamidDB[32], szTeam[5], szName[50];
			int ServerID;
			GetClientAuthId(target, AuthId_Steam3, szSteamid, 32);
			GetClientName(target, szName, 50);
			SQL_FetchString(hndl, 0, szSteamidDB, 32);
			SQL_FetchString(hndl, 1, szTeam, 5);
			ServerID = SQL_FetchInt(hndl, 2);
			
			if (StrEqual(szSteamid, szSteamidDB))
			{
				PrintToChat(client, "[%cATJ%c] Player is already in database. NAME:(%s), SID:(%s), TEAM:(%s), ServerID:(%i)", limeGREEN, Default, szName, szSteamidDB, szTeam, ServerID);
			}
		} else {
			char szQuery[150];
			Format(szQuery, 150, sql_insertPlayer, szSteamid, team, GetConVarInt(atj_ServerID));
			//PrintToChat(client, "[%cATJ%c] Test %s %s %i", limeGREEN, Default, szSteamid, team, GetConVarInt(atj_ServerID));
			SQL_TQuery(g_hDB, SQL_InsertPlayerCallback, szQuery, client, DBPrio_Low);
		}
	} else {
		PrintToServer("[ATJ] MySQL Error: %s", error);
	}
}

public int SQL_InsertPlayerCallback(Handle owner, Handle hndl, char[] error, any data)
{
	PrintToChat(data, "[%cATJ%c] Player successfully added to database! :)", limeGREEN, Default);
}

public void connectToDB()
{
	char szError[215];
	g_hDB = SQL_Connect("atj_sid", false, szError, sizeof(szError));
	
	if (g_hDB == INVALID_HANDLE)
	{
		SetFailState("[ATJ] Unable to connect to the MySQL server: %s", szError);
		return;
	}
	
	char driver[8];
	SQL_ReadDriver(g_hDB, driver, sizeof(driver));
	
	if (strcmp(driver, "sqlite", false) == 0)
	{
		SetFailState("[ATJ] SQLite is not supported");
	}
	
	db_CreateTables();
}

void db_CreateTables()
{
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, sql_createTables);
	SQL_UnlockDatabase(g_hDB);
}

public Action playerTeam(Event event, char[] name, bool useless)
{
	if (GetConVarBool(atj_changeteamifspawn))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (!GetConVarBool(atj_holder))
			get_steamid(client);
		else
			get_steamidDB(client);
		CreateTimer(1.0, steamid_spawner, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action halfTime(Event event, char[] name, bool useless)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && !IsClientObserver(i))
		{
			char szQuery[120], szSteamid[32];
			GetClientAuthId(i, AuthId_Steam3, szSteamid, 32);
			Format(szQuery, 120, sql_selectSID, szSteamid);
			SQL_TQuery(g_hDB, sql_UpdateCheckCallback, szQuery, i, DBPrio_Low);
		}
	}
}

public Action matchEnd(Event event, char[] name, bool useless)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
		{
			char szQuery[120], szSteamid[32];
			GetClientAuthId(i, AuthId_Steam3, szSteamid, 32);
			Format(szQuery, 120, sql_deletePlayer, szSteamid);
			SQL_TQuery(g_hDB, sql_deletePlayersCallback, szQuery, _, DBPrio_Low);
		}
	}
}

public int sql_deletePlayersCallback(Handle owner, Handle hndl, char[] error, any data)
{  }

public void OnClientPutInServer(int client)
{
	if (!GetConVarBool(atj_holder))
		get_steamid(client);
	else
		get_steamidDB(client);
	CreateTimer(1.0, steamid_spawner, client, TIMER_FLAG_NO_MAPCHANGE);
}

void get_steamidDB(int client)
{
	char szQuery[120], szSteamid[32];
	GetClientAuthId(client, AuthId_Steam3, szSteamid, 32);
	Format(szQuery, 120, sql_selectSID, szSteamid);
	SQL_TQuery(g_hDB, sql_selectSIDCallback, szQuery, client, DBPrio_Low);
	
}

public int sql_UpdateCheckCallback(Handle owner, Handle hndl, char[] error, any data)
{
	int client = data;
	
	if (hndl != INVALID_HANDLE)
	{
		if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		{
			char szSteamidDB[32], szSteamid[32], szTeam[5];
			int ServerID;
			GetClientAuthId(client, AuthId_Steam3, szSteamid, 32);
			SQL_FetchString(hndl, 0, szSteamidDB, 32);
			SQL_FetchString(hndl, 1, szTeam, 5);
			ServerID = SQL_FetchInt(hndl, 2);
			
			if (GetConVarInt(atj_ServerID) == 0)
			{
				if (StrEqual(szSteamidDB, szSteamid))
				{
					char szQuery[120];
					if (StrEqual(szTeam, "T", false))
					{
						Format(szQuery, 120, sql_updatePlayer, szSteamid, "CT", ServerID, szSteamid);
					}
					
					else if (StrEqual(szTeam, "CT", false))
					{
						Format(szQuery, 120, sql_updatePlayer, szSteamid, "T", ServerID, szSteamid);
					}
					
					SQL_TQuery(g_hDB, sql_updatedPlayerCallback, szQuery, client, DBPrio_Low);
				}
			}
			else if (ServerID == GetConVarInt(atj_ServerID))
			{
				if (StrEqual(szSteamidDB, szSteamid))
				{
					char szQuery[120];
					if (StrEqual(szTeam, "T", false))
					{
						Format(szQuery, 120, sql_updatePlayer, szSteamid, "CT", GetConVarInt(atj_ServerID), szSteamid);
					}
					
					else if (StrEqual(szTeam, "CT", false))
					{
						Format(szQuery, 120, sql_updatePlayer, szSteamid, "T", GetConVarInt(atj_ServerID), szSteamid);
					}
					
					SQL_TQuery(g_hDB, sql_updatedPlayerCallback, szQuery, _, DBPrio_Low);
				}
			}
		}
	} else {
		PrintToServer("[ATJ] MySQL Error: %s", error);
	}
}

public int sql_updatedPlayerCallback(Handle owner, Handle hndl, char[] error, any data)
{ 
	if(hndl == INVALID_HANDLE)
	PrintToServer("[ATJ] MySQL Error: %s", error);
}

public int sql_selectSIDCallback(Handle owner, Handle hndl, char[] error, any data)
{
	int client = data;
	if (hndl != INVALID_HANDLE)
	{
		if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		{
			char szSteamidDB[32], szSteamid[32], szTeam[5];
			int ServerID;
			GetClientAuthId(client, AuthId_Steam3, szSteamid, 32);
			SQL_FetchString(hndl, 0, szSteamidDB, 32);
			ServerID = SQL_FetchInt(hndl, 2);
			
			if (GetConVarInt(atj_ServerID) == 0)
			{
				if (StrEqual(szSteamid, szSteamidDB))
				{
					g_iWhatTeam[client] = SQL_FetchInt(hndl, 1);
				}
			} else if (ServerID == GetConVarInt(atj_ServerID))
			{
				if (StrEqual(szSteamid, szSteamidDB))
				{
					g_iWhatTeam[client] = SQL_FetchInt(hndl, 1);
				}
			}
			
		}
	} else {
		PrintToServer("[ATJ] MySQL Error: %s", error);
	}
}

void get_steamid(int client)
{
	char line[60], steamid[32];
	
	BuildPath(Path_SM, szKvFile, sizeof(szKvFile), "configs/Autoteamjoin-steamids.txt");
	
	GetClientAuthId(client, AuthId_Steam3, steamid, 32);
	
	g_hKV = OpenFile(szKvFile, "r");
	
	if (g_hKV != INVALID_HANDLE)
	{
		while (!IsEndOfFile(g_hKV))
		{
			ReadFileLine(g_hKV, line, 200);
			ExplodeString(line, "--", steamidHolder, sizeof(steamidHolder), sizeof(steamidHolder[]));
			
			if (StrEqual(steamidHolder[0], steamid))
			{
				if (StrEqual(steamidHolder[1], "T", false))
				{
					g_iWhatTeam[client] = 1;
					CloseHandle(g_hKV);
					return;
				} else if (StrEqual(steamidHolder[1], "CT", false))
				{
					g_iWhatTeam[client] = 2;
					CloseHandle(g_hKV);
					return;
				}
				else if (StrEqual(steamidHolder[1], "SPEC", false))
				{
					g_iWhatTeam[client] = 3;
					CloseHandle(g_hKV);
					return;
				}
			}
		}
		CloseHandle(g_hKV);
	} else {
		//ATJ Auto team join
		SetFailState("[ATJ] (configs/Autoteamjoin-steamids.txt) File was not found!");
	}
}

public Action steamid_spawner(Handle timer, any client)
{
	if (g_iWhatTeam[client] == 1)
	{
		if (IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		CS_SwitchTeam(client, CS_TEAM_T);
	}
	else if (g_iWhatTeam[client] == 2)
	{
		if (IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		CS_SwitchTeam(client, CS_TEAM_CT);
	}
	else if (g_iWhatTeam[client] == 3)
	{
		if (IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	}
	
	if (GetConVarBool(atj_chatMessage))
	{
		if (g_iWhatTeam[client] == 1)
			PrintToChat(client, "[%cATJ%c] Your team has been set to Terrorist. (If the buy menu is bugged do this to fix. Click your TeamMenu key and exit out of the menu)", limeGREEN, Default);
		else if (g_iWhatTeam[client] == 2)
			PrintToChat(client, "[%cATJ%c] Your team has been set to Counter-Terrorist. (If the buy menu is bugged do this to fix. Click your TeamMenu key and exit out of the menu)", limeGREEN, Default);
		else if (g_iWhatTeam[client] == 3)
			PrintToChat(client, "[%cATJ%c] Your team has been set to Spectator. (If any bugs open TeamMenu and exit out)", limeGREEN, Default);
	}
}
