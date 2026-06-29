/**************************************************************
--------------------------------------------------------------
 NEOTOKYO° Stats & Ranking.

 Plugin licensed under the GPLv3
 
 Coded by FlyGemma.
 
  Credits to: 
 	FrostbyteX & MikeJS - Ideas and code snippets used.
	quadeye.com.au | mpower0000 - Feedback and testing.
--------------------------------------------------------------

Changelog

	1.0.0
		* Initial release
	1.1.0
		* top10 displays tied players &  time played.
		* Fixed rankoff toggle bug that was displaying  a message on connect.
		* Additional convars & options
			- Team Kill penalty convars.
			- Players earn 3 points for reaching Lieutenant.
	1.1.1
		* Fixed an array bug.
		* Removed timeplayed from top10 to fix a length bug.
	1.2.0
		* Reduced occurance of top10 length bug.
		* Rebalenced point gain/loss.
		* Stats no longer count bot kills.
		* Additional Commands
			- Public command: sm_stats <#userid|name>, lets players view other players stats.
			- Admin commands: sm_rankon <#userid|name> && sm_rankoff <#userid|name>. Ranks on or (off targets point gain/loss and disables them from rankon).
		* Fixed a rankoff cancel bug.
		* Fixed killtimer errors.
		* Bonus points for knife kill.
		* Bonus points for round end. (Extra if alive at round end.) No bonus points for ghost captures yet.
		* Additional convars & options
			- stats, top,  session, rankon and rankoff are hidden from chat.
			- FF Penalty after a round end.
			- Scoring after a round end.
		* session now displays total score.
		* session now displays total XP.
		* rank text is also sent to console.
**************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION	"1.2.0"

public Plugin:myinfo =
{
    name = "NEOTOKYO° Stats & Ranking.",
    author = "FlyGemma",
    description = "NEOTOKYO° Rank and Stats.",
    version = PLUGIN_VERSION,
    url = ""
};

new Handle:convar_ntstats_enabled = INVALID_HANDLE;
new Handle:convar_ntstats_rankonoff = INVALID_HANDLE;
new Handle:convar_ntstats_20xp = INVALID_HANDLE;
new Handle:convar_ntstats_ffpenalty = INVALID_HANDLE;
new Handle:convar_ntstats_hidechat = INVALID_HANDLE;
new Handle:convar_ntstats_end_ffpenalty = INVALID_HANDLE;
new Handle:convar_ntstats_end_scoring = INVALID_HANDLE;
new Handle:convar_ntstats_version = INVALID_HANDLE;
new Handle:db = INVALID_HANDLE;
new Handle:convar_round_timelimit = INVALID_HANDLE;

new g_stats_score[MAXPLAYERS+1];
new g_stats_kills[MAXPLAYERS+1];
new g_stats_deaths[MAXPLAYERS+1];
new g_stats_xp[MAXPLAYERS+1];
new g_stats_teamkills[MAXPLAYERS+1];
new g_stats_teamkilled[MAXPLAYERS+1];
new g_stats_time_joined[MAXPLAYERS+1];
new g_stats_time_played[MAXPLAYERS+1];

new bool:g_admin_rankoff[MAXPLAYERS+1] = false;
new bool:g_stats_frozen[MAXPLAYERS+1] = false;
new bool:g_stats_freeze_toggle[MAXPLAYERS+1] = false;
new bool:g_stats_unfreeze_toggle[MAXPLAYERS+1] = false;
new bool:g_alive[MAXPLAYERS+1] = false;
new bool:sqlite = false;

//new bool:g_RoundEnd_TimeLimit = false;
new bool:g_RoundStarted = false;

new g_session_score[MAXPLAYERS+1];
new g_session_kills[MAXPLAYERS+1];
new g_session_deaths[MAXPLAYERS+1];
new g_session_xp[MAXPLAYERS+1];
new g_session_old_xp[MAXPLAYERS+1];
new g_session_teamkills[MAXPLAYERS+1];
new g_session_teamkilled[MAXPLAYERS+1];

new g_global_player_count;
new g_time;
new maxplayers;

new Handle:g_client_xp[MAXPLAYERS+1];
new Handle:LoopTimer = INVALID_HANDLE;

public OnPluginStart()
{
	decl String:error[256];
	if(SQL_CheckConfig("fg_stats_nt"))
	{
		db = SQL_Connect("fg_stats_nt", true, error, sizeof(error));
	}
	else
	{
		db = SQL_Connect("storage-local", true, error, sizeof(error));
	}
	
	if(db == INVALID_HANDLE)
	{
		LogError("Could not connect to database: %s", error);
		return;
	}
	decl String:driver[16];
	SQL_ReadDriver(db, driver, sizeof(driver));
	if(strcmp(driver, "mysql", false)==0)
	{
		sqlite = false;
	}
	else if(strcmp(driver, "sqlite", false)==0)
	{
		sqlite = true;
	}
	else
	{
		LogError("Invalid database type.");
		return;
	}
	SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS fg_stats (steamid varchar(255) NOT NULL default '', name varchar(255) NOT NULL default '', score int(12) NOT NULL default 1000, kills int(12) NOT NULL default 0, deaths int(12) NOT NULL default 0, xp int(12) NOT NULL default 0, teamkills int(12) NOT NULL default 0, teamkilled int(12) NOT NULL default 0, timeplayed int(12) NOT NULL default 0, last_connect timestamp NOT NULL default CURRENT_TIMESTAMP, frozen int(12) NOT NULL default 0)");
	
	GetPlayerCount();
	
	convar_ntstats_enabled = CreateConVar("sm_ntstats_enabled", "1", "Enables or Disables NEOTOKYO° Stats & Ranking.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_ntstats_rankonoff = CreateConVar("sm_ntstats_onoff", "1", "Allows players to rankoff and rankon.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_ntstats_20xp = CreateConVar("sm_ntstats_20xp", "1", "Players earn 3 points for reaching Lieutenant", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_ntstats_ffpenalty = CreateConVar("sm_ntstats_ff_penalty", "5", "Amount of points to take away from Team Killers. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 20.0);
	convar_ntstats_hidechat = CreateConVar("sm_ntstats_hidechat", "1", "session, top, stats, rankon and rankoff are hidden from chat.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_ntstats_end_ffpenalty = CreateConVar("sm_ntstats_end_ff_penalty", "0", "Enables or Disables FF Kill penalties at the end of a round.", FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	convar_ntstats_end_scoring = CreateConVar("sm_ntstats_end_scoring", "1", "Enables or Disables kill scoring at the end of a round.", FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	convar_ntstats_version = CreateConVar("sm_neotokyostats_version", PLUGIN_VERSION, "NEOTOKYO° Stats & Ranking version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true);
	SetConVarString(convar_ntstats_version, PLUGIN_VERSION, true, true);
	
	RegConsoleCmd("say", console_say);
	RegConsoleCmd("say_team", console_say);
	RegConsoleCmd("sm_stats", stats_info);
	
	RegAdminCmd("sm_ntstats_reset", AdminCmd_Reset, ADMFLAG_CONFIG, "Resets NEOTOKYO° Stats & Ranking stats.");
	RegAdminCmd("sm_ntstats_reset", AdminCmd_Reset, ADMFLAG_CONFIG, "Resets NEOTOKYO° Stats & Ranking stats.");
	RegAdminCmd("sm_ntstats_inactive", AdminCmd_Inactive, ADMFLAG_CONFIG, "Deletes players who haven't played for # of days.");
	RegAdminCmd("sm_rankon", AdminCmd_Rankon, ADMFLAG_BAN, "Enables a players point gain / loss. Enables player from enabling/disabling their own rank.");
	RegAdminCmd("sm_rankoff", AdminCmd_Rankoff, ADMFLAG_BAN, "Disables a players point gain / loss. Disables player from enabling/disabling their own rank.");
	
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("game_round_restart", Event_Game_Round_Restart);
	
	LoadTranslations("common.phrases");

}
public OnMapStart()
{
	maxplayers = GetMaxClients();
	if(LoopTimer == INVALID_HANDLE)
	{
		LoopTimer = CreateTimer(1.0, LoopThroughMinutes , 0, TIMER_REPEAT);
	}
}
public OnMapEnd()
{
	KillTimer(LoopTimer);
	LoopTimer = INVALID_HANDLE;
}
public Action:AdminCmd_Reset(client, args)
{
	SQL_TQuery(db, SQLErrorCheckCallback, "DELETE FROM fg_stats");
	LogAction(client, -1, "\"%L\" reset NEOTOKYO° Stats & Ranking.", client);
	return Plugin_Handled;
}
public Action:AdminCmd_Inactive(client, args)
{
	if(args != 1)
	{
		PrintToConsole(client, "Usage: sm_ntstats_inactive <days>");
		return Plugin_Handled;
	}
	decl String:arg1[192];
	if(!GetCmdArg(1, arg1, sizeof(arg1)))
	{
		PrintToConsole(client, "Usage: sm_ntstats_inactive <days>");
		return Plugin_Handled;
	}
	new days = StringToInt(arg1);
	if(days <= 0)
	{
		PrintToConsole(client, "Invalid number of days.");
		return Plugin_Handled;
	}
	decl String:query[128];
	
	if(sqlite)
	{
		Format(query, 128, "DELETE FROM fg_stats WHERE last_connect < datetime('now', '-%i days');", days);
	}
	else if(!sqlite)
	{
		Format(query, 128, "DELETE FROM fg_stats WHERE last_connect < current_timestamp - interval %i day;", days);
	}
	LogAction(client, -1, "\"%L\" removed inactive players from NEOTOKYO° Stats & Ranking. (\"%i\")", client, days);

	
	SQL_TQuery(db, SQLErrorCheckCallback, query);
	
	return Plugin_Handled;
}
public GetPlayerCount()
{
	new Handle:query = SQL_Query(db, "SELECT COUNT(*) FROM fg_stats");
	if(query == INVALID_HANDLE)
	{
		LogError("GetPlayerCount(): Error getting player count.");
	}
	g_global_player_count = SQL_FetchInt(query, 0);
	CloseHandle(query);
}
public Action:AdminCmd_Rankon(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_rankon <#userid|name>");
		return Plugin_Handled;
	}
	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		AdminRankon(client, target_list[i]);
	}
	return Plugin_Handled;
}
public Action:AdminCmd_Rankoff(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_rankoff <#userid|name>");
		return Plugin_Handled;
	}
	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		AdminRankoff(client, target_list[i]);
	}
	return Plugin_Handled;
}
public AdminRankon(client, target)
{
	g_admin_rankoff[target] = false;
	g_stats_frozen[target] = false;
	g_stats_freeze_toggle[target] = false;
	g_stats_unfreeze_toggle[target] = false;
	
	ShowActivity2(client, "[SM] ", "%N used rankon on %N", client, target);
	LogAction(client, target, "\"%L\" sm_rankon'd \"%L\"", client, target);
}
public AdminRankoff(client, target)
{
	g_admin_rankoff[target] = true;
	g_stats_frozen[target] = true;
	g_stats_freeze_toggle[target] = false;
	g_stats_unfreeze_toggle[target] = false;
	
	ShowActivity2(client, "[SM] ", "%N used rankoff on %N", client, target);
	LogAction(client, target, "\"%L\" sm_rankoff'd \"%L\"", client, target);
}
public Action:stats_info(userid, args)
{
	if(args < 1)
	{
		ShowStats(userid, userid);
	}
	else if(args == 1)
	{
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		
		new target = FindTarget(userid, arg, true, false);
		ShowStats(userid, target);
	}
	else if(args > 1)
	{
		PrintToConsole(userid, "Usage: sm_stats <#userid|name>");
	}
}
public Action:console_say(userid, args)
{
	if(!userid || !GetConVarBool(convar_ntstats_enabled))
		return Plugin_Continue;
	
	decl String:text[192];
	if(!GetCmdArgString(text, sizeof(text)))
		return Plugin_Continue;
	
	new startidx = 0;
	
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if(strcmp(text[startidx], "rank", false) == 0 || strcmp(text[startidx], "!rank", false) == 0 || strcmp(text[startidx], "/rank", false) == 0)
	{
		ShowRank(userid);
		return Plugin_Handled;
	}
	if(strcmp(text[startidx], "top", false) == 0 || strcmp(text[startidx], "top10", false) == 0 || strcmp(text[startidx], "!top", false) == 0 || strcmp(text[startidx], "!top10", false) == 0 || strcmp(text[startidx], "/top", false) == 0 || strcmp(text[startidx], "/top10", false) == 0)
	{
		ShowTop(userid);
		if(GetConVarBool(convar_ntstats_hidechat))
			return Plugin_Handled;
	}
	if(strcmp(text[startidx], "session", false) == 0 || strcmp(text[startidx], "!session", false) == 0 || strcmp(text[startidx], "/session", false) == 0)
	{
		ShowSession(userid);
		if(GetConVarBool(convar_ntstats_hidechat))
			return Plugin_Handled;
	}
	if(strcmp(text[startidx], "stats", false) == 0 || strcmp(text[startidx], "statsme", false) == 0 || strcmp(text[startidx], "!stats", false) == 0 || strcmp(text[startidx], "!statsme", false) == 0 || strcmp(text[startidx], "/stats", false) == 0 || strcmp(text[startidx], "/statsme", false) == 0)
	{
		ShowStats(userid, userid);	
		if(GetConVarBool(convar_ntstats_hidechat))
			return Plugin_Handled;
	}
	if(GetConVarBool(convar_ntstats_rankonoff))
	{
		if(strcmp(text[startidx], "rankoff", false) == 0 || strcmp(text[startidx], "!rankoff", false) == 0 || strcmp(text[startidx], "/rankoff", false) == 0)
		{
			FreezeRank(userid);
			if(GetConVarBool(convar_ntstats_hidechat))
				return Plugin_Handled;
		}
		if(strcmp(text[startidx], "rankon", false) == 0 || strcmp(text[startidx], "!rankon", false) == 0 || strcmp(text[startidx], "/rankon", false) == 0)
		{
			UnfreezeRank(userid);
			if(GetConVarBool(convar_ntstats_hidechat))
				return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if(GetConVarBool(convar_ntstats_enabled) && !IsFakeClient(client))
	{
		decl String:client_steamid[128], String:query[256];
		GetClientAuthString(client, client_steamid, sizeof(client_steamid));
		new userid = GetClientUserId(client);
		Format(query, sizeof(query), "SELECT score, kills, deaths, xp, teamkills, teamkilled, timeplayed, frozen FROM fg_stats WHERE steamid = '%s'", client_steamid);
		SQL_TQuery(db, SQLQueryConnect, query, userid);
		
		g_session_score[client] = 0;
		g_session_kills[client] = 0;
		g_session_deaths[client] = 0;
		g_session_xp[client] = 0;
		g_session_teamkills[client] = 0;
		g_session_teamkilled[client] = 0;
		g_session_old_xp[client] = 0;
		g_stats_freeze_toggle[client] = false;
		g_stats_unfreeze_toggle[client] = false;
		g_admin_rankoff[client] = false;
		
		g_stats_time_joined[client] = GetTime();
	}
}
public OnClientDisconnect(userid)
{
	if(GetConVarBool(convar_ntstats_enabled) && !IsFakeClient(userid))
	{
		if(g_admin_rankoff[userid])
			g_stats_frozen[userid] = false;
		SavePlayer(userid);
	}
}
public SQLQueryConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQLQueryConnect(): Query failed: %s", error);
	}
	else
	{
		decl String:query[512], String:client_name[64], String:client_steamid[128];
		GetClientName(client, client_name, sizeof(client_name));

		ReplaceString(client_name, sizeof(client_name), "'", "");
		GetClientAuthString(client, client_steamid, sizeof(client_steamid));

		if(!SQL_MoreRows(hndl))
		{
			Format(query, sizeof(query), "INSERT INTO fg_stats (steamid, name, score, kills, deaths, xp, teamkills, teamkilled, timeplayed, last_connect, frozen) VALUES ('%s', '%s', 1000, 0, 0, 0, 0, 0, 0, current_timestamp, 0)", client_steamid, client_name);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		
			g_stats_score[client] = 1000;
			g_stats_kills[client] = 0;
			g_stats_deaths[client] = 0;
			g_stats_xp[client] = 0;
			g_stats_teamkills[client] = 0;
			g_stats_teamkilled[client] = 0;
			g_stats_time_joined[client] = GetTime();
			g_stats_time_played[client] = 0;
			g_stats_frozen[client] = false;
			g_global_player_count++;
		}
		else
		{
			Format(query, sizeof(query), "UPDATE fg_stats SET name = '%s', last_connect = current_timestamp WHERE steamid = '%s'", client_name, client_steamid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		}
		while(SQL_FetchRow(hndl))
		{
			g_stats_score[client] 		= SQL_FetchInt(hndl, 0);
			g_stats_kills[client] 		= SQL_FetchInt(hndl, 1);
			g_stats_deaths[client]		= SQL_FetchInt(hndl, 2);
			g_stats_xp[client] 			= SQL_FetchInt(hndl, 3);
			g_stats_teamkills[client] 	= SQL_FetchInt(hndl, 4);
			g_stats_teamkilled[client] 	= SQL_FetchInt(hndl, 5);
			g_stats_time_played[client] = SQL_FetchInt(hndl, 6);
			g_stats_frozen[client] 		= SQL_FetchInt(hndl, 7)==0?false:true;
		}
	}
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error))
	{
		LogError("Query failed: %s", error);
	}
}
public ShowRank(client)
{
	decl String:query[512];
	Format(query, sizeof(query), "SELECT DISTINCT score FROM fg_stats WHERE score > %i ORDER BY score ASC;", g_stats_score[client]);
	SQL_TQuery(db, SQLQueryRank, query, GetClientUserId(client));
}
public ShowTop(client)
{
	decl String:query[512];
	Format(query, sizeof(query), "SELECT name, score, kills, deaths FROM fg_stats ORDER BY score DESC LIMIT 20");
	SQL_TQuery(db, SQLQueryTop, query, GetClientUserId(client));
}

public SQLQueryRank(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	if((client = GetClientOfUserId(data))==0)
	{
		return;
	}
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQLQueryRank(): Query failed: %s", error);
	}
	else
	{
	
		new rank = SQL_GetRowCount(hndl);
		new next_score = 0;
		new bool:rankup = true;
	
		if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		{
			rank = SQL_GetRowCount(hndl);
			rank += 1;
			rankup = false;
			next_score = SQL_FetchInt(hndl, 0);
		}
		if(rankup)
		{
			rank += 1;
		}
		RankDisplay(client, rank, next_score);
	}
}
public RankDisplay(client, rank, next_score)
{
	new delta = 0;
	if(next_score > g_stats_score[client])
	{
		delta = next_score - g_stats_score[client];
	}
	decl String:text[256], String:client_name[64];
	GetClientName(client, client_name, sizeof(client_name));
	if(delta != 0)
	{
		Format(text, sizeof(text), "%s is rank %i/%i with %i points (%i to next rank), %i kills and %i deaths (%i total XP.)", client_name, rank, g_global_player_count, g_stats_score[client], delta, g_stats_kills[client], g_stats_deaths[client], g_stats_xp[client]);
	}
	else
	{
		Format(text, sizeof(text), "%s is rank %i/%i with %i points, %i kills and %i deaths (%i total XP.)", client_name, rank, g_global_player_count, g_stats_score[client], g_stats_kills[client], g_stats_deaths[client], g_stats_xp[client]);
	}
	PrintToConsoleAll(text);
	PrintToChatAll(text);
}
public ShowSession(client)
{
	decl String:text[256], String:client_name[64];
	GetClientName(client, client_name, sizeof(client_name));
	
	new Handle:sessioninfo = CreatePanel();
	
	SetPanelTitle(sessioninfo, "Player Session Stats");
	
	if(g_stats_frozen[client])
	{
		if(g_admin_rankoff[client])
			DrawPanelText(sessioninfo, "YOUR RANK POINTS ARE FROZEN AND DISABLED");
		else
			DrawPanelText(sessioninfo, "YOUR RANK POINTS ARE FROZEN \n Type rankon to unfreeze them.");
	}
	
	DrawPanelItem(sessioninfo, "Name");
	Format(text, sizeof(text), "%s", client_name);
	DrawPanelText(sessioninfo, text);
	
	DrawPanelItem(sessioninfo, "Score");
	Format(text, sizeof(text), "%s%i (%i)", (g_session_score[client] < 0 ? "" : "+"), g_session_score[client], g_stats_score[client]);
	DrawPanelText(sessioninfo, text);
	
	DrawPanelItem(sessioninfo, "XP");
	Format(text, sizeof(text), "%s%i (%i)", (g_session_xp[client] < 0 ? "" : "+"), g_session_xp[client], g_stats_xp[client]);
	DrawPanelText(sessioninfo, text);
	
	new g_session_timeplayed = GetTime() - g_stats_time_joined[client];
	DrawPanelItem(sessioninfo, "Time played");
	Format(text, sizeof(text), "%id %ih %im", g_session_timeplayed / 86400, (g_session_timeplayed % 86400) / 3600, (g_session_timeplayed % 3600) / 60);
	DrawPanelText(sessioninfo, text);
	
	DrawPanelItem(sessioninfo, "Kills/Deaths");
	Format(text, sizeof(text), "%i/%i - %.2f KD", g_session_kills[client], g_session_deaths[client], float(g_session_kills[client])/(g_session_deaths[client] > 0 ? float(g_session_deaths[client]) : 1.0));
	DrawPanelText(sessioninfo, text);
	
	if(g_session_teamkills[client] > 0 || g_session_teamkilled[client] > 0)
	{
		DrawPanelItem(sessioninfo, "Teamkills / Times Teamkilled");
		Format(text, sizeof(text), "%i / %i", g_session_teamkills[client], g_session_teamkilled[client]);
		DrawPanelText(sessioninfo, text);
	}
	
	SendPanelToClient(sessioninfo, client, PanelHandler, 10);
	CloseHandle(sessioninfo);
}
public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
public FreezeRank(client)
{
	if(g_admin_rankoff[client])
	{
		PrintToChat(client, "Your rank point gain/loss is frozen and disabled by an Admin.");
	}
	else
	{
		if(g_stats_unfreeze_toggle[client])
		{
			g_stats_unfreeze_toggle[client] = false;
			g_stats_freeze_toggle[client] = true;
			PrintToChat(client, "Your rank point gain/loss will not be unfrozen when you next spawn or die.");
		}
		else if(g_stats_frozen[client])
		{
			PrintToChat(client, "Your rank point gain/loss are already frozen.");
		}
		else
		{
			g_stats_freeze_toggle[client] = true;
			PrintToChat(client, "Your rank point gain/loss will be frozen when you next spawn or die.");
		}
	}
}
public UnfreezeRank(client)
{
	if(g_admin_rankoff[client])
	{
		PrintToChat(client, "Your rank point gain/loss is frozen and disabled by an Admin.");
	}
	else
	{
		if(g_stats_freeze_toggle[client])
		{
			g_stats_freeze_toggle[client] = false;
			g_stats_unfreeze_toggle[client] = true;
			PrintToChat(client, "Your rank point gain/loss will not be frozen when you next spawn or die.");
		}
		else if(!g_stats_frozen[client])
		{
			PrintToChat(client, "Your rank point gain/loss are already unfrozen.");
		}
		else
		{
			g_stats_unfreeze_toggle[client] = true;
			PrintToChat(client, "Your rank point gain/loss will be unfrozen when you next spawn or die.");
		}
	}
}
public SQLQueryTop(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	if((client = GetClientOfUserId(data))==0)
	{
		return;
	}
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQLQueryTop(): Query failed: %s", error);
	}
	else
	{
		new index = 0, top_score, top_kills, top_deaths, last_score = 0;
		decl String:top_name[64], String:text[11][256];
		new Handle:top10 = CreatePanel();
	
		SetPanelTitle(top10, "Top 10 Players");
		
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				index++;
				SQL_FetchString(hndl, 0, top_name, sizeof(top_name));
				top_score = SQL_FetchInt(hndl, 1);
				top_kills = SQL_FetchInt(hndl, 2);
				top_deaths = SQL_FetchInt(hndl, 3);
				if(top_score == last_score && index <= 11)
				{
					index-= 1;
				}
				if(index > 3 && index < 11)
				{
					if(top_score == last_score)
					{
						Format(text[index], 256, "%s\n%i. %s - %.2f KD", text[index], index, top_name, float(top_kills)/ (top_deaths == 0 ? 1.0 : float(top_deaths)));
					}
					else
					{
						Format(text[index], 256, "%i. %s - %.2f KD - %i points", index, top_name, float(top_kills)/ (top_deaths == 0 ? 1.0 : float(top_deaths)), top_score);
					}
				}
				else if(index < 11)
				{
					if(top_score == last_score)
					{
						Format(text[index], 256, "%s\n%i. %s - %.2f KD", text[index], index, top_name, float(top_kills)/ (top_deaths == 0 ? 1.0 : float(top_deaths)));
					}
					else
					{
						Format(text[index], 256, "%s - %.2f KD - %i points", top_name, float(top_kills)/ (top_deaths == 0 ? 1.0 : float(top_deaths)), top_score);
					}
				}
				last_score = top_score;
			}
			if(index > 10)
				index = 10;
			for (new i=1;i<=index;i++)
			{
				if(i > 3)
				{
					DrawPanelText(top10, text[i]);
				}
				else
				{
					DrawPanelItem(top10, text[i]);
				}
			}
		}
		SendPanelToClient(top10, client, PanelHandler, 10);
		CloseHandle(top10);
	}
}
public ShowStats(target, client)
{
	decl String:text[256], String:client_name[64];
	GetClientName(client, client_name, sizeof(client_name));
	
	new Handle:statsinfo = CreatePanel();
	
	SetPanelTitle(statsinfo, "Player Stats");

	DrawPanelItem(statsinfo, "Name");
	Format(text, sizeof(text), "%s", client_name);
	DrawPanelText(statsinfo, text);
	
	DrawPanelItem(statsinfo, "Score");
	Format(text, sizeof(text), "%i", g_stats_score[client]);
	DrawPanelText(statsinfo, text);
	
	DrawPanelItem(statsinfo, "XP");
	Format(text, sizeof(text), "%i", g_stats_xp[client]);
	DrawPanelText(statsinfo, text);
	
	new g_timeplayed = g_stats_time_played[client] + (GetTime() - g_stats_time_joined[client]);
	DrawPanelItem(statsinfo, "Time played");
	Format(text, sizeof(text), "%id %ih %im", g_timeplayed / 86400, (g_timeplayed % 86400) / 3600, (g_timeplayed % 3600) / 60);
	DrawPanelText(statsinfo, text);
	
	DrawPanelItem(statsinfo, "Kills/Deaths");
	Format(text, sizeof(text), "%i/%i - %.2f KD", g_stats_kills[client], g_stats_deaths[client], float(g_stats_kills[client])/(g_stats_deaths[client] > 0 ? float(g_stats_deaths[client]) : 1.0));
	DrawPanelText(statsinfo, text);
	
	DrawPanelItem(statsinfo, "Teamkills / Times Teamkilled");
	Format(text, sizeof(text), "%i / %i", g_stats_teamkills[client], g_stats_teamkilled[client]);
	DrawPanelText(statsinfo, text);

	SendPanelToClient(statsinfo, target, PanelHandler, 10);
	CloseHandle(statsinfo);
}
public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(convar_ntstats_enabled))
	{
		new userid = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(userid != 0 && attacker != 0 && IsClientConnected(userid) && IsClientConnected(attacker) && IsClientInGame(userid) && IsClientInGame(userid) && !IsFakeClient(userid) && !IsFakeClient(attacker))
		{
			if(GetConVarBool(convar_ntstats_rankonoff))
			{
				if(g_stats_freeze_toggle[userid])
				{
					g_stats_freeze_toggle[userid] = false;
					g_stats_frozen[userid] = true;
					PrintToChat(userid, "Your rank point gain/loss has been frozen. Type rankon to unfreeze them.");
				}
				if(g_stats_unfreeze_toggle[userid])
				{
					g_stats_unfreeze_toggle[userid] = false;
					g_stats_frozen[userid] = false;
					PrintToChat(userid, "Your rank point gain/loss has been unfrozen. Type rankoff to freeze them.");
				}
			}
			else if(!GetConVarBool(convar_ntstats_rankonoff))
			{
				g_stats_frozen[userid] = false;
			}
			new userid_team = GetClientTeam(userid);
			new attacker_team = GetClientTeam(attacker);
			if(userid == attacker && !g_stats_frozen[userid] && !g_RoundStarted)
			{
				g_stats_deaths[userid] += 1;
				g_session_deaths[userid] += 1;
				g_stats_score[userid] -= 2;
				g_session_score[userid] -= 2;
			}
			else if(userid_team == attacker_team && userid != attacker)
			{
				if(!g_RoundStarted && !GetConVarBool(convar_ntstats_end_ffpenalty))
				{
					//Nothing.
				}
				else if(!g_RoundStarted || g_RoundStarted)
				{
					if(GetConVarInt(convar_ntstats_ffpenalty) != 0)
					{
						g_stats_score[attacker] -= GetConVarInt(convar_ntstats_ffpenalty);
						g_session_score[attacker] -= GetConVarInt(convar_ntstats_ffpenalty);
						g_stats_teamkills[attacker] += 1;
						g_session_teamkills[attacker] += 1;
						if(!g_stats_frozen[userid])
						{
							g_stats_teamkilled[userid] += 1;
							g_session_teamkilled[userid] += 1;
							g_stats_deaths[userid] += 1;
							g_session_deaths[userid] += 1;
						}
					}
				}
			}
			else if(userid_team != attacker_team)
			{
				if(!g_RoundStarted && !GetConVarBool(convar_ntstats_end_scoring))
				{
					//Nothing.
				}
				else
				{
					new String:attacker_weapon[64];
					GetEventString(event, "weapon", attacker_weapon, sizeof(attacker_weapon));
					
					new bonus_points = 0;
					new score_dif_userid = g_stats_score[userid] - g_stats_score[attacker];
					if(score_dif_userid < 0)
						score_dif_userid = 1;
					else
						score_dif_userid = 1 + (g_stats_score[userid] - g_stats_score[attacker])/50;
					if(score_dif_userid > 2)
						score_dif_userid = 2;
					if(StrEqual("knife",attacker_weapon)== true)
						bonus_points += 2;
					
					new XP_bonus = GetXP(userid) - GetXP(attacker);
					if(XP_bonus < 0)
						XP_bonus = 0;
					else
					{
						XP_bonus = XP_bonus/4;
						if(XP_bonus < 1)
							XP_bonus = 1;
					}
					new score_dif_attacker = g_stats_score[userid] - g_stats_score[attacker];
					if(score_dif_attacker < 0)
						score_dif_attacker = (2 + XP_bonus) + bonus_points;
					else
						score_dif_attacker = 2 + (((g_stats_score[userid] - g_stats_score[attacker])/50) + XP_bonus) + bonus_points;
					
					if(!g_stats_frozen[userid])
					{
						g_stats_deaths[userid] += 1;
						g_session_deaths[userid] += 1;
						g_stats_score[userid] -= score_dif_userid;
						g_session_score[userid] -= score_dif_userid;
					}
					if(!g_stats_frozen[attacker])
					{
						g_stats_kills[attacker] += 1;
						g_session_kills[attacker] += 1;
						g_stats_score[attacker] += score_dif_attacker;
						g_session_score[attacker] += score_dif_attacker;
					}
				}
			}
			if(g_RoundStarted)
				g_alive[userid] = false;
			
			SavePlayer(userid);
			SavePlayer(attacker);
			SaveXP(attacker);
			SaveXP(userid);
		}
	}
}
public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(convar_ntstats_enabled))
	{
		new userid = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetConVarBool(convar_ntstats_rankonoff))
		{
			if(g_stats_freeze_toggle[userid])
			{
				g_stats_freeze_toggle[userid] = false;
				g_stats_frozen[userid] = true;
				PrintToChat(userid, "Your rank point gain/loss has been frozen. Type rankon to unfreeze them.");
			}
			if(g_stats_unfreeze_toggle[userid])
			{
				g_stats_unfreeze_toggle[userid] = false;
				g_stats_frozen[userid] = false;
				PrintToChat(userid, "Your rank point gain/loss has been unfrozen. Type rankoff to freeze them.");
			}
		}
		else if(!GetConVarBool(convar_ntstats_rankonoff))
		{
			g_stats_frozen[userid] = false;
		}
		SaveXP(userid);
		SavePlayer(userid);
		
		if(g_RoundStarted)
			g_alive[userid] = true;
	}
}
public SavePlayer(client)
{
	decl String:client_steamid[128], String:client_name[64], String:query[512];
	GetClientAuthString(client, client_steamid, sizeof(client_steamid));
	GetClientName(client, client_name, sizeof(client_name));
	ReplaceString(client_name, sizeof(client_name), "'", "");
	Format(query, sizeof(query), "UPDATE fg_stats SET name = '%s', score = %i, kills = %i, deaths = %i, xp = %i, teamkills = %i, teamkilled = %i, timeplayed = %i, frozen = %i WHERE steamid = '%s'", client_name, g_stats_score[client], g_stats_kills[client], g_stats_deaths[client], g_stats_xp[client], g_stats_teamkills[client], g_stats_teamkilled[client], g_stats_time_played[client] + (GetTime() - g_stats_time_joined[client]), g_stats_frozen[client], client_steamid);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
}

public SaveXP(client)
{
	g_client_xp[client] = CreateTimer(0.1, Timer_SaveXP, client, TIMER_FLAG_NO_MAPCHANGE);
}

public KillTimer_SaveXP(client)
{
	g_client_xp[client] = INVALID_HANDLE;
}
public Action:Timer_SaveXP(Handle:timer, any:client)
{
	if(client != 0)
	{
		if (!IsClientInGame(client) || g_stats_frozen[client])
		{
			KillTimer_SaveXP(client);
			return Plugin_Handled;
		}
		
		new client_xp = GetXP(client);
		if(client_xp > g_session_old_xp[client])
		{
			g_stats_xp[client] += (client_xp - g_session_old_xp[client]);
			g_session_xp[client] += (client_xp - g_session_old_xp[client]);
		}
		else if(client_xp < g_session_old_xp[client])
		{
			g_stats_xp[client] -= (g_session_old_xp[client] - client_xp);
			g_session_xp[client] -= (g_session_old_xp[client] - client_xp);
		}
		if(GetConVarBool(convar_ntstats_20xp))
		{
			if(g_session_old_xp[client] < 20 && g_session_xp[client] >= 20)
			{
				g_stats_score[client] += 3;
				g_session_score[client] += 3;
			}
		}
		g_session_old_xp[client] = g_session_xp[client];
		
		SavePlayer(client);
	}
	return Plugin_Handled;
}	
stock GetXP(client)
{
	return GetClientFrags(client);
}
PrintToConsoleAll(String:text[])
{
	for(new i=1;i<=maxplayers;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintToConsole(i, text);
		}
	}
}
public Event_Game_Round_Restart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(convar_ntstats_enabled))
	{
		g_time = 0;
		Event_RoundEnd();
	}
}

public Action:LoopThroughMinutes(Handle:timer,any:client)
{
	if (GetConVarBool(convar_ntstats_enabled))
	{
		decl String:round_timelimit[32] = "neo_round_timelimit";
		convar_round_timelimit = FindConVar(round_timelimit);
		
		g_time++;
		if(g_time == 15)
		{
			Event_RoundStart();
		}
		else if(g_time == (GetConVarInt(convar_round_timelimit) * 60))
		{
			//g_RoundEnd_TimeLimit = true;
			Event_RoundEnd();
		}
	}
}
public Event_RoundStart()
{
	g_RoundStarted = true;
	//g_RoundEnd_TimeLimit = false;
	for(new i=1;i<=maxplayers;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			g_alive[i] = true;
		}
	}
}
public Event_RoundEnd()
{
	g_RoundStarted = false;
	new Jinrai_Count = 0, NSF_Count = 0;
	for(new i=1;i<=maxplayers;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && g_alive[i])
		{
			new i_team = GetClientTeam(i);
			switch(i_team)
			{
				case 2: Jinrai_Count++;
				case 3:	NSF_Count++;
			}
		}
	}
	for(new i=1;i<=maxplayers;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !g_stats_frozen[i])
		{
			new i_team = GetClientTeam(i);
			if(Jinrai_Count > NSF_Count)
			{
				if(i_team == 2 && g_alive[i])
				{
					g_stats_score[i] += 3;
					g_session_score[i] += 3;
				}
				else if(i_team == 2)
				{
					g_stats_score[i] += 1;
					g_session_score[i] += 1;
				}
			}
			else if(NSF_Count > Jinrai_Count)
			{
				if(i_team == 3 && g_alive[i])
				{
					g_stats_score[i] += 3;
					g_session_score[i] += 3;
				}
				else if(i_team == 3)
				{
					g_stats_score[i] += 1;
					g_session_score[i] += 1;
				}
			}
			else if(NSF_Count == Jinrai_Count)
			{
				if(g_alive[i])
				{
					g_stats_score[i] += 2;
					g_session_score[i] += 2;
				}
				else
				{
					g_stats_score[i] += 1;
					g_session_score[i] += 1;
				}
			}
			SavePlayer(i);
		}
	}
}
