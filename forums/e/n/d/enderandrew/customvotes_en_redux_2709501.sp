#pragma semicolon 1
#pragma newdecls required

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <colorvariables>
#undef REQUIRE_PLUGIN
#include <sourcebanspp>
#tryinclude <kztimer>
#include <afk_manager>
// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Custom Votes"
#define PLUGIN_VERSION "1.19.1"
#define MAX_VOTE_TYPES 32
#define MAX_VOTE_MAPS 2048
#define MAX_VOTE_OPTIONS 32

#pragma semicolon 1
#pragma newdecls required

// ====[ HANDLES ]=============================================================
Handle g_hArrayVotePlayerSteamID[MAXPLAYERS + 1][MAX_VOTE_TYPES];
Handle g_hArrayVotePlayerIP[MAXPLAYERS + 1][MAX_VOTE_TYPES];
Handle g_hArrayVoteOptionName[MAX_VOTE_TYPES];
Handle g_hArrayVoteOptionResult[MAX_VOTE_TYPES];
Handle g_hArrayVoteMapList[MAX_VOTE_TYPES];
Handle g_hArrayRecentMaps;

// ====[ VARIABLES ]===========================================================
int g_iMapTime;
int g_iVoteCount;
int g_iCurrentVoteIndex;
int g_iCurrentVoteTarget;
int g_iCurrentVoteMap;
int g_iCurrentVoteOption;
int iAfkTime;
int g_iVoteType[MAX_VOTE_TYPES];
int g_iVoteDelay[MAX_VOTE_TYPES];
int g_iVoteCooldown[MAX_VOTE_TYPES];
int g_iVoteMinimum[MAX_VOTE_TYPES];
int g_iVoteImmunity[MAX_VOTE_TYPES];
int g_iVoteMaxCalls[MAX_VOTE_TYPES];
int g_iVotePasses[MAX_VOTE_TYPES];
int g_iVoteMaxPasses[MAX_VOTE_TYPES];
int g_iVoteMapRecent[MAX_VOTE_TYPES];
int g_iVoteCurrent[MAXPLAYERS + 1];
int g_iVoteRemaining[MAXPLAYERS + 1][MAX_VOTE_TYPES];
int g_iVoteLast[MAXPLAYERS + 1][MAX_VOTE_TYPES];
int g_iVoteAllLast[MAX_VOTE_TYPES]; // same as g_iVoteLast but applies to all players
int g_iVoteAllCooldown[MAX_VOTE_TYPES]; // cooldown between votes for ALL players
bool g_bVoteCallVote[MAX_VOTE_TYPES];
bool g_bVotePlayersBots[MAX_VOTE_TYPES];
bool g_bVotePlayersTeam[MAX_VOTE_TYPES];
bool g_bVoteMapCurrent[MAX_VOTE_TYPES];
bool g_bVoteMultiple[MAX_VOTE_TYPES];
bool g_bVoteForTarget[MAXPLAYERS + 1][MAX_VOTE_TYPES][MAXPLAYERS + 1];
bool g_bVoteForMap[MAXPLAYERS + 1][MAX_VOTE_TYPES][MAX_VOTE_MAPS];
bool g_bVoteForOption[MAXPLAYERS + 1][MAX_VOTE_TYPES][MAX_VOTE_OPTIONS];
bool g_bVoteForSimple[MAXPLAYERS + 1][MAX_VOTE_TYPES];
bool g_bKzTimer = false;
bool g_bSourceBans = false;
bool g_bAfkManager = false;
//bool g_bMapEnded = false;
float g_flVoteRatio[MAX_VOTE_TYPES];
char g_strVoteName[MAX_VOTE_TYPES][MAX_NAME_LENGTH];
char g_strVoteConVar[MAX_VOTE_TYPES][MAX_NAME_LENGTH];
char g_strVoteOverride[MAX_VOTE_TYPES][MAX_NAME_LENGTH];
char g_strVoteCommand[MAX_VOTE_TYPES][255];
char g_strVoteChatTrigger[MAX_VOTE_TYPES][255];
char g_strVoteStartNotify[MAX_VOTE_TYPES][255];
char g_strVoteCallNotify[MAX_VOTE_TYPES][255];
char g_strVotePassNotify[MAX_VOTE_TYPES][255];
char g_strVoteFailNotify[MAX_VOTE_TYPES][255];
char g_strVoteTargetIndex[255];
char g_strVoteTargetId[255];
char g_strVoteTargetAuth[255];
char g_strVoteTargetName[255];
char g_strConfigFile[PLATFORM_MAX_PATH];
char g_sLogPath[PLATFORM_MAX_PATH];
// extras
Handle CvarDebugMode;
Handle CvarResetOnWaveFailed;
Handle CvarAutoBanEnabled;
Handle CvarAutoBanWarning;
Handle CvarAutoBanDuration;
Handle CvarAutoBanType;
Handle CvarAfkTime;
Handle CvarAfkManager;
Handle CvarCancelVoteGameEnd;
Handle CvarPrintToAdmins;
bool bDebugMode;
bool bResetOnWaveFailed;
bool bAutoBanEnabled;
bool bAutoBanWarning;
bool bAutoBanType;
bool bAfkManagerEnable;
bool bCancelVoteGameEnd;
bool bPrintToAdmins;
int iAutoBanDuration;
bool IsTF2 = false;
bool IsCSGO = false;
bool IsMapEnding = false;

enum
{
	VoteType_Players = 0,
	VoteType_Map,
	VoteType_List,
	VoteType_Simple,
}

// ====[ PLUGIN ]==============================================================
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "ReFlexPoison,Anonymous Player",
	description = PLUGIN_NAME,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	/* Special thanks to afk manager ( https://forums.alliedmods.net/showthread.php?p=708265 ) and sourcecmod anti-cheat developers.
	I looked at their's plugin in order to learn how to add file logging. */
	// Special thanks for those who contributed on github
	// sneak-it ( https://github.com/caxanga334/cvreduxmodified/pulls?utf8=%E2%9C%93&q=is%3Apr+user%3Asneak-it )
}

