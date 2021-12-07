#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#define PLUGIN_NAME "[CSGO] Save Scores"
#define PLUGIN_VERSION "Save scores to a database and show scoreboard statistics."

new Handle:hConVars[5] = {INVALID_HANDLE, ...};

new bool:cv_bStatus, String:cv_sSQLEntry[64], bool:cv_bKills, bool:cv_bDeaths; 

new Handle:hDatabase;

new bool:bLoaded[MAXPLAYERS + 1];
new iKills[MAXPLAYERS + 1];
new iDeaths[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Keith Warren (Drixevel)",
	description = PLUGIN_VERSION,
	version = "1.0.0",
	url = "http://www.drixevel.com/"
};

public OnPluginStart()
{
	hConVars[0] = CreateConVar("savescores_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hConVars[1] = CreateConVar("sm_savescores_status", "1");
	hConVars[2] = CreateConVar("sm_savescores_sql_entry", "savescores");
	hConVars[3] = CreateConVar("sm_savescores_kills_display", "1");
	hConVars[4] = CreateConVar("sm_savescores_deaths_display", "1");
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	
	RegConsoleCmd("sm_t2", Test21);
}

public Action:Test21(client, args)
{
	CPrintToChat(client, "Kills: [%i] - Deaths: [%i] - bLoaded: [%i]", iKills[client], iDeaths[client], bLoaded[client]);
	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	cv_bStatus = GetConVarBool(hConVars[1]);
	GetConVarString(hConVars[2], cv_sSQLEntry, sizeof(cv_sSQLEntry));
	cv_bKills = GetConVarBool(hConVars[3]);
	cv_bDeaths = GetConVarBool(hConVars[4]);
	
	if (!cv_bStatus) return;
	
	if (hDatabase != INVALID_HANDLE)
	{
		CloseHandle(hDatabase);
		hDatabase = INVALID_HANDLE;
	}
	
	if (SQL_CheckConfig(cv_sSQLEntry))
	{
		SQL_TConnect(ConnectToSQL, cv_sSQLEntry);
	}
	else
	{
		LogError("Error retrieving SQL entry '%s' from database entry configuration file. Please verify integrity, attempting to use the default configuration instead.", cv_sSQLEntry);
		SQL_TConnect(ConnectToSQL);
	}
}

public OnPlayerSpawn(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_bStatus) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client) && bLoaded[client])
	{
		if (cv_bKills) SetEntProp(client, Prop_Data, "m_iFrags", iKills[client]);
		if (cv_bDeaths) SetEntProp(client, Prop_Data, "m_iDeaths", iDeaths[client]);
	}
}

public OnPlayerDeath(Handle:event, const String:sName[], bool:dontBroadcast)
{
	if (!cv_bStatus) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsClientInGame(client_killer)) iKills[client_killer]++;
	if (IsClientInGame(client)) iDeaths[client]++;
}

public ConnectToSQL(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Error connecting to database: %s", error);
		return;
	}
	
	hDatabase = hndl;
	LogMessage("Connected to database successfully. [%s]", cv_sSQLEntry);
	
	SQL_FastQuery(hDatabase, "CREATE TABLE IF NOT EXISTS `savescores` (`id` int(11) NOT NULL, `steam_id` varchar(32) NOT NULL, `kills` int(12) NOT NULL DEFAULT '0', `deaths` int(12) NOT NULL DEFAULT '0') ENGINE=MyISAM DEFAULT CHARSET=utf8;");
}

public OnClientConnected(client)
{
	bLoaded[client] = false;
	iKills[client] = -1;
	iDeaths[client] = -1;
}

public OnClientAuthorized(client, const String:sAuthID[])
{
	if (!cv_bStatus || IsFakeClient(client)) return;
	
	if (hDatabase == INVALID_HANDLE)
	{
		LogMessage("Database not connected, attempting to refresh client data in 5 seconds...");
		CreateTimer(5.0, RefreshClientData, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, GetClientUserId(client));
	WritePackString(hPack, sAuthID);
	
	new String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT kills, deaths FROM `savescores` where steam_id = '%s';", sAuthID);
	SQL_TQuery(hDatabase, RetrieveClientData, sQuery, hPack);
	LogMessage(sQuery);
}

public Action:RefreshClientData(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);
	if (cv_bStatus && IsClientInGame(client))
	{
		new String:sAuthID[64];
		GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID));
		OnClientAuthorized(client, sAuthID);
	}
}

public RetrieveClientData(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Error retrieving client info from database: %s", error);
		return;
	}
	
	ResetPack(data);
	
	new client = GetClientOfUserId(ReadPackCell(data));
	
	new String:sAuthID[64];
	ReadPackString(data, sAuthID, sizeof(sAuthID));
	
	CloseHandle(data);
	
	if(!client || !IsClientInGame(client) || IsFakeClient(client)) return;
	
	if (!SQL_FetchRow(hndl))
	{
		LogMessage("Client '%N' not found in the database, adding them.", client);
		
		new String:sQuery[512];
		Format(sQuery, sizeof(sQuery), "INSERT INTO `savescores` (steam_id, kills, deaths) VALUES ('%s', 0, 0);", sAuthID);
		SQL_FastQuery(hDatabase, sQuery);
		
		OnClientAuthorized(client, sAuthID);
		return;
	}
	else
	{
		LogMessage("Client '%N' found in database, retrieving data...", client);
	}
	
	iKills[client] = SQL_FetchInt(hndl, 0);
	iDeaths[client] = SQL_FetchInt(hndl, 1);
	
	LogMessage("Player '%N' has data that's been pulled successfully.", client);
	bLoaded[client] = true;
}

public OnClientDisconnect(client)
{
	if (!cv_bStatus || IsFakeClient(client)) return;
	
	new String:sAuthID[64];
	GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID));
	
	new String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "UPDATE `savescores` SET kills = '%i', deaths = '%i' WHERE steam_id = '%s';", iKills[client], iDeaths[client], sAuthID);
	SQL_FastQuery(hDatabase, sQuery);
	
	bLoaded[client] = false;
	iKills[client] = -1;
	iDeaths[client] = -1;
}