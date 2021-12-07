#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <cstrike>
#include <basecomm>
#include <timer>
#include <timer-logging>
#include <timer-rankings>
#include <clientprefs>
#include <timer-config_loader.sp>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig

#undef REQUIRE_PLUGIN
#include <timer-maptier>
#include <timer-physics>
#include <timer-worldrecord>

//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Defines
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//- States for plugin commands.
#define cChatCookie			0
#define cChatTop			1
#define cChatRank			2
#define cChatView			3
#define cChatNext			5
//- States for displaying data.
#define cDisplayNone		0
#define cDisplayScoreTag	1
#define cDisplayChatTag		2
#define cDisplayChatColor	4
#define cDisplayScoreStars	8
//- Cooldown for global messages.
#define cGlobalCooldown		60
//- States for debugging mode.
#define cPrintRanks			1
#define cPrintMaps			2
#define cPrintPlayers		4
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Handles
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:g_hDisplayMethod = INVALID_HANDLE;
new Handle:g_hRequiredPoints = INVALID_HANDLE;
new Handle:g_hGlobalMessage = INVALID_HANDLE;
new Handle:g_hPositionMethod = INVALID_HANDLE;
new Handle:g_hLimitTopPlayers = INVALID_HANDLE;
new Handle:g_hAdvertisement = INVALID_HANDLE;
new Handle:g_hDisplayCookie = INVALID_HANDLE;
new Handle:g_hTrie_CfgCommands = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayTag = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayInfo = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayStars = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayChat = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayColor = INVALID_HANDLE;
new Handle:g_hArray_CfgPoints = INVALID_HANDLE;
new Handle:g_hArray_CfgRanks = INVALID_HANDLE;
new Handle:g_hArray_Positions = INVALID_HANDLE;
new Handle:g_hSettingsMenu = INVALID_HANDLE;
new Handle:g_hLimitTopPerPage = INVALID_HANDLE;
new Handle:g_hConnectTopOnly = INVALID_HANDLE;
new Handle:g_hKickMsg = INVALID_HANDLE;
new Handle:g_hKickDelay = INVALID_HANDLE;
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Variables
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new bool:g_bLateLoad;
new bool:g_bLateQuery;
new bool:g_bSql;
new bool:g_bInitalizing;
new bool:g_bGlobalMessage;
new bool:g_bSettingsMenu;
new g_iConnectTopOnly;
new g_iEnabled;
new g_iTotalRanks;
new g_iTotalPlayers;
new g_iHighestRank;
new g_iDisplayMethod;
new g_iRequiredPoints;
new g_iPositionMethod;
new g_iLimitTopPlayers;
new g_iDebugIndex = 1;
new g_iCurrentDebug = -1;
new g_iLimitTopPerPage;
new Float:g_fAdvertisement;
new String:g_sLoadingScoreTag[1024];
new String:g_sLoadingChatTag[1024];
new String:g_sLoadingChatColor[1024];
new String:g_sCurrentMap[PLATFORM_MAX_PATH];
new String:g_sPluginLog[PLATFORM_MAX_PATH];
new String:g_sDumpLog[PLATFORM_MAX_PATH];
new String:g_sKickMsg[512];
new Float:g_fKickDelay;
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Client Data
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new g_iCompletions[MAXPLAYERS + 1];
new g_iCurrentIndex[MAXPLAYERS + 1] = { -1, ... };
new g_iCurrentPoints[MAXPLAYERS + 1];
new g_iCurrentRank[MAXPLAYERS + 1];
new g_iNextIndex[MAXPLAYERS + 1] = { -1, ... };
new g_iLastGlobalMessage[MAXPLAYERS + 1];
new String:g_sAuth[MAXPLAYERS + 1][24];
new bool:g_bLoadedSQL[MAXPLAYERS + 1];
new bool:g_bAuthed[MAXPLAYERS + 1];
new g_iClientDisplay[MAXPLAYERS + 1];
new bool:g_bLoadedCookies[MAXPLAYERS + 1];
new bool:g_bShowConnectMsg[MAXPLAYERS + 1] = {false, ...};
new Float:g_fKickTime[MAXPLAYERS + 1];

//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Forwards
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new Handle:g_timerGainPointsForward;
new Handle:g_timerLostPointsForward;
new Handle:g_timerSetPointsForward;
new Handle:g_timerPointsLoadedForward;
new Handle:g_timerRankLoadedForward;



//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Session Statss
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new Handle:g_hSession = INVALID_HANDLE;

