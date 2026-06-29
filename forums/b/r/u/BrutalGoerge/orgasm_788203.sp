/************************************************************************
*************************************************************************
kill-streak orgasm
Description:
	Fun simple kill messages and sounds for TF2
*************************************************************************
*************************************************************************

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version.
This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY;
without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*****************************
Author: Goerge

Thanks r5053, it was your script that helped me understand a lot of this sql stuff
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <colors>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "4.0.0"

#define SOUND			"vo/announcer_am_killstreak0"
#define NUMSOUNDS		9
#define BIRTHDAY		"misc/happy_birthday.wav"
#define FIRST_BLOOD 	"vo/announcer_am_firstblood04.mp3"

enum a_state
{
	newMap,
	preGame,
	normalRound,
	bonusRound,
};

Handle g_hResetTimer[MAXPLAYERS+1] = {null, ...};

static const int iSoundIndexes[] = {6,9,3,8,2,7,4,1,5};
Database g_hDb = null;

/** Database connection */
bool useDatabase = false;
bool g_arena;
bool g_sqlite = false;
a_state g_state;
bool g_bUseClientPrefs = false;
bool g_bEnabled;
bool g_bCountBots;
bool firstFrag = false;

enum struct PlayerData
{
	int iKillStreak;
	int iOrgasmTrigger;
	int iHighStreak;
	int iSavedStreak;
	int iNumTriggers;
	int iNextMessage;
	int iFireWorkTrigger;
	int iTarget;
	int iEnabled;
}

PlayerData g_aPlayers[MAXPLAYERS + 1];

int g_iMinPlayers;
ConVar cvar_LowInterval		= null;
ConVar cvar_HighInterval 	= null;
ConVar cvar_Message 		= null;
ConVar cvar_ShowKills 		= null;
ConVar cvar_FirstInterval 	= null;
ConVar cvar_RandomMode		= null;
ConVar cvar_FireWorks	 	= null;
ConVar cvar_Reset			= null;
ConVar cvar_SQL				= null;
ConVar cvar_RemoveDays		= null;
Cookie g_cookie_enabled 	= null;
ConVar cvar_logMinPlayers	= null;
ConVar g_enabled			= null;
ConVar cvar_CountBots		= null;
ConVar cvar_disableSounds	= null;

public Plugin myinfo = 
{
	name = "Kill Streak Orgasms",
	author = "Goerge",
	description = "Kill Streak Orgasms",
	version = PLUGIN_VERSION,
	url = "https://github.com/BrutalGoerge/tf2tmng"
};

/**
 * Called when the plugin is first loaded.
 * Registers ConVars, commands, event hooks, and initializes the database and clientprefs.
 */
