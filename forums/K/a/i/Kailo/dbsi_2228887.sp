/**
 * Database Simple Interface Plugin
 * Add natives for simple databases using.
 * 
 * Glad to be useful. Your, Kailo.
 * =============================================================================
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

public Plugin:myinfo =
{
	name = "Database Simple Interface",
	author = "Kailo",
	description = "Database handler.",
	version = "1.0",
	url = "http://steamcommunity.com/id/kailo97/"
};

new Handle:db = INVALID_HANDLE;
new Handle:dbsi_confname = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("SQL_Write", Native_SQL_Write);
   CreateNative("SQL_Read", Native_SQL_Read);
   return APLRes_Success;
}

public OnPluginStart()
{
	dbsi_confname = CreateConVar("dbsi_confname", "dbsi", "Config name from database.cfg for connect params.");	
	
	AutoExecConfig(true);
	
	new String:error[255], String:confname[128]
	GetConVarString(dbsi_confname, confname, 128)
	db = SQL_Connect(confname, false, error, 255)
	if (db == INVALID_HANDLE)
	{
		PrintToServer("Could not connect: %s (Confname: %s)(Reload plugin for try again)", error, confname)
	}
}

public OnPluginEnd()
{
	if (db != INVALID_HANDLE)
	{
		CloseHandle(db)
	}
}

public Native_SQL_Write(Handle:plugin, numParams)
{
	new client = GetNativeCell(2), String:id[64], String:text[1024], written, String:table[64]
	GetNativeString(1, table, 64)
	GetClientAuthString(client, id, 64)
	FormatNativeString(0, 3, 4, 1024, written, text)
	CheckTableInDB(table)
	if(CheckClientInDB(id, table)) {UpdateTextFromDB(id, text, table);}
	else {InsertTextInDB(id, text, table);}
}

public Native_SQL_Read(Handle:plugin, numParams)
{
	new len
	len = GetNativeCell(4)
	new client = GetNativeCell(2), String:text[len+1], String:id[64], String:table[64]
	GetNativeString(1, table, 64)
	GetClientAuthString(client, id, 64)
	CheckTableInDB(table)
	GetTextFromDB(id, text, len+1, table)
	SetNativeString(3, text, len+1, false);
}

CheckTableInDB(const String:table[])
{
	new String:query[128]
	Format(query, 128, "CREATE TABLE IF NOT EXISTS %s (id varchar(18) NOT NULL PRIMARY KEY, text varchar(1024) NOT NULL)", table)
	if (!SQL_FastQuery(db, query))
	{
		new String:error[255]
		SQL_GetError(db, error, 255)
		ThrowNativeError(SP_ERROR_NATIVE, "Failed to check table query (error: %s) (query: %s)", error, query);
	}
	
	return 1
}

bool:CheckClientInDB(const String:id[], const String:table[])
{
	new Handle:hCheckQuery, String:query[128]
	Format(query, 128, "SELECT * FROM %s WHERE id = '%s'", table, id)
	hCheckQuery = SQL_Query(db, query)
	if (hCheckQuery == INVALID_HANDLE)
	{
		new String:error[255]
		SQL_GetError(db, error, 255)
		ThrowNativeError(SP_ERROR_NATIVE, "Failed to check client query (error: %s) (query: %s)", error, query);
	}
	
	if(SQL_GetRowCount(hCheckQuery) == 0)
	{
		CloseHandle(hCheckQuery)
		return false;
	}
	
	CloseHandle(hCheckQuery)
	return true;
}

InsertTextInDB(const String:id[], const String:text[], const String:table[])
{
	new String:query[128]
	Format(query, 128, "INSERT INTO %s (id, text) VALUES ('%s', '%s')", table, id, text)
	if (!SQL_FastQuery(db, query))
	{
		new String:error[255]
		SQL_GetError(db, error, 255)
		ThrowNativeError(SP_ERROR_NATIVE, "Failed to insert query (error: %s) (query: %s)", error, query);
	}
	
	return 1
}

UpdateTextFromDB(const String:id[], const String:text[], const String:table[])
{
	new String:query[128]
	Format(query, 128, "UPDATE %s SET text = '%s' WHERE id = '%s'", table, text, id)
	if (!SQL_FastQuery(db, query))
	{
		new String:error[255]
		SQL_GetError(db, error, 255)
		ThrowNativeError(SP_ERROR_NATIVE, "Failed to update query (error: %s) (query: %s)", error, query);
	}
	
	return 1
}

GetTextFromDB(const String:id[], String:text[], maxlength, const String:table[])
{
	new Handle:hGetQuery, String:query[128]
	Format(query, 128, "SELECT text FROM %s WHERE id = '%s'", table, id)
	hGetQuery = SQL_Query(db, query)
	if (hGetQuery == INVALID_HANDLE)
	{
		new String:error[255]
		SQL_GetError(db, error, 255)
		ThrowNativeError(SP_ERROR_NATIVE, "Failed to get query (error: %s) (query: %s)", error, query);
	}
	
	if(SQL_GetRowCount(hGetQuery) == 0)
	{
		CloseHandle(hGetQuery)
		return 1;
	}
	
	SQL_FetchRow(hGetQuery);
	SQL_FetchString(hGetQuery, 0, text, maxlength);
	
	CloseHandle(hGetQuery)
	return 1;
}