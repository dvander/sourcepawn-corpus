#define PLUGIN_VERSION "3.1"

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <geoip>

#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Votekick (no black screen)",
	author = "Dragokas",
	description = "Vote for player kick with translucent menu",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
};

/*
	Description:
	 - This plugin replaces annoing black screen vote for kick by translucent menu.
	 
	Features:

	 - translucent menu
	 - kick for 1 hour (adjustable) even if the player used a trick to quit from the game before the vote ends.
	 - prevents votekick exploit
	 - un-kick (from the same menu)
	 - vote announcement
	 - no black screen
	 - flexible configuration of access rights
	 - kick reasons (with translation):
	 * See the file: data/votekick_reason.txt
	 - all actions are logged (who kick, whom kick, who tried to kick, ip/country/nick/SteamId, reason ...)
	 - ability to black list specific users (by SteamId or nickname) to prevent them from starting the vote:
	 * See the file: data/votekick_vote_block.txt
	
	Logfile location:
	 - logs/vote_kick.log
	 
	Data file:
	 - data/votekick_vote_block.txt - list of user you may want to disable ability to start the voting
	 * (SteamId and nicknames with simple mask * are allowed).
	 - data/votekick_reason.txt - list of kick reasons (optionally, must be supplied with appropriate translation in file: l4d_votekick.phrases.txt).

	Permissions:
	 - by default, vote can be started by player with "k" (StartVote) flag (adjustable).
	 - by default, vote can be vetoed or force passed by player with "d" (Ban) flag (adjustable).
	 - ability to set minimum time to allow repeat the vote.
	 - ability to set minimum players count to allow starting the vote.
	 - admins cannot target root admin.
	 - non-admins cannot target admins.
	 - users with lower immunity level cannot target users with higher level.
	
	Commands:
	
	- sm_vk (or sm_votekick) - Try to start vote for kick
	- sm_veto - Allow admin to veto current vote
	- sm_votepass - Allow admin to bypass current
	
	Requirements:
	 - GeoIP extension (included in SourceMod).
	
	Languages:
	 - Russian
	 - English
	
	Installation:
	 - copy smx file to addons/sourcemod/plugins/
	 - copy phrases.txt file to addons/sourcemod/translations/
	 - copy data/ .txt file to addons/sourcemod/data/
	
	Credits:
	 - D1maxa - for the initial plugin
	 - MasterMind420 & Powerlord - for suggestions on fixing exploit
	 - SilverShot - for ConVar solution on votekick exploit
	 - toniex - for new update suggestions
	 - Profanuch - for new update suggestions
	 - GoGetSomeSleep - for donation
	 - alliedfront - much thanks for adding full versus support, fixing bot kick exploit and several bugs.
	
	===================================================================================================
	
	ChangeLog:
	Fork by Dragokas:

	Plugin is initially based on the work of D1maxa.
	
	1.2
	 - converted to a new syntax and methodmaps
	 - added VIP immunity support (VIP-module by R1KO).
	 - added logging of kick action and kick attempts.
	 
	1.3
	 - added restriction for vote not often than 1 times on minute
	 - fixed IsClientAdmin() security issue
	 - added to server and console log about the person who started the vote
	 - VIP-module requirement is removed, replaced by "k" (Start Vote) admin flag.
	 - added !veto
	 - added !votepass
	 
	1.4
	 - Added logging of all "callvote" commands to logs/vote.log file.
	 
	1.5
	 - Potentially, fixed exploit for bypassing votekick (thanks to MasterMind420 and Powerlord).
	 - Added ConVars.
	 
	1.6 (07-May-2019)
	 - Plugin is simplified.
	 - Added "sm_votekick_accessflag" ConVar (by default: "k" StartVote flag).
	 - Prohibit "sv_vote_issue_kick_allowed" ConVar to prevent votekick exploit (thanks to SilverShot)
	
	1.7
	 - Some security fixes
	
	1.8 (09-Aug-2019)
	 - Fixed infinite "Vote is in progress"
	 - Fixed rare mem leak.
	
	2.0 (29-Mar-2021)
	 - Added un-kick ability. Use the same command - !vk. Kicked players will be displayed at the very end of the list with the "X" icon.
	 - Vote access is now also checked via inter-players immunity priority.
	 - Vote access is now also checked whether non-admin client try to target an admin (thanks to @Profanuch for suggestion).
	 - Do not display in vote menu the players from another team (in versus mode), except for "z" root admin and "!veto" admin (thanks to @toniex for suggestion).
	 - PRIVATE_STUFF is moved from source code to external file:
	  * "data/votekick_vote_block.txt" - for specific players you may want to block the vote ability (STEAM id and player nicknames are allowed).
	 - Added ConVar "sm_votekick_vetoflag" - Admin flag required to veto/votepass the vote.
	 - Improved blocking of "sv_vote_issue_kick_allowed" ConVar.
	 - Added missing FCVAR_NOTIFY flag to version ConVar for tracking the telemetry.
	 - Better log formatting.
	 
	2.1 (25-Apr-2021)
	 - Fixed exploit allowing players with the bad name to broke the menu.
	 
	2.2 (29-Apr-2021)
	 - Added ability to specify kick reasons with translation support (thanks to GoGetSomeSleep for donation support):
	  * see file data/votekick_reason.txt
	  * see file translations/l4d_votekick.phrases.txt (for adding new translation for kick reasons).
	 - Added ConVar "sm_votekick_show_kick_reason" - Allow to select kick reason? (1 - Yes / 0 - No)
	 - Added ConVar "sm_votekick_show_bots" - Allow to vote kick survivor bots? (1 - Yes / 0 - No)
	 - Added ConVar "sm_votekick_show_self" - Allow to self-kick (for debug purposes)? (1 - Yes / 0 - No)
	 - Performance optimizations.
	 - SM 1.9+ required.
	 
	2.3 (01-Jul-2022)
	 - Allowed to vote everybody against clients who located in deny list (regardless of vote access flag).
	 - Added compatibility with Auto-Name-Changer by Exle. "newnames.txt" file will be detected and merged to deny list.
	 - Fixed compilation warnings on SM 1.11.
	 
	2.4 (01-Jul-2022)
	 - Fix for previous update.
	 - Also, support for old version of Auto-Name-Changer with newnames.ini file name, instead of newnames.txt.
	
	2.5 (07-Jan-2024)
	 - Fixed exploit in kicking bots (coded by alliedfront).
	 
	2.6 (10-Jan-2024)
	 - Added basic support for versus.
	 
	3.0 (29-Jan-2024) by alliedfront
	 - Added full support for versus.
	 - Fixed unkick list overflowing with old players.
	 - Fixed invalid target errors.
	 - Added ConVar "sm_votekick_show_vote_details" - Allow to show mumber of yesVotes - noVotes? (1 - Yes / 0 - No)
	 - Added ConVar "sm_votekick_minplayers_versus" - Minimum players present in versus games to allow starting vote for kick
	 - Added details on count of yes/no/abstained vote results.
	 - Translation file is updated.
	 
	3.1 (30-Jan-2024)
	 - Code optimizations.
	 - Translation file is updated.
*/

