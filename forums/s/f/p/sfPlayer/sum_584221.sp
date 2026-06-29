/***
 * This program has been released under the terms of the GPL v3 (http://www.gnu.org/licenses/gpl-3.0.txt)
 *
 * Version 1.5.0 released 2008-02-25
 */

#include <sourcemod>

#pragma semicolon 1

#define ADM_PERM_NONE 0
#define ADM_PERM_LIGHT 4079 // no unban, cheats, rcon, root
#define ADM_PERM_DEFAULT 12287 // no rcon, root
#define ADM_PERM_FULL 16383 // no root
#define ADM_PERM_ROOT 32767

#define MANI_SUPPORT 1
#define CHATMESSAGES 1
#define CONSOLEMESSAGES 1

#define STEAMID_LENGTH 30
enum DatabaseIdent {
	DBIdent_Unknown,
	DBIdent_MySQL,
	DBIdent_SQLite,
};

public Plugin:myinfo = {
	name = "SUM - global admins, bans and antifake",
	author = "sfPlayer",
	description = "Handles bans, admins and nicks for multiple servers",
	version = "1.5.0",
	url = "http://www.player.to/"
}

#if MANI_SUPPORT
new bool:maniPresent = false;
#endif
new Handle:hDatabase = INVALID_HANDLE;
new DatabaseIdent:databaseIdent = DBIdent_Unknown;
 
public OnPluginStart() {
	SQL_TConnect(gotDatabase, "sumdb");
	RegAdminCmd("sum_setup", sum_setup, ADMFLAG_ROOT, "Create and configure the SUM Database");
	RegAdminCmd("sum_stats", sum_stats, ADMFLAG_RCON, "Shows SUM statistics");
	RegAdminCmd("sum_setadmin", sum_setadmin, ADMFLAG_ROOT, "Sets global admin permissions for SUM");
	RegConsoleCmd("sum_admins", sum_admins, "List SUM admins");
	RegConsoleCmd("sum_banlog", sum_banlog, "List previous bans");
}

public OnMapStart() {
	if (hDatabase == INVALID_HANDLE) {
		SQL_TConnect(gotDatabase, "sumdb");
	}
}
 
public gotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE) {
		LogError("SUM: Database failure: %s", error);
	} else {
		hDatabase = hndl;

		decl String:dbIdent[20];
		new Handle:DBDrv = SQL_ReadDriver(hDatabase, dbIdent, sizeof(dbIdent));
		CloseHandle(DBDrv);
		if (StrEqual(dbIdent, "mysql")) {
			databaseIdent = DBIdent_MySQL;
		} else if (StrEqual(dbIdent, "sqlite")) {
			databaseIdent = DBIdent_SQLite;
		} else {
			databaseIdent = DBIdent_Unknown;
		}
	}
}

public OnClientDisconnect(client) {
	decl String:auth[STEAMID_LENGTH];
	GetClientAuthString(client, auth, sizeof(auth));
#if MANI_SUPPORT
	if (maniPresent) {
		ServerCommand("ma_client RemoveClient sum%s", auth);
	}
#endif
#if CONSOLEMESSAGES
	decl String:name[MAX_NAME_LENGTH+1];
	GetClientName(client, name, sizeof(name)); 

	decl String:buffer[100];
	Format(buffer, sizeof(buffer), "%s left, SteamID %s", name, auth);
	PrintToConsoleAll(buffer);
#endif
}

public OnClientAuthorized(client, const String:auth[]) {
	if (hDatabase != INVALID_HANDLE) {
		checkSteamID(GetClientUserId(client), auth);
	}
#if CONSOLEMESSAGES
	decl String:name[MAX_NAME_LENGTH+1];
	GetClientName(client, name, sizeof(name)); 

	decl String:buffer[100];
	Format(buffer, sizeof(buffer), "%s joined, SteamID %s", name, auth);
	PrintToConsoleAll(buffer);
#endif
}

#if CHATMESSAGES
public OnClientPostAdminCheck(client) {
	if (hDatabase != INVALID_HANDLE) {
		decl String:auth[STEAMID_LENGTH];
		GetClientAuthString(client, auth, sizeof(auth));
		decl String:newquery[255];
		Format(newquery, sizeof(newquery), "SELECT name, bancount FROM clientname n, client c WHERE n.steamid = '%s' AND c.steamid = n.steamid ORDER BY count DESC LIMIT 3;", auth);
		SQL_TQuery(hDatabase, T_queryNames, newquery, GetClientUserId(client));
	}
}
#endif

