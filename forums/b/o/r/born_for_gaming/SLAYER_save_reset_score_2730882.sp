#include <sourcemod>
#include <clientprefs>
#include <cstrike>
#include <morecolors>

#include "savescores/globals.sp"
#include "savescores/cstrike.sp"
#define GAME_CSTRIKE 1
#pragma semicolon 1
#pragma newdecls required
ConVar cvar_save_scores_warmod;
ConVar status;
EngineVersion g_Game;
#undef REQUIRE_PLUGIN
#define PLUGIN_VERSION "2.4.3"
bool CSGO;
public Plugin myinfo = 
{
	name = "[CSS/CSGO] Savescores/Resetscores",
	author = "SLAYER",
	description = "Save scores and Rest scores of the players.",
	version = PLUGIN_VERSION,
	url = "https://bit.ly/2L62Ogg"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS && g_Game != Engine_SourceSDK2006)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	CSGO = (g_Game == Engine_CSGO);
	// Creating cvars
	CreateConVar("SLAYER_save_reset_scores_version", PLUGIN_VERSION, "Save Scores Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_save_scores = CreateConVar("sm_save_scores", "1", "Enabled/Disabled save scores functionality, 0 = off/1 = on", 0, true, 0.0, true, 1.0);
	cvar_save_scores_tracking_time = CreateConVar("sm_save_scores_tracking_time", "0", "Amount of time in minutes to store a player score for, if set to 0 the score will be tracked for the duration of the map", 0, true, 0.0, true, 60.0);
	cvar_save_scores_forever = CreateConVar("sm_save_scores_forever", "0", "If set to 1 save scores will not clear scores on map change or round restart. Track players scores until admin will use \"sm_save_scores_reset\"", 0, true, 0.0, true, 1.0);
	cvar_save_scores_allow_reset = CreateConVar("sm_save_reset_scores_allow_reset", "1", "Allow players to reset there scores, 0 = off/1 = on", 0, true, 0.0, true, 1.0);
	cvar_save_scores_warmod = CreateConVar("sm_save_reset_scores_warmod", "1", "To disable Reset score when War Start (1 = Enabled). Its enabled when sm_save_scores_allow_reset 1", 0, true, 0.0, true, 1.0);
	cvar_lan = FindConVar("sv_lan");
	status = FindConVar("wm_status");

	
	
	// Hooking cvar change
	HookConVarChange(cvar_lan, OnCVarChange);
	HookConVarChange(cvar_save_scores, OnCVarChange);
	HookConVarChange(cvar_save_scores_tracking_time, OnCVarChange);
	HookConVarChange(cvar_save_scores_forever, OnCVarChange);
	HookConVarChange(cvar_save_scores_allow_reset, OnCVarChange);
	
	// Hooking event
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	// Creating commands
	RegConsoleCmd("sm_resetscore", ResetScore, "Resets your deaths and kills back to 0");
	RegConsoleCmd("sm_rs", ResetScore, "Resets your deaths and kills back to 0");
	RegAdminCmd("sm_save_scores_reset", Command_Clear, ADMFLAG_GENERIC, "Resets all saved scores");
	RegAdminCmd("sm_resetplayer", CommandResetPlayer, ADMFLAG_SLAY);
	RegAdminCmd("sm_reset", CommandResetPlayer, ADMFLAG_SLAY);
	RegAdminCmd("sm_setstars", CommandSetStars, ADMFLAG_SLAY);
	if(CSGO)
	{
		RegAdminCmd("sm_setassists", CommandSetAssists, ADMFLAG_SLAY);
		RegAdminCmd("sm_setpoints", CommandSetPoints, ADMFLAG_SLAY);
		RegAdminCmd("sm_setscore", CommandSetScoreCSGO, ADMFLAG_SLAY);
	}
	else
	{
		RegAdminCmd("sm_setscore", CommandSetScore, ADMFLAG_SLAY);
	}
	

	AutoExecConfig(true, "SLAYER_save_reset_score");
	

	InitDB();	

	ClearDB();
	
	CreateTimer(1.0, SaveAllScores, _, TIMER_REPEAT);
}

public void NewGameCommand(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(!save_scores || StringToInt(newValue) == 0)
	{
		return;
	}
	
	float fTimer = StringToFloat(newValue);
	
	if(isNewGameTimer)
	{
		CloseHandle(g_hNewGameTimer);
	}
	
	g_hNewGameTimer = CreateTimer(fTimer - 0.1, MarkNextRoundAsNewGame);
	isNewGameTimer = true;
} 


public Action MarkNextRoundAsNewGame(Handle timer)
{
	isNewGameTimer = false;
	g_NextRoundNewGame = true;
}

