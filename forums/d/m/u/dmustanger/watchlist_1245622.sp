#pragma semicolon 1
#include <sourcemod>
#include <dbi>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define IPLUGIN_VERSION "2.0.1"

public Plugin:myinfo = 
{
	name = "WatchList",
	author = "Dmustanger",
	description = "Sets players to a WatchList.",
	version = IPLUGIN_VERSION,
	url = "http://thewickedclowns.net"
}

new iadmin = (1<<2);
new iWatchlistAnnounce = 3;
new itargets[MAXPLAYERS];
new iprune = 0;

new Handle:Database = INVALID_HANDLE;
new Handle:CvarHostIp = INVALID_HANDLE;
new Handle:CvarPort = INVALID_HANDLE;
new Handle:CvarWatchlistAnnounceInterval = INVALID_HANDLE;
new Handle:WatchlistTimer = INVALID_HANDLE;
new Handle:CvarWatchlistSound = INVALID_HANDLE;
new Handle:CvarWatchlistLog = INVALID_HANDLE;
new Handle:CvarWatchlistAdmin = INVALID_HANDLE;
new Handle:CvarWatchlistAnnounce = INVALID_HANDLE;
new Handle:hTopMenu = INVALID_HANDLE;
new Handle:CvarWatchlistPrune = INVALID_HANDLE;
new Handle:CvarAnnounceAdminJoin = INVALID_HANDLE;

new String:glogFile[PLATFORM_MAX_PATH];
new String:gServerIp[200];
new String:gServerPort[100];

new bool:IsMYSQL = true;
new bool:IsSoundOn = true;
new bool:IsLogOn = false;
new bool:IsAdminJoinOn = false;

new const String:WatchlistSound[] = "resource/warning.wav";

public OnPluginStart()
{
	BuildPath(Path_SM, glogFile, sizeof(glogFile), "logs/watchlist.log");
	CreateConVar("watchlist2_version", IPLUGIN_VERSION, "WatchList Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("watchlist.phrases");
	LoadTranslations("common.phrases");
	if (!SQL_CheckConfig("watchlist"))
	{
		decl String:ltext[256];
		Format(ltext, sizeof(ltext), "%T", "ERROR1", LANG_SERVER);
		SetFailState(ltext);	
	}
	else
	{
		SQL_TConnect(sqlGotDatabase, "watchlist");
		RegAdminCmd("watchlist_query", Command_Watchlist_Query, ADMFLAG_KICK, "watchlist_query \"steam_id | online\"", "Queries the Watchlist. Leave blank to search all.");		
		RegAdminCmd("watchlist_add", Command_Watchlist_Add, ADMFLAG_KICK, "watchlist_add \"steam_id | #userid | name\" \"reason\"", "Adds a player to the watchlist.");
		RegAdminCmd("watchlist_remove", Command_Watchlist_Remove, ADMFLAG_KICK, "watchlist_remove \"steam_id | #userid | name\"", "Removes a player from the watchlist.");
		CvarHostIp = FindConVar("hostip");
		CvarPort = FindConVar("hostport");
		CvarWatchlistAnnounceInterval = CreateConVar("watchlist_announce_interval", "1.0", "Controls how often users on the watchlist \nwho are currently on the server are announced. \nThe time is specified in whole minutes (1.0...10.0).", FCVAR_NONE,	true, 1.0, true, 10.0);
		HookConVarChange(CvarWatchlistAnnounceInterval, WatchlistAnnounceIntChange);
		CvarWatchlistSound = CreateConVar("watchlist_sound_enabled", "1", "Plays a warning sound to admins when \na WatchList player is announced. \n1 to Enable. \n0 to Disable.");
		HookConVarChange(CvarWatchlistSound, WatchlistSoundChange);
		CvarWatchlistLog = CreateConVar("watchlist_log_enabled", "0", "Enables logging. \n1 to Enable. \n0 to Disable.");
		HookConVarChange(CvarWatchlistLog, WatchlistLogChange);
		CvarWatchlistAdmin = CreateConVar("watchlist_adminflag", "c", "Choose the admin flag that admins must have to use the watchlist. \nFind more flags at http://wiki.alliedmods.net/Adding_Admins_(SourceMod)#Levels");
		HookConVarChange(CvarWatchlistAdmin, WatchlistAdminChange);
		CvarWatchlistAnnounce = CreateConVar("watchlist_announce", "3", "1 Announce only when a player on the Watchlist joins and leaves the server. \n2 Announce every x amount of mins set by watchlist_announce_interval. \n3 Both 1 and 2. \n0 Disables announcing.");
		HookConVarChange(CvarWatchlistAnnounce, WatchlistAnnounceChange);
		CvarWatchlistPrune = CreateConVar("watchlist_auto_delete", "0", "Controls how long in days to keep a player \non the watchlist before it is auto deleted. \n0 to Disable.");
		HookConVarChange(CvarWatchlistPrune, WatchlistPruneChange);
		CvarAnnounceAdminJoin = CreateConVar("watchlist_admin_join", "0", "If set to 1, when a admin joins he will get a list of players on the watchlist that are on the server in the console.");
		HookConVarChange(CvarAnnounceAdminJoin, AnnounceAdminJoinChange);
		WatchlistTimer = CreateTimer(60.0, ShowWatchlist, INVALID_HANDLE, TIMER_REPEAT);
		AutoExecConfig(true, "watchlist");
	}
}

public GetIpPort()
{
	decl String:sServerIp[100];
	decl String:sServerPort[50];
	decl String:sqlServerIp[200];
	decl String:sqlServerPort[100];
	decl String:ip[4];
	new longip = GetConVarInt(CvarHostIp);
	ip[0] = (longip >> 24) & 0x000000FF;
	ip[1] = (longip >> 16) & 0x000000FF;
	ip[2] = (longip >> 8) & 0x000000FF;
	ip[3] = longip & 0x000000FF;
	Format(sServerIp, sizeof(sServerIp), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
	GetConVarString(CvarPort, sServerPort, sizeof(sServerPort));
	SQL_EscapeString(Database, sServerIp, sqlServerIp, sizeof(sqlServerIp));
	SQL_EscapeString(Database, sServerPort, sqlServerPort, sizeof(sqlServerPort));
	strcopy(gServerIp, sizeof(gServerIp), sqlServerIp);
	strcopy(gServerPort, sizeof(gServerPort), sqlServerPort);
}

public sqlGotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		decl String:ltext[256];
		Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
		SetFailState(ltext);
	}
	else 
	{
		Database = hndl;
		sqldbtable();
		GetIpPort();
	}	
}

