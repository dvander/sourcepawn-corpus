#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "0.3"
new Handle:ghDB = INVALID_HANDLE;
new String:gsAddresses[MAXPLAYERS+1][18];
new gIsOnLan[MAXPLAYERS+1];
new gWatched[MAXPLAYERS+1];
new gIsAdmin[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SQL WhoIs",
	author = "knoid",
	description = "Monitor players across different names & IP addresses",
	version = PLUGIN_VERSION,
	url = "http://www.joe.to"
}

public OnPluginStart()
{
	CreateConVar("sm_whois_version", PLUGIN_VERSION, "SQL WhoIs Version", FCVAR_PLUGIN|FCVAR_SPONLY);

	CreateTimer(120.0, AlertAdmins, _, TIMER_REPEAT);

	RegAdminCmd("sm_whois", Command_WhoIs, ADMFLAG_BAN, "Show a player's activity");
	RegAdminCmd("sm_lan", Command_Lan, ADMFLAG_BAN, "Show players using the same IP address");
	RegAdminCmd("sm_note", Command_Note, ADMFLAG_BAN, "Record note on player's record");
	RegAdminCmd("sm_watch", Command_Watch, ADMFLAG_BAN, "Record watch against player (reason required)");
	RegAdminCmd("sm_unwatch", Command_UnWatch, ADMFLAG_BAN, "Remove existing watch against player (reason required)");

	HookEvent("player_changename", Event_NameChange);
	HookEvent("player_disconnect", Event_PlayerDisconnect);

	ConnectToSQLServer();

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			gIsOnLan[i] = 0;
			gWatched[i] = 0;
			gIsAdmin[i] = 0;
			StorePlayerName(i);
		}
	}
}

//Connect to MySQL
public OnMapStart()
{
	decl String:sQuery0[255];

	ConnectToSQLServer();

	Format(sQuery0, sizeof(sQuery0),"DELETE FROM whois_connections WHERE UNIX_TIMESTAMP(date) < (UNIX_TIMESTAMP() - 5184000)");
	FQuery(sQuery0, "whois_connections");

}

//Disconnect from MySQL
public OnMapEnd()
{
	if (ghDB != INVALID_HANDLE)
	{
		CloseHandle(ghDB);
		ghDB = INVALID_HANDLE;
	}
}

// Client has connected; record connection, check for LAN ips
public OnClientPostAdminCheck(player)
{
	if (!IsFakeClient(player))
	{
		StorePlayerName(player);
	}
	return true;
}

public Action:OnBanClient(player, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:admin)
{
	decl String:sName[32];
	GetClientName(player, sName, sizeof(sName));
	AddReason(0, sName, reason, 1);
}

public Action:OnBanIdentity(const String:identity[], time, flags, const String:reason[], const String:command[], any:admin)
{
	decl String:sName[32];
	switch (StrContains(identity, "STEAM_", true))
	{
// It's a steam id, we're assuming it's correct and complete
		case !-1:
		{
			strcopy (sName, sizeof(sName), identity);
			AddReason(0, sName, reason, 1);
		}
// It's an IP....functionality to be implemented
	}
}

// Remove client from LAN ip record
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sDisconnectReason[32],
			String:sName[32],
			String:sReason[255],
			String:datetime[20];

	GetEventString(event, "reason", sDisconnectReason, sizeof(sDisconnectReason));
	if (StrEqual(sDisconnectReason, "kick"))
	{
		GetClientName(player, sName, sizeof(sName));
		FormatTime(datetime, sizeof(datetime), "%m-%d-%Y_%H-%M");
		Format (sReason, sizeof(sReason), "Player kicked from server at %s", datetime);
		AddReason(0, sName, sReason, 0);
	}
}

public OnClientDisconnect_Post(player)
{
	strcopy(gsAddresses[player],18,"");
	gIsOnLan[player] = 0;
	gWatched[player] = 0;
	gIsAdmin[player] = 0;
}


