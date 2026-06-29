#include <sourcemod>

#define MAX_MAPNANE_LENGTH 128
#define MAX_INT_STRING 6
#define MIN_PLAYERS	1

#define PL_VERSION "2.5"

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

new String:g_DefaultMap[MAX_MAPNANE_LENGTH];


public OnPluginStart()
{
	CreateConVar("sm_defaultmap_version", PL_VERSION, "Default Map Changer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	GetCurrentMap(g_DefaultMap, MAX_MAPNANE_LENGTH);
	
	g_hPlyrData = CreateTrie();

	HookEvent("player_disconnect", EventPlayerDisconnect, EventHookMode_Pre);
}

public OnClientConnected(client)
{
	decl String:index[MAX_INT_STRING];
	
	if(!client || IsFakeClient(client))
		return;
	
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
	decl String:buffer[MAX_MAPNANE_LENGTH];
	
	GetCurrentMap(buffer,MAX_MAPNANE_LENGTH);
		
	if(!StrEqual(buffer,g_DefaultMap))
	{
		ForceChangeLevel(g_DefaultMap, "Server empty. Going to default map...");
	}
}