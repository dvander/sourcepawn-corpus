/*
Revision 1.1.1
--------------
	SQL queries are now executed when command is issued, rather than caching until the client disconnects.
	The sm_warnreset command now removes all previous punishments from the logging database.
	Removed random requirement for adminmenu when it wasn't being used.
	Added CVar sm_warnings_time_format to control the time format used in sm_warnlist
	
Revision 1.1.2
--------------
	Plugin now takes into consideration SQLite v MySQL in regards to Auto Increment.
	
Revision 1.1.3
--------------
	Fixed a bug where sm_warn issued the client command for server command.
	Fixed a serious bug with the auth portion of the database.
	Added sm_warnpuge, to completely dump tables.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <dbi>
#include <clientprefs>
//#include <colors> //https://forums.alliedmods.net/showpost.php?p=1883578&postcount=311 - Use for CS:GO
#include <morecolors>	//https://www.doctormckay.com/download/scripting/include/morecolors.inc - Use for CS:S

#define PLUGIN_VERSION "1.1.3"

#define TEAM_NONE 0
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLUE 3

#define ACTION_WARN 1
#define ACTION_TIME 2

new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:g_hDatabaseTable = INVALID_HANDLE;
new Handle:g_hLogging = INVALID_HANDLE;
new Handle:g_hLoggingTable = INVALID_HANDLE;
new Handle:g_hLoggingPath = INVALID_HANDLE;
new Handle:g_hWarnClientCmd = INVALID_HANDLE;
new Handle:g_hWarnServerCmd = INVALID_HANDLE;
new Handle:g_hWarnUrl = INVALID_HANDLE;
new Handle:g_hWarnSound = INVALID_HANDLE;
new Handle:g_hWarnLength = INVALID_HANDLE;
new Handle:g_hTimeClientCmd = INVALID_HANDLE;
new Handle:g_hTimeServerCmd = INVALID_HANDLE;
new Handle:g_hTimeUrl = INVALID_HANDLE;
new Handle:g_hTimeSound = INVALID_HANDLE;
new Handle:g_hNotifyTimeout = INVALID_HANDLE;
new Handle:g_hTimeDefault = INVALID_HANDLE;
new Handle:g_hExpireLength = INVALID_HANDLE;
new Handle:g_hShowActivity = INVALID_HANDLE;
new Handle:g_hNotifyFlag = INVALID_HANDLE;
new Handle:g_hNotifyOverride = INVALID_HANDLE;
new Handle:g_hNotifyWarnings = INVALID_HANDLE;
new Handle:g_hNotifyTimeouts = INVALID_HANDLE;
new Handle:g_hCookie_Warnings = INVALID_HANDLE;
new Handle:g_hCookie_Timeouts = INVALID_HANDLE;
new Handle:g_hCookie_Duration = INVALID_HANDLE;
new Handle:g_hCookie_Issue = INVALID_HANDLE;
new Handle:g_hWarnDatabase = INVALID_HANDLE;
new Handle:g_hLogDatabase = INVALID_HANDLE;
new Handle:g_hTimeFormat = INVALID_HANDLE;

new g_iTeam[MAXPLAYERS + 1];
new g_iPeskyMenus[MAXPLAYERS + 1][2];
new g_iNumWarnings[MAXPLAYERS + 1];
new g_iNumTimeouts[MAXPLAYERS + 1];
new g_iTimeoutIssue[MAXPLAYERS + 1];
new g_iTimeoutDuration[MAXPLAYERS + 1];
new g_iNotifyCounter[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bTimeout[MAXPLAYERS + 1];
new String:g_sSteam[MAXPLAYERS + 1][24];
new Handle:g_hWarnNotice[MAXPLAYERS + 1];
new Handle:g_hTimeoutNotice[MAXPLAYERS + 1];
new Handle:g_hExpireNotice[MAXPLAYERS + 1];

new g_iTotalTimeouts, g_iTotalPlayers, g_iWarnLength, g_iTimeDefault, g_iExpireLength, g_iShowActivity, g_iNotifyFlag, g_iNotifyWarnings, g_iNotifyTimeouts;
new bool:g_bNotifyTimeout, bool:g_bLateLoad;
new String:g_sLoggingPath[PLATFORM_MAX_PATH], String:g_sNotifyOverride[32], String:g_sWarnClientCmd[128], String:g_sWarnServerCmd[128], String:g_sWarnUrl[128], String:g_sTimeClientCmd[128], String:g_sTimeServerCmd[128];
new String:g_sTimeFormat[128], String:g_sTimeUrl[128], String:g_sWarnSound[PLATFORM_MAX_PATH], String:g_sTimeSound[PLATFORM_MAX_PATH], String:g_sDatabase[128], String:g_sLogging[128], String:g_sDatabaseTable[128], String:g_sLoggingTable[128];

public Plugin:myinfo =
{
	name = "Player Warnings",
	author = "Panduh",
	description = "Provides configurable support for warning players, placing them in timeout, as well as tracking the infraction count.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart ()
{
	decl String:sBuffer[32];
	LoadTranslations("common.phrases");
	LoadTranslations("sm_player_warnings.phrases");

	CreateConVar("sm_warnings_version", PLUGIN_VERSION, "Player Warnings: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hDatabase = CreateConVar("sm_warnings_database", "", "Controls what database configuration to use for warnings. Use \"\" for ClientPrefs.", FCVAR_NONE);
	HookConVarChange(g_hDatabase, OnSettingsChange);
	GetConVarString(g_hDatabase, g_sDatabase, sizeof(g_sDatabase));

	g_hDatabaseTable = CreateConVar("sm_warnings_database_table", "player_warnings", "Controls what table the database will utilize if non-clientprefs.", FCVAR_NONE);
	HookConVarChange(g_hDatabaseTable, OnSettingsChange);
	GetConVarString(g_hDatabaseTable, g_sDatabaseTable, sizeof(g_sDatabaseTable));

	g_hLogging = CreateConVar("sm_warnings_logging_database", "", "Controls what database configuration to use for logging warnings. Use \"\" for Log files.", FCVAR_NONE);
	HookConVarChange(g_hLogging, OnSettingsChange);
	GetConVarString(g_hLogging, g_sLogging, sizeof(g_sLogging));

	g_hLoggingTable = CreateConVar("sm_warnings_logging_database_table", "player_warnings_logs", "Controls what table the database will utilize if non log files.", FCVAR_NONE);
	HookConVarChange(g_hLoggingTable, OnSettingsChange);
	GetConVarString(g_hLoggingTable, g_sLoggingTable, sizeof(g_sLoggingTable));

	g_hLoggingPath = CreateConVar("sm_warnings_logging_database_path", "logs/player_warnings.log", "Controls what table log file the plugin will use for logging if non-database.", FCVAR_NONE);
	HookConVarChange(g_hLoggingPath, OnSettingsChange);
	GetConVarString(g_hLoggingPath, g_sLoggingPath, sizeof(g_sLoggingPath));

	g_hWarnClientCmd = CreateConVar("sm_warnings_warn_client_cmd", "", "The client command to be issued on the client upon being warned by an administrator.", FCVAR_NONE);
	HookConVarChange(g_hWarnClientCmd, OnSettingsChange);
	GetConVarString(g_hWarnClientCmd, g_sWarnClientCmd, sizeof(g_sWarnClientCmd));

	g_hWarnServerCmd = CreateConVar("sm_warnings_warn_server_cmd", "", "The server command to be issued on the client upon being warned by an administrator. These can be used to replace with the client data: {clientName}, {clientUser}, {clientAuth}", FCVAR_NONE);
	HookConVarChange(g_hWarnServerCmd, OnSettingsChange);
	GetConVarString(g_hWarnServerCmd, g_sWarnServerCmd, sizeof(g_sWarnServerCmd));

	g_hWarnUrl = CreateConVar("sm_warnings_warn_url", "", "The address to be issued to the client in a motd window upon being warned by an administrator.", FCVAR_NONE);
	HookConVarChange(g_hWarnUrl, OnSettingsChange);
	GetConVarString(g_hWarnUrl, g_sWarnUrl, sizeof(g_sWarnUrl));

	g_hWarnSound = CreateConVar("sm_warnings_warn_sound", "npc/roller/mine/rmine_tossed1.wav", "The sound to be played to the client upon being warned by an administrator.", FCVAR_NONE);
	HookConVarChange(g_hWarnSound, OnSettingsChange);
	GetConVarString(g_hWarnSound, g_sWarnSound, sizeof(g_sWarnSound));

	g_hWarnLength = CreateConVar("sm_warnings_warn_duration", "10", "The number of seconds the center print will appear for a warned player. (0.0 = Disable Repeating Prints)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hWarnLength, OnSettingsChange);
	g_iWarnLength = GetConVarBool(g_hWarnLength);

	g_hTimeClientCmd = CreateConVar("sm_warnings_timeout_client_cmd", "", "The client command to be issued on the client upon being placed in time out.", FCVAR_NONE);
	HookConVarChange(g_hTimeClientCmd, OnSettingsChange);
	GetConVarString(g_hTimeClientCmd, g_sTimeClientCmd, sizeof(g_sTimeClientCmd));

	g_hTimeServerCmd = CreateConVar("sm_warnings_timeout_server_cmd", "", "The server command to be issued on the client upon being placed in time out. These can be used to replace with the client data: {clientName}, {clientUser}, {clientAuth}", FCVAR_NONE);
	HookConVarChange(g_hTimeServerCmd, OnSettingsChange);
	GetConVarString(g_hTimeServerCmd, g_sTimeServerCmd, sizeof(g_sTimeServerCmd));

	g_hTimeUrl = CreateConVar("sm_warnings_timeout_url", "", "The address to be issued to the client in a motd window upon being placed in time out by an administrator.", FCVAR_NONE);
	HookConVarChange(g_hTimeUrl, OnSettingsChange);
	GetConVarString(g_hTimeUrl, g_sTimeUrl, sizeof(g_sTimeUrl));

	g_hTimeSound = CreateConVar("sm_warnings_timeout_sound", "common/bugreporter_failed.wav", "The sound to be played to the client upon being placed in time out by an administrator.", FCVAR_NONE);
	HookConVarChange(g_hTimeSound, OnSettingsChange);
	GetConVarString(g_hTimeSound, g_sTimeSound, sizeof(g_sTimeSound));

	g_hNotifyTimeout = CreateConVar("sm_warnings_timeout_notify", "1", "If enabled, clients in timeout will receive a continuous center notification displaying the remaining time. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hNotifyTimeout, OnSettingsChange);
	g_bNotifyTimeout = GetConVarBool(g_hNotifyTimeout);

	g_hTimeDefault = CreateConVar("sm_warnings_timeout_default", "300", "The default duration for time out punishments, in seconds, if no duration is specified.", FCVAR_NONE, true, 1.0);
	HookConVarChange(g_hTimeDefault, OnSettingsChange);
	g_iTimeDefault = GetConVarInt(g_hTimeDefault);

	g_hExpireLength = CreateConVar("sm_warnings_expire_duration", "10", "The number of seconds the center print will appear for a player whos timeout has expired. (0.0 = Disable Repeating Prints)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hExpireLength, OnSettingsChange);
	g_iExpireLength = GetConVarInt(g_hExpireLength);

	g_hNotifyWarnings = CreateConVar("sm_warnings_notify_warnings", "6", "The minimum number of warnings needed to warn in-game administrators of connection. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hNotifyWarnings, OnSettingsChange);
	g_iNotifyWarnings = GetConVarInt(g_hNotifyWarnings);

	g_hNotifyTimeouts = CreateConVar("sm_warnings_notify_timeouts", "3", "The minimum number of timeouts needed to warn in-game administrators of connection. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hNotifyTimeouts, OnSettingsChange);
	g_iNotifyTimeouts = GetConVarInt(g_hNotifyTimeouts);

	g_hNotifyFlag = CreateConVar("sm_warnings_notify_admins_flag", "b", "Players with this flag currently in-game will be notified of a player connecting that meet warning criteria, if they do not have the defined override.", FCVAR_NONE);
	HookConVarChange(g_hNotifyFlag, OnSettingsChange);
	GetConVarString(g_hNotifyFlag, sBuffer, sizeof(sBuffer));
	g_iNotifyFlag = ReadFlagString(sBuffer);

	g_hNotifyOverride = CreateConVar("sm_warnings_notify_admins_override", "Player_Warnings_Notify", "Players with this override currently in-game will be notified of a player connecting that meet warning criteria. (\"\" = Disabled)", FCVAR_NONE);
	HookConVarChange(g_hNotifyOverride, OnSettingsChange);
	GetConVarString(g_hNotifyOverride, g_sNotifyOverride, sizeof(g_sNotifyOverride));

	g_hTimeFormat = CreateConVar("sm_warnings_time_format", "%m/%d/%y %H:%M:%S", "The formatting string to use for displaying time within the plugin. http://cplusplus.com/reference/ctime/strftime/", FCVAR_NONE);
	HookConVarChange(g_hTimeFormat, OnSettingsChange);
	GetConVarString(g_hTimeFormat, g_sTimeFormat, sizeof(g_sTimeFormat));
	
	AutoExecConfig(true, "sm_player_warnings");

	g_hShowActivity = FindConVar("sm_show_activity");
	HookConVarChange(g_hShowActivity, OnSettingsChange);
	g_iShowActivity = GetConVarInt(g_hShowActivity);

	RegAdminCmd("sm_warn", Command_Warn, ADMFLAG_GENERIC, "Usage: sm_warn <target> <reason:optional> | Issues a warning to the target.");
	RegAdminCmd("sm_timeout", Command_Time, ADMFLAG_GENERIC, "Usage: sm_timeout <target> <duration> <reason:optional> | Issues a timeout to the target.");
	RegAdminCmd("sm_forgive", Command_Forgive, ADMFLAG_GENERIC, "Usage: sm_forgive <target> | Removes a current timeout from the target.");
	RegAdminCmd("sm_warnlist", Command_List, ADMFLAG_GENERIC, "Usage: sm_warnlist | Displays a list of clients in timeout as well as total warning/timeout per client.");
	RegAdminCmd("sm_warnreset", Command_Reset, ADMFLAG_ROOT, "Usage: sm_warnreset <target> | Resets the total number of warnings and timeouts on specified target(s) and removes previous punishments.");
	RegAdminCmd("sm_warnpurge", Command_Purge, ADMFLAG_ROOT, "Usage: sm_warnpurge | Completely drops existing tables.");

	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);

	GetGameFolderName(sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "cstrike") || StrEqual(sBuffer, "csgo"))
	{
		AddCommandListener(Command_Join, "jointeam");
		AddCommandListener(Command_Join, "joinclass");
	}

	g_hCookie_Warnings = RegClientCookie("total_warnings", "The player's total number of warnings.", CookieAccess_Private);
	g_hCookie_Timeouts = RegClientCookie("total_timeouts", "The player's total number of timeouts.", CookieAccess_Private);
	g_hCookie_Duration = RegClientCookie("timeout_duration", "The current timeout's duration.", CookieAccess_Private);
	g_hCookie_Issue = RegClientCookie("timeout_issue", "The timestamp when the current timeout was issued.", CookieAccess_Private);
}

public OnMapStart()
{
	if(!StrEqual(g_sWarnSound, ""))
		PrecacheSound(g_sWarnSound, true);

	if(!StrEqual(g_sTimeSound, ""))
		PrecacheSound(g_sTimeSound, true);
}

public OnConfigsExecuted()
{
	if(!StrEqual(g_sLogging, ""))
	{
		if(g_hLogDatabase == INVALID_HANDLE)
			SQL_TConnect(SQL_ConnectLog, g_sLogging);
	}

	if(!StrEqual(g_sDatabase, ""))
	{
		if(g_hWarnDatabase == INVALID_HANDLE)
			SQL_TConnect(SQL_ConnectMain, g_sDatabase);
	}
	else if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iTotalPlayers++;
				g_iTeam[i] = GetClientTeam(i);
				GetClientAuthString(i, g_sSteam[i], sizeof(g_sSteam[]));

				if(!g_bLoaded[i] && AreClientCookiesCached(i))
					LoadCookies(i);
			}
		}

		g_bLateLoad = false;
	}
}

public OnClientConnected(client)
{
	g_iTotalPlayers++;
}

public OnClientPostAdminCheck(client)
{
	if(client > 0)
	{
		GetClientAuthString(client, g_sSteam[client], sizeof(g_sSteam[]));

		if(!StrEqual(g_sDatabase, ""))
		{
			decl String:sQuery[256];
			Format(sQuery, sizeof(sQuery), "SELECT total_warnings, total_timeouts, timeout_duration, timeout_issue FROM %s WHERE steam_id = '%s'", g_sDatabaseTable, g_sSteam[client]);
			SQL_TQuery(g_hWarnDatabase, SQL_LoadPlayerCall, sQuery, GetClientUserId(client));
		}
		else if(!g_bLoaded[client] && AreClientCookiesCached(client))
			LoadCookies(client);
	}
}

public OnClientDisconnect(client)
{
	g_iTotalPlayers--;
	g_iTeam[client] = 0;
	g_bLoaded[client] = false;

	if(g_bTimeout[client])
	{
		g_iTotalTimeouts--;
		g_bTimeout[client] = false;
	}

	if(g_hExpireNotice[client] != INVALID_HANDLE && CloseHandle(g_hExpireNotice[client]))
		g_hExpireNotice[client] = INVALID_HANDLE;
	if(g_hWarnNotice[client] != INVALID_HANDLE && CloseHandle(g_hWarnNotice[client]))
		g_hWarnNotice[client] = INVALID_HANDLE;
	if(g_hTimeoutNotice[client] != INVALID_HANDLE && CloseHandle(g_hTimeoutNotice[client]))
		g_hTimeoutNotice[client] = INVALID_HANDLE;

	g_iNumWarnings[client] = g_iNumTimeouts[client] = g_iTimeoutDuration[client] = g_iTimeoutIssue[client] = 0;
}

public OnClientCookiesCached(client)
{
	if(StrEqual(g_sDatabase, "") && !g_bLoaded[client])
	{
		LoadCookies(client);
	}
}

public Action:Command_Join(client, const String:command[], argc)
{
	if(client > 0 && IsClientInGame(client))
	{
		if(g_bTimeout[client])
		{
			if(g_iTeam[client] != TEAM_SPEC)
			{
				if(IsPlayerAlive(client))
					ForceSuicide(client);
				ChangeClientTeam(client, TEAM_SPEC);

				CreateTimer(0.1, Timer_ConfirmSpectate, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}

			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client))
	{
		g_iTeam[client] = GetEventInt(event, "team");
		if(g_bTimeout[client])
		{
			if(g_iTeam[client] != TEAM_SPEC)
			{
				if(IsPlayerAlive(client))
					ForceSuicide(client);
				ChangeClientTeam(client, TEAM_SPEC);

				CreateTimer(0.1, Timer_ConfirmSpectate, userid, TIMER_FLAG_NO_MAPCHANGE);
				SetEventBroadcast(event, true);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client) && g_iTeam[client] >= TEAM_RED)
	{
		if(g_bTimeout[client])
		{
			if(g_iTeam[client] != TEAM_SPEC)
			{
				ForceSuicide(client);
				ChangeClientTeam(client, TEAM_SPEC);
				CreateTimer(0.1, Timer_ConfirmSpectate, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_ConfirmSpectate(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client))
	{
		if(g_iTeam[client] != TEAM_SPEC)
		{
			ChangeClientTeam(client, TEAM_SPEC);
			CreateTimer(0.1, Timer_ConfirmSpectate, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Continue;
}

public Action:Command_Warn(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%t", "Command_Warn_Arguments");
		return Plugin_Handled;
	}

	new iCount, bool:bTemp;
	decl String:sBuffer[256], String:sTemp[256], String:sPattern[64], iTargets[MAXPLAYERS + 1];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	StripQuotes(sBuffer);

	new iStart = BreakString(sBuffer, sPattern, sizeof(sPattern));
	if((iCount = ProcessTargetString(sPattern, client, iTargets, sizeof(iTargets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, sTemp, sizeof(sTemp), bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	decl String:sReason[256];
	if(iStart == -1)
		strcopy(sReason, sizeof(sReason), "");
	else
		strcopy(sReason, sizeof(sReason), sBuffer[iStart]);

	for(new i = 0; i < iCount; i++)
	{
		if(IsClientInGame(iTargets[i]))
		{
			g_iNumWarnings[iTargets[i]]++;

			if(StrEqual(g_sDatabase, ""))
			{
				IntToString(g_iNumWarnings[iTargets[i]], sPattern, sizeof(sPattern));
				SetClientCookie(iTargets[i], g_hCookie_Warnings, sPattern);
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "UPDATE %s SET total_warnings = %d WHERE steam_id = '%s'", g_sDatabaseTable, g_iNumWarnings[iTargets[i]], g_sSteam[iTargets[i]]);
				SQL_TQuery(g_hWarnDatabase, SQL_SavePlayerCall, sBuffer, GetClientUserId(iTargets[i]));
			}

			if(!StrEqual(g_sWarnSound, ""))
				EmitSoundToClient(iTargets[i], g_sWarnSound);

			ShowActivity2(client, "[SM] ", "%T", "Command_Warn_Activity", client, iTargets[i]);
			LogAction(client, iTargets[i], "%T", "Command_Warn_Log", LANG_SERVER, client, iTargets[i]);

			PrintCenterText(iTargets[i], "%t%t", "Prefix_Center", "Notify_Warn_Center");
			CPrintToChat(iTargets[i], "%t%t", "Prefix_Chat", "Notify_Warn_Chat");
			if(!StrEqual(sReason, ""))
				CPrintToChat(iTargets[i], "%t%t", "Prefix_Chat", "Notify_Warn_Chat_Reason", sReason);

			if(!StrEqual(g_sLogging, ""))
			{
				decl String:sQuery[384];
				Format(sQuery, sizeof(sQuery), "INSERT INTO %s (steam_id, timestamp, action, admin, reason) VALUES ('%s', %d, %d, '%s', '%s')", g_sLoggingTable, g_sSteam[iTargets[i]], GetTime(), ACTION_WARN, g_sSteam[client], sReason);
				SQL_TQuery(g_hLogDatabase, SQL_LogAction, sQuery, _);
			}
			else
			{
				BuildPath(Path_SM, sBuffer, sizeof(sBuffer), g_sLoggingPath);
				LogToFileEx(sBuffer, "%N (%s) warned %N (%s), Time: %d, Reason: %s", client, g_sSteam[client], iTargets[i], g_sSteam[iTargets[i]], GetTime(), sReason);
			}

			if(!StrEqual(g_sWarnClientCmd, ""))
				FakeClientCommand(iTargets[i], "%s", g_sWarnClientCmd);

			if(!StrEqual(g_sWarnServerCmd, ""))
			{
				strcopy(sBuffer, sizeof(sBuffer), g_sWarnServerCmd);

				Format(sTemp, sizeof(sTemp), "%N", iTargets[i]);
				ReplaceString(sBuffer, sizeof(sBuffer), "{clientName}", sTemp, false);
				Format(sTemp, sizeof(sTemp), "#%d", GetClientUserId(iTargets[i]));
				ReplaceString(sBuffer, sizeof(sBuffer), "{clientUser}", sTemp, false);
				ReplaceString(sBuffer, sizeof(sBuffer), "{clientAuth}", g_sSteam[iTargets[i]], false);

				ServerCommand("%s", sBuffer);
			}

			if(!StrEqual(g_sWarnUrl, ""))
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Panel_Title_Warn", iTargets[i]);
				ShowMOTDPanel(iTargets[i], sBuffer, g_sWarnUrl, MOTDPANEL_TYPE_URL);
			}

			if(g_iWarnLength)
			{
				g_iNotifyCounter[iTargets[i]] = g_iWarnLength;
				CreateTimer(1.0, Timer_Notify_Warn, GetClientUserId(iTargets[i]), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_Time(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%t", "Command_Timeout_Arguments");
		return Plugin_Handled;
	}

	new iTime = GetTime(), iSeconds, iStart, iCount, bool:bTemp;
	decl String:sBuffer[256], String:sPattern[64], String:sTemp[256], iTargets[MAXPLAYERS + 1];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	StripQuotes(sBuffer);

	iStart = BreakString(sBuffer, sPattern, sizeof(sPattern));
	if(iStart == -1)
		iSeconds = g_iTimeDefault;
	else
	{
		iStart += BreakString(sBuffer[iStart], sTemp, sizeof(sTemp));
		iSeconds = StringToInt(sTemp) * 60;
		if(iSeconds <= 0 || iSeconds > 31556926)
			iSeconds = g_iTimeDefault;
	}

	if((iCount = ProcessTargetString(sPattern, client, iTargets, sizeof(iTargets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, sTemp, sizeof(sTemp), bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	decl String:sReason[192];
	if(iStart == -1)
		strcopy(sReason, sizeof(sReason), "");
	else
		strcopy(sReason, sizeof(sReason), sBuffer[iStart]);

	for (new i = 0; i < iCount; i++)
	{
		if(IsClientInGame(iTargets[i]))
		{
			g_iNumTimeouts[iTargets[i]]++;
			g_iTimeoutIssue[iTargets[i]] = iTime;
			g_iTimeoutDuration[iTargets[i]] = iSeconds;

			if(StrEqual(g_sDatabase, ""))
			{
				IntToString(g_iNumTimeouts[iTargets[i]], sPattern, sizeof(sPattern));
				SetClientCookie(iTargets[i], g_hCookie_Timeouts, sPattern);

				IntToString(g_iTimeoutIssue[iTargets[i]], sPattern, sizeof(sPattern));
				SetClientCookie(iTargets[i], g_hCookie_Issue, sPattern);

				IntToString(g_iTimeoutDuration[iTargets[i]], sPattern, sizeof(sPattern));
				SetClientCookie(iTargets[i], g_hCookie_Duration, sPattern);
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "UPDATE %s SET total_timeouts = %d, timeout_duration = %d, timeout_issue = %d WHERE steam_id = '%s'", g_sDatabaseTable, g_iNumTimeouts[iTargets[i]], g_iTimeoutDuration[iTargets[i]], g_iTimeoutIssue[iTargets[i]], g_sSteam[iTargets[i]]);
				SQL_TQuery(g_hWarnDatabase, SQL_SavePlayerCall, sBuffer, GetClientUserId(iTargets[i]));
			}

			if(!StrEqual(g_sTimeSound, ""))
				EmitSoundToClient(iTargets[i], g_sTimeSound);

			ShowActivity2(client, "[SM] ", "%T", "Command_Timeout_Activity", LANG_SERVER, iTargets[i], iSeconds);
			LogAction(client, iTargets[i], "%T", "Command_Timeout_Log", LANG_SERVER, client, iTargets[i], iSeconds);

			new iRemaining = (g_iTimeoutIssue[iTargets[i]] + g_iTimeoutDuration[iTargets[i]]) - iTime;
			PrintCenterText(client, "%t%t", "Prefix_Center", "Notify_Timeout_Center", iRemaining);
			CPrintToChat(client, "%t%t", "Prefix_Chat", "Notify_Timeout_Chat", iRemaining);
			if(!StrEqual(sReason, ""))
				CPrintToChat(iTargets[i], "%t%t", "Prefix_Chat", "Notify_Timeout_Chat_Reason", sReason);

			if(!StrEqual(g_sLogging, ""))
			{
				decl String:sQuery[512];
				Format(sQuery, sizeof(sQuery), "INSERT INTO %s (steam_id, timestamp, action, admin, reason) VALUES ('%s', %d, %d, '%s', '%s')", g_sLoggingTable, g_sSteam[iTargets[i]], GetTime(), ACTION_TIME, g_sSteam[client], sReason);
				SQL_TQuery(g_hLogDatabase, SQL_LogAction, sQuery, _);
			}
			else
			{
				BuildPath(Path_SM, sBuffer, sizeof(sBuffer), g_sLoggingPath);
				LogToFileEx(sBuffer, "%N (%s) placed %N (%s) in Timeout, Time: %d, Reason: %s", client, g_sSteam[client], iTargets[i], g_sSteam[iTargets[i]], GetTime(), sReason);
			}

			if(g_iTeam[iTargets[i]] != TEAM_SPEC)
			{
				if(IsPlayerAlive(iTargets[i]))
					ForceSuicide(iTargets[i]);

				ChangeClientTeam(iTargets[i], TEAM_SPEC);
			}

			IssueClientTimeout(iTargets[i]);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Forgive(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%t", "Command_Forgive_Arguments");
		return Plugin_Handled;
	}

	new iCount, bool:bTemp;
	decl iTargets[MAXPLAYERS + 1], String:sPattern[64], String:sBuffer[192];
	GetCmdArg(1, sPattern, sizeof(sPattern));
	if((iCount = ProcessTargetString(sPattern, client, iTargets, sizeof(iTargets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, sBuffer, sizeof(sBuffer), bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	for(new i = 0; i < iCount; i++)
	{
		if(IsClientInGame(iTargets[i]) && g_bTimeout[iTargets[i]])
		{
			g_iTotalTimeouts--;
			g_bTimeout[iTargets[i]] = false;
			g_iTimeoutIssue[iTargets[i]] = g_iTimeoutDuration[iTargets[i]] = 0;

			CPrintToChat(iTargets[i], "%t%t", "Prefix_Chat", "Command_Forgive_Chat");
			PrintCenterText(iTargets[i], "%t%t", "Prefix_Center", "Command_Forgive_Center");
			ShowActivity2(client, "[SM] ", "%T", "Command_Forgive_Activity", client, iTargets[i]);
			LogAction(client, iTargets[i], "%T", "Command_Forgive_Log", LANG_SERVER, client, iTargets[i]);

			if(StrEqual(g_sDatabase, ""))
			{
				SetClientCookie(iTargets[i], g_hCookie_Issue, "0");
				SetClientCookie(iTargets[i], g_hCookie_Duration, "0");
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "UPDATE %s SET timeout_duration = %d, timeout_issue = %d WHERE steam_id = '%s'", g_sDatabaseTable, g_iTimeoutDuration[iTargets[i]], g_iTimeoutIssue[iTargets[i]], g_sSteam[iTargets[i]]);
				SQL_TQuery(g_hWarnDatabase, SQL_SavePlayerCall, sBuffer, GetClientUserId(iTargets[i]));
			}

			if(g_hTimeoutNotice[iTargets[i]] != INVALID_HANDLE && CloseHandle(g_hTimeoutNotice[iTargets[i]]))
				g_hTimeoutNotice[iTargets[i]] = INVALID_HANDLE;
			if(g_hExpireNotice[iTargets[i]] != INVALID_HANDLE && CloseHandle(g_hExpireNotice[iTargets[i]]))
				g_hExpireNotice[iTargets[i]] = INVALID_HANDLE;
			ServerCommand("sm_show_activity 0;sm_unsilence #%d;sm_show_activity %d", GetClientUserId(iTargets[i]), g_iShowActivity);
		}
	}

	return Plugin_Handled;
}

public Action:Command_List(client, args)
{
	if(!client)
		ReplyToCommand(client, "%t%t", "Prefix_Center", "Command_List_Game_Only");
	else
		Menu_Display(client);
}

public Action:Command_Purge(client, args)
{
	decl String:sQuery[192];
	Format(sQuery, sizeof(sQuery), "DROP TABLE %s", g_sDatabaseTable);
	SQL_TQuery(g_hWarnDatabase, CallBack_ResetContest, sQuery);
	
	Format(sQuery, sizeof(sQuery), "DROP TABLE %s", g_sLoggingTable);
	SQL_TQuery(g_hLogDatabase, CallBack_ResetContest, sQuery);
}


public CallBack_ResetContest(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("The table purge could not be completed!");
		LogError("- Source: CallBack_ResetContest");
	}
}

public Action:Command_Reset(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%t", "Command_Reset_Arguments");
		return Plugin_Handled;
	}

	new iCount, bool:bTemp;
	decl iTargets[MAXPLAYERS + 1], String:sPattern[64], String:sBuffer[192];
	GetCmdArg(1, sPattern, sizeof(sPattern));
	if((iCount = ProcessTargetString(sPattern, client, iTargets, sizeof(iTargets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, sBuffer, sizeof(sBuffer), bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	for(new i = 0; i < iCount; i++)
	{
		if(IsClientInGame(iTargets[i]))
		{
			if(g_bTimeout[iTargets[i]])
			{
				g_iTotalTimeouts--;
				g_bTimeout[iTargets[i]] = false;
				CPrintToChat(iTargets[i], "%t%t", "Prefix_Chat", "Command_Forgive_Chat");
				PrintCenterText(iTargets[i], "%t%t", "Prefix_Center", "Command_Forgive_Center");
				ShowActivity2(client, "[SM] ", "%T", "Command_Forgive_Activity", client, iTargets[i]);
				LogAction(client, iTargets[i], "%T", "Command_Forgive_Log", LANG_SERVER, client, iTargets[i]);

				ServerCommand("sm_show_activity 0;sm_unsilence #%d;sm_show_activity %d", GetClientUserId(iTargets[i]), g_iShowActivity);
				if(g_hTimeoutNotice[iTargets[i]] != INVALID_HANDLE && CloseHandle(g_hTimeoutNotice[iTargets[i]]))
					g_hTimeoutNotice[iTargets[i]] = INVALID_HANDLE;
				if(g_hExpireNotice[iTargets[i]] != INVALID_HANDLE && CloseHandle(g_hExpireNotice[iTargets[i]]))
					g_hExpireNotice[iTargets[i]] = INVALID_HANDLE;
			}

			g_iNumWarnings[iTargets[i]] = g_iNumTimeouts[iTargets[i]] = g_iTimeoutIssue[iTargets[i]] = g_iTimeoutDuration[iTargets[i]] = 0;
			if(StrEqual(g_sDatabase, ""))
			{
				SetClientCookie(iTargets[i], g_hCookie_Warnings, "0");
				SetClientCookie(iTargets[i], g_hCookie_Timeouts, "0");
				SetClientCookie(iTargets[i], g_hCookie_Issue, "0");
				SetClientCookie(iTargets[i], g_hCookie_Duration, "0");
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "REPLACE INTO %s (steam_id, total_warnings, total_timeouts, timeout_duration, timeout_issue) VALUES ('%s', %d, %d, %d, %d)", g_sDatabaseTable, g_sSteam[iTargets[i]], g_iNumWarnings[iTargets[i]], g_iNumTimeouts[iTargets[i]], g_iTimeoutDuration[iTargets[i]], g_iTimeoutIssue[iTargets[i]]);
				SQL_TQuery(g_hWarnDatabase, SQL_SavePlayerCall, sBuffer, GetClientUserId(iTargets[i]));
			}
			
			if(!StrEqual(g_sLogging, ""))
			{
				Format(sBuffer, sizeof(sBuffer), "DELETE FROM %s WHERE steam_id = '%s'", g_sLoggingTable, g_sSteam[iTargets[i]]);
				SQL_TQuery(g_hLogDatabase, SQL_LogAction, sBuffer, _);
			}
		}
	}

	return Plugin_Continue;
}

Menu_Display(client, index = 0, list = false)
{
	decl String:sTitle[192], String:sOption[8];
	Format(sTitle, sizeof(sTitle), "%T", "Menu_Warning_Title_List", client);
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuDisplay);
	SetMenuTitle(_hMenu, sTitle);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, false);

	if(!list && g_iTotalTimeouts && g_iTotalPlayers > 1)
	{
		Format(sTitle, sizeof(sTitle), "%T", "List_Display_Current", client);
		AddMenuItem(_hMenu, "-1", sTitle);

		Format(sTitle, sizeof(sTitle), "%T", "List_Display_Total", client);
		AddMenuItem(_hMenu, "0", sTitle);
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(sOption, sizeof(sOption), "%d", GetClientUserId(i));

				Format(sTitle, sizeof(sTitle), "%T", "List_Total_Display_Name", client, i, g_iNumWarnings[i], g_iNumTimeouts[i]);
				AddMenuItem(_hMenu, sOption, sTitle);
			}
		}
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:sOption[32];
			GetMenuItem(menu, param2, sOption, sizeof(sOption));
			new target = StringToInt(sOption);

			g_iPeskyMenus[param1][0] = GetMenuSelectionPosition(); 
			if(target <= 0)
			{
				if(!target)
					Menu_Display(param1, g_iPeskyMenus[param1][0], true);
				else
					Menu_DisplayCurrent(param1);
			}
			else
			{
				g_iPeskyMenus[param1][1] = target;
				target = GetClientOfUserId(target);
				if(target > 0 && IsClientInGame(target))
					Menu_DisplayTarget(param1, target);
				else
					Menu_Display(param1, g_iPeskyMenus[param1][0]);
			}
		}
	}
}

Menu_DisplayTarget(client, target)
{
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuDisplayTarget);
	decl String:sBuffer[192], String:sName[32], String:sTemp[32];
	GetClientName(target, sName, sizeof(sName));
	SetMenuTitle(_hMenu, sName);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	if(!StrEqual(g_sLogging, ""))
	{
		Format(sBuffer, sizeof(sBuffer), "%T", "List_Past_Punishments", client);
		AddMenuItem(_hMenu, "", sBuffer);
	}
	
	Format(sBuffer, sizeof(sBuffer), "%T", "List_Total_Warnings", client, g_iNumWarnings[target]);
	AddMenuItem(_hMenu, "", sBuffer, ITEMDRAW_DISABLED);

	Format(sBuffer, sizeof(sBuffer), "%T", "List_Total_Timeouts", client, g_iNumTimeouts[target]);
	AddMenuItem(_hMenu, "", sBuffer, ITEMDRAW_DISABLED);

	if(g_bTimeout[target])
	{
		Format(sBuffer, sizeof(sBuffer), "%T", "List_Timeout_Current", client);
		AddMenuItem(_hMenu, "", sBuffer, ITEMDRAW_DISABLED);

		Format(sBuffer, sizeof(sBuffer), "%T", "List_Current_Duration", client, g_iTimeoutDuration[target]);
		AddMenuItem(_hMenu, "", sBuffer, ITEMDRAW_DISABLED);

		FormatTime(sTemp, sizeof(sTemp), NULL_STRING, g_iTimeoutIssue[target]);
		Format(sBuffer, sizeof(sBuffer), "%T", "List_Current_Issue", client, sTemp);
		AddMenuItem(_hMenu, "", sBuffer, ITEMDRAW_DISABLED);

		FormatTime(sTemp, sizeof(sTemp), NULL_STRING, (g_iTimeoutIssue[target] + g_iTimeoutDuration[target]));
		Format(sBuffer, sizeof(sBuffer), "%T", "List_Current_Expire", client, sTemp);
		AddMenuItem(_hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	else
	{
		Format(sBuffer, sizeof(sBuffer), "%T", "List_Timeout_Inactive", client);
		AddMenuItem(_hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuDisplayTarget(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if(param2 <= MenuCancel_Exit)
				Menu_Display(param1, g_iPeskyMenus[param1][0]);
		}
		case MenuAction_Select:
		{
			new iTarget = GetClientOfUserId(g_iPeskyMenus[param1][1]);
			if(iTarget && IsClientInGame(iTarget))
			{
				decl String:sQuery[256];
				Format(sQuery, sizeof(sQuery), "SELECT * FROM %s WHERE steam_id = '%s'", g_sLoggingTable, g_sSteam[iTarget]);
				SQL_TQuery(g_hLogDatabase, SQL_ListPastActions, sQuery, GetClientUserId(param1));
			}
			else
				Menu_Display(param1, g_iPeskyMenus[param1][0]);
		}
	}
}

public SQL_ListPastActions(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("The query string for listing past actions could not be executed!");
		LogError("- Source: SQL_ListPastActions");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[512];
			SQL_GetError(hndl, _sError, 512);
			LogError("- Error: %s", _sError);
		}
		else
			LogError("- Error: %s", error);
	}
	else
	{
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client))
			return;

		new iTarget = GetClientOfUserId(g_iPeskyMenus[client][1]);
		if(!iTarget || !IsClientInGame(iTarget))
		{
			Menu_Display(client, g_iPeskyMenus[client][0]);
			return;
		}
		
		if(!SQL_GetRowCount(hndl))
		{
			CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_List_Past_Punishments_Null");
			Menu_DisplayTarget(client, iTarget);
		}
		else
		{
			decl String:sBuffer[256], String:sTemp[12], String:sAdmin[24], String:sTime[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Warning_Title_List", client, iTarget);
			new Handle:hMenu = CreateMenu(MenuHandler_PastDisplay);
			SetMenuTitle(hMenu, sBuffer);

			while(SQL_FetchRow(hndl))
			{
				new iLog = SQL_FetchInt(hndl, 0);
				new iAction = SQL_FetchInt(hndl, 2);
				new iTime = SQL_FetchInt(hndl, 3);
				SQL_FetchString(hndl, 5, sAdmin, sizeof(sAdmin));

				FormatTime(sTime, sizeof(sTime), g_sTimeFormat, iTime);
				if(iAction == ACTION_WARN)
					Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Past_Option_Warn", client, sTime, sAdmin);
				else
					Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Past_Option_Time", client, sTime, sAdmin);
				IntToString(iLog, sTemp, sizeof(sTemp));
				AddMenuItem(hMenu, sTemp, sBuffer);
			}
			
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler_PastDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if(param2 <= MenuCancel_Exit)
			{
				new iTarget = GetClientOfUserId(g_iPeskyMenus[param1][1]);
				if(iTarget && IsClientInGame(iTarget))
					Menu_DisplayTarget(param1, iTarget);
				else
					Menu_Display(param1, g_iPeskyMenus[param1][0]);
			}
		}
		case MenuAction_Select:
		{
			decl String:sOption[12], String:sQuery[128];
			GetMenuItem(menu, param2, sOption, sizeof(sOption));
			
			Format(sQuery, sizeof(sQuery), "SELECT action,reason FROM %s WHERE log_index = %d", g_sLoggingTable, StringToInt(sOption));
			SQL_TQuery(g_hLogDatabase, SQL_ListPastReason, sQuery, GetClientUserId(param1));
		}
	}
}

public SQL_ListPastReason(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("The query string for displaying past action reason could not be executed!");
		LogError("- Source: SQL_LogAction");
		if(hndl != INVALID_HANDLE)
		{
			decl String:sError[512];
			SQL_GetError(hndl, sError, 512);
			LogError("- Error: %s", sError);
		}
		else
			LogError("- Error: %s", error);
	}
	else
	{
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client))
			return;
			
		if(SQL_FetchRow(hndl))
		{
			decl String:sReason[192];
			new iAction = SQL_FetchInt(hndl, 0);
			SQL_FetchString(hndl, 1, sReason, sizeof(sReason));
			
			if(StrEqual(sReason, ""))
				CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Default_Reason");
			else
			{			
				if(iAction == ACTION_WARN)
					CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_List_Past_Warning", sReason);
				else
					CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_List_Past_Time", sReason);
			}
		}

		new iTarget = GetClientOfUserId(g_iPeskyMenus[client][1]);
		if(iTarget && IsClientInGame(iTarget))
			Menu_DisplayTarget(client, iTarget);
		else
			Menu_Display(client, g_iPeskyMenus[client][0]);
	}
}

Menu_DisplayCurrent(client)
{
	decl String:sTitle[192], String:sName[32], String:sOption[8];
	Format(sTitle, sizeof(sTitle), "%T", "Menu_Warning_Title_Current", client);
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuDisplayCurrent);
	SetMenuTitle(_hMenu, sTitle);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, false);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_bTimeout[i])
		{
			Format(sOption, sizeof(sOption), "%d", GetClientUserId(i));

			GetClientName(i, sName, sizeof(sName));
			AddMenuItem(_hMenu, sOption, sName);
		}
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuDisplayCurrent(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if(param2 <= MenuCancel_Exit)
				Menu_Display(param1, g_iPeskyMenus[param1][0], true);
		}
		case MenuAction_Select:
		{
			decl String:sOption[32];
			GetMenuItem(menu, param2, sOption, sizeof(sOption));
			new target = GetClientOfUserId(StringToInt(sOption));

			if(target > 0 && IsClientInGame(target))
				Menu_DisplayTarget(param1, target);
			else
				Menu_DisplayCurrent(param1);
		}
	}
}

ForceSuicide(client)
{
	new _iEnt = CreateEntityByName("point_hurt");
	if(_iEnt > 0 && IsValidEdict(_iEnt))
	{
		decl String:sName[64];
		GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
		DispatchKeyValue(client, "targetname", "StartPlayerSuicide");
		DispatchKeyValue(_iEnt, "DamageTarget", "StartPlayerSuicide");
		DispatchKeyValue(_iEnt, "Damage", "100000");
		DispatchKeyValue(_iEnt, "DamageType", "0");
		DispatchSpawn(_iEnt);

		AcceptEntityInput(_iEnt, "Hurt");
		if(StrEqual(sName, "", false))
			DispatchKeyValue(client, "targetname", "StopPlayerSuicide");
		else
			DispatchKeyValue(client, "targetname", sName);
		AcceptEntityInput(_iEnt, "Kill");
	}
}

public SQL_ConnectMain(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Player Warnings was unable to connect to the provided database!");
		LogError("- Source: SQL_ConnectMain");
		if(hndl != INVALID_HANDLE)
		{
			decl String:sError[512];
			SQL_GetError(hndl, sError, 512);
			LogError("- Error: %s", sError);
		}
		else if(strlen(error) > 0)
			LogError("- Error: %s", error);
	}
	else
	{
		SQL_LockDatabase(hndl);
		decl String:sQuery[512];
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (steam_id varchar(24) PRIMARY KEY default '', total_warnings int(8) NOT NULL default 0, total_timeouts int(8) NOT NULL default 0, timeout_duration int(12) NOT NULL default 0, timeout_issue int(12) NOT NULL default 0)", g_sDatabaseTable);
		if(!SQL_FastQuery(hndl, sQuery))
		{
			SQL_GetError(hndl, sQuery, 512);

			LogError("The query string for creating the main table could not be executed!");
			LogError("- Source: SQL_ConnectMain");
			LogError("- Error: %s", sQuery);
			CloseHandle(hndl);
			return;
		}
		SQL_UnlockDatabase(hndl);
		g_hWarnDatabase = hndl;

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTotalPlayers++;
					g_iTeam[i] = GetClientTeam(i);
					GetClientAuthString(i, g_sSteam[i], sizeof(g_sSteam[]));

					Format(sQuery, sizeof(sQuery), "SELECT total_warnings, total_timeouts, timeout_duration, timeout_issue FROM %s WHERE steam_id = '%s'", g_sDatabaseTable, g_sSteam[i]);
					SQL_TQuery(g_hWarnDatabase, SQL_LoadPlayerCall, sQuery, GetClientUserId(i));
				}
			}

			g_bLateLoad = false;
		}
	}
}

public SQL_LoadPlayerCall(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("The query string for loading the client could not be executed!");
		LogError("- Source: SQL_LoadPlayerCall");
		if(hndl != INVALID_HANDLE)
		{
			decl String:sError[512];
			SQL_GetError(hndl, sError, 512);
			LogError("- Error: %s", sError);
		}
		else
			LogError("- Error: %s", error);
	}
	else
	{
		new client = GetClientOfUserId(userid);
		if(client > 0 && IsClientInGame(client))
		{
			if(SQL_FetchRow(hndl))
			{
				g_iNumWarnings[client] = SQL_FetchInt(hndl, 0);
				g_iNumTimeouts[client] = SQL_FetchInt(hndl, 1);
				g_iTimeoutDuration[client] = SQL_FetchInt(hndl, 2);
				g_iTimeoutIssue[client] = SQL_FetchInt(hndl, 3);

				if(!CheckCommandAccess(client, "Player_Warnings_Ignore", ADMFLAG_GENERIC))
				{
					if(g_iNotifyWarnings && g_iNumWarnings[client] >= g_iNotifyWarnings && g_iNotifyTimeouts && g_iNumTimeouts[client] >= g_iNotifyTimeouts)
					{
						for(new i = 1; i <= MaxClients; i++)
							if(i != client && IsClientInGame(i) && CheckCommandAccess(i, g_sNotifyOverride, g_iNotifyFlag))
								CPrintToChat(i, "%t", "Notify_Connect_Naughty_Very", client, g_iNumWarnings[client], g_iNumTimeouts[client]);
					}
					else if(g_iNotifyTimeouts && g_iNumTimeouts[client] >= g_iNotifyTimeouts)
					{
						for(new i = 1; i <= MaxClients; i++)
							if(i != client && IsClientInGame(i) && CheckCommandAccess(i, g_sNotifyOverride, g_iNotifyFlag))
								CPrintToChat(i, "%t", "Notify_Connect_Naughty_Timeouts", client, g_iNumTimeouts[client]);
					}
					else if(g_iNotifyWarnings && g_iNumWarnings[client] >= g_iNotifyWarnings)
					{
						for(new i = 1; i <= MaxClients; i++)
							if(i != client && IsClientInGame(i) && CheckCommandAccess(i, g_sNotifyOverride, g_iNotifyFlag))
								CPrintToChat(i, "%t", "Notify_Connect_Naughty_Warnings", client, g_iNumWarnings[client]);
					}
				}

				if((g_iTimeoutIssue[client] + g_iTimeoutDuration[client]) > GetTime())
					IssueClientTimeout(client);
				else
					g_iTimeoutDuration[client] = g_iTimeoutIssue[client] = 0;
			}
		}
	}
}

public SQL_SavePlayerCall(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("The query string for saving the client could not be executed!");
		LogError("- Source: SQL_SavePlayerCall");
		if(hndl != INVALID_HANDLE)
		{
			decl String:sError[512];
			SQL_GetError(hndl, sError, 512);
			LogError("- Error: %s", sError);
		}
		else
			LogError("- Error: %s", error);
	}
}

public SQL_LogAction(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("The query string for logging actions could not be executed!");
		LogError("- Source: SQL_LogAction");
		if(hndl != INVALID_HANDLE)
		{
			decl String:sError[512];
			SQL_GetError(hndl, sError, 512);
			LogError("- Error: %s", sError);
		}
		else
			LogError("- Error: %s", error);
	}
}

public SQL_ConnectLog(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Player Warnings was unable to connect to the provided logging database!");
		LogError("- Source: SQL_ConnectMain");
		if(hndl != INVALID_HANDLE)
		{
			decl String:sError[512];
			SQL_GetError(hndl, sError, 512);
			LogError("- Error: %s", sError);
		}
		else if(strlen(error) > 0)
			LogError("- Error: %s", error);
	}
	else
	{
		SQL_LockDatabase(hndl);
		decl String:sQuery[512], String:sTemp[16];

		SQL_GetDriverIdent(owner, sTemp, sizeof(sTemp));
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS %s (log_index INTEGER PRIMARY KEY %s, steam_id varchar(24) default '', action int(12) NOT NULL default 0, timestamp int(12) NOT NULL default 0, reason varchar(192) default '', admin varchar(24) default '')", g_sLoggingTable, StrEqual(sTemp, "sqlite") ? "AUTOINCREMENT" : "AUTO_INCREMENT");
		if(!SQL_FastQuery(hndl, sQuery))
		{
			SQL_GetError(hndl, sQuery, 512);

			LogError("The query string for creating the logging table could not be executed!");
			LogError("- Source: SQL_ConnectLog");
			LogError("- Error: %s", sQuery);
			CloseHandle(hndl);
			return;
		}
		SQL_UnlockDatabase(hndl);
		g_hLogDatabase = hndl;
	}
}

LoadCookies(client)
{
	decl String:_sCookie[16] = "";
	GetClientCookie(client, g_hCookie_Warnings, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, "", false))
	{
		SetClientCookie(client, g_hCookie_Warnings, "0");
		SetClientCookie(client, g_hCookie_Timeouts, "0");
		SetClientCookie(client, g_hCookie_Duration, "0");
		SetClientCookie(client, g_hCookie_Issue, "0");
	}
	else
	{
		g_iNumWarnings[client] = StringToInt(_sCookie);

		GetClientCookie(client, g_hCookie_Timeouts, _sCookie, sizeof(_sCookie));
		g_iNumTimeouts[client] = StringToInt(_sCookie);

		GetClientCookie(client, g_hCookie_Duration, _sCookie, sizeof(_sCookie));
		g_iTimeoutDuration[client] = StringToInt(_sCookie);

		GetClientCookie(client, g_hCookie_Issue, _sCookie, sizeof(_sCookie));
		g_iTimeoutIssue[client] = StringToInt(_sCookie);

		new _iTime = GetTime();
		new _iDuration =  g_iTimeoutDuration[client] + g_iTimeoutIssue[client];
		if(_iDuration > _iTime)
			IssueClientTimeout(client);
		else
		{
			g_iTimeoutDuration[client] = g_iTimeoutIssue[client] = 0;
			SetClientCookie(client, g_hCookie_Duration, "0");
			SetClientCookie(client, g_hCookie_Issue, "0");
		}
	}

	g_bLoaded[client] = true;
}

IssueClientTimeout(client)
{
	if(!g_bTimeout[client])
		g_iTotalTimeouts++;

	decl String:sBuffer[192];
	g_bTimeout[client] = true;
	new _iRemaining = (g_iTimeoutIssue[client] + g_iTimeoutDuration[client]) - GetTime();
	g_hExpireNotice[client] = CreateTimer(float(_iRemaining), Timer_Timeout_Expire, client, TIMER_FLAG_NO_MAPCHANGE);
	ServerCommand("sm_show_activity 0;sm_silence #%d;sm_show_activity %d", GetClientUserId(client), g_iShowActivity);

	if(!StrEqual(g_sTimeClientCmd, ""))
		FakeClientCommand(client, "%s", g_sTimeClientCmd);

	if(!StrEqual(g_sTimeServerCmd, ""))
	{
		decl String:sTemp[32];
		strcopy(sBuffer, sizeof(sBuffer), g_sTimeServerCmd);

		Format(sTemp, sizeof(sTemp), "%N", client);
		ReplaceString(sBuffer, sizeof(sBuffer), "{clientName}", sTemp, false);
		Format(sTemp, sizeof(sTemp), "#%d", GetClientUserId(client));
		ReplaceString(sBuffer, sizeof(sBuffer), "{clientUser}", sTemp, false);
		ReplaceString(sBuffer, sizeof(sBuffer), "{clientAuth}", g_sSteam[client], false);

		ServerCommand("%s", sBuffer);
	}

	if(!StrEqual(g_sTimeUrl, ""))
	{
		Format(sBuffer, sizeof(sBuffer), "%T", "Panel_Title_Timeout", client);
		ShowMOTDPanel(client, sBuffer, g_sTimeUrl, MOTDPANEL_TYPE_URL);
	}

	if(g_bNotifyTimeout)
	{
		if(g_hTimeoutNotice[client] != INVALID_HANDLE)
			CloseHandle(g_hTimeoutNotice[client]);

		g_iNotifyCounter[client] = _iRemaining;
		g_hTimeoutNotice[client] = CreateTimer(1.0, Timer_Notify_Timeout, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Timeout_Expire(Handle:timer, any:client)
{
	g_iTotalTimeouts--;
	g_bTimeout[client] = false;
	g_hExpireNotice[client] = INVALID_HANDLE;

	if(IsClientInGame(client))
	{
		g_iTimeoutIssue[client] = g_iTimeoutDuration[client] = 0;
		if(StrEqual(g_sDatabase, ""))
		{
			SetClientCookie(client, g_hCookie_Duration, "0");
			SetClientCookie(client, g_hCookie_Issue, "0");
		}

		ServerCommand("sm_show_activity 0;sm_unsilence #%d;sm_show_activity %d", GetClientUserId(client), g_iShowActivity);
		CPrintToChat(client, "%t%t", "Prefix_Chat", "Notify_Expire_Chat");
		PrintCenterText(client, "%t%t", "Prefix_Center", "Notify_Expire_Center");

		if(g_iExpireLength)
		{
			g_iNotifyCounter[client] = g_iExpireLength;
			g_hTimeoutNotice[client] = CreateTimer(1.0, Timer_Notify_Expire, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_Notify_Timeout(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		g_iNotifyCounter[client]--;
		if(g_iNotifyCounter[client] > 0)
		{
			PrintCenterText(client, "%t%t", "Prefix_Center", "Notify_Timeout_Center", g_iNotifyCounter[client]);
			return Plugin_Continue;
		}
	}

	g_hTimeoutNotice[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_Notify_Warn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client))
	{
		g_iNotifyCounter[client]--;
		if(g_iNotifyCounter[client] > 0)
		{
			PrintCenterText(client, "%t%t", "Prefix_Center", "Notify_Warn_Center", g_iNotifyCounter[client]);
			return Plugin_Continue;
		}
	}

	g_hWarnNotice[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_Notify_Expire(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		g_iNotifyCounter[client]--;
		if(g_iNotifyCounter[client] > 0)
		{
			PrintCenterText(client, "%t%t", "Prefix_Center", "Notify_Expire_Center");
			return Plugin_Continue;
		}
	}

	g_hTimeoutNotice[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hWarnLength)
		g_iWarnLength = StringToInt(newvalue);
	else if(cvar == g_hNotifyTimeout)
		g_bNotifyTimeout = bool:StringToInt(newvalue);
	else if(cvar == g_hTimeDefault)
		g_iTimeDefault = StringToInt(newvalue);
	else if(cvar == g_hExpireLength)
		g_iExpireLength = StringToInt(newvalue);
	else if(cvar == g_hDatabase)
	{
		strcopy(g_sDatabase, sizeof(g_sDatabase), newvalue);
		if(g_hWarnDatabase != INVALID_HANDLE)
			CloseHandle(g_hWarnDatabase);

		if(!StrEqual(g_sDatabase, ""))
			SQL_TConnect(SQL_ConnectMain, g_sDatabase);
	}
	else if(cvar == g_hDatabaseTable)
		strcopy(g_sDatabaseTable, sizeof(g_sDatabaseTable), newvalue);
	else if(cvar == g_hLogging)
	{
		strcopy(g_sLogging, sizeof(g_sLogging), newvalue);
		if(g_hLogDatabase != INVALID_HANDLE)
			CloseHandle(g_hLogDatabase);

		if(!StrEqual(g_sLogging, ""))
			SQL_TConnect(SQL_ConnectLog, g_sLogging);
	}
	else if(cvar == g_hLoggingTable)
		strcopy(g_sLoggingTable, sizeof(g_sLoggingTable), newvalue);
	else if(cvar == g_hLoggingPath)
		strcopy(g_sLoggingPath, sizeof(g_sLoggingPath), newvalue);
	else if(cvar == g_hWarnClientCmd)
		strcopy(g_sWarnClientCmd, sizeof(g_sWarnClientCmd), newvalue);
	else if(cvar == g_hWarnServerCmd)
		strcopy(g_sWarnServerCmd, sizeof(g_sWarnServerCmd), newvalue);
	else if(cvar == g_hWarnUrl)
		strcopy(g_sWarnUrl, sizeof(g_sWarnUrl), newvalue);
	else if(cvar == g_hTimeClientCmd)
		strcopy(g_sTimeClientCmd, sizeof(g_sTimeClientCmd), newvalue);
	else if(cvar == g_hTimeServerCmd)
		strcopy(g_sTimeServerCmd, sizeof(g_sTimeServerCmd), newvalue);
	else if(cvar == g_hTimeUrl)
		strcopy(g_sTimeUrl, sizeof(g_sTimeUrl), newvalue);
	else if(cvar == g_hWarnSound)
	{
		strcopy(g_sWarnSound, sizeof(g_sWarnSound), newvalue);
		if(!StrEqual(g_sWarnSound, ""))
			PrecacheSound(g_sWarnSound);
	}
	else if(cvar == g_hTimeSound)
	{
		strcopy(g_sTimeSound, sizeof(g_sTimeSound), newvalue);
		if(!StrEqual(g_sTimeSound, ""))
			PrecacheSound(g_sTimeSound);
	}
	else if(cvar == g_hShowActivity)
	{
		if(StringToInt(newvalue))
			g_iShowActivity = StringToInt(newvalue);
	}
	else if(cvar == g_hNotifyFlag)
		g_iNotifyFlag = ReadFlagString(newvalue);
	else if(cvar == g_hTimeSound)
		strcopy(g_sNotifyOverride, sizeof(g_sNotifyOverride), newvalue);
	else if(cvar == g_hNotifyWarnings)
		g_iNotifyWarnings = StringToInt(newvalue);
	else if(cvar == g_hNotifyTimeouts)
		g_iNotifyTimeouts = StringToInt(newvalue);
	else if(cvar == g_hTimeFormat)
		strcopy(g_sTimeFormat, sizeof(g_sTimeFormat), newvalue);
}