// ====[ FUNCTIONS ]===========================================================
public void OnPluginStart()
{
	CreateConVar("sm_customvotes_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	CvarResetOnWaveFailed = CreateConVar("sm_cv_tf2_reset_wavefailed", "0", "Reset maxpasses on wave failed?", FCVAR_NONE, true, 0.0, true, 1.0); // reset max passes on wave failed
	HookConVarChange( CvarResetOnWaveFailed, OnConVarChanged );
	CvarAutoBanEnabled = CreateConVar("sm_cv_autoban", "0", "Should the plugin automatically ban players who evade votes?", FCVAR_NONE, true, 0.0, true, 1.0); // ban players evading votes?
	HookConVarChange( CvarAutoBanEnabled, OnConVarChanged );
	CvarAutoBanWarning = CreateConVar("sm_cv_autoban_warning", "1", "Should the plugin warn targeted players if they will be banned upon disconnecting? Requires sm_cv_autoban 1.", FCVAR_NONE, true, 0.0, true, 1.0); // warn players about ban evasion enforcement?
	HookConVarChange( CvarAutoBanWarning, OnConVarChanged );
	CvarAutoBanType = CreateConVar("sm_cv_bantype", "0", "Ban type to be used for vote evasion bans? 0 - Local | 1 - MySQL (SourceBans)", FCVAR_NONE, true, 0.0, true, 1.0); // should we use mysql banning?
	HookConVarChange( CvarAutoBanType, OnConVarChanged );
	CvarAutoBanDuration = CreateConVar("sm_cv_banduration", "15", "How long (in minutes) should the plugin ban someone for evading votes?", FCVAR_NONE, true, 0.0, true, 525600.0); // the ban duration
	HookConVarChange( CvarAutoBanDuration, OnConVarChanged );
	CvarCancelVoteGameEnd = CreateConVar("sm_cv_cancelvote", "1", "Cancel pending votes on round end?", FCVAR_NONE, true, 0.0, true, 1.0); // Cancel votes using events, default enabled due to OnMapEnd being fired after OnClientDisconnect
	HookConVarChange( CvarCancelVoteGameEnd, OnConVarChanged );
	CvarDebugMode = CreateConVar("sm_cv_debug", "0", "Enable debug mode?", FCVAR_NONE, true, 0.0, true, 1.0); // Debug mode
	HookConVarChange( CvarDebugMode, OnConVarChanged );
	CvarAfkManager = CreateConVar("sm_cv_afkenable", "0", "Enable Afk players are no longer counted in the total?", FCVAR_NONE, true, 0.0, true, 1.0); //Enable Afk players are no longer counted in the total?
	HookConVarChange( CvarAfkManager, OnConVarChanged );
	CvarAfkTime = CreateConVar("sm_cv_afktime", "60", "How long (Seconds) Afk players are no longer counted in the total?", FCVAR_NONE, true, 0.0, true, 1000.0); //How long Afk players are no longer counted in the total?
	HookConVarChange( CvarAfkTime, OnConVarChanged );
	CvarPrintToAdmins = CreateConVar("sm_cv_printtoadmins", "1", "Prints votes started by players to admins. Default to ADMFLAG_GENERIC, configurable override with sm_customvotes_printtoadmins", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange( CvarPrintToAdmins, OnConVarChanged );
	
	RegAdminCmd("sm_customvotes_reload", Command_Reload, ADMFLAG_ROOT, "Reloads the configuration file (Clears all votes)");
	RegAdminCmd("sm_votemenu", Command_ChooseVote, 0, "Opens the vote menu");

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("customvotes.phrases");

	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/customvotes.cfg");

	AddCommandListener(OnClientSayCmd, "say");
	AddCommandListener(OnClientSayCmd, "say_team");

	g_bKzTimer = LibraryExists("KZTimer");

	if(g_hArrayRecentMaps == INVALID_HANDLE)
		g_hArrayRecentMaps = CreateArray(MAX_NAME_LENGTH);
		
	DetectGame();
	
	// hook required for resetting total passes when the wave is lost (MVM)
	// TF2 only
	if(IsTF2 == true)
	{
		HookEvent("mvm_wave_failed", TF_WaveFailed);
		HookEvent("teamplay_win_panel", TF_TeamPlayWinPanel);
		HookEvent("arena_win_panel", TF_ArenaWinPanel);
		HookEvent("pve_win_panel", TF_MVMWinPanel);
	}
	if(IsCSGO == true)
	{
		HookEvent("cs_win_panel_match", CSGO_MapEnd);
	}
	
	CreateLogFile();
	AutoExecConfig(true, "sm_customvotes_redux");
}

public void OnMapStart()
{
	IsMapEnding = false;
	g_iMapTime = 0;
	//g_bMapEnded = false; // map started, set it to false

	char strMap[MAX_NAME_LENGTH];
	GetCurrentMap(strMap, sizeof(strMap));

	if(GetArraySize(g_hArrayRecentMaps) <= 0)
		PushArrayString(g_hArrayRecentMaps, strMap);
	else
	{
		ShiftArrayUp(g_hArrayRecentMaps, 0);
		SetArrayString(g_hArrayRecentMaps, 0, strMap);
	}

	Config_Load();
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
/* 	if(!g_bMapEnded)
	{
		g_bMapEnded = true;
	} */
	
	IsMapEnding = true;
	
	if((!IsTF2) && !bCancelVoteGameEnd)
	{
		if(IsVoteInProgress()) // is vote in progress?
		{
			CancelVote(); // cancel any running votes on map end.
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Map ended while a vote was in progress, canceling vote.");
		}
	}
	g_iCurrentVoteIndex = -1;
	g_iCurrentVoteTarget = -1;
	g_iCurrentVoteMap = -1;
	g_iCurrentVoteOption = -1;
}

public void OnConVarChanged( Handle hConVar, const char[] strOldValue, const char[] strNewValue )
{
	bResetOnWaveFailed = GetConVarBool( CvarResetOnWaveFailed );
	bAutoBanEnabled = GetConVarBool( CvarAutoBanEnabled );
	bAutoBanWarning = GetConVarBool( CvarAutoBanWarning );
	bAutoBanType = GetConVarBool( CvarAutoBanType );
	iAutoBanDuration = GetConVarInt( CvarAutoBanDuration );
	bCancelVoteGameEnd = GetConVarBool( CvarCancelVoteGameEnd );
	bDebugMode = GetConVarBool( CvarDebugMode );
	bAfkManagerEnable = GetConVarBool( CvarAfkManager );
	iAfkTime = GetConVarBool( CvarAfkTime );
	bPrintToAdmins = GetConVarBool( CvarPrintToAdmins );
}

stock void DetectGame()
{
	char game_mod[32];
	GetGameFolderName(game_mod, sizeof(game_mod));
	
	if (strcmp(game_mod, "tf", false) == 0)
	{
		IsTF2 = true;
		LogMessage("Game Detected: Team Fortress 2.");
	}
	else if (strcmp(game_mod, "csgo", false) == 0)
	{
		IsCSGO = true;
		LogMessage("Game Detected: Counter-Strike: Global Offensive.");
	}
	else
	{
		LogMessage("Game Detected: Other.");
	}
}

public void OnLibraryAdded(const char[] szName)
{
	if (StrEqual(szName, "KZTimer"))
	{
		g_bKzTimer = true;
	}
	
	if (StrEqual(szName, "sourcebans++"))
	{
		g_bSourceBans = true;
	}
	if (StrEqual(szName, "afkmanager"))
	{
		g_bAfkManager = true;
	}
}

public void OnLibraryRemoved(const char[] szName)
{
	if (StrEqual(szName, "KZTimer"))
	{
		g_bKzTimer = false;
	}
	
	if (StrEqual(szName, "sourcebans++"))
	{
		g_bSourceBans = false;
	}
	if (StrEqual(szName, "afkmanager"))
	{
		g_bAfkManager = false;
	}
}

public void OnClientConnected(int iTarget)
{
	g_iVoteCurrent[iTarget] = -1;
	for(int iVote = 0; iVote < g_iVoteCount; iVote++)
	{
		g_iVoteRemaining[iTarget][iVote] = g_iVoteMaxCalls[iVote];
		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
		{
			g_bVoteForTarget[iVoter][iVote][iTarget] = false;
			g_bVoteForTarget[iTarget][iVote][iVoter] = false;
		}

		for(int iMap = 0; iMap < MAX_VOTE_MAPS; iMap++)
			g_bVoteForMap[iTarget][iVote][iMap] = false;

		for(int iOption = 0; iOption < MAX_VOTE_OPTIONS; iOption++)
			g_bVoteForOption[iTarget][iVote][iOption] = false;

		g_bVoteForSimple[iTarget][iVote] = false;

		if(g_hArrayVotePlayerSteamID[iTarget][iVote] != INVALID_HANDLE)
			ClearArray(g_hArrayVotePlayerSteamID[iTarget][iVote]);

		if(g_hArrayVotePlayerIP[iTarget][iVote] != INVALID_HANDLE)
			ClearArray(g_hArrayVotePlayerIP[iTarget][iVote]);
	}

	char strClientIP[MAX_NAME_LENGTH];
	if(!GetClientIP(iTarget, strClientIP, sizeof(strClientIP)))
		return;

	char strSavedIP[MAX_NAME_LENGTH];
	for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
	{
		for(int iVote = 0; iVote < g_iVoteCount; iVote++)
		{
			if(g_bVoteForTarget[iVoter][iVote][iTarget])
				break;

			if(g_hArrayVotePlayerIP[iVoter][iVote] == INVALID_HANDLE)
				continue;

			for(int iIP = 0; iIP < GetArraySize(g_hArrayVotePlayerIP[iVoter][iVote]); iIP++)
			{
				GetArrayString(g_hArrayVotePlayerIP[iVoter][iVote], iIP, strSavedIP, sizeof(strSavedIP));
				if(StrEqual(strSavedIP, strClientIP))
				{
					g_bVoteForTarget[iVoter][iTarget][iTarget] = true;
					// g_bVoteForTarget[iVoter][iVote][iTarget] = true; ?
					break;
				}
			}
		}
	}

	for(int iVote = 0; iVote < g_iVoteCount; iVote++)
		CheckVotesForTarget(iVote, iTarget);
}

public void OnClientAuthorized(int iTarget, const char[] strTargetSteamId)
{
	char strClientAuth[MAX_NAME_LENGTH];
	for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
	{
		for(int iVote = 0; iVote < g_iVoteCount; iVote++)
		{
			if(g_bVoteForTarget[iVoter][iVote][iTarget])
				break;

			if(g_hArrayVotePlayerSteamID[iVoter][iVote] == INVALID_HANDLE)
				continue;

			for(int iSteamId = 1; iSteamId < GetArraySize(g_hArrayVotePlayerSteamID[iVoter][iVote]); iSteamId++)
			{
				GetArrayString(g_hArrayVotePlayerSteamID[iVoter][iVote], iSteamId, strClientAuth, sizeof(strClientAuth));
				if(StrEqual(strTargetSteamId, strClientAuth))
				{
					g_bVoteForTarget[iVoter][iVote][iTarget] = true;
					break;
				}
			}
		}
	}

	for(int iVote = 0; iVote < g_iVoteCount; iVote++)
		CheckVotesForTarget(iVote, iTarget);
}

public void OnClientDisconnect(int iTarget)
{
	g_iVoteCurrent[iTarget] = -1;
	for(int iVote = 0; iVote < g_iVoteCount; iVote++)
	{
		g_iVoteRemaining[iTarget][iVote] = g_iVoteMaxCalls[iVote];
		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
		{
			g_bVoteForTarget[iVoter][iVote][iTarget] = false;
			g_bVoteForTarget[iTarget][iVote][iVoter] = false;
		}

		for(int iMap = 0; iMap < MAX_VOTE_MAPS; iMap++)
			g_bVoteForMap[iTarget][iVote][iMap] = false;

		for(int iOption = 0; iOption < MAX_VOTE_OPTIONS; iOption++)
			g_bVoteForOption[iTarget][iVote][iOption] = false;

		g_bVoteForSimple[iTarget][iVote] = false;

		if(g_hArrayVotePlayerSteamID[iTarget][iVote] != INVALID_HANDLE)
			ClearArray(g_hArrayVotePlayerSteamID[iTarget][iVote]);

		if(g_hArrayVotePlayerIP[iTarget][iVote] != INVALID_HANDLE)
			ClearArray(g_hArrayVotePlayerIP[iTarget][iVote]);
	}

	for(int iVote = 0; iVote < MAX_VOTE_TYPES; iVote++)
	{
		switch(g_iVoteType[iVote])
		{
			case VoteType_Players:
			{
				for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
					CheckVotesForTarget(iVote, iVoter);
			}
			case VoteType_Map:
			{
				for(int iMap = 0; iMap < MAX_VOTE_MAPS; iMap++)
					CheckVotesForMap(iVote, iMap);
			}
			case VoteType_List:
			{
				for(int iOption = 0; iOption < MAX_VOTE_OPTIONS; iOption++)
					CheckVotesForOption(iVote, iOption);
			}
			case VoteType_Simple:
			{
				for(int iSimple = 0; iSimple < MAX_VOTE_TYPES; iSimple++)
					CheckVotesForSimple(iVote);
			}
		}
	}
	// Experimental vote evasion logging
	if(g_iCurrentVoteTarget >= 1 && IsVoteInProgress() && !IsMapEnding) // Do we have a target and the vote is in progress
	{
		if(iTarget == g_iCurrentVoteTarget) // the id of the player who just disconnected matches the vote target id.
		{
			// get target's name
			char LogstrTargetName[MAX_NAME_LENGTH];
			GetClientName(iTarget, LogstrTargetName, sizeof(LogstrTargetName));
			
			// get target's SteamID
			char LstrTargetAuth[MAX_NAME_LENGTH];
			GetClientAuthId(iTarget, AuthId_Steam2, LstrTargetAuth, sizeof(LstrTargetAuth));
			
			// Logging Vote
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Vote target disconnected while vote was in progress! The target was: %s (%s).",
				LogstrTargetName,
				LstrTargetAuth);
				
			if(bAutoBanEnabled)
			{
				if(g_bSourceBans && bAutoBanType) // SourceBans is available and the plugin is told to use it
				{
					SBPP_BanPlayer(0, iTarget, iAutoBanDuration, "Vote Evasion");
				}
				else
				{
					BanClient(iTarget, iAutoBanDuration, BANFLAG_AUTO, "Vote Evasion", "Vote Evasion", "CVR");
				}
				
				if(!g_bSourceBans && bAutoBanType) // Plugin is told to use sourcebans but sourcebans is not available
				{
					LogError("Unable to ban using SourceBans++.");
				}
			}
		}
	}
}

void CreateLogFile() // creates the log file in the system
{
	char cTime[64];
	FormatTime(cTime, sizeof(cTime), "%Y%m%d"); // add date to file name
	// Path used for logging.
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/customvotes_%s.log", cTime);
}

// ====[ COMMANDS ]============================================================
public Action Command_Reload(int iClient, int iArgs)
{
	Config_Load();
	return Plugin_Handled;
}

public Action Command_ChooseVote(int iClient, int iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;
		
	if(IsMapEnding)
	{
		CReplyToCommand(iClient, "%t", "Map Ending");
		return Plugin_Handled;
	}

	if(IsVoteInProgress())
	{
		CReplyToCommand(iClient, "%t", "Vote in Progress");
		CPrintToChat(iClient, "%t", "Vote in Progress");
		return Plugin_Handled;
	}

	Menu_ChooseVote(iClient);
	return Plugin_Handled;
}

public Action OnClientSayCmd(int iVoter, const char[] strCmd, int iArgc)
{
	if(!IsValidClient(iVoter))
		return Plugin_Continue;

	char strText[255];
	GetCmdArgString(strText, sizeof(strText));
	StripQuotes(strText);

	ReplaceString(strText, sizeof(strText), "!", "");
	ReplaceString(strText, sizeof(strText), "/", "");

	for(int iVote = 0; iVote < g_iVoteCount; iVote++)
	{
		if(StrEqual(g_strVoteChatTrigger[iVote], strText))
		{
			g_iVoteCurrent[iVoter] = iVote;
			switch(g_iVoteType[iVote])
			{
				case VoteType_Players: Menu_PlayersVote(iVote, iVoter);
				case VoteType_Map: Menu_MapVote(iVote, iVoter);
				case VoteType_List: Menu_ListVote(iVote, iVoter);
				case VoteType_Simple: CastSimpleVote(iVote, iVoter);
			}
			break;
		}
	}

	return Plugin_Continue;
}

// ====[ MENUS ]===============================================================
public void Menu_ChooseVote(int iVoter)
{
	Handle hMenu = CreateMenu(MenuHandler_Vote);
	SetMenuTitle(hMenu, "Vote Menu:");

	char strIndex[4];
	int iTime = GetTime();
	for(int iVote = 0; iVote < g_iVoteCount; iVote++)
	{
		int iFlags;

		// Admin access
		if(g_strVoteOverride[iVote][0] && !CheckCommandAccess(iVoter, g_strVoteOverride[iVote], 0))
			{
			iFlags = ITEMDRAW_DISABLED;
			}

		// Max votes
		else if(g_iVoteRemaining[iVoter][iVote] <= 0 && g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
			{
			iFlags = ITEMDRAW_DISABLED;
			}

		// Max passes
		else if(g_iVotePasses[iVote] >= g_iVoteMaxPasses[iVote] && g_iVoteMaxPasses[iVote] > 0)
			{
			iFlags = ITEMDRAW_DISABLED;
			}

		// Cooldown
		else if(iTime - g_iVoteLast[iVoter][iVote] < g_iVoteCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
			{
			iFlags = ITEMDRAW_DISABLED;
			}
			
		// Cooldown (All Players)
		else if(iTime - g_iVoteAllLast[iVote] < g_iVoteAllCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
			{
			iFlags = ITEMDRAW_DISABLED;
			}

		IntToString(iVote, strIndex, sizeof(strIndex));

		char strName[56];
		strcopy(strName, sizeof(strName), g_strVoteName[iVote]);

		if(g_iVoteType[iVote] == VoteType_Simple)
		{
			if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
			{
				ReplaceString(strName, sizeof(strName), "{On|Off}", "Off", true);
				ReplaceString(strName, sizeof(strName), "{on|off}", "off", true);
			}
			else
			{
				ReplaceString(strName, sizeof(strName), "{On|Off}", "On", true);
				ReplaceString(strName, sizeof(strName), "{on|off}", "on", true);
			}

			if(!g_bVoteCallVote[iVote])
				Format(strName, sizeof(strName), "%s [%i/%i]", strName, GetVotesForSimple(iVote), GetRequiredVotes(iVote));
		}

		AddMenuItem(hMenu, strIndex, strName, iFlags);
	}

	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bKzTimer)
		{
			KZTimer_StopUpdatingOfClimbersMenu(i);
		}
	}

	DisplayMenu(hMenu, iVoter, 30);
}

public int MenuHandler_Vote(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		char strBuffer[8];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		int iVote = StringToInt(strBuffer);
		g_iVoteCurrent[iVoter] = iVote;

		switch(g_iVoteType[iVote])
		{
			case VoteType_Players: Menu_PlayersVote(iVote, iVoter);
			case VoteType_Map: Menu_MapVote(iVote, iVoter);
			case VoteType_List: Menu_ListVote(iVote, iVoter);
			case VoteType_Simple: CastSimpleVote(iVote, iVoter);
		}
	}
}

public void Menu_PlayersVote(int iVote, int iVoter)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}
	
	if(IsMapEnding)
	{
		CPrintToChat(iVoter, "%t", "Map Ending");
		return;
	}

	if(g_strVoteOverride[iVote][0] && !CheckCommandAccess(iVoter, g_strVoteOverride[iVote], 0))
	{
		CPrintToChat(iVoter, "%t", "No Access");
		return;
	}

	if(g_iVoteRemaining[iVoter][iVote] <= 0 && g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "No Votes Remaining");
		return;
	}

	if(g_iVotePasses[iVote] >= g_iVoteMaxPasses[iVote] && g_iVoteMaxPasses[iVote] > 0)
	{
		CPrintToChat(iVoter, "%t", "Voting No Longer Available");
		return;
	}

	if(g_iMapTime < g_iVoteDelay[iVote])
	{
		CPrintToChat(iVoter, "%t", "Vote Delay", g_iVoteDelay[iVote] - g_iMapTime);
		return;
	}

	int iTime = GetTime();
	if(iTime - g_iVoteLast[iVoter][iVote] < g_iVoteCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteCooldown[iVote] - (iTime - g_iVoteLast[iVoter][iVote]));
		return;
	}
	
	if(iTime - g_iVoteAllLast[iVote] < g_iVoteAllCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteAllCooldown[iVote] - (iTime - g_iVoteAllLast[iVote]));
		return;
	}

	Handle hMenu = CreateMenu(MenuHandler_PlayersVote);
	SetMenuTitle(hMenu, "%s:", g_strVoteName[iVote]);
	SetMenuExitBackButton(hMenu, true);

	int iCount;
	char strUserId[8];
	char strName[MAX_NAME_LENGTH + 12];

	int iVoterTeam = GetClientTeam(iVoter);
	for(int iTarget = 1; iTarget <= MaxClients; iTarget++) if(IsClientInGame(iTarget))
	{
		if(!g_bVotePlayersBots[iVote] && IsFakeClient(iTarget))
			continue;

		if(g_bVotePlayersTeam[iVote] && GetClientTeam(iTarget) != iVoterTeam)
			continue;

		int iFlags;
		if(iTarget == iVoter)
			iFlags = ITEMDRAW_DISABLED;

		AdminId idAdmin = GetUserAdmin(iTarget);
		if(idAdmin != INVALID_ADMIN_ID)
		{
			if(GetAdminImmunityLevel(idAdmin) >= g_iVoteImmunity[iVote])
				iFlags = ITEMDRAW_DISABLED;
		}

		IntToString(GetClientUserId(iTarget), strUserId, sizeof(strUserId));

		if(g_bVoteCallVote[iVote])
			GetClientName(iTarget, strName, sizeof(strName));
		else
			Format(strName, sizeof(strName), "%N [%i/%i]", iTarget, GetVotesForTarget(iVote, iTarget), GetRequiredVotes(iVote));

		if(GetVotesForTarget(iVote, iTarget) > 0)
			InsertMenuItem(hMenu, 0, strUserId, strName, iFlags);
		else
			AddMenuItem(hMenu, strUserId, strName, iFlags);
		iCount++;
	}

	if(iCount <= 0)
	{
		CPrintToChat(iVoter, "%t", "No Valid Clients");
		return;
	}

	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bKzTimer)
		{
			KZTimer_StopUpdatingOfClimbersMenu(i);
		}
	}

	DisplayMenu(hMenu, iVoter, 30);
}

