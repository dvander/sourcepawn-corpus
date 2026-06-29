#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define VERSION "0.0.1"


// Handle for the db
new Handle:db;
new String:LastName[MAXPLAYERS+1][32];
new LastChange[MAXPLAYERS+1];
new bool:g_PluginChangedName[MAXPLAYERS+1] = false;

new Handle:nnc_time = 				INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "No Name Change",
	author = "Mitch",
	description = "Cant change names until after a certain amount of time.",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("sm_nnc_version", VERSION, "No Name Change Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	nnc_time =	CreateConVar( "sm_nnc_time", "1440", "Time before the player can change their name again." );
	HookEvent("player_changename", OnPlayerChangeName, EventHookMode_Post);
	// Create database if it doesn't exist and create the table
	InitDB(db);
}


InitDB(&Handle:DbHNDL)
{

	// Errormessage Buffer
	new String:Error[255];
	
	// COnnect to the DB
	DbHNDL = SQL_Connect("storage-local", true, Error, sizeof(Error));
	
	
	// If something fails we quit
	if(DbHNDL == INVALID_HANDLE)
	{
		SetFailState(Error);
	}
	
	// Querystring
	new String:Query[255];
	Format(Query, sizeof(Query), "CREATE TABLE IF NOT EXISTS nonamechange (steamid TEXT UNIQUE, name TEXT, lastchange NUMERIC);");
	
	// Database lock
	SQL_LockDatabase(DbHNDL);
	
	// Execute the query
	SQL_FastQuery(DbHNDL, Query);
	
	// Database unlock
	SQL_UnlockDatabase(DbHNDL);
	
}

public Action:Timer_Rename(Handle:timer, any:client)
{	
	if (client != 0)
	{
		SetClientName(client, LastName[client]);
		g_PluginChangedName[client] = true;
	}
	return Plugin_Stop;
}


public OnPlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client) || g_PluginChangedName[client])
	{
		return;
	}

	decl String:newName[MAX_NAME_LENGTH];
	GetEventString(event, "newname", newName, MAX_NAME_LENGTH);
	if(!StrEqual(newName, LastName[client]))
	{
		dontBroadcast = true;
		CreateTimer(1.0, Timer_Rename, client );
	}
}
stock SetClientName(client, const String:name[])
{
    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);
}  
public OnClientPutInServer(client)
{
	if(IsClientValid(client) || !IsFakeClient(client))
	{
		new String:Name[32], String:steam[21];
		GetClientName(client, Name, sizeof(Name));
		GetClientAuthString(client, steam, sizeof(steam));
		g_PluginChangedName[client] = false;
		AddPlayer(steam, Name);
		ReadClient(client, steam);
	}
}
DisplayClient(client)
{
	if(IsClientValid(client))
	{
		if((GetTime() - LastChange[client]) >= GetConVarInt(nnc_time)*60)
		{
			new String:Name[32], String:steam[21];
			GetClientName(client, Name, sizeof(Name));
			GetClientAuthString(client, steam, sizeof(steam));
			UpdatePlayer(steam, Name);
		}
		else
		{
			SetClientName(client, LastName[client]);
			g_PluginChangedName[client] = true;
		}
		
	}
}
public OnClientDisconnect(client)
{
	if(IsClientValid(client))
	{
		new String:Name[32], String:steam[21];
		GetClientName(client, Name, sizeof(Name));
		GetClientAuthString(client, steam, sizeof(steam));
		AddPlayer(steam, Name);
		LastChange[client] = 0;
		Format(LastName[client], sizeof(LastName), "");
	}
}
AddPlayer(const String:Id[21], const String:Name[32])
{
	new String:Query[255];
	Format(Query, sizeof(Query), "INSERT OR IGNORE INTO nonamechange VALUES ('%s', '%s', '0')", Id, Name);
	SQL_TQuery(db, SQL_ErrorCheckCallBack, Query);
}
UpdatePlayer(const String:Id[21], const String:Name[32])
{
	new String:Query[255];
	new String:name[32];
	Format(name, sizeof(name), Name);
	ReplaceString(name, sizeof(name), "@", " ");
	Format(Query, sizeof(Query), "UPDATE nonamechange SET name = '%s', lastchange = '%i' WHERE steamid = '%s'", name, GetTime(), Id);
	SQL_TQuery(db, SQL_ErrorCheckCallBack, Query);
}

bool:ReadClient(client, const String:steamId[21])
{
	if(IsClientValid(client))
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT * FROM nonamechange WHERE steamid = '%s'", steamId);
		SQL_TQuery(db, SQL_ReadClient, buffer, client);
		return true;
	}
	return false;
}
public SQL_ReadClient(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl != INVALID_HANDLE)
	{
		if(SQL_FetchRow(hndl))
		{
			Format(LastName[data], sizeof(LastName), "");
			LastChange[data] = 0;
			new String:Buffer[32];
			SQL_FetchString(hndl, 1, Buffer, sizeof(Buffer));
			Format(LastName[data], sizeof(LastName), "%s", Buffer);
			LastChange[data] =	SQL_FetchInt(hndl, 2);
		}
	}
	DisplayClient(data);
}

public SQL_ErrorCheckCallBack(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("Query failed! %s", error);
	}
}

stock bool:IsClientValid(id)
{
	if(id >0 && IsClientConnected(id) && IsClientInGame(id)) return true;
	else return false;
}