new String:g_sName[MAXPLAYERS + 1][32];
new bool:g_bCheck[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name        = "[Timer] Rankings",
	author      = "Panduh (AlliedMods: thetwistedpanda), Zipcore",
	description = "[Timer] An advanced ranking component providing competitive ranking",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = g_bLateQuery = late;
	RegPluginLibrary("timer-rankings");
	
	CreateNative("Timer_GetPoints", Native_GetPoints);
	CreateNative("Timer_GetPointRank", Native_GetPointRank);
	CreateNative("Timer_SetPoints", Native_SetPoints);
	CreateNative("Timer_AddPoints", Native_AddPoints);
	CreateNative("Timer_RemovePoints", Native_RemovePoints);
	CreateNative("Timer_SavePoints", Native_SavePoints);
	CreateNative("Timer_RefreshPoints", Native_RefreshPoints);
	CreateNative("Timer_RefreshPointsAll", Native_RefreshPointsAll);

	return APLRes_Success;
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("timer/timer-rankings");

	LoadPhysics();
	LoadTimerSettings();
	
	LoadTranslations("common.phrases");
	LoadTranslations("timer-rankings.phrases");
	AutoExecConfig_CreateConVar("timer_ranks_version", PL_VERSION, "[Timer] Rankings: Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = AutoExecConfig_CreateConVar("timer_ranks_enabled", "1", "Determines operating mode of the plugin. (0 = Disabled, 1 = Enabled, 2 = Debug)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_iEnabled = GetConVarInt(g_hEnabled);

	g_hDisplayMethod = AutoExecConfig_CreateConVar("timer_ranks_display_method", "15", "Determines what information is displayed by clients. Negative / Positives cannot be combined. Positives will force the feature, negatives will allow clients to toggle it on/off. Values that are left off will be ignored by the plugin. (-1/1 = Scoreboard Tag, -2/2 = Chat Tag, -4/4 = Text Color, -8/8 = Scoreboard Stars)", FCVAR_NONE, true, -15.0, true, 15.0);
	HookConVarChange(g_hDisplayMethod, OnCVarChange);
	g_iDisplayMethod = GetConVarInt(g_hDisplayMethod);

	g_hRequiredPoints = AutoExecConfig_CreateConVar("timer_ranks_minimum_points", "20", "Optional requirement that determines the minimum number of points a client must possess to be in any rankings.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hRequiredPoints, OnCVarChange);
	g_iRequiredPoints = GetConVarInt(g_hRequiredPoints);

	g_hGlobalMessage = AutoExecConfig_CreateConVar("timer_ranks_global_messages", "0", "If enabled, a message will be sent to all players when a client checks their rank, otherwise only the issuing client will receive the message.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hGlobalMessage, OnCVarChange);
	g_bGlobalMessage = GetConVarBool(g_hGlobalMessage);

	g_hPositionMethod = AutoExecConfig_CreateConVar("timer_ranks_position_method", "1", "Determines what method will be used to determine rank positions in-game. (0 = Based on clients' total number of points, 1 = Based on the clients' current rank within the server)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hPositionMethod, OnCVarChange);
	g_iPositionMethod = GetConVarInt(g_hPositionMethod);

	g_hLimitTopPlayers = AutoExecConfig_CreateConVar("timer_ranks_limit_top_players", "10", "The maximum number of players to be pulled for the Top Players command.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hLimitTopPlayers, OnCVarChange);
	g_iLimitTopPlayers = GetConVarInt(g_hLimitTopPlayers);
	
	g_hAdvertisement = AutoExecConfig_CreateConVar("timer_ranks_adverts", "0.0", "Optional feature that prints the translation phrase `Advertisement` every x.x seconds. (0.0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hAdvertisement, OnCVarChange);
	g_fAdvertisement = GetConVarFloat(g_hAdvertisement);
	
	g_hLimitTopPerPage = AutoExecConfig_CreateConVar("timer_ranks_limit_top_page", "5", "The maximum number of entries to show per page for the Top Players command. (0 = Default)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hLimitTopPerPage, OnCVarChange);
	g_iLimitTopPerPage = GetConVarInt(g_hLimitTopPerPage);
	
	g_hSettingsMenu = AutoExecConfig_CreateConVar("timer_ranks_settings_menu", "1", "If enabled, the plugin will receive it's own entry in the !settings with shortcuts to all commands. Restart required to disable.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSettingsMenu, OnCVarChange);
	g_bSettingsMenu = GetConVarBool(g_hSettingsMenu);
	
	g_hConnectTopOnly = AutoExecConfig_CreateConVar("timer_ranks_connect_top_only", "0", "If enabled, the plugin will only allow top X players to connect, others will be kicked.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hConnectTopOnly, OnCVarChange);
	g_iConnectTopOnly = GetConVarInt(g_hConnectTopOnly);

	g_hKickDelay = AutoExecConfig_CreateConVar("timer_ranks_kick_delay", "0.0", "Time to wait before player will be kicked.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hKickDelay, OnCVarChange);
	g_fKickDelay = GetConVarFloat(g_hKickDelay);

	g_hKickMsg = AutoExecConfig_CreateConVar("timer_ranks_kick_msg", "Sry, you have to be at least rank {rank} on our other server to play on this server!", "Message to display before player will be kicked. Use {rank} to display needed rank.", FCVAR_NONE);
	HookConVarChange(g_hKickMsg, OnCVarChange);
	GetConVarString(g_hKickMsg, g_sKickMsg, sizeof(g_sKickMsg));
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if(!SQL_CheckConfig("timer"))
	{
		SetFailState("[Timer] Ranking Stopped - There is no 'timer' entry within databases.cfg!");
	}

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	RegAdminCmd("timer_setrankpoints", Command_SetRankPoints, ADMFLAG_CHEATS, "Usage: timer_setrankpoints <steam> <amount> | <steam> must exist otherwise the operation fails.");
	RegAdminCmd("timer_changerankpoints", Command_ChangeRankPoints, ADMFLAG_CHEATS, "Usage: timer_changerankpoints <steam> <amount> | <steam> must exist otherwise the operation fails. | Positive to add, Negative to subtract.");
	RegAdminCmd("timer_listranks", Command_ListRanks, ADMFLAG_KICK, "Queries the database for all ranking information and displays it to server console or issuing admin.");
	
	RegConsoleCmd("sm_session", Cmd_Session, "Session stats about player");
	g_hSession = CreateKeyValues("data");
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_team", Event_OnPlayerTeam);

	HookEvent("player_connect", event_connect, EventHookMode_Pre);
	HookEvent("player_disconnect", event_disconnect, EventHookMode_Pre);

	g_timerGainPointsForward = CreateGlobalForward("OnPlayerGainPoints", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_timerLostPointsForward = CreateGlobalForward("OnPlayerLostPoints", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_timerSetPointsForward = CreateGlobalForward("OnPlayerSetPoints", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_timerPointsLoadedForward = CreateGlobalForward("OnPlayerPointsLoaded", ET_Event, Param_Cell, Param_Cell);
	g_timerRankLoadedForward = CreateGlobalForward("OnPlayerRankLoaded", ET_Event, Param_Cell, Param_Cell);
	
	if(g_iDisplayMethod < 0)
	{
		g_hDisplayCookie = RegClientCookie("Timer-Ranks-Display", "Determines the display method for [Timer] Ranks.", CookieAccess_Private);
	}

	if(g_bSettingsMenu)
	{
		decl String:sFormat[64];
		FormatEx(sFormat, sizeof(sFormat), "%T", "Menu_Core_Title", LANG_SERVER);
		SetCookieMenuItem(Menu_Settings, 0, sFormat);
	}

	BuildPath(Path_SM, g_sPluginLog, sizeof(g_sPluginLog), "logs/timer-rankings.debug.log");
	BuildPath(Path_SM, g_sDumpLog, sizeof(g_sDumpLog), "logs/timer-rankings.dump.log");
	RegServerCmd("timer_rankingsdump", Command_PrintRanks, "Generates a dump file in /logs/ that contains all definitions and rankings.");
}

public Menu_Settings(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			FormatEx(buffer, maxlen, "%t", "Menu_Core_Title", client);
		case CookieMenuAction_SelectOption:
			CreateSettingsMenu(client);
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_iEnabled = StringToInt(newvalue);
	}
	else if(cvar == g_hDisplayMethod)
	{
		g_iDisplayMethod = StringToInt(newvalue);

		if(g_iDisplayMethod < 0 && g_hDisplayCookie == INVALID_HANDLE)
		{
			g_hDisplayCookie = RegClientCookie("Timer-Ranks-Display", "Determines the display method for [Timer] Ranks.", CookieAccess_Private);
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && g_bAuthed[i] && !g_bLoadedCookies[i] && AreClientCookiesCached(i))
				{
					LoadClientData(i);
				}
			}
		}
	}
	else if(cvar == g_hRequiredPoints)
	{
		g_iRequiredPoints = StringToInt(newvalue);
	}
	else if(cvar == g_hGlobalMessage)
	{
		g_bGlobalMessage = bool:StringToInt(newvalue);
	}
	else if(cvar == g_hPositionMethod)
	{
		g_iPositionMethod = StringToInt(newvalue);
	}
	else if(cvar == g_hLimitTopPlayers)
	{
		g_iLimitTopPlayers = StringToInt(newvalue);
	}
	else if(cvar == g_hAdvertisement)
	{
		g_fAdvertisement = StringToFloat(newvalue);
	}
	else if(cvar == g_hLimitTopPerPage)
	{
		g_iLimitTopPerPage = StringToInt(newvalue);
	}
	else if(cvar == g_hSettingsMenu)
	{
		g_bSettingsMenu = bool:StringToInt(newvalue);
	}
	else if(cvar == g_hConnectTopOnly)
	{
		g_iConnectTopOnly = StringToInt(newvalue);
	}
	else if(cvar == g_hKickDelay)
	{
		g_fKickDelay = StringToFloat(newvalue);
	}
	else if(cvar == g_hKickMsg)
	{
		FormatEx(g_sKickMsg, sizeof(g_sKickMsg), "%s", newvalue);
	}
}

public OnConfigsExecuted()
{
	if(!g_iEnabled)
		return;

	Parse_Points();

	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				g_bAuthed[i] = GetClientAuthString(i, g_sAuth[i], sizeof(g_sAuth[]));
				if(!g_bAuthed[i])
					CreateTimer(2.0, Timer_AuthClient, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				else
				{
					g_sAuth[i][6] = '0';
					if(!g_bLoadedCookies[i] && AreClientCookiesCached(i))
						LoadClientData(i);
				}
			}
		}

		GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
		g_bLateLoad = false;
	}

	if(g_hDatabase == INVALID_HANDLE)
		SQL_TConnect(SQL_Connect_Database, "timer");
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	if(!g_iEnabled)
		return;

	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));

	if(g_fAdvertisement > 0.0)
		CreateTimer(g_fAdvertisement, Timer_Advertisement, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	if(!g_iEnabled)
		return;

	g_sCurrentMap[0] = '\0';
}

public Action:Timer_Advertisement(Handle:timer)
{
	if(!g_iEnabled)
		return Plugin_Continue;

	CPrintToChatAll(PLUGIN_PREFIX, "Advertisement");

	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	if(!g_iEnabled || IsFakeClient(client))
		return;

	g_bShowConnectMsg[client] = true;
	g_bCheck[client] = true;
	
	g_bAuthed[client] = GetClientAuthString(client, g_sAuth[client], sizeof(g_sAuth[]));
	if(!g_bAuthed[client])
		CreateTimer(2.0, Timer_AuthClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	else if(g_hDatabase != INVALID_HANDLE && !g_bInitalizing)
	{
		GetClientName(client, g_sName[client], sizeof(g_sName[]));
		g_sAuth[client][6] = '0';
		if(!g_bLoadedSQL[client])
		{
			decl String:sQuery[192];
			FormatEx(sQuery, sizeof(sQuery), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", g_sAuth[client]);
			if(g_iEnabled == 2)
				PrintToDebug("OnClientPostAdminCheck(%N): Issuing Query `%s`", client, sQuery);
			SQL_TQuery(g_hDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(client), DBPrio_Low);
		}

		if(!g_bLoadedCookies[client] && AreClientCookiesCached(client))
			LoadClientData(client);
	}
}

public OnClientCookiesCached(client)
{
	if(!g_iEnabled || IsFakeClient(client))
		return;

	if(!g_bLoadedCookies[client])
		LoadClientData(client);
}

LoadClientData(client)
{
	if(g_hDisplayCookie == INVALID_HANDLE)
		return;

	new String:sCookie[3] = "";
	GetClientCookie(client, g_hDisplayCookie, sCookie, sizeof(sCookie));

	if(StrEqual(sCookie, "", false))
	{
		new iDisplayMethod = (g_iDisplayMethod * -1);
		decl String:sBuffer[3];
		IntToString(iDisplayMethod, sBuffer, sizeof(sBuffer));
		SetClientCookie(client, g_hDisplayCookie, sBuffer);

		g_iClientDisplay[client] = iDisplayMethod;
	}
	else
	{
		g_iClientDisplay[client] = StringToInt(sCookie);
	}

	g_bLoadedCookies[client] = true;
}

public OnClientDisconnect(client)
{
	if(!g_iEnabled)
		return;

	g_sAuth[client][0] = '\0';
	
	if(g_bAuthed[client] && KvJumpToKey(g_hSession, g_sAuth[client], false) && g_iCurrentIndex[client] >= 0)
	{
		new points_start = KvGetNum(g_hSession, "points", 0);
		new points = Timer_GetPoints(client);
		KvSetFloat(g_hSession, "disconnec_time", GetEngineTime());
		
		new String:sPre[3];
		if(points-points_start >= 0)
			Format(sPre, sizeof(sPre), "+");
		
		decl String:sNameBuffer[1024];
		GetArrayString(g_hCfgArray_DisplayChat, g_iCurrentIndex[client], sNameBuffer, sizeof(sNameBuffer));
		
		#if defined LEGACY_COLORS
		CFormat(sNameBuffer, 1024, client);
		CPrintToChatAll("%s{lightred}%s {olive}disconnected with {lightred}%d {olive}points {lightred}(%s%d).", sNameBuffer, g_sName[client], points, sPre, points-points_start);
		#else
		CReplaceColorCodes(sNameBuffer, client, false, 1024);
		CPrintToChatAll("%s{red}%s {green}disconnected with {yellow}%d {green}points {yellow}(%s%d).", sNameBuffer, g_sName[client], points, sPre, points-points_start);
		#endif
	}
	KvRewind(g_hSession);

	g_bAuthed[client] = false;
	g_bLoadedSQL[client] = false;
	g_bLoadedCookies[client] = false;

	g_iNextIndex[client] = -1;
	g_iCurrentIndex[client] = -1;
	g_iCompletions[client] = 0;
	g_iCurrentPoints[client] = 0;
	g_iLastGlobalMessage[client] = 0;
	g_iClientDisplay[client] = 0;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

public Action:Command_Say(client, const String:command[], argc)
{
	if(!g_iEnabled || !client || g_bInitalizing)
		return Plugin_Continue;

	decl String:sText[192], String:sBuffer[24];
	GetCmdArgString(sText, sizeof(sText));

	new iIndex, iStart;
	if(sText[strlen(sText) - 1] == '"')
	{
		sText[strlen(sText) - 1] = '\0';
		iStart = 1;
	}

	BreakString(sText[iStart], sBuffer, sizeof(sBuffer));
	if(GetTrieValue(g_hTrie_CfgCommands, sBuffer, iIndex))
	{
		switch(iIndex)
		{
			case cChatCookie:
			{
				if(g_iDisplayMethod >= 0 || g_hDisplayCookie == INVALID_HANDLE || g_iCurrentIndex[client] == -1)
					return Plugin_Continue;

				if(!g_bLoadedSQL[client] || !g_bLoadedCookies[client])
				{
					CPrintToChat(client, PLUGIN_PREFIX, "Phrase.Loading");
					return Plugin_Handled;
				}

				CreateCookieMenu(client);
			}
			case cChatTop:
			{
				FormatEx(sText, sizeof(sText), "SELECT `lastname`,`points` FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC LIMIT %d", g_iRequiredPoints, g_iLimitTopPlayers);
				if(g_iEnabled == 2)
					PrintToDebug("Command_Say(%N): Issuing Query `%s`", client, sText);
				SQL_TQuery(g_hDatabase, CallBack_Top, sText, GetClientUserId(client));
			}
			case cChatRank:
			{
				if(!g_bLoadedSQL[client])
				{
					CPrintToChat(client, PLUGIN_PREFIX, "Phrase_Loading");
					return Plugin_Handled;
				}

				if(g_iCurrentPoints[client] < g_iRequiredPoints)
					CPrintToChat(client, PLUGIN_PREFIX, "Phrase_Rank_Not_Enough", g_iRequiredPoints, g_iCurrentPoints[client]);
				else
				{
					FormatEx(sText, sizeof(sText), "SELECT COUNT(*) FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC", g_iCurrentPoints[client]);
					if(g_iEnabled == 2)
						PrintToDebug("Command_Say(%N): Issuing Query `%s`", client, sText);
					SQL_TQuery(g_hDatabase, CallBack_Rank, sText, GetClientUserId(client));
				}
			}
			case cChatView:
			{
				if(g_iDisplayMethod != 0)
					CreateInfoMenu(client);
				else
					return Plugin_Continue;
			}
			case cChatNext:
			{
				if(!g_bLoadedSQL[client])
				{
					CPrintToChat(client, PLUGIN_PREFIX, "Phrase_Loading");
					return Plugin_Handled;
				}

				FormatEx(sText, sizeof(sText), "SELECT `lastname`,`points` FROM `ranks` WHERE `points` >= %d AND `auth` != '%s' ORDER BY `points` ASC LIMIT %d", g_iCurrentPoints[client], g_sAuth[client], g_iLimitTopPlayers);
				if(g_iEnabled == 2)
					PrintToDebug("Command_Say(%N): Issuing Query `%s`", client, sText);
				SQL_TQuery(g_hDatabase, CallBack_Next, sText, GetClientUserId(client));
			}
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

CreateCookieMenu(client)
{
	decl String:sBuffer[128];
	new Handle:hMenu = CreateMenu(MenuHandler_CookieMenu);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Cookie", client);
	SetMenuTitle(hMenu, sBuffer);

	decl String:sSelected[8], String:sUnselected[8];
	FormatEx(sSelected, sizeof(sSelected), "%T", "Menu_Option_Selected", client);
	FormatEx(sUnselected, sizeof(sUnselected), "%T", "Menu_Option_Empty", client);

	new iDisplayMethod = (g_iDisplayMethod * -1);
	if(iDisplayMethod & cDisplayScoreTag)
	{
		GetArrayString(g_hCfgArray_DisplayTag, g_iCurrentIndex[client], sBuffer, sizeof(sBuffer));
		if(!StrEqual(sBuffer, ""))
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayScoreTag) ? sSelected : sUnselected, "Menu_Cookie_Option_Tag", client);
		else
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayScoreTag) ? sSelected : sUnselected, "Menu_Cookie_Option_Tag_Default", client);
		AddMenuItem(hMenu, "1", sBuffer);
	}

	if(iDisplayMethod & cDisplayChatTag)
	{
		GetArrayString(g_hCfgArray_DisplayChat, g_iCurrentIndex[client], sBuffer, sizeof(sBuffer));
		if(!StrEqual(sBuffer, ""))
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayChatTag) ? sSelected : sUnselected, "Menu_Cookie_Option_Chat", client);
		else
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayChatTag) ? sSelected : sUnselected, "Menu_Cookie_Option_Chat_Default", client);
		AddMenuItem(hMenu, "2", sBuffer);
	}

	if(iDisplayMethod & cDisplayChatColor)
	{
		GetArrayString(g_hCfgArray_DisplayColor, g_iCurrentIndex[client], sBuffer, sizeof(sBuffer));
		if(!StrEqual(sBuffer, ""))
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayChatColor) ? sSelected : sUnselected, "Menu_Cookie_Option_Text", client);
		else
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayChatColor) ? sSelected : sUnselected, "Menu_Cookie_Option_Text_Default", client);
		AddMenuItem(hMenu, "4", sBuffer);
	}

	if(iDisplayMethod & cDisplayScoreStars)
	{
		if(GetArrayCell(g_hCfgArray_DisplayStars, g_iCurrentIndex[client]))
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayScoreStars) ? sSelected : sUnselected, "Menu_Cookie_Option_Stars", client);
		else
			FormatEx(sBuffer, sizeof(sBuffer), "%s%T", (g_iClientDisplay[client] & cDisplayScoreStars) ? sSelected : sUnselected, "Menu_Cookie_Option_Stars_Default", client);
		AddMenuItem(hMenu, "8", sBuffer);
	}

	DisplayMenu(hMenu, client, 30);
}