// Client has changed name; we track this as a new connection for simplicity
public Action:Event_NameChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:sOldName[32], String:sNewName[32];
	GetEventString(event, "oldname", sOldName, sizeof(sOldName));
	GetEventString(event, "newname", sNewName, sizeof(sNewName));

	if ((!StrEqual(sOldName, sNewName)) && (!IsFakeClient(player)))
	{
		StorePlayerName(player);
	}
	return Plugin_Handled;
}

public Action:AlertAdmins(Handle:timer)
{

	decl String:sWatchedPlayer[32],
			String:sOutput[255];
	new i, bool:LAN = false;

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			if (gIsOnLan[i] == 1)
			{
				LAN = true;
			}
			if (gWatched[i] == 1)
			{
				GetClientName(i, sWatchedPlayer, 32);
				Format (sOutput, sizeof(sOutput), "[SM] %s needs to be watched! Type sm_whois %s in your console for details.", sWatchedPlayer, sWatchedPlayer);
				PrintToAdmins(sOutput);
			}
		}
	}
	if (LAN)
	{
		Format (sOutput, sizeof(sOutput), "[SM] There are players on the same LAN! Type sm_lan in your console for details.");
		PrintToAdmins(sOutput);
	}
}

// Display recorded player info
public Action:Command_WhoIs(admin, args)
{
// Connected?
	if (ghDB == INVALID_HANDLE)
	{
		LogError("[WhoIs] No DB connection!");
		return Plugin_Handled;
	}

	decl String:sArg[32],
			String:sPlayer[32],
			String:sAuthid[32],
			String:sAuthIdBuffer[65],
			String:sQuery0[255],
			String:sQuery1[255],
			String:sQuery2[255],
			String:sQuery3[255],
			String:sQuery4[255],
			String:sQuery5[255],
			Now;
	new i;

	GetCmdArgString(sArg, sizeof(sArg));
	BreakString(sArg, sPlayer, sizeof(sPlayer));

	if (!args || (StrEqual(sPlayer, "")))
	{
		ReplyToCommand(admin, "[SM] Usage: sm_whois <name/ID>");
		return Plugin_Handled;
	}

	if (FindPlayer(admin, sPlayer, sAuthid) == -2)
	{
		return Plugin_Handled;
	}

	SQL_EscapeString(ghDB, sAuthid, sAuthIdBuffer, 65);

	Format(sQuery0, sizeof(sQuery0),"SELECT lastip, lastname, connections, UNIX_TIMESTAMP(), first_connection FROM whois WHERE steamid = '%s' LIMIT 1",sAuthIdBuffer);
	Format(sQuery1, sizeof(sQuery1),"SELECT UNIX_TIMESTAMP(date) FROM whois_connections WHERE steamid = '%s'",sAuthIdBuffer);
	Format(sQuery2, sizeof(sQuery2),"SELECT name, connections FROM whois_players WHERE steamid = '%s'",sAuthIdBuffer);
	Format(sQuery3, sizeof(sQuery3),"SELECT added_by, adder_steamid, added_date, removed_by, remover_steamid, removed_date, reason, removal_reason, active FROM whois_watches WHERE steamid = '%s'",sAuthIdBuffer);
	Format(sQuery4, sizeof(sQuery4),"SELECT added_by, adder_steamid, added_date, note FROM whois_notes WHERE steamid = '%s'",sAuthIdBuffer);
	Format(sQuery5, sizeof(sQuery5),"SELECT ip, connections FROM whois_ips WHERE steamid = '%s'", sAuthid);

	new Handle:hQuery0 = SQL_Query(ghDB, sQuery0);

	decl String:sLastIP[16],
			String:sLastName[32],
			String:sFirstConnection[19],
			TotalConns;

	if (admin >0)
	{
		PrintToChat(admin, "[SM] Check your console for results.");
	}

	while (SQL_FetchRow(hQuery0))
	{
		SQL_FetchString(hQuery0, 0, sLastIP, sizeof(sLastIP));
		SQL_FetchString(hQuery0, 1, sLastName, sizeof(sLastName));
		TotalConns = SQL_FetchInt(hQuery0, 2);
		Now = SQL_FetchInt(hQuery0, 3);
		SQL_FetchString(hQuery0, 4, sFirstConnection, sizeof(sFirstConnection));
	}

	PrintToConsole(admin, "[SM] SteamID: %s", sAuthid);
	PrintToConsole(admin, "[SM] Last Known Name: %s", sLastName);
	PrintToConsole(admin, "[SM] Last Known IP: %s", sLastIP);
	PrintToConsole(admin, "[SM] Total Connections: %d", TotalConns);

	CloseHandle(hQuery0);


	new Handle:hQuery1 = SQL_Query(ghDB, sQuery1),
			ConnsLastWeek,
			ConnsToday,
			Today = Now-86400,
			ThisWeek = Now-604800;
	decl ConnsLast30Days,
			Date;

	ConnsLast30Days = SQL_GetRowCount(hQuery1);

	i = 0;
	while (SQL_FetchRow(hQuery1))
	{
		Date = SQL_FetchInt(hQuery1, 0);

		if (Date > (Today))
		{
			ConnsToday++;
		}

		if (Date > (ThisWeek))
		{
			ConnsLastWeek++;
		}

		i++;
	}

	PrintToConsole(admin, "[SM] (%d today, %d this week, %d this month)", ConnsToday, ConnsLastWeek, ConnsLast30Days);
	CloseHandle(hQuery1);


	new Handle:hQuery5 = SQL_Query(ghDB, sQuery5);

	decl ConnsPerIP,
			String:sAddress[18];

	PrintToConsole(admin, "[SM]");
	PrintToConsole(admin, "[SM] Known IP Addresses:");

	while (SQL_FetchRow(hQuery5))
	{
		SQL_FetchString(hQuery5, 0, sAddress, 17);
		ConnsPerIP = SQL_FetchInt(hQuery5, 1);
		PrintToConsole(admin, "[SM] %s (%d times)", sAddress, ConnsPerIP);
	}

	CloseHandle(hQuery5);


	new Handle:hQuery2 = SQL_Query(ghDB, sQuery2);

	decl ConnsPerName,
			String:sName[32];

	PrintToConsole(admin, "[SM]");
	PrintToConsole(admin, "[SM] Known Aliases:");

	while (SQL_FetchRow(hQuery2))
	{
		SQL_FetchString(hQuery2, 0, sName, 32);
		ConnsPerName = SQL_FetchInt(hQuery2, 1);
		PrintToConsole(admin, "[SM] %s (%d times)", sName, ConnsPerName);
	}

	CloseHandle(hQuery2);

	new Handle:hQuery4 = SQL_Query(ghDB, sQuery4);

	PrintToConsole(admin, "[SM]");

	if (hQuery4 != INVALID_HANDLE)
	{
		if (SQL_GetRowCount(hQuery4) > 0)
		{
			PrintToConsole(admin, "[SM] Notes:");

			decl String:sNoteAddedBy[32],
					String:sNoteAdderSteamID[32],
					String:sNoteAddedDate[20],
					String:sNoteReason[255];

			while (SQL_FetchRow(hQuery4))
			{
				SQL_FetchString(hQuery4, 0, sNoteAddedBy, sizeof(sNoteAddedBy));
				SQL_FetchString(hQuery4, 1, sNoteAdderSteamID, sizeof(sNoteAdderSteamID));
				SQL_FetchString(hQuery4, 2, sNoteAddedDate, sizeof(sNoteAddedDate));
				SQL_FetchString(hQuery4, 3, sNoteReason, sizeof(sNoteReason));
				PrintToConsole(admin, "[SM] %s: Note by %s (%s) - %s", sNoteAddedDate, sNoteAddedBy, sNoteAdderSteamID, sNoteReason);
			}
		}
		else
		{
			PrintToConsole(admin, "[SM] No notes recorded against this player");
		}
	}
	CloseHandle(hQuery4);

	new Handle:hQuery3 = SQL_Query(ghDB, sQuery3);

	PrintToConsole(admin, "[SM]");

	if (hQuery3 != INVALID_HANDLE)
	{
		if (SQL_GetRowCount(hQuery3) > 0)
		{
			PrintToConsole(admin, "[SM] Watches:");
			decl String:sWatchAddedBy[32],
					String:sWatchAdderSteamID[32],
					String:sWatchAddedDate[20],
					String:sWatchRemovedBy[32],
					String:sWatchRemoverSteamID[32],
					String:sWatchRemovedDate[20],
					String:sWatchReason[255],
					String:sWatchRemovalReason[255],
					WatchActive;

			while (SQL_FetchRow(hQuery3))
			{
				SQL_FetchString(hQuery3, 0, sWatchAddedBy, sizeof(sWatchAddedBy));
				SQL_FetchString(hQuery3, 1, sWatchAdderSteamID, sizeof(sWatchAdderSteamID));
				SQL_FetchString(hQuery3, 2, sWatchAddedDate, sizeof(sWatchAddedDate));
				SQL_FetchString(hQuery3, 3, sWatchRemovedBy, sizeof(sWatchRemovedBy));
				SQL_FetchString(hQuery3, 4, sWatchRemoverSteamID, sizeof(sWatchRemoverSteamID));
				SQL_FetchString(hQuery3, 5, sWatchRemovedDate, sizeof(sWatchRemovedDate));
				SQL_FetchString(hQuery3, 6, sWatchReason, sizeof(sWatchReason));
				SQL_FetchString(hQuery3, 7, sWatchRemovalReason, sizeof(sWatchRemovalReason));
				WatchActive = SQL_FetchInt(hQuery3, 8);
				PrintToConsole(admin, "[SM] %s: Watch by %s (%s) - %s", sWatchAddedDate, sWatchAddedBy, sWatchAdderSteamID, sWatchReason);
				if (WatchActive == 0)
				{
					PrintToConsole(admin, "[SM] %s: Watch removed by %s (%s) - %s", sWatchRemovedDate, sWatchRemovedBy, sWatchRemoverSteamID, sWatchRemovalReason);
				}
			}
		}
		else
		{
			PrintToConsole(admin, "[SM] No watches recorded against this player");
		}
	}
	CloseHandle(hQuery3);

	return Plugin_Handled;
}