sqldbtable()
{
	decl String:sdbtype[64];
	decl String:squery[256];
	decl String:query[256];
	SQL_ReadDriver(Database, sdbtype, sizeof(sdbtype));
	if(StrEqual(sdbtype, "sqlite", false))
	{
		IsMYSQL = false;
		squery = "CREATE TABLE IF NOT EXISTS watchlist2 (ingame INTEGER NOT NULL, steamid TEXT PRIMARY KEY ON CONFLICT REPLACE, serverip TEXT, serverport TEXT, reason TEXT NOT NULL, name TEXT, date TEXT NOT NULL, date_last_seen TEXT NOT NULL);";
		query = "CREATE TABLE IF NOT EXISTS watchlist_info (stored_date TEXT);";
	}
	else
	{
		IsMYSQL = true;
		squery = "CREATE TABLE IF NOT EXISTS watchlist2 (ingame INT NOT NULL, steamid VARCHAR(50) NOT NULL, serverip VARCHAR(40), serverport VARCHAR(20), reason TEXT NOT NULL, name VARCHAR(100), date DATE, date_last_seen DATE, PRIMARY KEY (steamid)) ENGINE = InnoDB;";
		query = "CREATE TABLE IF NOT EXISTS watchlist_info (stored_date DATE)ENGINE = InnoDB;";
	}
	SQL_FastQuery(Database, query);
	SQL_TQuery(Database, sqlT_Generic, squery);
}

public sqlT_Generic(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
}

public Action:ShowWatchlist(Handle:timer, Handle:pack)
{
	decl String:squery[256];
	Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE serverip = '%s' AND serverport = '%s' AND ingame > 0", gServerIp, gServerPort);
	SQL_TQuery(Database, sqlT_ShowWatchlist, squery);
}

public sqlT_ShowWatchlist(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			decl String:sqlsteam[130];
			new iuserid = SQL_FetchInt(hndl, 0);
			new iclient = GetClientOfUserId(iuserid);
			SQL_FetchString(hndl, 1, sqlsteam, sizeof(sqlsteam));
			if (iclient != 0)
			{
				if (IsClientConnected(iclient) && !IsFakeClient(iclient))
				{
					decl String:ssteam[64];
					GetClientAuthString(iclient, ssteam, sizeof(ssteam));
					if (StrEqual(ssteam, sqlsteam, false))
					{
						if (iWatchlistAnnounce >= 2)
						{
							decl String:sname[MAX_NAME_LENGTH];
							decl String:sqlreason[256];
							decl String:stext[256];
							GetClientName(iclient, sname, sizeof(sname));
							SQL_FetchString(hndl, 4, sqlreason, sizeof(sqlreason));
							Format(stext, sizeof(stext), "%T", "Watchlist_Timer_Announce", LANG_SERVER, sname, ssteam, sqlreason);
							PrintToAdmins(stext);
						}
					}
					else
					{
						DeactivateClient(sqlsteam);
					}
				}
				else
				{
					DeactivateClient(sqlsteam);
				}
			}
			else
			{
				DeactivateClient(sqlsteam);
			}
		}
	}
}

public PrintToAdmins(String:stext[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i) && !IsClientTimingOut(i))
		{
			if (GetUserFlagBits(i) & iadmin)
			{
				PrintToChat(i, "%s", stext);
				if (IsSoundOn)
				{
					EmitSoundToClient(i, WatchlistSound);
				}
			}
		}	
	}
}

public DeactivateClient(String:sqlsteam[])
{
	decl String:squery[256];
	Format(squery, sizeof(squery), "UPDATE watchlist2 SET ingame = 0, serverip = '0.0.0.0', serverport = '00000' WHERE steamid = '%s'", sqlsteam);
	SQL_TQuery(Database, sqlT_Generic, squery);
}

