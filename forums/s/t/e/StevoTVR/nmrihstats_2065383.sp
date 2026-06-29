/*
* 
* Simple NMRiH Stats
* https://forums.alliedmods.net/showthread.php?t=230459
* 
* Description:
* This is a basic point-based stats plugin for No More Room in Hell, with rank
* and top10 commands. Stat data is stored in a configurable database.
* 
* Default Configuration:
* 	- Zombie kill: +1
* 	- Headshot bonus: +1
* 	- Death: -20
* 	- Team kill: -20
* 	- Extraction: +50
* 
* 
* Changelog
* Dec 22, 2013 - v.0.5:
* 	[+] Added sm_stats_start_at_avg ConVar to toggle players starting at the
* 		average or 0
*	[*] Players cannot start with negative points
*	[*] Fixed bug with sm_stats_setpoints targetting
*	[-] Disabled reward for objectives due to game event unreliability
*	[*] Adjusted default reward values (-20 for death, +50 for extraction)
* Dec 11, 2013 - v.0.4:
* 	[+] Added commands to set players' point values manually
*	[+] Added command to reset the stats database
*	[-] Removed sm_stats_startpoints ConVar
*	[*] New players now start at the average score of all players
*	[*] Fixed server being able to call rank and top10 commands
*	[*] Fixed plugin overriding database changes from other sources
* Dec 01, 2013 - v.0.3:
* 	[+] Added detection of fire kills
*	[+] Added headshot bonus
*	[+] Added point award for getting extracted
*	[+] Added team point award for completing an objective
*	[+] Added chat triggers for rank and top10
* Nov 27, 2013 - v.0.2:
* 	[+] Added sm_stats_startpoints ConVar
* 	[+] Added stat notifications in players' chat area
* 	[*] Fixed race condition with database connection
* 	[*] Only updates names when needed
* 	[*] Only allows loading on NMRiH
* Nov 25, 2013 - v.0.1:
* 	[*] Initial Release
* 
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.5"
//#define DEBUG

public Plugin:myinfo = 
{
	name = "Simple NMRiH Stats",
	author = "Stevo.TVR",
	description = "Basic point-based stats for No More Room in Hell",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=230459"
}

new Handle:hDatabase = INVALID_HANDLE;

new Handle:sm_stats_killpoints = INVALID_HANDLE;
new Handle:sm_stats_deathpoints = INVALID_HANDLE;
new Handle:sm_stats_tkpoints = INVALID_HANDLE;
new Handle:sm_stats_headshot_bonus = INVALID_HANDLE;
new Handle:sm_stats_extractionpoints = INVALID_HANDLE;
//new Handle:sm_stats_objectivepoints = INVALID_HANDLE;
new Handle:sm_stats_start_at_avg = INVALID_HANDLE;

new clientPoints[MAXPLAYERS+1];
new clientKills[MAXPLAYERS+1];
new clientDeaths[MAXPLAYERS+1];

new clientKillsSinceNotify[MAXPLAYERS+1];
new clientKillPointsSinceNotify[MAXPLAYERS+1];

new totalPlayers;
new resetCode;

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false) != 0)
	{
		SetFailState("Unsupported game!");
	}
	
	CreateConVar("sm_nmrihstats_version", PLUGIN_VERSION, "Simple NMRiH Stats version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_stats_killpoints = CreateConVar("sm_stats_killpoints", "1", "Points to award for a zombie kill");
	sm_stats_deathpoints = CreateConVar("sm_stats_deathpoints", "-20", "Points to award for getting killed");
	sm_stats_tkpoints = CreateConVar("sm_stats_tkpoints", "-20", "Points to award for killing a teammate");
	sm_stats_headshot_bonus = CreateConVar("sm_stats_headshot_bonus", "1", "Bonus points to award for headshots on top of sm_stats_killpoints");
	sm_stats_extractionpoints = CreateConVar("sm_stats_extractionpoints", "50", "Points to award for getting extracted");
	//sm_stats_objectivepoints = CreateConVar("sm_stats_objectivepoints", "5", "Points to award team for completing an objective");
	sm_stats_start_at_avg = CreateConVar("sm_stats_start_at_avg", "1", "New players start with the average of all player scores (0 = players start at 0)", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "nmrihstats");

	RegConsoleCmd("sm_rank", Command_Rank, "Displays your current rank");
	RegConsoleCmd("sm_top10", Command_Top10, "Lists top 10 players");
	
	RegAdminCmd("sm_stats_setpoints", Command_SetPoints, ADMFLAG_RCON, "Set a player's stat points");
	RegAdminCmd("sm_stats_setpoints_id", Command_SetPointsId, ADMFLAG_RCON, "Set a SteamID's stat points");
	RegAdminCmd("sm_stats_reset", Command_Reset, ADMFLAG_RCON, "Reset all stats. Use once to get code, use with code to confirm.");
	
	LoadTranslations("common.phrases");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("npc_killed", Event_NPCKilled);
	HookEvent("zombie_killed_by_fire", Event_ZombieKilledByFire);
	HookEvent("zombie_head_split", Event_ZombieHeadSplit);
	HookEvent("player_extracted", Event_PlayerExtracted);
	//HookEvent("objective_complete", Event_ObjectiveComplete);
	HookEvent("player_changename", Event_ChangeName);
	
	ConnectDatabase();
	
	CreateTimer(300.0, Timer_PlayerKillsNotify, _, TIMER_REPEAT);
}

public ConnectDatabase()
{
	new String:db[] = "storage-local";
	if(SQL_CheckConfig("nmrihstats"))
	{
		db = "nmrihstats";
	}
	decl String:error[256];
	hDatabase = SQL_Connect(db, true, error, sizeof(error));
	if(hDatabase == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	
	SQL_TQuery(hDatabase, T_FastQuery, "CREATE TABLE IF NOT EXISTS nmrihstats (steam_id VARCHAR(64) PRIMARY KEY, name TEXT, points INTEGER, kills INTEGER, deaths INTEGER);");
}

public OnMapStart()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientAuthorized(i) && !IsFakeClient(i))
		{
			decl String:query[1024], String:auth[64];
			GetClientAuthString(i, auth, sizeof(auth));
			Format(query, sizeof(query), "SELECT name, points, kills, deaths FROM nmrihstats WHERE steam_id = '%s' LIMIT 1;", auth);
			SQL_TQuery(hDatabase, T_LoadPlayer, query, i);
		}
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if(IsFakeClient(client))
		return;
	
	clientKillPointsSinceNotify[client] = 0;
	clientKillsSinceNotify[client] = 0;
	
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT name, points, kills, deaths FROM nmrihstats WHERE steam_id = '%s' LIMIT 1;", auth);
	SQL_TQuery(hDatabase, T_LoadPlayer, query, client);
}

public T_LoadPlayer(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!IsClientAuthorized(client) || IsFakeClient(client))
		return;
	
	if(hndl != INVALID_HANDLE)
	{
		if(SQL_FetchRow(hndl))
		{
			decl String:authid[64], String:playername[64], String:dbname[64];
			GetClientAuthString(client, authid, sizeof(authid));
			GetClientName(client, playername, sizeof(playername));
			
			SQL_FetchString(hndl, 0, dbname, sizeof(dbname));
			if(strcmp(playername, dbname) != 0)
			{
				UpdatePlayerName(authid, playername);
			}
			
			clientPoints[client] = SQL_FetchInt(hndl, 1);
			clientKills[client] = SQL_FetchInt(hndl, 2);
			clientDeaths[client] = SQL_FetchInt(hndl, 3);
			
#if defined DEBUG
			LogMessage("Loaded player: %L [%dp %dk %dd]", client, clientPoints[client], clientKills[client], clientDeaths[client]);
#endif
		}
		else
		{
			if(GetConVarBool(sm_stats_start_at_avg))
			{
				SQL_TQuery(hDatabase, T_AddPlayer, "SELECT AVG(points) FROM nmrihstats;", client);
			}
			else
			{
				AddPlayer(client, 0);
			}
		}
	}
}

public T_AddPlayer(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl != INVALID_HANDLE)
	{
		if(SQL_FetchRow(hndl))
		{
			new points = SQL_FetchInt(hndl, 0);
			if(points < 0)
				points = 0;
			
			AddPlayer(client, points);
		}
	}
}

public AddPlayer(client, points)
{
	if(!IsClientAuthorized(client) || IsFakeClient(client))
		return;

	decl String:query[1024], String:authid[64], String:playername[64], String:escname[129];
	GetClientAuthString(client, authid, sizeof(authid));
	GetClientName(client, playername, sizeof(playername));
	SQL_EscapeString(hDatabase, playername, escname, sizeof(escname));
	
	Format(query, sizeof(query), "INSERT INTO nmrihstats VALUES ('%s', '%s', %d, 0, 0);", authid, escname, points);
	SQL_TQuery(hDatabase, T_FastQuery, query);
	
	clientPoints[client] = points;
	clientKills[client] = 0;
	clientDeaths[client] = 0;
	
#if defined DEBUG
	LogMessage("Adding player: %L [%dp %dk %dd]", client, clientPoints[client], clientKills[client], clientDeaths[client]);
#endif
}

public Action:Timer_PlayerKillsNotify(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && clientKillPointsSinceNotify[i] != 0)
		{
			new change = clientKillPointsSinceNotify[i], kills = clientKillsSinceNotify[i];
			PrintToChat(i, "\x04[Stats]\x01 %s%d point%s (%d) for killing %d zombie%s", (change >= 0 ? "+" : ""), change, (change != -1 && change != 1 ? "s" : ""), clientPoints[i], kills, (kills > 1 ? "s" : ""));
			clientKillPointsSinceNotify[i] = 0;
			clientKillsSinceNotify[i] = 0;
		}
	}
}

public Action:Command_Rank(client, args)
{
	ShowRank(client);
	return Plugin_Handled;
}

public ShowRank(client)
{
	if(client == 0)
		return;
	
	SQL_TQuery(hDatabase, T_UpdateTotalQuery, "SELECT COUNT(*) FROM nmrihstats;");
	
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT points FROM nmrihstats WHERE points > %d ORDER BY points ASC;", clientPoints[client]);
	SQL_TQuery(hDatabase, T_RankQuery, query, client);
}

public T_UpdateTotalQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
	{
		totalPlayers = SQL_FetchInt(hndl, 0);
	}
}

public T_RankQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE || !IsClientInGame(client))
		return;
	
	new rank = 1, rankdiff = 0;
	if(SQL_FetchRow(hndl))
	{
		rank = SQL_GetRowCount(hndl) + 1;
		rankdiff = SQL_FetchInt(hndl, 0) - clientPoints[client];
	}
	PrintToChatAll("\x01Player \x04%N\x01 is rank \x04%d\x01 of \x04%d\x01 total tracked player%s with \x04%d\x01 point%s and is \x04%d\x01 point%s away from the next rank.", client, rank, totalPlayers, totalPlayers != 1 ? "s" : "", clientPoints[client], clientPoints[client] != 1 ? "s" : "", rankdiff, rankdiff != 1 ? "s" : "");
}

public Action:Command_Top10(client, args)
{
	ShowTop10(client);
	return Plugin_Handled;
}

public ShowTop10(client)
{
	if(client == 0)
		return;
	
	SQL_TQuery(hDatabase, T_Top10Query, "SELECT name, points FROM nmrihstats ORDER BY points DESC LIMIT 10;", client);
}

public T_Top10Query(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE || !IsClientInGame(client))
		return;
	
	decl String:name[64], String:line[128];
	new i;
	PrintToChat(client, "\x04Top 10 players:");
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, name, sizeof(name));
		Format(line, sizeof(line), "\x04#%d.\x01 %s (%d)", ++i, name, SQL_FetchInt(hndl, 1));
		new Handle:data;
		CreateDataTimer(5.0 - 0.5 * i, Timer_Top10, data);
		WritePackCell(data, client);
		WritePackString(data, line);
	}
}

public Action:Timer_Top10(Handle:timer, Handle:hndl)
{
	ResetPack(hndl);
	new client = ReadPackCell(hndl);
	if(IsClientInGame(client))
	{
		decl String:line[128];
		ReadPackString(hndl, line, sizeof(line));
		PrintToChat(client, line);
	}
}

public OnClientSayCommand_Post(client, const String:command[], const String:sArgs[])
{
	decl String:text[192];
	new startidx = 0;
	
	if(strcopy(text, sizeof(text), sArgs) < 1)
	{
		return;
	}
	
	if(text[0] == '"')
	{
		startidx = 1;
	}

	if((strcmp(command, "say2", false) == 0) && strlen(sArgs) >= 4)
		startidx += 4;

	if(strcmp(text[startidx], "rank", false) == 0
	|| strcmp(text[startidx], "/rank", false) == 0
	|| strcmp(text[startidx], "!rank", false) == 0)
	{
		ShowRank(client);
	}
	else if(strcmp(text[startidx], "top10", false) == 0
	|| strcmp(text[startidx], "/top10", false) == 0
	|| strcmp(text[startidx], "!top10", false) == 0)
	{
		ShowTop10(client);
	}
}

public Action:Command_SetPoints(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_stats_setpoints <points> <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:pointsString[64], String:targetString[256];
	
	GetCmdArg(1, pointsString, sizeof(pointsString));
	new points = StringToInt(pointsString);
	
	GetCmdArg(2, targetString, sizeof(targetString));
	decl targets[64], String:tn[MAX_TARGET_LENGTH], bool:tn_is_ml;
	new count = ProcessTargetString(targetString, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, tn, sizeof(tn), tn_is_ml);
	if(count < 1)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	decl String:auth[64];
	for(new i = 0; i < count; i++)
	{
		if(IsClientAuthorized(targets[i]))
		{
			GetClientAuthString(targets[i], auth, sizeof(auth));
			SetPoints(auth, points);
			clientPoints[targets[i]] = points;
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_SetPointsId(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_stats_setpoints_id <points> <steamid>");
		return Plugin_Handled;
	}
	
	decl String:pointsString[64], String:targetString[64], String:auth[129];
	
	GetCmdArg(1, pointsString, sizeof(pointsString));
	new points = StringToInt(pointsString);
	
	GetCmdArg(2, targetString, sizeof(targetString));
	if(strncmp(targetString, "STEAM_", 6) != 0 || targetString[7] != ':')
	{
		ReplyToCommand(client, "[SM] %t", "Invalid SteamID specified");
		return Plugin_Handled;
	}
	
	SQL_EscapeString(hDatabase, targetString, auth, sizeof(auth));
	SetPoints(auth, points);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientAuthorized(i))
		{
			GetClientAuthString(i, auth, sizeof(auth));
			if(strcmp(targetString, auth) == 0)
			{
				clientPoints[i] = points;
				break;
			}
		}
	}
	
	return Plugin_Handled;
}

public SetPoints(const String:auth[], points)
{
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE nmrihstats SET points = %d WHERE steam_id = '%s';", points, auth);
	SQL_TQuery(hDatabase, T_FastQuery, query);
}

public Action:Command_Reset(client, args)
{
	if(args < 1)
	{
		resetCode = GetRandomInt(100000, 999999);
		ReplyToCommand(client, "[SM] Usage: sm_stats_reset %d", resetCode);
		return Plugin_Handled;
	}
	
	decl String:arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	new code = StringToInt(arg);
	
	if(resetCode == 0 || resetCode != code)
	{
		ReplyToCommand(client, "[SM] Error: Incorrect confirmation code!");
		return Plugin_Handled;
	}
	
	resetCode = 0;
	SQL_TQuery(hDatabase, T_FastQuery,"DELETE FROM nmrihstats", 0, DBPrio_High);
	ReplyToCommand(client, "[SM] Success! The stats database has been reset.");
	ReplyToCommand(client, "[SM] Reload the plugin or change map on all servers using this database");
	
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client == 0 || IsFakeClient(client) || !IsClientAuthorized(client))
		return Plugin_Continue;
	
	if(attacker != 0 && attacker != client && !IsFakeClient(attacker) && IsClientAuthorized(attacker))
	{
		new change = GetConVarInt(sm_stats_tkpoints);
		if(change == 0)
			return Plugin_Continue;
		
		clientPoints[attacker] += change;
		
		PrintToChat(attacker, "\x04[Stats]\x01 %s%d point%s (%d) for killing a teammate!", (change >= 0 ? "+" : ""), change, (change != -1 && change != 1 ? "s" : ""), clientPoints[attacker]);
		
#if defined DEBUG
		LogMessage("Player %L (%d) %d for killing a teammate", attacker, clientPoints[attacker], GetConVarInt(sm_stats_tkpoints));
#endif
		
		decl String:query[1024], String:authid[64];
		GetClientAuthString(attacker, authid, sizeof(authid));
		Format(query, sizeof(query), "UPDATE nmrihstats SET points = points + %d WHERE steam_id = '%s';", change, authid);
		SQL_TQuery(hDatabase, T_FastQuery, query);
		
		return Plugin_Continue;
	}
	
	new change = GetConVarInt(sm_stats_deathpoints);
	clientDeaths[client]++;
	clientPoints[client] += change;
	
	PrintToChat(client, "\x04[Stats]\x01 %s%d point%s (%d) for getting killed", (change >= 0 ? "+" : ""), change, (change != -1 && change != 1 ? "s" : ""), clientPoints[client]);
	
#if defined DEBUG
	LogMessage("Player %L (%d) %d for getting killed", client, clientPoints[client], GetConVarInt(sm_stats_deathpoints));
#endif
	
	decl String:query[1024], String:authid[64];
	GetClientAuthString(client, authid, sizeof(authid));
	Format(query, sizeof(query), "UPDATE nmrihstats SET points = points + %d, deaths = deaths + 1 WHERE steam_id = '%s';", change, authid);
	SQL_TQuery(hDatabase, T_FastQuery, query);
	
	return Plugin_Continue;
}

public Action:Event_NPCKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "killeridx");
	ZombieKilled(client);
	return Plugin_Continue;
}

public Action:Event_ZombieKilledByFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "igniter_id");
#if defined DEBUG
	if(client > 0 && client <= MaxClients && !IsFakeClient(client) && IsClientAuthorized(client))
		LogMessage("Player %L killed a zombie with fire!", client);
#endif
	ZombieKilled(client);
	return Plugin_Continue;
}

public ZombieKilled(client)
{
	if(client == 0 || client > MaxClients || IsFakeClient(client) || !IsClientAuthorized(client))
		return;
	
	new change = GetConVarInt(sm_stats_killpoints);
	clientKills[client]++;
	clientPoints[client] += change;
	
	clientKillsSinceNotify[client]++;
	clientKillPointsSinceNotify[client] += change;
	
#if defined DEBUG
	LogMessage("Player %L (%d) %d for killing a zombie", client, clientPoints[client], GetConVarInt(sm_stats_killpoints));
#endif
	
	decl String:query[1024], String:authid[64];
	GetClientAuthString(client, authid, sizeof(authid));
	Format(query, sizeof(query), "UPDATE nmrihstats SET points = points + %d, kills = kills + 1 WHERE steam_id = '%s';", change, authid);
	SQL_TQuery(hDatabase, T_FastQuery, query);
}

public Action:Event_ZombieHeadSplit(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player_id");
	
	if(client == 0 || client > MaxClients || IsFakeClient(client) || !IsClientAuthorized(client))
		return Plugin_Continue;
	
	new change = GetConVarInt(sm_stats_headshot_bonus);
	if(change == 0)
		return Plugin_Continue;
	
	clientPoints[client] += change;
	
	clientKillPointsSinceNotify[client] += change;
	
#if defined DEBUG
	LogMessage("Player %L (%d) %d for headshot!", client, clientPoints[client], GetConVarInt(sm_stats_headshot_bonus));
#endif

	decl String:query[1024], String:authid[64];
	GetClientAuthString(client, authid, sizeof(authid));
	Format(query, sizeof(query), "UPDATE nmrihstats SET points = points + %d WHERE steam_id = '%s';", change, authid);
	SQL_TQuery(hDatabase, T_FastQuery, query);
	
	return Plugin_Continue;
}

public Action:Event_PlayerExtracted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player_id");
	
	if(client == 0 || client > MaxClients || IsFakeClient(client) || !IsClientAuthorized(client))
		return Plugin_Continue;
	
	new change = GetConVarInt(sm_stats_extractionpoints);
	if(change == 0)
		return Plugin_Continue;
	
	clientPoints[client] += change;
	
	PrintToChat(client, "\x04[Stats]\x01 %s%d point%s (%d) for getting extracted", (change >= 0 ? "+" : ""), change, (change != -1 && change != 1 ? "s" : ""), clientPoints[client]);
	
#if defined DEBUG
	LogMessage("Player %L (%d) %d for getting extracted", client, clientPoints[client], GetConVarInt(sm_stats_extractionpoints));
#endif
	
	decl String:query[1024], String:authid[64];
	GetClientAuthString(client, authid, sizeof(authid));
	Format(query, sizeof(query), "UPDATE nmrihstats SET points = points + %d WHERE steam_id = '%s';", change, authid);
	SQL_TQuery(hDatabase, T_FastQuery, query);

	return Plugin_Continue;
}

/*public Action:Event_ObjectiveComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
#if defined DEBUG
	new id = GetEventInt(event, "id");
	decl String:objname[64];
	GetEventString(event, "name", objname, sizeof(objname));
	LogMessage("Objective Complete: id = %d name = %s", id, objname);
#endif

	new change = GetConVarInt(sm_stats_objectivepoints);
	if(change == 0)
		return Plugin_Continue;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientAuthorized(i) || !IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
			continue;
			
		clientPoints[i] += change;
		
		PrintToChat(i, "\x04[Stats]\x01 %s%d point%s (%d) for completing an objective", (change >= 0 ? "+" : ""), change, (change != -1 && change != 1 ? "s" : ""), clientPoints[i]);
		
#if defined DEBUG
		LogMessage("Player %L (%d) %d for completing an objective", i, clientPoints[i], GetConVarInt(sm_stats_objectivepoints));
#endif
		
		decl String:query[1024], String:authid[64];
		GetClientAuthString(i, authid, sizeof(authid));
		Format(query, sizeof(query), "UPDATE nmrihstats SET points = points + %d WHERE steam_id = '%s';", change, authid);
		SQL_TQuery(hDatabase, T_FastQuery, query);
	}
	
	return Plugin_Continue;
}*/

public Action:Event_ChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client != 0 && !IsFakeClient(client))
	{
		decl String:authid[64], String:playername[64];
		GetClientAuthString(client, authid, sizeof(authid));
		GetEventString(event, "newname", playername, sizeof(playername));
		UpdatePlayerName(authid, playername);
	}
	
	return Plugin_Continue;
}

public T_FastQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Nothing to do
}

public UpdatePlayerName(const String:authid[], const String:name[])
{
	decl String:query[1024], String:escname[129];
	SQL_EscapeString(hDatabase, name, escname, sizeof(escname));
	Format(query, sizeof(query), "UPDATE nmrihstats SET name = '%s' WHERE steam_id = '%s';", escname, authid);
	SQL_TQuery(hDatabase, T_FastQuery, query);
	
#if defined DEBUG
	LogMessage("Updating name: %s", name);
#endif
}
