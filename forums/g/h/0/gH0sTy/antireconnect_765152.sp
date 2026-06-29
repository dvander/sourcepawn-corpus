#include <sourcemod>

#define PLUGIN_VERSION "1.0.4"

public Plugin:myinfo = 
{
	name = "Anti-Reconnect",
	author = "exvel, gH0sTy",
	description = "Blocking people for time from reconnecting",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new Handle:sldb = INVALID_HANDLE;
new Handle:cvar_ar_time = INVALID_HANDLE;
new Handle:cvar_ar_admin_immunity = INVALID_HANDLE;
new bool:isLAN = false;
//new bool:isZombie = false;

public OnPluginStart()
{
	InitDB();
	ClearDB();
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	isLAN = GetConVarBool(FindConVar("sv_lan"));
	
	CreateConVar("sm_anti_reconnect_version", PLUGIN_VERSION, "Anti-Reconnect Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_ar_time = CreateConVar("sm_anti_reconnect_time", "90", "Time in seconds players must to wait before connect to the server again after disconnecting, 0 = disabled", FCVAR_PLUGIN, true, 0.0);
	cvar_ar_admin_immunity = CreateConVar("sm_anti_reconnect_admin_immunity", "0", "0 = disabled, 1 = protect admins from Anti-Reconnect functionality", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	LoadTranslations("antireconnect.phrases.txt");
	AutoExecConfig(true);
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:reason[128];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "reason", reason, 128);
	if (StrEqual(reason, "Disconnect by user."))
	{
		if (isLAN || !GetConVarBool(cvar_ar_time) || client==0)
		{
			return;
		}
		
		if (IsFakeClient(client))
		{
			return;
		}
		
		if (GetUserFlagBits(client) && GetConVarBool(cvar_ar_admin_immunity))
		{
			return;
		}
		
		InsertClientInDB(client);
		//isZombie=false;
	}
}

//public OnClientPutInServer(client)
public OnClientAuthorized(client)
{
	if (isLAN || !GetConVarBool(cvar_ar_time) || client==0)
	{
		return;
	}
	
	if (IsFakeClient(client) || !IsClientConnected(client))
	{
		return;
	}

	decl String:query[200];
	decl String:steamId[30];
	
	GetClientAuthString(client, steamId, sizeof(steamId));	
	Format(query, sizeof(query), "SELECT * FROM	antireconnect WHERE steamId = '%s';", steamId);
	SQL_TQuery(sldb, CheckPlayer, query, client);
}

public CheckPlayer(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		return;
	}
	
	new time = GetTime() - SQL_FetchInt(hndl, 1) - GetConVarInt(cvar_ar_time);
	if (time >= 0)
	{
		RemoveScoreFromDB(client);
		return;
	}
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		KickClient(client, "%t", "You are not allowed to reconnect for X seconds", -time);
	}
}

public RemoveScoreFromDB(client)
{
	decl String:query[200];
	decl String:steamId[30];
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	
	Format(query, sizeof(query), "DELETE FROM antireconnect WHERE steamId = '%s';", steamId);
	SQL_FastQuery(sldb, query);
}

public OnConfigsExecuted()
{
	isLAN = GetConVarBool(FindConVar("sv_lan"));
}

public InsertClientInDB(client)
{		
	decl String:steamId[30];
	decl String:query[200];
	GetClientAuthString(client, steamId, sizeof(steamId));
		
	SQL_LockDatabase(sldb);
	
	Format(query, sizeof(query), "DELETE FROM antireconnect WHERE steamid = '%s';", steamId);
	SQL_FastQuery(sldb, query);
		
	Format(query, sizeof(query), "INSERT INTO antireconnect VALUES ('%s', %d);", steamId, GetTime());
	SQL_FastQuery(sldb, query);
	
	SQL_UnlockDatabase(sldb);
}

public OnMapStart()
{
	ClearDB();
}

public InitDB()
{
	new String:error[255];
	sldb = SQLite_UseDatabase("antireconnect", error, sizeof(error));
	if(sldb == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	SQL_LockDatabase(sldb);
	SQL_FastQuery(sldb, "CREATE TABLE IF NOT EXISTS antireconnect (steamid TEXT, timestamp INTEGER);");
	SQL_UnlockDatabase(sldb);
}

public ClearDB()
{
	SQL_LockDatabase(sldb);
	SQL_FastQuery(sldb, "DELETE FROM antireconnect;");
	SQL_UnlockDatabase(sldb);
}