public int MenuHandler_PlayersVote(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_ChooseVote(iVoter);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		char strBuffer[8];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		int iVote = g_iVoteCurrent[iVoter];
		if(iVote == -1)
			return;

		if(IsVoteInProgress())
		{
			CPrintToChat(iVoter, "%t", "Vote In Progress");
			return;
		}

		int iTarget = GetClientOfUserId(StringToInt(strBuffer));
		if(!IsValidClient(iTarget))
		{
			CPrintToChat(iVoter, "%t", "Player no longer available");
			Menu_ChooseVote(iVoter);
			return;
		}

		if(g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
		{
			g_iVoteRemaining[iVoter][iVote]--;
			CPrintToChat(iVoter, "%t", "Votes Remaining", g_iVoteRemaining[iVoter][iVote]);
		}

		g_iVoteLast[iVoter][iVote] = GetTime();
		g_iVoteAllLast[iVote] = GetTime();
		if(g_bVoteCallVote[iVote])
		{
			Vote_Players(iVote, iVoter, iTarget);
			return;
		}

		g_bVoteForTarget[iVoter][iVote][iTarget] = true;
		if(!g_bVoteMultiple[iVote])
		{
			for(int iClient = 0; iClient <= MaxClients; iClient++)
			{
				if(iClient != iTarget)
					g_bVoteForTarget[iVoter][iVote][iClient] = false;
			}
		}

		if(g_strVoteCallNotify[iVote][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[iVote]);

			FormatVoteString(iVote, iTarget, strNotification, sizeof(strNotification));
			FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));
			FormatTargetString(iVote, iTarget, strNotification, sizeof(strNotification));

			ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
			ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

			CPrintToChatAll("%s", strNotification);
		}

		if(!IsFakeClient(iTarget) && IsClientAuthorized(iTarget))
		{
			char strAuth[MAX_NAME_LENGTH];
			GetClientAuthId(iVoter, AuthId_Steam2, strAuth, sizeof(strAuth));
			PushArrayString(g_hArrayVotePlayerSteamID[iVoter][iVote], strAuth);
		}

		char strIP[MAX_NAME_LENGTH];
		if(GetClientIP(iTarget, strIP, sizeof(strIP)))
			PushArrayString(g_hArrayVotePlayerIP[iVoter][iVote], strIP);

		CheckVotesForTarget(iVote, iTarget);
		Menu_ChooseVote(iVoter);
	}
}

public void Vote_Players(int iVote, int iVoter, int iTarget)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}

	int iPlayers[MAXPLAYERS + 1];
	int iTotal;
	if (bAfkManagerEnable && g_bAfkManager)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForTarget[i][iVote][iTarget] = false;
			if(IsClientInGame(i) && !IsFakeClient(i) && i != iTarget && !IsAFKClient(i))
			{
				if(g_bVotePlayersTeam[iVote])
				{
					if(GetClientTeam(i) == GetClientTeam(iVoter))
					iPlayers[iTotal++] = i;
				}
				else
					iPlayers[iTotal++] = i;
			}
		}
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForTarget[i][iVote][iTarget] = false;
			if(IsClientInGame(i) && !IsFakeClient(i) && i != iTarget)
			{
				if(g_bVotePlayersTeam[iVote])
				{
					if(GetClientTeam(i) == GetClientTeam(iVoter))
					iPlayers[iTotal++] = i;
				}
				else
					iPlayers[iTotal++] = i;
			}
		}
	}
	if(g_iVoteMinimum[iVote] > iTotal || iTotal <= 0)
	{
		CPrintToChat(iVoter, "%t", "Not Enough Valid Clients");
		return;
	}
	if(g_strVoteStartNotify[iVote][0]) // Vote Start Notify
	{
		char strNotification[255];
		strcopy(strNotification, sizeof(strNotification), g_strVoteStartNotify[iVote]);

		FormatVoteString(iVote, iTarget, strNotification, sizeof(strNotification));
		FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));
		FormatTargetString(iVote, iTarget, strNotification, sizeof(strNotification));

		if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
		}
		else
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
		}

		ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
		ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

		CPrintToChatAll("%s", strNotification);
		
		// get vote name
		char LogstrName[56];
		strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
		
		// get voter's name
		char LogstrVoterName[MAX_NAME_LENGTH];
		GetClientName(iVoter, LogstrVoterName, sizeof(LogstrVoterName));
		
		// get voter's SteamID
		char LstrVoterAuth[MAX_NAME_LENGTH];
		GetClientAuthId(iVoter, AuthId_Steam2, LstrVoterAuth, sizeof(LstrVoterAuth));
		
		// get target's name
		char LogstrTargetName[MAX_NAME_LENGTH];
		GetClientName(iTarget, LogstrTargetName, sizeof(LogstrTargetName));
		
		// get target's SteamID
		char LstrTargetAuth[MAX_NAME_LENGTH];
		GetClientAuthId(iTarget, AuthId_Steam2, LstrTargetAuth, sizeof(LstrTargetAuth));
		
		// Logging Vote
		LogToFileEx(g_sLogPath,
			"[Custom Votes] Vote %s started by %s (%s) targeting %s (%s).",
			LogstrName,
			LogstrVoterName,
			LstrVoterAuth,
			LogstrTargetName,
			LstrTargetAuth);
		
		if (bPrintToAdmins)
			PrintToAdmins("Vote %s started by %s (%s) targeting %s (%s)", LogstrName, LogstrVoterName, LstrVoterAuth, LogstrTargetName, LstrTargetAuth);
	}

	Handle hMenu = CreateMenu(VoteHandler_Players);

	char strTarget[MAX_NAME_LENGTH];
	char strBuffer[MAX_NAME_LENGTH + 12];

	GetClientName(iTarget, strTarget, sizeof(strTarget));
	Format(strBuffer, sizeof(strBuffer), "%s (%s)", g_strVoteName[iVote], strTarget);

	SetMenuTitle(hMenu, "%s", strBuffer);
	SetMenuExitButton(hMenu, false);

	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	
	if(GetRandomInt(1, 2) == 1)
	{
		AddMenuItem(hMenu, "Yes", "Yes");
		AddMenuItem(hMenu, "No", "No");
	}
	else
	{
	AddMenuItem(hMenu, "No", "No");
	AddMenuItem(hMenu, "Yes", "Yes");
	}
	g_iCurrentVoteIndex = iVote;
	g_iCurrentVoteTarget = iTarget;

	IntToString(iTarget, g_strVoteTargetIndex, sizeof(g_strVoteTargetIndex));
	IntToString(GetClientUserId(iTarget), g_strVoteTargetId, sizeof(g_strVoteTargetId));
	GetClientAuthId(iTarget, AuthId_Steam2, g_strVoteTargetAuth, sizeof(g_strVoteTargetAuth));
	strcopy(g_strVoteTargetName, sizeof(g_strVoteTargetName), strTarget);
	
	if(bAutoBanEnabled && bAutoBanWarning)
	{
		CPrintToChat(iTarget, "%t", "Ban Warning");
	}

	VoteMenu(hMenu, iPlayers, iTotal, 30);
}

public int VoteHandler_Players(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}
	if(iAction == MenuAction_Select)
	{
		char strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		if(StrEqual(strInfo, "Yes", false))
		{
			g_bVoteForTarget[iVoter][g_iCurrentVoteIndex][g_iCurrentVoteTarget] = true;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteTarget, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				FormatTargetString(g_iCurrentVoteIndex, g_iCurrentVoteTarget, strNotification, sizeof(strNotification));

				ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
				ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

				CPrintToChatAll("%s", strNotification);
			}
		}
		else if(StrEqual(strInfo, "No", false))
		{
			g_bVoteForTarget[iVoter][g_iCurrentVoteIndex][g_iCurrentVoteTarget] = false;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteTarget, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				FormatTargetString(g_iCurrentVoteIndex, g_iCurrentVoteTarget, strNotification, sizeof(strNotification));

				ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "No", true);
				ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "no", true);

				CPrintToChatAll("%s", strNotification);
			}
		}
	}
	else if(iAction == MenuAction_VoteEnd)
	{
		if(!CheckVotesForTarget(g_iCurrentVoteIndex, g_iCurrentVoteTarget) && g_strVoteFailNotify[g_iCurrentVoteIndex][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVoteFailNotify[g_iCurrentVoteIndex]);

			FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteTarget, strNotification, sizeof(strNotification));
			FormatTargetString(g_iCurrentVoteIndex, g_iCurrentVoteTarget, strNotification, sizeof(strNotification));

			CPrintToChatAll("%s", strNotification);
		}

		g_iCurrentVoteTarget = -1;
		g_iCurrentVoteIndex = -1;

		strcopy(g_strVoteTargetIndex, sizeof(g_strVoteTargetIndex), "");
		strcopy(g_strVoteTargetId, sizeof(g_strVoteTargetId), "");
		strcopy(g_strVoteTargetAuth, sizeof(g_strVoteTargetAuth), "");
		strcopy(g_strVoteTargetName, sizeof(g_strVoteTargetName), "");
	}
}

