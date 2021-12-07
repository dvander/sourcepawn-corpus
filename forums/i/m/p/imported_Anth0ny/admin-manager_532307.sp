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
       	name = "ASAM - Admin Manager",
       	author = "AngelX, based on original AlliedModders LLC code",
       	description = "Manages SQL admins (UTF8-ready)",
       	version = "1.3",
       	url = "http://www.megatron.ws/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_sql_addadmin", Command_AddAdmin, ADMFLAG_ROOT, "Adds an admin to the SQL database");
	RegAdminCmd("sm_sql_deladmin", Command_DelAdmin, ADMFLAG_ROOT, "Removes an admin from the SQL database");
	RegAdminCmd("sm_sql_addgroup", Command_AddGroup, ADMFLAG_ROOT, "Adds a group to the SQL database");
	RegAdminCmd("sm_sql_delgroup", Command_DelGroup, ADMFLAG_ROOT, "Removes a group from the SQL database");
	RegAdminCmd("sm_sql_setadmingroups", Command_SetAdminGroups, ADMFLAG_ROOT, "Sets an admin's groups in the SQL database");
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

public Action:Command_SetAdminGroups(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM:AM] Usage: sm_sql_setadmingroups <identity> [group1] ... [group N]");
		return Plugin_Handled;
	}
	
	new Handle:db = Connect(); 
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM:AM] Could not connect to database");
		return Plugin_Handled;
	}
	
	decl String:identity[65];
	decl String:safe_identity[140];
	GetCmdArg(1, identity, sizeof(identity));
	SQL_QuoteString(db, identity, safe_identity, sizeof(safe_identity));
	
	decl String:query[255];
	Format(
		query, 
		sizeof(query),
		"SELECT id FROM sm_admins WHERE identity = '%s'",
		safe_identity
	);
		
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
	{
		return DoError(client, db, query, "Admin lookup query failed");
	}
	
	if (!SQL_FetchRow(hQuery))
	{
		ReplyToCommand(client, "[SM:AM] SQL Admin not found");
		CloseHandle(hQuery);
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	new id = SQL_FetchInt(hQuery, 0);
	
	CloseHandle(hQuery);
	
	Format(
		query, 
		sizeof(query), 
		"DELETE FROM sm_admins_groups WHERE admin_id = %d", 
		id
	);

	if (!SQL_FastQuery(db, query))
	{
		return DoError(client, db, query, "Admin group deletion query failed");
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM:AM] SQL Admin groups reset");
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	decl String:error[256];
	new Handle:hAddQuery, Handle:hFindQuery;
	
	Format(
		query, 
		sizeof(query), 
		"SELECT id FROM sm_groups WHERE name = ?"
	);
	if ((hFindQuery = SQL_PrepareQuery(db, query, error, sizeof(error))) == INVALID_HANDLE)
	{
		return DoStmtError(client, db, query, error, "Group search prepare failed");
	}

	Format(
		query, 
		sizeof(query), 
		"INSERT INTO sm_admins_groups (admin_id, group_id, inherit_order) VALUES (%d, ?, ?)",
		id
	);
	if ((hAddQuery = SQL_PrepareQuery(db, query, error, sizeof(error))) == INVALID_HANDLE)
	{
		CloseHandle(hFindQuery);
		return DoStmtError(client, db, query, error, "Add admin group prepare failed");
	}

	decl String:name[80];
	new inherit_order = 0;
	for (new i=2; i<=args; i++)
	{
		GetCmdArg(i, name, sizeof(name));
		
		SQL_BindParamString(hFindQuery, 0, name, false);
		if (!SQL_Execute(hFindQuery) || !SQL_FetchRow(hFindQuery))
		{
			ReplyToCommand(client, "[SM:AM] SQL Group '%s' not found", name);
		} else {
			new gid = SQL_FetchInt(hFindQuery, 0);
			
			SQL_BindParamInt(hAddQuery, 0, gid);
			SQL_BindParamInt(hAddQuery, 1, ++inherit_order);
			if (!SQL_Execute(hAddQuery))
			{
				ReplyToCommand(client, "[SM:AM] SQL Group '%s' failed to bind", name);
				inherit_order--;
			}
		}
	}
	
	CloseHandle(hAddQuery);
	CloseHandle(hFindQuery);
	CloseHandle(db);
	
	if (inherit_order == 1)
	{
		ReplyToCommand(client, "[SM:AM] Added group to user");
	} else if (inherit_order > 1) {
		ReplyToCommand(client, "[SM:AM] Added %d groups to user", inherit_order);
	}
	
	return Plugin_Handled;
}