char g_sCharKicked[] = "☓";

char FILE_VOTE_BLOCK[PLATFORM_MAX_PATH]		= "data/votekick_vote_block.txt";
char FILE_VOTE_REASON[PLATFORM_MAX_PATH]	= "data/votekick_reason.txt";
char FILE_ANC_BLOCK[PLATFORM_MAX_PATH];
char FILE_ANC_BLOCK_1[PLATFORM_MAX_PATH]	= "cfg/sourcemod/anc/newnames.ini"; // old version naming
char FILE_ANC_BLOCK_2[PLATFORM_MAX_PATH]	= "cfg/sourcemod/anc/newnames.txt";

ArrayList g_hArrayVoteBlock, g_hArrayVoteReason;
StringMap hMapSteam, hMapPlayerName, hMapPlayerTeam;
char g_sSteam[64], g_sIP[32], g_sCountry[4], g_sName[MAX_NAME_LENGTH], g_sLog[PLATFORM_MAX_PATH];
int g_iKickUserId, iLastTime[MAXPLAYERS+1], g_iKickTarget[MAXPLAYERS+1], g_iReason, g_iVoteIssuerTeam;
bool g_bVeto, g_bVotepass, g_bVoteInProgress, g_bVoteDisplayed;

// ConVars
ConVar g_hCvarDelay, g_hCvarKickTime, g_hCvarAnnounceDelay, g_hCvarTimeout, g_hCvarLog, g_hMinPlayers, g_hCvarAccessFlag, g_hCvarVetoFlag;
ConVar g_hCvarGameMode, g_hCvarShowKickReason, g_hCvarShowBots, g_hCvarShowSelf, g_hCvarShowVoteDetails, g_hMinPlayersVersus;
float g_fCvarAnnounceDelay;
int g_iCvarKickTime, g_iCvarDelay, g_iCvarTimeout, g_iMinPlayers, g_iCvarAccessFlag, g_iCvarVetoFlag, g_iMinPlayersVersus;
bool g_bCvarLog, g_bCvarShowKickReason, g_bCvarShowBots, g_bCvarShowSelf, g_bCvarShowVoteDetails, g_bIsVersus;