// Show players at same IP address
public Action:Command_Lan(admin, args)
{
	decl String:sLanPlayers[32][32];
	decl String:sLanPlayerIPs[32][18];
	new i, j, bool:LAN = false;

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && (gIsOnLan[i] == 1))
		{
			LAN = true;
			GetClientName(i, sLanPlayers[j], 32);
			strcopy(sLanPlayerIPs[j],17,gsAddresses[i]);
			j++;
		}
	}

	if (LAN)
	{
		if (admin >0)
		{
			PrintToChat(admin, "[SM] Check your console for results.");
		}
		PrintToConsole(admin, "[SM] The following users are playing on LAN:");
		for (i = 0; i < j; i++)
		{
			PrintToConsole(admin, "[SM] '%s' - '%s'", sLanPlayerIPs[i], sLanPlayers[i]);
		}
	} else {
		ReplyToCommand(admin, "[SM] No users currently playing on the same LAN");
	}
	return Plugin_Handled;
}

// Record a note against a player
public Action:Command_Note(admin, args)
{
	decl String:sArg[255], String:sPlayer[32];
	decl R;

	GetCmdArgString(sArg, sizeof(sArg));
	R = BreakString(sArg, sPlayer, sizeof(sPlayer));

	if (!args || (StrEqual(sPlayer, "")) || (R == -1))
	{
		ReplyToCommand(admin, "[SM] Usage: sm_note <name/ID> <reason>");
		return Plugin_Handled;
	}

	AddReason(admin, sPlayer, sArg[R], 0);

	return Plugin_Handled;
}

