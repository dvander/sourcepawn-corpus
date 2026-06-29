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
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.

*****************************
Author: Goerge

Thanks r5053, it was your script that helped me understand a lot of this sql stuff
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <colors>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "3.3.2"

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
new Handle:g_hResetTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

static const iSoundIndexes[] = {6,9,3,8,2,7,4,1,5};
new Handle:g_hDb = INVALID_HANDLE;			/** Database connection */
new bool:useDatabase = false,
	bool:g_arena,
	bool:g_sqlite = false,
	a_state:g_state,
	bool:g_bUseClientPrefs = false,
	bool:g_bEnabled,
	bool:g_bCountBots,
	bool:firstFrag = false;

enum e_PlayerData
{
	iKillStreak,
	iOrgasmTrigger,
	iHighStreak,
	iSavedStreak,
	iNumTriggers,
	iNextMessage,
	iFireWorkTrigger,
	iTarget,
	iEnabled,
};

new g_aPlayers[MAXPLAYERS + 1][e_PlayerData];

new g_iMinPlayers,
	Handle:cvar_LowInterval		= INVALID_HANDLE,
	Handle:cvar_HighInterval 	= INVALID_HANDLE,
	Handle:cvar_Message 		= INVALID_HANDLE,
	Handle:cvar_ShowKills 		= INVALID_HANDLE,
	Handle:cvar_FirstInterval 	= INVALID_HANDLE,
	Handle:cvar_RandomMode		= INVALID_HANDLE,
	Handle:cvar_FireWorks	 	= INVALID_HANDLE,
	Handle:cvar_Reset			= INVALID_HANDLE,
	Handle:cvar_SQL				= INVALID_HANDLE,
	Handle:cvar_RemoveDays		= INVALID_HANDLE,
	Handle:g_cookie_enabled 	= INVALID_HANDLE,
	Handle:cvar_logMinPlayers	= INVALID_HANDLE,
	Handle:g_enabled			= INVALID_HANDLE,
	Handle:cvar_CountBots		=INVALID_HANDLE,
	Handle:cvar_disableSounds	=INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Kill Streak Orgasms",
	author = "Goerge",
	description = "Kill Streak Orgasms",
	version = PLUGIN_VERSION,
	url = "http://www.fpsbanana.com"
};

public OnPluginStart()
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
	HookConVarChange(g_enabled, ConVarChange);
	HookConVarChange(cvar_logMinPlayers, ConVarChange);
	HookConVarChange(cvar_CountBots, ConVarChange);
	
	/**
	check to see if client prefs is loaded and configured properly
	*/
	new String:sExtError[124];
	new iExtStatus = GetExtensionFileStatus("clientprefs.ext", sExtError, sizeof(sExtError));
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
	
	/**
	now that we have checked for the clientprefs ext, see if we can use its natives
	*/
	if (g_bUseClientPrefs)
	{
		g_cookie_enabled = RegClientCookie("enable", "enable sounds and messages for the client", CookieAccess_Public);
		SetCookieMenuItem(CookieMenu_TopMenu, g_cookie_enabled, "Kill-Streaks");
	}
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
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

public Action:cmd_Reset(client, args)
{
	if (g_hResetTimer[client] != INVALID_HANDLE)
	{
		CloseTimer(client);
		ResetDatabase();
		ReplyToCommand(client, "[SM] %t", "DatabaseReset");
		LogAction(client, -1, "%N reset the database", client);
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[SM] %t", "AreYouSure");
	new id;
	if (client)
	{
		id = GetClientUserId(client);
	}
	g_hResetTimer[client] = CreateTimer(30.0, timer_Confirm, id);
	return Plugin_Handled;
}

public Action:timer_Confirm(Handle:timer, any:id)
{
	new client;
	if (id)
	{
		client = GetClientOfUserId(id);
	}
	g_hResetTimer[client] = INVALID_HANDLE;
}

CloseTimer(client)
{
	if (g_hResetTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hResetTimer[client]);
		g_hResetTimer[client] = INVALID_HANDLE;
	}
}

public Action:cmd_say(client, args)
{
	if (!client || !useDatabase)
		return Plugin_Continue;
	new String:text[32], startidx;
	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{		
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	}
	
	if (!strcmp(text[startidx], "TopStreak", false) || !strcmp(text[startidx], "StreakTop", false))
	{
		top10pnl(client);
	}
	return Plugin_Continue;
}

