/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod SQL Admins Plugin (Threaded)
 * Fetches admins from an SQL database dynamically.
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
 * Version: $Id: admin-sql-threaded.sp 1409 2007-09-10 23:38:58Z dvander $
 */

/* We like semicolons */
#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
       	name = "ASAM - Admin Connector",
       	author = "AngelX, based on original AlliedModders LLC code",
       	description = "Reads admins from SQL dynamically (threaded and UTF8 ready)",
       	version = "1.3",
       	url = "http://www.megatron.ws/"
};

/**
 * Notes:
 *
 * 1) All queries in here are high priority.  This is because the admin stuff 
 *    is very important.  Do not take this to mean that in your script, 
 *    everything should be high priority.  
 *
 * 2) All callbacks are locked with "sequence numbers."  This is to make sure 
 *    that multiple calls to sm_reloadadmins and the like do not make us 
 *    store the results from two or more callbacks accidentally.  Instead, we 
 *    check the sequence number in each callback with the current "allowed" 
 *    sequence number, and if it doesn't match, the callback is cancelled.
 *
 * 3) Sequence numbers for groups are not cleared unless there was a 100% 
 *    success in the fetch.  This is so we can potentially implement 
 *    connection retries in the future.
 *
 * 4) Sequence numbers for the user cache are ignored except for being 
 *    non-zero, which means players in-game should be re-checked for admin 
 *    powers.
 */

new Handle:hDatabase = INVALID_HANDLE;			/** Database connection */
new g_sequence = 0;								/** Global unique sequence number */
new ConnectLock = 0;							/** Connect sequence number */
new RebuildCachePart[3] = {0};					/** Cache part sequence numbers */
new PlayerSeq[MAXPLAYERS+1];					/** Player-specific sequence numbers */
new bool:PlayerAuth[MAXPLAYERS+1];				/** Whether a player has been "pre-authed" */
new Handle:h_cvarAdminFilter = INVALID_HANDLE; /** Filter for groups of admins CVAR */				

#define _DEBUG


public OnPluginStart()
{
	h_cvarAdminFilter = CreateConVar("sm_admin_filter", "", "Filter by server for groups of admins that been load");
}

public OnMapEnd()
{
	/**
	 * Clean up on map end just so we can start a fresh connection when we need it later.
	 */
	if (hDatabase != INVALID_HANDLE)
	{
		CloseHandle(hDatabase);
		hDatabase = INVALID_HANDLE;
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) 
{
	PlayerSeq[client] = 0;
	PlayerAuth[client] = false;
	return true;
}

public OnClientDisconnect(client) 
{
	PlayerSeq[client] = 0;
	PlayerAuth[client] = false;
}

public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
#if defined _DEBUG
	LogMessage("[DEBUG] OnDatabaseConnect(%x,%x,%d) ConnectLock=%d", owner, hndl, data, ConnectLock);
#endif

	/**
	 * If this happens to be an old connection request, ignore it.
	 */
	if (data != ConnectLock || hDatabase != INVALID_HANDLE)
	{
		if (hndl != INVALID_HANDLE)
		{
			CloseHandle(hndl);
		}
		return;
	}
	
	ConnectLock = 0;
	hDatabase = hndl;
	
	/**
	 * See if the connection is valid.  If not, don't un-mark the caches
	 * as needing rebuilding, in case the next connection request works.
	 */
	if (hDatabase == INVALID_HANDLE)
	{
		LogError("Failed to connect to database: %s", error);
		return;
	}

	if (!SQL_FastQuery(hDatabase, "SET NAMES 'utf8'"))
	{
		LogError("Can't select UTF8 code page");
		return;
	}

	/**
	 * See if we need to get any of the cache stuff now.
	 */
	new sequence;
	if ((sequence = RebuildCachePart[_:AdminCache_Groups]) != 0)
	{
		FetchGroups(hDatabase, sequence);
	}
	if ((sequence = RebuildCachePart[_:AdminCache_Admins]) != 0)
	{
		FetchUsersWeCan(hDatabase);
	}
}

RequestDatabaseConnection() 
{
	ConnectLock = ++g_sequence;
	if (SQL_CheckConfig("admins"))
	{
		SQL_TConnect(OnDatabaseConnect, "admins", ConnectLock);
	} else {
		SQL_TConnect(OnDatabaseConnect, "default", ConnectLock);
	}
}