public MenuHandler_CookieMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:sOption[4];
			GetMenuItem(menu, param2, sOption, 4);

			switch(StringToInt(sOption))
			{
				case cDisplayScoreTag:
				{
					decl String:sBuffer[20], String:sTemp[20];
					GetArrayString(g_hCfgArray_DisplayTag, g_iCurrentIndex[param1], sBuffer, sizeof(sBuffer));

					if(g_iClientDisplay[param1] & cDisplayScoreTag)
					{
						g_iClientDisplay[param1] &= ~cDisplayScoreTag;

						CS_GetClientClanTag(param1, sTemp, sizeof(sTemp));
						if(StrEqual(sTemp, sBuffer))
							CS_SetClientClanTag(param1, "");
					}
					else
					{
						g_iClientDisplay[param1] |= cDisplayScoreTag;

						CS_GetClientClanTag(param1, sTemp, sizeof(sTemp));
						if(!StrEqual(sTemp, sBuffer))
							CS_SetClientClanTag(param1, sBuffer);
					}
				}
				case cDisplayChatTag:
				{
					if(g_iClientDisplay[param1] & cDisplayChatTag)
					{
						g_iClientDisplay[param1] &= ~cDisplayChatTag;
					}
					else
					{
						g_iClientDisplay[param1] |= cDisplayChatTag;
					}
				}
				case cDisplayChatColor:
				{
					if(g_iClientDisplay[param1] & cDisplayChatColor)
					{
						g_iClientDisplay[param1] &= ~cDisplayChatColor;
					}
					else
					{
						g_iClientDisplay[param1] |= cDisplayChatColor;
					}
				}
				case cDisplayScoreStars:
				{
					if(g_iClientDisplay[param1] & cDisplayScoreStars)
					{
						g_iClientDisplay[param1] &= ~cDisplayScoreStars;
					}
					else
					{
						g_iClientDisplay[param1] |= cDisplayScoreStars;
					}
				}
			}

			decl String:sBuffer[3];
			IntToString(g_iClientDisplay[param1], sBuffer, sizeof(sBuffer));
			SetClientCookie(param1, g_hDisplayCookie, sBuffer);

			CreateCookieMenu(param1);
		}
	}
}

CreateInfoMenu(client, item = 0)
{
	if(g_iTotalRanks < 0)
		return;

	decl String:sBuffer[128], String:sTemp[4];
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Info", client);

	new Handle:hMenu = CreateMenu(MenuHandler_InfoMenu);
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	new iHideNegative;
	if(g_iPositionMethod)
		iHideNegative = FindValueInArray(g_hArray_Positions, -1);
	else
		iHideNegative = FindValueInArray(g_hArray_CfgPoints, -1);

	for(new i = 0; i <= g_iTotalRanks; i++)
	{
		if(i == iHideNegative)
			continue;

		GetArrayString(g_hCfgArray_DisplayInfo, i, sBuffer, sizeof(sBuffer));
		IntToString(i, sTemp, sizeof(sTemp));
		AddMenuItem(hMenu, sTemp, sBuffer);
	}

	DisplayMenuAtItem(hMenu, client, item, 30);
}

public MenuHandler_InfoMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:sOption[4], String:sInfo[64];
			GetMenuItem(menu, param2, sOption, 4);
			new iIndex = StringToInt(sOption);

			GetArrayString(g_hCfgArray_DisplayInfo, iIndex, sInfo, sizeof(sInfo));

			new iEnd, iStart, iPoints;
			if(g_iPositionMethod)
			{
				new iPreviousIndex = (iIndex - 1);
				if(iPreviousIndex < 0)
					iStart = 1;
				else
				{
					iStart = GetArrayCell(g_hArray_CfgRanks, iPreviousIndex);
					if(iStart == -1)
						iStart = 1;
					else
						iStart++;
				}

				iEnd = GetArrayCell(g_hArray_CfgRanks, iIndex);
				CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Rank", iStart, iEnd, sInfo);
			}
			else
			{
				iPoints = GetArrayCell(g_hArray_CfgPoints, iIndex);
				CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Points", iPoints, sInfo);
			}

			if(g_iDisplayMethod > 0)
			{
				decl String:sTag[1024], String:sChat[1024], String:sText[1024];
				GetArrayString(g_hCfgArray_DisplayTag, iIndex, sTag, sizeof(sTag));
				GetArrayString(g_hCfgArray_DisplayChat, iIndex, sChat, sizeof(sChat));
				GetArrayString(g_hCfgArray_DisplayColor, iIndex, sText, sizeof(sText));
				#if defined LEGACY_COLORS
				CFormat(sChat, sizeof(sChat), param1);
				CFormat(sText, sizeof(sText), param1);
				#else
				CReplaceColorCodes(sChat, param1, false, 1024);
				CReplaceColorCodes(sText, param1, false, 1024);
				#endif

				if(g_iDisplayMethod & cDisplayScoreTag && !StrEqual(sTag, ""))
					CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Tag", sTag);
				if(g_iDisplayMethod & cDisplayChatTag && !StrEqual(sChat, ""))
					CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Chat", sChat, param1);
				if(g_iDisplayMethod & cDisplayChatColor && !StrEqual(sText, ""))
					CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Text", sText);
				if(g_iDisplayMethod & cDisplayScoreStars)
				{
					new iStars = GetArrayCell(g_hCfgArray_DisplayStars, iIndex);
					if(iStars)
					{
						CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Stars", iStars);
					}
				}
			}
			else if(g_iDisplayMethod < 0)
			{
				new iDisplayMethod = g_iDisplayMethod * -1;

				decl String:sTag[1024], String:sChat[1024], String:sText[1024];
				GetArrayString(g_hCfgArray_DisplayTag, iIndex, sTag, sizeof(sTag));
				GetArrayString(g_hCfgArray_DisplayChat, iIndex, sChat, sizeof(sChat));
				GetArrayString(g_hCfgArray_DisplayColor, iIndex, sText, sizeof(sText));
				#if defined LEGACY_COLORS
				CFormat(sChat, sizeof(sChat), param1);
				CFormat(sText, sizeof(sText), param1);
				#else
				CReplaceColorCodes(sChat, param1, false, 1024);
				CReplaceColorCodes(sText, param1, false, 1024);
				#endif

				if(iDisplayMethod & cDisplayScoreTag && !StrEqual(sTag, ""))
					CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Tag", sTag);
				if(iDisplayMethod & cDisplayChatTag && !StrEqual(sChat, ""))
					CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Chat", sChat, param1);
				if(iDisplayMethod & cDisplayChatColor && !StrEqual(sText, ""))
					CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Text", sText);
				if(iDisplayMethod & cDisplayScoreStars)
				{
					new iStars = GetArrayCell(g_hCfgArray_DisplayStars, iIndex);
					if(iStars)
					{
						CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Display_Stars", iStars);
					}
				}
			}

			if(!g_iPositionMethod && g_iCurrentPoints[param1] < iPoints)
			{
				iPoints -= g_iCurrentPoints[param1];
				CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Info_Rank_Remaining", iPoints);
			}

			CreateInfoMenu(param1, GetMenuSelectionPosition());
		}
	}
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	if(!g_iEnabled || g_hDatabase == INVALID_HANDLE || !g_bAuthed[author] || !g_iDisplayMethod)
		return Plugin_Continue;

	/*if(author && GetClientTeam(author) <= CS_TEAM_SPECTATOR)
	{
		ClearArray(recipients);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				PushArrayCell(recipients, i);
			}
		}
	}*/
	
	if(g_iDisplayMethod < 0)
	{
		new iDisplay = (g_iDisplayMethod * -1);

		if((g_hDisplayCookie != INVALID_HANDLE && !g_bLoadedCookies[author]) || !g_bLoadedSQL[author])
		{
			if(iDisplay & cDisplayChatTag)
			{
				Format(name, 1024, "%s%s", g_sLoadingChatTag, name);
				#if defined LEGACY_COLORS
				CFormat(name, 1024, author);
				#else
				CReplaceColorCodes(name, author, false, 1024);
				#endif
			}

			if(iDisplay & cDisplayChatColor)
			{
				Format(message, 1024, "%s%s", g_sLoadingChatColor, message);
				#if defined LEGACY_COLORS
				CFormat(message, 1024, author);
				#else
				CReplaceColorCodes(message, author, false, 1024);
				#endif
			}

			return Plugin_Changed;
		}
		else if(g_iCurrentIndex[author] != -1)
		{
			if(iDisplay & cDisplayChatTag && g_iClientDisplay[author] & cDisplayChatTag)
			{
				decl String:sNameBuffer[1024];
				GetArrayString(g_hCfgArray_DisplayChat, g_iCurrentIndex[author], sNameBuffer, sizeof(sNameBuffer));
				Format(name, 1024, "%s%s", sNameBuffer, name);
				#if defined LEGACY_COLORS
				CFormat(name, 1024, author);
				#else
				CReplaceColorCodes(name, author, false, 1024);
				#endif
			}

			if(iDisplay & cDisplayChatColor && g_iClientDisplay[author] & cDisplayChatColor)
			{
				decl String:sTextBuffer[1024];
				GetArrayString(g_hCfgArray_DisplayColor, g_iCurrentIndex[author], sTextBuffer, sizeof(sTextBuffer));
				Format(message, 1024, "%s%s", sTextBuffer, message);
				#if defined LEGACY_COLORS
				CFormat(message, 1024, author);
				#else
				CReplaceColorCodes(message, author, false, 1024);
				#endif
			}

			return Plugin_Changed;
		}
	}
	else
	{
		if(!g_bLoadedSQL[author])
		{
			if(g_iDisplayMethod & cDisplayChatTag)
			{
				Format(name, 1024, "%s%s", g_sLoadingChatTag, name);
				#if defined LEGACY_COLORS
				CFormat(name, 1024, author);
				#else
				CReplaceColorCodes(name, author, false, 1024);
				#endif
			}

			if(g_iDisplayMethod & cDisplayChatColor)
			{
				Format(message, 1024, "%s%s", g_sLoadingChatColor, message);
				#if defined LEGACY_COLORS
				CFormat(message, 1024, author);
				#else
				CReplaceColorCodes(message, author, false, 1024);
				#endif
			}

			return Plugin_Changed;
		}
		else if(g_iCurrentIndex[author] != -1)
		{
			if(g_iDisplayMethod & cDisplayChatTag)
			{
				decl String:sNameBuffer[1024];
				GetArrayString(g_hCfgArray_DisplayChat, g_iCurrentIndex[author], sNameBuffer, sizeof(sNameBuffer));
				Format(name, 1024, "%s%s", sNameBuffer, name);
				#if defined LEGACY_COLORS
				CFormat(name, 1024, author);
				#else
				CReplaceColorCodes(name, author, false, 1024);
				#endif
			}

			if(g_iDisplayMethod & cDisplayChatColor)
			{
				decl String:sTextBuffer[1024];
				GetArrayString(g_hCfgArray_DisplayColor, g_iCurrentIndex[author], sTextBuffer, sizeof(sTextBuffer));
				Format(message, 1024, "%s%s", sTextBuffer, message);
				#if defined LEGACY_COLORS
				CFormat(message, 1024, author);
				#else
				CReplaceColorCodes(message, author, false, 1024);
				#endif
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_iEnabled)
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR || IsFakeClient(client))
		return Plugin_Continue;

	UpdateClientTag(client);
	UpdateClientStars(client);
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_iEnabled)
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	UpdateClientTag(client);
	UpdateClientStars(client);
	return Plugin_Continue;
}