public Action:Command_DelGroup(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM:AM] Usage: sm_sql_delgroup <name>");
		return Plugin_Handled;
	}

	new Handle:db = Connect();
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM:AM] Could not connect to database");
		return Plugin_Handled;
	}
	
	new len;
	decl String:name[80];
	decl String:safe_name[180];
	GetCmdArgString(name, sizeof(name));
	
	/* Strip quotes in case the user tries to use them */
	len = strlen(name);
	if (len > 1 && (name[0] == '"' && name[len-1] == '"'))
	{
		name[--len] = '\0';
		SQL_QuoteString(db, name[1], safe_name, sizeof(safe_name));
	} else {
		SQL_QuoteString(db, name, safe_name, sizeof(safe_name));
	}
	
	decl String:query[256];
	
	new Handle:hQuery;
	Format(
		query, 
		sizeof(query), 
		"SELECT id FROM sm_groups WHERE name = '%s'", 
		safe_name
	);
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
	{
		return DoError(client, db, query, "Group retrieval query failed");
	}
	
	if (!SQL_FetchRow(hQuery))
	{
		ReplyToCommand(client, "[SM:AM] SQL Group not found");
		CloseHandle(hQuery);
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	new id = SQL_FetchInt(hQuery, 0);
	
	CloseHandle(hQuery);
	
	/* Delete admin inheritance for this group */
	Format(
		query, 
		sizeof(query), 
		"DELETE FROM sm_admins_groups WHERE group_id = %d", 
		id
	);
	if (!SQL_FastQuery(db, query))
	{
		return DoError(client, db, query, "Admin group deletion query failed");
	}
	
	/* Finally delete the group */
	Format(
		query, 
		sizeof(query), 
		"DELETE FROM sm_groups WHERE id = %d", 
		id
	);
	if (!SQL_FastQuery(db, query))
	{
		return DoError(client, db, query, "Group deletion query failed");
	}
	
	ReplyToCommand(client, "[SM:AM] SQL Group deleted");
	
	CloseHandle(db);
	
	return Plugin_Handled;
}

public Action:Command_AddGroup(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM:AM] Usage: sm_sql_addgroup <name> <flags> [immunity] [server]");
		return Plugin_Handled;
	}

	new immunity;
	if (args >= 3)
	{
		new String:arg3[32];
		GetCmdArg(3, arg3, sizeof(arg3));
		if (!StringToIntEx(arg3, immunity))
		{
			ReplyToCommand(client, "[SM:AM] Invalid immunity");
			return Plugin_Handled;
		}
	}

	new Handle:db = Connect();
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM:AM] Could not connect to database");
		return Plugin_Handled;
	}

	decl String:name[64];
	decl String:safe_name[64];
	GetCmdArg(1, name, sizeof(name));
	SQL_QuoteString(db, name, safe_name, sizeof(safe_name));
	
	new Handle:hQuery;
	decl String:query[256];
	Format(
		query, 
		sizeof(query), 
		"SELECT id FROM sm_groups WHERE name = '%s'", 
		safe_name
	);
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
	{
		return DoError(client, db, query, "Group retrieval query failed");
	}
	
	if (SQL_GetRowCount(hQuery) > 0)
	{
		ReplyToCommand(client, "[SM:AM] SQL Group already exists");
		CloseHandle(hQuery);
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	CloseHandle(hQuery);
	
	decl String:flags[30];
	decl String:safe_flags[64];
	GetCmdArg(2, flags, sizeof(flags));
	SQL_QuoteString(db, flags, safe_flags, sizeof(safe_flags));

	decl String:safe_server[64];
	safe_server[0] = '\0';
	if (args >= 4)
	{
		decl String:server[64];
		GetCmdArg(4, server, sizeof(server));
		SQL_QuoteString(db, server, safe_server, sizeof(safe_server));
	}

	Format(query, 
		sizeof(query),
		"INSERT INTO sm_groups (name, flags, immunity_level, server) VALUES ('%s', '%s', '%d', '%s')",
		safe_name,
		safe_flags,
		immunity,
		safe_server);
	
	if (!SQL_FastQuery(db, query))
	{
		return DoError(client, db, query, "Group insertion query failed");
	}

	ReplyToCommand(client, "[SM:AM] SQL Group added");
	
	CloseHandle(db);
		
	return Plugin_Handled;
}	