public OnMapStart()
{
	PrecacheSound(WatchlistSound, true);
	if (iprune > 0)
	{
		decl String:squery[256];
		if(IsMYSQL)
		{
			Format(squery, sizeof(squery), "SELECT CURDATE()");
		}
		else
		{
			Format(squery, sizeof(squery), "SELECT date('now')");
		}
		SQL_TQuery(Database, sqlT_PruneDatabase, squery);
	}
}	

public sqlT_PruneDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			decl String:snewdate[25];
			SQL_FetchString(hndl, 0, snewdate, sizeof(snewdate));
			new Handle:dbprune = CreateDataPack();
			WritePackString(dbprune, snewdate);
			decl String:squery[256];
			Format(squery, sizeof(squery), "SELECT stored_date FROM watchlist_info");
			SQL_TQuery(Database, sqlT_PruneDatabaseCmp, squery, dbprune);
		}
	}
}

public sqlT_PruneDatabaseCmp(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		decl String:squery[256];
		if (SQL_FetchRow(hndl))
		{		
			decl String:sqldate[25];
			decl String:newdate[25];
			SQL_FetchString(hndl, 0, sqldate, sizeof(sqldate));
			ResetPack(pack);
			ReadPackString(pack, newdate, sizeof(newdate));
			if (!StrEqual(sqldate, newdate, false))
			{
				PruneDatabase();
				if (IsMYSQL)
				{
					Format(squery, sizeof(squery), "UPDATE watchlist_info SET stored_date = CURDATE()");
				}
				else
				{
					Format(squery, sizeof(squery), "UPDATE watchlist_info SET stored_date = date('now')");
				}
				SQL_TQuery(Database, sqlT_Generic, squery);
			}
		}
		else
		{
			PruneDatabase();
			if (IsMYSQL)
			{
				Format(squery, sizeof(squery), "INSERT INTO watchlist_info (stored_date) VALUES (CURDATE())");
			}
			else
			{
				Format(squery, sizeof(squery), "INSERT INTO watchlist_info (stored_date) VALUES (date('now'))");
			}
			SQL_TQuery(Database, sqlT_Generic, squery);
		}
	}
	CloseHandle(pack);
}

public PruneDatabase()
{
	decl String:squery[256];
	if (IsMYSQL)
	{
		Format(squery, sizeof(squery), "DELETE FROM watchlist2 WHERE DATE_SUB(CURDATE(), INTERVAL %i DAY) >= date", iprune);
	}
	else
	{
		Format(squery, sizeof(squery), "DELETE FROM watchlist2 WHERE date('now', '-%i DAY') >= date", iprune);
	}
	SQL_TQuery(Database, sqlT_Generic, squery);
	if (IsLogOn)
	{
		LogToFile(glogFile, "Database Pruned.");
	}
}

public OnClientPostAdminCheck(iclient)
{
	if (!IsFakeClient(iclient))
	{
		decl String:squery[256];
		new iuserid = GetClientUserId(iclient);
		if (GetUserFlagBits(iclient) & iadmin)
		{
			if (IsAdminJoinOn)
			{
				Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE serverip = '%s' AND serverport = '%s' AND ingame > 0", gServerIp, gServerPort);
				SQL_TQuery(Database, sqlT_AdminJoinQuery, squery, iuserid);
			}
		}
		else
		{
			decl String:ssteam[64];
			decl String:sqlsteam[130];
			GetClientAuthString(iclient, ssteam, sizeof(ssteam));
			SQL_EscapeString(Database, ssteam, sqlsteam, sizeof(sqlsteam));
			Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE steamid = '%s'", sqlsteam); 
			SQL_TQuery(Database, sqlT_CheckUser, squery, iuserid);
		}
	}
}

public sqlT_AdminJoinQuery(Handle:owner, Handle:hndl, const String:error[], any:iuserid)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		decl String:stext[256];
		new iclient = GetClientOfUserId(iuserid);
		if (iclient != 0)
		{
			Format(stext, sizeof(stext), "%T", "Watchlist_Query_Header", iclient);
			new bool:nodata = true;
			PrintToConsole(iclient, stext);
			while (SQL_FetchRow(hndl))
			{
				decl String:sqlsteamid[130];
				decl String:sqlname[100];
				decl String:sqlreason[256];
				decl String:sqldate[25];
				SQL_FetchString(hndl, 1, sqlsteamid, sizeof(sqlsteamid));
				SQL_FetchString(hndl, 5, sqlname, sizeof(sqlname));
				SQL_FetchString(hndl, 4, sqlreason, sizeof(sqlreason));
				SQL_FetchString(hndl, 7, sqldate, sizeof(sqldate));
				PrintToConsole(iclient, "%s, %s, %s, %s", sqlsteamid, sqlname, sqldate, sqlreason);
				if (nodata)
				{
					nodata = false;
				}
			}
			if (nodata)
			{
				PrintToConsole(iclient, "%T", "Watchlist_Query_Empty", iclient);
			}
			else
			{
				PrintToChat(iclient, "%t", "Watchlist_Admin_Join", iclient);
				if (IsSoundOn)
				{
					EmitSoundToClient(iclient, WatchlistSound);
				}
			}
			PrintToConsole(iclient, stext);
		}
	}
}

