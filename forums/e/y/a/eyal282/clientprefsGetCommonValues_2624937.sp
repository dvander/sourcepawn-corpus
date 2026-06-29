#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1



Database dbClientPrefs;

enum enValuesList
{
	String:vlValue[128],
	vlValueCount
};	
new ValuesList[enValuesList];

public Plugin myinfo =
{
	name = "Client prefs Common values",
	author = "Eyal282",
	description = "I wonder what's the most chosen song by the players, to give to the new players by default.",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=309777",
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	new String:Error[256];
	dbClientPrefs = SQLite_UseDatabase("clientprefs-sqlite", Error, sizeof(Error));
	
	if(dbClientPrefs == INVALID_HANDLE)
		SetFailState("Thanos car");
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:autism[], bool:dontautism)
{
	GetCookieCommonValues("UsefulCommands_PartyMode", true);
}


stock GetCookieCommonValues(const String:Name[], bool:LiveResults = true)
{
	new String:sQuery[256];

	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookies WHERE name = \"%s\"", Name); 

	new Handle:DP = CreateDataPack();
	
	WritePackString(DP, Name);
	WritePackCell(DP, LiveResults);
	SQL_TQuery(dbClientPrefs, SQLCB_FindCookieIdByName, sQuery, DP); 

}
public SQLCB_FindCookieIdByName(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	new String:Name[64];
	ResetPack(DP);
	
	ReadPackString(DP, Name, sizeof(Name));
	new bool:LiveResults = ReadPackCell(DP);
	CloseHandle(DP);
	
	if(hndl == null || SQL_GetRowCount(hndl) == 0)
		return; // Cookie not found.

	new Handle:Cookie = FindClientCookie(Name);
	
	if(Cookie == INVALID_HANDLE)
		return; // Cookie not found.
		
	SQL_FetchRow(hndl);
      
	new ID = SQL_FetchInt(hndl, 0);
	
	new String:RemovedAuthIds[(MAXPLAYERS * 40)] = "\"BOT\", ", String:TempValue[128], Handle:LiveValuesTrie = INVALID_HANDLE, String:AuthId[35];
	
	new currentcount;
	
	if(LiveResults)
	{
		LiveValuesTrie = CreateTrie();
		
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(!AreClientCookiesCached(i))
				continue;
				
			else if(IsFakeClient(i))
				continue;
			
			GetClientCookie(i, Cookie, TempValue, sizeof(TempValue));
			
			if(TempValue[0] == EOS)
				continue;
				
			GetClientAuthId(i, AuthId_Engine, AuthId, sizeof(AuthId));
			Format(RemovedAuthIds, sizeof(RemovedAuthIds), "%s\"%s\", ", RemovedAuthIds, AuthId);
			
			GetTrieValue(LiveValuesTrie, TempValue, currentcount);
			SetTrieValue(LiveValuesTrie, TempValue, currentcount+1, true);
		}
	}
	RemovedAuthIds[strlen(RemovedAuthIds)-2] = EOS;

	new String:sQuery[256 + sizeof(RemovedAuthIds)];

	if(LiveResults)
		Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookie_cache WHERE cookie_id = %i EXCEPT SELECT * FROM sm_cookie_cache WHERE player IN (%s) ORDER BY value ASC", ID, RemovedAuthIds); // ASC or DESC don't really matter...
	
	else
		Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookie_cache WHERE cookie_id = %i ORDER BY value ASC", ID); // ASC or DESC don't really matter...

	DP = CreateDataPack();

	WritePackCell(DP, LiveResults);
	WritePackCell(DP, LiveValuesTrie);
	SQL_TQuery(dbClientPrefs, SQLCB_GetCookieCommonValues, sQuery, DP); 
}