public Action:sum_setup(client, args) {
	if (args != 1 && args != 5 && args != 6) {
		ReplyToCommand(client, "SUM: Usage: sum_setup mysql <host> <database> <user> <password> [<port>] or sum_setup sqlite (local only)");
		return Plugin_Handled;
	}

	decl String:dbIdent[7];
	GetCmdArg(1, dbIdent, sizeof(dbIdent));

	new Handle:kvHandle = CreateKeyValues("Databases");
	decl String:kvFileName[255];
	BuildPath(Path_SM, kvFileName, sizeof(kvFileName), "configs/databases.cfg");
	FileToKeyValues(kvHandle, kvFileName);

	if (StrEqual(dbIdent, "mysql")) {
		if (args < 5) {
			ReplyToCommand(client, "SUM: Usage: sum_setup mysql <host> <database> <user> <password> [<port>] or sum_setup sqlite (local only)");
			CloseHandle(kvHandle);
			return Plugin_Handled;
		}

		decl String:dbHost[32];
		GetCmdArg(2, dbHost, sizeof(dbHost));
		decl String:dbDatabase[32];
		GetCmdArg(3, dbDatabase, sizeof(dbDatabase));
		decl String:dbUser[32];
		GetCmdArg(4, dbUser, sizeof(dbUser));
		decl String:dbPassword[32];
		GetCmdArg(5, dbPassword, sizeof(dbPassword));

		new dbPort = 0;
		if (args == 6) {
			decl String:dbsPort[6];
			GetCmdArg(6, dbsPort, sizeof(dbsPort));
			dbPort = StringToInt(dbsPort);
		}

		decl String:err[128];

		new Handle:dbDrvHandle = SQL_GetDriver("mysql");
		if (dbDrvHandle == INVALID_HANDLE) {
			ReplyToCommand(client, "SUM: Error: The MySQL driver (SM extension) is not available");
			CloseHandle(kvHandle);
			return Plugin_Handled;
		}

		new Handle:dbConnection = SQL_ConnectEx(dbDrvHandle, dbHost, dbUser, dbPassword, dbDatabase, err, sizeof(err), false, dbPort, 10);
		if (dbConnection == INVALID_HANDLE) {
			ReplyToCommand(client, "SUM: Error: The MySQL configuration is invalid (%s)", err);
			CloseHandle(dbDrvHandle);
			CloseHandle(kvHandle);
			return Plugin_Handled;
		} else {
			decl String:queryStr[70];
			Format(queryStr, sizeof(queryStr), "CREATE DATABASE IF NOT EXISTS %s;", dbDatabase);
			SQL_FastQuery(dbConnection, queryStr);

			if (!SQL_FastQuery(dbConnection, "CREATE TABLE `banlog` (`target` varchar(30) NOT NULL,`creator` varchar(30) NOT NULL,`time` int(10) unsigned NOT NULL,`duration` int(10) unsigned NOT NULL,`reason` varchar(64) NOT NULL,KEY `target` (`target`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;") || !SQL_FastQuery(dbConnection, "CREATE TABLE `client` (`steamid` varchar(30) NOT NULL,`admin` int(10) unsigned NOT NULL default '0',`banneduntil` int(10) unsigned NOT NULL default '0',`bancount` int(10) unsigned NOT NULL default '0',`connectcount` int(10) unsigned NOT NULL default '0',`lastconnect` int(10) unsigned NOT NULL default '0',PRIMARY KEY  (`steamid`),KEY `admin` (`admin`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;") || !SQL_FastQuery(dbConnection, "CREATE TABLE `clientname` (`steamid` varchar(30) NOT NULL,`name` varchar(64) NOT NULL,`count` int(10) unsigned NOT NULL default '0',PRIMARY KEY  (`steamid`,`name`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;")) {
				if (SQL_GetError(dbConnection, err, sizeof(err))) {
					ReplyToCommand(client, "SUM: Error: Can't create database (%s)", err);
				}
				CloseHandle(dbConnection);
				CloseHandle(dbDrvHandle);
				CloseHandle(kvHandle);
				return Plugin_Handled;
			}
			CloseHandle(dbConnection);
			CloseHandle(dbDrvHandle);
		}

		KvJumpToKey(kvHandle, "sumdb", true);
		KvSetString(kvHandle, "driver", "mysql");
		KvSetString(kvHandle, "host", dbHost);
		KvSetString(kvHandle, "database", dbDatabase);
		KvSetString(kvHandle, "user", dbUser);
		KvSetString(kvHandle, "pass", dbPassword);
		if (dbPort != 0) KvSetNum(kvHandle, "port", dbPort);
	} else if (StrEqual(dbIdent, "sqlite")) {
		decl String:err[128];

		new Handle:dbDrvHandle = SQL_GetDriver("sqlite");
		if (dbDrvHandle == INVALID_HANDLE) {
			ReplyToCommand(client, "SUM: Error: The SQLite driver (SM extension) is not available");
			CloseHandle(kvHandle);
			return Plugin_Handled;
		}

		new Handle:dbConnection = SQL_ConnectEx(dbDrvHandle, "", "", "", "sumdb", err, sizeof(err), false, 0, 10);
		if (dbConnection == INVALID_HANDLE) {
			ReplyToCommand(client, "SUM: Error: The SQLite configuration is invalid (%s)", err);
			CloseHandle(dbDrvHandle);
			CloseHandle(kvHandle);
			return Plugin_Handled;
		} else {
			if (!SQL_FastQuery(dbConnection, "CREATE TABLE banlog (target varchar(30) NOT NULL,creator varchar(30) NOT NULL,time unsigned int(10) NOT NULL,duration unsigned int(10) NOT NULL,reason varchar(64) NOT NULL,KEY target);") || !SQL_FastQuery(dbConnection, "CREATE TABLE client (steamid varchar(30) NOT NULL,admin unsigned int(10) NOT NULL default '0',banneduntil unsigned int(10) NOT NULL default '0',bancount unsigned int(10) NOT NULL default '0',connectcount unsigned int(10) NOT NULL default '0',lastconnect unsigned int(10) NOT NULL default '0',PRIMARY KEY (steamid));") || !SQL_FastQuery(dbConnection, "CREATE TABLE clientname (steamid varchar(30) NOT NULL,name varchar(64) NOT NULL,count unsigned int(10) NOT NULL default '0',PRIMARY KEY (steamid,name));")) {
				if (SQL_GetError(dbConnection, err, sizeof(err))) {
					ReplyToCommand(client, "SUM: Error: Can't create database (%s)", err);
				}
				CloseHandle(dbConnection);
				CloseHandle(dbDrvHandle);
				CloseHandle(kvHandle);
				return Plugin_Handled;
			}
			CloseHandle(dbConnection);
			CloseHandle(dbDrvHandle);
		}

		KvJumpToKey(kvHandle, "sumdb", true);
		KvSetString(kvHandle, "driver", "sqlite");
		KvSetString(kvHandle, "database", "sumdb");
	} else {
		ReplyToCommand(client, "SUM: Usage: sum_setup mysql <host> <database> <user> <password> [<port>] or sum_setup sqlite (local only)");
		CloseHandle(kvHandle);
		return Plugin_Handled;
	}

	KvRewind(kvHandle);
	if (KeyValuesToFile(kvHandle, kvFileName)) {
		ReplyToCommand(client, "SUM: Database setup successful, change the map to activate it");
	} else {
		ReplyToCommand(client, "SUM: Error: Can't write database config, configure it manually");
	}

	CloseHandle(kvHandle);
	return Plugin_Handled;
}