public void OnPluginStart()
{
	LoadTranslations("l4d_votekick.phrases");
	CreateConVar("l4d_votekick_version", PLUGIN_VERSION, "Version of L4D Votekick on this server", FCVAR_DONTRECORD | CVAR_FLAGS);
	
	g_hCvarDelay = CreateConVar(			"sm_votekick_delay",			"60",			"Minimum delay (in sec.) allowed between votes", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(			"sm_votekick_timeout",			"10",			"How long (in sec.) does the vote last", CVAR_FLAGS );
	g_hCvarAnnounceDelay = CreateConVar(	"sm_votekick_announcedelay",	"2.0",			"Delay (in sec.) between announce and vote menu appearing", CVAR_FLAGS );
	g_hCvarKickTime = CreateConVar(			"sm_votekick_kicktime",			"3600",			"How long player will be kicked (in sec.)", CVAR_FLAGS );
	g_hMinPlayers = CreateConVar(			"sm_votekick_minplayers",		"4",			"Minimum players present in game to allow starting vote for kick", CVAR_FLAGS );
	g_hCvarAccessFlag = CreateConVar(		"sm_votekick_accessflag",		"k",			"Admin flag required to start the vote (leave empty to allow for everybody)", CVAR_FLAGS );
	g_hCvarVetoFlag = CreateConVar(			"sm_votekick_vetoflag",			"d",			"Admin flag required to veto/votepass the vote", CVAR_FLAGS );
	g_hCvarLog = CreateConVar(				"sm_votekick_log",				"1",			"Use logging? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowKickReason = CreateConVar(	"sm_votekick_show_kick_reason",	"0",			"Allow to select kick reason? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowBots = CreateConVar(			"sm_votekick_show_bots",		"0",			"Allow to vote kick survivor bots? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowSelf = CreateConVar(			"sm_votekick_show_self",		"0",			"Allow to self-kick (for debug purposes)? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowVoteDetails = CreateConVar(	"sm_votekick_show_vote_details","0",			"Allow to show mumber of yesVotes - noVotes? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hMinPlayersVersus = CreateConVar(		"sm_votekick_minplayers_versus","4",			"Minimum players present in team to allow starting vote for kick (Versus gamemode)", CVAR_FLAGS );
	
	AutoExecConfig(true,				"sm_votekick");
	
	FindConVar("sv_vote_issue_kick_allowed").AddChangeHook(OnCvarChangedVoteKickMenu);
	
	g_hCvarGameMode = FindConVar("mp_gamemode");
	
	RegConsoleCmd("sm_votekick", 	Command_Votekick,	"Show menu to select player to vote for kick/unkick");
	RegConsoleCmd("sm_vk", 			Command_Votekick,	"Show menu to select player to vote for kick/unkick");
	
	RegConsoleCmd("sm_veto", 		Command_Veto, 		"Allow admin to veto current vote.");
	RegConsoleCmd("sm_votepass", 	Command_Votepass, 	"Allow admin to bypass current vote.");

	hMapSteam = new StringMap();
	hMapPlayerName = new StringMap();
	hMapPlayerTeam = new StringMap();
	
	g_hArrayVoteBlock = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	g_hArrayVoteReason = new ArrayList(ByteCountToCells(32));
	
	BuildPath(Path_SM, FILE_VOTE_BLOCK, sizeof(FILE_VOTE_BLOCK), FILE_VOTE_BLOCK);
	BuildPath(Path_SM, FILE_VOTE_REASON, sizeof(FILE_VOTE_REASON), FILE_VOTE_REASON);
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/vote_kick.log");
	
	if( FileExists(FILE_ANC_BLOCK_1) )
	{
		FILE_ANC_BLOCK = FILE_ANC_BLOCK_1;
	}
	if( FileExists(FILE_ANC_BLOCK_2) )
	{
		FILE_ANC_BLOCK = FILE_ANC_BLOCK_2;
	}
	
	g_hCvarDelay.AddChangeHook(OnCvarChanged);
	g_hCvarTimeout.AddChangeHook(OnCvarChanged);
	g_hCvarAnnounceDelay.AddChangeHook(OnCvarChanged);
	g_hCvarKickTime.AddChangeHook(OnCvarChanged);
	g_hMinPlayers.AddChangeHook(OnCvarChanged);
	g_hCvarAccessFlag.AddChangeHook(OnCvarChanged);
	g_hCvarVetoFlag.AddChangeHook(OnCvarChanged);
	g_hCvarLog.AddChangeHook(OnCvarChanged);
	g_hCvarShowKickReason.AddChangeHook(OnCvarChanged);
	g_hCvarShowBots.AddChangeHook(OnCvarChanged);
	g_hCvarShowSelf.AddChangeHook(OnCvarChanged);
	g_hCvarShowVoteDetails.AddChangeHook(OnCvarChanged);
	g_hMinPlayersVersus.AddChangeHook(OnCvarChanged);
	g_hCvarGameMode.AddChangeHook(OnCvarChanged);
	
	GetCvars();
}

public void OnCvarChangedVoteKickMenu(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if( convar.IntValue != 0 ) // prevents black screen vote kick exploit
	{
		convar.SetInt(0);
	}
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarDelay = g_hCvarDelay.IntValue;
	g_iCvarTimeout = g_hCvarTimeout.IntValue;
	g_fCvarAnnounceDelay = g_hCvarAnnounceDelay.FloatValue;
	g_iCvarKickTime = g_hCvarKickTime.IntValue;
	g_iMinPlayers = g_hMinPlayers.IntValue;
	g_iMinPlayersVersus = g_hMinPlayersVersus.IntValue;
	g_bCvarLog = g_hCvarLog.BoolValue;
	g_bCvarShowBots = g_hCvarShowBots.BoolValue;
	g_bCvarShowSelf = g_hCvarShowSelf.BoolValue;
	g_bCvarShowVoteDetails = g_hCvarShowVoteDetails.BoolValue;
	
	char sReq[32];
	g_hCvarVetoFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 )
		g_iCvarVetoFlag = 0;
	else	
		g_iCvarVetoFlag = ReadFlagString(sReq);
	
	g_hCvarAccessFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 )
		g_iCvarAccessFlag = 0;
	else	
		g_iCvarAccessFlag = ReadFlagString(sReq);
	
	bool bShowReasonPrev = g_bCvarShowKickReason;
	g_bCvarShowKickReason = g_hCvarShowKickReason.BoolValue;
	
	if( g_bCvarShowKickReason && !bShowReasonPrev )
	{
		if( g_hArrayVoteReason.Length == 0 )
		{
			LoadReasonList();
		}
	}
	
	char gt[32];
	g_hCvarGameMode.GetString(gt, sizeof(gt));
	g_bIsVersus = strcmp(gt, "versus", false) == 0;
}

void ReadFileToArrayList(char[] sPath, ArrayList list, bool bClearList = true)
{
	static char str[MAX_NAME_LENGTH];
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		SetFailState("Failed to open file: \"%s\". You are missing at installing!", sPath);
	}
	else {
		if( bClearList )
		{
			list.Clear();
		}
		while( !hFile.EndOfFile() && hFile.ReadLine(str, sizeof(str)) )
		{
			TrimString(str);
			list.PushString(str);
		}
		delete hFile;
	}
}

void LoadBlockList()
{
	static int ft_block, ft_anc_block;
	int ft1, ft2;
	
	if( ft_block 		!= (ft1 = GetFileTime(FILE_VOTE_BLOCK, 	FileTime_LastChange)) 
	||	ft_anc_block 	!= (ft2 = GetFileTime(FILE_ANC_BLOCK, 	FileTime_LastChange)) )
	{
		ft_block = ft1;
		ft_anc_block = ft2;
		ReadFileToArrayList(FILE_VOTE_BLOCK, 	g_hArrayVoteBlock);
		if( FILE_ANC_BLOCK[0] != 0 && ft_anc_block != -1 )
		{
			ReadFileToArrayList(FILE_ANC_BLOCK, 	g_hArrayVoteBlock, false); // append
		}
	}
}

void LoadReasonList()
{
	static int ft_reason;
	int ft;

	if( g_bCvarShowKickReason )
	{
		ft = GetFileTime(FILE_VOTE_REASON, FileTime_LastChange);
		if( ft != ft_reason )
		{
			ft_reason = ft;
			ReadFileToArrayList(FILE_VOTE_REASON, g_hArrayVoteReason);
		}
	}
}

public void OnMapStart()
{
	LoadBlockList();
	LoadReasonList();
}

public Action Command_Veto(int client, int args)
{
	if( g_bVoteInProgress ) { // IsVoteInProgress() is not working here, sm bug?
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if( g_bVoteInProgress ) {
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	AddCommandListener(CheckVote, "callvote");
	if( !CommandExists ("sm_voteban") )
	{
		RegConsoleCmd("sm_voteban", Command_Votekick);
	}
}

public Action CheckVote(int client, char[] command, int args)
{
	if( client == 0 || !IsClientInGame(client) )
		return Plugin_Stop;
	
	char s[MAX_NAME_LENGTH];
	if( args >= 2 ) {
		GetCmdArg(1, s, sizeof(s));
		if( strcmp(s, "Kick", false) == 0 ) {
			GetCmdArg(2, s, sizeof(s));
			int UserId = StringToInt(s);
			if( UserId ) {
				int target = GetClientOfUserId(UserId);
				if( target && IsClientInGame(target) )
					StartVoteAccessCheck(client, target);
			}
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action Command_Votekick(int client, int args)
{
	if( client ) CreateVotekickMenu(client);
	return Plugin_Handled;
}


void CreateVotekickMenu(int client)
{
	Menu menu = new Menu(Menu_Votekick, MENU_ACTIONS_DEFAULT);
	static char name[MAX_NAME_LENGTH];
	static char uid[12];
	static char menuItem[64];
	static char ip[32];
	static char code[4];
	
	int iIssuerTeam = GetClientTeam(client);
	int iTargetTeam;
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			if( i == client && !g_bCvarShowSelf )
				continue;
			
			if( IsFakeClient(i) )
			{
				if( !g_bCvarShowBots )
					continue;
				
				if( GetClientTeam(i) != 2 )
					continue;
			}
			
			if( g_bIsVersus ) 
			{
				iTargetTeam = GetClientTeam(i);
				if( iIssuerTeam != iTargetTeam && iTargetTeam != 1 ) // allow to kick a spectator
					continue;
			}
			Format(uid, sizeof(uid), "%i", GetClientUserId(i));
			if( GetClientName(i, name, sizeof(name)) )
			{
				NormalizeName(name, sizeof(name));
				
				if( GetClientIP(i, ip, sizeof(ip)) )
				{
					if( !GeoipCode3(ip, code) )
						strcopy(code, sizeof(code), "LAN");

					Format(menuItem, sizeof(menuItem), " %s (%s)", name, code);
					menu.AddItem(uid, menuItem);
				}
				else
					menu.AddItem(uid, name);
			}
		}
	}
	
	static char sTime[32];
	static char sSteam[64];
	int iPlayerTeam;
	StringMapSnapshot hSnap = hMapSteam.Snapshot();
	if( hSnap )
	{
		int iTime;
		for( int i = 0; i < hSnap.Length; i++ )
		{
			hSnap.GetKey(i, sSteam, sizeof(sSteam));
			hMapSteam.GetString(sSteam, sTime, sizeof(sTime));
			iTime = StringToInt(sTime);
			if( (g_iCvarKickTime - (GetTime() - iTime)) < 0 ) {	// leftover expired entries (negative time) of kicked players are deleted, for reasons of clarity
																// (had 3 pages of expired entries after 2 days, which were displayed on each !vk to the client)
				hMapSteam.Remove(sSteam);
				hMapPlayerName.Remove(sSteam);
				hMapPlayerTeam.Remove(sSteam);
			}
			hMapPlayerName.GetString(sSteam, name, sizeof(name));
			hMapPlayerTeam.GetValue(sSteam, iPlayerTeam);
			
			// add target to menu for unkick. active for both: co-op and versus (versus: only issuer team can unkick target)
			// Versus: don't allow opposite team to unkick a player who was kicked by issuer team (could be friend of the opposite team who acts destructive or just a mad anonymous tk)
			if( !(g_bIsVersus && iIssuerTeam != iPlayerTeam) ) {	
				Format(menuItem, sizeof(menuItem), "%s %s %T", g_sCharKicked, name, "time_left", client, (g_iCvarKickTime - (GetTime() - iTime)) / 60);  
				menu.AddItem(sSteam, menuItem);
			}
		}
		delete hSnap;
	}
	
	menu.SetTitle("%T", "Player To Kick", client);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Votekick(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			char info[32];
			if( menu.GetItem(param2, info, sizeof(info)) )
			{
				if( strncmp(info, "STEAM_", 6, false) == 0 )
				{
					StartVoteAccessCheck_UnKick(param1, info);
				}
				else {
					StartVoteAccessCheck(param1, GetClientOfUserId(StringToInt(info)));
				}
			}
		}
	}
	return 0;
}

void StartVoteAccessCheck_UnKick(int client, char[] sSteam)
{
	if( IsVoteInProgress() || g_bVoteInProgress ) {
		CPrintToChat(client, "%t", "other_vote");
		LogVoteAction(client, "[DENY] Reason: another vote is in progress.");
		return;
	}

	if( !IsVoteAllowed(client, -1) )
	{
		char name[MAX_NAME_LENGTH];
		hMapPlayerName.GetString(sSteam, name, sizeof(name));
		CPrintToChatAll("%t", "no_access_specific_unkick", client, name); // "%s tried to use votekick against %s, but has no access."
		LogVoteAction(client, "[NO ACCESS]");
		LogToFileEx(g_sLog, "[TRIED] to kick against: %s", name);
		return;
	}

	StartVoteUnKick(client, sSteam);
}

void StartVoteAccessCheck(int client, int target)
{
	if( IsVoteInProgress() || g_bVoteInProgress ) {
		CPrintToChat(client, "%t", "other_vote");
		LogVoteAction(client, "[DENY] Reason: another vote is in progress.");
		return;
	}

	if( target == 0 || !IsClientInGame(target) )
	{
		CPrintToChat(client, "%t", "not_in_game"); // "Client is already disconnected."
		return;
	}
	
	if( !IsVoteAllowed(client, target) )
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(target, name, sizeof(name));
		CPrintToChatAll("%t", "no_access_specific", client, name); // "%s tried to use votekick against %s, but has no access."
		LogVoteAction(client, "[NO ACCESS]");
		LogVoteAction(target, "[TRIED] to kick against:");
		return;
	}
	
	if( g_bCvarShowKickReason )
	{
		g_iKickTarget[client] = GetClientUserId(target);
		ShowMenuReason(client);
	}
	else {
		StartVoteKick(client, target);
	}
}

void ShowMenuReason(int client)
{
	char sReason[64];
	Menu menu = new Menu(Menu_Reason, MENU_ACTIONS_DEFAULT);
	
	for( int i = 0; i < g_hArrayVoteReason.Length; i++ )
	{
		g_hArrayVoteReason.GetString(i, sReason, sizeof(sReason));
		if( TranslationPhraseExists(sReason) )
		{
			Format(sReason, sizeof(sReason), "%T", sReason, client);
		}
		menu.AddItem("", sReason);
	}
	menu.SetTitle("%T:", "Reason_Menu", client);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Reason(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			int target = GetClientOfUserId(g_iKickTarget[param1]);
			if( target && IsClientInGame(target) )
			{
				g_iReason = param2;
				StartVoteKick(param1, target);
			}
		}
	}
	return 0;
}

int GetRealClientCount() {
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) ) cnt++;
	return cnt;
}

