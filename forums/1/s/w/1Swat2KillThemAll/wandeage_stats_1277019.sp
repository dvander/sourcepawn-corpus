/**
 * @file	wandeage.sp
 * @author	1Swat2KillThemAll
 *
 * @brief	WanDeage CS:S(OB) ServerSide Plugin - STATS
 * @version	1.000.000
 *
 * @todo	test SQLite, todo: fix translation of PrintRank()
 *
 * WanDeage CS:S(OB) ServerSide Plugin - STATS
 * Copyright (C)/© 2010 B.D.A.K. Koch
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#pragma semicolon 1

#include <sourcemod>

#include "wandeage.inc"

//#define MECH_ACHI		//<------ Edit
enum EStats
{
	E_S_Points = 0,
	E_S_Kills,
	E_S_Deaths,
	E_S_SOldPoints,
	E_S_SStreak,
	E_S_SKills,
	E_S_SDeaths,
	E_S_Max
};
new Stats[E_S_Max][MAXPLAYERS+1];

#define MYSQL 0
#define SQLITE 1
enum EQueries
{
	E_QCreate = 0,
	E_QInsert,
	E_QSelectId,
	E_QConnect,
	E_QUpdate,
	E_QDelete,
	E_QSelectTop,
	E_QSelectWorst,
	E_QSelectCount,
	E_QSelectRank,
	E_QMax
};
new const String:SQLQueries[2][E_QMax][] =
{
	{
		"CREATE TABLE IF NOT EXISTS sm_wandeage ( id int(11) NOT NULL AUTO_INCREMENT, name VARCHAR(65), points int(11) DEFAULT 0, kills int(11) DEFAULT 0, deaths int(11) DEFAULT 0, last_online DATE, steam VARCHAR(23), UNIQUE (steam), PRIMARY KEY (id));",
		"INSERT INTO sm_wandeage (name, last_online, steam) VALUES ('%s', CURDATE(), '%s');",
		"SELECT id FROM sm_wandeage WHERE steam = '%s';",
		"SELECT id, points, kills, deaths FROM sm_wandeage WHERE steam = '%s'",
		"UPDATE sm_wandeage SET name = '%s', points = points + '%i', kills = '%i', deaths = '%i', last_online = CURDATE() WHERE id = '%i';",
		"DELETE FROM sm_wandeage WHERE DATEDIFF(CURDATE(), last_online) >= %i;",
		"SELECT name, points FROM sm_wandeage ORDER BY points DESC LIMIT 10;",
		"SELECT name, points FROM sm_wandeage ORDER BY points ASC LIMIT 10;",
		"SELECT COUNT(*) FROM sm_wandeage;",
		"SELECT COUNT(*) FROM sm_wandeage WHERE points > '%i';"
	},
	{
		"CREATE TABLE IF NOT EXISTS sm_wandeage (id int(11) PRIMARY KEY, name VARCHAR(65), points int(11) DEFAULT 0, kills int(11) DEFAULT 0, deaths int(11) DEFAULT 0, last_online DATE DEFAULT (DATE('now')), steam VARCHAR(23) UNIQUE);",
		"INSERT INTO sm_wandeage (name, steam) VALUES ('%s', '%s');",
		"SELECT id FROM sm_wandeage WHERE steam = '%s';",
		"SELECT id, points, kills, deaths FROM sm_wandeage WHERE steam = '%s'",
		"UPDATE sm_wandeage SET name = '%s', points = points + '%i', kills = '%i', deaths = '%i', last_online = DATE('now') WHERE id = '%i';",
		"DELETE FROM sm_wandeage WHERE DATE('now') - last_online  >= %i;",
		"SELECT name, points FROM sm_wandeage ORDER BY points DESC LIMIT 10;",
		"SELECT name, points FROM sm_wandeage ORDER BY points ASC LIMIT 10;",
		"SELECT COUNT(*) FROM sm_wandeage;",
		"SELECT COUNT(*) FROM sm_wandeage WHERE points > '%i';"
	}
};
#define MYSQL_ADMIN_CREATEQUERY "CREATE TABLE IF NOT EXISTS sm_wandeage_admins (id int(11) NOT NULL AUTO_INCREMENT, username VARCHAR(64) NOT NULL UNIQUE, password VARCHAR(41) NOT NULL, steam VARCHAR(23) UNIQUE, privileges INT UNSIGNED, PRIMARY KEY (id));"

new db_id[MAXPLAYERS+1] = { -1, ... },
	admin_privileges[MAXPLAYERS+1] = { 0, ... },
	Handle:db, db_type,
	Handle:Top10Menu, Handle:Worst10Menu,
	String:cl_auth[MAXPLAYERS+1][23],
	Handle:h_CvEnabled, CvEnabled,
	Handle:h_CvDbName,
	Handle:h_CvDebug, CvDebug = 0,
	Handle:h_CvDeletionPeriod, CvDeletionPeriod,
	stats_enabled, dbHasChanged,
	stats_admin;
#if defined MECHA_ACHI
new bool:mecha_achi, rWanDeages[MAXPLAYERS+1];
#endif //MECHA_ACHI

enum EAdminMenu
{
	E_AMAddPoints = 0,
	E_AMRemovePoints,
	E_AMSetPoints,
	E_AMAddKills,
	E_AMRemoveKills,
	E_AMSetKills,
	E_AMAddDeaths,
	E_AMRemoveDeaths,
	E_AMSetDeaths,
	E_AMMax
};
new const String:AdminMenuEntries[E_AMMax][] =
{
	"AddPoints",
	"RemovePoints",
	"SetPoints",
	"AddKills",
	"RemoveKills",
	"SetKills",
	"AddDeaths",
	"RemoveDeaths",
	"SetDeaths"
};
new AdminMenuFlags[E_AMMax] =
{
	4,
	4,
	4,
	8,
	8,
	8,
	16,
	16,
	16
};
enum EAdminMenuChoice
{
	E_AMCAction = 0,
	E_AMCTarget,
	E_AMCAmount,
	E_AMCMax
};
new AdminMenuChoice[MAXPLAYERS+1][E_AMCMax];

#define PLUGIN_NAME "WanDeage Stats"
#define PLUGIN_NAME_NOSPACE "WanDeage_Stats"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#if defined MECHA_ACHI
#define PLUGIN_DESCRIPTION "WanDeage Stats (SQL + Mecha Ware Achievements)"
#else
#define PLUGIN_DESCRIPTION "WanDeage Stats (SQL)"
#endif //MECHA_ACHI
#define PLUGIN_VERSION "0.001.000"
#define PLUGIN_URL "http://web.ccc-clan.com/wandeage/"
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	dbHasChanged = false;
	HookEvents();

	h_CvDeletionPeriod = CreateConVar("sm_wandeage_deletionperiod", "180", "Sets after how many days of inactivity a player should be deleted.", FCVAR_DONTRECORD, true, 0.0);
	CvDeletionPeriod = 180;
	HookConVarChange(h_CvDeletionPeriod, OnConVarChanged);
	h_CvEnabled = CreateConVar("sm_wandeage_stats", "1", "Sets whether WanDeage stats should be enabled.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(h_CvEnabled, OnConVarChanged);
	CvEnabled = GetConVarInt(h_CvEnabled);
	h_CvDbName = CreateConVar("sm_wandeage_database", "default", "The name of the WanDeage database.", FCVAR_DONTRECORD);
	HookConVarChange(h_CvDbName, OnConVarChanged);
	h_CvDebug = FindConVar("sm_wandeage_debug");
	HookConVarChange(h_CvDebug, OnConVarChanged);
	CvDebug = GetConVarInt(h_CvDebug);

	AutoExecConfig(true, PLUGIN_NAME_NOSPACE);

	wandeage_loaded = LibraryExists("wandeage");
#if defined MECHA_ACHI
	mecha_achi = LibraryExists("mw_achi");

	for (new i = 0; i <= MaxClients; i++)
	{
		rWanDeages[i] = 0;
	}
#endif //MECHA_ACHI

	for (new i = 0; i < _:E_S_Max; i++)
	{
		for (new j = 0; j <= MaxClients; j++)
		{
			Stats[i][j] = 0;
		}
	}

	if (wandeage_loaded)
	{
		WanDeageLoaded();
	}

	LoadTranslations("wandeage.phrases");
	LoadTranslations("common.phrases");
}
public OnPluginEnd()
{
	//UnhookEvents();

	if (wandeage_loaded)
	{
		AddWanDeageModules("Stats", true);
	}

	CloseHandle(db);
	CloseHandle(Top10Menu);
	CloseHandle(Worst10Menu);
}
public OnMapStart()
{
	if (stats_enabled || !dbHasChanged)
	{
		return;
	}

	if (db != INVALID_HANDLE)
	{
		CloseHandle(db);
	}
	ConnectToDB();
}

WanDeageLoaded()
{
	HookWanDeage(OnWanDeage);
	HookWanDeageCommand(OnWanDeageCommand);
	AddWanDeageModules("Stats", false);
	ConnectToDB();
}

HookEvents()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}
UnhookEvents()
{
	UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action:OnWanDeage(uid_client, uid_victim)
{
	new client = GetClientOfUserId(uid_client),
		victim = GetClientOfUserId(uid_victim);
#if defined MECHA_ACHI
	rWanDeages[victim] = 0;
#endif //MECHA_ACHI

	if (!client || !victim || (!CvDebug && (IsFakeClient(client) || IsFakeClient(victim))))
	{
		return;
	}
	Stats[E_S_SStreak][client]++;
	new win = RoundToCeil(Stats[E_S_SStreak][client] * 2.5);

	if (win > 1000)
	{
		win = 1000;
	}

	Stats[E_S_Points][client] += win;

	if (!Stats[E_S_SStreak][victim])
	{
		Stats[E_S_SStreak][victim]--;
	}
	else
	{
		Stats[E_S_SStreak][victim] = 0;
	}

	new loss = (2 * win) / 3;

	if (loss > 20)
	{
		loss = 20;
	}

	Stats[E_S_Points][victim] -= loss;
	Stats[E_S_Kills][client]++;
	Stats[E_S_Deaths][victim]++;
	Stats[E_S_SKills][client]++;
	Stats[E_S_SDeaths][victim]++;
#if defined MECHA_ACHI
	//if (mecha_achi) { //ALWAYS FALSE????
	rWanDeages[client]++;
	mw_AchievementEvent("wandeage", client, victim, 0, 0);

	if (rWanDeages[client] ==  5)
	{
		mw_AchievementEvent("wandeage_ace", client, 0, 0, 0);
	}

	if (Stats[E_S_Points][client] >= 10000)
	{
		mw_AchievementEvent("wandeage_10kpoints", client, 0, 0, 0);
	}

	if (Stats[E_S_SStreak][client] == 15)
	{
		mw_AchievementEvent("wandeage_15streak", client, 0, 0, 0);
		IgniteEntity(client, 2);
	}

	//}
#endif //MECHA_ACHI
}
public Action:OnWanDeageCommand(client, args, String:argstr[])
{
	new bool:Handled = false;

	if (StrEqual(argstr, "points"))
	{
		PrintPoints(client);
		Handled = true;
	}
	else if (StrEqual(argstr, "rank"))
	{
		PrintRank(client);
		Handled = true;
	}
	else if (StrEqual(argstr, "session"))
	{
		ShowSession(client);
		Handled = true;
	}
	else if (StrEqual(argstr, "top"))
	{
		ShowTop(client, 1);
		Handled = true;
	}
	else if (StrEqual(argstr, "worst"))
	{
		ShowTop(client, 0);
		Handled = true;
	}
	else if (StrEqual(argstr, "stats_admin") && stats_admin)
	{
		WanDeageAdminMenu(client);
		Handled = true;
	}

	if (Handled)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
public WdInfoMenuHandler(client)
{
	InformationMenu(client);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "wandeage"))
	{
		wandeage_loaded = false;
		stats_enabled = false;
	}

#if defined MECHA_ACHI
	else if (StrEqual(name, "mw_achi"))
	{
		mecha_achi = false;
	}
#endif //MECHA_ACHI
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "wandeage"))
	{
		wandeage_loaded = true;
		WanDeageLoaded();
	}

#if defined MECHA_ACHI
	else if (StrEqual(name, "mw_achi"))
	{
		mecha_achi = true;
	}
#endif //MECHA_ACHI
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == h_CvDeletionPeriod)
	{
		CvDeletionPeriod = StringToInt(newVal);
	}
	else if (cvar == h_CvEnabled)
	{
		CvEnabled = StringToInt(newVal);

		if (CvEnabled)
		{
			HookEvents();
		}
		else
		{
			UnhookEvents();
		}
	}
	else if (cvar == h_CvDebug)
	{
		CvDebug = StringToInt(newVal);
	}
	else if (cvar == h_CvDbName)
	{
		dbHasChanged = true;
	}
}

public OnClientDisconnect(client)
{
	UpdateClient(client);
}
public OnClientAuthorized(client, const String:auth[])
{
	admin_privileges[client] = 0;

	for (new i = 0; i < _:E_S_Max; i++)
	{
		Stats[i][client] = 0;
	}

	if (IsFakeClient(client))
	{
		return;
	}

	decl String:query[255];
	Format(query, sizeof(query), SQLQueries[db_type][E_QConnect], auth);
	strcopy(cl_auth[client], 20, auth);

	if (stats_enabled)
	{
		SQL_TQuery(db, T_ClientConnected, query, GetClientUserId(client));
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CvEnabled)
		for (new i = 1; i <= MaxClients; i++)
		{
			UpdateClient(i);
#if defined MECHA_ACHI
			rWanDeages[i] = 0;
#endif //MECHA_ACHI
		}

	BuildTop();
}

ConnectToDB()
{
	decl String:name[64];
	GetConVarString(h_CvDbName, name, sizeof(name));

	if (SQL_CheckConfig(name))
	{
		SQL_TConnect(GetDatabase, name);
	}
	else
	{
		LogError("Failed to connect using conf. %s: using default", name);
		SQL_TConnect(GetDatabase);
	}
}
public GetDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("(1) Database failure: %s", error);
		stats_enabled = false;
	}
	else
	{
		db_type = -1;
		decl String:type[32];
		new Handle:driver = SQL_ReadDriver(hndl);
		SQL_GetDriverProduct(driver, type, sizeof(type));

		if (StrEqual(type, "MySQL", false))
		{
			db_type = 0;
		}

		if (StrEqual(type, "SQLite", false))
		{
			db_type = 1;
			
		}

		if (db_type < 0)
		{
			LogError("(2) Unrecognized Database-type!");
			stats_enabled = false;
		}

		db = hndl;
		SQL_LockDatabase(db);

		decl Handle:result;
		if (!SQL_FastQuery(db, SQLQueries[db_type][E_QCreate]) || (db_type == MYSQL && !SQL_FastQuery(db, MYSQL_ADMIN_CREATEQUERY) && ((result = SQL_Query(db, "SELECT * FROM sm_wandeage_admins LIMIT 0")) == INVALID_HANDLE)))
		{
			decl String:error2[128];
			SQL_GetError(db, error2, sizeof(error2));
			LogError("(3) %s", error2);
			stats_enabled = false;
			stats_admin = false;
		}
		stats_admin = result != INVALID_HANDLE;

		SQL_UnlockDatabase(db);
		BuildTop();
		DeleteOldPlayers();
		stats_enabled = true;
	}
}
public T_ClientConnected(Handle:owner, Handle:hndl, const String:error[], any:uid_client)
{
	new client = GetClientOfUserId(uid_client);

	if (!client || !IsClientConnected(client) || !wandeage_loaded || !stats_enabled)
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("(4) Query failed! %s", error);
		stats_enabled = false;
	}
	else if (!SQL_FetchRow(hndl))
	{
		decl String:name[MAX_NAME_LENGTH],
			String:name2[2*(MAX_NAME_LENGTH)+1],
			String:query[255];
		GetClientName(client, name, sizeof(name));
		SQL_EscapeString(db, name, name2, sizeof(name2));
		Format(query, sizeof(query), SQLQueries[db_type][E_QInsert], name2, cl_auth[client]);
		SQL_LockDatabase(db);

		if (!SQL_FastQuery(db, query))
		{
			decl String:error2[128];
			SQL_GetError(db, error2, sizeof(error2));
			LogError("(5) %s", error2);
		}
		else
		{
			new Handle:result;
			Format(query, sizeof(query), SQLQueries[db_type][E_QSelectId], cl_auth[client]);

			if ((result = SQL_Query(db, query)) == INVALID_HANDLE)
			{
				decl String:error2[128];
				SQL_GetError(db, error2, sizeof(error2));
				LogError("(6) %s", error2);
			}
			else if (SQL_FetchRow(result))
			{
				db_id[client] = SQL_FetchInt(result, 0);
			}

			CloseHandle(result);
		}

		SQL_UnlockDatabase(db);
	}
	else
	{
		db_id[client] = SQL_FetchInt(hndl, 0);
		Stats[E_S_Points][client] = SQL_FetchInt(hndl, 1);
		Stats[E_S_Kills][client] = SQL_FetchInt(hndl, 2);
		Stats[E_S_Deaths][client] = SQL_FetchInt(hndl, 3);
	}

	Stats[E_S_SOldPoints][client] = Stats[E_S_Points][client];

	if (stats_admin)
	{
		SQL_LockDatabase(db);

		decl Handle:res, String:query2[128];
		Format(query2, sizeof(query2), "SELECT privileges FROM sm_wandeage_admins WHERE steam = '%s'", cl_auth[client]);
		if ((res = SQL_Query(db, query2)) == INVALID_HANDLE)
		{
			decl String:error2[128];
			SQL_GetError(db, error2, sizeof(error2));
			LogError("(7) %s", error2);
			stats_admin = false;
		}
		if (SQL_FetchRow(res))
		{
			admin_privileges[client] = SQL_FetchInt(res, 0);
			CloseHandle(res);
		}

		SQL_UnlockDatabase(db);
	}
}
UpdateClient(client)
{
	if (!client || !IsClientConnected(client) || IsFakeClient(client) || !wandeage_loaded || !stats_enabled)
	{
		return;
	}

	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	decl String:name2[2*(MAX_NAME_LENGTH)+1];
	SQL_EscapeString(db, name, name2, sizeof(name2));
	decl String:query[512];
	Format(query, sizeof(query), SQLQueries[db_type][E_QUpdate], name2, Stats[E_S_Points][client] - Stats[E_S_SOldPoints][client], Stats[E_S_Kills][client], Stats[E_S_Deaths][client], db_id[client]);
	SQL_TQuery(db, T_UpdateClient, query);
}
public T_UpdateClient(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("(8) Query failed! %s", error);
		stats_enabled = false;
	}
}
DeleteOldPlayers()
{
	if (CvDeletionPeriod > 0)
	{
		decl String:query[255];
		Format(query, sizeof(query), SQLQueries[db_type][E_QDelete], CvDeletionPeriod);
		SQL_TQuery(db, T_DeleteOldPlayers, query);
	}
}
public T_DeleteOldPlayers(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("(9) Query failed! %s", error);
	}
	else if (CvDebug)
	{
		LogMessage("Deleted %i players, inactivity > %i days.", SQL_GetAffectedRows(db), CvDeletionPeriod);
	}
}
BuildTop()
{
	if (db != INVALID_HANDLE)
	{
		SQL_TQuery(db, T_Top10, SQLQueries[db_type][E_QSelectTop]);
	}
}
public T_Top10(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("(10) Query failed! %s", error);
	}
	else
	{
		BuildTop10Menu(hndl, 1);
	}

	SQL_TQuery(db, T_Worst10, SQLQueries[db_type][E_QSelectWorst]);
}
public T_Worst10(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("(11) Query failed! %s", error);
	}
	else
	{
		BuildTop10Menu(hndl, 0);
	}
}
BuildTop10Menu(Handle:hndl, order)
{
	new Handle:panel = CreatePanel();

	if (order)
	{
		SetPanelTitle(panel, "WanDeage Top10");
	}
	else
	{
		SetPanelTitle(panel, "WanDeage Worst10");
	}

	decl String:buffer[MAX_NAME_LENGTH], points,
		String:message[MAX_NAME_LENGTH + 10];

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, buffer, sizeof(buffer));
		points = SQL_FetchInt(hndl, 1);
		Format(message, sizeof(message), "%s: %i", buffer, points);
		DrawPanelItem(panel, message);
	}

	if (order)
	{
		if (Top10Menu != INVALID_HANDLE)
		{
			CloseHandle(Top10Menu);
		}

		Top10Menu = panel;
	}
	else
	{
		if (Worst10Menu != INVALID_HANDLE)
		{
			CloseHandle(Worst10Menu);
		}

		Worst10Menu = panel;
	}
}
PrintRank(client)
{
	if (IsFakeClient(client) || !stats_enabled)
	{
		return;
	}

	decl String:String_Query[128];
	Format(String_Query, sizeof(String_Query), SQLQueries[db_type][E_QSelectRank], Stats[E_S_Points][client]);
	SQL_LockDatabase(db);
	new Handle:hQuery = SQL_Query(db, String_Query),
		Handle:hQuery2 = SQL_Query(db, SQLQueries[db_type][E_QSelectCount]);
	SQL_UnlockDatabase(db);

	if (hQuery == INVALID_HANDLE || !SQL_FetchRow(hQuery) || hQuery2 == INVALID_HANDLE || !SQL_FetchRow(hQuery2))
	{
		PrintToChat(client, "%t", "CantRetrieveStats", YELLOW, LIGHTGREEN, YELLOW);
	}
	else
	{
		new place = SQL_FetchInt(hQuery, 0) + 1, players = SQL_FetchInt(hQuery2, 0);
		decl String:Name[MAX_NAME_LENGTH];
		GetClientName(client, Name, sizeof(Name));

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				//PrintToChat(i, "%t", "PrintRank", LIGHTGREEN, YELLOW, LIGHTGREEN, YELLOW, GREEN, Name, YELLOW, GREEN, place, YELLOW, GREEN, players, YELLOW, GREEN, Stats[E_S_Points][client], YELLOW);
				PrintToChat(i, "%c[%cWanDeage%c] %c%s%c is ranked %c%i%c of %c%i%c with %c%i%c points.", YELLOW, LIGHTGREEN, YELLOW, GREEN, Name, YELLOW, GREEN, place, YELLOW, GREEN, players, YELLOW, GREEN, Stats[E_S_Points][client], YELLOW);
			}
		}
		//TODO Fix translation
	}

	CloseHandle(hQuery);
	CloseHandle(hQuery2);
}
PrintPoints(client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	decl String:Name[MAX_NAME_LENGTH];
	GetClientName(client, Name, sizeof(Name));

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrintToChat(i, "%t", "PrintPoints", YELLOW, LIGHTGREEN, YELLOW, GREEN, Name, YELLOW, GREEN, Stats[E_S_Points][client], YELLOW);
		}
	}
}
ShowTop(client, order)
{
	if (!stats_enabled)
	{
		PrintToChat(client, "DBError", YELLOW, LIGHTGREEN, YELLOW);
	}
	else if (order)
	{
		SendPanelToClient(Top10Menu, client, PanelHandlerEmpty, 20);
	}
	else
	{
		SendPanelToClient(Worst10Menu, client, PanelHandlerEmpty, 20);
	}
}
ShowSession(client)
{
	decl String:buff[128];
	new Handle:panel3 = CreatePanel();

	Format(buff, sizeof(buff), "%T", "SessionTitle", client);
	SetPanelTitle(panel3, buff);

	Format(buff, sizeof(buff), "%T", "SessionSKills", client, Stats[E_S_SKills][client]);
	DrawPanelItem(panel3, buff);

	Format(buff, sizeof(buff), "%T", "SessionSDeaths", client, Stats[E_S_SDeaths][client]);
	DrawPanelItem(panel3, buff);

	Format(buff, sizeof(buff), "%T", "SessionKills", client, Stats[E_S_Kills][client]);
	DrawPanelItem(panel3, buff);

	Format(buff, sizeof(buff), "%T", "SessionDeaths", client, Stats[E_S_Deaths][client]);
	DrawPanelItem(panel3, buff);

	Format(buff, sizeof(buff), "%T", "SessionCurrentStreak", client, Stats[E_S_SStreak][client]);
	DrawPanelItem(panel3, buff);

	Format(buff, sizeof(buff), "%T", "SessionPointsG", client, Stats[E_S_Points][client] - Stats[E_S_SOldPoints][client]);
	DrawPanelItem(panel3, buff);

	Format(buff, sizeof(buff), "%T", "SessionCPoints", client, Stats[E_S_Points][client]);
	DrawPanelItem(panel3, buff);

	SendPanelToClient(panel3, client, PanelHandlerEmpty, 20);
	CloseHandle(panel3);
}

InformationMenu(client)
{
	new Handle:menu = CreateMenu(InformationMenuHandler);
	SetMenuTitle(menu, "%T", "CodedBy", client, "1Swat2KillThemAll");
	AddMenuItem(menu, "0", "!wandeage <command>");
	AddMenuItem(menu, "1", "points");
	AddMenuItem(menu, "2", "rank");
	AddMenuItem(menu, "3", "session");
	AddMenuItem(menu, "4", "top");
	AddMenuItem(menu, "5", "worst");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public InformationMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				PrintPoints(param1);
			}
			case 2:
			{
				PrintRank(param1);
			}
			case 3:
			{
				ShowSession(param1);
			}
			case 4:
			{
				ShowTop(param1, 1);
			}
			case 5:
			{
				ShowTop(param1, 0);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

WanDeageAdminMenu(client)
{
	if (!admin_privileges[client])
	{
		return;
	}

	for (new i = 0; i < _:E_AMCMax; i++)
	{
		AdminMenuChoice[client][i] = 0;
	}

	new Handle:menu = CreateMenu(AdminMenuHandler);
	decl String:buff[8], String:text[64];
	SetMenuTitle(menu, "%T", "AdminMenu", client);

	for (new i = 0; i < _:E_AMMax; i++)
	{
		if (admin_privileges[client] & AdminMenuFlags[i])
		{
			IntToString(i, buff, sizeof(buff));
			Format(text, sizeof(text), "%T", AdminMenuEntries[i], client);
			AddMenuItem(menu, buff, text);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public AdminMenuHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		decl String:buff[8];
		GetMenuItem(menu, param, buff, sizeof(buff));
		if ((AdminMenuChoice[client][E_AMCAction] = StringToInt(buff)) < 0 || AdminMenuChoice[client][E_AMCAction] >= _:E_AMMax)
		{
			return;
		}

		new Handle:menu2 = CreateMenu(AdminMenuHandler2);
		SetMenuTitle(menu, "%T", "Player", client);
		decl String:name[MAX_NAME_LENGTH];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
			{
				continue;
			}
			IntToString(GetClientUserId(i), buff, sizeof(buff));
			GetClientName(i, name, sizeof(name));

			AddMenuItem(menu2, buff, name);
		}

		DisplayMenu(menu2, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public AdminMenuHandler2(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		decl String:buff[8];
		GetMenuItem(menu, param, buff, sizeof(buff));
		AdminMenuChoice[client][E_AMCTarget] = StringToInt(buff);

		if (AdminMenuChoice[client][E_AMCAction] == _:E_AMSetPoints)
		{
			AdminMenuChoice[client][E_AMCAmount] = Stats[E_S_Points][AdminMenuChoice[client][E_AMCTarget]];
		}
		else if (AdminMenuChoice[client][E_AMCAction] == _:E_AMSetKills)
		{
			AdminMenuChoice[client][E_AMCAmount] = Stats[E_S_Points][AdminMenuChoice[client][E_AMCTarget]];
		}

		AdminMenu3(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
AdminMenu3(client)
{
	new Handle:menu = CreateMenu(AdminMenuHandler3);
	SetMenuTitle(menu, "%T", "Amount", client, AdminMenuChoice[client][E_AMCAmount]);
	AddMenuItem(menu, "1", "+1");
	AddMenuItem(menu, "-1", "-1");
	AddMenuItem(menu, "5", "+5");
	AddMenuItem(menu, "-5", "-5");
	AddMenuItem(menu, "10", "+10");
	AddMenuItem(menu, "-10", "-10");
	AddMenuItem(menu, "50", "+50");
	AddMenuItem(menu, "-50", "-50");
	AddMenuItem(menu, "100", "+100");
	AddMenuItem(menu, "-100", "-100");
	AddMenuItem(menu, "500", "-500");
	AddMenuItem(menu, "-500", "-500");
	AddMenuItem(menu, "1000", "+1000");
	AddMenuItem(menu, "-1000", "-1000");
	decl String:buff[32];
	Format(buff, sizeof(buff), "%T", "Submit", client);
	AddMenuItem(menu, "0", buff);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}
public AdminMenuHandler3(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		decl String:buff[8];
		GetMenuItem(menu, param, buff, sizeof(buff));

		new selection = StringToInt(buff);

		if (selection)
		{
			AdminMenuChoice[client][E_AMCAmount] += selection;
			AdminMenu3(client);
		}
		else
		{
			new target = GetClientOfUserId(AdminMenuChoice[client][E_AMCTarget]);
			switch (AdminMenuChoice[client][E_AMCAction])
			{
				case E_AMAddPoints:
				{
					Stats[E_S_Points][target] += AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMRemovePoints:
				{
					Stats[E_S_Points][target] -= AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMSetPoints:
				{
					Stats[E_S_Points][target] = AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMAddKills:
				{
					Stats[E_S_Kills][target] += AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMRemoveKills:
				{
					Stats[E_S_Kills][target] -= AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMSetKills:
				{
					Stats[E_S_Kills][target] = AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMAddDeaths:
				{
					Stats[E_S_Deaths][target] += AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMRemoveDeaths:
				{
					Stats[E_S_Deaths][target] -= AdminMenuChoice[client][E_AMCAmount];
				}
				case E_AMSetDeaths:
				{
					Stats[E_S_Deaths][target] = AdminMenuChoice[client][E_AMCAmount];
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