public Action:sum_stats(client, args) {
	if (hDatabase == INVALID_HANDLE) {
		ReplyToCommand(client, "SUM: Database offline");
	} else {
		SQL_LockDatabase(hDatabase);

		new Handle:query = SQL_Query(hDatabase, "SELECT COUNT(*) FROM client UNION ALL SELECT COUNT(*) FROM client WHERE admin > 0 UNION ALL SELECT COUNT(*) FROM clientname;");
		if (query != INVALID_HANDLE && SQL_FetchRow(query)) {
			new users = SQL_FetchInt(query, 0);
			SQL_FetchRow(query);
			new admins = SQL_FetchInt(query, 0);
			SQL_FetchRow(query);
			new names = SQL_FetchInt(query, 0);
			CloseHandle(query);

			ReplyToCommand(client, "SUM: Database online\n\n%d users (%d admins)\n%d names", users, admins, names);
		} else {
			decl String:err[128];
			SQL_GetError(hDatabase, err, sizeof(err));
			ReplyToCommand(client, "SUM: Database error: %s", err);
		}

		SQL_UnlockDatabase(hDatabase);
	}

	return Plugin_Handled;
}

public Action:sum_admins(client, args) {
	if (hDatabase != INVALID_HANDLE) {
		decl String:queryStr[300];

		if (databaseIdent == DBIdent_MySQL) {
			strcopy(queryStr, sizeof(queryStr), "SELECT cl.steamid, name, admin FROM client cl LEFT JOIN clientname co USING (steamid) WHERE admin>0 AND (connectcount = 0 OR count = (SELECT MAX(count) FROM clientname WHERE clientname.steamid = co.steamid GROUP BY clientname.steamid)) GROUP BY cl.steamid ORDER BY cl.steamid ASC LIMIT 100;");
		} else if (databaseIdent == DBIdent_SQLite) {
			// limitation: doesn't show mostly used name
			strcopy(queryStr, sizeof(queryStr), "SELECT cl.steamid, name, admin FROM client cl LEFT JOIN clientname cn ON (cl.steamid = cn.steamid) WHERE admin>0 GROUP BY cl.steamid ORDER BY cl.steamid ASC LIMIT 100;");
		}

		if (client > 0) {
			SQL_TQuery(hDatabase, T_queryAdmins, queryStr, GetClientUserId(client));
		} else {
			SQL_LockDatabase(hDatabase);
			new Handle:query = SQL_Query(hDatabase, queryStr);

			displayAdminList(query, 0);

			CloseHandle(query);
			SQL_UnlockDatabase(hDatabase);
		}
	} else {
		ReplyToCommand(client, "SUM: Database offline");
	}

	return Plugin_Handled;
}

