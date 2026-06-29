#include <SteamWorks>
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <cstrike>

//Plugin infos
#define PLUGIN_AUTHOR 			"Arkarr"
#define PLUGIN_VERSION 			"1.00"
//CONFIG var
#define	DB_SAVE_INTERVAL		30
#define CLANTAG					"MY CLAN TAG"
#define STEAM_NAME_PHRASE		"STEAM NAME PHRASE"
#define GROUP_ID				0000000
//Database queries
#define	DB_CONFIGURATION_NAME	"mydatabaseCONFIG"
#define QUERY_INIT_DATABASE		"CREATE TABLE IF NOT EXISTS `player_time` (`steamid` varchar(45) NOT NULL, `stime` int NOT NULL, PRIMARY KEY (`steamid`))"
#define QUERY_LOAD_CLIENT_TIME	"SELECT `stime` FROM player_time WHERE `steamid`=\"%s\""
#define QUERY_UPDATE_ENTRY		"UPDATE `player_time` SET `stime`=\"%i\" WHERE `steamid`=\"%s\";"
#define QUERY_NEW_ENTRY			"INSERT INTO `player_time` (`steamid`,`stime`) VALUES (\"%s\", %i);"

EngineVersion engineName;

Handle DATABASE_PlayerTime;

bool IsInDatabase[MAXPLAYERS + 1];
bool inGroup[MAXPLAYERS + 1];

int NbrSeconds[MAXPLAYERS + 1];
int Seconds;
int Tick;

public Plugin myinfo = 
{
	name = "[ANY] Play Time Recorder",
	author = PLUGIN_AUTHOR,
	description = "Record the number of seconds a player spent on the server.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	CreateTimer(1.0, TMR_UpdateClientTime, _, TIMER_REPEAT);
	
	engineName = GetEngineVersion();
}

public void OnConfigsExecuted()
{
	SQL_TConnect(GotDatabase, DB_CONFIGURATION_NAME);
}

public void OnClientPutInServer(int client)
{
	SteamWorks_GetUserGroupStatus(client, GROUP_ID);
}

public void OnClientConnected(int client)
{
	LoadPlayTime(client);
}

public void OnClientDisconnect(int client)
{
	SaveIntoDatabase(client);
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
	int client = GetUserFromAuthID(authid);
	if(isMember)
		inGroup[client] = true;	
}

public int GetUserFromAuthID(int authid)
{
	for(int i=1; i<=MaxClients; i++)
	{
		char authstring[50];
		GetClientAuthId(i, AuthId_Steam3, authstring, sizeof(authstring));	
		
		char authstring2[50];
		IntToString(authid, authstring2, sizeof(authstring2));
		
		if(StrContains(authstring, authstring2) != -1)
		{
			return i;
		}
	}
	
	return -1;
}

public Action TMR_UpdateClientTime(Handle tmr)
{
	Tick++;
	Seconds++;
	for(int client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(Seconds >= 60)
			{
				if(engineName == Engine_CSGO && inGroup[client])
				{
					char clanTag[45];
					CS_GetClientClanTag(client, clanTag, sizeof(clanTag));
					if(StrEqual(clanTag, CLANTAG))
						NbrSeconds[client]++;
				}
				
				char clientName[100];
				GetClientName(client, clientName, sizeof(clientName));
				if(StrEqual(STEAM_NAME_PHRASE, clientName))
						NbrSeconds[client]++;				
			}
			
			NbrSeconds[client]++;
			if(Tick >= DB_SAVE_INTERVAL && DATABASE_PlayerTime != INVALID_HANDLE)
				SaveIntoDatabase(client);
		}
	}
	
	if(Seconds >= 60)
		Seconds = 0;
		
	if(Tick >= DB_SAVE_INTERVAL)
		Tick = 0;
}

public void LoadPlayTime(int client)
{
	char query[100];
	char steamid[30];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	Format(query, sizeof(query), QUERY_LOAD_CLIENT_TIME, steamid);
	SQL_TQuery(DATABASE_PlayerTime, T_GetPlayerInfo, query, client);
}

public GotDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
		return;
	}
	
	DATABASE_PlayerTime = hndl;
	
	char buffer[300];
	if (!SQL_FastQuery(DATABASE_PlayerTime, QUERY_INIT_DATABASE))
	{
		SQL_GetError(DATABASE_PlayerTime, buffer, sizeof(buffer));
		SetFailState("%s", buffer);
	}
	
	for (int z = 0; z < MaxClients; z++)
	{
		if (!IsClientInGame(z))
			continue;
		
		LoadPlayTime(z);
	}
}

public void T_GetPlayerInfo(Handle db, Handle results, const char[] error, any data)
{
	if(DATABASE_PlayerTime == INVALID_HANDLE)
		return;
		
	int client = data;
	
	if (!IsClientInGame(client))
		return;
	
	if (!SQL_FetchRow(results))
	{
		IsInDatabase[client] = false;
	}
	else
	{
		NbrSeconds[client] = SQL_FetchInt(results, 0);
		IsInDatabase[client] = true;
	}
}

public void SaveIntoDatabase(int client)
{
	char query[400];
	char steamid[30];
	
	if (!GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid)))
		return;
	
	if (IsInDatabase[client])
	{
		Format(query, sizeof(query), QUERY_UPDATE_ENTRY, NbrSeconds[client], steamid);
		SQL_FastQuery(DATABASE_PlayerTime, query);
	}
	else
	{
		Format(query, sizeof(query), QUERY_NEW_ENTRY, steamid, NbrSeconds[client]);
		SQL_FastQuery(DATABASE_PlayerTime, query);
	}
}
