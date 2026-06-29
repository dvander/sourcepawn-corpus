#include <sourcemod>

#define MAX_MAPNAME_LENGTH 128
#define MAX_INT_STRING 6
#define MIN_PLAYERS	1

#define PL_VERSION "2.6"

public Plugin:myinfo = 
{
	name = "Default Map Changer",
	author = "TigerOx",
	description = "Changes the map to default if the server is empty.",
	version = PL_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=141399"
};

new g_PlyrCount;
new Handle:g_hPlyrData;

new Handle:g_hDefaultMap
new String:DefaultMap[MAX_MAPNAME_LENGTH];

new Handle:g_hTimerActive

public OnPluginStart()
{
	CreateConVar("sm_defaultmap_version", PL_VERSION, "Default Map Changer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	g_hDefaultMap = CreateConVar("sm_defaultmap", "de_nuke", "Default map", FCVAR_PLUGIN)
	
	g_hPlyrData = CreateTrie();
	
	g_hTimerActive = INVALID_HANDLE;
	
	HookEvent("player_disconnect", EventPlayerDisconnect, EventHookMode_Pre);
}

public OnClientConnected(client)
{
	decl String:index[MAX_INT_STRING];
	
	if(!client || IsFakeClient(client))
		return;
	
	if (g_hTimerActive != INVALID_HANDLE)
	{
		KillTimer(g_hTimerActive);
		CloseHandle(g_hTimerActive);
		g_hTimerActive = INVALID_HANDLE;
	}
	
	IntToString(GetClientUserId(client),index,MAX_INT_STRING);
	
	if(SetTrieValue(g_hPlyrData, index, 0, false) && !g_PlyrCount++)
	{
		new time;
		
		if(GetMapTimeLimit(time) && time && GetMapTimeLeft(time) && time < 0)
		{
			ServerCommand("mp_restartgame 1");
		}
	}
}

public Action:EventPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:index[MAX_INT_STRING];
	new userid = GetEventInt(event, "userid");
	
	if(!userid)
		return;
	
	IntToString(userid,index,MAX_INT_STRING);
	
	if(RemoveFromTrie(g_hPlyrData,index) && (--g_PlyrCount < MIN_PLAYERS))
	{
		SetDefaultMap();
	}
}

public OnMapStart()
{
	if(!g_PlyrCount)
	{
		SetDefaultMap();
	}
}

SetDefaultMap()
{
	g_hTimerActive = CreateTimer(60.0, ChangeMap)
}

public Action:ChangeMap(Handle:timer)
{
	decl String:buffer[MAX_MAPNAME_LENGTH];
	
	GetCurrentMap(buffer,MAX_MAPNAME_LENGTH);
	
	GetConVarString(g_hDefaultMap, DefaultMap, MAX_MAPNAME_LENGTH);
	
	if(!StrEqual(buffer,DefaultMap))
	{
		ForceChangeLevel(DefaultMap, "Server empty. Going to default map...");
	}
}