ConnectToDatabase()
{
	new String:error[255];
	
	if (SQL_CheckConfig("orgasm"))
	{
		g_hDb = SQL_Connect("orgasm",true,error, sizeof(error));
		if (g_hDb == INVALID_HANDLE)		
			PrintToServer("Failed to connect: %s", error);
		else
			useDatabase = true;
	}
	else
	{
		g_hDb = SQLite_UseDatabase("orgasm", error, sizeof(error));    
		if (g_hDb == INVALID_HANDLE)
			PrintToServer("SQL error: %s", error);
		else		
			useDatabase = true;		
	}
	
	if (useDatabase) 
	{
		new String:driver[32];
		new Handle:hDriver = SQL_ReadDriver(g_hDb, driver, 32);
		CloseHandle(hDriver);		
		LogMessage("DatabaseInit (CONNECTED) with db driver: %s", driver);
		if (strcmp(driver, "sqlite", false) == 0)
			g_sqlite = true;
		else
		{
			/* Set codepage to utf8 */
			decl String:query[255];
			Format(query, sizeof(query), "SET NAMES 'utf8'");
			if (!SQL_FastQuery(g_hDb, query))			
				LogMessage("Can't select character set (%s)", query);
		}			
		CreateTables();
	}	
}

CreateTables()
{	
	if (g_sqlite)
		createdbplayerLite();
	else
		createdbplayer();
}

createdbplayer()
{
	new len = 0;
	decl String:query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `OrgasmPlayer` (");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` varchar(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`STREAK` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`LASTCONNECT` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`STEAMID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	SQL_FastQuery(g_hDb, query);
}

createdbplayerLite()
{
	new len = 0;
	decl String:query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `OrgasmPlayer`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `STREAK` INTEGER,`LASTCONNECT` INTEGER);");
	SQL_FastQuery(g_hDb, query);
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client) || !useDatabase || !g_bEnabled)
		return;
	ResetClient(client, true);
	InitiateClient(client);
}

public hook_Event_TFRestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_state = normalRound;  // game got restarted, re-enable pre-game
}

public hook_Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_state = normalRound;  // game got restarted, re-enable pre-game
}

public OnConfigsExecuted()
{
	g_bEnabled = GetConVarBool(g_enabled);
	g_iMinPlayers = GetConVarInt(cvar_logMinPlayers);
	g_bCountBots = GetConVarBool(cvar_CountBots);
	if (GetConVarBool(cvar_SQL) && !useDatabase)
		SetFailState("unable to connect to database");
	
	g_arena = false;
	new String:buffer[64];
	for (new i = 1; i<= NUMSOUNDS; i++)
	{
		Format(buffer, sizeof(buffer), "%s%i.mp3", SOUND, i);
		PrecacheSound(buffer, true);
	}
	
	PrecacheSound(BIRTHDAY, true);
	new Handle:arena = FindConVar("tf_gamemode_arena");
	if (GetConVarBool(arena))
		g_arena = true;
	CloseHandle(arena);
}

public OnMapStart()
{
	g_state = newMap;
	firstFrag = false;
	RemoveOldPlayers();
}

public hook_Death(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (!g_bEnabled || g_state != normalRound)
		return;
	//get killer id
	new killer = GetClientOfUserId(GetEventInt(event, "attacker")),
		victim	= GetClientOfUserId(GetEventInt(event, "userid"));
		
	if (g_aPlayers[killer][iEnabled] && GetEventInt(event, "death_flags") & 32) // dead ringer kill print message but really do nothing
	{
		if (killer && g_aPlayers[killer][iKillStreak] > 1  && GetConVarBool(cvar_ShowKills))
			PrintHintText(killer, "%t", "GenericStreak", g_aPlayers[killer][iKillStreak]+1);
		return;
	}
	if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH && GetEventInt(event, "customkill") != TF_CUSTOM_FISH_KILL)
	{
		return;
	}
	if (killer != victim)
	{
		AdvanceStreak(killer);	
		DoFirstBloodCheck(killer, victim);
	}
	DoDeathMessageCheck(killer, victim);
	
	//reset dead guy's numbers
	ResetClient(victim);
}