public sqlT_CheckUser(Handle:owner, Handle:hndl, const String:error[], any:iuserid)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			new iclient = GetClientOfUserId(iuserid); 
			if (iclient != 0)
			{
				if (IsClientConnected(iclient) && !IsFakeClient(iclient) && IsClientInGame(iclient) && !IsClientTimingOut(iclient) && !IsClientInKickQueue(iclient))
				{
					decl String:sname[MAX_NAME_LENGTH];
					decl String:sqlname[100];	
					decl String:ssteam[64];
					decl String:sqlsteam[130];
					decl String:sqlreason[512];
					decl String:squery[256];
					decl String:stext[256];
					GetClientName(iclient, sname, sizeof(sname));
					SQL_EscapeString(Database, sname, sqlname, sizeof(sqlname));
					GetClientAuthString(iclient, ssteam, sizeof(ssteam));
					SQL_EscapeString(Database, ssteam, sqlsteam, sizeof(sqlsteam));
					SQL_FetchString(hndl, 4, sqlreason, sizeof(sqlreason));
					Format(stext, sizeof(stext), "%T", "Watchlist_Player_Join", LANG_SERVER, sname, sqlsteam, sqlreason);
					if ((iWatchlistAnnounce == 1) || (iWatchlistAnnounce == 3))
					{
						PrintToAdmins(stext);
					}
					if (IsLogOn)
					{
						LogToFile(glogFile, stext);
					}
					if (IsMYSQL)
					{
						Format(squery, sizeof(squery), "UPDATE watchlist2 SET ingame = %i, serverip = '%s', serverport = '%s', name = '%s', date_last_seen = CURDATE() WHERE steamid = '%s'", iuserid, gServerIp, gServerPort, sqlname, sqlsteam);
					}
					else
					{	
						Format(squery, sizeof(squery), "UPDATE watchlist2 SET ingame = %i, serverip = '%s', serverport = '%s', name = '%s', date_last_seen = date('now') WHERE steamid = '%s'", iuserid, gServerIp, gServerPort, sqlname, sqlsteam);
					}
					SQL_TQuery(Database, sqlT_Generic, squery);
				}
			}
		}
	}
}

public OnClientDisconnect(iclient)
{
	if (!IsFakeClient(iclient))
	{
		decl String:sname[MAX_NAME_LENGTH];
		decl String:ssteam[64];
		decl String:sqlsteam[130];
		decl String:squery[256];
		GetClientName(iclient, sname, sizeof(sname));
		GetClientAuthString(iclient, ssteam, sizeof(ssteam));
		SQL_EscapeString(Database, ssteam, sqlsteam, sizeof(sqlsteam));
		Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE steamid = '%s'", sqlsteam);
		new Handle:clientdc = CreateDataPack();
		WritePackString(clientdc, sqlsteam);
		WritePackString(clientdc, sname);
		SQL_TQuery(Database, sqlT_ClientDC, squery, clientdc);	
	}
}

public sqlT_ClientDC(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			decl String:sqlsteam[130];
			decl String:sname[100];
			decl String:stext[256];
			ResetPack(pack);
			ReadPackString(pack, sqlsteam, sizeof(sqlsteam));
			ReadPackString(pack, sname, sizeof(sname));
			Format(stext, sizeof(stext), "%T", "Watchlist_Player_Leave", LANG_SERVER, sname, sqlsteam);
			if ((iWatchlistAnnounce == 1) || (iWatchlistAnnounce == 3))
			{
				PrintToAdmins(stext);
			}
			if (IsLogOn)
			{
				LogToFile(glogFile, stext);
			}
			DeactivateClient(sqlsteam);
		}
	}
	CloseHandle(pack);
}
	
public Action:Command_Watchlist_Query (iclient, args)
{
	decl String:squery[256];
	if (GetCmdArgs() > 0)
	{
		decl String:ssteam[64];
		GetCmdArg(1, ssteam, sizeof(ssteam));
		if (StrEqual(ssteam, "online", false))
		{
			Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE serverip = '%s' AND serverport = '%s' AND ingame > 0", gServerIp, gServerPort);
		}
		else if (StrContains(ssteam, "STEAM_", false) != -1)
		{
			if (strlen(ssteam) < 10)
			{
				ReplyToCommand(iclient, "USAGE: watchlist_query \"steam_id\". Be sure to use quotes to query a steamid.");
				return Plugin_Handled;
			}
			else
			{
				decl String:sqlsteam[130];
				SQL_EscapeString(Database, ssteam, sqlsteam, sizeof(sqlsteam));
				Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE steamid = '%s'", sqlsteam);
			}
		}
		else
		{
			ReplyToCommand(iclient, "USAGE: watchlist_query \"steam_id | online\". Leave blank to search all.");
			return Plugin_Handled;
		}
	}
	else
	{
		Format(squery, sizeof(squery), "SELECT * FROM watchlist2");
	}
	SQL_TQuery(Database, sqlT_WatchlistQuery, squery, iclient);
	return Plugin_Handled;
}