public void Menu_MapVote(int iVote, int iVoter)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}

	if(g_strVoteOverride[iVote][0] && !CheckCommandAccess(iVoter, g_strVoteOverride[iVote], 0))
	{
		CPrintToChat(iVoter, "%t", "No Access");
		return;
	}

	if(g_iVoteRemaining[iVoter][iVote] <= 0 && g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "No Votes Remaining");
		return;
	}

	if(g_iVotePasses[iVote] >= g_iVoteMaxPasses[iVote] && g_iVoteMaxPasses[iVote] > 0)
	{
		CPrintToChat(iVoter, "%t", "Voting No Longer Available");
		return;
	}

	if(g_iMapTime < g_iVoteDelay[iVote])
	{
		CPrintToChat(iVoter, "%t", "Vote Delay", g_iVoteDelay[iVote] - g_iMapTime);
		return;
	}

	int iTime = GetTime();
	if(iTime - g_iVoteLast[iVoter][iVote] < g_iVoteCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteCooldown[iVote] - (iTime - g_iVoteLast[iVoter][iVote]));
		return;
	}
	
	if(iTime - g_iVoteAllLast[iVote] < g_iVoteAllCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteAllCooldown[iVote] - (iTime - g_iVoteAllLast[iVote]));
		return;
	}

	Handle hMenu = CreateMenu(MenuHandler_MapVote);
	SetMenuTitle(hMenu, "%s:", g_strVoteName[iVote]);
	SetMenuExitBackButton(hMenu, true);

	char strMap[MAX_NAME_LENGTH];
	char strCurrentMap[MAX_NAME_LENGTH];
	char strRecentMap[MAX_NAME_LENGTH];
	char strBuffer[MAX_NAME_LENGTH + 12];

	int iLastMapCount = GetArraySize(g_hArrayRecentMaps);
	if(iLastMapCount > g_iVoteMapRecent[iVote])
		iLastMapCount = g_iVoteMapRecent[iVote];

	int iMapCount = GetArraySize(g_hArrayVoteMapList[iVote]);
	if(iMapCount > MAX_VOTE_MAPS)
		iMapCount = MAX_VOTE_MAPS;

	for(int iMap = 0; iMap < iMapCount; iMap++)
	{
		int iFlags;
		if(g_bVoteMapCurrent[iVote])
		{
			GetArrayString(g_hArrayVoteMapList[iVote], iMap, strMap, sizeof(strMap));
			GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));

			if(StrEqual(strMap, strRecentMap))
				iFlags = ITEMDRAW_DISABLED;
		}

		if(iLastMapCount > 0)
		{
			for(int iLastMap = 0; iLastMap < iLastMapCount; iLastMap++)
			{
				GetArrayString(g_hArrayVoteMapList[iVote], iMap, strMap, sizeof(strMap));
				GetArrayString(g_hArrayRecentMaps, iLastMap, strRecentMap, sizeof(strRecentMap));

				if(StrEqual(strMap, strRecentMap))
				{
					iFlags = ITEMDRAW_DISABLED;
					break;
				}
			}
		}

		if(g_bVoteCallVote[iVote])
			Format(strBuffer, sizeof(strBuffer), "%s", strMap);
		else
			Format(strBuffer, sizeof(strBuffer), "%s [%i/%i]", strMap, GetVotesForMap(iVote, iMap), GetRequiredVotes(iVote));

		if(GetVotesForMap(iVote, iMap) > 0)
			InsertMenuItem(hMenu, 0, strMap, strBuffer, iFlags);
		else
			AddMenuItem(hMenu, strMap, strBuffer, iFlags);
	}

	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bKzTimer)
		{
			KZTimer_StopUpdatingOfClimbersMenu(i);
		}
	}

	DisplayMenu(hMenu, iVoter, 30);
}

public int MenuHandler_MapVote(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_ChooseVote(iVoter);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		char strBuffer[MAX_NAME_LENGTH];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		int iVote = g_iVoteCurrent[iVoter];
		if(iVote == -1)
			return;

		if(IsVoteInProgress())
		{
			CPrintToChat(iVoter, "%t", "Vote In Progress");
			return;
		}

		if(g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
		{
			g_iVoteRemaining[iVoter][iVote]--;
			CPrintToChat(iVoter, "%t", "Votes Remaining", g_iVoteRemaining[iVoter][iVote]);
		}

		int iMap = -1;
		char strMapName[MAX_NAME_LENGTH];
		for(int iMapList = 0; iMapList < GetArraySize(g_hArrayVoteMapList[iVote]); iMapList++)
		{
			GetArrayString(g_hArrayVoteMapList[iVote], iMapList, strMapName, sizeof(strMapName));
			if(StrEqual(strMapName, strBuffer))
			{
				iMap = iMapList;
				break;
			}
		}

		if(iMap == -1)
		{
			Menu_ChooseVote(iVoter);
			return;
		}

		g_iVoteLast[iVoter][iVote] = GetTime();
		if(g_bVoteCallVote[iVote])
		{
			Vote_Map(iVote, iVoter, iMap);
			return;
		}

		if(g_bVoteForMap[iVoter][iVote][iMap])
		{
			CPrintToChat(iVoter, "%t", "Already Voted");
			Menu_ChooseVote(iVoter);
			return;
		}

		g_bVoteForMap[iVoter][iVote][iMap] = true;
		if(!g_bVoteMultiple[iVote])
		{
			for(int iSavedMap = 0; iSavedMap < GetArraySize(g_hArrayVoteMapList[iVote]); iSavedMap++)
			{
				if(iSavedMap != iMap)
					g_bVoteForMap[iVoter][iVote][iSavedMap] = false;
			}
		}

		if(g_strVoteCallNotify[iVote][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[iVote]);

			FormatVoteString(iVote, iMap, strNotification, sizeof(strNotification));
			FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));
			FormatMapString(iVote, iMap, strNotification, sizeof(strNotification));

			ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
			ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

			CPrintToChatAll("%s", strNotification);
		}

		g_iVoteLast[iVoter][iVote] = GetTime();
		g_iVoteAllLast[iVote] = GetTime();
		CheckVotesForMap(iVote, iMap);
		Menu_ChooseVote(iVoter);
	}
}

public void Vote_Map(int iVote, int iVoter, int iMap)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}

	int iPlayers[MAXPLAYERS + 1];
	int iTotal;
	if (bAfkManagerEnable && g_bAfkManager)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForMap[i][iVote][iMap] = false;
			if(IsClientInGame(i) && !IsFakeClient(i) && !IsAFKClient(i))
			{
				iPlayers[iTotal++] = i;
			}
		}
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForMap[i][iVote][iMap] = false;
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				iPlayers[iTotal++] = i;
			}
		}
	}
	if(g_iVoteMinimum[iVote] > iTotal || iTotal <= 0)
	{
		CPrintToChat(iVoter, "%t", "Not Enough Valid Clients");
		return;
	}

	if(g_strVoteStartNotify[iVote][0])
	{
		char strNotification[255];
		strcopy(strNotification, sizeof(strNotification), g_strVoteStartNotify[iVote]);

		FormatVoteString(iVote, iMap, strNotification, sizeof(strNotification));
		FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));
		FormatMapString(iVote, iMap, strNotification, sizeof(strNotification));

		if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
		}
		else
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
		}

		ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
		ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

		CPrintToChatAll("%s", strNotification);
		
		// get vote name
		char LogstrName[56];
		strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
		
		// get voter's name
		char LogstrVoterName[MAX_NAME_LENGTH];
		GetClientName(iVoter, LogstrVoterName, sizeof(LogstrVoterName));
		
		// get voter's SteamID
		char LstrVoterAuth[MAX_NAME_LENGTH];
		GetClientAuthId(iVoter, AuthId_Steam2, LstrVoterAuth, sizeof(LstrVoterAuth));
		
		// get current map name
		char LogstrCurrentMap[MAX_NAME_LENGTH];
		GetCurrentMap(LogstrCurrentMap, sizeof(LogstrCurrentMap));
		
		// get target map name
		char LogstrMap[MAX_NAME_LENGTH];
		GetArrayString(g_hArrayVoteMapList[iVote], iMap, LogstrMap, sizeof(LogstrMap));
		
		// Logging Vote
		LogToFileEx(g_sLogPath,
			"[Custom Votes] Vote %s started by %s (%s). To change map from %s to %s.",
			LogstrName,
			LogstrVoterName,
			LstrVoterAuth,
			LogstrCurrentMap,
			LogstrMap);

		if (bPrintToAdmins)
			PrintToAdmins("Vote %s started by %s (%s). To change map from %s to %s", LogstrName, LogstrVoterName, LstrVoterAuth, LogstrCurrentMap, LogstrMap);
	}

	Handle hMenu = CreateMenu(VoteHandler_Map);

	char strMap[MAX_NAME_LENGTH];
	char strBuffer[MAX_NAME_LENGTH + 12];

	GetArrayString(g_hArrayVoteMapList[iVote], iMap, strMap, sizeof(strMap));
	Format(strBuffer, sizeof(strBuffer), "%s (%s)", g_strVoteName[iVote], strMap);

	SetMenuTitle(hMenu, "%s", strBuffer);
	SetMenuExitButton(hMenu, false);

	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	if(GetRandomInt(1, 2) == 1)
	{
		AddMenuItem(hMenu, "Yes", "Yes");
		AddMenuItem(hMenu, "No", "No");
	}
	else
	{
	AddMenuItem(hMenu, "No", "No");
	AddMenuItem(hMenu, "Yes", "Yes");
	}

	g_iCurrentVoteIndex = iVote;
	g_iCurrentVoteMap = iMap;
	VoteMenu(hMenu, iPlayers, iTotal, 30);
}

public int VoteHandler_Map(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		char strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		if(StrEqual(strInfo, "Yes"))
		{
			g_bVoteForMap[iVoter][g_iCurrentVoteIndex][g_iCurrentVoteMap] = true;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteMap, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				FormatMapString(g_iCurrentVoteIndex, g_iCurrentVoteMap, strNotification, sizeof(strNotification));

				ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
				ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

				CPrintToChatAll("%s", strNotification);
			}
		}
		else if(StrEqual(strInfo, "No"))
		{
			g_bVoteForMap[iVoter][g_iCurrentVoteIndex][g_iCurrentVoteMap] = false;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteMap, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				FormatMapString(g_iCurrentVoteIndex, g_iCurrentVoteMap, strNotification, sizeof(strNotification));

				ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "No", true);
				ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "no", true);

				CPrintToChatAll("%s", strNotification);
			}
		}
	}
	else if(iAction == MenuAction_VoteEnd)
	{
		if(!CheckVotesForMap(g_iCurrentVoteIndex, g_iCurrentVoteMap) && g_strVoteFailNotify[g_iCurrentVoteIndex][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVoteFailNotify[g_iCurrentVoteIndex]);

			FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteMap, strNotification, sizeof(strNotification));
			FormatMapString(g_iCurrentVoteIndex, g_iCurrentVoteMap, strNotification, sizeof(strNotification));

			CPrintToChatAll("%s", strNotification);
		}
		g_iCurrentVoteMap = -1;
		g_iCurrentVoteIndex = -1;
	}
}