StartLooper(client)
{
	CreateTimer(0.1, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);	// first firework
	CreateTimer(2.0, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);		// second firework
}

public Action:Timer_Particles(Handle:timer, any:client)
{
	if (IsPlayerAlive(client))
		AttachParticle(client, "mini_fireworks");
	return Plugin_Handled;
}

public hook_Win(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;
	g_state = bonusRound;
	new varMessage = GetConVarInt(cvar_Message), highestVal = 0, highStreaks = 0, ClientList[MAXPLAYERS+1], String:s_Name[MAX_NAME_LENGTH + 1], String:message[255];	
	
	for (new i=1;i <= MaxClients;i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		if (g_aPlayers[i][iKillStreak] >= varMessage)
		{
			if (g_aPlayers[i][iKillStreak] > g_aPlayers[i][iSavedStreak])
				SaveStreak(i);
			GetClientName(i, s_Name, sizeof(s_Name));
			Format(s_Name, sizeof(s_Name), "\x03%s\x05", s_Name);
			CPrintToChatAllEx(i, "[SM] %t", "RoundEndMsg", s_Name, g_aPlayers[i][iKillStreak]);
			if(g_aPlayers[i][iKillStreak] > g_aPlayers[i][iHighStreak])
				g_aPlayers[i][iHighStreak] = g_aPlayers[i][iKillStreak];
		}
	}	
	for (new i=1; i<=MaxClients;i++)
	{
		if(g_aPlayers[i][iHighStreak] > highestVal)
		{
			highestVal = g_aPlayers[i][iHighStreak];
		}
	}
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && g_aPlayers[i][iHighStreak] == highestVal)
		{
			ClientList[highStreaks] = i;
			highStreaks++;
		}
	}
	
	if (highestVal >= GetConVarInt(cvar_FirstInterval))
	{
		if (highStreaks == 1)
		{	
			decl String:h_name[32];
			GetClientName(ClientList[0], h_name, sizeof(h_name));
			Format(message, sizeof(message), "{default}[SM] %T", "HighestStreak", LANG_SERVER, h_name, highestVal);
			new Handle:MessagePack;		
			CreateDataTimer(3.0, TimerMessage, MessagePack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(MessagePack, ClientList[0]);
			WritePackString(MessagePack, message);
		}
		else if (highStreaks > 1)
		{
			decl String:list[1024];
			list = "";
			decl String:tmpName[64];
			for (new i = 0; i < highStreaks-1; i++)
			{
				GetClientName(ClientList[i], tmpName, 64);
				if (highStreaks == 2)
					Format(list, 1024, "%s%s ", list, tmpName);
				else
					Format(list, 1024, "%s%s, ", list, tmpName);
			}
			GetClientName(ClientList[highStreaks-1], tmpName, 64);
			Format(list, 1024, "%sand %s", list, tmpName);
			if (highStreaks == 2)
				Format(message, sizeof(message), "{default}[SM] %T", "Highest2", LANG_SERVER, list, highestVal);
			else
				Format(message, sizeof(message), "{default}[SM] %T", "HighestMult", LANG_SERVER, list, highestVal);
			new Handle:MessagePack;
			CreateDataTimer(3.0, TimerMessage, MessagePack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(MessagePack, 0);
			WritePackString(MessagePack, message);
		}
	}
	ResetAll(GetConVarBool(cvar_Reset));
}


public Action:TimerMessage(Handle:timer, any:pack)
{
	ResetPack(pack);
	new	client = ReadPackCell(pack);
	new String:message[255];
	ReadPackString(pack, message, sizeof(message));	
	if (client && IsClientInGame(client))
		CPrintToChatAllEx(client, message);
	else
		CPrintToChatAll(message);
	return Plugin_Handled;
}

public hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	firstFrag = false;
	if (g_bEnabled)
		g_state == newMap ? (g_state = preGame) : (g_state = normalRound);
}

//will be needed if change to a round_Start hook above :D
//also should reset between maps
public OnClientDisconnect(client)
{
	UpdatePlayerConnectTime(client);
	ResetClient(true);
}