// If round is a new game we should clear DB or restore players' scores
public Action Event_NewGameStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_NextRoundNewGame)
	{
		return Plugin_Continue;
	}
	
	g_NextRoundNewGame = false;	
	ClearDB();
	
	if(!save_scores_forever || !save_scores || isLAN)
	{
		return Plugin_Continue;
	}
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && !justConnected[client])
		{
			SetScore(client, g_iPlayerScore[client]);
			SetDeaths(client, g_iPlayerDeaths[client]);
			SetCash(client, g_iPlayerCash[client]);
		}
	}
	
	return Plugin_Continue;
}


public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!save_scores_forever || !save_scores || isLAN)
	{
		return Plugin_Continue;
	}
	
	char szMessage[32];
	GetEventString(event, "message", szMessage, sizeof(szMessage));
	
	if(StrEqual(szMessage, "#Game_Commencing") || StrEqual(szMessage, "#Round_Draw"))
	{
		g_NextRoundNewGame = true;
	}
	
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	GetCVars();
	
	if(save_scores && save_scores_allow_reset && !g_isMenuItemCreated)
	{
		SetCookieMenuItem(ResetScoreInMenu, 0, "Reset Score");
		g_isMenuItemCreated = true;
	}
}

// Action that will be done when menu item will be pressed
public void ResetScoreInMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{	
	if(action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%T", "Reset Score", client);
		return;
	}
	
	if(!save_scores || !save_scores_allow_reset)
	{
		return;
	}
	
	SetDeaths(client, 0);
	SetScore(client, 0);
	RemoveScoreFromDB(client);
	CPrintToChat(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} You {lime}have {white}just {aqua}reset {yellow}your {white}score{lime}!");
}