// Record that a player should be watched
public Action:Command_Watch(admin, args)
{
	decl String:sArg[255], String:sPlayer[32];
	decl R;

	GetCmdArgString(sArg, sizeof(sArg));
	R = BreakString(sArg, sPlayer, sizeof(sPlayer));

	if (!args || (StrEqual(sPlayer, "")) || (R == -1))
	{
		ReplyToCommand(admin, "[SM] Usage: sm_watch <name/ID> <reason>");
		return Plugin_Handled;
	}

	AddReason(admin, sPlayer, sArg[R], 1);

	return Plugin_Handled;
}

// Remove active watches from a player
public Action:Command_UnWatch(admin, args)
{
	decl String:sArg[255], String:sPlayer[32];
	decl R;

	GetCmdArgString(sArg, sizeof(sArg));
	R = BreakString(sArg, sPlayer, sizeof(sPlayer));

	if (!args || (StrEqual(sPlayer, "")) || (R == -1))
	{
		ReplyToCommand(admin, "[SM] Usage: sm_unwatch <name/ID> <reason>");
		return Plugin_Handled;
	}

	AddReason(admin, sPlayer, sArg[R], 2);

	return Plugin_Handled;
}

// Record a player connection
StorePlayerName(player)
{

// Connected?
	if (ghDB == INVALID_HANDLE)
	{
		LogError("[WhoIs] No DB connection!");
                return false;
	}

	decl String:sClientName[32],
			String:sAddress[18],
			String:sAuthid[32],
			String:sName[65],
			String:sQuery0[420],
			String:sQuery1[255],
			String:sQuery2[255],
			String:sQuery3[255],
			String:sQuery4[255];

	GetClientIP(player, gsAddresses[player], 17, true);
	GetClientName(player, sClientName, sizeof(sClientName));
	GetClientAuthString(player, sAuthid, sizeof(sAuthid));

	strcopy (sAddress, 18, gsAddresses[player]);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && StrEqual(sAddress, gsAddresses[i]) && (player != i) && (strlen(gsAddresses[player]) > 0))
		{
			gIsOnLan[i] = 1;
			gIsOnLan[player] = 1;
		}
	}

	new AdminId:admin = GetUserAdmin(player);
	if (admin != INVALID_ADMIN_ID)
	{
		new bool:bAccess = GetAdminFlag(admin, Admin_Generic, Access_Effective);
		if (bAccess)
		{
			gIsAdmin[player] = 1;
		}
	}