public sqlT_WatchlistQuery(Handle:owner, Handle:hndl, const String:error[], any:idata) 
{
	if (hndl == INVALID_HANDLE) 
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		decl String:stext[256];
		Format(stext, sizeof(stext), "%T", "Watchlist_Query_Header", idata);
		new bool:nodata = true;
		PrintToConsole(idata, stext);
		while (SQL_FetchRow(hndl))
		{
			decl String:sqlsteamid[130];
			decl String:sqlname[100];
			decl String:sqlreason[256];
			decl String:sqldate[25];
			SQL_FetchString(hndl, 1, sqlsteamid, sizeof(sqlsteamid));
			SQL_FetchString(hndl, 5, sqlname, sizeof(sqlname));
			SQL_FetchString(hndl, 4, sqlreason, sizeof(sqlreason));
			SQL_FetchString(hndl, 7, sqldate, sizeof(sqldate));
			PrintToConsole(idata, "%s, %s, %s, %s", sqlsteamid, sqlname, sqldate, sqlreason);
			if (nodata)
			{
				nodata = false;
			}
		}
		if (nodata)
		{
			PrintToConsole(idata, "%T", "Watchlist_Query_Empty", idata);
		}
		PrintToConsole(idata, stext);
	}
}

public Action:Command_Watchlist_Add (iclient, args) 
{
	if (GetCmdArgs() < 2) 
	{
		ReplyToCommand(iclient, "USAGE: watchlist_add \"steam_id | #userid | name\" \"reason\"");
		return Plugin_Handled;
	}
	else
	{
		decl String:splayerid[64];
		decl String:ssteam[64];
		new itarget = -1;
		GetCmdArg(1, splayerid, sizeof(splayerid));
		if (StrContains(splayerid, "STEAM_", false) != -1)
		{
			if (strlen(splayerid) < 10)
			{
				ReplyToCommand(iclient, "USAGE: watchlist_add \"steam_id | #userid | name\" \"reason\"");
				return Plugin_Handled;
			}
			else
			{
				ssteam = splayerid;
			}
		}
		else
		{
			itarget = FindTarget(iclient, splayerid);
			if (itarget > 0)
			{
				GetClientAuthString(itarget, ssteam, sizeof(ssteam));
			}
			else
			{
				ReplyToTargetError(iclient, COMMAND_TARGET_NOT_IN_GAME);
				return Plugin_Handled;
			}
		}
		decl String:sreason[256];
		decl String:pclient[25];
		decl String:ptarget[25];
		decl String:sqlsteam[130];
		decl String:squery[256];
		GetCmdArg(2, sreason, sizeof(sreason));
		SQL_EscapeString(Database, ssteam, sqlsteam, sizeof(sqlsteam));
		Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE steamid = '%s'", sqlsteam);
		IntToString(iclient, pclient, sizeof(pclient));
		IntToString(itarget, ptarget, sizeof(ptarget));
		new Handle:CheckWatchlistAddPack = CreateDataPack();
		WritePackString(CheckWatchlistAddPack, pclient);
		WritePackString(CheckWatchlistAddPack, ptarget);
		WritePackString(CheckWatchlistAddPack, sqlsteam);
		WritePackString(CheckWatchlistAddPack, sreason);
		SQL_TQuery(Database, sqlT_CommandWatchlistAdd, squery, CheckWatchlistAddPack);
		return Plugin_Handled;
	}
}

public sqlT_CommandWatchlistAdd(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	if (hndl == INVALID_HANDLE) 
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		decl String:pclient[25];
		decl String:ptarget[25];
		decl String:sqlsteam[130];
		decl String:preason[256];
		decl String:sqlreason[256];
		ResetPack(pack);
		ReadPackString(pack, pclient, sizeof(pclient));
		ReadPackString(pack, ptarget, sizeof(ptarget));
		ReadPackString(pack, sqlsteam, sizeof(sqlsteam));
		ReadPackString(pack, preason, sizeof(preason));
		new iclient = StringToInt(pclient);
		if (SQL_FetchRow(hndl))
		{
			decl String:stext[256];
			SQL_FetchString(hndl, 4, sqlreason, sizeof(sqlreason));
			Format(stext, sizeof(stext), "%T", "Watchlist_Add", iclient, sqlsteam, sqlreason);
			if (iclient > 0)
			{
				PrintToChat(iclient, stext);
			}
			else
			{
				ReplyToCommand(iclient, stext);
			}
		}
		else
		{
			new itarget = StringToInt(ptarget);
			WatchlistAdd(iclient, itarget, sqlsteam, preason);
		}
	}
	CloseHandle(pack);
}

