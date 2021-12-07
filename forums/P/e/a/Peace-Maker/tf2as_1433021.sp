#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:g_hDatabase;

public Plugin:myinfo = 
{
	name = "TF2 Anti-Scam",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Blocks scammers",
	version = PLUGIN_VERSION,
	url = "http://www.tf2antiscam.com/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_tf2as_version", PLUGIN_VERSION, "TF2AS version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	if(!SQL_CheckConfig("tf2as"))
	{
		SetFailState("Can't find tf2as database configuration.");
		return;
	}
	
	SQL_TConnect(SQL_OnConnected, "tf2as");
}

/**
 * Event Forwards
 */

public OnClientAuthorized(client, const String:auth[])
{
	decl String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT bid FROM `sb_bans` WHERE authid REGEXP '^STEAM_[0-9]:%s$' AND (length = 0 OR ends > UNIX_TIMESTAMP()) AND RemoveType IS NULL;", auth[8]);
	SQL_TQuery(g_hDatabase, SQL_OnPlayerChecked, sQuery, GetClientUserId(client));
}

/**
 * SQL Callbacks
 */

public SQL_OnConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		// Try to connect again in 5 minutes
		CreateTimer(300.0, Timer_OnReconnectToDatabase, _, TIMER_FLAG_NO_MAPCHANGE);
		LogError("Database failure: %s.", error);
		return;
	}

	g_hDatabase = hndl;
}

public SQL_OnPlayerChecked(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	
	// Player already left?
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Can't check if player is banned: %s", error);
		// Recheck with a delay
		CreateTimer(20.0, Timer_OnRecheckClient, userid, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	decl String:sAuth[64];
	GetClientAuthString(client, sAuth, sizeof(sAuth));
	if(SQL_GetRowCount(hndl) > 0)
	{
		PrintToChatAll("TF2AS: %N (%s) is a scammer! Blocked from joining.", client, sAuth);
		KickClient(client, "You're banned for scamming by TF2AS. www.tf2antiscam.com");
		return;
	}
}

/**
 * Timer Callbacks
 */

public Action:Timer_OnReconnectToDatabase(Handle:timer, any:data)
{
	SQL_TConnect(SQL_OnConnected, "tf2as");
	return Plugin_Stop;
}

public Action:Timer_OnRecheckClient(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	// Player already left?
	if(!client)
		return Plugin_Stop;
	
	decl String:sAuth[64];
	GetClientAuthString(client, sAuth, sizeof(sAuth));
	
	// Recheck the player
	OnClientAuthorized(client, sAuth);
	return Plugin_Stop;
}