public OnClientSettingsChanged(client)
{
	if(!g_iEnabled || IsFakeClient(client))
		return;

	if(IsClientInGame(client))
	{
		decl String:sBuffer[20];
		if(GetClientInfo(client, "cl_clanid", sBuffer, sizeof(sBuffer)))
			UpdateClientTag(client);
	}
}

UpdateClientTag(client)
{
	if(!g_iDisplayMethod)
		return;

	if(g_iDisplayMethod < 0)
	{
		new iDisplayMethod = (g_iDisplayMethod * -1);

		if(!g_bLoadedCookies[client] || !g_bLoadedSQL[client])
		{
			CS_SetClientClanTag(client, g_sLoadingScoreTag);
		}
		else if(iDisplayMethod & cDisplayScoreTag && g_iClientDisplay[client] & cDisplayScoreTag && g_iCurrentIndex[client] != -1)
		{
			decl String:sBuffer[20];
			GetArrayString(g_hCfgArray_DisplayTag, g_iCurrentIndex[client], sBuffer, sizeof(sBuffer));
			CS_SetClientClanTag(client, sBuffer);
		}
	}
	else
	{
		if(!g_bLoadedSQL[client])
		{
			CS_SetClientClanTag(client, g_sLoadingScoreTag);
		}
		else if(g_iDisplayMethod & cDisplayScoreTag && g_iCurrentIndex[client] != -1)
		{
			decl String:sBuffer[20];
			GetArrayString(g_hCfgArray_DisplayTag, g_iCurrentIndex[client], sBuffer, sizeof(sBuffer));
			CS_SetClientClanTag(client, sBuffer);
		}
	}
}

UpdateClientStars(client)
{
	if(!g_iDisplayMethod)
		return;

	if(g_iDisplayMethod < 0)
	{
		if(!g_bLoadedCookies[client])
			return;

		new iDisplayMethod = (g_iDisplayMethod * -1);
		if(iDisplayMethod & cDisplayScoreStars && g_iClientDisplay[client] & cDisplayScoreStars && g_iCurrentIndex[client] != -1)
		{
			CS_SetMVPCount(client, GetArrayCell(g_hCfgArray_DisplayStars, g_iCurrentIndex[client]));
		}
	}
	else
	{
		if(!g_bLoadedSQL[client])
			return;

		if(g_iDisplayMethod & cDisplayScoreStars && g_iCurrentIndex[client] != -1)
		{
			CS_SetMVPCount(client, GetArrayCell(g_hCfgArray_DisplayStars, g_iCurrentIndex[client]));
		}
	}
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

public SQL_Connect_Database(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(owner, error, "SQL_Connect_Database.Owner");
	ErrorCheck(hndl, error, "SQL_Connect_Database.Handle");

	g_hDatabase = hndl;
	decl String:sDriver[16];
	SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver));

	g_bSql = StrEqual(sDriver, "mysql", false);
	if(g_bSql)
	{
		SQL_TQuery(g_hDatabase, CallBack_Names, "SET NAMES  'utf8'", _, DBPrio_High);

		SQL_TQuery(g_hDatabase, CallBack_Creation, "CREATE TABLE IF NOT EXISTS `ranks` (`auth` varchar(24) NOT NULL PRIMARY KEY, `points` int(11) NOT NULL default 0, `lastname` varchar(65) NOT NULL default '', `lastplay` int(11) NOT NULL default 0);");

	}
	else
	{
		SQL_TQuery(g_hDatabase, CallBack_Creation, "CREATE TABLE IF NOT EXISTS `ranks` (`auth` varchar(24) NOT NULL PRIMARY KEY, `points` INTEGER NOT NULL default 0, `lastname` varchar(65) NOT NULL default '', `lastplay` INTEGER NOT NULL default 0);");
	}

	SQL_TQuery(g_hDatabase, CallBack_Total, "SELECT COUNT(*) FROM `ranks`", _, DBPrio_Low);
}

public CallBack_Total(Handle:owner, Handle:hndl, const String:error[], any:ref)
{
	ErrorCheck(hndl, error, "CallBack_Total");

	if(SQL_FetchRow(hndl))
	{
		g_iTotalPlayers = SQL_FetchInt(hndl, 0);
	}
}

public CallBack_Names(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(hndl, error, "CallBack_Names");
}

public CallBack_Creation(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(hndl, error, "CallBack_Creation");

	if(g_bLateQuery)
	{
		decl String:sQuery[192];
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !g_bLoadedSQL[i] && g_bAuthed[i] && !IsFakeClient(i))
			{
				FormatEx(sQuery, sizeof(sQuery), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", g_sAuth[i]);
				if(g_iEnabled == 2)
					PrintToDebug("CallBack_Creation(%N): Issuing Query `%s`", i, sQuery);
				SQL_TQuery(g_hDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(i), DBPrio_Low);
			}
		}

		g_bLateQuery = false;
	}
}

public CallBack_MapInsert(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(owner, error, "CallBack_MapInsert");
}

public CallBack_MapUpdate(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(owner, error, "CallBack_MapUpdate");
}

