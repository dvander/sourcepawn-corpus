/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
//////////   	       Spray Tracker     	 ////////////
//////////                By Geit                ////////////
/////////////////////////////////////////////////////////////

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

/////////////////////////////////////////////////////////////
//////////////////////    SETUP    //////////////////////////
/////////////////////////////////////////////////////////////
#define PL_VERSION "1.11"

new bool:g_Recent[MAXPLAYERS+1] = false;

new Handle:g_StatsDB;

public Plugin:myinfo = 
{
	name = "Spray Tracker",
	author = "Geit",
	description = "Tracks spray names",
	version = PL_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=127776"
}


public OnPluginStart()
{	
	Stats_Init();
	CreateConVar("sm_spraytracker_version", PL_VERSION, "Spray 'n Display Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddTempEntHook("Player Decal",PlayerSpray);
}


public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay) {
	new client = TE_ReadNum("m_nPlayer");

	if(client && IsClientInGame(client) && g_Recent[client] == false) 
	{
		
		decl String:spray[96];
		if(!GetPlayerDecalFile(client, spray, sizeof(spray)))
			return;
		
		decl String:query[392], String:name[96], String:nbuffer[256], String:port[8]/*, String:buffer[256], String:steamid[25]*/, String:spraybuffer[256], String:ip[32];	
		
		GetConVarString(FindConVar("hostport"), port, sizeof(port));
		GetConVarString(FindConVar("ip"), ip, sizeof(ip));
		GetClientName(client, name, sizeof(name));
		SQL_EscapeString(g_StatsDB, name, nbuffer, sizeof(nbuffer));
		
		SQL_EscapeString(g_StatsDB, spray, spraybuffer, sizeof(spraybuffer));
		
		Format(query, sizeof(query), "UPDATE sprays SET date=NOW(), name='%s', port='%s', ip='%s', count=count+1 WHERE filename='%s' LIMIT 1", nbuffer, port, ip, spraybuffer);
		SQL_TQuery(g_StatsDB, T_ErrorOnly, query);
		
		Format(query, sizeof(query), "SELECT banned from sprays WHERE filename='%s' LIMIT 1", spraybuffer);
		SQL_TQuery(g_StatsDB, CB_BanCheck, query, client);
		
		g_Recent[client]=true;
		CreateTimer(2.0, Recent_Spray, client);
	}
}

public SprayDecal(client, entIndex, Float:pos[3]) 
{
TE_Start("Player Decal");
TE_WriteVector("m_vecOrigin", pos);
TE_WriteNum("m_nEntity", entIndex);
TE_WriteNum("m_nPlayer", client);
TE_SendToAll();
}

public Action:Recent_Spray(Handle:timer, any:client) 
{
	g_Recent[client]=false;
}
/////////////////////////////////////////////////////////////
//////////////////////   CALLBACKS	/////////////////////////
/////////////////////////////////////////////////////////////
public CB_BanCheck(Handle:owner, Handle:result, const String:error[], any:client) 
{
	if(result != INVALID_HANDLE && SQL_HasResultSet(result) && SQL_GetRowCount(result) >= 1) 
	{
		while(SQL_FetchRow(result))
		{
			if (SQL_FetchInt(result, 0) == 1) 
			{
				SprayDecal(client, 0, Float:{ 0.0, 0.0, 0.0 });
				PrintToChat(client, "You're not allowed to spray that!");
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	decl String:spray[96];
	
	if(IsClientInGame(client) && !IsFakeClient(client) && DatabaseIntact())
	{
		if(!GetPlayerDecalFile(client, spray, sizeof(spray)))
			return;
		
		decl String:query[392], String:steamid[25], String:name[96], String:spraybuffer[256], String:buffer[256], String:nbuffer[256], String:port[8], String:ip[32];
	
		GetConVarString(FindConVar("hostport"), port, sizeof(port));
		GetConVarString(FindConVar("ip"), ip, sizeof(ip));
		GetClientAuthString(client,steamid, sizeof(steamid));
		GetClientName(client, name, sizeof(name));
		
		SQL_EscapeString(g_StatsDB, steamid, buffer, sizeof(buffer));
		SQL_EscapeString(g_StatsDB, name, nbuffer, sizeof(nbuffer));
		SQL_EscapeString(g_StatsDB, spray, spraybuffer, sizeof(spraybuffer));
		
		Format(query, sizeof(query), "INSERT IGNORE INTO `sprays` (`steamid`, `name`, `port`, `filename`, `firstdate`, `ip`) VALUES('%s', '%s', '%s', '%s', NOW(), '%s')", buffer, nbuffer, port, spraybuffer, ip);
		SQL_TQuery(g_StatsDB, T_ErrorOnly, query);
	}
}

/////////////////////////////////////////////////////////////
/////////////////////////   SQL  ////////////////////////////
/////////////////////////////////////////////////////////////

public DatabaseIntact()
{
	if(g_StatsDB != INVALID_HANDLE)
	{
		return true;
	} else 
	{
		decl String:error[255];
		SQL_GetError(g_StatsDB, error, sizeof(error));
		PrintToServer("Database not intact (%s)", error);
		return false;
	}
}

public T_ErrorOnly(Handle:owner, Handle:result, const String:error[], any:client)
{
	if(result == INVALID_HANDLE)
	{
		LogError("[SPRAY] MYSQL ERROR (error: %s)", error);
	}
}

stock Stats_Init()
{
	decl String:error[255];
	PrintToServer("Connecting to database...");
	g_StatsDB = SQL_DefConnect(error, sizeof(error));
	if(g_StatsDB != INVALID_HANDLE)
	{
		SQL_TQuery(g_StatsDB, T_ErrorOnly, "SET NAMES UTF8", 0, DBPrio_High);
		PrintToServer("Connected successfully.");
	} else 
	{
		PrintToServer("Connection Failure!");
		LogError("[SPRAY] MYSQL ERROR (error: %s)", error);
	}
}