public Action:sum_banlog(client, args) {
	ReplyToCommand(client, "SUM: Usage: sum_banlog [<name|#userid|steamid|unknown>] [<target|creator>=target]");

	if (hDatabase != INVALID_HANDLE) {
		new String:queryStr[150] = "SELECT target, creator, time, duration, reason FROM banlog %sORDER BY time DESC LIMIT 100;";
		decl String:auth[STEAMID_LENGTH];

		if (args == 0) {
			Format(queryStr, sizeof(queryStr), queryStr, "");
		} else {
			if (args == 1 || args == 2) {
				decl String:arg1[MAX_NAME_LENGTH+1];
				GetCmdArg(1, arg1, sizeof(arg1));

				if (StrEqual(arg1, "unknown", false)) {
					auth = "UNKNOWN";
				} else {
					new target = FindTarget(client, arg1, true, false);
					if (target == -1) return Plugin_Handled;
				
					GetClientAuthString(target, auth, sizeof(auth));
				}
			} else if (args == 5 || args == 6) {
				decl String:argArr[5][11];
				GetCmdArg(1, argArr[0], 11);
				GetCmdArg(2, argArr[1], 11);
				GetCmdArg(3, argArr[2], 11);
				GetCmdArg(4, argArr[3], 11);
				GetCmdArg(5, argArr[4], 11);

				if (StrEqual(argArr[0], "STEAM_0") && StrEqual(argArr[1], ":") && isNumeric(argArr[2]) && StrEqual(argArr[3], ":") && isNumeric(argArr[4])) {
					ImplodeStrings(argArr, 5, "", auth, sizeof(auth));
				} else {
					return Plugin_Handled;
				}
			} else {
				return Plugin_Handled;
			}

			if (args == 2 || args == 6) {
				decl String:arg_target[8];
				GetCmdArg(args, arg_target, sizeof(arg_target));

				if (StrEqual(arg_target, "creator", false)) {
					Format(queryStr, sizeof(queryStr), queryStr, "WHERE creator = '%s' ");
					Format(queryStr, sizeof(queryStr), queryStr, auth);
				} else {
					Format(queryStr, sizeof(queryStr), queryStr, "WHERE target = '%s' ");
					Format(queryStr, sizeof(queryStr), queryStr, auth);
				}
			} else {
				Format(queryStr, sizeof(queryStr), queryStr, "WHERE target = '%s' ");
				Format(queryStr, sizeof(queryStr), queryStr, auth);
			}
		}

		if (client > 0) {
			SQL_TQuery(hDatabase, T_queryBanLog, queryStr, GetClientUserId(client));
		} else {
			SQL_LockDatabase(hDatabase);
			new Handle:query = SQL_Query(hDatabase, queryStr);

			displayBanLog(query, 0);

			CloseHandle(query);
			SQL_UnlockDatabase(hDatabase);
		}
	} else {
		ReplyToCommand(client, "SUM: Database offline");
	}

	return Plugin_Handled;
}