public void OnPluginStart()
{
	cvar_logMinPlayers = CreateConVar("sm_orgasm_log_minplayers", "10", "How many players connected before streaks are logged to database", FCVAR_PLUGIN, true, 0.0, false);
	g_enabled = CreateConVar("orgasm_enabled", "1", "enable the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_FirstInterval 	= CreateConVar("sm_orgasm_first_interval", "3", 
										"First interval in which the plugin triggers", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvar_LowInterval 	= CreateConVar("sm_orgasm_low_interval", "2", 
										"Low random value in whichthe plugin will trigger a sound.\nEX: low = 3, high = 5, then the plugin will trigger a sound every 3 kills, 4 kills, or 5 kills", 
										FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvar_HighInterval 	= CreateConVar("sm_orgasm_high_interval", "4", "High random interval in which the plugin will trigger random kill-streak sounds.", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvar_Message 		= CreateConVar("sm_orgasm_message", "9", "If someone dies with this many, or more kills, print a special message to everyone", FCVAR_PLUGIN, true, 1.0, false);
	CreateConVar("sm_orgasm_version", PLUGIN_VERSION, "Orgasm version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cvar_ShowKills 		= CreateConVar("sm_orgasm_showallkills", "1", "Show all kill-streaks greater than 1 as hint messages to clients", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_RandomMode 	= CreateConVar("sm_orgasm_random_mode", "1", "Play sounds randomly. 1 enables. 0 plays the sounds in order", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_FireWorks 		= CreateConVar("sm_orgasm_fireworks_trigger", "6", 
										"After a client get this many sound triggers, attach the achievement fireworks to him for 5 seconds. 0 disables", FCVAR_PLUGIN, true, 0.0, false);
	cvar_Reset			= CreateConVar("sm_orgasm_reset_at_round_end", "1", "Enable/disable high-streak resetting between rounds", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SQL			= CreateConVar("sm_orgasm_use_database", "1", "Attempt to connect to a SQL database to save stats", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_RemoveDays	= CreateConVar("sm_orgasm_remove_players", "15", "How many days innactive players stay in the database", FCVAR_PLUGIN, true, 0.0, false);
	cvar_CountBots = CreateConVar("sm_orgasm_countbots", "0", "Include bots in the player count in decidng whether or not to save streaks", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_disableSounds = CreateConVar("sm_orgasm_playsounds", "1", "Play the sounds for this plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_death", hook_Death, EventHookMode_Post);
	HookEvent("teamplay_round_win", hook_Win, EventHookMode_Post);
	HookEvent("teamplay_round_start", hook_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("game_start", 				hook_Event_GameStart);
	HookEventEx("teamplay_restart_round", 	hook_Event_TFRestartRound);
	
	RegConsoleCmd("say", cmd_say);
	RegConsoleCmd("say_team", cmd_say);
	RegAdminCmd("sm_orgasm_reset", cmd_Reset, ADMFLAG_ROOT, "Resets the kill-streak database");
	
	LoadTranslations("common.phrases");
	LoadTranslations("orgasm.phrases");
	AutoExecConfig(true, "orgasm");
	ConnectToDatabase();
	
	g_enabled.AddChangeHook(ConVarChange);
	cvar_logMinPlayers.AddChangeHook(ConVarChange);
	cvar_CountBots.AddChangeHook(ConVarChange);
	
	// Check to see if the optional clientprefs extension is loaded and configured properly
	char sExtError[124];
	int iExtStatus = GetExtensionFileStatus("clientprefs.ext", sExtError, sizeof(sExtError));
	
	if (iExtStatus == -1)
		LogAction(-1, 0, "Optional extension clientprefs failed to load.");
	if (iExtStatus == 0)
	{
		LogAction(-1, 0, "Optional extension clientprefs is loaded with errors.");
		LogAction(-1, 0, "Status reported was [%s].", sExtError);
	}
	else if (iExtStatus == -2)
		LogAction(-1, 0, "Optional extension clientprefs is missing.");
	else if (iExtStatus == 1)
	{
		if (SQL_CheckConfig("clientprefs"))		
			g_bUseClientPrefs = true;
		else
			LogAction(-1, 0, "Optional extension clientprefs found, but no database entry is present");
	}
	
	// If clientprefs is available, register a cookie to allow players to toggle effects
	if (g_bUseClientPrefs)
	{
		g_cookie_enabled = new Cookie("enable", "enable sounds and messages for the client", CookieAccess_Public);
		SetCookieMenuItem(CookieMenu_TopMenu, g_cookie_enabled, "Kill-Streaks");
	}
}

/**
 * Handles live updates to ConVars so server restarts aren't needed to apply settings.
 */
public void ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_enabled)
	{
		if (StringToInt(newValue))
		{
			if (GetClientCount())
				CreateTimer(0.1, lateInit);
			g_bEnabled = true;
		}
		else
			g_bEnabled = false;
	}
	if (convar == cvar_logMinPlayers)
		g_iMinPlayers = StringToInt(newValue);
	if (convar == cvar_CountBots)
		StringToInt(newValue) == 1 ? (g_bCountBots = true) : (g_bCountBots = false);
}

/**
 * Admin command to clear out the database.
 * Requires the user to type it twice within 30 seconds to confirm.
 */
public Action cmd_Reset(int client, int args)
{
	// If the timer is active, they are confirming the reset.
	if (g_hResetTimer[client] != null)
	{
		CloseResetTimer(client);
		ResetDatabase();
		ReplyToCommand(client, "[SM] %t", "DatabaseReset");
		LogAction(client, -1, "%N reset the database", client);
		return Plugin_Handled;
	}
	
	// Otherwise, prompt them to confirm and start the timer.
	ReplyToCommand(client, "[SM] %t", "AreYouSure");
	int id;
	if (client)
	{
		id = GetClientUserId(client);
	}
	g_hResetTimer[client] = CreateTimer(30.0, timer_Confirm, id);
	return Plugin_Handled;
}

/**
 * Clears the reset confirmation timer if the admin doesn't confirm in time.
 */
public Action timer_Confirm(Handle timer, any id)
{
	int client;
	if (id)
	{
		client = GetClientOfUserId(id);
	}
	g_hResetTimer[client] = null;
	return Plugin_Handled;
}

/**
 * Helper to manually kill the reset confirmation timer.
 */
void CloseResetTimer(int client)
{
	if (g_hResetTimer[client] != null)
	{
		KillTimer(g_hResetTimer[client]);
		g_hResetTimer[client] = null;
	}
}

/**
 * Intercepts chat commands (like saying "TopStreak" or "StreakTop") to open the Top 10 menu.
 */
public Action cmd_say(int client, int args)
{
	if (!client || !useDatabase)
		return Plugin_Continue;
		
	char text[32];
	int startidx = 0;
	GetCmdArgString(text, sizeof(text));
	
	// Strip trailing quotes if present
	if (text[strlen(text)-1] == '"')
	{		
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	}
	
	// Check if the user is requesting the top streak panel
	if (!strcmp(text[startidx], "TopStreak", false) || !strcmp(text[startidx], "StreakTop", false))
	{
		top10pnl(client);
	}
	return Plugin_Continue;
}

/**
 * Establishes a connection to the SQL or SQLite database defined in databases.cfg.
 */
void ConnectToDatabase()
{
	char error[255];
	
	if (SQL_CheckConfig("orgasm"))
	{
		g_hDb = SQL_Connect("orgasm", true, error, sizeof(error));
		if (g_hDb == null)		
			PrintToServer("Failed to connect: %s", error);
		else
			useDatabase = true;
	}
	else
	{
		// Fallback to SQLite if no external database is configured
		g_hDb = SQLite_UseDatabase("orgasm", error, sizeof(error));    
		if (g_hDb == null)
			PrintToServer("SQL error: %s", error);
		else		
			useDatabase = true;		
	}
	
	if (useDatabase) 
	{
		char driver[32];
		g_hDb.Driver.GetIdentifier(driver, sizeof(driver));		
		LogMessage("DatabaseInit (CONNECTED) with db driver: %s", driver);
		
		if (strcmp(driver, "sqlite", false) == 0)
			g_sqlite = true;
		else
		{
			// Set codepage to utf8 for MySQL to properly store special characters in names
			char query[255];
			Format(query, sizeof(query), "SET NAMES 'utf8'");
			if (!SQL_FastQuery(g_hDb, query))		
				LogMessage("Can't select character set (%s)", query);
		}			
		CreateTables();
	}	
}

/**
 * Routes to the correct table creation logic based on the database type.
 */
void CreateTables()
{	
	if (g_sqlite)
		createdbplayerLite();
	else
		createdbplayer();
}

/**
 * Creates the MySQL table structure if it doesn't already exist.
 */
void createdbplayer()
{
	int len = 0;
	char query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `OrgasmPlayer` (");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`STREAK` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`LASTCONNECT` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`STEAMID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	SQL_FastQuery(g_hDb, query);
}

/**
 * Creates the SQLite table structure if it doesn't already exist.
 */
void createdbplayerLite()
{
	int len = 0;
	char query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `OrgasmPlayer`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `STREAK` INTEGER,`LASTCONNECT` INTEGER);");
	
	SQL_FastQuery(g_hDb, query);
}

/**
 * Called when a player fully joins the server. Fetches or generates their profile in the database.
 */
public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client) || !useDatabase || !g_bEnabled)
		return;
	ResetClient(client, true);
	InitiateClient(client);
}

/**
 * Adjusts game state when a round is restarted.
 */
public void hook_Event_TFRestartRound(Event event, const char[] name, bool dontBroadcast)
{
	g_state = normalRound;
}

/**
 * Adjusts game state when the game fully starts.
 */
public void hook_Event_GameStart(Event event, const char[] name, bool dontBroadcast)
{
	g_state = normalRound;
}

/**
 * Called when server configs are processed. Caches CVars and precaches audio files.
 */
public void OnConfigsExecuted()
{
	g_bEnabled = g_enabled.BoolValue;
	g_iMinPlayers = cvar_logMinPlayers.IntValue;
	g_bCountBots = cvar_CountBots.BoolValue;
	
	if (cvar_SQL.BoolValue && !useDatabase)
		SetFailState("unable to connect to database");
	
	g_arena = false;
	char buffer[64];
	for (int i = 1; i<= NUMSOUNDS; i++)
	{
		Format(buffer, sizeof(buffer), "%s%i.mp3", SOUND, i);
		PrecacheSound(buffer, true);
	}
	
	PrecacheSound(BIRTHDAY, true);
	
	// Check if arena mode is active
	ConVar arena = FindConVar("tf_gamemode_arena");
	if (arena != null && arena.BoolValue)
		g_arena = true;
	delete arena;
}

/**
 * Called when a new map loads. Resets states and runs database cleanup.
 */
public void OnMapStart()
{
	g_state = newMap;
	firstFrag = false;
	RemoveOldPlayers();
}

/**
 * Core logic hook. Called every time a player dies. 
 * Evaluates who killed who, triggers sounds, handles first blood, and resets the victim's streak.
 */
public void hook_Death(Event event, const char[] name, bool dontBroadcast)
{	
	if (!g_bEnabled || g_state != normalRound)
		return;
		
	// Block streaks from triggering or logging during the "Waiting for Players" phase
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
		
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	// Ignore Dead Ringer fake deaths, but still print current streak hint to the killer
	if (g_aPlayers[killer].iEnabled && event.GetInt("death_flags") & 32) 
	{
		if (killer && g_aPlayers[killer].iKillStreak > 1  && cvar_ShowKills.BoolValue)
			PrintHintText(killer, "%t", "GenericStreak", g_aPlayers[killer].iKillStreak+1);
		return;
	}
	
	// Ignore custom Holy Mackerel bat hits (only count the actual kill)
	if (event.GetInt("weaponid") == TF_WEAPON_BAT_FISH && event.GetInt("customkill") != TF_CUSTOM_FISH_KILL)
	{
		return;
	}
	
	// If it wasn't a suicide, advance the killer's streak
	if (killer != victim)
	{
		AdvanceStreak(killer);	
		DoFirstBloodCheck(killer, victim);
	}
	
	// Check if the victim had a high streak and broadcast a message
	DoDeathMessageCheck(killer, victim);
	
	// Reset the victim's active streak logic back to zero
	ResetClient(victim);
}

/**
 * Prepares the back-to-back fireworks particles attached to a player.
 */
void StartLooper(int client)
{
	CreateTimer(0.1, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);	// first firework
	CreateTimer(2.0, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE); // second firework
}

/**
 * Timer callback to physically attach the firework particle system.
 */
public Action Timer_Particles(Handle timer, any client)
{
	if (IsPlayerAlive(client))
		AttachParticle(client, "mini_fireworks");
	return Plugin_Handled;
}

/**
 * Called when a round is won. Determines highest streaks for the round and announces them.
 */
public void hook_Win(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;
	g_state = bonusRound;
	
	int varMessage = cvar_Message.IntValue;
	int highestVal = 0;
	int highStreaks = 0;
	int ClientList[MAXPLAYERS+1];
	char s_Name[MAX_NAME_LENGTH + 1];
	char message[255];
	
	// Iterate through clients, save their data, and announce anyone who passed the 'cvar_Message' threshold
	for (int i=1;i <= MaxClients;i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		if (g_aPlayers[i].iKillStreak >= varMessage)
		{
			if (g_aPlayers[i].iKillStreak > g_aPlayers[i].iSavedStreak)
				SaveStreak(i);
			GetClientName(i, s_Name, sizeof(s_Name));
			Format(s_Name, sizeof(s_Name), "\x03%s\x05", s_Name);
			CPrintToChatAllEx(i, "[SM] %t", "RoundEndMsg", s_Name, g_aPlayers[i].iKillStreak);
			
			if(g_aPlayers[i].iKillStreak > g_aPlayers[i].iHighStreak)
				g_aPlayers[i].iHighStreak = g_aPlayers[i].iKillStreak;
		}
	}	
	
	// Find what the absolute highest streak of the round was
	for (int i=1; i<=MaxClients;i++)
	{
		if(g_aPlayers[i].iHighStreak > highestVal)
		{
			highestVal = g_aPlayers[i].iHighStreak;
		}
	}
	
	// Collect all players who tied for that highest streak
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && g_aPlayers[i].iHighStreak == highestVal)
		{
			ClientList[highStreaks] = i;
			highStreaks++;
		}
	}
	
	// Prepare the final announcement for the top streaker(s)
	if (highestVal >= cvar_FirstInterval.IntValue)
	{
		if (highStreaks == 1)
		{	
			char h_name[32];
			GetClientName(ClientList[0], h_name, sizeof(h_name));
			Format(message, sizeof(message), "{default}[SM] %T", "HighestStreak", LANG_SERVER, h_name, highestVal);
			
			DataPack MessagePack;		
			CreateDataTimer(3.0, TimerMessage, MessagePack, TIMER_FLAG_NO_MAPCHANGE);
			MessagePack.WriteCell(ClientList[0]);
			MessagePack.WriteString(message);
		}
		else if (highStreaks > 1)
		{
			// Formatting logic if multiple people tied for top streak
			char list[1024];
			list = "";
			char tmpName[64];
			
			for (int i = 0; i < highStreaks-1; i++)
			{
				GetClientName(ClientList[i], tmpName, sizeof(tmpName));
				if (highStreaks == 2)
					Format(list, sizeof(list), "%s%s ", list, tmpName);
				else
					Format(list, sizeof(list), "%s%s, ", list, tmpName);
			}
			GetClientName(ClientList[highStreaks-1], tmpName, sizeof(tmpName));
			Format(list, sizeof(list), "%sand %s", list, tmpName);
			
			if (highStreaks == 2)
				Format(message, sizeof(message), "{default}[SM] %T", "Highest2", LANG_SERVER, list, highestVal);
			else
				Format(message, sizeof(message), "{default}[SM] %T", "HighestMult", LANG_SERVER, list, highestVal);
				
			DataPack MessagePack;
			CreateDataTimer(3.0, TimerMessage, MessagePack, TIMER_FLAG_NO_MAPCHANGE);
			MessagePack.WriteCell(0);
			MessagePack.WriteString(message);
		}
	}
	// Purge high streaks back to 0 if the cvar is configured to reset on round end
	ResetAll(cvar_Reset.BoolValue);
}

