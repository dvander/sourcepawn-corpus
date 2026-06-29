#include <sourcemod>
#include <csgocolors>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
	name        = "HeadShot Event",
	author      = "CamerDisco",
	description = "for some events",
	version     = PLUGIN_VERSION,
	url         = "http://max-play.pl"
};

Handle g_hDB;

ConVar turn;
ConVar turn_info_after_kill;
ConVar savetime;
ConVar minplayers;
ConVar advert;
ConVar time_advert;

int count[MAXPLAYERS+1];

bool loaded[MAXPLAYERS+1];
bool bad[MAXPLAYERS+1];
bool close;
bool connected;

public void OnPluginStart()
{
	DbConnect();
	
	HookEvent("player_death", Event_PlayerDeath);
	    
	RegConsoleCmd("sm_myhs", counths);
	
	LoadTranslations("headshot_event.phrases");
	
	turn = CreateConVar("sm_hsevent_on", "1", "on or off the plugin");
	turn_info_after_kill = CreateConVar("sm_hsevent_info_after_kill", "1", "display info to client about new headshot after kill");
	savetime = CreateConVar("sm_hsevent_savetime", "300.0", "as much time save headshots in database");
	minplayers = CreateConVar("sm_hsevent_minplayers", "2", "Amount of players who must be in the server to count headshots");
	advert = CreateConVar("sm_hsevent_advert", "1", "on/off advert about event");
	time_advert = CreateConVar("sm_hsevent_time_advert", "360.0", "time in float between adverts");
	
	for(int i = 1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
	
	CreateTimer(savetime.FloatValue, saveplayers, _, TIMER_REPEAT);
	
	if(advert.IntValue>0)
		CreateTimer(time_advert.FloatValue, giveinfo, _, TIMER_REPEAT);
	
	AutoExecConfig(true);
}

public void DbConnect()
{
	// db connection
	char error[256];
	g_hDB = SQL_Connect("hsevent", true, error, sizeof(error));
	if(g_hDB == null || strlen(error) > 0)
	{
		PrintToServer("[Mysql-EventHS] Unable to connect to database (%s)", error);
		LogError("[Mysql-EventHS] Unable to connect to database (%s)", error);
		connected = false;
		return;
	}
	else
	{
		connected = true;
		DoTables();
		PrintToServer("[Mysql-EventHS] Successfully connected to database!");
	}
}


public void OnMapEnd()
{
	SaveHsForAll();
}

public void DoTables()
{
	char query[512];

	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `hs` (`id` int(11) NOT NULL AUTO_INCREMENT, `steamid` text NOT NULL, `count` int(11) NOT NULL, `name` text NOT NULL, PRIMARY KEY (`id`)) ENGINE=MyISAM AUTO_INCREMENT=14030 DEFAULT CHARSET=utf8;");

	SQL_TQuery(g_hDB, SQLT_DoTables, query);
}

public void SQLT_DoTables(Handle owner, Handle hndl, const char[] error, any data)
{
	if(owner==INVALID_HANDLE || hndl==INVALID_HANDLE){
		LogError("SQL Error: %s", error);
		return;
	}
}

public void OnMapStart()
{
	LoadHSForAll();
}

public Action saveplayers(Handle timer)
{
	SaveHsForAll();
}


public Action giveinfo(Handle timer)
{
	CPrintToChatAll("%T", "advert", LANG_SERVER);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!IsValidClient(client)) return;
	if (!IsClientAuthorized(client)) return;
	if (turn.IntValue == 0) return;
	if (!connected) return;
	

	if(GetPlayerCount() >= minplayers.IntValue)
	{
		bool headshot = GetEventBool(event, "headshot");

		if(headshot) 
		{
			if(loaded[client])
			{
				count[client]++;
				
				if(turn_info_after_kill.IntValue>0)
				{
					CPrintToChat(client, "%T", "new headshot info", LANG_SERVER, count[client]);
				}
			}
			else PrintToChat(client, "error: 5");
		}
	}
}


public void OnClientPostAdminCheck(int client)
{	
	if (IsFakeClient(client)) return;
	if (!IsClientAuthorized(client)) return;
	
	close = true;
	
	loaded[client] = false;
	count[client]= 1;
	bad[client] = true;
	LoadHS(client);
	
	close = false;
}

public void OnClientDisconnect(int client)
{
	SaveHS(client);
}


public Action counths(int client, int args)
{
	CPrintToChat(client, "%T", "myhs command", LANG_SERVER, count[client], minplayers.IntValue);
}

public bool IsValidClient(int client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsClientSourceTV(client))
		return true;

	return false;
}

stock int GetPlayerCount()
{
	int iAmmount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			iAmmount++;
		}
	}
	return iAmmount;
}



public void LoadHS(int client){

	if (!IsClientAuthorized(client)) return;
	if (!close) return;
	
	char auth[64];
	char eauth[128];
	char query[512];
	
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	
	SQL_EscapeString(g_hDB, auth, eauth, sizeof(eauth));
	
	Format(query, sizeof(query), "SELECT count FROM hs WHERE steamid='%s'", eauth);
	
	if(SQL_TQuery(g_hDB, SQLT_LoadHS, query, GetClientUserId(client)))
	{
		loaded[client] = true;
	}
	
}

public void LoadHSForAll()
{
	for (int i = 1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			LoadHS(i);
		}
	}
}


public void SQLT_LoadHS(Handle owner, Handle hndl, const char[] error, any data){
	int client = GetClientOfUserId(data);
	
	if(client<=0) return;
	
	if(owner==INVALID_HANDLE || hndl==INVALID_HANDLE){
		LogError("SQL Error: %s", error);
		return;
	}
	
	
	if(SQL_GetRowCount(hndl)<=0){
		char query[256];
		char auth[64];
		char eauth[128];
		char clientname[256];
		char clientname2[256];
		
		
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
		SQL_EscapeString(g_hDB, auth, eauth, sizeof(eauth));
		
		GetClientName(client, clientname, 64);
		SQL_EscapeString(g_hDB, clientname, clientname2, sizeof(clientname2));
		
		Format(query, sizeof(query), "INSERT INTO `hs` (`id`, `steamid`, `count`, `name`) VALUES (NULL, '%s', %d, '%s')", eauth, count[client], clientname2);
		
		if(SQL_TQuery(g_hDB, SQLT_Error, query, _))
		{
			bad[client] = false;
		}
		
	}
	else
	{
		SQL_FetchRow(hndl);
		int field;
		if(SQL_FieldNameToNum(hndl, "count", field))
		{
			count[client] = SQL_FetchInt(hndl, field);
			bad[client] = false;
		}
	}
}

public void SQLT_Error(Handle owner, Handle hndl, const char [] error, any data){
	if(hndl==INVALID_HANDLE){
		LogError("SQL Error: %s", error);
	}
}


public void SaveHS(int client)
{
	if(!IsClientAuthorized(client)) return;
	if(!IsValidClient(client)) return;
	if(bad[client]) return;

	
	char query[512];
	char auth[64];
	char eauth[128];
	
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	SQL_EscapeString(g_hDB, auth, eauth, sizeof(eauth));
	Format(query, sizeof(query), "UPDATE `hs` SET `count`=%d WHERE hs.steamid = '%s'", count[client], eauth);
	
	SQL_TQuery(g_hDB, SQLT_Error, query, _);
}

public void SaveHsForAll()
{
	for (int i = 1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SaveHS(i);
		}
	}
}

