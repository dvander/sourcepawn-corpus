/**
 * PlayerRecords by bl4nk
 *
 * This plugin logs a lot of information on each player into
 * a MySQL database. The current list of information logged
 * is as follows:
 * - The player's SteamID
 * - Every name the player has used
 * - The last time the player used a certain name
 * - The last IP address the player connected from
 * - The amount of times a player has connected to the server
 *
 *
 * All of this information is logged into two MySQL tables:
 * `players` : Includes the SteamID, first used name, last used name,
 *             last ip connected from, number of connections, and the
 *             date and time of their last successful* connection.
 * `playernames` : Each name a SteamID uses, and when they last used it.
 * `playerips` : Each IP address a SteamID has used, and when they last used it.
 *
 * (*) When I say successful connection, I mean when they've connected to the
 *     server, and their SteamID has been authorized. Players who are banned
 *     and get booted with a ban message do NOT "successfully" connect.
 */

#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0-b2"

new Handle:hQuery = INVALID_HANDLE;
new Handle:hdatabase = INVALID_HANDLE;

// Functions
public Plugin:myinfo =
{
	name = "PlayerRecords",
	author = "bl4nk",
	description = "Records information on each player that connects to the server",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_playerrecords_version", PLUGIN_VERSION, "PlayerRecords Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_changename", event_Name);
	SQL_TConnect(sql_Connect);
}

public sql_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		SetFailState("Database failure: %s", error);
	else
		hdatabase = hndl;

	CreateTables();
}

public OnClientAuthorized(client, const String:auth[])
{
	decl String:ipaddr[32], String:clientName[32], String:clientNameBuffer[65], String:query[512];

	GetClientIP(client, ipaddr, sizeof(ipaddr));
	GetClientName(client, clientName, sizeof(clientName));
	SQL_EscapeString(hdatabase, clientName, clientNameBuffer, sizeof(clientNameBuffer));

	Format(query, sizeof(query), "INSERT INTO players (steamid, firstname, lastname, lastip) VALUES ('%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE lastname = VALUES(lastname), lastip = VALUES(lastip), connections = connections + 1, lastconnect = NOW()", auth, clientNameBuffer, clientNameBuffer, ipaddr);
	SendQuery(query);

	Format(query, sizeof(query), "INSERT INTO playernames (steamid, name, last) VALUES ('%s', '%s', NOW()) ON DUPLICATE KEY UPDATE last = NOW()", auth, clientNameBuffer);
	SendQuery(query);

	Format(query, sizeof(query), "INSERT INTO playerips (steamid, ip, last) VALUES ('%s', '%s', NOW()) ON DUPLICATE KEY UPDATE last = NOW()", auth, ipaddr);
	SendQuery(query);
}

public OnClientDisconnect(client)
{
	decl String:auth[32];
	if (GetClientAuthString(client, auth, sizeof(auth)))
	{
		decl String:ipaddr[32], String:clientName[32], String:clientNameBuffer[65], String:query[512];
		GetClientIP(client, ipaddr, sizeof(ipaddr));
		GetClientName(client, clientName, sizeof(clientName));
		SQL_EscapeString(hdatabase, clientName, clientNameBuffer, sizeof(clientNameBuffer));

		Format(query, sizeof(query), "INSERT INTO players (steamid, firstname, lastname, lastip) VALUES ('%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE lastname = VALUES(lastname), lastip = VALUES(lastip), connections = connections + 1", auth, clientNameBuffer, clientNameBuffer, ipaddr);
		SendQuery(query);

		Format(query, sizeof(query), "INSERT INTO playernames (steamid, name, last) VALUES ('%s', '%s', NOW()) ON DUPLICATE KEY UPDATE last = NOW()", auth, clientNameBuffer);
		SendQuery(query);

		Format(query, sizeof(query), "INSERT INTO playerips (steamid, ip, last) VALUES ('%s', '%s', NOW()) ON DUPLICATE KEY UPDATE last = NOW()", auth, ipaddr);
		SendQuery(query);
	}
}

public Action:event_Name(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:auth[32], String:clientName[32], String:clientNameBuffer[65], String:query[512];

	GetClientAuthString(client, auth, sizeof(auth));
	GetEventString(event, "newname", clientName, sizeof(clientName));
	SQL_QuoteString(hdatabase, clientName, clientNameBuffer, sizeof(clientNameBuffer));

	Format(query, sizeof(query), "UPDATE players SET lastname = '%s' WHERE steamid = '%s'", clientNameBuffer, auth);
	SendQuery(query);

	Format(query, sizeof(query), "INSERT INTO playernames (steamid, name, last) VALUES ('%s', '%s', NOW()) ON DUPLICATE KEY UPDATE last = NOW()", auth, clientNameBuffer);
	SendQuery(query);
}

public sql_Query(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data);

	if (hndl == INVALID_HANDLE)
	{
		decl String:query[255];
		ReadPackString(data, query, sizeof(query));

		LogError("Query Failed! %s", error);
		LogError("Query: %s", query);
		return;
	}

	CloseHandle(data);
	CloseHandle(hndl);
}

stock SendQuery(String:query[])
{
	hQuery = CreateDataPack();
	WritePackString(hQuery, query);
	SQL_TQuery(hdatabase, sql_Query, query, hQuery);
}

stock CreateTables()
{
	decl String:query[512];
	Format(query, sizeof(query), "%s%s%s%s%s%s%s%s%s",
		"CREATE TABLE IF NOT EXISTS `players` (",
		"  `steamid` varchar(32) NOT NULL,",
		"  `firstname` varchar(32) NOT NULL,",
		"  `lastname` varchar(32) NOT NULL,",
		"  `lastip` varchar(32) NOT NULL,",
		"  `connections` int(11) NOT NULL default 1,",
		"  `lastconnect` timestamp NOT NULL default CURRENT_TIMESTAMP,",
		"  PRIMARY KEY (`steamid`)",
		") ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;");

	SendQuery(query);

	Format(query, sizeof(query), "%s%s%s%s%s%s%s%s",
		"CREATE TABLE IF NOT EXISTS `playernames` (",
		"  `id` int(11) NOT NULL AUTO_INCREMENT,",
		"  `steamid` varchar(32) NOT NULL,",
		"  `name` varchar(32) NOT NULL,",
		"  `last` timestamp NOT NULL default CURRENT_TIMESTAMP,",
		"  PRIMARY KEY (`id`),",
		"  CONSTRAINT UNIQUE (`steamid`, `name`)",
		") ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;");

	SendQuery(query);

	Format(query, sizeof(query), "%s%s%s%s%s%s%s%s",
		"CREATE TABLE IF NOT EXISTS `playerips` (",
		"  `id` int(11) NOT NULL AUTO_INCREMENT,",
		"  `steamid` varchar(32) NOT NULL,",
		"  `ip` varchar(32) NOT NULL,",
		"  `last` timestamp NOT NULL default CURRENT_TIMESTAMP,",
		"  PRIMARY KEY (`id`),",
		"  CONSTRAINT UNIQUE (`steamid`, `ip`)",
		") ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;");

	SendQuery(query);
}