/**
 * Fires the delayed chat announcement populated during the end-of-round evaluation.
 */
public Action TimerMessage(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	char message[255];
	pack.ReadString(message, sizeof(message));	
	
	if (client && IsClientInGame(client))
		CPrintToChatAllEx(client, message);
	else
		CPrintToChatAll(message);
	return Plugin_Handled;
}

/**
 * Re-enables First Blood checks when a new round begins.
 */
public void hook_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	firstFrag = false;
	if (g_bEnabled)
		g_state == newMap ? (g_state = preGame) : (g_state = normalRound);
}

/**
 * Commits a player's last connect time and streak data when they leave the server.
 */
public void OnClientDisconnect(int client)
{
	UpdatePlayerConnectTime(client);
	ResetClient(client, true);
}

/**
 * Called when a player dies. If their current streak was high enough, prints a broadcast message
 * noting that their streak was ended (and by who).
 */
void DoDeathMessageCheck(int killer, int victim)
{
	if (g_aPlayers[victim].iKillStreak < cvar_Message.IntValue)
		return;

	// Save the data right away if their final streak beat their previous record
	if (useDatabase && g_aPlayers[victim].iKillStreak > g_aPlayers[victim].iSavedStreak)
		SaveStreak(victim);	
	
	char v_name[MAX_NAME_LENGTH + 1];
	GetClientName(victim, v_name, sizeof(v_name));
	
	if (killer != victim)
	{
		char k_name[MAX_NAME_LENGTH + 1];
		char translation[32];
		
		// If the world killed them (fall damage, map hazard, etc)
		if (killer < 1 || killer > MaxClients)
			Format(k_name, sizeof(k_name), "World");
		else if (IsClientInGame(killer))
			GetClientName(killer, k_name, sizeof(k_name));
			
		Format(translation, sizeof(translation), "DeathMsg%i", GetRandomInt(1,3));	
		CPrintToChatAllEx(victim, "[SM] %t", translation, v_name, g_aPlayers[victim].iKillStreak, k_name);
	}
	else // If they suicided
		CPrintToChatAllEx(victim, "[SM] %t", "SuicideMsg", v_name, g_aPlayers[victim].iKillStreak);	
}