public void Menu_ListVote(int iVote, int iVoter)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}

	if(g_strVoteOverride[iVote][0] && !CheckCommandAccess(iVoter, g_strVoteOverride[iVote], 0))
	{
		CPrintToChat(iVoter, "%t", "No Access");
		return;
	}

	if(g_iVoteRemaining[iVoter][iVote] <= 0 && g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "No Votes Remaining");
		return;
	}

	if(g_iVotePasses[iVote] >= g_iVoteMaxPasses[iVote] && g_iVoteMaxPasses[iVote] > 0)
	{
		CPrintToChat(iVoter, "%t", "Voting No Longer Available");
		return;
	}

	if(g_iMapTime < g_iVoteDelay[iVote])
	{
		CPrintToChat(iVoter, "%t", "Vote Delay", g_iVoteDelay[iVote] - g_iMapTime);
		return;
	}

	int iTime = GetTime();
	if(iTime - g_iVoteLast[iVoter][iVote] < g_iVoteCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteCooldown[iVote] - (iTime - g_iVoteLast[iVoter][iVote]));
		return;
	}
	
	if(iTime - g_iVoteAllLast[iVote] < g_iVoteAllCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteAllCooldown[iVote] - (iTime - g_iVoteAllLast[iVote]));
		return;
	}

	Handle hMenu = CreateMenu(MenuHandler_ListVote);
	SetMenuTitle(hMenu, "%s:", g_strVoteName[iVote]);
	SetMenuExitBackButton(hMenu, true);

	char strIndex[MAX_NAME_LENGTH];
	char strBuffer[MAX_NAME_LENGTH + 12];
	char strOptionName[MAX_NAME_LENGTH];
	for(int iOption = 0; iOption < GetArraySize(g_hArrayVoteOptionName[iVote]); iOption++)
	{
		GetArrayString(g_hArrayVoteOptionName[iVote], iOption, strOptionName, sizeof(strOptionName));
		if(g_bVoteCallVote[iVote])
			Format(strBuffer, sizeof(strBuffer), "%s", strOptionName, GetVotesForOption(iVote, iOption), GetRequiredVotes(iVote));
		else
			Format(strBuffer, sizeof(strBuffer), "%s [%i/%i]", strOptionName, GetVotesForOption(iVote, iOption), GetRequiredVotes(iVote));

		IntToString(iOption, strIndex, sizeof(strIndex));

		if(GetVotesForOption(iVote, iOption) > 0)
			InsertMenuItem(hMenu, 0, strIndex, strBuffer);
		else
			AddMenuItem(hMenu, strIndex, strBuffer);
	}

	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bKzTimer)
		{
			KZTimer_StopUpdatingOfClimbersMenu(i);
		}
	}

	DisplayMenu(hMenu, iVoter, 30);
}

public int MenuHandler_ListVote(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_ChooseVote(iVoter);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		char strBuffer[MAX_NAME_LENGTH];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		int iVote = g_iVoteCurrent[iVoter];
		if(iVote == -1)
		{
			return;
		}

		if(IsVoteInProgress())
		{
			CPrintToChat(iVoter, "%t", "Vote In Progress");
			return;
		}

		if(g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
		{
			g_iVoteRemaining[iVoter][iVote]--;
			CPrintToChat(iVoter, "%t", "Votes Remaining", g_iVoteRemaining[iVoter][iVote]);
		}

		int iOption = StringToInt(strBuffer);
		g_iVoteLast[iVoter][iVote] = GetTime();
		if(g_bVoteCallVote[iVote])
		{
			Vote_List(iVote, iVoter, iOption);
			return;
		}

		if(g_bVoteForOption[iVoter][iVote][iOption])
		{
			CPrintToChat(iVoter, "%t", "Already Voted");
			Menu_ChooseVote(iVoter);
			return;
		}

		g_bVoteForOption[iVoter][iVote][iOption] = true;
		if(!g_bVoteMultiple[iVote])
		{
			for(int iOptionList = 0; iOptionList < GetArraySize(g_hArrayVoteOptionName[iVote]); iOptionList++)
			{
				if(iOptionList != iOption)
					g_bVoteForOption[iVoter][iVote][iOptionList] = false;
			}
		}

		if(g_strVoteCallNotify[iVote][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[iVote]);

			FormatVoteString(iVote, iOption, strNotification, sizeof(strNotification));
			FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));
			FormatOptionString(iVote, iOption, strNotification, sizeof(strNotification));

			ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
			ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

			CPrintToChatAll("%s", strNotification);
		}

		g_iVoteLast[iVoter][iVote] = GetTime();
		g_iVoteAllLast[iVote] = GetTime();
		CheckVotesForOption(iVote, iOption);
		Menu_ChooseVote(iVoter);
	}
}

public void Vote_List(int iVote, int iVoter, int iOption)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}

	int iPlayers[MAXPLAYERS + 1];
	int iTotal;

	if (bAfkManagerEnable && g_bAfkManager)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForOption[i][iVote][iOption] = false;
			if(IsClientInGame(i) && !IsFakeClient(i) && !IsAFKClient(i))
			{
				iPlayers[iTotal++] = i;
			}
		}
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForOption[i][iVote][iOption] = false;
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				iPlayers[iTotal++] = i;
			}
		}
	}
	if(g_iVoteMinimum[iVote] > iTotal || iTotal <= 0)
	{
		CPrintToChat(iVoter, "%t", "Not Enough Valid Clients");
		return;
	}

	if(g_strVoteStartNotify[iVote][0])
	{
		char strNotification[255];
		strcopy(strNotification, sizeof(strNotification), g_strVoteStartNotify[iVote]);

		FormatVoteString(iVote, iOption, strNotification, sizeof(strNotification));
		FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));
		FormatOptionString(iVote, iOption, strNotification, sizeof(strNotification));

		if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
		}
		else
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
		}

		ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
		ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

		CPrintToChatAll("%s", strNotification);

		// get vote name
		char LogstrName[56];
		strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
		
		// get voter's name
		char LogstrVoterName[MAX_NAME_LENGTH];
		GetClientName(iVoter, LogstrVoterName, sizeof(LogstrVoterName));
		
		// get voter's SteamID
		char LstrVoterAuth[MAX_NAME_LENGTH];
		GetClientAuthId(iVoter, AuthId_Steam2, LstrVoterAuth, sizeof(LstrVoterAuth));
		
		// get vote option
		char LstrOptionResult[MAX_NAME_LENGTH];
		GetArrayString(g_hArrayVoteOptionResult[iVote], iOption, LstrOptionResult, sizeof(LstrOptionResult));
		
		// Logging Vote
		LogToFileEx(g_sLogPath,
			"[Custom Votes] Vote %s started by %s (%s). Selected Option: %s",
			LogstrName,
			LogstrVoterName,
			LstrVoterAuth,
			LstrOptionResult);

		if (bPrintToAdmins)
			PrintToAdmins("Vote %s started by %s (%s). Selected Option: %s", LogstrName, LogstrVoterName, LstrVoterAuth, LstrOptionResult);
	}

	Handle hMenu = CreateMenu(VoteHandler_List);

	char strOption[MAX_NAME_LENGTH];
	char strBuffer[MAX_NAME_LENGTH + 12];

	GetArrayString(g_hArrayVoteOptionName[iVote], iOption, strOption, sizeof(strOption));
	Format(strBuffer, sizeof(strBuffer), "%s (%s)", g_strVoteName[iVote], strOption);

	SetMenuTitle(hMenu, "%s", strBuffer);
	SetMenuExitButton(hMenu, false);

	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	if(GetRandomInt(1, 2) == 1)
	{
		AddMenuItem(hMenu, "Yes", "Yes");
		AddMenuItem(hMenu, "No", "No");
	}
	else
	{
	AddMenuItem(hMenu, "No", "No");
	AddMenuItem(hMenu, "Yes", "Yes");
	}

	g_iCurrentVoteIndex = iVote;
	g_iCurrentVoteOption = iOption;
	VoteMenu(hMenu, iPlayers, iTotal, 30);
}

public int VoteHandler_List(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		char strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		if(StrEqual(strInfo, "Yes"))
		{
			g_bVoteForOption[iVoter][g_iCurrentVoteIndex][g_iCurrentVoteOption] = true;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteOption, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				FormatOptionString(g_iCurrentVoteIndex, g_iCurrentVoteOption, strNotification, sizeof(strNotification));

				ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
				ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

				CPrintToChatAll("%s", strNotification);
			}
		}
		else if(StrEqual(strInfo, "No"))
		{
			g_bVoteForOption[iVoter][g_iCurrentVoteIndex][g_iCurrentVoteOption] = false;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteOption, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				FormatOptionString(g_iCurrentVoteIndex, g_iCurrentVoteOption, strNotification, sizeof(strNotification));

				ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "No", true);
				ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "no", true);

				CPrintToChatAll("%s", strNotification);
			}
		}
	}
	else if(iAction == MenuAction_VoteEnd)
	{
		if(!CheckVotesForOption(g_iCurrentVoteIndex, g_iCurrentVoteOption) && g_strVoteFailNotify[g_iCurrentVoteIndex][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVoteFailNotify[g_iCurrentVoteIndex]);

			FormatVoteString(g_iCurrentVoteIndex, g_iCurrentVoteOption, strNotification, sizeof(strNotification));
			FormatOptionString(g_iCurrentVoteIndex, g_iCurrentVoteOption, strNotification, sizeof(strNotification));

			CPrintToChatAll("%s", strNotification);
		}
		g_iCurrentVoteOption = -1;
		g_iCurrentVoteIndex = -1;
	}
}

public void CastSimpleVote(int iVote, int iVoter)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}

	if(g_strVoteOverride[iVote][0] && !CheckCommandAccess(iVoter, g_strVoteOverride[iVote], 0))
	{
		CPrintToChat(iVoter, "%t", "No Access");
		return;
	}

	if(g_iVoteRemaining[iVoter][iVote] <= 0 && g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "No Votes Remaining");
		return;
	}

	if(g_iVotePasses[iVote] >= g_iVoteMaxPasses[iVote] && g_iVoteMaxPasses[iVote] > 0)
	{
		CPrintToChat(iVoter, "%t", "Voting No Longer Available");
		return;
	}

	if(g_iMapTime < g_iVoteDelay[iVote])
	{
		CPrintToChat(iVoter, "%t", "Vote Delay", g_iVoteDelay[iVote] - g_iMapTime);
		return;
	}

	int iTime = GetTime();
	if(iTime - g_iVoteLast[iVoter][iVote] < g_iVoteCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteCooldown[iVote] - (iTime - g_iVoteLast[iVoter][iVote]));
		return;
	}
	
	if(iTime - g_iVoteAllLast[iVote] < g_iVoteAllCooldown[iVote] && !CheckCommandAccess(iVoter, "customvotes_cooldown", ADMFLAG_GENERIC))
	{
		CPrintToChat(iVoter, "%t", "Vote Cooldown", g_iVoteAllCooldown[iVote] - (iTime - g_iVoteAllLast[iVote]));
		return;
	}

	if(g_iVoteMaxCalls[iVote] > 0 && !CheckCommandAccess(iVoter, "customvotes_maxvotes", ADMFLAG_GENERIC))
	{
		g_iVoteRemaining[iVoter][iVote]--;
		CPrintToChat(iVoter, "%t", "Votes Remaining", g_iVoteRemaining[iVoter][iVote]);
	}

	g_iVoteLast[iVoter][iVote] = iTime;
	g_iVoteAllLast[iVote] = iTime;
	if(g_bVoteCallVote[iVote])
	{
		Vote_Simple(iVote, iVoter);
		return;
	}

	g_bVoteForSimple[iVoter][iVote] = true;
	if(g_strVoteCallNotify[iVote][0])
	{
		char strNotification[255];
		strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[iVote]);

		FormatVoteString(iVote, _, strNotification, sizeof(strNotification));
		FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));

		if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
		}
		else
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
		}

		ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
		ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

		CPrintToChatAll("%s", strNotification);
	}

	CheckVotesForSimple(iVote);
	Menu_ChooseVote(iVoter);
}

