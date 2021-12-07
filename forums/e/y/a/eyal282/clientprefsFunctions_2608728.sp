#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1

Database dbClientPrefs;

public Plugin myinfo =
{
	name = "Client prefs functions",
	author = "Eyal282",
	description = "Adds useful functions to clientprefs",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=309777",
};

new Handle:fwConnected = INVALID_HANDLE;

public OnPluginStart()
{	
	fwConnected = CreateGlobalForward("clientprefsFunc_OnDatabaseConnected", ET_Ignore);
	
	TriggerTimer(CreateTimer(2.5, ConnectDatabase, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT), true);
	
}

// For information about the natives go to "https://forums.alliedmods.net/showthread.php?t=309777"

native clientprefsFunc_GetAuthIdCookie(const String:Name[100], const String:AuthId[100], String:buffer[], length, &timestamp);
native clientprefsFunc_SortCookie(const String:Name[100], bool:Ascending = false, String:Error[50], Handle:AuthIdArray, Handle:ValueArray, Handle:TimestampArray);

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("clientprefsFunc_SortCookie", Native_SortCookie);
	CreateNative("clientprefsFunc_GetAuthIdCookie", Native_GetAuthIdCookie);
}

public Native_GetAuthIdCookie(Handle:plugin, params)
{
	new String:Name[100];
	GetNativeString(1, Name, sizeof(Name));
	
	new String:AuthId[100];
	GetNativeString(2, AuthId, sizeof(AuthId));
	
	new String:sQuery[256];
        
	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookies WHERE name = \"%s\"", Name); 

	new DBResultSet:hResults = SQL_Query(dbClientPrefs, sQuery); 
	
	if(hResults == null || hResults.RowCount == 0) // If query failed or a row was not found.
	{
		SetNativeString(3, "clientprefsFuncError_CookieNotFound", GetNativeCell(4));
		return;
	}	
	hResults.FetchRow();
	
	new ID = hResults.FetchInt(0);
		
	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookie_cache WHERE cookie_id = %i AND player = \"%s\"", ID, AuthId);
		
	hResults = SQL_Query(dbClientPrefs, sQuery); 
	
	if(hResults == null || hResults.RowCount == 0) // If query failed or a row was not found.
	{
		SetNativeString(3, "clientprefsFuncError_AuthIdNotFound", GetNativeCell(4));
		return;
	}
	
	hResults.FetchRow();

	hResults.FetchString(2, sQuery, sizeof(sQuery));

	SetNativeString(3, sQuery, GetNativeCell(4));
	
	new timestamp = hResults.FetchInt(3);
	
	SetNativeCellRef(5, timestamp);
}

public Native_SortCookie(Handle:plugin, params)
{
	new String:Name[100];
	GetNativeString(1, Name, sizeof(Name));
	
	new String:sQuery[256];
        
	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookies WHERE name = \"%s\"", Name); 

	new DBResultSet:hResults = SQL_Query(dbClientPrefs, sQuery); 
	
	if(hResults == null || hResults.RowCount == 0) // If query failed or a row was not found.
	{
		SetNativeString(3, "clientprefsFuncError_CookieNotFound", 50);
		return;
	}	
	
	new bool:Ascending = view_as<bool>(GetNativeCell(2));
	
	hResults.FetchRow();
      
	new ID = hResults.FetchInt(0);
		
	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookie_cache WHERE cookie_id = %i ORDER BY value %s", ID, Ascending ? "ASC" : "DESC" );

	hResults = SQL_Query(dbClientPrefs, sQuery); 
	
	if(hResults == null || hResults.RowCount == 0) // If query failed or a row was not found.
	{
		SetNativeString(3, "clientprefsFuncError_CookieEmpty", 50);
		return;
	}	
	
	new Handle:AuthIdArray = GetNativeCell(4);
	new Handle:ValueArray = GetNativeCell(5);
	new Handle:TimestampArray = GetNativeCell(6);
	
	new String:AuthID[100], String:Value[100];
	while(hResults.FetchRow())
	{
		hResults.FetchString(0, AuthID, sizeof(AuthID));
		PushArrayString(AuthIdArray, AuthID);
		
		hResults.FetchString(2, Value, sizeof(Value));
		PushArrayString(ValueArray, Value);
		
		new Timestamp = hResults.FetchInt(3);
		PushArrayCell(TimestampArray, Timestamp);

	}
	
	SetNativeString(3, "", 50);
}
public Action:ConnectDatabase(Handle:hTimer)
{
	if(dbClientPrefs != INVALID_HANDLE)
		return Plugin_Stop;
		
	new String:Error[256];
	if((dbClientPrefs = SQLite_UseDatabase("clientprefs-sqlite", Error, sizeof(Error))) == INVALID_HANDLE)
	{
		LogError(Error);
		return Plugin_Continue;
	}	
	else
	{ 
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

