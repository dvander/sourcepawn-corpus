#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1

Database dbLocal;

public Plugin myinfo =
{
	name = "SQLite Helper",
	author = "Eyal282",
	description = "Allows convenient database making with sqlite without prior knowledge required",
	version = "1.0",
	url = "",
};

new bool:Connected = false;

new Handle:fwConnected = INVALID_HANDLE;

public OnPluginStart()
{	
	fwConnected = CreateGlobalForward("SQLiteHelper_OnDatabaseConnected", ET_Ignore);
	
	Connected = false;
	TriggerTimer(CreateTimer(2.5, ConnectDatabase, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT), true);
	
}


public SQLiteHelper_OnDatabaseConnected()
{
	// Called when the database is connected.
	
	// Note: All of the plugin's natives are useless before this is called.
}


native bool:SQLiteHelper_isDatabaseConnected(const String:Name[100], String:Error[50]);

// return: true if the database is connected ( forward SQLiteHelper_OnDatabaseConnected was called ), false otherwise.

// Note: if this returns false ( rare occasions ) then no other native will work.

native SQLiteHelper_RegisterValue(const String:Name[100], String:Error[50]);

// Registers a value, must be done in the SQLiteHelper_OnDatabaseConnected forward ONLY!

// String:Name - Name of value, must be extra-unique to avoid collisions. If your plugin is named "CSGO Stats" and you want to save kills, use the name as "CSGO-Stats_Kills" or something similar.

// String:Error - Buffer in case of error. Go to SQLiteHelper.sp to see the possible errors.

// Note: Collision between two names may occur even if another plugin is not using this stock, so don't assume if you're the only plugin to use this stock collisions won't occur.

// Note: this function must be called only once in the lifetime of your plugin but it's always a good idea to keep this function because better safe than sorry.

native SQLiteHelper_SetClientValue(client, const String:Name[100], String:Error[50], const String:value[], timestamp=-1);

// Sets a client's value in the database based on value's name.

// client - Client to set the value for.

// String:Name - Name of value to set for the client.

// String:Error - Buffer in case of error. Go to SQLiteHelper.sp to see the possible errors.

// String:value - Value to set for the client.

// timestamp - Optional timestamp in the value's "last updated". This timestamp is unix and is retrieved through GetClientValue.

native SQLiteHelper_AddClientValue(client, const String:Name[100], String:Error[50], const String:value[], timestamp=-1);

// Note: The exact same as SetClientValue in terms of arguments so peek there for info here, EXCEPT it won't set the value but instead add the existing value with the value you put in String:value[].

// Note: You can set String:value[] to be a negative int / float for subtracting.

// Note: If you add a float to an int, the database will store the entire value as a float.

native SQLiteHelper_GetClientValue(client, const String:Name[100], String:Error[50], String:buffer[], length, &timestamp=0);

// Gets the value of a client.

// client - Client to get value from.

// Name - Name of value to get from.

// String:Error - Buffer in case of error. Go to SQLiteHelper.sp to see the possible errors.

// buffer - Buffer to store the value into.

// length - Length of buffer.

// timestamp - Copyback for the timestamp when last updated.

// Note: Buffer will be set to be empty if client was not found. This means that if you create the variable buffer to be non-empty and it becomes empty you can tell for sure that the client doesn't exist.

native SQLiteHelper_SetAuthIdValue(const String:AuthId[100], const String:Name[100], String:Error[50], String:value[], timestamp=-1);

native SQLiteHelper_AddAuthIdValue(const String:AuthId[100], const String:Name[100], String:Error[50], String:value[], timestamp=-1);

native SQLiteHelper_GetAuthIdValue(const String:AuthId[100], const String:Name[100], String:Error[50], String:buffer[], length, &timestamp=0);

// All these three natives about AuthId all act like their Client equivalents, except you provide the AuthId of an offline ( or online ) player.

// Note: For reference, if you were to use it on an online client, GetClientAuthId must use AuthId_Engine. This means the AuthId inside the database is the engine's and not any other AuthId types.

native SQLiteHelper_SortValue(const String:Name[100], bool:Ascending = false, String:Error[50], Handle:AuthIdArray, Handle:ValueArray, Handle:TimestampArray);

// Sorts values based on ascending or descending order.

// String:Name - Name of value to sort.

// bool:Ascending - true if to sort from lowest value to highest value. false to sort from highest value to lowest value. If false, the highest value will be 0 in the arrays.

// String:Error - Buffer in case of error. Go to SQLiteHelper.sp to see the possible errors.

// Handle:AuthIdArray - An array which YOU created to contain the Auth IDs that were sorted. CreateArray(100);

// Handle:ValueArray - An array which YOU created to contain the values that were sorted. CreateArray(100);