WatchlistAdd(iclient, itarget, String:sqlsteam[], String:sreason[]) 
{
	decl String:pclient[25];
	decl String:sqlreason[512];
	decl String:squery[512];
	SQL_EscapeString(Database, sreason, sqlreason, sizeof(sqlreason));
	if (itarget > 0) 
	{
		decl String:splayer_name[MAX_NAME_LENGTH];
		decl String:sqlplayer_name[101];
		GetClientName(itarget, splayer_name, sizeof(splayer_name));
		SQL_EscapeString(Database, splayer_name, sqlplayer_name, sizeof(sqlplayer_name));
		new iuserid = 0;
		if (IsClientConnected(itarget))
		{
			iuserid = GetClientUserId(itarget);
		}
		if (IsMYSQL)
		{
			Format(squery, sizeof(squery), "INSERT INTO watchlist2 (ingame, steamid, serverip, serverport, reason, name, date, date_last_seen) VALUES (%i, '%s', '%s', '%s', '%s', '%s', CURDATE(), CURDATE())", iuserid, sqlsteam, gServerIp, gServerPort, sqlreason, sqlplayer_name);
		}
		else
		{
			Format(squery, sizeof(squery), "INSERT INTO watchlist2 (ingame, steamid, serverip, serverport, reason, name, date, date_last_seen) VALUES (%i, '%s', '%s', '%s', '%s', '%s', date('now'), date('now'))", iuserid, sqlsteam, gServerIp, gServerPort, sqlreason, sqlplayer_name);
		}
	}
	else
	{
		if (IsMYSQL)
		{
			Format(squery, sizeof(squery), "INSERT INTO watchlist2 (ingame, steamid, serverip, serverport, reason, name, date, date_last_seen) VALUES (%i, '%s', '0.0.0.0', '00000', '%s', 'unknown', CURDATE(), CURDATE())", itarget, sqlsteam, sqlreason);
		}
		else
		{
			Format(squery, sizeof(squery), "INSERT INTO watchlist2 (ingame, steamid, serverip, serverport, reason, name, date, date_last_seen) VALUES (%i, '%s', '0.0.0.0', '00000', '%s', 'unknown', date('now'), date('now'))", itarget, sqlsteam, sqlreason);
		}
	}
	IntToString(iclient, pclient, sizeof(pclient));
	new Handle:WatchlistAddPack = CreateDataPack();
	WritePackString(WatchlistAddPack, pclient);
	WritePackString(WatchlistAddPack, sqlsteam);
	WritePackString(WatchlistAddPack, sqlreason);
	SQL_TQuery(Database, sqlT_WatchlistAdd, squery, WatchlistAddPack);
}

public sqlT_WatchlistAdd(Handle:owner, Handle:hndl, const String:error[], any:pack) 
{
	decl String:stext[256];
	decl String:pclient[25];
	decl String:sqlsteam[130];
	decl String:sqlreason[256];
	ResetPack(pack);
	ReadPackString(pack, pclient, sizeof(pclient));
	ReadPackString(pack, sqlsteam, sizeof(sqlsteam));
	ReadPackString(pack, sqlreason, sizeof(sqlreason));
	CloseHandle(pack);
	new iclient = StringToInt(pclient);
	if (hndl == INVALID_HANDLE) 
	{	
		Format(stext, sizeof(stext), "%T", "Watchlist_Add_Fail", iclient, sqlsteam);
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		Format(stext, sizeof(stext), "%T", "Watchlist_Add_Success", iclient, sqlsteam, sqlreason);
		if (IsLogOn)
		{
			LogToFile(glogFile, stext);
		}
	}
	ReplyToCommand(iclient, stext);
}

public Action:Command_Watchlist_Remove (iclient, args) 
{
	new itarget = -1;
	if (GetCmdArgs() < 1) 
	{
		ReplyToCommand(iclient, "USAGE: watchlist_remove \"steam_id | #userid | name\"");
		return Plugin_Handled;
	}
	else
	{
		decl String:splayer_id[50];
		decl String:ssteam[64];
		GetCmdArg(1, splayer_id, sizeof(splayer_id));
		if (StrContains(splayer_id, "STEAM_", false) != -1)
		{
			if (strlen(splayer_id) < 10)
			{
				ReplyToCommand(iclient, "USAGE: watchlist_remove \"steam_id | #userid | name\"");
				return Plugin_Handled;
			}
			else
			{
				ssteam = splayer_id;
			}
		}
		else
		{
			itarget = FindTarget(iclient, splayer_id);
			if (itarget > 0)
			{
				GetClientAuthString(itarget, ssteam, sizeof(ssteam));
			}
			else
			{
				ReplyToTargetError(iclient, COMMAND_TARGET_NOT_IN_GAME);
				return Plugin_Handled;
			}
		}
		decl String:pclient[25];
		decl String:sqlsteam[130];
		decl String:squery[256];
		IntToString(iclient, pclient, sizeof(pclient));
		SQL_EscapeString(Database, ssteam, sqlsteam, sizeof(sqlsteam));
		Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE steamid = '%s'", sqlsteam);
		new Handle:CheckWatchlistRemovePack = CreateDataPack();
		WritePackString(CheckWatchlistRemovePack, pclient);
		WritePackString(CheckWatchlistRemovePack, sqlsteam);
		SQL_TQuery(Database, sqlT_CommandWatchlistRemove, squery, CheckWatchlistRemovePack);
		return Plugin_Handled;
	}
}