// Should prevent injection vulnerabilities, we hope
	SQL_EscapeString(ghDB, sClientName, sName, 65);

// Setup SQL
	Format(sQuery0, sizeof(sQuery0),"INSERT INTO whois (steamid, first_connection, lastip, lastname, connections) VALUES ('%s', current_timestamp, '%s', '%s', 1) ON DUPLICATE KEY UPDATE lastip = '%s', lastname = '%s', connections = connections + 1",sAuthid,sAddress,sName,sAddress,sName);
	Format(sQuery1, sizeof(sQuery1),"INSERT INTO whois_players (steamid, name, connections) VALUES ('%s', '%s', '%d') ON DUPLICATE KEY UPDATE connections = connections + 1",sAuthid,sName,1);
	Format(sQuery2, sizeof(sQuery2),"INSERT INTO whois_ips (steamid, ip, connections) VALUES ('%s', '%s', '%d') ON DUPLICATE KEY UPDATE connections = connections + 1",sAuthid, sAddress, 1);
	Format(sQuery3, sizeof(sQuery3),"INSERT INTO whois_connections (steamid) VALUES ('%s')",sAuthid);
	Format(sQuery4, sizeof(sQuery4),"SELECT count( * ) FROM whois_watches WHERE ( steamid = '%s' AND active =1)",sAuthid);

	FQuery(sQuery0, "whois");
	FQuery(sQuery1, "whois_players");
	FQuery(sQuery2, "whois_ips");
	FQuery(sQuery3, "whois_connections");

	new Handle:hQuery4 = SQL_Query(ghDB, sQuery4);

	while (SQL_FetchRow(hQuery4))
	{
		if (SQL_FetchInt(hQuery4, 0)>0)
		{
			gWatched[player] = 1;
		}
	}

	return true;
}