DoDeathMessageCheck(killer, victim)
{
	if (g_aPlayers[victim][iKillStreak] < GetConVarInt(cvar_Message))
		return;

	if (useDatabase && g_aPlayers[victim][iKillStreak] > g_aPlayers[victim][iSavedStreak])
		SaveStreak(victim);	
	
	decl String:v_name[MAX_NAME_LENGTH + 1];
	GetClientName(victim, v_name, sizeof(v_name));	
	if (killer != victim)
	{
		decl String:k_name[MAX_NAME_LENGTH + 1];
		decl String:translation[32];
		if (killer < 1 || killer > MaxClients)
			Format(k_name, sizeof(k_name), "World");
		else if (IsClientInGame(killer))
			GetClientName(killer, k_name, sizeof(k_name));
		Format(translation, sizeof(translation), "DeathMsg%i", GetRandomInt(1,3));	
		CPrintToChatAllEx(victim, "[SM] %t", translation, v_name, g_aPlayers[victim][iKillStreak], k_name);	
	}
	else
		CPrintToChatAllEx(victim, "[SM] %t", "SuicideMsg", v_name, g_aPlayers[victim][iKillStreak]);	
}

DoFirstBloodCheck(killer, victim)
{
	if (!killer || g_arena)
		return;
	if (!firstFrag)
	{
		firstFrag = true;
		decl String:killerName[MAX_NAME_LENGTH + 1], String:victimName[MAX_NAME_LENGTH + 1];	
		GetClientName(killer, killerName, sizeof(killerName));
		GetClientName(victim, victimName, sizeof(victimName));
		CPrintToChatAllEx(killer, "[SM] %t", "FirstBlood", killerName, victimName);
		if (GetConVarBool(cvar_disableSounds))
			EmitSoundToAll(FIRST_BLOOD, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);		
	}
}

stock ResetClient(client, bool:all = false)
{
	g_aPlayers[client][iKillStreak] = 0;
	if (all)
		g_aPlayers[client][iHighStreak] = 0;
	g_aPlayers[client][iNumTriggers] = 0;
	g_aPlayers[client][iNextMessage] = 0;
	g_aPlayers[client][iOrgasmTrigger] = GetConVarInt(cvar_FirstInterval);
	g_aPlayers[client][iFireWorkTrigger] = GetConVarInt(cvar_FireWorks);
}

stock ResetAll(bool:all = false)
{
	for (new i=1; i<= MaxClients; i++)
		ResetClient(i, all);	
}

SaveStreak(client)
{
	new iCount;
	if (g_bCountBots)
		iCount = GetClientCount(true);
	else
		iCount = MyClientCount();
	if (iCount < g_iMinPlayers)
		return;
	g_aPlayers[client][iSavedStreak] = g_aPlayers[client][iHighStreak];
	new String:buffer[250], String:ClientSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
	Format(buffer, sizeof(buffer), "UPDATE OrgasmPlayer SET STREAK = '%i' WHERE STEAMID = '%s'", g_aPlayers[client][iKillStreak], ClientSteamID);
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, buffer);
}

AdvanceStreak(killer)
{
	if (!killer)
		return;
		
	g_aPlayers[killer][iKillStreak]++;
	
	if (g_aPlayers[killer][iKillStreak] > g_aPlayers[killer][iHighStreak])
		g_aPlayers[killer][iHighStreak] = g_aPlayers[killer][iKillStreak];		
	
	if	(g_aPlayers[killer][iKillStreak] >  1)
	{
		if (g_aPlayers[killer][iKillStreak] == g_aPlayers[killer][iOrgasmTrigger])
			Orgasm(killer);
		else if (g_aPlayers[killer][iEnabled] && GetConVarBool(cvar_ShowKills))	
			PrintHintText(killer, "%t", "GenericStreak", g_aPlayers[killer][iKillStreak]);
	}
}