// Handle:TimestampArray - An array which YOU created to contain the timestamps of the values that were sorted. CreateArray(1).

// Note: Always create the arrays or you will get errors from this snippet.

// Note: Arrays are filled equally so in a single index within all arays, the data will match a single client.

// Note: If necessary you can use this native to irate through the entire database.

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SQLiteHelper_isDatabaseConnected", Native_isDatabaseConnected);
	CreateNative("SQLiteHelper_RegisterValue", Native_RegisterValue);
	CreateNative("SQLiteHelper_SetClientValue", Native_SetClientValue);
	CreateNative("SQLiteHelper_GetClientValue", Native_GetClientValue);
	CreateNative("SQLiteHelper_SetAuthIdValue", Native_SetAuthIdValue);
	CreateNative("SQLiteHelper_GetAuthIdValue", Native_GetAuthIdValue);
	CreateNative("SQLiteHelper_AddClientValue", Native_AddClientValue);
	CreateNative("SQLiteHelper_AddAuthIdValue", Native_AddAuthIdValue);
	CreateNative("SQLiteHelper_SortValue", Native_SortValue);
}

public Native_isDatabaseConnected(Handle:plugin, params)
{
	return Connected;
}
public Native_RegisterValue(Handle:plugin, params)
{
	if(!Connected)
	{
		SetNativeString(2, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	new String:Name[100];
	GetNativeString(1, Name, sizeof(Name));
	
	new String:sQuery[256];
       
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (AuthId VARCHAR(64) NOT NULL UNIQUE, value VARCHAR(256) NOT NULL, timestamp INT(15) NOT NULL)", Name); 
	
	if(!SQL_FastQuery(dbLocal, sQuery)) 
	{	
		SetNativeString(2, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
}

public Native_SetClientValue(Handle:plugin, params)
{	
	if(!Connected)
	{
		SetNativeString(3, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	new client = GetNativeCell(1);
	
	new String:AuthId[100];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:Name[100];
	GetNativeString(2, Name, sizeof(Name));
	
	new String:Value[256];
	
	new length;
	GetNativeStringLength(4, length);
	
	GetNativeString(4, Value, length+1);
	
	new String:sQuery[256];
        
	new timestamp = GetNativeCell(5);
	
	if(timestamp == -1)
		timestamp = GetTime();
		
	Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO %s VALUES (\"%s\", \"\", %i)", Name, AuthId, timestamp);
	
	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
	
	Format(sQuery, sizeof(sQuery), "UPDATE %s SET value = \"%s\", timestamp = %i WHERE AuthId = \"%s\"", Name, Value, timestamp, AuthId);

	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
}

public Native_AddClientValue(Handle:plugin, params)
{
	if(!Connected)
	{
		SetNativeString(3, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	new client = GetNativeCell(1);
	
	new String:AuthId[100];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:Name[100];
	GetNativeString(2, Name, sizeof(Name));
	
	new String:Value[256];
	
	new length;
	GetNativeStringLength(4, length);
	
	GetNativeString(4, Value, length+1);
	
	new String:sQuery[256];
        
	new timestamp = GetNativeCell(5);
	
	if(timestamp == -1)
		timestamp = GetTime();
		
	Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO %s VALUES (\"%s\", \"\", %i)", Name, AuthId, timestamp);
	
	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
	
	Format(sQuery, sizeof(sQuery), "UPDATE %s SET value = value + %s, timestamp = %i WHERE AuthId = \"%s\"", Name, Value, timestamp, AuthId);

	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
}

public Native_GetClientValue(Handle:plugin, params)
{
	if(!Connected)
	{
		SetNativeString(3, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	new client = GetNativeCell(1);
	
	new String:AuthId[100];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	new String:Name[100];
	GetNativeString(2, Name, sizeof(Name));
	
	new String:sQuery[256];
        
	Format(sQuery, sizeof(sQuery), "SELECT * FROM %s WHERE AuthId = \"%s\"", Name, AuthId); 

	new DBResultSet:hResults = SQL_Query(dbLocal, sQuery); 
	
	if(hResults == null) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
	if(hResults.RowCount == 0) // If a row was not found.
	{
		SetNativeString(4, "", 1);
		return;
	}

	hResults.FetchRow();

	hResults.FetchString(1, sQuery, sizeof(sQuery));
	
	SetNativeString(4, sQuery, GetNativeCell(5));
}

public Native_SetAuthIdValue(Handle:plugin, params)
{	
	if(!Connected)
	{
		SetNativeString(3, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	new String:AuthId[100];
	GetNativeString(1, AuthId, sizeof(AuthId));
	
	new String:Name[100];
	GetNativeString(2, Name, sizeof(Name));
	
	new String:Value[256];
	
	new length;
	GetNativeStringLength(4, length);
	
	GetNativeString(4, Value, length+1);
	
	new String:sQuery[256];
        
	new timestamp = GetNativeCell(5);
	
	if(timestamp == -1)
		timestamp = GetTime();
		
	Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO %s VALUES (\"%s\", \"\", %i)", Name, AuthId, timestamp);
	
	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
	
	Format(sQuery, sizeof(sQuery), "UPDATE %s SET value = \"%s\", timestamp = %i WHERE AuthId = \"%s\"", Name, Value, timestamp, AuthId);

	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
}

public Native_AddAuthIdValue(Handle:plugin, params)
{
	if(!Connected)
	{
		SetNativeString(3, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	new String:AuthId[100];
	GetNativeString(1, AuthId, sizeof(AuthId));
	
	new String:Name[100];
	GetNativeString(2, Name, sizeof(Name));
	
	new String:Value[256];
	
	new length;
	GetNativeStringLength(4, length);
	
	GetNativeString(4, Value, length+1);
	
	new String:sQuery[256];
        
	new timestamp = GetNativeCell(5);
	
	if(timestamp == -1)
		timestamp = GetTime();
		
	Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO %s VALUES (\"%s\", \"\", %i)", Name, AuthId, timestamp);
	
	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
	
	Format(sQuery, sizeof(sQuery), "UPDATE %s SET value = value + %s, timestamp = %i WHERE AuthId = \"%s\"", Name, Value, timestamp, AuthId);

	if(!SQL_FastQuery(dbLocal, sQuery)) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
}

public Native_GetAuthIdValue(Handle:plugin, params)
{
	if(!Connected)
	{
		SetNativeString(3, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	
	new String:AuthId[100];
	GetNativeString(1, AuthId, sizeof(AuthId));
	
	new String:Name[100];
	GetNativeString(2, Name, sizeof(Name));
	
	new String:sQuery[256];
        
	Format(sQuery, sizeof(sQuery), "SELECT * FROM %s WHERE AuthId = \"%s\"", Name, AuthId); 

	new DBResultSet:hResults = SQL_Query(dbLocal, sQuery); 
	
	if(hResults == null) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
	if(hResults.RowCount == 0) // If a row was not found.
	{
		SetNativeString(4, "", 1);
		return;
	}

	hResults.FetchRow();

	hResults.FetchString(1, sQuery, sizeof(sQuery));
	
	SetNativeString(4, sQuery, GetNativeCell(5));
}

public Native_SortValue(Handle:plugin, params)
{
	if(!Connected)
	{
		SetNativeString(3, "SQLiteHelperError_NotConnected", 50);
		return;
	}
	new String:Name[100];
	GetNativeString(1, Name, sizeof(Name));
	
	new String:sQuery[256];
	
	new bool:Ascending = view_as<bool>(GetNativeCell(2));
		
	Format(sQuery, sizeof(sQuery), "SELECT * FROM %s ORDER BY value %s", Name, Ascending ? "ASC" : "DESC" );

	new DBResultSet:hResults = SQL_Query(dbLocal, sQuery); 	
	if(hResults == null) // If query failed.
	{
		SetNativeString(3, "SQLiteHelperError_QueryFailed", 50);
		return;
	}	
	if(hResults.RowCount == 0) // If a row was not found
		return;

	new Handle:AuthIdArray = GetNativeCell(4);
	new Handle:ValueArray = GetNativeCell(5);
	new Handle:TimestampArray = GetNativeCell(6);
	
	new String:AuthID[100], String:Value[100];
	while(hResults.FetchRow())
	{
		hResults.FetchString(0, AuthID, sizeof(AuthID));
		PushArrayString(AuthIdArray, AuthID);
		
		hResults.FetchString(1, Value, sizeof(Value));
		PushArrayString(ValueArray, Value);
		
		new Timestamp = hResults.FetchInt(2);
		PushArrayCell(TimestampArray, Timestamp);

	}
}
public Action:ConnectDatabase(Handle:hTimer)
{
	if(dbLocal != INVALID_HANDLE)
	{
		Connected = true;
		return Plugin_Stop;
	}	
	new String:Error[256];
	if((dbLocal = SQLite_UseDatabase("sourcemod-local", Error, sizeof(Error))) == INVALID_HANDLE)
	{
		LogError(Error);
		return Plugin_Continue;
	}	
	else
	{ 
		Connected = true;
		new nullint;
		Call_StartForward(fwConnected);
		
		
		Call_Finish(nullint);
		return Plugin_Stop;
	}
}

public SQL_Error(Database db, DBResultSet hResults, const char[] Error, Data) 
{ 
    if(hResults == null) 
        ThrowError(Error);
} 