public SQLCB_GetCookieCommonValues(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	ResetPack(DP);
	
	new bool:LiveResults = ReadPackCell(DP);
	new Handle:LiveValuesTrie = ReadPackCell(DP);
	
	CloseHandle(DP);

	if(hndl == null)
	{
		if(LiveValuesTrie != INVALID_HANDLE)
			CloseHandle(LiveValuesTrie);
			
		ThrowError(sError);
	}
	/*
	else if(SQL_GetRowCount(hndl) == 0)
	{
		if(LiveValuesTrie != INVALID_HANDLE)
			CloseHandle(LiveValuesTrie);
			
		return; // Value was never set.
	}
	*/
	new String:Value[128], String:LastValue[sizeof(Value)], count = 0, Handle:ValuesArray;
	
	ValuesArray = CreateArray(sizeof(Value)+2); // 2 for the integers.
	
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 2, Value, sizeof(Value));
		
		if(StrEqual(LastValue, Value, false) || LastValue[0] == EOS)
		{
			if(Value[0] == EOS)
				continue;

			count++;
		}
		else
		{	
			FormatEx(ValuesList[vlValue], sizeof(Value), LastValue);
			ValuesList[vlValueCount] = count;
			PushArrayArray(ValuesArray, ValuesList);
			count = 0;
		}
		
		FormatEx(LastValue, sizeof(Value), Value);

	}
	
	FormatEx(ValuesList[vlValue], sizeof(Value), Value);
	ValuesList[vlValueCount] = count;
	PushArrayArray(ValuesArray, ValuesList);
	
	if(LiveResults)
	{
		new Handle:TempTrieSnapshot = CreateTrieSnapshot(LiveValuesTrie);
		
		new String:Key[64], tsLength = TrieSnapshotLength(TempTrieSnapshot), arSize = GetArraySize(ValuesArray);
		for(new i=0;i < tsLength;i++)
		{
			new Count = 0, bool:found=false;
			GetTrieSnapshotKey(TempTrieSnapshot, i, Key, sizeof(Key));
			
			for(new arIndex=0;arIndex < arSize;arIndex++)
			{
				GetArrayArray(ValuesArray, arIndex, ValuesList);
				GetTrieValue(LiveValuesTrie, Key, Count);
				
				if(StrEqual(Key, ValuesList[vlValue]))
				{
					ValuesList[vlValueCount] += Count;
					SetArrayArray(ValuesArray, arIndex, ValuesList);
					found = true;
					arIndex = arSize; // Equal to break
				}
			}
				
			if(!found)
			{
				FormatEx(ValuesList[vlValue], sizeof(Value), Key);
				ValuesList[vlValueCount] = Count;
				PushArrayArray(ValuesArray, ValuesList);
			}
				
		}
		
		CloseHandle(TempTrieSnapshot);
		
	}
	SortADTArrayCustom(ValuesArray, SortCB_CommonValues);
	
	OnGetCommonCookieValues(ValuesArray);
	
	CloseHandle(ValuesArray);
	
	if(LiveValuesTrie != INVALID_HANDLE)
		CloseHandle(LiveValuesTrie);
}

OnGetCommonCookieValues(Handle:ValuesArray)
{
	GetArrayArray(ValuesArray, 0, ValuesList);
	PrintToChatAll("The most common cookie choice is %s, with %i players choosing it.", ValuesList[vlValue], ValuesList[vlValueCount]);
	
	GetArrayArray(ValuesArray, 1, ValuesList);
	PrintToChatAll("The second most common cookie choice is %s, with %i players choosing it.", ValuesList[vlValue], ValuesList[vlValueCount]);
}

/*
 * @return				-1 if first should go before second
 *					0 if first is equal to second
 *					1 if first should go after second
 */
 
public SortCB_CommonValues(index1, index2, Handle:Array, Handle:autism)
{
	new ValueIndex1, ValueIndex2;
	
	GetArrayArray(Array, index1, ValuesList);
	ValueIndex1 = ValuesList[vlValueCount];
	
	GetArrayArray(Array, index2, ValuesList);
	ValueIndex2 = ValuesList[vlValueCount];
	
	if(ValueIndex1 > ValueIndex2)
		return -1;
		
	else if(ValueIndex1 < ValueIndex2)
		return 1;
		
	return 0;
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
		return Plugin_Stop;
}

public SQL_Error(Handle:db, Handle:hndl, const char[] Error, autism) 
{ 
    if(hndl == null) 
        ThrowError(Error);
} 