public void Vote_Simple(int iVote, int iVoter)
{
	if(IsVoteInProgress())
	{
		CPrintToChat(iVoter, "%t", "Vote In Progress");
		return;
	}

	int iPlayers[MAXPLAYERS + 1];
	int iTotal;
	
	if (bAfkManagerEnable && g_bAfkManager)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForSimple[i][iVote] = false;
			if(IsClientInGame(i) && !IsFakeClient(i) && !IsAFKClient(i))
			{
				iPlayers[iTotal++] = i;
			}
		}
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_bVoteForSimple[i][iVote] = false;	
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				iPlayers[iTotal++] = i;
			}
		}
	}
	if(g_iVoteMinimum[iVote] > iTotal || iTotal <= 0)
	{
		CPrintToChat(iVoter, "%t", "Not Enough Valid Clients");
		return;
	}

	if(g_strVoteStartNotify[iVote][0])
	{
		char strNotification[255];
		strcopy(strNotification, sizeof(strNotification), g_strVoteStartNotify[iVote]);

		FormatVoteString(iVote, _, strNotification, sizeof(strNotification));
		FormatVoterString(iVote, iVoter, strNotification, sizeof(strNotification));

		if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
		}
		else
		{
			ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
			ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
		}

		ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
		ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

		CPrintToChatAll("%s", strNotification);
		
		// get vote name
		char LogstrName[56];
		strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
		
		// get voter's name
		char LogstrVoterName[MAX_NAME_LENGTH];
		GetClientName(iVoter, LogstrVoterName, sizeof(LogstrVoterName));
		
		// get voter's SteamID
		char LstrVoterAuth[MAX_NAME_LENGTH];
		GetClientAuthId(iVoter, AuthId_Steam2, LstrVoterAuth, sizeof(LstrVoterAuth));
		
		// Logging Vote
		LogToFileEx(g_sLogPath,
			"[Custom Votes] Vote %s started by %s (%s).",
			LogstrName,
			LogstrVoterName,
			LstrVoterAuth);
		
		if (bPrintToAdmins)
			PrintToAdmins("Vote %s started by %s (%s)", LogstrName, LogstrVoterName, LstrVoterAuth);
	}

	Handle hMenu = CreateMenu(VoteHandler_Simple);

	char strName[56];
	strcopy(strName, sizeof(strName), g_strVoteName[iVote]);

	if(g_iVoteType[iVote] == VoteType_Simple)
	{
		if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
		{
			ReplaceString(strName, sizeof(strName), "{On|Off}", "Off", true);
			ReplaceString(strName, sizeof(strName), "{on|off}", "off", true);
		}
		else
		{
			ReplaceString(strName, sizeof(strName), "{On|Off}", "On", true);
			ReplaceString(strName, sizeof(strName), "{on|off}", "on", true);
		}
	}

	SetMenuTitle(hMenu, "%s", strName);
	SetMenuExitButton(hMenu, false);

	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", " ", ITEMDRAW_NOTEXT);
	if(GetRandomInt(1, 2) == 1)
	{
		AddMenuItem(hMenu, "Yes", "Yes");
		AddMenuItem(hMenu, "No", "No");
	}
	else
	{
	AddMenuItem(hMenu, "No", "No");
	AddMenuItem(hMenu, "Yes", "Yes");
	}

	g_iCurrentVoteIndex = iVote;
	VoteMenu(hMenu, iPlayers, iTotal, 30);
}

public int VoteHandler_Simple(Handle hMenu, MenuAction iAction, int iVoter, int iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		char strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		if(StrEqual(strInfo, "Yes"))
		{
			g_bVoteForSimple[iVoter][g_iCurrentVoteIndex] = true;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, _, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				
				// prevents GetConVarBool if we don't have a convar
				if(!StrEqual(g_strVoteConVar[g_iCurrentVoteIndex],""))
				{

					if(GetConVarBool(FindConVar(g_strVoteConVar[g_iCurrentVoteIndex])))
					{
						ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
						ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
					}
					else
					{
						ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
						ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
					}
				
				}
				else
				{

					ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "Yes", true);
					ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "yes", true);

					CPrintToChatAll("%s", strNotification);
				
				}
			}
		}
		else if(StrEqual(strInfo, "No"))
		{
			g_bVoteForSimple[iVoter][g_iCurrentVoteIndex] = false;
			if(g_strVoteCallNotify[g_iCurrentVoteIndex][0])
			{
				char strNotification[255];
				strcopy(strNotification, sizeof(strNotification), g_strVoteCallNotify[g_iCurrentVoteIndex]);

				FormatVoteString(g_iCurrentVoteIndex, _, strNotification, sizeof(strNotification));
				FormatVoterString(g_iCurrentVoteIndex, iVoter, strNotification, sizeof(strNotification));
				
				if(!StrEqual(g_strVoteConVar[g_iCurrentVoteIndex],""))
				{

					if(GetConVarBool(FindConVar(g_strVoteConVar[g_iCurrentVoteIndex])))
					{
						ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
						ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
					}
					else
					{
						ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
						ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
					}
				
				}
				else
				{

					ReplaceString(strNotification, sizeof(strNotification), "{Yes|No}", "No", true);
					ReplaceString(strNotification, sizeof(strNotification), "{yes|no}", "no", true);

					CPrintToChatAll("%s", strNotification);
				
				}
			}
		}
	}
	else if(iAction == MenuAction_VoteEnd)
	{
		if(!CheckVotesForSimple(g_iCurrentVoteIndex) && g_strVoteFailNotify[g_iCurrentVoteIndex][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVoteFailNotify[g_iCurrentVoteIndex]);

			FormatVoteString(g_iCurrentVoteIndex, _, strNotification, sizeof(strNotification));

			CPrintToChatAll("%s", strNotification);
		}
		g_iCurrentVoteIndex = -1;
	}
}

// Reset vote at wave failure.
public Action TF_WaveFailed(Handle event, const char[] name, bool dontBroadcast)
{
	if(bResetOnWaveFailed)
	{
		for(int iVote = 0; iVote < MAX_VOTE_TYPES; iVote++)
		{
			g_iVotePasses[iVote] = 0;
		}
	}
	
	if(bDebugMode) // If debug is enabled, log events
	{
		LogToFileEx(g_sLogPath,
			"[Custom Votes] DEBUG: Event TF_WaveFailed.");
	}
}
// Cancel votes on Game Over (TF2)
public Action TF_TeamPlayWinPanel(Handle event, const char[] name, bool dontBroadcast)
{
	IsMapEnding = true;
	
	if(bCancelVoteGameEnd)
	{
		//g_bMapEnded = true;
		if(IsVoteInProgress()) // is vote in progress?
		{
			CancelVote(); // cancel any running votes on map end.
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Map end while a vote was in progress, canceling vote.");
		}
		g_iCurrentVoteIndex = -1;
		g_iCurrentVoteTarget = -1;
		g_iCurrentVoteMap = -1;
		g_iCurrentVoteOption = -1;
	}
	
	if(bDebugMode) // If debug is enabled, log events
	{
		LogToFileEx(g_sLogPath,
			"[Custom Votes] DEBUG: Event TF_TeamPlayWinPanel. bCancelVoteGameEnd: %d IsVoteInProgress: %d", bCancelVoteGameEnd, IsVoteInProgress());
	}
}
public Action TF_ArenaWinPanel(Handle event, const char[] name, bool dontBroadcast)
{
	IsMapEnding = true;
	
	if(bCancelVoteGameEnd)
	{
		//g_bMapEnded = true;
		if(IsVoteInProgress()) // is vote in progress?
		{
			CancelVote(); // cancel any running votes on map end.
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Map end while a vote was in progress, canceling vote.");
		}
		g_iCurrentVoteIndex = -1;
		g_iCurrentVoteTarget = -1;
		g_iCurrentVoteMap = -1;
		g_iCurrentVoteOption = -1;
	}
	
	if(bDebugMode) // If debug is enabled, log events
	{
		LogToFileEx(g_sLogPath,
			"[Custom Votes] DEBUG: Event TF_ArenaWinPanel. bCancelVoteGameEnd: %d IsVoteInProgress: %d", bCancelVoteGameEnd, IsVoteInProgress());
	}
}
public Action TF_MVMWinPanel(Handle event, const char[] name, bool dontBroadcast)
{
	IsMapEnding = true;

	if(bCancelVoteGameEnd)
	{
		//g_bMapEnded = true;
		if(IsVoteInProgress()) // is vote in progress?
		{
			CancelVote(); // cancel any running votes on map end.
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Map end while a vote was in progress, canceling vote.");
		}
		g_iCurrentVoteIndex = -1;
		g_iCurrentVoteTarget = -1;
		g_iCurrentVoteMap = -1;
		g_iCurrentVoteOption = -1;
	}
	
	if(bDebugMode) // If debug is enabled, log events
	{
		LogToFileEx(g_sLogPath,
			"[Custom Votes] DEBUG: Event TF_MVMWinPanel. bCancelVoteGameEnd: %d IsVoteInProgress: %d", bCancelVoteGameEnd, IsVoteInProgress());
	}
}
// Cancel votes on round end (CSGO)
public Action CSGO_MapEnd(Handle event, const char[] name, bool dontBroadcast)
{
	IsMapEnding = true;
	
	if(bCancelVoteGameEnd)
	{
		//g_bMapEnded = true;
		if(IsVoteInProgress()) // is vote in progress?
		{
			CancelVote(); // cancel any running votes on map end.
			LogToFileEx(g_sLogPath, "[Custom Votes] CS:GO Match End Panel detected while a vote was in progress, canceling vote.");
		}
		g_iCurrentVoteIndex = -1;
		g_iCurrentVoteTarget = -1;
		g_iCurrentVoteMap = -1;
		g_iCurrentVoteOption = -1;
	}
	
	if(bDebugMode) // If debug is enabled, log events
	{
		LogToFileEx(g_sLogPath, "[Custom Votes] DEBUG: Event CSGO_MapEnd. bCancelVoteGameEnd: %d IsVoteInProgress: %d", bCancelVoteGameEnd, IsVoteInProgress());
	}
}

public Action OnLogAction(Handle source, Identity ident, int client, int target, const char[] message)
{
	if((StrContains(message, "changed map to") != -1) && bCancelVoteGameEnd && IsVoteInProgress())
	{
		//g_bMapEnded = true;
		CancelVote(); // cancel any running votes on map end.
		LogToFileEx(g_sLogPath,
			"[Custom Votes] Map manually changed while a vote was in progress, canceling vote.");
	}
	g_iCurrentVoteIndex = -1;
	g_iCurrentVoteTarget = -1;
	g_iCurrentVoteMap = -1;
	g_iCurrentVoteOption = -1;
}