public sqlT_CommandWatchlistRemove(Handle:owner, Handle:hndl, const String:error[], any:pack) 
{
	if (hndl == INVALID_HANDLE) 
	{
		if (IsLogOn)
		{
			decl String:stext[256];
			Format(stext, sizeof(stext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, stext);
		}
	}
	else
	{
		decl String:pclient[25];
		decl String:sqlsteam[130];
		ResetPack(pack);
		ReadPackString(pack, pclient, sizeof(pclient));
		ReadPackString(pack, sqlsteam, sizeof(sqlsteam));
		new iclient = StringToInt(pclient);
		if (SQL_FetchRow(hndl))
		{
			WatchlistRemove(iclient, sqlsteam);
		}
		else
		{
			decl String:stext[256];
			Format(stext, sizeof(stext), "%T", "Watchlist_Remove", iclient, sqlsteam);
			if (iclient > 0)
			{
				PrintToChat(iclient, stext);
			}
			else
			{
				ReplyToCommand(iclient, stext);
			}
		}
	}
	CloseHandle(pack);
}

WatchlistRemove(iclient, String:sqlsteam[]) 
{
	decl String:pclient[25];
	decl String:squery[256];
	Format(squery, sizeof(squery), "DELETE FROM watchlist2 WHERE steamid = '%s'", sqlsteam);	
	IntToString(iclient, pclient, sizeof(pclient));
	new Handle:WatchlistRemovePack = CreateDataPack();
	WritePackString(WatchlistRemovePack, pclient);
	WritePackString(WatchlistRemovePack, sqlsteam);
	SQL_TQuery(Database, sqlT_WatchlistRemove, squery, WatchlistRemovePack);
}

public sqlT_WatchlistRemove(Handle:owner, Handle:hndl, const String:error[], any:pack) 
{
	decl String:stext[256];
	decl String:pclient[25];
	decl String:sqlsteam[130];
	ResetPack(pack);
	ReadPackString(pack, pclient, sizeof(pclient));
	ReadPackString(pack, sqlsteam, sizeof(sqlsteam));
	CloseHandle(pack);
	new iclient = StringToInt(pclient);
	if (hndl == INVALID_HANDLE) 
	{
		Format(stext, sizeof(stext), "%T", "Watchlist_Remove_Fail", iclient, sqlsteam);
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else 
	{
		Format(stext, sizeof(stext), "%T", "Watchlist_Remove_Success", iclient, sqlsteam);
		if (IsLogOn)
		{
			LogToFile(glogFile, stext);
		}
	}
	if (iclient > 0)
	{
		PrintToChat(iclient, stext);
	}
	else
	{
		ReplyToCommand(iclient, stext);
	}
}

public WatchlistAnnounceIntChange(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	if (WatchlistTimer != INVALID_HANDLE)
	{
		CloseHandle(WatchlistTimer);
	}
	WatchlistTimer = CreateTimer(StringToInt(newVal) * 60.0, ShowWatchlist, INVALID_HANDLE, TIMER_REPEAT);	
}

public WatchlistSoundChange(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{
	if (GetConVarBool(cvar))
	{
		IsSoundOn = true;
	}
	else
	{
		IsSoundOn = false;
	}
}

public WatchlistLogChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (GetConVarBool(cvar))
	{
		IsLogOn = true;
	}
	else
	{
		IsLogOn = false;
	}
}

public WatchlistAdminChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	iadmin = ReadFlagString(newVal);
	AddCommandOverride("watchlist_query", Override_Command, iadmin);
	AddCommandOverride("watchlist_add", Override_Command, iadmin);
	AddCommandOverride("watchlist_remove", Override_Command, iadmin);
}

public WatchlistAnnounceChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new inewVal = GetConVarInt(cvar);
	if (inewVal <= 0)
	{
		iWatchlistAnnounce = 0;
	}
	else if (inewVal >= 3)
	{
		iWatchlistAnnounce = 3;
	}
	else
	{
		iWatchlistAnnounce = inewVal;
	}
}

public WatchlistPruneChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	iprune = GetConVarInt(cvar);
}

public AnnounceAdminJoinChange(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	if (GetConVarBool(cvar))
	{
		IsAdminJoinOn = true;
	}
	else
	{
		IsAdminJoinOn = false;
	}
}

public OnAllPluginsLoaded() 
{
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);	
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	hTopMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "watchlist_add", TopMenuObject_Item, MenuWatchlistAdd, player_commands, "watchlist_add");
		AddToTopMenu(hTopMenu, "watchlist_remove", TopMenuObject_Item, MenuWatchlistRemove, player_commands, "watchlist_remove");		 
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public MenuWatchlistAdd(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)	
	{
		Format(buffer, maxlength, "%T", "Watchlist_Add_Menu", param, param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		WatchlistAddTargetMenu(param);
	}
}

WatchlistAddTargetMenu(iclient) 
{
	new Handle:menu = CreateMenu(MenuWatchlistAddTarget);
	decl String:stitle[100];
	Format(stitle, sizeof(stitle), "%T", "Watchlist_Add_Menu", iclient, iclient);
	SetMenuTitle(menu, stitle);
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu(menu, iclient, false, false);
	DisplayMenu(menu, iclient, MENU_TIME_FOREVER);
}

