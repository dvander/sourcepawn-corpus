/**
 * clientpref.sp
 * Implements client preferences saving for other plugins.
 * This file is part of SourceMod, Copyright (C) 2004-2007 AlliedModders LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * Version: $Id$
 */
 
#include <sourcemod>
#include <clientpref>

#pragma semicolon 1

new Handle:SQL_ClientPrefs = INVALID_HANDLE;
new Handle:g_Fwd_OnClientPref = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Client Preferences",
	author = "AlliedModders LLC",
	description = "Adds ability for plugins to store and use client preferences",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_Fwd_OnClientPref = CreateGlobalForward("OnClientPref", ET_Ignore, Param_Cell, Param_String, Param_String);
	
	//	Connect to the SQLite Database
	new String:error[1];
	SQL_ClientPrefs = SQL_Connect("clientprefs", true, error, sizeof(error));
	if (SQL_ClientPrefs == INVALID_HANDLE)
	{
		SQL_ClientPrefs = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "clientprefs", error, sizeof(error), true, 0);
		SQL_FastQuery(SQL_ClientPrefs, "CREATE TABLE IF NOT EXISTS clientprefs (steamid STRING, id STRING, value STRING);");
	}
	
	RegPluginLibrary("clientpref");
	
}

public Native_ClientUpdateItem(Handle:plugin, numParams)
{
	new userid = GetNativeCell(1);
	decl String:steamid[255], String:id[255], String:data[255];
	GetNativeString(2, steamid, sizeof(steamid));
	GetNativeString(3, id, sizeof(id));
	GetNativeString(4, data, sizeof(data));
	
	ClientPrefUpdateItem(userid, steamid, id, data);
}

public Native_ClientDeleteItem(Handle:plugin, numParams)
{
	new userid = GetNativeCell(1);
	decl String:steamid[255], String:id[255];
	GetNativeString(2, steamid, sizeof(steamid));
	GetNativeString(3, id, sizeof(id));
	
	ClientPrefDeleteItem(userid, steamid, id);
}

public Native_ClientSelectItem(Handle:plugin, numParams)
{
	new userid = GetNativeCell(1);
	decl String:steamid[255], String:id[255];
	GetNativeString(2, steamid, sizeof(steamid));
	GetNativeString(3, id, sizeof(id));
	
	ClientPrefSelectItem(userid, steamid, id);
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:Error[])
{
	CreateNative("ClientPrefUpdate", Native_ClientUpdateItem);
	CreateNative("ClientPrefDelete", Native_ClientDeleteItem);
	CreateNative("ClientPrefSelect", Native_ClientSelectItem);
	return true;
}

public ClientPrefUpdateItem(userid, String:steamid[], String:id[], String:value[])
{
	new String:query[184];
	
	Format(query, sizeof(query), "SELECT * FROM clientprefs WHERE steamid = '%s' AND id = '%s'", steamid, id);
	
	new Handle:data = CreateDataPack();
	WritePackCell(data, userid);
	WritePackString(data, steamid);
	WritePackString(data, id);
	WritePackString(data, value);
	
	SQL_TQuery(SQL_ClientPrefs, T_CheckUniqueID, query, data);
}

public ClientPrefDeleteItem(userid, String:steamid[], String:id[])
{
	new String:query[184];
	
	Format(query, sizeof(query), "DELETE FROM clientprefs WHERE steamid = '%s' AND id = '%s'", steamid, id);
	SQL_TQuery(SQL_ClientPrefs, T_ClientQueryPrefCheck, query, userid);
}

public ClientPrefSelectItem(userid, String:steamid[], String:id[])
{
	new String:query[184];
	
	Format(query, sizeof(query), "SELECT value FROM clientprefs WHERE steamid = '%s' AND id = '%s'", steamid, id);
	
	new Handle:data = CreateDataPack();
	WritePackCell(data, userid);
	WritePackString(data, id);
	
	SQL_TQuery(SQL_ClientPrefs, T_ClientQueryPrefSelect, query, data);
}

public T_CheckUniqueID(Handle:owner, Handle:db, const String:error[], any:data)
{	
	decl String:steamid[255], String:id[255], String:value[255];
	new client;
	
	ResetPack(data);
	new userid = ReadPackCell(data);
	ReadPackString(data, steamid, sizeof(steamid));
	ReadPackString(data, id, sizeof(id));
	ReadPackString(data, value, sizeof(value));
	CloseHandle(data);
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(userid)) == 0)
	{
		return 0;
	}
	
	if (db == INVALID_HANDLE)
	{
		return 0;
	}
	
	new String:query[184];
	
	if (SQL_GetRowCount(db) < 1)
	{
		Format(query, sizeof(query), "INSERT INTO clientprefs VALUES ('%s', '%s', '%s')", steamid, id, value);
		SQL_TQuery(SQL_ClientPrefs, T_ClientQueryPrefCheck, query, userid);
		return 1;
	} else {
		Format(query, sizeof(query), "UPDATE clientprefs SET value = '%s' WHERE steamid = '%s' AND id = '%s'", value, steamid, id);
		SQL_TQuery(SQL_ClientPrefs, T_ClientQueryPrefCheck, query, userid);
		return 1;
	}
}

public T_ClientQueryPrefCheck(Handle:owner, Handle:db, const String:error[], any:data)
{	
	new client;
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return 0;
	}

	if (db == INVALID_HANDLE)
	{
		return 0;
	}
	return 1;
}

public T_ClientQueryPrefSelect(Handle:owner, Handle:db, const String:error[], any:data)
{	
	decl String:id[255], String:stored[255];
	new client;
	
	ResetPack(data);
	new userid = ReadPackCell(data);
	ReadPackString(data, id, sizeof(id));
	CloseHandle(data);
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(userid)) == 0)
	{
		return 0;
	}

	if (db == INVALID_HANDLE)
	{
		return 0;
	}
	
	while (SQL_FetchRow(db))
	{
		SQL_FetchString(db, 0, stored, sizeof(stored));
	}
	
	Call_StartForward(g_Fwd_OnClientPref);
	Call_PushCell(client);
	Call_PushString(id);
	Call_PushString(stored);
	Call_Finish();
	
	return 1;
}