//	Versus: count members of issuer team 
int GetRealTeamClientCount(int iTeam) {
        int cnt;
        for( int i = 1; i <= MaxClients; i++ )
                if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iTeam ) cnt++; //Versus: get only number of members of team of issuer of votekick
        return cnt;
}

bool IsVoteAllowed(int client, int target)
{
	
	bool bHasVoteAccessFlagClient = HasVoteAccessFlag(client);

	if( target != -1)
	{
		if( target == 0 || !IsClientInGame(target) )
			return false;
	
		// This comparison does not trigger an "Exception reported: Client index -1 is invalid", but logically precedes the subsequent comparison 
		if( client == target && bHasVoteAccessFlagClient )
			return true;
	
		if( IsClientRootAdmin(target) )
			return false;
	}
	
	if( IsClientRootAdmin(client) )
		return true;
	
	if( iLastTime[client] != 0 )
	{
		if( iLastTime[client] + g_iCvarDelay > GetTime() ) {
			CPrintToChat(client, "%t", "too_often"); // "You can't vote too often!"
			LogVoteAction(client, "[DENY] Reason: too often.");
			return false;
		}
	}
	iLastTime[client] = GetTime();
	
	// Check if there are enough players in order to vote for kick/unkick. 
	// Versus minimum may be set differently, cfg variable "sm_votekick_minplayers_versus"
	int iClients = GetRealClientCount();
	int iMinPlayers = 0;
	if ( g_bIsVersus ) {
		iClients = GetRealTeamClientCount( GetClientTeam(client) ); //Versus: only team of issuer is allowed to vote
		iMinPlayers = g_iMinPlayersVersus;
	}
	else {
		iMinPlayers = g_iMinPlayers;
	}
	if( iClients < iMinPlayers ) {
		CPrintToChat(client, "%t", "not_enough_players", iMinPlayers); // "Not enough players to start the vote. Required minimum: %i"
		LogVoteAction(client, "[DENY] Reason: Not enough players. Now: %i, required: %i.", iClients, iMinPlayers);
		return false;
	}
	
	if( target != -1)
	{
		if( HasVoteAccessFlag(target) && !bHasVoteAccessFlagClient )
			return false;
	

		if( GetImmunityLevel(client) < GetImmunityLevel(target) )
		{
			CPrintToChat(client, "%t", "no_access_immunity");
			LogVoteAction(client, "[DENY] Reason: Target immunity (%i) is higher than vote issuer (%i)", GetImmunityLevel(target), GetImmunityLevel(client));
			return false;
		}
	
		if( IsAdmin(target) && !IsAdmin(client) )
			return false;

		if( InDenyFile(target, g_hArrayVoteBlock) )	// allow to vote everybody against clients who located in deny list (regardless of vote access flag)
		{
			LogVoteAction(client, "[ALLOW] Reason: target is in deny list.");
			return true;
		}

		if( !g_bCvarShowBots && IsFakeClient(target) )
			return false;
	}
		
	if( InDenyFile(client, g_hArrayVoteBlock) )
	{
		LogVoteAction(client, "[DENY] Reason: player is in deny list.");
		return false;
	}

	return bHasVoteAccessFlagClient;
}