Orgasm(killer)
{
	g_aPlayers[killer][iNumTriggers]++;
	g_aPlayers[killer][iOrgasmTrigger] += GetRandomInt(GetConVarInt(cvar_LowInterval), GetConVarInt(cvar_HighInterval));
	
	if (GetConVarBool(cvar_FireWorks) && g_aPlayers[killer][iNumTriggers] == g_aPlayers[killer][iFireWorkTrigger])
	{
		g_aPlayers[killer][iFireWorkTrigger] += GetConVarInt(cvar_FireWorks);		
		decl String:streakerName[MAX_NAME_LENGTH + 1];
		GetClientName(killer, streakerName, sizeof(streakerName));
		CPrintToChatAllEx(killer, "[SM] %t", "StreakMsg", streakerName, g_aPlayers[killer][iKillStreak]);
		if (TFClassType:TF2_GetPlayerClass(killer) != TFClass_Spy)
		{
			StartLooper(killer);
			if (GetConVarBool(cvar_disableSounds))
				EmitSoundToAll(BIRTHDAY, killer, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	
	if (!g_aPlayers[killer][iEnabled])
		return;
		
	new switcher;
	if (!GetConVarBool(cvar_RandomMode))
	{
		g_aPlayers[killer][iNextMessage]++;
		if (g_aPlayers[killer][iNextMessage] > 9)	
			g_aPlayers[killer][iNextMessage] = 1;
		switcher = g_aPlayers[killer][iNextMessage];
	}
	else
		switcher = GetRandomInt(1,9);
	
	new String:translation[32];
	new String:sound[64];	
	Format(sound, sizeof(sound), "%s%i.mp3", SOUND, iSoundIndexes[switcher-1]);
	Format(translation, sizeof(translation), "Hint%i", switcher);
	if (GetConVarBool(cvar_disableSounds))
		EmitSoundToClient(killer, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	PrintHintText(killer, "%t", translation, g_aPlayers[killer][iKillStreak]);
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");	
	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3] ;
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 55;
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

public top10pnl(client)
{	
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT NAME,STREAK FROM `OrgasmPlayer` ORDER BY STREAK DESC LIMIT 0,10");
	SQL_TQuery(g_hDb, T_ShowTOP, buffer, GetClientUserId(client));
}

public T_ShowTOP(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} 
	else 
	{
		
		new Handle:menu = CreatePanel(INVALID_HANDLE);		
		new i  = 1;
		new String:plname[32];
		new score;
		DrawPanelItem(menu, "Top-10 Kill-Streaks");
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, plname , 32);
			score = SQL_FetchInt(hndl,1);
			new String:menuline[50];
			Format(menuline, sizeof(menuline), "  %02.2d  %i  %s", i, score, plname);
			DrawPanelText(menu, menuline);
			
			i++;
		}/*
		SetMenuPagination(menu, MENU_NO_PAGINATION);
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 60);*/
		SendPanelToClient(menu, client, TopMenuHandler1, 20);	 
		return;
	}
	return;	
}

public T_CheckConnectingUsr(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if (hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
	
	else 
	{
		new String:clientname[60];
		GetClientName( client, clientname, sizeof(clientname) );
		ReplaceString(clientname, sizeof(clientname), "'", "");
		ReplaceString(clientname, sizeof(clientname), "<?", "");
		ReplaceString(clientname, sizeof(clientname), "?>", "");
		ReplaceString(clientname, sizeof(clientname), "\"", "");
		ReplaceString(clientname, sizeof(clientname), "<?PHP", "");
		ReplaceString(clientname, sizeof(clientname), "<?php", "");
		new String:ClientSteamID[60];
		GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
		new String:buffer[255];
		
		if (!SQL_GetRowCount(hndl)) 
		{
		/*insert user*/	
			if (!g_sqlite)
			{
				Format(buffer, sizeof(buffer), "INSERT INTO OrgasmPlayer (`NAME`,`STEAMID`) VALUES ('%s','%s')", clientname, ClientSteamID);
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
			}
			else
			{
				Format(buffer, sizeof(buffer), "INSERT INTO OrgasmPlayer VALUES('%s','%s',0,0);", ClientSteamID,clientname);
				SQL_TQuery(g_hDb, SQLErrorCheckCallback, buffer);
			
			}
			UpdatePlayerConnectTime(client);
		}
		else
		{
			/*update name*/
			Format(buffer, sizeof(buffer), "UPDATE OrgasmPlayer SET NAME = '%s' WHERE STEAMID = '%s'", clientname, ClientSteamID);
			SQL_TQuery(g_hDb,SQLErrorCheckCallback, buffer);
			UpdatePlayerConnectTime(client);
			new clientpoints;
			while (SQL_FetchRow(hndl))
			{
				clientpoints = SQL_FetchInt(hndl,0);
				g_aPlayers[client][iSavedStreak] = clientpoints;
				if (clientpoints > 10)
					CPrintToChatAll("[SM] %t", "ConnectMessage", clientname, clientpoints);
			}
		}
	}	
}

public InitializeClientondb(client)
{
	new String:ConUsrSteamID[60];
	new String:buffer[255];

	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT STREAK FROM OrgasmPlayer WHERE STEAMID = '%s'", ConUsrSteamID);
	new conuserid;
	conuserid = GetClientUserId(client);
	SQL_TQuery(g_hDb, T_CheckConnectingUsr, buffer, conuserid);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
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

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
		LogError("SQL Error: %s", error);
	
}


public TopMenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock MyClientCount()
{
	new clients;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			clients++;
	}
	return clients;
}

stock RemoveOldPlayers()
{
	new days = GetConVarInt(cvar_RemoveDays);
	if (days >= 1)
	{
		new timesec = GetTime() - (days * 86400);
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM OrgasmPlayer WHERE LASTCONNECT < '%i'",timesec);
		SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	}
}

stock UpdatePlayerConnectTime(client)
{
	new String:clsteamId[60];
	new time = GetTime();

	if (IsClientInGame(client))
	{
		GetClientAuthId(client, AuthId_Steam2, clsteamId, sizeof(clsteamId));
		new String:query[512];
		Format(query, sizeof(query), "UPDATE OrgasmPlayer SET LASTCONNECT = '%i' WHERE STEAMID = '%s'",time ,clsteamId);
		SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);
	}
}