public Action ResetScore(int client, int args)
{
	if(GetConVarInt(status) > 4 && GetConVarInt(cvar_save_scores_warmod) == 1 && GetConVarInt(cvar_save_scores_allow_reset) == 1)
	{ 
			char name[MAX_NAME_LENGTH];
			GetClientName(client, name, sizeof(name));
			CPrintToChatAll("\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} Player \x03%s {aqua}want to {crimson}reset {white}his {cyan}Scores. {magenta}Noob {lime}Reset {yellow}Score is {fullred}Disabled!!!", name);
			return Plugin_Handled;
	}
	else if(GetConVarInt(status) > 4 && client > 0 && GetDeaths(client) == 0 && GetScore(client) == 0)
	{
		if(CSGO && CS_GetClientAssists(client) == 0 && CS_GetMVPCount(client) == 0)
		{
			CPrintToChat(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {yellow}Your {lime}Score {white}is {aqua}already \x030{yellow}!");
			return Plugin_Handled;
		}
		if(!CSGO)
		{
			CPrintToChat(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {yellow}Your {lime}Score {white}is {aqua}already \x030{yellow}!");
			return Plugin_Handled;
		}
	}
	else if(GetConVarInt(status) > 4 && GetConVarInt(cvar_save_scores_warmod) == 0)
	{
			SetDeaths(client, 0);
			SetScore(client, 0);
			RemoveScoreFromDB(client);		
			char name[MAX_NAME_LENGTH];
			GetClientName(client, name, sizeof(name));
			if(GetClientTeam(client) == 2)
			{
				CPrintToChatAll("\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} Player {red}%s {lime}has {white}just {aqua}reset {yellow}his {white}score{lime}!", name);
			}
			else if(GetClientTeam(client) == 3)
			{
				CPrintToChatAll("\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} Player {blue}%s {lime}has {white}just {aqua}reset {yellow}his {white}score{lime}!", name);
			}
			else if(GetClientTeam(client) == 1)
			{
				CPrintToChatAll("\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} Player {white}%s {lime}has {white}just {aqua}reset {yellow}his {white}score{lime}!", name);
			}
	}
	if(!save_scores && !save_scores_allow_reset)
	{
		return Plugin_Handled;
	}
	if(client > 0 && GetConVarInt(status) == 4 && GetDeaths(client) == 0 && GetScore(client) == 0)
	{
		if(CSGO && CS_GetClientAssists(client) == 0 && CS_GetMVPCount(client) == 0)
		{
			CPrintToChat(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {yellow}Your {lime}Score {white}is {aqua}already \x030{yellow}!");
			return Plugin_Handled;
		}
		if(!CSGO)
		{
			CPrintToChat(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {yellow}Your {lime}Score {white}is {aqua}already \x030{yellow}!");
			return Plugin_Handled;
		}
	}
	if(client > 0 && GetConVarInt(status) == 4)
	{
		SetDeaths(client, 0);
		SetScore(client, 0);
		RemoveScoreFromDB(client);
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		if(GetConVarInt(cvar_save_scores_allow_reset) == 1)
		{
			if(GetClientTeam(client) == 2)
			{
				CPrintToChatAll("\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} Player {red}%s {lime}has {white}just {aqua}reset {yellow}his {white}score{lime}!", name);
			}
			else if(GetClientTeam(client) == 3)
			{
				CPrintToChatAll("\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} Player {blue}%s {lime}has {white}just {aqua}reset {yellow}his {white}score{lime}!", name);
			}
			else if(GetClientTeam(client) == 1)
			{
				CPrintToChatAll("\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]{yellow} Player {white}%s {lime}has {white}just {aqua}reset {yellow}his {white}score{lime}!", name);
			}	
		}
	}
	return Plugin_Handled;
}

// Here we are creating SQL DB
public void InitDB()
{
	// SQL DB
	char error[255];
	g_hDB = SQLite_UseDatabase("SLAYER_save_reset_score", error, sizeof(error));	
	if(g_hDB == INVALID_HANDLE) SetFailState("SQL error: %s", error);	
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, "VACUUM");
	SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS savescores_scores (steamid TEXT PRIMARY KEY, frags SMALLINT, deaths SMALLINT, money SMALLINT, timestamp INTEGER);");
	SQL_UnlockDatabase(g_hDB);
}

public Action Command_Clear(int admin, int args)
{
	if(!save_scores || !save_scores_allow_reset)
	{
		CReplyToCommand(admin, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {lime}Reset {yellow}Scores {white}]is {aqua}currently\x03 disabled.");
		return Plugin_Handled;
	}
	
	ClearDB(false);
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			SetScore(client, 0);
			SetDeaths(client, 0);			
			SetCash(client, g_CSDefaultCash);
		}
	}
	
	CReplyToCommand(admin, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {lime}Players {white}scores {aqua}has {yellow}been\x03 reset.");
	return Plugin_Handled;
}

// Just clear DB. Sometimes we need it to be delayed.
void ClearDB(bool Delay = true)
{
	if(Delay)
	{
		CreateTimer(0.1, ClearDBDelayed);
	}
	else
	{
		ClearDBQuery();
	}
}

public Action ClearDBDelayed(Handle timer)
{
	if(!save_scores_forever)
	{
		ClearDBQuery();
	}
}

// Doing clearing stuff
void ClearDBQuery()
{
	// Clearing SQL DB
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, "DELETE FROM savescores_scores;");
	SQL_UnlockDatabase(g_hDB);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("OnCalcPlayerScore");
	return APLRes_Success;
}

public void OnMapStart()
{
	ClearDB();
}

public Action SaveAllScores(Handle timer)
{
	if(!save_scores_forever || !save_scores || isLAN)
	{
		return Plugin_Continue;
	}
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client) && !justConnected[client])
		{
			g_iPlayerScore[client] = GetScore(client);
			g_iPlayerDeaths[client] = GetDeaths(client);			
			// If game is CS also save player's cash
			g_iPlayerCash[client] = GetCash(client);
		}
	}
	
	return Plugin_Continue;
}

// Syncronize DB with score varibles
public void SyncDB()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
		{
			char steamId[30], query[200];			
			GetClientAuthId(client, AuthId_Engine, steamId, sizeof(steamId));
			int frags = GetScore(client);
			int deaths = GetDeaths(client);
			int cash = GetCash(client);			
			Format(query, sizeof(query), "INSERT OR REPLACE INTO savescores_scores VALUES ('%s', %d, %d, %d, %d);", steamId, frags, deaths, cash, GetTime());
			SQL_FastQuery(g_hDB, query);
		}
	}
}

// Most of the score manipulations will be done in this event
public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || isLAN || !save_scores) return Plugin_Continue;
	if(IsFakeClient(client) || !IsClientInGame(client)) return Plugin_Continue;
	
	if(GetEventInt(event, "team") == 1 && save_scores_css_spec_cash && !justConnected[client])
	{
		InsertScoreInDB(client);
		return Plugin_Continue;
	}
	else if(GetEventInt(event, "team") > 1 && GetEventInt(event, "oldteam") < 2 && save_scores_css_spec_cash && !justConnected[client])
	{
		onlyCash[client] = false;
		GetScoreFromDB(client);
	}
	else if(justConnected[client] && GetEventInt(event, "team") != 1)
	{
		justConnected[client] = false;
		GetScoreFromDB(client);
	}
	
	return Plugin_Continue;
}

public int GetScore(int client)
{
	return GetClientFrags(client);
}