bool InDenyFile(int client, ArrayList list)
{
	static char sName[MAX_NAME_LENGTH], str[MAX_NAME_LENGTH];
	static char sSteam[64];
	
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
	GetClientName(client, sName, sizeof(sName));
	
	for( int i = 0; i < list.Length; i++ )
	{
		list.GetString(i, str, sizeof(str));
	
		if( strncmp(str, "STEAM_", 6, false) == 0 )
		{
			if( strcmp(sSteam, str, false) == 0 )
			{
				return true;
			}
		}
		else {
			if( StrContains(str, "*") ) // allow masks like "Dan*" to match "Danny and Danil"
			{
				ReplaceString(str, sizeof(str), "*", "");
				if( StrContains(sName, str, false) != -1 )
				{
					return true;
				}
			}
			else {
				if( strcmp(sName, str, false) == 0 )
				{
					return true;
				}
			}
		}
	}
	return false;
}

bool GetReason(char[] sReasonEng, int len, bool &bHasPhrase)
{
	if( g_bCvarShowKickReason )
	{
		if( g_iReason < g_hArrayVoteReason.Length )
		{
			g_hArrayVoteReason.GetString(g_iReason, sReasonEng, len);
			bHasPhrase = TranslationPhraseExists(sReasonEng);
			return true;
		}
	}
	return false;
}

