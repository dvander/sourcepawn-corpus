// Some snippets such as the sourcebans.cfg parsing are taken near-directly from the Sourcebans plugin

#include <sourcemod>

#define VERSION "1.0"

new String:g_DatabasePrefix[10] = "sb";

new Handle:g_DB;
new Handle:sb_max = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Sourcebans Max bans",
	author = "Franc1sco steam: franug",
	description = ".",
	version = VERSION,
	url = "http://www.uea-clan.com"
};

public OnPluginStart()
{
	CreateConVar("sm_sourcebans_maxbans", VERSION, "Version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
	SQL_TConnect(OnDatabaseConnected, "sourcebans");
	
	sb_max = CreateConVar("sm_sourcebans_maxbans", "3", "Max bans for ban permanetly");
}

public OnDatabaseConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		SetFailState("Failed to connect to SB db, %s", error);
	
	g_DB = hndl;
}

public OnClientPostAdminCheck(client)
{
	if (g_DB == INVALID_HANDLE)
		return;
	
	decl String:auth[32];
	if (!GetClientAuthString(client, auth, sizeof(auth)) || auth[0] == 'B' || auth[9] == 'L')
		return;
	
	
	decl String:query[512], String:ip[30];
	GetClientIP(client, ip, sizeof(ip));
	FormatEx(query, sizeof(query), "SELECT COUNT(bid) FROM %s_bans WHERE ((type = 0 AND authid REGEXP '^STEAM_[0-9]:%s$') OR (type = 1 AND ip = '%s')) AND ((length > '0' AND ends > UNIX_TIMESTAMP()) OR RemoveType IS NOT NULL)", g_DatabasePrefix, auth[8], ip);
	
	SQL_TQuery(g_DB, OnConnectBanCheck, query, GetClientUserId(client), DBPrio_Low);
}

public OnConnectBanCheck(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (!client || hndl == INVALID_HANDLE || !SQL_FetchRow(hndl))
		return;
		
	new bancount = SQL_FetchInt(hndl, 0);
	if (bancount > 0)
	{
		new max_number = GetConVarInt(sb_max);
		if(bancount >= max_number)
			ServerCommand("sm_ban #%d 0 \"banned for exceeded the max number of bans\"",GetClientUserId(client));
		else
		{
			new diferencia = (max_number - bancount);
			PrintToChat(client,"\x04You got banned (%i/%i). If you get banned %i more times you will be permanently banned.", bancount, diferencia, max_number);
		}
	}
}