public OnRebuildAdminCache(AdminCachePart:part) 
{
	/**
	 * Mark this part of the cache as being rebuilt.  This is used by the 
	 * callback system to determine whether the results should still be 
	 * used.
	 */
	new sequence = ++g_sequence;
	RebuildCachePart[_:part] = sequence;

#if defined _DEBUG
	LogMessage("[DEBUG] OnRebuildAdminCache(%d) Sequence=%d", part, sequence);
#endif
	
	/**
	 * If we don't have a database connection, we can't do any lookups just yet.
	 */
	if (!hDatabase)
	{
		/**
		 * Ask for a new connection if we need it.
		 */
		if (!ConnectLock)
		{
			RequestDatabaseConnection();
		}
		return;
	}
	
	switch (part)
	{
		case AdminCache_Groups:
			FetchGroups(hDatabase, sequence);
		case AdminCache_Admins:
			FetchUsersWeCan(hDatabase);
	}
}

public Action:OnClientPreAdminCheck(client) 
{
#if defined _DEBUG
	LogMessage("[DEBUG] OnClientPreAdminCheck(%d)", client);
#endif

	PlayerAuth[client] = true;
	
	/**
	 * Play nice with other plugins.  If there's no database, don't delay the 
	 * connection process.  Unfortunately, we can't attempt anything else and 
	 * we just have to hope either the database is waiting or someone will type 
	 * sm_reloadadmins.
	 */
	if (hDatabase == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}
	
	/**
	 * Similarly, if the cache is in the process of being rebuilt, don't delay 
	 * the user's normal connection flow.  The database will soon auth the user 
	 * normally.
	 */
	if (RebuildCachePart[_:AdminCache_Admins] != 0)
	{
		return Plugin_Continue;
	}
	
	/**
	 * If someone has already assigned an admin ID (bad bad bad), don't 
	 * bother waiting.
	 */
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		return Plugin_Continue;
	}
	
	FetchUser(hDatabase, client);
	
	return Plugin_Handled;
}

public OnReceiveUserGroups(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	new Handle:pk = Handle:data;
	ResetPack(pk);
	
	new client = ReadPackCell(pk);
	new sequence = ReadPackCell(pk);
	
#if defined _DEBUG
	LogMessage("[DEBUG] OnReceiveUserGroups(%d) Sequence=%d", client, sequence);
#endif

	/**
	 * Make sure it's the same client.
	 */
	if (PlayerSeq[client] != sequence)
	{
		CloseHandle(pk);
		return;
	}
	
	new AdminId:adm = AdminId:ReadPackCell(pk);
	
	/**
	 * Someone could have sneakily changed the admin id while we waited.
	 */
	if (GetUserAdmin(client) != adm)
	{
		NotifyPostAdminCheck(client);
		CloseHandle(pk);
		return;
	}
	
	/**
	 * See if we got results.
	 */
	if (hndl == INVALID_HANDLE)
	{
		decl String:query[255];
		ReadPackString(pk, query, sizeof(query));
		LogError("SQL error receiving user: %s", error);
		LogError("Query dump: %s", query);
		NotifyPostAdminCheck(client);
		CloseHandle(pk);
		return;
	}
	
	decl String:name[80];
	new GroupId:gid;
	
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, name, sizeof(name));
		
		if ((gid = FindAdmGroup(name)) == INVALID_GROUP_ID)
		{
			continue;
		}
		
#if defined _DEBUG
		LogMessage("[DEBUG] Binding user group (%d, %d, %d, %s, %d)", client, sequence, adm, name, gid);
#endif
		
		AdminInheritGroup(adm, gid);
	}
	
	/**
	 * We're DONE! Omg.
	 */
	NotifyPostAdminCheck(client);
	CloseHandle(pk);
}