public void SetScore(int client, int score)
{
	SetEntProp(client, Prop_Data, "m_iFrags", score);
}

public int GetDeaths(int client)
{
	return GetEntProp(client, Prop_Data, "m_iDeaths");		
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));	
	justConnected[client] = true;
	onlyCash[client] = false;	
	if(!client || isLAN || !save_scores || !IsClientInGame(client) || IsFakeClient(client)) return;	
	InsertScoreInDB(client);
}


void InsertScoreInDB(int client)
{
	char steamId[30];
	int cash = 0;
	GetClientAuthId(client, AuthId_Engine, steamId, sizeof(steamId));
	int frags = GetScore(client);
	int deaths = GetDeaths(client);
	cash = GetCash(client);
	if(frags == 0 && deaths == 0 && cash == g_CSDefaultCash) return;
	InsertScoreQuery(steamId, frags, deaths, cash);
}

void InsertScoreQuery(const char[] steamId, int frags, int deaths, int cash)
{
	char query[200];
	Format(query, sizeof(query), "INSERT OR REPLACE INTO savescores_scores VALUES ('%s', %d, %d, %d, %d);", steamId, frags, deaths, cash, GetTime());
	SQL_TQuery(g_hDB, EmptySQLCallback, query);
}

public void GetScoreFromDB(int client)
{
	if(!IsClientInGame(client))
	{
		onlyCash[client] = false;
		return;
	}
	
	char steamId[30], query[200];	
	GetClientAuthId(client, AuthId_Engine, steamId, sizeof(steamId));
	Format(query, sizeof(query), "SELECT * FROM	savescores_scores WHERE steamId = '%s';", steamId);
	SQL_TQuery(g_hDB, SetPlayerScore, query, client);
}

public void OnMapEnd()
{
	if (save_scores_forever && save_scores && !isLAN) SyncDB();
}

public void SetPlayerScore(Handle owner, Handle hndl, const char[] error, any client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", error);
		onlyCash[client] = false;
		return;
	}
	
	if(SQL_GetRowCount(hndl) == 0)
	{
		onlyCash[client] = false;
		return;
	}
	
	if(!IsClientInGame(client))
	{
		onlyCash[client] = false;
		return;
	}
	
	if((save_scores_tracking_time * 60 < (GetTime() - SQL_FetchInt(hndl,4))) && save_scores_tracking_time != 0 && !onlyCash[client])
	{
		if(!save_scores_forever)
		{
			RemoveScoreFromDB(client);
			return;
		}
	}

	int score = SQL_FetchInt(hndl,1);
	int deaths = SQL_FetchInt(hndl,2);
	
	if(save_scores && !onlyCash[client])
	{
		if(score != 0 || deaths != 0)
		{
			SetScore(client, score);
			SetDeaths(client, deaths);
			CPrintToChat(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {lime}Your {white}old {aqua}score {crimson}has {yellow}been \x03reloaded.");
		}
	}
		
	if(save_scores_css_cash && save_scores)
	{
		int cash = SQL_FetchInt(hndl,3);
		SetCash(client, cash);
		CPrintToChat(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]  {yellow}Cash {lime}restored {white}to {aqua}%d.", cash);
	}
	
	onlyCash[client] = false;	
	if(!save_scores_forever) RemoveScoreFromDB(client);
}


// Removes player's score from DB
public void RemoveScoreFromDB(int client)
{
	char query[200], steamId[30];	
	GetClientAuthId(client, AuthId_Engine, steamId, sizeof(steamId));
	Format(query, sizeof(query), "DELETE FROM savescores_scores WHERE steamId = '%s';", steamId);
	SQL_TQuery(g_hDB, EmptySQLCallback, query);
}

public void EmptySQLCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) LogError("SQL Error: %s", error);
}