// ====[ FUNCTIONS ]===========================================================
public void Config_Load()
{
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Configuration file %s not found!", g_strConfigFile);
		return;
	}

	Handle hKeyValues = CreateKeyValues("Custom Votes");
	if(!FileToKeyValues(hKeyValues, g_strConfigFile) || !KvGotoFirstSubKey(hKeyValues))
	{
		SetFailState("Improper structure for configuration file %s!", g_strConfigFile);
		return;
	}

	g_iVoteCount = 0;
	g_iCurrentVoteIndex = -1;
	g_iCurrentVoteTarget = -1;
	g_iCurrentVoteMap = -1;
	g_iCurrentVoteOption = -1;

	strcopy(g_strVoteTargetIndex, sizeof(g_strVoteTargetIndex), "");
	strcopy(g_strVoteTargetId, sizeof(g_strVoteTargetId), "");
	strcopy(g_strVoteTargetAuth, sizeof(g_strVoteTargetAuth), "");
	strcopy(g_strVoteTargetName, sizeof(g_strVoteTargetName), "");

	for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
		g_iVoteCurrent[iVoter] = -1;

	for(int iVote = 0; iVote < MAX_VOTE_TYPES; iVote++)
	{
		g_iVoteDelay[iVote] = 0;
		g_iVoteMinimum[iVote] = 0;
		g_iVoteImmunity[iVote] = 0;
		g_iVoteMaxCalls[iVote] = 0;
		g_iVotePasses[iVote] = 0;
		g_iVoteMaxPasses[iVote] = 0;
		g_iVoteMapRecent[iVote] = 0;
		g_bVoteCallVote[iVote] = false;
		g_bVotePlayersBots[iVote] = false;
		g_bVotePlayersTeam[iVote] = false;
		g_bVoteMapCurrent[iVote] = false;
		g_bVoteMultiple[iVote] = false;
		g_flVoteRatio[iVote] = 0.0;
		strcopy(g_strVoteName[iVote], sizeof(g_strVoteName[]), "");
		strcopy(g_strVoteConVar[iVote], sizeof(g_strVoteConVar[]), "");
		strcopy(g_strVoteOverride[iVote], sizeof(g_strVoteOverride[]), "");
		strcopy(g_strVoteCommand[iVote], sizeof(g_strVoteCommand[]), "");
		strcopy(g_strVoteChatTrigger[iVote], sizeof(g_strVoteChatTrigger[]), "");
		strcopy(g_strVoteStartNotify[iVote], sizeof(g_strVoteStartNotify[]), "");
		strcopy(g_strVoteCallNotify[iVote], sizeof(g_strVoteCallNotify[]), "");
		strcopy(g_strVotePassNotify[iVote], sizeof(g_strVotePassNotify[]), "");
		strcopy(g_strVoteFailNotify[iVote], sizeof(g_strVoteFailNotify[]), "");

		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
		{
			g_iVoteRemaining[iVoter][iVote] = 0;
			g_iVoteLast[iVoter][iVote] = 0;
			g_iVoteAllLast[iVote] = 0;
			for(int iTarget = 1; iTarget <= MaxClients; iTarget++)
			{
				g_bVoteForTarget[iTarget][iVote][iVoter] = false;
				g_bVoteForTarget[iVoter][iVote][iTarget] = false;
			}

			for(int iMap = 0; iMap < MAX_VOTE_MAPS; iMap++)
				g_bVoteForMap[iVoter][iVote][iMap] = false;

			for(int iOption = 0; iOption < MAX_VOTE_OPTIONS; iOption++)
				g_bVoteForOption[iVoter][iVote][iOption] = false;

			g_bVoteForSimple[iVoter][iVote] = false;

			if(g_hArrayVotePlayerSteamID[iVoter][iVote] != INVALID_HANDLE)
			{
				CloseHandle(g_hArrayVotePlayerSteamID[iVoter][iVote]);
				g_hArrayVotePlayerSteamID[iVoter][iVote] = INVALID_HANDLE;
			}

			if(g_hArrayVotePlayerIP[iVoter][iVote] != INVALID_HANDLE)
			{
				CloseHandle(g_hArrayVotePlayerIP[iVoter][iVote]);
				g_hArrayVotePlayerIP[iVoter][iVote] = INVALID_HANDLE;
			}
		}

		if(g_hArrayVoteOptionName[iVote] != INVALID_HANDLE)
		{
			CloseHandle(g_hArrayVoteOptionName[iVote]);
			g_hArrayVoteOptionName[iVote] = INVALID_HANDLE;
		}

		if(g_hArrayVoteOptionResult[iVote] != INVALID_HANDLE)
		{
			CloseHandle(g_hArrayVoteOptionResult[iVote]);
			g_hArrayVoteOptionResult[iVote] = INVALID_HANDLE;
		}

		if(g_hArrayVoteMapList[iVote] != INVALID_HANDLE)
		{
			CloseHandle(g_hArrayVoteMapList[iVote]);
			g_hArrayVoteMapList[iVote] = INVALID_HANDLE;
		}
	}

	int iVote;
	do
	{
		// Name of vote
		KvGetSectionName(hKeyValues, g_strVoteName[iVote], sizeof(g_strVoteName[]));

		// Type of vote (Valid types: players, map, list)
		char strType[24];
		KvGetString(hKeyValues, "type", strType, sizeof(strType));

		if(StrEqual(strType, "players"))
			g_iVoteType[iVote] = VoteType_Players;
		else if(StrEqual(strType, "map"))
			g_iVoteType[iVote] = VoteType_Map;
		else if(StrEqual(strType, "list"))
			g_iVoteType[iVote] = VoteType_List;
		else if(StrEqual(strType, "simple"))
			g_iVoteType[iVote] = VoteType_Simple;
		else
		{
			LogError("Invalid vote type for vote %s", g_strVoteName[iVote]);
			continue;
		}

		// Determine if a vote is called to determine the result of the selection, or if each selection is chosen  manually by the players
		g_bVoteCallVote[iVote] = view_as<bool>(KvGetNum(hKeyValues, "vote"));

		// Delay in seconds before players vote after the map has changed
		g_iVoteDelay[iVote] = KvGetNum(hKeyValues, "delay");

		// Delay in seconds before players can vote again after casting a selection
		g_iVoteCooldown[iVote] = KvGetNum(hKeyValues, "cooldown");
		
		// Delay in seconds before all players can vote again after casting a selection
		g_iVoteAllCooldown[iVote] = KvGetNum(hKeyValues, "cooldownall");

		// Minimum votes required for the vote to pass (Overrides ratio)
		g_iVoteMinimum[iVote] = KvGetNum(hKeyValues, "minimum");

		// Admins with equal or higher immunity are removed from the vote
		g_iVoteImmunity[iVote] = KvGetNum(hKeyValues, "immunity");

		// Maximum times a player can vote
		g_iVoteMaxCalls[iVote] = KvGetNum(hKeyValues, "maxcalls");
		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
			g_iVoteRemaining[iVoter][iVote] = g_iVoteMaxCalls[iVote];

		// Maximum times a player can cast a selection
		g_iVoteMaxPasses[iVote] = KvGetNum(hKeyValues, "maxpasses");

		// Allow/disallow players from casting a selection on more than one option
		g_bVoteMultiple[iVote] = view_as<bool>(KvGetNum(hKeyValues, "multiple"));

		// Ratio of players required to cast a selection for the vote to pass
		g_flVoteRatio[iVote] = KvGetFloat(hKeyValues, "ratio");

		// Control variable being changed
		KvGetString(hKeyValues, "cvar", g_strVoteConVar[iVote], sizeof(g_strVoteConVar[]));

		// Admin override (Use this with admin_overrides.cfg to prohibit access from specific players)
		KvGetString(hKeyValues, "override", g_strVoteOverride[iVote], sizeof(g_strVoteOverride[]));

		// Command(s) ran when a vote is passed
		KvGetString(hKeyValues, "command", g_strVoteCommand[iVote], sizeof(g_strVoteCommand[]));

		// Chat trigger to open the vote selections (Do not include ! or / in the trigger)
		KvGetString(hKeyValues, "chattrigger", g_strVoteChatTrigger[iVote], sizeof(g_strVoteChatTrigger[]));

		// Printed to everyone's chat when a player starts a vote
		KvGetString(hKeyValues, "start_notify", g_strVoteStartNotify[iVote], sizeof(g_strVoteStartNotify[]));

		// Printed to everyone's chat when a player casts a selection
		KvGetString(hKeyValues, "call_notify", g_strVoteCallNotify[iVote], sizeof(g_strVoteCallNotify[]));

		// Printed to everyone's chat when the vote passes
		KvGetString(hKeyValues, "pass_notify", g_strVotePassNotify[iVote], sizeof(g_strVotePassNotify[]));

		// Printed to everyone's chat when the vote fails to pass
		KvGetString(hKeyValues, "fail_notify", g_strVoteFailNotify[iVote], sizeof(g_strVoteFailNotify[]));

		switch(g_iVoteType[iVote])
		{
			case VoteType_Players:
			{
				// Allows/disallows casting selections on bots
				g_bVotePlayersBots[iVote] = view_as<bool>(KvGetNum(hKeyValues, "bots"));

				// Restricts players to only casting selections on team members
				g_bVotePlayersTeam[iVote] = view_as<bool>(KvGetNum(hKeyValues, "team"));

				for(int iTarget = 0; iTarget <= MaxClients; iTarget++)
				{
					g_hArrayVotePlayerSteamID[iTarget][iVote] = CreateArray(MAX_NAME_LENGTH);
					g_hArrayVotePlayerIP[iTarget][iVote] = CreateArray(MAX_NAME_LENGTH);
				}
			}
			case VoteType_Map:
			{
				// How many recent maps will be removed from the vote selections
				g_iVoteMapRecent[iVote] = KvGetNum(hKeyValues, "recentmaps");

				// Allows/disallows casting selections on the current map
				g_bVoteMapCurrent[iVote] = view_as<bool>(KvGetNum(hKeyValues, "currentmap"));

				// List of maps to populate the selection list
				char strMapList[24];
				KvGetString(hKeyValues, "maplist", strMapList, sizeof(strMapList), "default");

				g_hArrayVoteMapList[iVote] = CreateArray(MAX_NAME_LENGTH);
				ReadMapList(g_hArrayVoteMapList[iVote], _, strMapList, MAPLIST_FLAG_CLEARARRAY);
			}
			case VoteType_List:
			{
				if(!KvGotoFirstSubKey(hKeyValues, false))
					continue;

				do
				{
					if(!KvGotoFirstSubKey(hKeyValues, false))
						continue;

					g_hArrayVoteOptionName[iVote] = CreateArray(16);
					g_hArrayVoteOptionResult[iVote] = CreateArray(16);
					do
					{
						// Vote option name
						char strOptionName[MAX_NAME_LENGTH];
						KvGetSectionName(hKeyValues, strOptionName, sizeof(strOptionName));
						PushArrayString(g_hArrayVoteOptionName[iVote], strOptionName);

						// Vote option result
						char strOptionResult[MAX_NAME_LENGTH];
						KvGetString(hKeyValues, NULL_STRING, strOptionResult, sizeof(strOptionResult));
						PushArrayString(g_hArrayVoteOptionResult[iVote], strOptionResult);
					}
					while(KvGotoNextKey(hKeyValues, false));
					KvGoBack(hKeyValues);
				}
				while(KvGotoNextKey(hKeyValues, false));
				KvGoBack(hKeyValues);
			}
		}
		iVote++;
	}
	while(KvGotoNextKey(hKeyValues, false));
	CloseHandle(hKeyValues);

	g_iVoteCount = iVote;
	LogMessage("Configuration file %s loaded.", g_strConfigFile);
}

public bool CheckVotesForTarget(int iVote, int iTarget)
{

	int iVotes = GetVotesForTarget(iVote, iTarget);
	int iRequired = GetRequiredVotes(iVote);
	
/* 	if(g_bMapEnded) // if the map ended, always return false
	{
		return false;
	} */

	if(iVotes >= iRequired)
	{
		g_iVotePasses[iVote]++;

		if(g_strVoteCommand[iVote][0])
		{
			char strCommand[255];
			strcopy(strCommand, sizeof(strCommand), g_strVoteCommand[iVote]);

			FormatTargetString(iVote, iTarget, strCommand, sizeof(strCommand));
			ServerCommand(strCommand);
		}

		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
			g_bVoteForTarget[iVoter][iVote][iTarget] = false;

		if(g_strVotePassNotify[iVote][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVotePassNotify[iVote]);

			FormatTargetString(iVote, iTarget, strNotification, sizeof(strNotification));
			CPrintToChatAll("%s", strNotification);
			
			// get vote name
			char LogstrName[56];
			strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
			
			// get target's name
			char LogstrTargetName[MAX_NAME_LENGTH];
			GetClientName(iTarget, LogstrTargetName, sizeof(LogstrTargetName));
			
			// get target's SteamID
			char LstrTargetAuth[MAX_NAME_LENGTH];
			GetClientAuthId(iTarget, AuthId_Steam2, LstrTargetAuth, sizeof(LstrTargetAuth));
			
			// Logging Vote
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Last vote (%s) passed. The Target was: %s (%s).",
				LogstrName,
				LogstrTargetName,
				LstrTargetAuth);
		}
		return true;
	}
	return false;
}

public bool CheckVotesForMap(int iVote, int iMap)
{
	int iVotes = GetVotesForMap(iVote, iMap);
	int iRequired = GetRequiredVotes(iVote);
	
/* 	if(g_bMapEnded) // if the map ended, always return false
	{
		return false;
	} */

	if(iVotes >= iRequired)
	{
		g_iVotePasses[iVote]++;

		if(g_strVoteCommand[iVote][0])
		{
			char strCommand[255];
			strcopy(strCommand, sizeof(strCommand), g_strVoteCommand[iVote]);

			FormatMapString(iVote, iMap, strCommand, sizeof(strCommand));
			ServerCommand(strCommand);
		}

		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
			g_bVoteForMap[iVoter][iVote][iMap] = false;

		if(g_strVotePassNotify[iVote][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVotePassNotify[iVote]);

			FormatMapString(iVote, iMap, strNotification, sizeof(strNotification));
			CPrintToChatAll("%s", strNotification);
			
			// get vote name
			char LogstrName[56];
			strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
			
			// get current map name
			char LogstrCurrentMap[MAX_NAME_LENGTH];
			GetCurrentMap(LogstrCurrentMap, sizeof(LogstrCurrentMap));
			
			// get target map name
			char LogstrMap[MAX_NAME_LENGTH];
			GetArrayString(g_hArrayVoteMapList[iVote], iMap, LogstrMap, sizeof(LogstrMap));
			
			// Logging Vote
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Last vote (%s) passed. Map was changed from %s to %s.",
				LogstrName,
				LogstrCurrentMap,
				LogstrMap);
		}
		return true;
	}
	return false;
}

