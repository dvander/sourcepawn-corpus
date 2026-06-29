#pragma semicolon 1

#define PLUGIN_AUTHOR "Addicted"
#define PLUGIN_VERSION "1.00"

#include <colors_csgo>
#pragma newdecls required
#include <sourcemod>

Handle db = INVALID_HANDLE;

int g_kills[MAXPLAYERS+1]  = {0, ...};

public Plugin myinfo = 
{
	name = "Color Rank",
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);	
	HookEvent("round_start", Event_RoundStart);

	Connect();
}

public void Connect()
{
	if (SQL_CheckConfig("colorranks"))
		SQL_TConnect(OnDatabaseConnect, "colorranks");
	else
		SetFailState("Can't find 'colorranks' in databases.cfg");
}

public void OnDatabaseConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		PrintToServer("Failed to connect: %s", error);
		SetFailState("Failed to connect, SQL Error:  %s", error);
		return;
	}

	db = hndl;
	SQL_CreateTables();
}

public void SQL_CreateTables()
{
	char sQuery[1256];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS colorranks (name VARCHAR(22), steamid VARCHAR(22), kills INT(16), PRIMARY KEY (steamid))");	

	SQL_TQuery(db, SQLErrorCheckCallback, sQuery);
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!StrEqual("", error))
		LogError("SQL Error: %s", error);
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{	
		char sQuery[1256];
		
		char steamID[64];
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		
		Format(sQuery, sizeof(sQuery), "INSERT INTO `colorranks`(`name`, `steamid`, `kills`) VALUES (\"%N\",\"%s\",0) ON DUPLICATE KEY UPDATE `name` = \"%N\"", client, steamID, client);
		SQL_TQuery(db, SQLErrorCheckCallback, sQuery);

		g_kills[client]  = 0;

		Format(sQuery, sizeof(sQuery), "SELECT `kills` FROM `colorranks` WHERE steamid = \"%s\"", steamID);
		SQL_TQuery(db, SQLSetStats, sQuery, client);
	}
}

public void OnClientDisconnect(int client)
{	
	if(IsValidClient(client))
	{				
		char sQuery[1256];	
	
		char steamID[64];
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	
		Format(sQuery, sizeof(sQuery), "UPDATE `colorranks` SET `kills` = %i WHERE steamid = \"%s\"", g_kills[client], steamID);
		SQL_TQuery(db, SQLErrorCheckCallback, sQuery);
	}
}

public void SQLSetStats(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!IsValidClient(data))
	{
		CPrintToChat(data, "[{blue}Color Ranks{default}] {red}You are not a authorized! Please try again!{default}");
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		CPrintToChat(data, "[{blue}Color Ranks{default}] {red}Query failed!{default}");
		return;
	}
	
	else if (!SQL_GetRowCount(hndl)) 
	{
		CPrintToChat(data, "[{blue}Color Ranks{default}] {red}Database not initialized correctly! Please try again!{default}");
		return;
	}
	
	SQL_FetchRow(hndl);
	g_kills[data]  = SQL_FetchInt(hndl, 0);	
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontbroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	 
	if(IsValidClient(attacker) && attacker != victim)
	{
		g_kills[attacker] += 1;
	}
	
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{	
		if(IsValidClient(i))
		{
			CheckColors(i, g_kills[i]);
		}
	}
}  

public Action Event_RoundEnd(Handle event, const char[] name, bool dontbroadcast)
{	
	for(int i = 1; i <= MaxClients; i++)
	{	
		if(IsValidClient(i))
		{
			char sQuery[1256];	
	
			char steamID[64];
			GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));

			Format(sQuery, sizeof(sQuery), "UPDATE `colorranks` SET `kills` = %i WHERE steamid = \"%s\"", g_kills[i], steamID);
			SQL_TQuery(db, SQLErrorCheckCallback, sQuery);
		}
	}	
}

public void CheckColors(int client, int kills)
{
	if(kills >= 1000 && kills < 2000)
	{
		SetEntityRenderColor(client, 0, 255, 0, 255);	
	}
	else if(kills >= 2000)
	{
		SetEntityRenderColor(client, 0, 0, 255, 255);
	}
	else
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);	
	}
}

public bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (!IsClientAuthorized(client))
		return false;
	if (IsFakeClient(client))
		return false;
	
	return true;
} 