public Action:sum_setadmin(client, args) {
	decl String:arg_string[256];
	GetCmdArgString(arg_string, sizeof(arg_string));

	decl String:arg_pieces[3][STEAMID_LENGTH];

	if (ExplodeString(arg_string, " ", arg_pieces, 3, STEAMID_LENGTH) != 2) {
		ReplyToCommand(client, "SUM: Usage: sum_setadmin <steamid> <permissions|none|light|default|full|root>");
		return Plugin_Handled;
	}

	decl String:auth[STEAMID_LENGTH];
	strcopy(auth, sizeof(auth), arg_pieces[0]);

	if (strncmp(auth, "STEAM_0:", 8) != 0) {
		ReplyToCommand(client, "SUM: Usage: sum_setadmin <steamid> <permissions|none|light|default|full|root>");
		return Plugin_Handled;
	}

	decl String:permissions[11];
	strcopy(permissions, sizeof(permissions), arg_pieces[1]);

	decl admin;

	if (StrEqual(permissions, "none", false)) {
		admin = ADM_PERM_NONE;
	} else if (StrEqual(permissions, "light", false)) {
		admin = ADM_PERM_LIGHT;
	} else if (StrEqual(permissions, "default", false)) {
		admin = ADM_PERM_DEFAULT;
	} else if (StrEqual(permissions, "full", false)) {
		admin = ADM_PERM_FULL;
	} else if (StrEqual(permissions, "root", false)) {
		admin = ADM_PERM_ROOT;
	} else {
		if (StringToIntEx(permissions, admin) != strlen(permissions)) {
			ReplyToCommand(client, "SUM: Usage: sum_setadmin <steamid> <permissions|none|light|default|full|root>");
			return Plugin_Handled;
		}
	}

	if (hDatabase == INVALID_HANDLE) {
		ReplyToCommand(client, "SUM: Error: No database connection, can't add admin.");
		return Plugin_Handled;
	}

	decl String:buffer[sizeof(auth)*2+1];
	SQL_QuoteString(hDatabase, auth, buffer, sizeof(buffer));

	decl String:newquery[150];

	if (databaseIdent == DBIdent_MySQL) {
		Format(newquery, sizeof(newquery), "INSERT INTO client SET admin = '%d', steamid = '%s' ON DUPLICATE KEY UPDATE admin = '%d';", admin, buffer, admin);
		SQL_TQuery(hDatabase, T_ignore, newquery);
	} else if (databaseIdent == DBIdent_SQLite) {
		Format(newquery, sizeof(newquery), "INSERT OR IGNORE INTO client (admin, steamid) VALUES ('%d', '%s');", admin, buffer, DBPrio_High);
		SQL_TQuery(hDatabase, T_ignore, newquery);
		Format(newquery, sizeof(newquery), "UPDATE client SET admin = '%d' WHERE steamid = '%s';", admin, buffer);
		SQL_TQuery(hDatabase, T_ignore, newquery);
	}
	
	return Plugin_Handled;
}