public MenuWatchlistAddTarget (Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:sinfo[32], String:sname[MAX_NAME_LENGTH];
		new iuserid, itarget;
		GetMenuItem(menu, param2, sinfo, sizeof(sinfo), _, sname, sizeof(sname));
		iuserid = StringToInt(sinfo);
		if ((itarget = GetClientOfUserId(iuserid)) == 0 || !CanUserTarget(param1, itarget))
		{
			ReplyToTargetError(param1, COMMAND_TARGET_NOT_IN_GAME);
		}
		else
		{
			itargets[param1] = itarget;
			WatchlistReasonMenu(param1);
		}
	}
}

WatchlistReasonMenu(iclient) 
{
	new Handle:menu = CreateMenu(WatchlistAddReasonMenu);
	decl String:stitle[100];
	Format(stitle, sizeof(stitle), "%T", "Watchlist_Add_Menu", iclient, iclient);
	SetMenuTitle(menu, stitle);
	SetMenuExitBackButton(menu, true);	
	AddMenuItem(menu, "Aimbot", "Aimbot");
	AddMenuItem(menu, "Speedhack", "Speedhack");
	AddMenuItem(menu, "Spinbot", "Spinbot");
	AddMenuItem(menu, "Team Killing", "Team Killing");
	AddMenuItem(menu, "Mic Spam", "Mic Spam");
	AddMenuItem(menu, "Breaking server rules", "Breaking server rules");
	DisplayMenu(menu, iclient, MENU_TIME_FOREVER);
}

public WatchlistAddReasonMenu (Handle:menu, MenuAction:action, param1, param2) 
{	
	if (action == MenuAction_End)
	{		
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:sreason[256];
		decl String:sreason_name[256];
		decl String:ssteam[64];
		decl String:sqlsteam[130];
		decl String:squery[256];
		decl String:pclient[25];
		decl String:ptarget[25];
		new itarget = itargets[param1];
		GetClientAuthString(itarget, ssteam, sizeof(ssteam));
		GetMenuItem(menu, param2, sreason, sizeof(sreason), _, sreason_name, sizeof(sreason_name));
		SQL_EscapeString(Database, ssteam, sqlsteam, sizeof(sqlsteam));
		Format(squery, sizeof(squery), "SELECT * FROM watchlist2 WHERE steamid = '%s'", sqlsteam);
		IntToString(param1, pclient, sizeof(pclient));
		IntToString(itarget, ptarget, sizeof(ptarget));
		new Handle:CheckWatchlistAddReasonMenu = CreateDataPack();
		WritePackString(CheckWatchlistAddReasonMenu, pclient);
		WritePackString(CheckWatchlistAddReasonMenu, ptarget);
		WritePackString(CheckWatchlistAddReasonMenu, sqlsteam);
		WritePackString(CheckWatchlistAddReasonMenu, sreason);
		SQL_TQuery(Database, sqlT_CommandWatchlistAdd, squery, CheckWatchlistAddReasonMenu);
	}	
}

public MenuWatchlistRemove(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Watchlist_Remove_Menu", param, param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		FindWatchlistTargetsMenu(param);
	}
}

FindWatchlistTargetsMenu(iclient) 
{
	decl String:squery[256];
	Format(squery, sizeof(squery), "SELECT * FROM watchlist2");
	SQL_TQuery(Database, sqlWatchlistRemoveTargetMenu, squery, iclient);
}

public sqlWatchlistRemoveTargetMenu(Handle:owner, Handle:hndl, const String:error[], any:idata)
{
	if (hndl == INVALID_HANDLE)
	{
		if (IsLogOn)
		{
			decl String:ltext[256];
			Format(ltext, sizeof(ltext), "%T", "ERROR2", LANG_SERVER, error);
			LogToFile(glogFile, ltext);
		}
	}
	else
	{
		new Handle:menu = CreateMenu(MenuWatchlistRemoveTarget);
		decl String:stitle[100];
		Format(stitle, sizeof(stitle), "%T", "Watchlist_Remove_Menu", idata, idata);
		SetMenuTitle(menu, stitle);
		SetMenuExitBackButton(menu, true);
		new bool:noClients = true;
		while (SQL_FetchRow(hndl))
		{
			decl String:starget[130];
			decl String:sname[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 5, sname, sizeof(sname));
			SQL_FetchString(hndl, 1, starget, sizeof(starget));
			AddMenuItem(menu, starget, sname);
			if (noClients)
			{
				noClients = false;
			}
		}
		if (noClients)
		{
			decl String:stext[256];
			Format(stext, sizeof(stext), "%T", "Watchlist_Query_Empty", idata);
			AddMenuItem(menu, "noClients", stext);
		}
		DisplayMenu(menu, idata, MENU_TIME_FOREVER);		
	}
}

public MenuWatchlistRemoveTarget(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:starget[130];
		decl String:sjunk[256];
		GetMenuItem(menu, param2, starget, sizeof(starget), _, sjunk, sizeof(sjunk));
		if (strcmp(starget, "noClients", true) == 0) 
		{
			return;
		}
		else
		{
			decl String:sqlsteam[130];
			SQL_EscapeString(Database, starget, sqlsteam, sizeof(sqlsteam));
			WatchlistRemove(param1, sqlsteam);
		}
	}
}