public CallBack_CreateClient(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(owner, error, "CallBack_CreateClient");

	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	g_iCurrentIndex[client] = -1;
	if(g_iPositionMethod)
	{
		decl String:sQuery[192];
		FormatEx(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC", g_iCurrentPoints[client]);
		if(g_iEnabled == 2)
			PrintToDebug("CallBack_CreateClient(%N): Issuing Query `%s`", client, sQuery);
		SQL_TQuery(g_hDatabase, CallBack_LoadRank, sQuery, userid);
	}
	else
	{
		for(new i = 0; i <= g_iTotalRanks; i++)
		{
			new iPoints = GetArrayCell(g_hArray_CfgPoints, i);
			if(iPoints == -1)
				continue;

			if(g_iCurrentPoints[client] >= GetArrayCell(g_hArray_CfgPoints, i))
				g_iCurrentIndex[client] = i;
			else
				break;
		}

		if(g_iCurrentIndex[client] == -1)
		{
			g_iCurrentIndex[client] = FindValueInArray(g_hArray_CfgPoints, -1);
			g_iNextIndex[client] = GetArrayCell(g_hArray_CfgPoints, g_iTotalRanks);
		}
		else
		{
			if(g_iCurrentIndex[client] == g_iTotalRanks)
				g_iNextIndex[client] = -1;
			else
				g_iNextIndex[client] = GetArrayCell(g_hArray_CfgPoints, g_iCurrentIndex[client] + 1);
		}

		g_bLoadedSQL[client] = true;

		UpdateClientTag(client);
		UpdateClientStars(client);
	}
}

public CallBack_UpdateClient(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(hndl, error, "CallBack_UpdateClient");
}

public CallBack_ClientConnect(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(owner, error, "CallBack_ClientConnect");

	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	decl String:sName[MAX_NAME_LENGTH];
	decl String:sSafeName[((MAX_NAME_LENGTH * 2) + 1)];
	GetClientName(client, sName, sizeof(sName));
	SQL_EscapeString(g_hDatabase, sName, sSafeName, sizeof(sSafeName));
	
	decl String:sQuery[256];
	if(!SQL_GetRowCount(hndl))
	{
		g_iCurrentPoints[client] = 0;

		FormatEx(sQuery, sizeof(sQuery), "INSERT INTO `ranks` (auth, points, lastname, lastplay) VALUES ('%s', 0, '%s', %d)", g_sAuth[client], sSafeName, GetTime());
		if(g_iEnabled == 2)
			PrintToDebug("CallBack_ClientConnect(%N): Issuing Query `%s`", client, sQuery);
		SQL_TQuery(g_hDatabase, CallBack_CreateClient, sQuery, userid);

		g_iTotalPlayers++;
		
		ValidatePlayerSlot(client, true);
	}
	else if(SQL_FetchRow(hndl))
	{
		FormatEx(sQuery, sizeof(sQuery), "UPDATE `ranks` SET lastname = '%s', lastplay = %d WHERE auth = '%s'", sSafeName, GetTime(), g_sAuth[client]);
		if(g_iEnabled == 2)
			PrintToDebug("CallBack_ClientConnect(%N): Issuing Query `%s`", client, sQuery);
		SQL_TQuery(g_hDatabase, CallBack_UpdateClient, sQuery, _);

		g_iCurrentPoints[client] = SQL_FetchInt(hndl, 0);

		if(g_iPositionMethod)
		{
			FormatEx(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC", g_iCurrentPoints[client]);
			if(g_iEnabled == 2)
				PrintToDebug("CallBack_ClientConnect(%N): Issuing Query `%s`", client, sQuery);
			SQL_TQuery(g_hDatabase, CallBack_LoadRank, sQuery, userid);
		}
		else
		{
			g_iCurrentIndex[client] = -1;
			for(new i = 0; i <= g_iTotalRanks; i++)
			{
				new iPoints = GetArrayCell(g_hArray_CfgPoints, i);
				if(iPoints == -1)
					continue;

				if(g_iCurrentPoints[client] >= GetArrayCell(g_hArray_CfgPoints, i))
					g_iCurrentIndex[client] = i;
				else
					break;
			}

			if(g_iCurrentIndex[client] == -1)
			{
				g_iCurrentIndex[client] = FindValueInArray(g_hArray_CfgPoints, -1);
				g_iNextIndex[client] = GetArrayCell(g_hArray_CfgPoints, g_iTotalRanks);
			}
			else
			{
				if(g_iCurrentIndex[client] == g_iTotalRanks)
					g_iNextIndex[client] = -1;
				else
					g_iNextIndex[client] = GetArrayCell(g_hArray_CfgPoints, g_iCurrentIndex[client] + 1);
			}

			g_bLoadedSQL[client] = true;

			UpdateClientStars(client);
			UpdateClientTag(client);
		}
	}
	
	if(g_bAuthed[client] && g_bCheck[client])
	{
		if(KvJumpToKey(g_hSession, g_sAuth[client], false))
		{
			new Float:disconnec_time = GetEngineTime()-KvGetFloat(g_hSession, "disconnec_time", 0.0);
			if(disconnec_time > 180.0)
				CreateSession(client, g_iCurrentPoints[client], false);
		}
		else CreateSession(client, g_iCurrentPoints[client], true);
		
		KvRewind(g_hSession);
		
		g_bCheck[client] = false;
	}
		
	Call_StartForward(g_timerPointsLoadedForward);
	Call_PushCell(client);
	Call_PushCell(g_iCurrentPoints[client]);
	Call_Finish();
}

public CallBack_LoadRank(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(hndl, error, "CallBack_LoadRank");
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	new iOutside = FindValueInArray(g_hArray_Positions, -1);
	if(SQL_FetchRow(hndl))
	{
		g_iCurrentRank[client] = SQL_FetchInt(hndl, 0);
		
		if(g_iCurrentRank[client] > g_iHighestRank)
			g_iCurrentIndex[client] = iOutside;
		else
		{
			new iSize = GetArraySize(g_hArray_Positions);
			for(new i = 0; i < iSize; i++)
			{
				if(g_iCurrentRank[client] <= GetArrayCell(g_hArray_Positions, i))
				{
					g_iCurrentIndex[client] = i;
					break;
				}
			}
		}
	}
	else
		g_iCurrentIndex[client] = iOutside;

	g_bLoadedSQL[client] = true;
		
	Call_StartForward(g_timerRankLoadedForward);
	Call_PushCell(client);
	Call_PushCell(g_iCurrentRank[client]);
	Call_Finish();

	UpdateClientStars(client);
	UpdateClientTag(client);
	ValidatePlayerSlot(client);
	ShowConnectMsg(client);
}

ShowConnectMsg(client)
{
	if(g_bLateLoad)
		return;
	
	if(IsFakeClient(client))
		return;
	
	if(!g_bShowConnectMsg[client])
		return;
	
	if(g_iCurrentPoints[client] < 0)
		return;
	
	if(g_iCurrentIndex[client] < 0)
		return;
	
	g_bShowConnectMsg[client] = false;
	
	decl String:sNameBuffer[1024];
	decl String:s_Country[32];
	decl String:s_address[32];		
	GetClientIP(client, s_address, 32);
	Format(s_Country, 100, "Unknown");
	GetArrayString(g_hCfgArray_DisplayChat, g_iCurrentIndex[client], sNameBuffer, sizeof(sNameBuffer));
	
	if(!IsFakeClient(client))
	{
		GeoipCountry(s_address, s_Country, 100);     
		if(!strcmp(s_Country, NULL_STRING))
			Format( s_Country, 100, "The Moon", s_Country );
		else				
			if( StrContains( s_Country, "United", false ) != -1 || 
				StrContains( s_Country, "Republic", false ) != -1 || 
				StrContains( s_Country, "Federation", false ) != -1 || 
				StrContains( s_Country, "Island", false ) != -1 || 
				StrContains( s_Country, "Netherlands", false ) != -1 || 
				StrContains( s_Country, "Isle", false ) != -1 || 
				StrContains( s_Country, "Bahamas", false ) != -1 || 
				StrContains( s_Country, "Maldives", false ) != -1 || 
				StrContains( s_Country, "Philippines", false ) != -1 || 
				StrContains( s_Country, "Vatican", false ) != -1 )
			{
				Format( s_Country, 100, "The %s", s_Country );
			}				
		
	}
	
	#if defined LEGACY_COLORS
	CFormat(sNameBuffer, 1024, client);
	CPrintToChatAll("%s%N {olive}[{lightred}%d points{olive}] connected from %s.", sNameBuffer, client, g_iCurrentPoints[client], s_Country);
	#else
	CReplaceColorCodes(sNameBuffer, client, false, 1024);
	CPrintToChatAll("%s%N {green}[{yellow}%d points{green}] connected from %s.", sNameBuffer, client, g_iCurrentPoints[client], s_Country);
	#endif
}

public CallBack_Top(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(hndl, error, "CallBack_Top");
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	new iIndex, iPoints;
	decl String:sName[32];
	if(SQL_GetRowCount(hndl))
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, iIndex);
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sName, sizeof(sName));
			iPoints = SQL_FetchInt(hndl, 1);

			WritePackString(hPack, sName);
			WritePackCell(hPack, iPoints);

			iIndex++;
		}

		SetPackPosition(hPack, 0);
		WritePackCell(hPack, iIndex);
		CreateTopMenu(client, hPack);
	}
	else
		CPrintToChat(client, PLUGIN_PREFIX, "Phrase_Rank_None");
}

CreateTopMenu(client, Handle:pack)
{
	decl String:sBuffer[128], String:sName[32];
	new Handle:hMenu = CreateMenu(MenuHandler_MenuTopPlayers);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Top", client, g_iLimitTopPlayers);
	SetMenuTitle(hMenu, sBuffer);
	if(g_iLimitTopPerPage)
		SetMenuPagination(hMenu, g_iLimitTopPerPage);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	new iCount = ReadPackCell(pack);
	for(new i = 0; i < iCount; i++)
	{
		ReadPackString(pack, sName, sizeof(sName));
		new iPoints = ReadPackCell(pack);

		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Top_Option", client, sName, iPoints, i + 1);
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	CloseHandle(pack);
	DisplayMenu(hMenu, client, 30);
}

public MenuHandler_MenuTopPlayers(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public CallBack_Next(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(hndl, error, "CallBack_Next");
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	new iIndex, iPoints;
	decl String:sName[32];
	if(SQL_GetRowCount(hndl))
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, iIndex);
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sName, sizeof(sName));
			iPoints = SQL_FetchInt(hndl, 1);

			WritePackString(hPack, sName);
			WritePackCell(hPack, iPoints);

			iIndex++;
		}

		SetPackPosition(hPack, 0);
		WritePackCell(hPack, iIndex);
		CreateNextMenu(client, hPack);
	}
	else
		CPrintToChat(client, PLUGIN_PREFIX, "Phrase_Next_None");
}

CreateNextMenu(client, Handle:pack)
{
	decl String:sBuffer[128], String:sName[32];
	new Handle:hMenu = CreateMenu(MenuHandler_MenuNextPlayers);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Next", client, g_iLimitTopPlayers);
	SetMenuTitle(hMenu, sBuffer);
	if(g_iLimitTopPerPage)
		SetMenuPagination(hMenu, g_iLimitTopPerPage);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	new iCount = ReadPackCell(pack);
	for(new i = 0; i < iCount; i++)
	{
		ReadPackString(pack, sName, sizeof(sName));
		new iPoints = ReadPackCell(pack);

		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Next_Option", client, sName, iPoints, g_iLimitTopPlayers - i);

		if(i == 0)
			AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
		else
			InsertMenuItem(hMenu, 0, "", sBuffer, ITEMDRAW_DISABLED);
	}
	CloseHandle(pack);
	DisplayMenu(hMenu, client, 30);
}

CreateSettingsMenu(client)
{
	decl String:sBuffer[128];
	new Handle:hMenu = CreateMenu(MenuHandler_SettingsMenu);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Settings_Title", client);
	SetMenuTitle(hMenu, sBuffer);

	if(g_iDisplayMethod < 0 && g_hDisplayCookie != INVALID_HANDLE && g_iCurrentIndex[client] != -1)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Settings_Option_Cookie", client);
		AddMenuItem(hMenu, "1", sBuffer);
	}

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Settings_Option_Top", client);
	AddMenuItem(hMenu, "2", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Settings_Option_Rank", client);
	AddMenuItem(hMenu, "3", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Settings_Option_Next", client);
	AddMenuItem(hMenu, "4", sBuffer);

	if(g_iDisplayMethod != 0)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_Settings_Option_Positions", client);
		AddMenuItem(hMenu, "5", sBuffer);
	}

	DisplayMenu(hMenu, client, 30);
}

public MenuHandler_SettingsMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			if(g_iCurrentIndex[param1] == -1)
				return;

			decl String:sOption[4];
			GetMenuItem(menu, param2, sOption, 4);
			switch(StringToInt(sOption))
			{
				case 1:
				{
					if(!g_bLoadedSQL[param1] || !g_bLoadedCookies[param1])
					{
						CPrintToChat(param1, PLUGIN_PREFIX, "Phrase.Loading");
						return;
					}

					CreateCookieMenu(param1);
				}
				case 2:
				{
					decl String:sQuery[192];
					FormatEx(sQuery, sizeof(sQuery), "SELECT `lastname`,`points` FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC LIMIT %d", g_iRequiredPoints, g_iLimitTopPlayers);
					if(g_iEnabled == 2)
						PrintToDebug("Command_Say(%N): Issuing Query `%s`", param1, sQuery);
					SQL_TQuery(g_hDatabase, CallBack_Top, sQuery, GetClientUserId(param1));
				}
				case 3:
				{
					if(!g_bLoadedSQL[param1])
					{
						CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Loading");
						return;
					}

					if(g_iCurrentPoints[param1] < g_iRequiredPoints)
						CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Rank_Not_Enough", g_iRequiredPoints, g_iCurrentPoints[param1]);
					else
					{
						decl String:sQuery[192];
						FormatEx(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC", g_iCurrentPoints[param1]);
						if(g_iEnabled == 2)
							PrintToDebug("Command_Say(%N): Issuing Query `%s`", param1, sQuery);
						SQL_TQuery(g_hDatabase, CallBack_Rank, sQuery, GetClientUserId(param1));
					}

					CreateSettingsMenu(param1);
				}
				case 4:
				{
					if(!g_bLoadedSQL[param1])
					{
						CPrintToChat(param1, PLUGIN_PREFIX, "Phrase_Loading");
						return;
					}

					decl String:sQuery[192];
					FormatEx(sQuery, sizeof(sQuery), "SELECT `lastname`,`points` FROM `ranks` WHERE `points` >= %d AND `auth` != '%s' ORDER BY `points` ASC LIMIT %d", g_iCurrentPoints[param1], g_sAuth[param1], g_iLimitTopPlayers);
					if(g_iEnabled == 2)
						PrintToDebug("Command_Say(%N): Issuing Query `%s`", param1, sQuery);
					SQL_TQuery(g_hDatabase, CallBack_Next, sQuery, GetClientUserId(param1));
				}
				case 5:
				{
					CreateInfoMenu(param1);
				}
			}
		}
	}
}