/**
 * Checks if a kill is the very first one in the round and broadcasts a First Blood sound/message.
 */
void DoFirstBloodCheck(int killer, int victim)
{
	if (!killer || g_arena)
		return;
		
	if (!firstFrag)
	{
		firstFrag = true;
		char killerName[MAX_NAME_LENGTH + 1], victimName[MAX_NAME_LENGTH + 1];	
		GetClientName(killer, killerName, sizeof(killerName));
		GetClientName(victim, victimName, sizeof(victimName));
		CPrintToChatAllEx(killer, "[SM] %t", "FirstBlood", killerName, victimName);
		if (cvar_disableSounds.BoolValue)
			EmitSoundToAll(FIRST_BLOOD, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);		
	}
}

/**
 * Zeros out a player's streak tracking variables.
 * @param all If true, wipes their High Streak for the map too (useful for map changes or disconnects).
 */
void ResetClient(int client, bool all = false)
{
	g_aPlayers[client].iKillStreak = 0;
	if (all)
		g_aPlayers[client].iHighStreak = 0;
	g_aPlayers[client].iNumTriggers = 0;
	g_aPlayers[client].iNextMessage = 0;
	g_aPlayers[client].iOrgasmTrigger = cvar_FirstInterval.IntValue;
	g_aPlayers[client].iFireWorkTrigger = cvar_FireWorks.IntValue;
}