public Action:Command_DelAdmin(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM:AM] Usage: sm_sql_deladmin <identity>");
		return Plugin_Handled;
	}
	
	new Handle:db = Connect();
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM:AM] Could not connect to database");
		return Plugin_Handled;
	}
	
	decl String:identity[65];
	decl String:safe_identity[140];
	GetCmdArg(1, identity, sizeof(identity));
	SQL_QuoteString(db, identity, safe_identity, sizeof(safe_identity));
	
	decl String:query[255];
	Format(
		query, 
		sizeof(query),
		"SELECT id FROM sm_admins WHERE identity = '%s'",
		safe_identity
	);
		
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
	{
		return DoError(client, db, query, "Admin lookup query failed");
	}
	
	if (!SQL_FetchRow(hQuery))
	{
		ReplyToCommand(client, "[SM:AM] SQL Admin not found");
		CloseHandle(hQuery);
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	new id = SQL_FetchInt(hQuery, 0);
	
	CloseHandle(hQuery);
	
	/* Delete group bindings */
	Format(
		query,
		sizeof(query),
		"DELETE FROM sm_admins_groups WHERE admin_id = %d", 
		id
	);
	if (!SQL_FastQuery(db, query))
	{
		return DoError(client, db, query, "Admin group deletion query failed");
	}
	
	Format(query, sizeof(query), "DELETE FROM sm_admins WHERE id = %d", id);
	if (!SQL_FastQuery(db, query))
	{
		return DoError(client, db, query, "Admin deletion query failed");
	}
	
	CloseHandle(db);
	
	ReplyToCommand(client, "[SM:AM] SQL Admin deleted");
	
	return Plugin_Handled;
}

public Action:Command_AddAdmin(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM:AM] Usage: sm_sql_addadmin <alias> <identity>");
		return Plugin_Handled;
	}
	
	decl String:identity[65];
	decl String:safe_identity[140];
	GetCmdArg(2, identity, sizeof(identity));
	
	decl String:query[256];
	new Handle:hQuery;
	new Handle:db = Connect();
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM:AM] Could not connect to database");
		return Plugin_Handled;
	}
	
	SQL_QuoteString(db, identity, safe_identity, sizeof(safe_identity));
	
	Format(
		query, 
		sizeof(query), 
		"SELECT id FROM sm_admins WHERE identity = '%s'", 
		safe_identity
	);
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
	{
		return DoError(client, db, query, "Admin retrieval query failed");
	}
	
	if (SQL_GetRowCount(hQuery) > 0)
	{
		ReplyToCommand(client, "[SM:AM] SQL Admin already exists");
		CloseHandle(hQuery);
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	CloseHandle(hQuery);
	
	decl String:alias[64];
	decl String:safe_alias[140];
	GetCmdArg(1, alias, sizeof(alias));
	SQL_QuoteString(db, alias, safe_alias, sizeof(safe_alias));
	
	Format(
		query, 
		sizeof(query), 
		"INSERT INTO sm_admins (identity, name) VALUES ('%s', '%s')", 
		safe_identity, 
		safe_alias
	);
	if (!SQL_FastQuery(db, query))
	{
		return DoError(client, db, query, "Admin insertion query failed");
	}
	
	ReplyToCommand(client, "[SM:AM] SQL Admin added");
	
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

stock Action:DoError(client, Handle:db, const String:query[], const String:msg[])
{
		decl String:error[255];
		SQL_GetError(db, error, sizeof(error));
		LogError("%s: %s", msg, error);
		LogError("Query dump: %s", query);
		CloseHandle(db);
		ReplyToCommand(client, "[SM:AM] Failed to query database");
		return Plugin_Handled;
}

stock Action:DoStmtError(client, Handle:db, const String:query[], const String:error[], const String:msg[])
{
		LogError("%s: %s", msg, error);
		LogError("Query dump: %s", query);
		CloseHandle(db);
		ReplyToCommand(client, "[SM:AM] Failed to query database");
		return Plugin_Handled;
}