// The advanced vote handling callback receives detailed results of voting, 
// which will be displayed to the Team the issuer belongs to (versus) or to all (co-op), 
// if "sm_votekick_show_vote_details" is set to "1" ("0": vote results are not shown)
// This handler is et via Menu.VoteResultCallback property (see below). If this callback is set, 
// MenuAction_VoteEnd will not be called for menu.DisplayVoteToAll and menu.DisplayVote, which is no longer needed. 
// The use of Menu.VoteResultCallback was necessary, because on a tie, a random item is returned by menu.VoteDisplay()
// from a list of the tied items (confirmed in my tests: sometimes in case of a tie it returns 0 and player is kicked out, 
// which is of course not acceptable. Behavior may be due to intended use in the case of map voting).

public void Handle_VoteResults(	Menu menu,	// The menu being voted on.
				int num_votes,				// Number of votes tallied in total.
				int num_clients,			// Number of clients who could vote.
				const int[][] client_info,	// Array of clients.  Use VOTEINFO_CLIENT_ defines.
				int num_items,				// Number of unique items that were selected.
				const int[][] item_info )	// Array of items, sorted by count.  Use VOTEINFO_ITEM defines.
{

	// VoteResults handle not appears when nobody has voted at all, so we need to test only for cases: num_items >= 1

	int yesVotes = 0; int noVotes = 0;
	if ( num_items == 1 )
	{
		// winner vote is array index 0

		if ( item_info[0][VOTEINFO_ITEM_INDEX] == 0 )	// item_info[0][0] ="Yes" wins
			yesVotes = item_info[0][VOTEINFO_ITEM_VOTES];
		else						// item_info[0][1] ="No" wins
			noVotes = item_info[0][VOTEINFO_ITEM_VOTES];
	} 
	else if ( num_items > 1 )
	{
		if ( item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES] )	// Tie: #"Yes" = #"No"
			yesVotes = noVotes = item_info[0][VOTEINFO_ITEM_VOTES];
		else
		{
			if ( item_info[0][VOTEINFO_ITEM_INDEX] == 0 )
			{
				yesVotes = item_info[0][VOTEINFO_ITEM_VOTES];	// item_info[0][0] ="Yes" wins
				noVotes = item_info[1][VOTEINFO_ITEM_VOTES];
			}
			else
			{
				noVotes = item_info[0][VOTEINFO_ITEM_VOTES];	// item_info[0][1] ="No" wins
				yesVotes = item_info[1][VOTEINFO_ITEM_VOTES];
			}
		}
	} 

	// Show vote result details, if "sm_votekick_show_vote_details" is set to "1" in cfg
	// don't show voting results in case of a votepass or veto
	if ( g_bCvarShowVoteDetails && (!g_bVotepass || !g_bVeto) )
		CPrintToChatTeam( "%t", "detailed_vote_results", yesVotes, noVotes, (num_clients-num_votes) ); 

	if ( (yesVotes > noVotes || g_bVotepass) && !g_bVeto )
		Handler_PostVoteAction(true); // kick player
	else
		Handler_PostVoteAction(false); // vote failed

	g_bVoteInProgress = false;
}