/**
 * Helper to apply ResetClient to the entire server simultaneously.
 */
void ResetAll(bool all = false)
{
	for (int i=1; i<= MaxClients; i++)
		ResetClient(i, all);
}

/**
 * Pushes the client's current highest streak to the database, ensuring min player thresholds are met.
 */
void SaveStreak(int client)
{
	int iCount;
	if (g_bCountBots)
		iCount = GetClientCount(true);
	else
		iCount = MyClientCount();
		
	// Don't log to DB if the server is practically empty to prevent easy stat padding
	if (iCount < g_iMinPlayers)
		return;
		
	g_aPlayers[client].iSavedStreak = g_aPlayers[client].iHighStreak;
	char buffer[250], ClientSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
	Format(buffer, sizeof(buffer), "UPDATE OrgasmPlayer SET STREAK = '%i' WHERE STEAMID = '%s'", g_aPlayers[client].iKillStreak, ClientSteamID);
	g_hDb.Query(SQLErrorCheckCallback, buffer);
}

/**
 * Increments the killer's streak count by 1 and delegates to Orgasm() if a milestone threshold is met.
 */
void AdvanceStreak(int killer)
{
	if (!killer)
		return;
		
	g_aPlayers[killer].iKillStreak++;
	
	if (g_aPlayers[killer].iKillStreak > g_aPlayers[killer].iHighStreak)
		g_aPlayers[killer].iHighStreak = g_aPlayers[killer].iKillStreak;		
	
	if	(g_aPlayers[killer].iKillStreak >  1)
	{
		// Did they hit the next milestone threshold?
		if (g_aPlayers[killer].iKillStreak == g_aPlayers[killer].iOrgasmTrigger)
			Orgasm(killer);
		// Otherwise, just print a basic hint text updating their count
		else if (g_aPlayers[killer].iEnabled && cvar_ShowKills.BoolValue)	
			PrintHintText(killer, "%t", "GenericStreak", g_aPlayers[killer].iKillStreak);
	}
}