public MenuHandler_MenuNextPlayers(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public CallBack_Rank(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(hndl, error, "CallBack_Rank");
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	if(SQL_FetchRow(hndl))
	{
		new iTime = GetTime();
		new iCount = SQL_FetchInt(hndl, 0);

		if(g_bGlobalMessage)
		{
			if(!BaseComm_IsClientGagged(client) && (iTime > g_iLastGlobalMessage[client] + cGlobalCooldown))
			{
				g_iLastGlobalMessage[client] = iTime;
				CPrintToChatAll(PLUGIN_PREFIX, "Phrase_Rank_Global", client, iCount, g_iTotalPlayers, g_iCurrentPoints[client]);

				return;
			}
		}

		CPrintToChat(client, PLUGIN_PREFIX, "Phrase_Rank_Player", iCount, g_iTotalPlayers, g_iCurrentPoints[client]);
	}
}

public PanelHandler_RankMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public CallBack_CommandSetMapPointsResult(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	ErrorCheck(owner, error, "CallBack_CommandSetMapPointsResult");

	ResetPack(pack);
	decl String:sMap[128];
	ReadPackString(pack, sMap, sizeof(sMap));
	new iPoints = ReadPackCell(pack);
	CloseHandle(pack);

	PrintToAdmins("(Notice) Map `%s` will reward %d points for completion.", sMap, iPoints);
}

public Action:Command_SetRankPoints(client, args)
{
	if(!g_iEnabled)
		return Plugin_Handled;

	if(g_hDatabase != INVALID_HANDLE && !g_bInitalizing)
	{
		if(args < 2)
		{
			ReplyToCommand(client, "Usage: timer_setrankpoints <steam> <amount> | <steam> must exist otherwise the operation fails.");
			return Plugin_Handled;
		}

		new iBreak, iPoints;
		new Handle:hPack = CreateDataPack();
		decl String:sText[192], String:sAuth[24];
		GetCmdArgString(sText, sizeof(sText));

		iBreak = BreakString(sText, sAuth, sizeof(sAuth));
		if(iBreak == -1)
		{
			CloseHandle(hPack);

			ReplyToCommand(client, "Usage: timer_setrankpoints <steam> <amount> | <steam> must exist otherwise the operation fails.");
			return Plugin_Handled;
		}
		iPoints = StringToInt(sText[iBreak]);

		WritePackString(hPack, sAuth);
		WritePackCell(hPack, iPoints);

		FormatEx(sText, sizeof(sText), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", sAuth);
		if(g_iEnabled == 2)
			PrintToDebug("Command_SetRankPoints(%N): Issuing Query `%s`", client, sText);
		SQL_TQuery(g_hDatabase, CallBack_CommandSetRankPoints, sText, hPack);
	}
	else
		ReplyToCommand(client, "[SM] Database offline; cannot complete action!");

	return Plugin_Handled;
}

public CallBack_CommandSetRankPoints(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	ErrorCheck(owner, error, "CallBack_CommandSetRankPoints");

	ResetPack(pack);
	decl String:sAuth[24];
	ReadPackString(pack, sAuth, sizeof(sAuth));
	new iPoints = ReadPackCell(pack);
	CloseHandle(pack);

	if(!SQL_GetRowCount(hndl))
		PrintToAdmins("(Notice) Auth '%s' does not exist within the database; please check your input!", sAuth);
	else
	{
		PrintToAdmins("(Notice) Auth '%s' now has a total of %d points.", sAuth, iPoints);

		decl String:sQuery[192];
		FormatEx(sQuery, sizeof(sQuery), "UPDATE `ranks` SET `points` = %d WHERE `auth` = '%s'", iPoints, sAuth);
		if(g_iEnabled == 2)
			PrintToDebug("CallBack_CommandSetRankPoints(): Issuing Query `%s`", sQuery);
		SQL_TQuery(g_hDatabase, CallBack_UpdateClient, sQuery, _);

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && StrEqual(sAuth, g_sAuth[i], false))
			{
				g_iCurrentPoints[i] = iPoints;
				break;
			}
		}
	}
}

public Action:Command_ChangeRankPoints(client, args)
{
	if(!g_iEnabled)
		return Plugin_Handled;

	if(g_hDatabase != INVALID_HANDLE && !g_bInitalizing)
	{
		if(args < 2)
		{
			ReplyToCommand(client, "Usage: timer_changerankpoints <steam> <amount> | <steam> must exist otherwise the operation fails. | Positive = Add, Negative = Subtract");
			return Plugin_Handled;
		}

		new iBreak, iPoints;
		new Handle:hPack = CreateDataPack();
		decl String:sText[192], String:sAuth[24];
		GetCmdArgString(sText, sizeof(sText));

		iBreak = BreakString(sText, sAuth, sizeof(sAuth));
		if(iBreak == -1)
		{
			CloseHandle(hPack);

			ReplyToCommand(client, "Usage: timer_changerankpoints <steam> <amount> | <steam> must exist otherwise the operation fails. | Positive = Add, Negative = Subtract");
			return Plugin_Handled;
		}
		iPoints = StringToInt(sText[iBreak]);

		WritePackString(hPack, sAuth);
		WritePackCell(hPack, iPoints);

		FormatEx(sText, sizeof(sText), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", sAuth);
		if(g_iEnabled == 2)
			PrintToDebug("Command_ChangeRankPoints(): Issuing Query `%s`", sText);
		SQL_TQuery(g_hDatabase, CallBack_CommandChangeRankPoints, sText, hPack);
	}
	else
		ReplyToCommand(client, "[SM] Database offline; cannot complete action!");

	return Plugin_Handled;
}

public CallBack_CommandChangeRankPoints(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	ErrorCheck(owner, error, "CallBack_CommandChangeRankPoints");

	ResetPack(pack);
	decl String:sAuth[24];
	ReadPackString(pack, sAuth, sizeof(sAuth));
	new iPoints = ReadPackCell(pack);
	CloseHandle(pack);

	if(!SQL_GetRowCount(hndl))
		PrintToAdmins("(Notice) Auth '%s' does not exist within the database; please check your input!", sAuth);
	else if(SQL_FetchRow(hndl))
	{
		new iCurrent = SQL_FetchInt(hndl, 0);
		PrintToAdmins("(Notice) Auth '%s' has been assigned %d points.", sAuth, iPoints);

		decl String:sQuery[192];
		FormatEx(sQuery, sizeof(sQuery), "UPDATE `ranks` SET `points` = %d WHERE `auth` = '%s'", (iCurrent + iPoints), sAuth);
		if(g_iEnabled == 2)
			PrintToDebug("CallBack_CommandChangeRankPoints(): Issuing Query `%s`", sQuery);
		SQL_TQuery(g_hDatabase, CallBack_UpdateClient, sQuery, _);

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && StrEqual(sAuth, g_sAuth[i], false))
			{
				g_iCurrentPoints[i] = (iCurrent + iPoints);
				break;
			}
		}
	}
}

public MenuHandler_ListMapMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public Action:Command_ListRanks(client, args)
{
	if(!g_iEnabled)
		return Plugin_Handled;

	if(g_hDatabase != INVALID_HANDLE && !g_bInitalizing)
	{
		decl String:sQuery[128];
		FormatEx(sQuery, sizeof(sQuery), "SELECT `lastname`,`points` FROM `ranks` ORDER BY `points` DESC");
		if(g_iEnabled == 2)
			PrintToDebug("Command_ListRanks(%N): Issuing Query `%s`", client, sQuery);
		SQL_TQuery(g_hDatabase, CallBack_CommandListRanks, sQuery, client ? GetClientUserId(client) : 0);
	}

	return Plugin_Handled;
}