public OnReceiveUser(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new Handle:pk = Handle:data;
	ResetPack(pk);
	
	new client = ReadPackCell(pk);
	new sequence = ReadPackCell(pk);

#if defined _DEBUG
	LogMessage("[DEBUG] OnReceiveUser(%d) Sequence=%d", client, sequence);
#endif


	if (PlayerSeq[client] != sequence)
	{
		/* Discard everything, since we're out of sequence. */
		CloseHandle(pk);
		return;
	}
	
	/**
	 * If we need to use the results, make sure they succeeded.
	 */
	if (hndl == INVALID_HANDLE)
	{
		decl String:query[255];
		ReadPackString(pk, query, sizeof(query));
		LogError("SQL error receiving user: %s", error);
		LogError("Query dump: %s", query);
		RunAdminCacheChecks(client);
		NotifyPostAdminCheck(client);
		CloseHandle(pk);
		return;
	}
	
	new num_accounts = SQL_GetRowCount(hndl);
	if (num_accounts == 0)
	{
		RunAdminCacheChecks(client);
		NotifyPostAdminCheck(client);
		CloseHandle(pk);
		return;
	}
	
	decl String:identity[80];
	decl String:name[80];
	new AdminId:adm, id;
	
	/**
	 * Cache user info -- [0] = db id, [1] = cache id, [2] = groups
	 */
	decl user_lookup[num_accounts][3];
	new total_users = 0;
	
	while (SQL_FetchRow(hndl))
	{
		id = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, identity, sizeof(identity));
		SQL_FetchString(hndl, 2, name, sizeof(name));

		
		/* For dynamic admins we clear anything already in the cache. */
		if ((adm = FindAdminByIdentity(AUTHMETHOD_STEAM, identity)) != INVALID_ADMIN_ID)
		{
			RemoveAdmin(adm);
		}
		
		adm = CreateAdmin(name);
		if (!BindAdminIdentity(adm, AUTHMETHOD_STEAM, identity))
		{
			LogError("Could not bind prefetched SQL admin (\"%s\")", identity);
			continue;
		}
		
		user_lookup[total_users][0] = id;
		user_lookup[total_users][1] = _:adm;
		user_lookup[total_users][2] = SQL_FetchInt(hndl, 3);
		total_users++;
		
#if defined _DEBUG
		LogMessage("[DEBUG] Found SQL admin (%d,%s,%s):%d:%d", id, identity, name, adm, user_lookup[total_users-1][2]);
#endif
		
	}
	
	/**
	 * Try binding the user.
	 */	
	new group_count = 0;
	RunAdminCacheChecks(client);
	adm = GetUserAdmin(client);
	id = 0;
	
	
	for (new i=0; i<total_users; i++)
	{
		if (user_lookup[i][1] == _:adm)
		{
			id = user_lookup[i][0];
			group_count = user_lookup[i][2];
			break;
		}
	}
	
#if defined _DEBUG
	LogMessage("[DEBUG] Binding client (%d, %d) resulted in: (%d, %d, %d)", client, sequence, id, adm, group_count);
#endif
	
	/**
	 * If we can't verify that we assigned a database admin, or the user has no 
	 * groups, don't bother doing anything.
	 */
	if (!id || !group_count)
	{
		NotifyPostAdminCheck(client);
		CloseHandle(pk);
		return;
	}
	
	/**
	 * The user has groups -- we need to fetch them!
	 */
	decl String:query[255];

	decl String:adminfilter[64];
	GetConVarString(h_cvarAdminFilter, adminfilter, sizeof(adminfilter));

	Format(
		query, 
		sizeof(query), 
		"SELECT g.name FROM sm_admins_groups ag JOIN sm_groups g ON ag.group_id = g.id WHERE ag.admin_id = %d AND (g.server = '%s' OR g.server = '')", 
		id,
		adminfilter
	);
	 
	ResetPack(pk);
	WritePackCell(pk, client);
	WritePackCell(pk, sequence);
	WritePackCell(pk, _:adm);
	WritePackString(pk, query);

#if defined _DEBUG
	LogMessage("[DEBUG] Sending user groups query: %s", query);
#endif
	
	SQL_TQuery(owner, OnReceiveUserGroups, query, pk, DBPrio_High);
}