/**
 * The core milestone reward function. Calculates the player's next target milestone, 
 * handles fireworks triggers, and pushes the audio/visual hints to the client.
 */
void Orgasm(int killer)
{
	g_aPlayers[killer].iNumTriggers++;
	// Calculate the next random interval jump for their streak
	g_aPlayers[killer].iOrgasmTrigger += GetRandomInt(cvar_LowInterval.IntValue, cvar_HighInterval.IntValue);
	
	// Has the player hit the threshold to spawn a firework effect?
	if (cvar_FireWorks.BoolValue && g_aPlayers[killer].iNumTriggers == g_aPlayers[killer].iFireWorkTrigger)
	{
		g_aPlayers[killer].iFireWorkTrigger += cvar_FireWorks.IntValue;		
		char streakerName[MAX_NAME_LENGTH + 1];
		GetClientName(killer, streakerName, sizeof(streakerName));
		CPrintToChatAllEx(killer, "[SM] %t", "StreakMsg", streakerName, g_aPlayers[killer].iKillStreak);
		
		// Don't spawn fireworks on Spies to prevent giving away their position/disguise
		if (TF2_GetPlayerClass(killer) != TFClass_Spy)
		{
			StartLooper(killer);
			if (cvar_disableSounds.BoolValue)
				EmitSoundToAll(BIRTHDAY, killer, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	
	if (!g_aPlayers[killer].iEnabled)
		return;
		
	// Decide which announcer line to play
	int switcher;
	if (!cvar_RandomMode.BoolValue)
	{
		g_aPlayers[killer].iNextMessage++;
		if (g_aPlayers[killer].iNextMessage > 9)	
			g_aPlayers[killer].iNextMessage = 1;
		switcher = g_aPlayers[killer].iNextMessage;
	}
	else
		switcher = GetRandomInt(1,9);
	
	char translation[32];
	char sound[64];
	Format(sound, sizeof(sound), "%s%i.mp3", SOUND, iSoundIndexes[switcher-1]);
	Format(translation, sizeof(translation), "Hint%i", switcher);
	
	if (cvar_disableSounds.BoolValue)
		EmitSoundToClient(killer, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	PrintHintText(killer, "%t", translation, g_aPlayers[killer].iKillStreak);
}

/**
 * Spawns and configures a particle entity attached to a client.
 */
void AttachParticle(int ent, const char[] particleType)
{
	int particle = CreateEntityByName("info_particle_system");	
	char tName[128];
	if (IsValidEdict(particle))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 55.0; // Raise the origin slightly above the player model
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
}

/**
 * Submits the SQL query to fetch the Top 10 users to display in the UI panel.
 */
public void top10pnl(int client)
{	
	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT NAME,STREAK FROM `OrgasmPlayer` ORDER BY STREAK DESC LIMIT 0,10");
	g_hDb.Query(T_ShowTOP, buffer, GetClientUserId(client));
}

/**
 * Parses the DB result for the Top 10 query and builds the visual Menu panel for the client.
 */
public void T_ShowTOP(Database owner, DBResultSet hndl, const char[] error, any data)
{
	int client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == null)
	{
		LogError("Query failed! %s", error);
	} 
	else 
	{
		Panel menu = new Panel();		
		int i  = 1;
		char plname[32];
		int score;
		menu.DrawItem("Top-10 Kill-Streaks");
		
		// Loop through the results and build out the panel lines
		while (hndl.FetchRow())
		{
			hndl.FetchString(0, plname, sizeof(plname));
			score = hndl.FetchInt(1);
			char menuline[50];
			Format(menuline, sizeof(menuline), "  %02.2d  %i  %s", i, score, plname);
			menu.DrawText(menuline);
			
			i++;
		}
		menu.Send(client, TopMenuHandler1, 20);
		delete menu;	 
		return;
	}
	return;	
}

/**
 * DB Callback fired when a player connects. Validates their name and logs/updates them into the database.
 */
public void T_CheckConnectingUsr(Database owner, DBResultSet hndl, const char[] error, any data)
{
	int client;
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if (hndl == null)
		LogError("Query failed! %s", error);
	else 
	{
		// Clean out malicious characters from their Steam name before DB insertion
		char clientname[60];
		GetClientName( client, clientname, sizeof(clientname) );
		ReplaceString(clientname, sizeof(clientname), "'", "");
		ReplaceString(clientname, sizeof(clientname), "<?", "");
		ReplaceString(clientname, sizeof(clientname), "?>", "");
		ReplaceString(clientname, sizeof(clientname), "\"", "");
		ReplaceString(clientname, sizeof(clientname), "<?PHP", "");
		ReplaceString(clientname, sizeof(clientname), "<?php", "");
		
		char ClientSteamID[60];
		GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
		char buffer[255];
		
		// If RowCount is zero, this user has never connected before. Create them.
		if (!hndl.RowCount) 
		{
			if (!g_sqlite)
			{
				Format(buffer, sizeof(buffer), "INSERT INTO OrgasmPlayer (`NAME`,`STEAMID`) VALUES ('%s','%s')", clientname, ClientSteamID);
				g_hDb.Query(SQLErrorCheckCallback, buffer);
			}
			else
			{
				Format(buffer, sizeof(buffer), "INSERT INTO OrgasmPlayer VALUES('%s','%s',0,0);", ClientSteamID, clientname);
				g_hDb.Query(SQLErrorCheckCallback, buffer);
			
			}
			UpdatePlayerConnectTime(client);
		}
		else
		{
			// Otherwise update their name (in case it changed) and fetch their points.
			Format(buffer, sizeof(buffer), "UPDATE OrgasmPlayer SET NAME = '%s' WHERE STEAMID = '%s'", clientname, ClientSteamID);
			g_hDb.Query(SQLErrorCheckCallback, buffer);
			UpdatePlayerConnectTime(client);
			
			int clientpoints;
			while (hndl.FetchRow())
			{
				clientpoints = hndl.FetchInt(0);
				g_aPlayers[client].iSavedStreak = clientpoints;
				// If their stored streak is over 10, brag about it globally on connect
				if (clientpoints > 10)
					CPrintToChatAll("[SM] %t", "ConnectMessage", clientname, clientpoints);
			}
		}
	}	
}

/**
 * Submits the initial query to find a user in the database when they connect.
 */
public void InitializeClientondb(int client)
{
	char ConUsrSteamID[60];
	char buffer[255];

	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT STREAK FROM OrgasmPlayer WHERE STEAMID = '%s'", ConUsrSteamID);
	int conuserid = GetClientUserId(client);
	g_hDb.Query(T_CheckConnectingUsr, buffer, conuserid);
}

/**
 * Late load initialization for client cookies so the plugin functions gracefully if loaded mid-map.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("RegClientCookie");
	MarkNativeAsOptional("SetClientCookie");
	MarkNativeAsOptional("GetClientCookie");
	if (late && GetClientCount())
	{
		CreateTimer(2.0, lateInit);
	}
	return APLRes_Success;
}

/**
 * Standard error callback handler for blind SQL queries.
 */
public void SQLErrorCheckCallback(Database owner, DBResultSet hndl, const char[] error, any data)
{
	if(error[0] != '\0')
		LogError("SQL Error: %s", error);
}

/**
 * Stub handler to satisfy Panel signature constraints. Panels auto-close when interaction ends.
 */
public int TopMenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	// Panel handles are closed automatically. MenuAction_End can be used if we had standard menus.
	return 0;
}

/**
 * Returns a count of active, non-bot players currently on the server.
 */
int MyClientCount()
{
	int clients;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			clients++;
	}
	return clients;
}

/**
 * Executes a DELETE query pruning players from the database whose LASTCONNECT is older than cvar_RemoveDays.
 */
void RemoveOldPlayers()
{
	int days = cvar_RemoveDays.IntValue;
	if (days >= 1)
	{
		int timesec = GetTime() - (days * 86400); // 86400 seconds in a day
		char query[512];
		Format(query, sizeof(query), "DELETE FROM OrgasmPlayer WHERE LASTCONNECT < '%i'",timesec);
		g_hDb.Query(SQLErrorCheckCallback, query);
	}
}

/**
 * Stamps the player's profile in the database with the current UNIX timestamp.
 */
void UpdatePlayerConnectTime(int client)
{
	char clsteamId[60];
	int time = GetTime();
	if (IsClientInGame(client))
	{
		GetClientAuthId(client, AuthId_Steam2, clsteamId, sizeof(clsteamId));
		char query[512];
		Format(query, sizeof(query), "UPDATE OrgasmPlayer SET LASTCONNECT = '%i' WHERE STEAMID = '%s'", time, clsteamId);
		g_hDb.Query(SQLErrorCheckCallback, query);
	}
}

/**
 * Empties the entire tracking database table.
 */
void ResetDatabase()
{
	char query[512];
	Format(query, sizeof(query), "TRUNCATE TABLE OrgasmPlayer");
	g_hDb.Query(SQLErrorCheckCallback, query);	
	CreateTimer(1.0, lateInit);
}

/**
 * A delayed loop that re-initializes all clients currently on the server.
 * This is especially useful if the plugin is loaded or reloaded mid-map.
 */
public Action lateInit(Handle timer)
{
	g_state = normalRound;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ResetClient(i, true);
			InitializeClientondb(i);
		}
	}
	return Plugin_Handled;
}