stock ResetDatabase()
{
	new String:query[512];
	Format(query, sizeof(query), "TRUNCATE TABLE OrgasmPlayer");
	SQL_TQuery(g_hDb,SQLErrorCheckCallback, query);	
	CreateTimer(1.0, lateInit);
}

public Action:lateInit(Handle:timer)
{
	g_state = normalRound;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ResetClient(i, true);
			InitializeClientondb(i);
		}
	}
}

stock InitiateClient(client)
{
	new String:ConUsrSteamID[60];
	new String:buffer[255];
	GetClientAuthId(client, AuthId_Steam2, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT STREAK FROM OrgasmPlayer WHERE STEAMID = '%s'", ConUsrSteamID);
	new conuserid;
	conuserid = GetClientUserId(client);
	SQL_TQuery(g_hDb, T_CheckConnectingUsr, buffer, conuserid);
}

public OnClientCookiesCached(client)
{
	g_aPlayers[client][iEnabled] = 1;
	decl String:sEnabled[4];
	GetClientCookie(client, g_cookie_enabled, sEnabled, sizeof(sEnabled));
	if (StringToInt(sEnabled) == -1)
		g_aPlayers[client][iEnabled] = 0;
	else 
		g_aPlayers[client][iEnabled] = 1;
}

public CookieMenu_TopMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		//don't think we need to do anything
	}
	else
	{
		new Handle:hMenu = CreateMenu(Menu_CookieSettings);
		SetMenuTitle(hMenu, "Options (Current Setting)");
		if (g_aPlayers[client][iEnabled] == 1)
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Enabled)");		
		else
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Disabled)");
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

public Menu_CookieSettings(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsEnable);
			SetMenuTitle(hMenu, "Enable/Disable kill-streaks");
			
			if (g_aPlayers[client][iEnabled] == 1)
			{
				AddMenuItem(hMenu, "enable", "Enable (Set)");
				AddMenuItem(hMenu, "disable", "Disable");
			}
			else
			{
				AddMenuItem(hMenu, "enable", "Enabled");
				AddMenuItem(hMenu, "disable", "Disable (Set)");
			}
			
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
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
		CloseHandle(menu);
	}
}

public Menu_CookieSettingsEnable(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			SetClientCookie(client, g_cookie_enabled, "1");
			g_aPlayers[client][iEnabled] = 1;
			PrintToChat(client, "[SM] Kill-streaks are ENABLED");
		}
		else
		{
			SetClientCookie(client, g_cookie_enabled, "-1");
			g_aPlayers[client][iEnabled] = 0;
			PrintToChat(client, "[SM] kill-streaks are DISABLED");
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
		CloseHandle(menu);
	}
}
		