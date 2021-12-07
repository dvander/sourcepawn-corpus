#include <sourcemod>

enum Data
{
	Id,
	Frags,
};

new Handle:DB = INVALID_HANDLE;
new frags[MAXPLAYERS+1];
new rank[MAXPLAYERS+1][Data];

public Plugin:myinfo = 
{
	name = "Balance by Rank",
	author = "jaxoR",
	description = "This plugin balance teams according to the rank of the players",
	version = "1.0",
	url = "www.amxmodx-es.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	RegAdminCmd("sm_balance", command_balance, ADMFLAG_BAN);
	
	StartDB();
}

public StartDB()
{
	new String:Error[70];
	new String:query[300];
	
	DB = SQL_Connect("Balance", true, Error, sizeof(Error));
	
	if(DB == INVALID_HANDLE)
	{
		PrintToServer("MySQL Error - %s", Error);
		CloseHandle(DB);
	}
	else
	{
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS rank (steamid VARCHAR( 50 ) NOT NULL DEFAULT '', frags INT( 255 ) NOT NULL DEFAULT 0);");
		new Handle:queryC = SQL_Query(DB, query);
		
		if(queryC == INVALID_HANDLE)
		{
			SQL_GetError(DB, Error, sizeof(Error));
			PrintToServer("MySQL Error - %s", Error);
		}
	}
}

AllSpectator()
{
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i)) 
        {
            ChangeClientTeam(i, 1); 
        }
	}
}

MakeTable()
{
	new i, j;
	new aux[Data];
	
	for(i=1; i <= MaxClients; i++)
	{
		rank[i][Id] = i;
		rank[i][Frags] = frags[i];
	}
	
	for(i=2; i <= MaxClients; i++)
	{
		for(j=1; j <= MaxClients - 1; j++)
		{
			if(rank[j][Frags] > rank[j+1][Frags])
			{
				aux = rank[j];
				rank[j] = rank[j+1];
				rank[j+1] = aux;
			}
		}
	}
}

public Action:command_balance(client, args)
{
	new bool:team = false;
	
	PrintToChatAll("Balance started...");
	
	AllSpectator();
	MakeTable();
	
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i))
		{
			if(!team)
			{
				ChangeClientTeam(rank[i][Id], 2);
				team = true;
			}
			else
			{
				ChangeClientTeam(rank[i][Id], 3);
				team = false;
			}
		}
	}
}

public OnClientConnected(client)
{
	new String:Error[70];
	new String:steamid[32];
	new String:query[300];
	int frag = 0;
	
	GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
	
	Format(query, sizeof(query), "SELECT frags FROM rank WHERE steamid='%s'", steamid);
	new Handle:queryS = SQL_Query(DB, query);
	
	if(queryS != INVALID_HANDLE)
	{
		if(SQL_FetchRow(queryS))
		{
			SQL_FetchInt(queryS, 0, frag);
			frags[client] = frag;
		}
		else
		{
			new String:query2[300];
			
			Format(query2, 300, "INSERT INTO rank (steamid, frags) VALUES ('%s', %d)", steamid, frags);
			new Handle:queryI = SQL_Query(DB, query2);
			
			if(queryI == INVALID_HANDLE)
			{
				SQL_GetError(DB, Error, sizeof(Error));
				PrintToServer("MySQL Error - %s", Error);
			}
		}
	}
}

public OnClientDisconnect(client) 
{ 
	new String:Error[70];
	new String:steamid[32];
	new String:query[300];
	
	GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
	
	Format(query, sizeof(query), "UPDATE rank SET frags=%d WHERE steamid='%s'", frags[client], steamid);
	new Handle:queryU = SQL_Query(DB, query);
	
	if(queryU == INVALID_HANDLE)
	{
		SQL_GetError(DB, Error, sizeof(Error));
		PrintToServer("MySQL Error - %s", Error)
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victimId = event.GetInt("userid");
	int attackerId = event.GetInt("attacker");
	int victim = GetClientOfUserId(victimId);
	int attacker = GetClientOfUserId(attackerId);
	
	frags[attacker]++;
	frags[victim]--;
}