public CallBack_CommandListRanks(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(owner, error, "CallBack_CommandListRanks");

	new iClient;
	decl String:sBuffer[128];
	new Handle:hMenu = INVALID_HANDLE;
	if(userid)
	{
		iClient = GetClientOfUserId(userid);
		if(!IsClientInGame(iClient))
			return;

		hMenu = CreateMenu(MenuHandler_ListRankMenu);
		SetMenuTitle(hMenu, "[Timer] Ranking\n- Player List");
	}

	new iIndex;
	decl iPoints, String:sName[256];
	while(SQL_FetchRow(hndl))
	{
		iIndex++;

		SQL_FetchString(hndl, 0, sName, sizeof(sName));
		iPoints = SQL_FetchInt(hndl, 1);

		if(!userid)
			ReplyToCommand(iClient, "(#%d) %s, %d Points", iIndex, sName, iPoints);
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "(#%d) %s, %d Points", iIndex, sName, iPoints);
			AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
		}
	}

	if(hMenu != INVALID_HANDLE)
		DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_ListRankMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Parse_Points()
{
	if(g_hArray_CfgPoints == INVALID_HANDLE)
		g_hArray_CfgPoints = CreateArray();
	else
		ClearArray(g_hArray_CfgPoints);

	if(g_hArray_CfgRanks == INVALID_HANDLE)
		g_hArray_CfgRanks = CreateArray();
	else
		ClearArray(g_hArray_CfgRanks);

	if(g_hCfgArray_DisplayTag == INVALID_HANDLE)
		g_hCfgArray_DisplayTag = CreateArray(64);
	else
		ClearArray(g_hCfgArray_DisplayTag);

	if(g_hCfgArray_DisplayChat == INVALID_HANDLE)
		g_hCfgArray_DisplayChat = CreateArray(64);
	else
		ClearArray(g_hCfgArray_DisplayChat);

	if(g_hTrie_CfgCommands == INVALID_HANDLE)
		g_hTrie_CfgCommands = CreateTrie();
	else
		ClearTrie(g_hTrie_CfgCommands);

	if(g_hCfgArray_DisplayInfo == INVALID_HANDLE)
		g_hCfgArray_DisplayInfo = CreateArray(64);
	else
		ClearArray(g_hCfgArray_DisplayInfo);

	if(g_hCfgArray_DisplayStars == INVALID_HANDLE)
		g_hCfgArray_DisplayStars = CreateArray();
	else
		ClearArray(g_hCfgArray_DisplayStars);

	if(g_hCfgArray_DisplayColor == INVALID_HANDLE)
		g_hCfgArray_DisplayColor = CreateArray(64);
	else
		ClearArray(g_hCfgArray_DisplayColor);

	if(g_hArray_Positions == INVALID_HANDLE)
		g_hArray_Positions = CreateArray();
	else
		ClearArray(g_hArray_Positions);

	new Handle:hTemp[7] = { INVALID_HANDLE, ... };
	hTemp[0] = CreateArray();
	hTemp[1] = CreateArray();
	hTemp[2] = CreateArray(256);
	hTemp[3] = CreateArray(256);
	hTemp[4] = CreateArray(256);
	hTemp[5] = CreateArray(256);
	hTemp[6] = CreateArray();

	g_iTotalRanks = 0;
	decl iBuffer, String:sPath[PLATFORM_MAX_PATH], String:sBuffer[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/rankings.cfg");

	new Handle:hKeyValues = CreateKeyValues("Timer.Rankings.Configs");
	if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues))
	{
		do
		{
			KvGetSectionName(hKeyValues, sPath, sizeof(sPath));
			if(StrEqual(sPath, "Commands", false))
			{
				KvGotoFirstSubKey(hKeyValues, false);
				do
				{
					KvGetSectionName(hKeyValues, sBuffer, sizeof(sBuffer));
					iBuffer = KvGetNum(hKeyValues, NULL_STRING, 0);

					if(!StrContains(sBuffer, "sm_"))
					{
						strcopy(sPath, sizeof(sPath), sBuffer);
						ReplaceString(sPath, sizeof(sPath), "sm_", "!", false);
						SetTrieValue(g_hTrie_CfgCommands, sPath, iBuffer);

						strcopy(sPath, sizeof(sPath), sBuffer);
						ReplaceString(sPath, sizeof(sPath), "sm_", "/", false);
						SetTrieValue(g_hTrie_CfgCommands, sPath, iBuffer);
					}
					else
						SetTrieValue(g_hTrie_CfgCommands, sBuffer, iBuffer);
				}
				while (KvGotoNextKey(hKeyValues, false));

				KvGoBack(hKeyValues);
			}
			else if(StrEqual(sPath, "Loading", false))
			{
				KvGetString(hKeyValues, "tag", g_sLoadingScoreTag, sizeof(g_sLoadingScoreTag));
				KvGetString(hKeyValues, "chat", g_sLoadingChatTag, sizeof(g_sLoadingChatTag));
				KvGetString(hKeyValues, "text", g_sLoadingChatColor, sizeof(g_sLoadingChatColor));

				#if !defined LEGACY_COLORS
				ReplaceString(g_sLoadingChatTag, sizeof(g_sLoadingChatTag), "#", "\x07");
				ReplaceString(g_sLoadingChatColor, sizeof(g_sLoadingChatColor), "#", "\x07");
				#endif
			}
			else
			{
				PushArrayCell(hTemp[0], KvGetNum(hKeyValues, "points", 0));

				PushArrayCell(hTemp[1], KvGetNum(hKeyValues, "ranks", 0));

				KvGetString(hKeyValues, "tag", sPath, sizeof(sPath));
				PushArrayString(hTemp[2], sPath);

				KvGetString(hKeyValues, "chat", sBuffer, sizeof(sBuffer));
				#if !defined LEGACY_COLORS
				ReplaceString(sBuffer, sizeof(sBuffer), "#", "\x07");
				#endif
				PushArrayString(hTemp[3], sBuffer);

				KvGetString(hKeyValues, "text", sBuffer, sizeof(sBuffer));
				#if !defined LEGACY_COLORS
				ReplaceString(sBuffer, sizeof(sBuffer), "#", "\x07");
				#endif
				PushArrayString(hTemp[4], sBuffer);

				KvGetString(hKeyValues, "info", sPath, sizeof(sPath));
				PushArrayString(hTemp[5], sPath);

				PushArrayCell(hTemp[6], KvGetNum(hKeyValues, "stars", 0));

				g_iTotalRanks++;
			}
		}
		while (KvGotoNextKey(hKeyValues));

		g_iTotalRanks--;
		for(new i = g_iTotalRanks; i >= 0; i--)
		{
			new iIndex;
			new iCurrent;
			new iLowest = 2147483647;

			if(g_iPositionMethod)
			{
				new iSize = GetArraySize(hTemp[1]);
				for(new j = 0; j < iSize; j++)
				{
					if((iCurrent = GetArrayCell(hTemp[1], j)) <= iLowest)
					{
						iIndex = j;
						iLowest = iCurrent;
					}
				}
			}
			else
			{
				new iSize = GetArraySize(hTemp[0]);
				for(new j = 0; j < iSize; j++)
				{
					if((iCurrent = GetArrayCell(hTemp[0], j)) <= iLowest)
					{
						iIndex = j;
						iLowest = iCurrent;
					}
				}
			}

			PushArrayCell(g_hArray_CfgPoints, GetArrayCell(hTemp[0], iIndex));
			PushArrayCell(g_hArray_CfgRanks, GetArrayCell(hTemp[1], iIndex));
			GetArrayString(hTemp[2], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayTag, sPath);
			GetArrayString(hTemp[3], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayChat, sPath);
			GetArrayString(hTemp[4], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayColor, sPath);
			GetArrayString(hTemp[5], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayInfo, sPath);
			PushArrayCell(g_hCfgArray_DisplayStars, GetArrayCell(hTemp[6], iIndex));

			for(new j = 0; j <= 6; j++)
				RemoveFromArray(hTemp[j], iIndex);
		}

		if(g_iPositionMethod)
		{
			new iSize = GetArraySize(g_hArray_CfgRanks);
			for(new i = 0; i < iSize; i++)
			{
				g_iHighestRank = GetArrayCell(g_hArray_CfgRanks, i);

				if(FindValueInArray(g_hArray_Positions, g_iHighestRank) == -1)
					PushArrayCell(g_hArray_Positions, g_iHighestRank);
			}
		}
	}

	CloseHandle(hKeyValues);
	for(new i = 0; i <= 6; i++)
		CloseHandle(hTemp[i]);
}

public Action:Command_PrintRanks(args)
{
	decl String:sArgument[4];
	GetCmdArg(1, sArgument, sizeof(sArgument));
	new iArgument = StringToInt(sArgument);

	if(iArgument & cPrintRanks)
	{
		decl String:sTemp[256];
		LogToFile(g_sDumpLog, "%d currently defined ranks.", g_iTotalRanks);
		LogToFile(g_sDumpLog, "===Rank Definitions===");
		for(new i = 0; i <= g_iTotalRanks; i++)
		{
			LogToFile(g_sDumpLog, "Minimum Points: %d", GetArrayCell(g_hArray_CfgPoints, i));
			LogToFile(g_sDumpLog, "Minimum Rank: %d", GetArrayCell(g_hArray_CfgRanks, i));
			GetArrayString(g_hCfgArray_DisplayTag, i, sTemp, sizeof(sTemp));
			LogToFile(g_sDumpLog, "Tag: %s", sTemp);
			GetArrayString(g_hCfgArray_DisplayChat, i, sTemp, sizeof(sTemp));
			LogToFile(g_sDumpLog, "Chat: %s", sTemp);
			GetArrayString(g_hCfgArray_DisplayColor, i, sTemp, sizeof(sTemp));
			LogToFile(g_sDumpLog, "Text: %s", sTemp);
			GetArrayString(g_hCfgArray_DisplayInfo, i, sTemp, sizeof(sTemp));
			LogToFile(g_sDumpLog, "Info: %s", sTemp);
			LogToFile(g_sDumpLog, "Stars: %d", GetArrayCell(g_hCfgArray_DisplayStars, i));
			if(i < g_iTotalRanks)
				LogToFile(g_sDumpLog, "---");
			else
				LogToFile(g_sDumpLog, "");
		}

		PrintToChatAll("[Timer] Rankings: Finished printing Rank configuration to log!");
	}

	if(iArgument & cPrintPlayers)
	{
		if(g_iCurrentDebug != -1)
			return Plugin_Handled;

		g_iCurrentDebug = (g_iTotalPlayers > 500) ? 500 : g_iTotalPlayers;
		decl String:sPlayerQuery[256];
		FormatEx(sPlayerQuery, sizeof(sPlayerQuery), "SELECT `lastname`,`auth`,`points` FROM `ranks` ORDER BY `points` DESC LIMIT %d,%d", 0, g_iCurrentDebug);
		SQL_TQuery(g_hDatabase, CallBack_DebugPrintPlayers, sPlayerQuery, 0);
	}

	return Plugin_Handled;
}

public CallBack_DebugPrintPlayers(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		LogToFile(g_sDumpLog, "No Players Found");
		LogToFile(g_sDumpLog, "");

		PrintToChatAll("[Timer] Rankings: Finished printing Player Ranks to log!");
		return;
	}

	LogToFile(g_sDumpLog, "---Entries %d - %d---", data, g_iCurrentDebug);

	new iSize = GetArraySize(g_hArray_Positions);
	new iOutside = FindValueInArray(g_hArray_Positions, -1);
	decl iPoints, String:sName[65], String:sAuth[24], String:sPosition[256];
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, sName, sizeof(sName));
		SQL_FetchString(hndl, 1, sAuth, sizeof(sAuth));
		iPoints = SQL_FetchInt(hndl, 2);

		new iPosition = -1;
		if(g_iDebugIndex > g_iHighestRank)
			iPosition = iOutside;
		else
		{
			for(new i = 0; i < iSize; i++)
			{
				if(g_iDebugIndex <= GetArrayCell(g_hArray_Positions, i))
				{
					iPosition = i;
					break;
				}
			}
		}

		if(iPosition != -1)
			GetArrayString(g_hCfgArray_DisplayInfo, iPosition, sPosition, sizeof(sPosition));
		else
			strcopy(sPosition, sizeof(sPosition), "");

		LogToFile(g_sDumpLog, "[%s] `%s` == %d Points, %d/%d Position (`%s`)", sAuth, sName, iPoints, iPosition, g_iHighestRank, sPosition);
		g_iDebugIndex++;
	}

	if(data == g_iTotalPlayers)
	{
		PrintToChatAll("[Timer] Rankings: Finished printing Player Ranks to log!");
		g_iDebugIndex = 1;
		g_iCurrentDebug = -1;
		return;
	}

	new iStart = g_iCurrentDebug + 1;
	g_iCurrentDebug += 500;
	if(g_iCurrentDebug > g_iTotalPlayers)
		g_iCurrentDebug = g_iTotalPlayers;

	decl String:sPlayerQuery[256];
	FormatEx(sPlayerQuery, sizeof(sPlayerQuery), "SELECT `lastname`,`auth`,`points` FROM `ranks` ORDER BY `points` DESC LIMIT %d,%d", iStart, g_iCurrentDebug);
	SQL_TQuery(g_hDatabase, CallBack_DebugPrintPlayers, sPlayerQuery, iStart);
}