void StartVoteKick(int client, int target)
{
	static char sReasonEng[32];
	bool bHasPhrase;
	Menu menu = new Menu(Handle_Votekick, MenuAction_DisplayItem | MenuAction_Display);
	
	// If this callback is set, menu.MenuAction_VoteEnd will not be called. 
	// Needed because on a tie, a random item will be returned by menu.VoteDisplay()
	// from a list of the tied items (confirmed in tests: sometimes in case of a tie it returns 0 and player is kicked out, 
	// which is of course not acceptable. Behavior may be due to intended use in the case of map voting).
	menu.VoteResultCallback = Handle_VoteResults; 
	
	g_iKickUserId = GetClientUserId(target);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	
	GetClientAuthId(target, AuthId_Steam2, g_sSteam, sizeof(g_sSteam));
	GetClientName(target, g_sName, sizeof(g_sName));
	GetClientIP(target, g_sIP, sizeof(g_sIP));
	GeoipCode3(g_sIP, g_sCountry);
	
	GetReason(sReasonEng, sizeof(sReasonEng), bHasPhrase);

	LogVoteAction(client, "[KICK STARTED] by");
	LogVoteAction(target, "[KICK AGAINST] ");
	if( g_bCvarShowKickReason ) {
		LogVoteAction(0, "[REASON] %s", sReasonEng);
		if( bHasPhrase )
			CPrintToChatAll("%t \x01(%t %t\x01)", "vote_started", client, g_sName, "Reason", sReasonEng);
		else
			CPrintToChatAll("%t \x01(%t %s\x01)", "vote_started", client, g_sName, "Reason", sReasonEng);
	}
	else
		CPrintToChatAll("%t", "vote_started", client, g_sName); // %N is started vote for kick: %s
	
	PrintToServer("Vote for kick is started by: %N", client);
	PrintToConsoleAll("Vote for kick is started by: %N", client);
	
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	g_iVoteIssuerTeam = GetClientTeam(client);
	
	CreateTimer(g_fCvarAnnounceDelay, Timer_VoteDelayed, menu);
	if ( g_bIsVersus ) 
		CPrintHintTextToTeam( "%t", "vote_started_announce", g_sName);
	else
		CPrintHintTextToAll("%t", "vote_started_announce", g_sName);
}

void StartVoteUnKick(int client, char[] sSteam)
{
	Menu menu = new Menu(Handle_Votekick, MenuAction_DisplayItem | MenuAction_Display);
	menu.VoteResultCallback = Handle_VoteResults;
	g_iKickUserId = -1;
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;

	strcopy(g_sSteam, sizeof(g_sSteam), sSteam); 
	hMapPlayerName.GetString(sSteam, g_sName, sizeof(g_sName));
	g_sIP[0] = 0;
	g_sCountry[0] = 0;
	
	CPrintToChatAll("%t", "vote_started_unkick", client, g_sName); // %N is started vote for un-kick: %s
	PrintToServer("Vote for un-kick is started by: %N", client);
	PrintToConsoleAll("Vote for un-kick is started by: %N", client);
	
	LogVoteAction(client, "[UN-KICK STARTED] by");
	LogVoteAction(0, "[UN-KICK AGAINST] ");
	
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	g_iVoteIssuerTeam = GetClientTeam(client);
	
	CreateTimer(g_fCvarAnnounceDelay, Timer_VoteDelayed, menu);
	if ( g_bIsVersus ) 
		CPrintHintTextToTeam("%t", "vote_started_announce_unkick", g_sName);
	else
		CPrintHintTextToAll("%t", "vote_started_announce_unkick", g_sName);
}

Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if( g_bVotepass || g_bVeto ) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if( !IsVoteInProgress() ) {
			g_bVoteInProgress = true;
			if( g_bIsVersus )
			{
				int[] iClients = new int[MaxClients];
				int iCount = 0;
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientInGame(i) && GetClientTeam(i) == g_iVoteIssuerTeam )
					{
						iClients[iCount++] = i;
					}
				}
				menu.DisplayVote(iClients, iCount, g_iCvarTimeout);
			}
			else {
				menu.DisplayVoteToAll(g_iCvarTimeout);
			}
			g_bVoteDisplayed = true;
		}
		else {
			delete menu;
		}
	}
	return Plugin_Continue;
}