public void OnCVarChange(Handle convar_hndl, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

// Getting data from CVars and putting it into plugin's varibles
void GetCVars()
{
	isLAN = GetConVarBool(cvar_lan);
	save_scores = GetConVarBool(cvar_save_scores);
	save_scores_tracking_time = GetConVarInt(cvar_save_scores_tracking_time);
	save_scores_forever = GetConVarBool(cvar_save_scores_forever);
	save_scores_allow_reset = GetConVarBool(cvar_save_scores_allow_reset);	
	save_scores_css_cash = GetConVarBool(cvar_save_scores_css_cash);
	save_scores_css_spec_cash = GetConVarBool(cvar_save_scores_css_spec_cash);
	g_CSDefaultCash = GetConVarInt(cvar_startmoney);
}

public void SetDeaths(int client, int deaths)
{
	SetEntProp(client, Prop_Data, "m_iDeaths", deaths, 4, 0);
}
public Action CommandResetPlayer(int client, int args)
{                           
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	if (args != 1)
	{
		CReplyToCommand(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] \x03sm_resetplayer {yellow}<name or #userid>");
		return Plugin_Continue;
	}
 	
	char target_name[MAX_TARGET_LENGTH];
	char nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}
	for (int i = 0; i < target_count; i++)
	{
		ResetScore(client, target_list[i]);
	}
	CShowActivity2(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {lime}Reset {yellow}score {aqua}of \x03%s.", target_name);
	return Plugin_Continue;
}

public Action CommandSetScore(int client, int args)
{                           
  	char arg1[32], arg2[20], arg3[20],arg4[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	int kills = StringToInt(arg2);
	int deaths = StringToInt(arg3);
	int stars = StringToInt(arg4);
      
	if (args != 4)
	{
		CReplyToCommand(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] sm_setscore {lime}<name or #userid> <Kills> <Deaths><Stars>");
		return Plugin_Continue;
	}
 	
	char target_name[MAX_TARGET_LENGTH];
	char nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}

  	for (int i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Data, "m_iFrags", kills);
		SetEntProp(target_list[i], Prop_Data, "m_iDeaths", deaths);
		CS_SetMVPCount(target_list[i], stars);
	}
	
	CShowActivity2(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]set score of %s.", target_name);
	return Plugin_Continue;
}

public Action CommandSetScoreCSGO(int client, int args)
{                           
  	if (args != 6)
	{
		CReplyToCommand(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] sm_setscore {aqua}<name or #userid> <Kills> <Deaths><Assists><Stars><Points>");
		return Plugin_Continue;
	}
	
	char arg1[32], arg2[20], arg3[20], arg4[20], arg5[20], arg6[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	GetCmdArg(5, arg5, sizeof(arg5));
	GetCmdArg(6, arg6, sizeof(arg6));
	int kills = StringToInt(arg2);
	int deaths = StringToInt(arg3);
	int assists = StringToInt(arg4);
	int stars = StringToInt(arg5);
	int points = StringToInt(arg6);
 	
	char target_name[MAX_TARGET_LENGTH];
	char nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}

  	for (int i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Data, "m_iFrags", kills);
		SetEntProp(target_list[i], Prop_Data, "m_iDeaths", deaths);
		CS_SetClientAssists(target_list[i], assists);
		CS_SetMVPCount(target_list[i], stars);
		CS_SetClientContributionScore(target_list[i], points);
	}
	
	CShowActivity2(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {yellow}set {lime}score {white}of \x03%s.", target_name);
	return Plugin_Continue;
}

public Action CommandSetPoints(int client, int args)
{                           
	char arg1[32], arg2[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int points = StringToInt(arg2);
		
	if (args != 2)
	{
		CReplyToCommand(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03]\x03 sm_setpoints {aqua}<name or #userid> <points>");
		return Plugin_Continue;
	}

	char target_name[MAX_TARGET_LENGTH];
	char nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;

	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}

	for (int i = 0; i < target_count; i++)
	{   
		CS_SetClientContributionScore(target_list[i], points);
	}

	CShowActivity2(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {lime}set {yellow}points {aqua}of %s to %d.", target_name, points);
	return Plugin_Continue;
}

public Action CommandSetAssists(int client, int args)
{                           
	char arg1[32], arg2[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int assists = StringToInt(arg2);
		
	if (args != 2)
	{
		CReplyToCommand(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] sm_setassists {crimson}<name or #userid> <assists>");
		return Plugin_Continue;
	}

	char target_name[MAX_TARGET_LENGTH];
	char nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;

	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}

	for (int i = 0; i < target_count; i++)
	{   
		CS_SetClientAssists(target_list[i], assists);
	}

	CShowActivity2(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {crimson}set Pwhiteassists {yellow}of %s to %d.", target_name, assists);
	return Plugin_Continue;
}

public Action CommandSetStars(int client, int args)
{                           
	char arg1[32], arg2[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int stars = StringToInt(arg2);

	if (args != 2)
	{
		CReplyToCommand(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] sm_setstars {white}<name or #userid> <stars>");
		return Plugin_Continue;
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;

	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}

	for (int i = 0; i < target_count; i++)
	{
		CS_SetMVPCount(target_list[i], stars);
	}

	CShowActivity2(client, "\x03[{lime}>{white}R{crimson}e{yellow}s{aqua}e{lime}t\x03S{aqua}c{yellow}o{crimson}r{white}e{lime}<\x03] {lime}set {yellow}stars {crimson}of {white}%s to %d.", target_name, stars);
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}