// Add/remove a note/watch on a player; type 0 = add note, 1 = add watch, 2 = remove watch
AddReason(admin, String:sPlayer[32], const String:sReason[], type)
{
	decl String:sName[32],
			String:sPlayerAuthid[32],
			String:sAdminAuthid[32],
			String:sNameBuffer[65],
			String:sReasonBuffer[511],
			String:sPlayerAuthIdBuffer[65],
			String:sAdminAuthidBuffer[65],
			String:sQuery0[255],
			String:sSuccessMsg[40],
			String:sQueryType[32];

	if (ghDB == INVALID_HANDLE)
	{
		LogError("[WhoIs] No DB connection!");
		return false;
	}

	if (admin == 0)
	{
		strcopy(sName, 32, "Console");
		Format(sAdminAuthid, 32, "");
	} else {

		GetClientName(admin, sName, sizeof(sName));
		GetClientAuthString(admin, sAdminAuthid, sizeof(sAdminAuthid));
	}

	new target=FindPlayer(admin, sPlayer, sPlayerAuthid);

	switch (target)
	{
		case -2:
		{
			return false;
		}
		default:
		{
			SQL_EscapeString(ghDB, sPlayerAuthid, sPlayerAuthIdBuffer, 65);
			SQL_EscapeString(ghDB, sAdminAuthid, sAdminAuthidBuffer, 65);
			SQL_EscapeString(ghDB, sName, sNameBuffer, 65);
			SQL_EscapeString(ghDB, sReason, sReasonBuffer, 511);

			switch (type)
			{
				case 0:
				{
					Format(sQuery0, sizeof(sQuery0),"INSERT INTO whois_notes (steamid, added_by, adder_steamid, note) VALUES ('%s', '%s', '%s', '%s')", sPlayerAuthIdBuffer, sNameBuffer, sAdminAuthidBuffer, sReason);
					strcopy(sQueryType, sizeof(sQueryType), "Insert");
					strcopy(sSuccessMsg, 40, "[SM] Note successfully added!");
				}
				case 1:
				{
					Format(sQuery0, sizeof(sQuery0),"INSERT INTO whois_watches (steamid, added_by, adder_steamid, reason, active) VALUES ('%s', '%s', '%s', '%s', '%d')", sPlayerAuthIdBuffer, sNameBuffer, sAdminAuthidBuffer, sReason, 1);
					strcopy(sQueryType, sizeof(sQueryType), "Insert");
					strcopy(sSuccessMsg, 40, "[SM] Watch successfully added!");
					if (target > 0)
					{
						gWatched[target] = 1;
					}
				}
				case 2:
				{
					Format(sQuery0, sizeof(sQuery0),"UPDATE whois_watches SET active = 0, removed_date = current_timestamp, removed_by = '%s', remover_steamid = '%s', removal_reason = '%s' WHERE steamid = '%s'", sName, sAdminAuthidBuffer, sReason, sPlayerAuthIdBuffer);
					strcopy(sQueryType, sizeof(sQueryType), "Update");
					strcopy(sSuccessMsg, 40, "[SM] Watch successfully removed!");
					if (target > 0)
					{
						gWatched[target] = 0;
					}
				}
			}

			if (!FQuery(sQuery0, sQueryType))
			{
				ReplyToCommand(admin, sSuccessMsg);
			}
		}
	}
	return true;
}

FindPlayer(player, String:sPlayer[32], String:sAuthid[32])
{
	new target = FindTargetNoErrMsg(player, sPlayer);

	switch (target)
	{
// User not on server
		case -1:
		{
			switch (StrContains(sPlayer, "STEAM_", true))
			{
// It's a steam id, we're assuming it's correct and complete
				case !-1:
				{
					strcopy (sAuthid, sizeof(sAuthid), sPlayer);
				}
// Not a steam ID; search db for name match and grab steam ID
				default:
				{
					if (!CheckSQLDB(player, sPlayer))
					{
						return -2;
					}
					strcopy (sAuthid, sizeof(sAuthid), sPlayer);
				}
			}
		}
// User is on the server, grab their Steam ID
		default:
		{
			GetClientAuthString(target, sAuthid, sizeof(sAuthid));
		}
	}

	return target;
}