public int Handle_Votekick(Menu menu, MenuAction action, int param1, int param2)
{
	static char display[64], buffer[255];

	switch( action )
	{
		case MenuAction_End: {
			if( g_bVoteInProgress && g_bVotepass ) { // in case vote is passed with CancelVote(), so MenuAction_VoteEnd is not called.
				Handler_PostVoteAction(true);
			}
			g_bVoteInProgress = false;
			delete menu;
			
			// does currently nothing, just in case
			/*
			if ( param1 == MenuEnd_VotingCancelled )
			{
				PrintToServer("No Votes or Vote Cancelled!");
			}
			else if ( param1 == MenuEnd_VotingDone )
			{
				PrintToServer("Voting Done!");
			}
			*/
		}
		
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			Format(buffer, sizeof(buffer), "%T", display, param1);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			Format(buffer, sizeof(buffer), "%T", g_iKickUserId == -1 ? "vote_started_announce_unkick" : "vote_started_announce", param1, g_sName); // "Do you want to kick: %s ?"
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if( g_iKickUserId == -1 )
	{
		if( bVoteSuccess ) {
			hMapSteam.Remove(g_sSteam);
			hMapPlayerName.Remove(g_sSteam);
			hMapPlayerTeam.Remove(g_sSteam);
			LogVoteAction(0, "[UN-KICKED]");
			CPrintToChatAll("%t", "vote_success_unkick", g_sName);
		}
		else {
			LogVoteAction(0, "[NOT ACCEPTED]");
			CPrintToChatAll("%t", "vote_failed_unkick");
		}
	}
	else {
		if( bVoteSuccess ) {
			bool bHasPhrase;
			char sTime[32], sReason[92], sReasonEng[32];
			int iTarget = GetClientOfUserId(g_iKickUserId);
			if( iTarget && IsClientInGame(iTarget) ) {
				if( g_bCvarShowKickReason )
				{
					if( GetReason(sReasonEng, sizeof(sReasonEng), bHasPhrase) )
					{
						strcopy(sReason, sizeof(sReason), sReasonEng);

						if( bHasPhrase )
						{
							Format(sReason, sizeof(sReason), "%T", sReasonEng, iTarget);
						}
					}
					Format(sReason, sizeof(sReason), "%T: %s", "kick_for", iTarget, sReason); // Kicked for: XXX
				}
				else {
					FormatEx(sReason, sizeof(sReason), "%T", "kick_reason", iTarget); // Kicked for violation
				}
				KickClient(iTarget, sReason);
			}
			FormatEx(sTime, sizeof(sTime), "%i", GetTime());
			hMapSteam.SetString(g_sSteam, sTime, true);
			hMapPlayerName.SetString(g_sSteam, g_sName, true);
			hMapPlayerTeam.SetValue(g_sSteam, g_iVoteIssuerTeam, true);
			
			if( g_bCvarShowKickReason )
			{
				if( bHasPhrase )
				{
					CPrintToChatAll("%t. %t %t", "vote_success", g_sName, "Reason", sReasonEng);
				}
				else {
					CPrintToChatAll("%t. %t %s", "vote_success", g_sName, "Reason", sReasonEng);
				}
			}
			else {
				CPrintToChatAll("%t", "vote_success", g_sName);
			}
			LogVoteAction(0, "[KICKED]");
		}
		else {
			LogVoteAction(0, "[NOT ACCEPTED]");
			CPrintToChatAll("%t", "vote_failed");
		}
	}
	g_bVoteInProgress = false;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	static char sTime[32];
	static int iTime;
	
	if( strcmp(auth, "BOT") != 0 ) {
		if( hMapSteam.GetString(auth, sTime, sizeof(sTime)) ) {
			iTime = StringToInt(sTime);
			if( GetTime() - iTime < g_iCvarKickTime ) { // 1 hour
				KickClient(client, "You have been kicked from session");
				if( g_bCvarLog )
					LogToFileEx(g_sLog, "[DENY] %N | %s cannot join because kicked. Time left = %i min.", client, auth, (g_iCvarKickTime - (GetTime() - iTime)) / 60);
			}
			else {
				hMapSteam.Remove(auth);
				hMapPlayerName.Remove(auth);
				hMapPlayerTeam.Remove(auth);
			}
		}
	}
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

bool HasVoteAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	if (g_iCvarAccessFlag == 0) return true;			// sm_votekick_accessflag="" (leave empty to allow for everybody)
	return (iUserFlag & g_iCvarAccessFlag != 0);
}

bool HasVetoAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	return (iUserFlag & g_iCvarVetoFlag != 0);
}

void LogVoteAction(int client, const char[] format, any ...)
{
	if( !g_bCvarLog )
		return;
	
	static char sSteam[64];
	static char sIP[32];
	static char sCountry[4];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if( client && IsClientInGame(client) ) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		GeoipCode3(sIP, sCountry);
		LogToFileEx(g_sLog, "%s %s (%s | [%s] %s)", buffer, sName, sSteam, sCountry, sIP);
	}
	else {
		LogToFileEx(g_sLog, "%s %s (%s | [%s] %s)", buffer, g_sName, g_sSteam, g_sCountry, g_sIP);
	}
}

stock char[] Translate(int client, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

// Versus: msg only to members of issuer team
stock void CPrintToChatTeam(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
	if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == g_iVoteIssuerTeam )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}

// Versus: msg only to members of issuer team
stock void CPrintHintTextToTeam(const char[] format, any ...)	// Versus: msg only to members of team
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
	if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == g_iVoteIssuerTeam )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}

int GetImmunityLevel(int client)
{
	AdminId id = GetUserAdmin(client);
	if( id != INVALID_ADMIN_ID )
	{
		return GetAdminImmunityLevel(id);
	}
	return 0;
}

bool IsAdmin(int client)
{
	return GetUserAdmin(client) != INVALID_ADMIN_ID;
}

void NormalizeName(char[] name, int len)
{
	int i, j, k, bytes;
	char sNew[MAX_NAME_LENGTH];
	
	while( name[i] )
	{
		bytes = GetCharBytes(name[i]);
		
		if( bytes > 1 )
		{
			for( k = 0; k < bytes; k++ )
			{
				sNew[j++] = name[i++];
			}
		}
		else {
			if( name[i] >= 32 )
			{
				sNew[j++] = name[i++];
			}
			else {
				i++;
			}
		}
	}
	strcopy(name, len, sNew);
}