public bool CheckVotesForOption(int iVote, int iOption)
{
	int iVotes = GetVotesForOption(iVote, iOption);
	int iRequired = GetRequiredVotes(iVote);
	
/* 	if(g_bMapEnded) // if the map ended, always return false
	{
		return false;
	} */

	if(iVotes >= iRequired)
	{
		g_iVotePasses[iVote]++;

		if(g_strVoteCommand[iVote][0])
		{
			char strCommand[255];
			strcopy(strCommand, sizeof(strCommand), g_strVoteCommand[iVote]);

			FormatOptionString(iVote, iOption, strCommand, sizeof(strCommand));
			ServerCommand(strCommand);
		}

		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
			g_bVoteForOption[iVoter][iVote][iOption] = false;

		if(g_strVotePassNotify[iVote][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVotePassNotify[iVote]);

			FormatOptionString(iVote, iOption, strNotification, sizeof(strNotification));
			CPrintToChatAll("%s", strNotification);
			
			// get vote name
			char LogstrName[56];
			strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
			
			// get vote option
			char LstrOptionResult[MAX_NAME_LENGTH];
			GetArrayString(g_hArrayVoteOptionResult[iVote], iOption, LstrOptionResult, sizeof(LstrOptionResult));
			
			// Logging Vote
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Last vote (%s) passed. ( Option: %s ).",
				LogstrName,
				LstrOptionResult);
		}
		return true;
	}
	return false;
}

public bool CheckVotesForSimple(int iVote)
{
	int iVotes = GetVotesForSimple(iVote);
	int iRequired = GetRequiredVotes(iVote);
	
/* 	if(g_bMapEnded) // if the map ended, always return false
	{
		return false;
	} */

	if(iVotes >= iRequired)
	{
		g_iVotePasses[iVote]++;

		if(g_strVoteCommand[iVote][0])
		{
			char strCommand[255];
			strcopy(strCommand, sizeof(strCommand), g_strVoteCommand[iVote]);

			if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
				ReplaceString(strCommand, sizeof(strCommand), "{On|Off}", "0", false);
			else
				ReplaceString(strCommand, sizeof(strCommand), "{On|Off}", "1", false);

			FormatVoteString(iVote, _, strCommand, sizeof(strCommand));
			ServerCommand(strCommand);
		}

		for(int iVoter = 1; iVoter <= MaxClients; iVoter++)
			g_bVoteForSimple[iVoter][iVote] = false;

		if(g_strVotePassNotify[iVote][0])
		{
			char strNotification[255];
			strcopy(strNotification, sizeof(strNotification), g_strVotePassNotify[iVote]);

			if(g_strVoteConVar[iVote][0] && GetConVarBool(FindConVar(g_strVoteConVar[iVote])))
			{
				ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "Off", true);
				ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "off", true);
			}
			else
			{
				ReplaceString(strNotification, sizeof(strNotification), "{On|Off}", "On", true);
				ReplaceString(strNotification, sizeof(strNotification), "{on|off}", "on", true);
			}

			FormatVoteString(iVote, _, strNotification, sizeof(strNotification));
			CPrintToChatAll("%s", strNotification);

			// get vote name
			char LogstrName[56];
			strcopy(LogstrName, sizeof(LogstrName), g_strVoteName[iVote]);
			
			// Logging Vote
			LogToFileEx(g_sLogPath,
				"[Custom Votes] Last vote (%s) passed.",
				LogstrName);
		}
		return true;
	}
	return false;
}

public int GetVotesForTarget(int iVote, int iTarget)
{
	int iCount;
	for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
	{
		if(g_bVoteForTarget[iVoter][iVote][iTarget])
			iCount++;
	}
	return iCount;
}

public int GetVotesForMap(int iVote, int iMap)
{
	int iCount;
	for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
	{
		if(g_bVoteForMap[iVoter][iVote][iMap])
			iCount++;
	}
	return iCount;
}

public int GetVotesForOption(int iVote, int iOption)
{
	int iCount;
	for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
	{
		if(g_bVoteForOption[iVoter][iVote][iOption])
			iCount++;
	}
	return iCount;
}

public int GetVotesForSimple(int iVote)
{
	int iCount;
	for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
	{
		if(g_bVoteForSimple[iVoter][iVote])
			iCount++;
	}
	return iCount;
}

public int GetRequiredVotes(int iVote)
{
	int iCount;
	for(int iVoter = 1; iVoter <= MaxClients; iVoter++) if(IsClientInGame(iVoter))
	{
		if(!IsFakeClient(iVoter))
			iCount++;
	}

	int iRequired = RoundToCeil(float(iCount) * g_flVoteRatio[iVote]);
	if(iRequired < g_iVoteMinimum[iVote])
		iRequired = g_iVoteMinimum[iVote];

	if(iRequired < 1)
		iRequired = 1;

	return iRequired;
}

// ====[ TIMERS ]==============================================================
public Action Timer_Second(Handle hTimer)
{
	g_iMapTime++;
}

// ====[ STOCKS ]==============================================================
stock bool IsValidClient(int iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}
stock bool IsAFKClient(int iClient)
{
	if(AFKM_GetClientAFKTime(iClient) >= iAfkTime)
		return true;
	return false;
 }
stock void FormatVoterString(int iVote, int iVoter, char[] strBuffer, int iBufferSize)
{
	char strVoter[MAX_NAME_LENGTH];
	IntToString(iVoter, strVoter, sizeof(strVoter));

	ReplaceString(strBuffer, iBufferSize, "{VOTER_INDEX}", strVoter, false);

	char strVoterId[MAX_NAME_LENGTH];
	IntToString(GetClientUserId(iVoter), strVoterId, sizeof(strVoterId));

	ReplaceString(strBuffer, iBufferSize, "{VOTER_ID}", strVoterId, false);

	char strVoterSteamId[MAX_NAME_LENGTH];
	GetClientAuthId(iVoter, AuthId_Steam2, strVoterSteamId, sizeof(strVoterSteamId));

	QuoteString(strVoterSteamId, sizeof(strVoterSteamId));
	ReplaceString(strBuffer, iBufferSize, "{VOTER_STEAMID}", strVoterSteamId, false);

	char strVoterName[MAX_NAME_LENGTH];
	GetClientName(iVoter, strVoterName, sizeof(strVoterName));

	QuoteString(strVoterName, sizeof(strVoterName));
	ReplaceString(strBuffer, iBufferSize, "{VOTER_NAME}", strVoterName, false);
}

stock void FormatVoteString(int iVote, int iChoice = -1, char[] strBuffer, int iBufferSize)
{
	char strVoteAmount[MAX_NAME_LENGTH];
	switch(g_iVoteType[iVote])
	{
		case VoteType_Players: IntToString(GetVotesForTarget(iVote, iChoice), strVoteAmount, sizeof(strVoteAmount));
		case VoteType_Map: IntToString(GetVotesForMap(iVote, iChoice), strVoteAmount, sizeof(strVoteAmount));
		case VoteType_List: IntToString(GetVotesForOption(iVote, iChoice), strVoteAmount, sizeof(strVoteAmount));
		case VoteType_Simple: IntToString(GetVotesForSimple(iVote), strVoteAmount, sizeof(strVoteAmount));
	}

	QuoteString(strVoteAmount, sizeof(strVoteAmount));
	ReplaceString(strBuffer, iBufferSize, "{VOTE_AMOUNT}", strVoteAmount, false);

	char strVoteRequired[MAX_NAME_LENGTH];
	IntToString(GetRequiredVotes(iVote), strVoteRequired, sizeof(strVoteRequired));

	QuoteString(strVoteRequired, sizeof(strVoteRequired));
	ReplaceString(strBuffer, iBufferSize, "{VOTE_REQUIRED}", strVoteRequired, false);
}

stock void FormatTargetString(int iVote, int iTarget, char[] strBuffer, int iBufferSize)
{
	// Check if target disconnected (Anti-Grief)
	if(!IsValidClient(iTarget))
	{
		char strAntiGrief[255];
		strcopy(strAntiGrief, sizeof(strAntiGrief), g_strVoteTargetIndex);
		ReplaceString(strBuffer, iBufferSize, "{TARGET_INDEX}", g_strVoteTargetIndex, false);

		strcopy(strAntiGrief, sizeof(strAntiGrief), g_strVoteTargetId);
		ReplaceString(strBuffer, iBufferSize, "{TARGET_ID}", g_strVoteTargetId, false);

		strcopy(strAntiGrief, sizeof(strAntiGrief), g_strVoteTargetAuth);
		QuoteString(strAntiGrief, sizeof(strAntiGrief));
		ReplaceString(strBuffer, iBufferSize, "{TARGET_STEAMID}", g_strVoteTargetAuth, false);

		strcopy(strAntiGrief, sizeof(strAntiGrief), g_strVoteTargetName);
		QuoteString(strAntiGrief, sizeof(strAntiGrief));
		ReplaceString(strBuffer, iBufferSize, "{TARGET_NAME}", g_strVoteTargetName, false);
		return;
	}

	char strTarget[MAX_NAME_LENGTH];
	IntToString(iTarget, strTarget, sizeof(strTarget));

	ReplaceString(strBuffer, iBufferSize, "{TARGET_INDEX}", strTarget, false);

	char strTargetId[MAX_NAME_LENGTH];
	IntToString(GetClientUserId(iTarget), strTargetId, sizeof(strTargetId));

	ReplaceString(strBuffer, iBufferSize, "{TARGET_ID}", strTargetId, false);

	char strTargetSteamId[MAX_NAME_LENGTH];
	GetClientAuthId(iTarget, AuthId_Steam2, strTargetSteamId, sizeof(strTargetSteamId));

	QuoteString(strTargetSteamId, sizeof(strTargetSteamId));
	ReplaceString(strBuffer, iBufferSize, "{TARGET_STEAMID}", strTargetSteamId, false);

	char strTargetName[MAX_NAME_LENGTH];
	GetClientName(iTarget, strTargetName, sizeof(strTargetName));

	QuoteString(strTargetName, sizeof(strTargetName));
	ReplaceString(strBuffer, iBufferSize, "{TARGET_NAME}", strTargetName, false);
}

stock void FormatMapString(int iVote, int iMap, char[] strBuffer, int iBufferSize)
{
	char strMap[MAX_NAME_LENGTH];
	GetArrayString(g_hArrayVoteMapList[iVote], iMap, strMap, sizeof(strMap));

	QuoteString(strMap, sizeof(strMap));
	ReplaceString(strBuffer, iBufferSize, "{MAP_NAME}", strMap, false);

	char strCurrentMap[MAX_NAME_LENGTH];
	GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));

	QuoteString(strCurrentMap, sizeof(strCurrentMap));
	ReplaceString(strBuffer, iBufferSize, "{CURRENT_MAP_NAME}", strCurrentMap, false);
}

stock void FormatOptionString(int iVote, int iOption, char[] strBuffer, int iBufferSize)
{
	char strOptionName[MAX_NAME_LENGTH];
	GetArrayString(g_hArrayVoteOptionName[iVote], iOption, strOptionName, sizeof(strOptionName));

	QuoteString(strOptionName, sizeof(strOptionName));
	ReplaceString(strBuffer, iBufferSize, "{OPTION_NAME}", strOptionName, false);

	char strOptionResult[MAX_NAME_LENGTH];
	GetArrayString(g_hArrayVoteOptionResult[iVote], iOption, strOptionResult, sizeof(strOptionResult));

	QuoteString(strOptionResult, sizeof(strOptionResult));
	ReplaceString(strBuffer, iBufferSize, "{OPTION_RESULT}", strOptionResult, false);
}

stock void QuoteString(char[] strBuffer, int iBuffersize)
{
	Format(strBuffer, iBuffersize + 4, "\"%s\"", strBuffer);
}

void PrintToAdmins(any ...)
{
	char g_Buffer[256];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && CheckCommandAccess(i, "sm_customvotes_printtoadmins", ADMFLAG_GENERIC))
		{
			PrintToChat(i, "%s", g_Buffer);
		}
	}
}