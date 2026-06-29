/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod SQL Admin Manager Plugin
 * Adds/managers admins and groups in an SQL database.
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id: sql-admin-manager.sp 1411 2007-09-11 12:29:58Z dvander $
 */

/* We like semicolons */
#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
       	name = "ASAM - Admin Database Creator",
       	author = "AngelX, based on original AlliedModders LLC code",
       	description = "Create UTF8 database for SQL Admin Connector and Manager",
       	version = "1.3",
       	url = "http://www.megatron.ws/"
};

public OnPluginStart()
{
	RegServerCmd("sm_create_adm_tables", Command_CreateTables);
}

Handle:Connect()
{
	decl String:error[255];
	new Handle:db;
	
	if (SQL_CheckConfig("admins"))
	{
		db = SQL_Connect("admins", true, error, sizeof(error));
	} else {
		db = SQL_Connect("default", true, error, sizeof(error));
	}
	
	if (db == INVALID_HANDLE)
	{
		LogError("Could not connect to database: %s", error);
	}
	else if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
	{
		LogError("Can't select UTF8 code page");
	}
	
	return db;
}

CreateMySQL(client, Handle:db)
{
	new String:queries[3][] = 
	{
		"CREATE TABLE sm_admins (id int(10) unsigned NOT NULL auto_increment, identity varchar(65) NOT NULL, name varchar(65) NOT NULL, PRIMARY KEY (id))",
		"CREATE TABLE sm_groups (id int(10) unsigned NOT NULL auto_increment, flags varchar(30) NOT NULL, name varchar(120) NOT NULL, immunity_level int(1) unsigned NOT NULL, server varchar(65) NOT NULL, PRIMARY KEY (id))",
		"CREATE TABLE sm_admins_groups (admin_id int(10) unsigned NOT NULL, group_id int(10) unsigned NOT NULL, inherit_order int(10) NOT NULL, PRIMARY KEY (admin_id, group_id))"
	};

	for (new i = 0; i < 3; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "[SM:AM] Admin tables have been created.");
}

CreateSQLite(client, Handle:db)
{
	new String:queries[3][] = 
	{
		"CREATE TABLE sm_admins (id INTEGER PRIMARY KEY AUTOINCREMENT, identity varchar(65) NOT NULL, name varchar(65) NOT NULL)",
		"CREATE TABLE sm_groups (id INTEGER PRIMARY KEY AUTOINCREMENT, flags varchar(30) NOT NULL, name varchar(120) NOT NULL, immunity_level INTEGER NOT NULL, server varchar(65) NOT NULL)",
		"CREATE TABLE sm_admins_groups (admin_id INTEGER NOT NULL, group_id INTEGER NOT NULL, inherit_order int(10) NOT NULL, PRIMARY KEY (admin_id, group_id))"
	};

	for (new i = 0; i < 3; i++)
	{
		if (!DoQuery(client, db, queries[i]))
		{
			return;
		}
	}

	ReplyToCommand(client, "[SM:AM] Admin tables have been created.");
}


public Action:Command_CreateTables(args)
{
	new client = 0;
	new Handle:db = Connect();
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM:AM] Could not connect to database");
		return Plugin_Handled;
	}

	new String:ident[16];
	SQL_ReadDriver(db, ident, sizeof(ident));

	if (strcmp(ident, "mysql") == 0)
	{
		CreateMySQL(client, db);
	} else if (strcmp(ident, "sqlite") == 0) {
		CreateSQLite(client, db);
	} else {
		ReplyToCommand(client, "[SM:AM] Unknown driver type '%s', cannot create tables.", ident);
	}

	CloseHandle(db);

	return Plugin_Handled;
}

stock bool:DoQuery(client, Handle:db, const String:query[])
{
	if (!SQL_FastQuery(db, query))
	{
		decl String:error[255];
		SQL_GetError(db, error, sizeof(error));
		LogError("Query failed: %s", error);
		LogError("Query dump: %s", query);
		ReplyToCommand(client, "[SM:AM] Failed to query database");
		return false;
	}

	return true;
}