public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source) {
	if (time > 10 || time == 0) {
		decl String:authtarget[STEAMID_LENGTH];
		GetClientAuthString(client, authtarget, sizeof(authtarget));

		executeGlobalBan(source, authtarget, time, reason);
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

public Action:OnBanIdentity(const String:identity[], time, flags, const String:reason[], const String:command[], any:source) {
	if ((time > 10 || time == 0) && (flags & BANFLAG_AUTHID)) {
		executeGlobalBan(source, identity, time, reason);

		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

public Action:OnRemoveBan(const String:identity[], flags, const String:command[], any:source) {
	if ((flags & BANFLAG_AUTHID) && hDatabase != INVALID_HANDLE) {
		decl String:newquery[255];
		Format(newquery, sizeof(newquery), "UPDATE client SET banneduntil = '0' WHERE steamid = '%s';", identity);
		SQL_TQuery(hDatabase, T_ignore, newquery);

		ReplyToCommand(source, "SUM: Global ban removed.");
	}

	return Plugin_Continue;
}

executeGlobalBan(const client, const String:authtarget[], const time, const String:reason[]) {
	if (hDatabase != INVALID_HANDLE) {
		decl String:authcreator[STEAMID_LENGTH];
		if (client == 0 || !GetClientAuthString(client, authcreator, sizeof(authcreator))) {
			strcopy(authcreator, sizeof(authcreator), "UNKNOWN");
		}

		decl expiretime;
		if (time == 0) {
			expiretime = 2147483647; // signed int32 max
		} else {
			expiretime = GetTime() + time*60;
		}

		if (databaseIdent == DBIdent_MySQL) {
			decl String:newquery[200];
			Format(newquery, sizeof(newquery), "INSERT INTO client SET banneduntil = '%d', bancount = '1', steamid = '%s' ON DUPLICATE KEY UPDATE banneduntil = '%d', bancount = bancount+1;", expiretime, authtarget, expiretime);
			SQL_TQuery(hDatabase, T_ignore, newquery);
		} else if (databaseIdent == DBIdent_SQLite) {
			decl String:newquery[200];
			Format(newquery, sizeof(newquery), "INSERT OR IGNORE INTO client (banneduntil, bancount, steamid) VALUES ('%d', '0', '%s');", expiretime, authtarget, DBPrio_High);
			SQL_TQuery(hDatabase, T_ignore, newquery);
			Format(newquery, sizeof(newquery), "UPDATE client SET banneduntil = '%d', bancount = bancount+1 WHERE steamid = '%s';", expiretime, authtarget);
			SQL_TQuery(hDatabase, T_ignore, newquery);
		}

		decl String:buffer[150];
		SQL_QuoteString(hDatabase, reason, buffer, sizeof(buffer));

		decl String:newquery[350];
		Format(newquery, sizeof(newquery), "INSERT INTO banlog (target, creator, time, duration, reason) VALUES ('%s', '%s', '%d', '%d', '%s');", authtarget, authcreator, GetTime(), time, buffer);
		SQL_TQuery(hDatabase, T_ignore, newquery);

		BanIdentity(authtarget, 10, BANFLAG_AUTHID, reason);

		ReplyToCommand(client, "SUM: Global ban executed.");
	}
}

checkSteamID(const userid, const String:auth[]) {
	decl String:newquery[255];
	Format(newquery, sizeof(newquery), "SELECT admin, banneduntil, connectcount FROM client WHERE steamid = '%s';", auth);
	SQL_TQuery(hDatabase, T_querySteamID, newquery, userid);
}
 
public T_querySteamID(Handle:db, Handle:query, const String:error[], any:data) {
	decl client;

	if ((client = GetClientOfUserId(data)) == 0) return;

	decl String:auth[STEAMID_LENGTH];
	GetClientAuthString(client, auth, sizeof(auth));
 
	if (query == INVALID_HANDLE) {
		LogError("SUM: Query failed! %s", error);
	} else if (SQL_GetRowCount(query)) {
		// user already in db

		if (SQL_FetchRow(query)) {
			new admin = SQL_FetchInt(query, 0);
			new banneduntil = SQL_FetchInt(query, 1);
			new connectcount = SQL_FetchInt(query, 2);

			if (banneduntil > GetTime()) {
				KickClient(client, "SUM: You are banned from this server.");
			} else {
				insertClientName(client, auth);

				decl String:newquery[255];
				Format(newquery, sizeof(newquery), "UPDATE client SET connectcount = '%d', lastconnect = '%d' WHERE steamid = '%s';", connectcount+1, GetTime(), auth);
				SQL_TQuery(db, T_ignore, newquery);
			}
			
			if (admin) {
				SetUserFlagBits(client, GetUserFlagBits(client) | admin);
#if MANI_SUPPORT
				checkMani();

				if (maniPresent) {
					new String:maniflags[255] = "";

					if (admin & ADMFLAG_ROOT) {
						StrCat(maniflags, sizeof(maniflags), "+# "); // includes +client +P
					} else {
						if (admin & ADMFLAG_GENERIC) StrCat(maniflags, sizeof(maniflags), "+admin +p +spray ");
						if (admin & ADMFLAG_KICK) StrCat(maniflags, sizeof(maniflags), "+k ");
						if (admin & ADMFLAG_BAN) StrCat(maniflags, sizeof(maniflags), "+b +pban ");
						if (admin & ADMFLAG_SLAY) StrCat(maniflags, sizeof(maniflags), "+I +g +l +m ");
						if (admin & ADMFLAG_CHANGEMAP) StrCat(maniflags, sizeof(maniflags), "+c ");
						if (admin & ADMFLAG_CONVARS) StrCat(maniflags, sizeof(maniflags), "+E ");
						if (admin & ADMFLAG_CONFIG) StrCat(maniflags, sizeof(maniflags), "+J+ q+ q2+ q3 +w +z ");
						if (admin & ADMFLAG_CHAT) StrCat(maniflags, sizeof(maniflags), "+L +a +o +s ");
						if (admin & ADMFLAG_VOTE) StrCat(maniflags, sizeof(maniflags), "+A +B +C +D +Q +R +V +v ");
						if (admin & ADMFLAG_PASSWORD) StrCat(maniflags, sizeof(maniflags), "+H ");
						if (admin & ADMFLAG_RCON) StrCat(maniflags, sizeof(maniflags), "+r +x +y ");
						if (admin & ADMFLAG_CHEATS) StrCat(maniflags, sizeof(maniflags), "+F +G +K +M +N +O +S +T +U +W +X +Y +Z +d +e +grav +i +f +t ");
					}

					ServerCommand("ma_client AddClient sum%s", auth);
					ServerCommand("ma_client AddSteam sum%s %s", auth, auth);
					ServerCommand("ma_client SetAFlag sum%s \"%s\"", auth, maniflags);
				}
#endif
				PrintToConsole(client, "SUM: You have been given admin access.");
			}
		}
	} else {
		// user not in db

		decl String:newquery[255];
		Format(newquery, sizeof(newquery), "INSERT INTO client (steamid, connectcount, lastconnect) VALUES ('%s', '1', '%d');", auth, GetTime());
		SQL_TQuery(hDatabase, T_ignore, newquery);

		insertClientName(client, auth);
	}
}

insertClientName(const client, const String:auth[]) {
	decl String:name[MAX_NAME_LENGTH+1];

	if (GetClientName(client, name, sizeof(name))) {
		decl String:buffer[sizeof(name)*2+1];

		SQL_QuoteString(hDatabase, name, buffer, sizeof(buffer));

		if (databaseIdent == DBIdent_MySQL) {
			decl String:newquery[200];
			Format(newquery, sizeof(newquery), "INSERT INTO clientname (steamid, name, count) VALUES ('%s', '%s', '1') ON DUPLICATE KEY UPDATE count = count+1;", auth, buffer);
			SQL_TQuery(hDatabase, T_ignore, newquery);
		} else if (databaseIdent == DBIdent_SQLite) {
			decl String:newquery[200];
			Format(newquery, sizeof(newquery), "INSERT OR IGNORE INTO clientname (steamid, name, count) VALUES ('%s', '%s', '0');", auth, buffer);
			SQL_TQuery(hDatabase, T_ignore, newquery);
			Format(newquery, sizeof(newquery), "UPDATE clientname SET count = count+1 WHERE steamid = '%s' AND name = '%s';", auth, buffer);
			SQL_TQuery(hDatabase, T_ignore, newquery);
		}
	}
}

#if CHATMESSAGES
public T_queryNames(Handle:db, Handle:query, const String:error[], any:data) {
	decl client;

	if ((client = GetClientOfUserId(data)) == 0) return;

	decl String:auth[STEAMID_LENGTH];
	GetClientAuthString(client, auth, sizeof(auth));
	decl String:name[MAX_NAME_LENGTH+1];
	GetClientName(client, name, sizeof(name)); 

	if (query == INVALID_HANDLE) {
		LogError("SUM: Query failed! %s", error);
	} else if (SQL_GetRowCount(query)) {
		decl banCount;
		new String:namelist[(MAX_NAME_LENGTH+2)*3+2];

		while (SQL_FetchRow(query)) {
			decl String:cname[MAX_NAME_LENGTH+1];
			SQL_FetchString(query, 0, cname, sizeof(cname));
			banCount = SQL_FetchInt(query, 1);

			StrCat(namelist, sizeof(namelist), cname);
			StrCat(namelist, sizeof(namelist), ", ");
		}
		
		namelist[strlen(namelist)-2] = 0;

		if (banCount) {
			PrintToChatAll("SUM: %s (%s) is known as: %s (banned %d time(s) before).", name, auth, namelist, banCount);
		} else {
			PrintToChatAll("SUM: %s (%s) is known as: %s.", name, auth, namelist);
		}
	} else {
		PrintToChatAll("SUM: %s (%s) is not known yet.", name, auth);
	}
}
#endif

public T_queryAdmins(Handle:db, Handle:query, const String:error[], any:data) {
	decl client;

	if ((client = GetClientOfUserId(data)) == 0) return;

	displayAdminList(query, client);
}

public T_queryBanLog(Handle:db, Handle:query, const String:error[], any:data) {
	decl client;

	if ((client = GetClientOfUserId(data)) == 0) return;

	displayBanLog(query, client);
}

public T_ignore(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE) {
		LogError("SUM: Query failed! %s", error);
	}

	// nothing..
}

#if MANI_SUPPORT
checkMani() {
	new Handle:cvMani = INVALID_HANDLE;
	if ((cvMani = FindConVar("mani_admin_plugin_version")) == INVALID_HANDLE) {
		maniPresent = false;
	} else {
		CloseHandle(cvMani);
		maniPresent = true;
	}
}
#endif

displayAdminList(Handle:query, client) {
	if (query == INVALID_HANDLE) {
		LogError("SUM: Query failed!");
	} else if (SQL_GetRowCount(query)) {
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
			ReplyToCommand(client, "SUM: See console for output.");
		}

		new ReplySource:oldReplySource = SetCmdReplySource(SM_REPLY_TO_CONSOLE);

		ReplyToCommand(client, "--- SUM adminlist:");

		while (SQL_FetchRow(query)) {
			decl String:auth[STEAMID_LENGTH];
			SQL_FetchString(query, 0, auth, sizeof(auth));
			decl String:name[MAX_NAME_LENGTH+1];
			SQL_FetchString(query, 1, name, sizeof(name));
			if (strlen(name) == 0) strcopy(name, sizeof(name), "?");
			decl String:adminStr[11];
			SQL_FetchString(query, 2, adminStr, sizeof(adminStr));
			new admin = StringToInt(adminStr);

			decl adminchr;

			switch (admin) {
				case ADM_PERM_LIGHT: {
					adminchr = 'L';
				}
				case ADM_PERM_DEFAULT: {
					adminchr = 'D';
				}
				case ADM_PERM_FULL: {
					adminchr = 'F';
				}
				case ADM_PERM_ROOT: {
					adminchr = 'R';
				}
				default: {
					adminchr = 'C';
				}
			}

			if (steamidInGame(auth)) {
				ReplyToCommand(client, "* %s - %c - %s", auth, adminchr, name);
			} else {
				ReplyToCommand(client, "  %s - %c - %s", auth, adminchr, name);
			}
		}

		ReplyToCommand(client, "--- %d Admins (limited to 100) - * = ingame", SQL_GetRowCount(query));

		SetCmdReplySource(oldReplySource);
	} else {
		ReplyToCommand(client, "SUM: No admins found");
	}
}

displayBanLog(Handle:query, client) {
	if (query == INVALID_HANDLE) {
		LogError("SUM: Query failed!");
	} else if (SQL_GetRowCount(query)) {
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
			ReplyToCommand(client, "SUM: See console for output.");
		}

		new ReplySource:oldReplySource = SetCmdReplySource(SM_REPLY_TO_CONSOLE);

		ReplyToCommand(client, "--- SUM banlog:");
		ReplyToCommand(client, "target | creator | date | duration | reason");

		while (SQL_FetchRow(query)) {
			decl String:target[STEAMID_LENGTH];
			SQL_FetchString(query, 0, target, sizeof(target));
			decl String:creator[STEAMID_LENGTH];
			SQL_FetchString(query, 1, creator, sizeof(creator));
			new time = SQL_FetchInt(query, 2);
			new duration = SQL_FetchInt(query, 3);
			decl String:reason[65];
			SQL_FetchString(query, 4, reason, sizeof(reason));

			decl String:date[11];
			FormatTime(date, sizeof(date), "%Y-%m-%d", time);

			ReplyToCommand(client, "%s | %s | %s | %d | %s", target, creator, date, duration, reason);
		}

		ReplyToCommand(client, "--- %d entries (limited to 100)", SQL_GetRowCount(query));

		SetCmdReplySource(oldReplySource);
	} else {
		ReplyToCommand(client, "SUM: No bans found");
	}
}

stock bool:steamidInGame(const String:auth[]) {
	new maxclients = GetMaxClients();
	decl String:authcmp[STEAMID_LENGTH];

	for (new client=1; client <= maxclients; client++) {
		if (IsClientInGame(client)) {
			GetClientAuthString(client, authcmp, sizeof(authcmp));

			if (StrEqual(auth, authcmp)) {
				return true;
			}
		}
	}

	return false;
}

stock isNumeric(const String:str[]) {
	new strLength = strlen(str);
	for (new i=0; i<strLength; i++) {
		if (!IsCharNumeric(str[i])) {
			return false;
		}
	}

	return true;
}

#if CONSOLEMESSAGES
stock PrintToConsoleAll(const String:message[]) {
	new maxclients = GetMaxClients();

	for (new client=1; client <= maxclients; client++) {
		if (IsClientInGame(client)) {
			PrintToConsole(client, message);
		}
	}
}
#endif