/**
 * Wrapper function for querying a user on connection.
 */
void InitiateClient(int client)
{
	char ConUsrSteamID[60];
	char buffer[255];
	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT STREAK FROM OrgasmPlayer WHERE STEAMID = '%s'", ConUsrSteamID);
	int conuserid = GetClientUserId(client);
	g_hDb.Query(T_CheckConnectingUsr, buffer, conuserid);
}

/**
 * Called automatically by clientprefs when a player's cookies have been loaded from the DB.
 * We use this to set their individual toggle preference for the plugin's effects.
 */
public void OnClientCookiesCached(int client)
{
	g_aPlayers[client].iEnabled = 1;
	char sEnabled[4];
	g_cookie_enabled.Get(client, sEnabled, sizeof(sEnabled));
	
	// If the cookie holds "-1", they opted out. Otherwise, opt them in.
	if (StringToInt(sEnabled) == -1)
		g_aPlayers[client].iEnabled = 0;
	else 
		g_aPlayers[client].iEnabled = 1;
}

/**
 * The callback for building the top-level option in the standard !settings menu.
 */
public void CookieMenu_TopMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		// Native clientprefs handles the display name, nothing needed here
	}
	else
	{
		Menu hMenu = new Menu(Menu_CookieSettings);
		hMenu.SetTitle("Options (Current Setting)");
		
		if (g_aPlayers[client].iEnabled == 1)
			hMenu.AddItem("enable", "Enabled/Disable (Enabled)");		
		else
			hMenu.AddItem("enable", "Enabled/Disable (Disabled)");
			
		hMenu.ExitBackButton = true;
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
}

