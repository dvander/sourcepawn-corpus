/**
 * TF2AS TF2 Anti-Scam
 * is a service provided by CoolJosh3k
 * to block any known scammers from your server.
 * 
 * Visit http://www.tf2antiscam.com/ for more info.
 * 
 */

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:g_hDatabase;

new String:sLogFile[PLATFORM_MAX_PATH];

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
	
	// Log all info into this file
	BuildPath(Path_SM, sLogFile, sizeof(sLogFile), "logs/tf2as.log");
	
	// Register the !tf2as command to show info about tf2as
	RegConsoleCmd("sm_tf2as", Command_TF2AS, "Shows message about TF2AS being active.");
	
	// Connect to the database
	SQL_TConnect(SQL_OnConnected, "tf2as");
}

/**
 * Event Forwards
 */

public OnClientAuthorized(client, const String:auth[])
{
	// Don't error, if the database is unavailable, just retry gracefully
	if(g_hDatabase == INVALID_HANDLE)
	{
		CreateTimer(60.0, Timer_OnReconnectToDatabase, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
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
		CreateTimer(60.0, Timer_OnReconnectToDatabase, _, TIMER_FLAG_NO_MAPCHANGE);
		LogToFile(sLogFile, "Database failure: %s.", error);
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
		LogToFile(sLogFile, "Can't check if player is banned: %s", error);
		// Recheck with a delay
		CreateTimer(20.0, Timer_OnRecheckClient, userid, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	// Player is banned. Kick him.
	if(SQL_GetRowCount(hndl) > 0)
	{
		decl String:sAuth[64], String:sIP[16];
		GetClientAuthString(client, sAuth, sizeof(sAuth));
		PrintToChatAll("\x03TF2AS: Scammer detected! %s was blocked from joining. Visit www.tf2AntiScam.com for more info.", sAuth);
		KickClient(client, "TF2AS has blocked you from this server. www.tf2antiscam.com");
		
		GetClientIP(client, sIP, sizeof(sIP));
		LogToFile(sLogFile, "Scammer detected! %N (%s) (%s) was blocked from joining.", client, sAuth, sIP);
		
		// Optionally ban player 5 minutes to avoid database spam with connection spamming.
		//BanClient(client, 5, BANFLAG_AUTO, "TF2AS: Scammer");
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

/**
 * Command Callbacks
 */
 
public Action:Command_TF2AS(client, args)
{
	ReplyToCommand(client, "\x03This server is protected with TF2AS www.tf2AntiScam.com");
	return Plugin_Handled;
}