// Queries sql db to find a player by name (if not in server)
CheckSQLDB(admin, String:sPlayer[32])
{
	decl String:sError[255],
			String:sQuery0[255],
			Q,
			String:sPlayerBuffer[65];

	if (strlen(sPlayer) < 4)
	{
		ReplyToCommand(admin, "[SM] Not enough characters to search by name");
		return false;
	}

	SQL_EscapeString(ghDB, sPlayer, sPlayerBuffer, 65);

	Format(sQuery0, sizeof(sQuery0),"SELECT steamid, name FROM whois_players WHERE name LIKE '%%%s%%'", sPlayerBuffer);

	new Handle:hQuery = SQL_Query(ghDB, sQuery0);
	if (hQuery == INVALID_HANDLE)
	{
		SQL_GetError(ghDB, sError, sizeof(sError));
		PrintToServer("[WhoIs] Query failed! (error: %s)", sError);
		return false;
	}

	switch (Q = SQL_GetRowCount(hQuery))
	{
		case 0:
		{
			ReplyToCommand(admin, "[SM] Player not found");
			return false;
		}
// One row returned; copy Steam ID over
		case 1:
		{
			while (SQL_FetchRow(hQuery))
			{
				SQL_FetchString(hQuery, 0, sPlayer, sizeof(sPlayer));
			}
		}
// In most cases there will be multiple rows per player
		default:
		{
			decl String:sAuthid[Q][32], String:sName[Q][32];
			new i, k, j[Q];
			while (SQL_FetchRow(hQuery))
			{
				SQL_FetchString(hQuery, 0, sAuthid[i], 32);
				SQL_FetchString(hQuery, 1, sName[i], 32);
				if ((i>0) && (!StrEqual(sAuthid[i], sAuthid[i-1])))
				{
					j[k] = i;
					k++;
				}
				i++;
			}

// If results contain more than one Steam ID, print results and break
			if (k > 0)
			{
				if (admin >0)
				{
					PrintToChat(admin, "[SM] Check your console for results.");
				}

				PrintToConsole(admin, "[SM] Found the following players - please reissue the command with a Steam ID (or more specific name):");

				for (i = 0; i < k; i++)
				{
					PrintToConsole(admin, "[SM] '%s' - '%s'", sAuthid[j[i]], sName[j[i]]);
				}

				return false;
			}

			strcopy(sPlayer, sizeof(sPlayer), sAuthid[0]);
		}
	}
	return true;
}

// cribbed from helpers.inc; removed output msg on fail
FindTargetNoErrMsg(player, const String:sTarget[], bool:nobots = true, bool:immunity = false)
{
	decl String:sTarget_name[MAX_TARGET_LENGTH];
	decl target_list[1], bool:tn_is_ml;

	new flags = COMMAND_FILTER_NO_MULTI;
	if (nobots)
	{
		flags |= COMMAND_FILTER_NO_BOTS;
	}
	if (!immunity)
	{
		flags |= COMMAND_FILTER_NO_IMMUNITY;
	}

	if (ProcessTargetString(
			sTarget,
			player,
			target_list,
			1,
			flags,
			sTarget_name,
			sizeof(sTarget_name),
			tn_is_ml) > 0)
	{
		return target_list[0];
	}
	else
	{
		return -1;
	}
}

// Insert/update a record somewhere
FQuery(const String:sQuery[], String:sQueryType[32])
{
	decl String:sError[255];
	if (!SQL_FastQuery(ghDB, sQuery))
	{
		SQL_GetError(ghDB, sError, sizeof(sError));
		PrintToServer("[WhoIs] Failed to insert or update table '%s'! (error: %s)", sQueryType, sError);
		return false;
	}
	return true;
}

// Print a message to server admins
PrintToAdmins(String:sOutput[255])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (gIsAdmin[i] == 1)
		{
			PrintToChat(i, sOutput);
		}
	}
}

ConnectToSQLServer()
{
	if (ghDB == INVALID_HANDLE)
	{
		new String:sError[255];
		ghDB = SQL_DefConnect(sError, sizeof(sError));
		if (ghDB == INVALID_HANDLE)
		{
			PrintToServer("[WhoIs] Could not connect: %s", sError);
		}
	}
}