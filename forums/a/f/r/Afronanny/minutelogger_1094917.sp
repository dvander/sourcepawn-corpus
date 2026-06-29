#include <sourcemod>

new Handle:hTimer[MAXPLAYERS];
new iMinutes[MAXPLAYERS];
new Handle:hKvFile;

new Handle:hDeleteTimer;

new iMinimumTime = 30;
new Float:fDeleteAfter = 36288000.0;

new Handle:hCvarMinTime;
new Handle:hCvarDeleteAfter;

public Plugin:myinfo = 
{
	name = "Minute Logger",
	author = "Afronanny",
	description = "Log Players' Playtimes by the minute",
	version = "1.0",
	url = "http://teamfail.net/"
}

public OnPluginStart()
{
	if (!FileExists("minutelog.txt"))
	{
		hKvFile = OpenFile("minutelog.txt", "w");
		CloseHandle(hKvFile);
	}
	hKvFile = CreateKeyValues("minutes");
	
	new maxclients = GetMaxClients();
	for (new i = 1; i < maxclients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			hTimer[i] = CreateTimer(60.0, Timer_MinuteReached, i, TIMER_REPEAT);
	}
	
	hDeleteTimer = CreateTimer(fDeleteAfter, Timer_Delete, INVALID_HANDLE, TIMER_REPEAT);
	
	hCvarMinTime = CreateConVar("sm_minutelogger_minimum", "30", "Minimum time to not get deleted", FCVAR_PLUGIN, true, 0.0);
	hCvarDeleteAfter = CreateConVar("sm_minutelogger_deleteafter", "36288000.0", "Time to delete data after", FCVAR_PLUGIN, true, 0.0);
	
	HookConVarChange(hCvarMinTime, ConVarChanged_MinTime);
	HookConVarChange(hCvarDeleteAfter, ConVarChanged_DeleteAfter);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	decl String:sAuthId[32];
	
	GetClientAuthString(client, sAuthId, sizeof(sAuthId));
	
	KvRewind(hKvFile);
	KvJumpToKey(hKvFile, sAuthId, true);
	iMinutes[client] = KvGetNum(hKvFile, "minutes");
	
	hTimer[client] = CreateTimer(60.0, Timer_MinuteReached, client, TIMER_REPEAT);
	return true;
}

public Action:Timer_MinuteReached(Handle:timer, any:data)
{
	decl String:sAuthId[32];
	decl String:sName[128];
	
	GetClientName(data, sName, sizeof(sName));
	GetClientAuthString(data, sAuthId, sizeof(sAuthId));
	
	KvRewind(hKvFile);
	KvJumpToKey(hKvFile, sAuthId);
	if (IsClientInGame(data))
	{
		//Make sure they're not in spectator
		if (GetClientTeam(data) != 1)
		{
			iMinutes[data]++;
			KvRewind(hKvFile);
			KvJumpToKey(hKvFile, sAuthId, true);
			KvSetNum(hKvFile, "minutes", iMinutes[data]);
			KvSetString(hKvFile, "name", sName);
			
			RefreshKeyValues();
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Delete(Handle:timer)
{
	KvRewind(hKvFile);
	KvGotoFirstSubKey(hKvFile);
	for (;;)
	{
		
		if (KvGetNum(hKvFile, "minutes") < iMinimumTime)
		{
			if (KvDeleteThis(hKvFile) >= 0)
				break;
		}
	}
	
}

public OnClientDisconnect(client)
{
	if (!IsFakeClient(client))
		CloseHandle(hTimer[client]);
	RefreshKeyValues();
	iMinutes[client] = 0;
}

public RefreshKeyValues()
{
	KvRewind(hKvFile);
	KeyValuesToFile(hKvFile, "minutelog.txt");
	CloseHandle(hKvFile);
	
	hKvFile = CreateKeyValues("minutes");
	FileToKeyValues(hKvFile, "minutelog.txt");
}

public ConVarChanged_DeleteAfter(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CloseHandle(hDeleteTimer);
	fDeleteAfter = StringToFloat(newValue);
	hDeleteTimer = CreateTimer(fDeleteAfter, Timer_Delete, INVALID_HANDLE, TIMER_REPEAT);
}		

public ConVarChanged_MinTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	iMinimumTime = StringToInt(newValue);
}

