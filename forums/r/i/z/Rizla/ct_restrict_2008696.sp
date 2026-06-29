/**
 * @file	ct_restrict.sp
 * @author	1Swat2KillThemAll
 *
 * @brief	Counter Strike: Source SourceMod Plugin
 * @version	2.0.0
 *
 * CT Restrict SourceMod Plugin
 * Copyright (C) 2010 - 2011 B.D.A.K. Koch
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
#include <sdktools>

#define YELLOW 0x01
#define TEAMCOLOR 0x02
#define LIGHTGREEN 0x03
#define GREEN 0x04

#define SQLITE__ 0
#define MYSQL__ 1
#define SQLMAX__ 2

new g_iDatabaseId[MAXPLAYERS+1] = { -1, ... },
	Handle:g_hDatabase = INVALID_HANDLE,
	g_DatabaseType = SQLITE__,
	Handle:g_hCvEnabled = INVALID_HANDLE;

new const stock g_c_banned_team = 3;

enum EQueries
{
	E_QCreate = 0,
	E_QInsert,
	E_QConnect,
	E_QDelete,
	E_QUpdate,
	E_QMax
};
new stock const String:SQLQueries[SQLMAX__][E_QMax][] =
{
	{ // SQLite
		"CREATE TABLE IF NOT EXISTS ct_restrict ( id INTEGER PRIMARY KEY, name VARCHAR(65), steam VARCHAR(32) UNIQUE, ban_time DATE DEFAULT (DATE('now')), admin_steam VARCHAR(32) );",
		"INSERT OR IGNORE INTO ct_restrict (name, steam, admin_steam) VALUES ('%s', '%s', '%s');",
		"SELECT id FROM ct_restrict WHERE steam = '%s';",
		"DELETE FROM ct_restrict WHERE id = '%i';",
		"UPDATE ct_restrict SET name = '%s' WHERE id = '%i';"
	},
	{ // MySQL
		"CREATE TABLE IF NOT EXISTS ct_restrict ( id INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT, name VARCHAR(65), steam VARCHAR(32) UNIQUE, ban_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, admin_steam VARCHAR(32), status INT(11), unbanned_by VARCHAR(32) );",
		"INSERT INTO ct_restrict (name, steam, admin_steam, status, unbanned_by) VALUES ('%s', '%s', '%s', '0', '0');",
		"SELECT id FROM ct_restrict WHERE steam = '%s' AND status = '0';",
		"DELETE FROM ct_restrict WHERE id = '%i';",
		"UPDATE ct_restrict SET name = '%s' WHERE id = '%i';"
	}
};

#define PLUGIN_NAME "CT Restrict"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCR "Ban players from using the CT team."
#define PLUGIN_VERSION "1.000.000"
#define PLUGIN_URL ""
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("CTR_IsClientCTBanned", Native_IsClientCTBanned);
	RegPluginLibrary("ct_restrict");

	return APLRes_Success;
}

#define ASSERT_NATIVE_ERROR_PARAMS(%1) if (numParams != (%1)) { ThrowNativeError(SP_ERROR_PARAM, "wrong number of parameters supplied: got (%i), expected (%i)", numParams, (%1)); }
#define ASSERT_NATIVE_ERROR_CLIENT(%1) decl client; if (!(client = GetNativeCell(%1)) || !IsClientInGame(client) || !IsClientConnected(client)) { ThrowNativeError(SP_ERROR_INDEX, "client index %i is invalid", client); }
public Native_IsClientCTBanned(Handle:plugin, numParams)
{
	ASSERT_NATIVE_ERROR_PARAMS(1)
	ASSERT_NATIVE_ERROR_CLIENT(1)

	return g_iDatabaseId[client] != -1;
}
#undef ASSERT_NATIVE_ERROR_PARAMS
#undef ASSERT_NATIVE_ERROR_CLIENT

public OnPluginStart()
{
	CreateConVar("sm_ctrestrict_version", PLUGIN_VERSION, "Version Console Variable", FCVAR_CHEAT | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_hCvEnabled = CreateConVar("sm_ctrestrict_enabled", "1", "Enable plugin?1:0", FCVAR_DONTRECORD, true, 0.0, true, 1.0);

	RegAdminCmd("sm_ctban", Command_CtBan, ADMFLAG_KICK, "sm_ctban <player> | Bans a player from joining CT.");
	RegAdminCmd("sm_ctunban", Command_CtUnban, ADMFLAG_ROOT, "sm_ctunban <player> | Unbans a player from joining CT.");
	RegAdminCmd("sm_reloadctban", Command_ReloadCtBan, ADMFLAG_ROOT, "sm_reloadctban <player(s)> | Reload bans");

	AddCommandListener(CListener_JoinTeam, "jointeam");
	HookEvent("player_team", Event_PlayerTeam);

	LoadTranslations("common.phrases");

	decl String:buff[255], String:db_config[128];
	new use_sqlite = 1;

	new Handle:kv = CreateKeyValues("CTRestrict");

	if (!FileToKeyValues(kv, "cfg/ct_restrict.kv") || !KvGotoFirstSubKey(kv))
	{
		LogMessage("Couldn\'t open keyvalue file!");
	}
	else
	{
		do
		{
			KvGetSectionName(kv, buff, sizeof(buff));

			if (StrEqual(buff, "Options"))
			{
				if (KvGotoFirstSubKey(kv))
				{
					do
					{
						KvGetSectionName(kv, buff, sizeof(buff));
		
						if (StrEqual(buff, "Database"))
						{
							if (!(use_sqlite = KvGetNum(kv, "use_sqlite", 0)))
							{
								KvGetString(kv, "database_config", db_config, sizeof(db_config), "ctbans");
							}
						}
					} while (KvGotoNextKey(kv));

					KvGoBack(kv);
				}
			}
		} while (KvGotoNextKey(kv));
	}

	CloseHandle(kv);

	if (!use_sqlite)
	{
		if (SQL_CheckConfig(db_config))
		{
			if ((g_hDatabase = SQL_Connect(db_config, true, buff, sizeof(buff))) == INVALID_HANDLE)
			{
				LogMessage("Couldn't connect to database using configuration \"%s\": %s", db_config, buff);
				use_sqlite = 1;
			}
			else
			{
				g_DatabaseType = -1;

				decl String:type[32];
				new Handle:driver = SQL_ReadDriver(g_hDatabase);

				SQL_GetDriverProduct(driver, type, sizeof(type));

				if (StrEqual(type, "MySQL", false))
				{
					g_DatabaseType = MYSQL__;
				}
				else if (StrEqual(type, "SQLite", false))
				{
					g_DatabaseType = SQLITE__;
				}

				if (g_DatabaseType < 0)
				{
					LogError("Unrecognized Database-type \"%s\".", type);
					use_sqlite = true;
					CloseHandle(g_hDatabase);
					g_hDatabase = INVALID_HANDLE;
				}
			}
		}
		else
		{
			LogMessage("Couldn't find named configuration \"%s\" in databases.cfg.", db_config);
			use_sqlite = true;
		}
	}
	if (use_sqlite)
	{
		if ((g_hDatabase = SQLite_UseDatabase("ct_restrict", buff, sizeof(buff))) == INVALID_HANDLE)
		{
			SetFailState(buff);
		}
	}

	SQL_TQuery(g_hDatabase, T_NoAction, SQLQueries[g_DatabaseType][E_QCreate], DBPrio_High);
}

public OnClientAuthorized(client, const String:auth[])
{
	g_iDatabaseId[client] = -1;

	if (IsFakeClient(client))
	{
		return;
	}

	decl String:query[255];
	Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QConnect], auth);
	SQL_TQuery(g_hDatabase, T_ClientConnected, query, GetClientUserId(client));
}
public T_ClientConnected(Handle:owner, Handle:hndl, const String:error[], any:uid_client)
{
	new client = GetClientOfUserId(uid_client);

	if (!client || !IsClientConnected(client))
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	else if (SQL_FetchRow(hndl))
	{
		g_iDatabaseId[client] = SQL_FetchInt(hndl, 0);
		if (IsClientInGame(client) && GetClientTeam(client) != (g_c_banned_team==3?2:3))
		{
			ChangeClientTeam(client, g_c_banned_team==3?2:3);
		}
	}
}

public Action:Command_CtBan(client, argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[SM] sm_ctban <player> | Bans a player from joining CT.");
	}
	else
	{
		decl String:arg[128];
		GetCmdArg(1, arg, sizeof(arg));

		decl reason, targets[1], String:target_name[1], bool:tn_is_ml;
		if ((reason = ProcessTargetString(arg, client, targets, sizeof(targets),
			COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS,
			target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, reason);

			return Plugin_Handled;
		}

		if (reason != 1)
		{
			return Plugin_Handled;
		}

		if (g_iDatabaseId[targets[0]] == -1)
		{
			ShowActivity2(client, "[SM]", "%N banned %N from playing on CT.", client, targets[0]);

			if (GetClientTeam(targets[0]) == g_c_banned_team && GetConVarInt(g_hCvEnabled))
			{
				ChangeClientTeam(targets[0], g_c_banned_team==3?2:3);
				PrintToChat(targets[0], "%c[TmF Gaming]%c You've been banned from playing on that team!", GREEN, LIGHTGREEN);
			}

			decl String:player_authid[32];
			GetClientAuthString(targets[0], player_authid, sizeof(player_authid));
			decl String:admin_authid[32];
			if (client != 0)
			{
				GetClientAuthString(client, admin_authid, sizeof(admin_authid));
			}
			else
			{
				strcopy(admin_authid, sizeof(admin_authid), "SERVER");
			}

			decl String:query[255],
			String:name[MAX_NAME_LENGTH],
			String:name2[2*(MAX_NAME_LENGTH)+1];
			GetClientName(targets[0], name, sizeof(name));
			SQL_EscapeString(g_hDatabase, name, name2, sizeof(name2));
			Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QInsert], name2, player_authid, admin_authid);


			SQL_TQuery(g_hDatabase, T_Insert, query, GetClientUserId(targets[0]), DBPrio_High);
		}
		else
		{
			ReplyToCommand(client, "[SM] %N was already banned from playing as CT.", targets[0]);
		}
	}

	return Plugin_Handled;
}
public T_Insert(Handle:owner, Handle:hndl, const String:error[], any:uid_client)
{
	new client = GetClientOfUserId(uid_client);

	if (!IsClientConnected(client))
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	else
	{
		decl String:query[255], String:authid[32];
		GetClientAuthString(client, authid, sizeof(authid));

		Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QConnect], authid);
		SQL_TQuery(g_hDatabase, T_ClientConnected, query, GetClientUserId(client), DBPrio_High);
	}
}

public Action:Command_CtUnban(client, argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[SM] sm_ctunban <player> | Unbans a player from joining CT.");
	}
	else
	{
		decl String:arg[128];
		GetCmdArg(1, arg, sizeof(arg));

		decl reason, targets[1], String:target_name[1], bool:tn_is_ml;
		if ((reason = ProcessTargetString(arg, client, targets, sizeof(targets),
			COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS,
			target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, reason);

			return Plugin_Handled;
		}

		if (reason != 1)
		{
			return Plugin_Handled;
		}

		if (g_iDatabaseId[targets[0]] != -1)
		{
			ShowActivity2(client, "[SM]", "%N unbanned %N from playing on CT.", client, targets[0]);

			decl String:query[255];
			Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QDelete], g_iDatabaseId[targets[0]]);

			SQL_TQuery(g_hDatabase, T_NoAction, query);

			g_iDatabaseId[targets[0]] = -1;
		}
		else
		{
			ReplyToCommand(client, "[SM] %N wasn't banned from playing as CT to begin with.", targets[0]);
		}
	}

	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if (g_iDatabaseId[client] != -1 && IsClientConnected(client))
	{
		decl String:query[255],
			String:name[MAX_NAME_LENGTH],
			String:name2[2*(MAX_NAME_LENGTH)+1];
		GetClientName(client, name, sizeof(name));
		SQL_EscapeString(g_hDatabase, name, name2, sizeof(name2));

		Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QUpdate], name2, g_iDatabaseId[client], DBPrio_Low);
		SQL_TQuery(g_hDatabase, T_NoAction, query);
	}

	g_iDatabaseId[client] = -1;
}

public T_NoAction(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
}

public Action:CListener_JoinTeam(client, const String:command[], argc)
{
	if (g_iDatabaseId[client] != -1)
	{
		decl String:buff[8], Action:ret, team;

		GetCmdArg(1, buff, sizeof(buff));
		StripQuotes(buff);
		TrimString(buff);

		if (!strlen(buff))
		{
			return Plugin_Handled;
		}

		team = StringToInt(buff);

		if (team)
		{
			if (team == g_c_banned_team)
			{
				ret = Plugin_Handled;
				PrintRejectionMessage(client);
			}
			else
			{
				ret = Plugin_Continue;
			}
		}
		else
		{
			if (GetClientTeam(client) != (g_c_banned_team==3?2:3))
			{
				ChangeClientTeam(client, g_c_banned_team==3?2:3);
			}

			ret = Plugin_Handled;
		}

		return ret;
	}

	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_hCvEnabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (client && IsClientConnected(client) && IsClientInGame(client) && !GetEventInt(event, "disconnect") &&
			!IsFakeClient(client) && g_iDatabaseId[client] != -1 && GetEventInt(event, "team") == g_c_banned_team)
		{
			CreateTimer(0.1, Timer_ChangeTeam, client, TIMER_FLAG_NO_MAPCHANGE);
			PrintRejectionMessage(client);
		}
	}
}
public Action:Timer_ChangeTeam(Handle:timer, any:client)
{
	ChangeClientTeam(client, g_c_banned_team==3?2:3);
}

PrintRejectionMessage(client)
{
	PrintToChat(client, "%c[TmF Gaming]%c You're banned from joining that team!", GREEN, LIGHTGREEN);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientConnected(i) && IsClientInGame(i))
		{
			PrintToChat(i, "%c[TmF Gaming]%c %N tried to join CT, but was rejected", GREEN, LIGHTGREEN, client);
		}
	}
}

public Action:Command_ReloadCtBan(client, argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[SM] sm_reloadctban <player(s)> | Reload bans");

		return Plugin_Handled;
	}

	new cClients = MaxClients;

	decl String:arg[32],
		cTargets,
		targets[cClients],
		String:target_name[1],
		bool:tn_is_ml;

	GetCmdArg(1, arg, sizeof(arg));
	if ((cTargets = ProcessTargetString(arg, client, targets, cClients,
		COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_BOTS,
		target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, cTargets);

		return Plugin_Handled;
	}

	decl String:authid[32];
	for (new i = 0; i < cTargets; i++)
	{
		GetClientAuthString(targets[i], authid, sizeof(authid));
		OnClientAuthorized(targets[i], authid);
	}

	ReplyToCommand(client, "[SM] Reloading CT Ban(s)");

	return Plugin_Handled;
}