/**
 * Sub-menu handler when they select the plugin from !settings.
 */
public int Menu_CookieSettings(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	if (action == MenuAction_Select) 
	{
		char sSelection[24];
		menu.GetItem(param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			Menu hMenu = new Menu(Menu_CookieSettingsEnable);
			hMenu.SetTitle("Enable/Disable kill-streaks");
			
			if (g_aPlayers[client].iEnabled == 1)
			{
				hMenu.AddItem("enable", "Enable (Set)");
				hMenu.AddItem("disable", "Disable");
			}
			else
			{
				hMenu.AddItem("enable", "Enabled");
				hMenu.AddItem("disable", "Disable (Set)");
			}
			
			hMenu.ExitBackButton = true;
			hMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

/**
 * Final menu handler that actually saves their toggle choice to the clientprefs database.
 */
public int Menu_CookieSettingsEnable(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	if (action == MenuAction_Select) 
	{
		char sSelection[24];
		menu.GetItem(param2, sSelection, sizeof(sSelection));
		
		// Set the cookie and live variable to enabled
		if (StrEqual(sSelection, "enable", false))
		{
			g_cookie_enabled.Set(client, "1");
			g_aPlayers[client].iEnabled = 1;
			PrintToChat(client, "[SM] Kill-streaks are ENABLED");
		}
		// Set the cookie and live variable to disabled
		else
		{
			g_cookie_enabled.Set(client, "-1");
			g_aPlayers[client].iEnabled = 0;
			PrintToChat(client, "[SM] kill-streaks are DISABLED");
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		// Navigate back up the menu tree
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		// Clean up the memory allocated for the menu
		delete menu;
	}
	return 0;
}