FetchUser(Handle:db, client) //internal call
{
	decl String:steamid[32];
	
	steamid[0] = '\0';
	if (GetClientAuthString(client, steamid, sizeof(steamid)))
	{
		if (StrEqual(steamid, "STEAM_ID_LAN"))
		{
			steamid[0] = '\0';
		}
	}
	
	/**
	 * Construct the query using the information the user gave us.
	 */
	decl String:query[512];
	new len = 0;

	decl String:adminfilter[64];
	GetConVarString(h_cvarAdminFilter, adminfilter, sizeof(adminfilter));

	len += Format(query[len], sizeof(query)-len, "SELECT a.id, a.identity, a.name, COUNT(ag.group_id)");
	len += Format(query[len], sizeof(query)-len, " FROM sm_admins a JOIN sm_admins_groups ag ON a.id = ag.admin_id");
	len += Format(query[len], sizeof(query)-len, " JOIN sm_groups g ON ag.group_id = g.id WHERE ");
	len += Format(query[len], sizeof(query)-len, " (g.server = '%s' OR g.server = '') AND", adminfilter);
	len += Format(query[len], sizeof(query)-len, " a.identity = '%s'", steamid);
	len += Format(query[len], sizeof(query)-len, " GROUP BY a.id");
	
	/**
	 * Send the actual query.
	 */	
	PlayerSeq[client] = ++g_sequence;
	
	new Handle:pk;
	pk = CreateDataPack();
	WritePackCell(pk, client);
	WritePackCell(pk, PlayerSeq[client]);
	WritePackString(pk, query);
	
#if defined _DEBUG
	LogMessage("[DEBUG] Sending user query: %s", query);
#endif
	
	SQL_TQuery(db, OnReceiveUser, query, pk, DBPrio_High);
}

FetchUsersWeCan(Handle:db)
{
	new max_clients = GetMaxClients();
	
	for (new i=1; i<=max_clients; i++)
	{
		if (PlayerAuth[i] && GetUserAdmin(i) == INVALID_ADMIN_ID)
		{
			FetchUser(db, i);
		}
	}
	
	/**
	 * This round of updates is done.  Go in peace.
	 */
	RebuildCachePart[_:AdminCache_Admins] = 0;
}

public OnReceiveGroups(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new Handle:pk = Handle:data;
	ResetPack(pk);
	
	/**
	 * Check if this is the latest result request.
	 */
	new sequence = ReadPackCell(pk);
	if (RebuildCachePart[_:AdminCache_Groups] != sequence)
	{
		/* Discard everything, since we're out of sequence. */
		CloseHandle(pk);
		return;
	}
	
	/**
	 * If we need to use the results, make sure they succeeded.
	 */
	if (hndl == INVALID_HANDLE)
	{
		decl String:query[255];
		ReadPackString(pk, query, sizeof(query));
		LogError("SQL error receiving groups: %s", error);
		LogError("Query dump: %s", query);
		CloseHandle(pk);
		return;
	}
	
	/**
	 * Now start fetching groups.
	 */
	decl String:flags[32];
	decl String:name[128];
	new immunity;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, flags, sizeof(flags));
		SQL_FetchString(hndl, 1, name, sizeof(name));
		immunity = SQL_FetchInt(hndl, 2);
		
#if defined _DEBUG
		LogMessage("[DEBUG] Adding group (%d, %s, %s)", immunity, flags, name);
#endif
		
		/* Find or create the group */
		new GroupId:gid;
		if ((gid = FindAdmGroup(name)) == INVALID_GROUP_ID)
		{
			gid = CreateAdmGroup(name);
		}

		/* Add flags from the database to the group */
		new num_flag_chars = strlen(flags);
		for (new i=0; i<num_flag_chars; i++)
		{
			decl AdminFlag:flag;
			if (!FindFlagByChar(flags[i], flag))
			{
				continue;
			}
			SetAdmGroupAddFlag(gid, flag, true);
		}
		
		SetAdmGroupImmunityLevel(gid, immunity);
	}

}

FetchGroups(Handle:db, sequence) 
{
	decl String:query[255];
	new Handle:pk;
	
	decl String:adminfilter[64];
	GetConVarString(h_cvarAdminFilter, adminfilter, sizeof(adminfilter));

	Format(
		query, 
		sizeof(query), 
		"SELECT flags, name, immunity_level FROM sm_groups WHERE server = '%s' OR server = ''", 
		adminfilter
	);

	pk = CreateDataPack();
	WritePackCell(pk, sequence);
	WritePackString(pk, query);
	
#if defined _DEBUG
	LogMessage("[DEBUG] Sending groups query: %s", query);
#endif


	SQL_TQuery(db, OnReceiveGroups, query, pk, DBPrio_High);
}