public Action:Timer_AuthClient(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(IsClientInGame(client))
	{
		g_bAuthed[client] = GetClientAuthString(client, g_sAuth[client], sizeof(g_sAuth[]));
		if(!g_bAuthed[client])
			return Plugin_Continue;
		else
		{
			if(g_hDatabase != INVALID_HANDLE && !g_bInitalizing)
				return Plugin_Continue;

			g_sAuth[client][6] = '0';
			GetClientName(client, g_sName[client], sizeof(g_sName[]));
			if(!g_bLoadedSQL[client])
			{
				decl String:sQuery[192];
				FormatEx(sQuery, sizeof(sQuery), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", g_sAuth[client]);
				SQL_TQuery(g_hDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(client));
			}

			if(!g_bLoadedCookies[client] && AreClientCookiesCached(client))
				LoadClientData(client);
		}
	}

	return Plugin_Stop;
}

ErrorCheck(Handle:owner, const String:error[], const String:callback[] = "")
{
	if(owner == INVALID_HANDLE)
	{
		Timer_LogError("Rankings: Fatal error occured in `%s`", callback);
		Timer_LogError("> `%s`", error);
		if(g_iEnabled == 2)
		{
			PrintToDebug("[Timer] Rankings: Fatal error occured in `%s`", callback);
			PrintToDebug("> `%s`", error);
		}

		SetFailState("FATAL SQL ERROR in `%s`; View logs!", callback);
	}
	else if(!StrEqual(error, ""))
	{
		Timer_LogError("Rankings: Error occured in `%s`", callback);
		Timer_LogError("> `%s`", error);
		if(g_iEnabled == 2)
		{
			PrintToDebug("[Timer] Rankings: Error occured in `%s`", callback);
			PrintToDebug("> `%s`", error);
		}
	}
}

stock PrintToDebug(const String:format[], any:...)
{
	decl String:sBuffer[2048];
	VFormat(sBuffer, sizeof(sBuffer), format, 2);

	LogToFile(g_sPluginLog, sBuffer);
}

stock PrintToAdmins(const String:format[], any:...)
{
	decl String:sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), format, 2);

	LogMessage("%s", sBuffer);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !CheckCommandAccess(i, "Timer_Rankings_Admin", ADMFLAG_GENERIC))
			continue;

		CPrintToChat(i, "%s%s", PLUGIN_PREFIX2, sBuffer);
	}

	if(g_iEnabled == 2)
		LogToFile(g_sPluginLog, sBuffer);
}

SavePoints(client)
{
	decl String:sQuery[192];
	FormatEx(sQuery, sizeof(sQuery), "UPDATE `ranks` SET `points` = %d WHERE `auth` = '%s'", g_iCurrentPoints[client], g_sAuth[client]);
	if(g_iEnabled == 2)
		PrintToDebug("OnFinishRound(%N): Issuing Query `%s`", client, sQuery);
	SQL_TQuery(g_hDatabase, CallBack_UpdateClient, sQuery, GetClientUserId(client), DBPrio_High);

	if(g_iPositionMethod)
	{
		FormatEx(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC", g_iCurrentPoints[client]);
		if(g_iEnabled == 2)
			PrintToDebug("OnFinishRound(%N): Issuing Query `%s`", client, sQuery);
		SQL_TQuery(g_hDatabase, CallBack_LoadRank, sQuery, GetClientUserId(client));
	}
	else
	{
		if(g_iNextIndex[client] == -1)
			return;

		if(g_iCurrentPoints[client] >= g_iNextIndex[client])
		{
			g_iCurrentIndex[client]++;
			if(g_iCurrentIndex[client] == g_iTotalRanks)
				g_iNextIndex[client] = -1;
			else
				g_iNextIndex[client] = GetArrayCell(g_hArray_CfgPoints, g_iCurrentIndex[client] + 1);

			UpdateClientTag(client);
			UpdateClientStars(client);
		}
	}
}

public Native_GetPoints(Handle:plugin, numParams)
{
	return g_iCurrentPoints[GetNativeCell(1)];
}

public Native_GetPointRank(Handle:plugin, numParams)
{
	return g_iCurrentRank[GetNativeCell(1)];
}

public Native_SetPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new points = GetNativeCell(2);
	
	new old_points = g_iCurrentPoints[client];
	
	g_iCurrentPoints[client] = points;
        
	// Forward points edit by raska
	Call_StartForward(g_timerSetPointsForward);
	Call_PushCell(client);
	Call_PushCell(g_iCurrentPoints[client]);
	Call_PushCell(old_points);
	Call_Finish();
}

public Native_AddPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new points = GetNativeCell(2);
	g_iCurrentPoints[client] += points;
        
	// Forward points edit by raska
	Call_StartForward(g_timerGainPointsForward);
	Call_PushCell(client);
	Call_PushCell(g_iCurrentPoints[client]);
	Call_PushCell(points);
	Call_Finish();
}

public Native_RemovePoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new points = GetNativeCell(2);
	
	g_iCurrentPoints[client] -= points;
	
	if(g_iCurrentPoints[client] < 0) g_iCurrentPoints[client] = 0;
        
	// Forward points edit by raska
	Call_StartForward(g_timerLostPointsForward);
	Call_PushCell(client);
	Call_PushCell(g_iCurrentPoints[client]);
	Call_PushCell(points);
	Call_Finish();
}

public Native_SavePoints(Handle:plugin, numParams)
{
	SavePoints(GetNativeCell(1));
}

public Native_RefreshPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:sQuery[192];
	if(IsClientInGame(client) && g_bAuthed[client] && !IsFakeClient(client))
	{
		g_bShowConnectMsg[client] = false;
		FormatEx(sQuery, sizeof(sQuery), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", g_sAuth[client]);
		if(g_iEnabled == 2)
			PrintToDebug("CallBack_Creation(%N): Issuing Query `%s`", client, sQuery);
		SQL_TQuery(g_hDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(client), DBPrio_Low);
	}
}

public Native_RefreshPointsAll(Handle:plugin, numParams)
{
	decl String:sQuery[192];
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_bAuthed[i] && !IsFakeClient(i))
		{
			g_bShowConnectMsg[i] = false;
			FormatEx(sQuery, sizeof(sQuery), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", g_sAuth[i]);
			if(g_iEnabled == 2)
				PrintToDebug("CallBack_Creation(%N): Issuing Query `%s`", i, sQuery);
			SQL_TQuery(g_hDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(i), DBPrio_Low);
		}
	}
}

stock bool:Client_HasAdminFlags(client, flags=ADMFLAG_GENERIC)
{
	new AdminId:adminId = GetUserAdmin(client);
	
	if (adminId == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	return bool:(GetAdminFlags(adminId, Access_Effective) & flags);
}

stock ValidatePlayerSlot(client, bool:force_kick = false)
{
	if(g_iConnectTopOnly > 0 && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION))
	{
		if(force_kick || g_iConnectTopOnly < g_iCurrentIndex[client])
		{
			g_fKickTime[client] = GetGameTime()+g_fKickDelay;
			CreateTimer(1.0, Timer_PrepareKick, GetClientSerial(client), TIMER_REPEAT);
		}
	}
}

public Action:Timer_PrepareKick(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (!IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	decl String:sRank[32];
	FormatEx(sRank, sizeof(sRank), "%d", g_iConnectTopOnly);
	
	decl String:buffer[512];
	FormatEx(buffer, sizeof(buffer), "%s", g_sKickMsg);
	
	ReplaceString(buffer, sizeof(buffer), "{rank}", sRank, true);
	
	if(GetGameTime() <= g_fKickTime[client])
	{
		CPrintToChat(client, "%s", buffer);
	}
	else
	{
		KickClient(client, "%s", buffer);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

CreateSession(client, points, bool:create)
{
	KvJumpToKey(g_hSession, g_sAuth[client], create);
	KvSetFloat(g_hSession, "connection_time", GetEngineTime());
	KvSetFloat(g_hSession, "disconnec_time", 0.0);
	KvSetNum(g_hSession, "points", points);
	KvSetNum(g_hSession, "worldrecords", 0);
	KvSetNum(g_hSession, "toprecords", 0);
	KvSetNum(g_hSession, "records", 0);
	KvRewind(g_hSession);
	
	CPrintToChat(client, "%s Session started. Type !session to see your session stats.", PLUGIN_PREFIX2);
}

public Action:Cmd_Session(client, args)
{
	SessionStats(client);
	return Plugin_Handled;
}

SessionStats(client)
{
	if(KvJumpToKey(g_hSession, g_sAuth[client], false))
	{
		decl String:sTag[20];
		GetArrayString(g_hCfgArray_DisplayTag, g_iCurrentIndex[client], sTag, sizeof(sTag));
		
		new points_start = KvGetNum(g_hSession, "points", 0);
		new points = Timer_GetPoints(client);
		new time_connected = RoundToFloor(GetEngineTime()-KvGetFloat(g_hSession, "connection_time", GetEngineTime()));
		
		decl String:text[256];
		new Handle:panel = CreatePanel();
		DrawPanelText(panel, "[Timer] Player Session Stats");
		DrawPanelItem(panel, "[Tag] Name");
		Format(text, sizeof(text), "[%s] %s", sTag, g_sName[client]);
		DrawPanelText(panel, text);
		DrawPanelItem(panel, "Points");
		Format(text, sizeof(text), "%d (%s%d)", points, (points-points_start < 0 ? "" : "+"), points-points_start);
		DrawPanelText(panel, text);
		DrawPanelItem(panel, "Time played");
		Format(text, sizeof(text), "%id %ih %im %is", time_connected / 86400,(time_connected % 86400) / 3600, (time_connected % 3600) / 60, time_connected % 60);
		DrawPanelText(panel, text);
		SendPanelToClient(panel, client, SessionHandler, 10);
		CloseHandle(panel);
	}
	KvRewind(g_hSession);
}

public SessionHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public Action:event_connect(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	if(!bDontBroadcast)
    {
		decl String:szName[32], String:szNetworkID[22], String:szAddress[26];
		GetEventString(hEvent, "name", szName, sizeof(szName)-1);
		GetEventString(hEvent, "networkid", szNetworkID, sizeof(szNetworkID)-1);
		GetEventString(hEvent, "address", szAddress, sizeof(szAddress)-1);
		
		new Handle:hNewEvent = CreateEvent("player_connect", true);
		SetEventString(hNewEvent, "name", szName);
		SetEventInt(hNewEvent, "index", GetEventInt(hEvent, "index"));
		SetEventInt(hNewEvent, "userid", GetEventInt(hEvent, "userid"));
		SetEventString(hNewEvent, "networkid", szNetworkID);
		SetEventString(hNewEvent, "address", szAddress);
		
		FireEvent(hNewEvent, true);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:event_disconnect(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	if(!bDontBroadcast)
    {
		decl String:szReason[22], String:szName[32], String:szNetworkID[22];
		GetEventString(hEvent, "reason", szReason, sizeof(szReason)-1);
		GetEventString(hEvent, "name", szName, sizeof(szName)-1);
		GetEventString(hEvent, "networkid", szNetworkID, sizeof(szNetworkID)-1);
		
		new Handle:hNewEvent = CreateEvent("player_disconnect", true);
		SetEventInt(hNewEvent, "userid", GetEventInt(hEvent, "userid"));
		SetEventString(hNewEvent, "reason", szReason);
		SetEventString(hNewEvent, "name", szName);
		SetEventString(hNewEvent, "networkid", szNetworkID);
		
		FireEvent(hNewEvent, true);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/*stock bool:IsValidClient(client, bool:nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}*/
