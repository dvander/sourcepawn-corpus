/*
	Universal Chatfilter
	Written by almostagreatcoder (almostagreatcoder@web.de)

	Licensed under the GPLv3
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	****

	This plugin needs the Simple Chat Processor (Redux) plugin to work!
	Get it from here: https://forums.alliedmods.net/showthread.php?p=1820365
	
	Make sure that chatfilter.cfg is in your sourcemod/configs/ directory. To
	understand the format of the file and the full potential of this plugin
	please read the comments within the sample config file provided with this
	plugin.

	CVars:
		sm_chatfilter_enabled 1			// Enable/disable this plugin
		sm_chatfilter_keep_penalty 0	// Enable/disable restoring of penalty points counters on reconnect of a player	
		sm_chatfilter_admins 1			// Enable/disable chat and name filtering on admins
	
	Commands:
		sm_chatfilter_status						// display plugin status and information about players
		sm_chatfilter_reload						// reload the config file (chatfilter.cfg)
		sm_chatfilter_group <name|#userid> <group>	// add a player to a group
		sm_chatfilter_ungroup <name|#userid>		// remove a player from his or her group
		sm_chatfilter_reset <name|#userid>	[<section id>]	// reset a player's penalty points to zero. If a section id  
															// is given, only the points for this section will be reset
		sm_showurl <name|#userid> "<url>"					// shows any arbitrary url to a player. (You can make use of
															// the @serverip and @serverport variables here)

*/

// Uncomment the line below to get a whole bunch of PrintToServer debug messages...
//#define DEBUG

#include <sourcemod>
#include <regex>
#include <sdktools>
#include <clientprefs>
#include <adt_trie>

#pragma semicolon 1

#define PLUGIN_NAME 		"Universal Chatfilter"
#define PLUGIN_VERSION 		"1.2.2"
#define PLUGIN_AUTHOR 		"almostagreatcoder"
#define PLUGIN_DESCRIPTION 	"Configurable filter for text chat and player names"
#define PLUGIN_URL 			"https://forums.alliedmods.net/showthread.php?t=288524"

#define CONFIG_FILENAME "chatfilter.cfg"
//#define TRANSLATIONS_FILENAME "chatfilter.phrases"
#define PLUGIN_PREFIX "\x01[SM] (Universal Chatfilter) \x04"
#define MAX_CONFIG_SECTIONS 100
#define MAX_REGEXES 250
#define MAX_REPLACEMENTS 250
#define MAX_ACTIONS 250
#define MAX_STEAMIDS 127

#define MAX_KEYWORD_LENGTH 200
#define MAX_REPLACEMENT_LENGTH 127 * 3
#define MAX_ACTION_LENGTH 250
#define MAX_EXPRESSION_LENGTH 128
#define MAX_MESSAGE_LENGTH 127
#define MAX_NAME_LENGTH_EXTENDED 64
#define MAX_NAME_REPLACEMENTS_LENGTH 160
#define MAX_COOKIE_LENGTH 511
#define MAX_GROUPNAME_LENGTH 50
#define STEAMID_LENGTH 25

#define DEFAULT_MODE 1
#define DEFAULT_PENALTY 0
#define DEFAULT_FILTERNAMES 0
#define DEFAULT_VALIDFROM 1546128000
#define DEFAULT_VALIDTO 2147483647


#define COMMAND_RELOAD "sm_chatfilter_reload"
#define COMMAND_STATUS "sm_chatfilter_status"
#define COMMAND_RESETPLAYER "sm_chatfilter_reset"
#define COMMAND_GROUP "sm_chatfilter_group"
#define COMMAND_UNGROUP "sm_chatfilter_ungroup"
#define COMMAND_SHOWURL "sm_showurl"

#define CVAR_VERSION "chatfilter_version"
#define CVAR_LOGLEVEL "sm_chatfilter_loglevel"
#define CVAR_ENABLED "sm_chatfilter_enabled"
#define CVAR_ADMINS "sm_chatfilter_admins"
#define CVAR_KEEPPOINTS "sm_chatfilter_keep_penalty"


/* These are the special 'tokens' that can be used in filter
 * or replacement expressions. 
 */
#define RGB_REGEX "{RGBA?:([a-fA-F0-9]{6,8})}"	// this one is not a filter token but a replacement token. 
#define COLORTAG_REGEX "{([a-zA-Z]+?)}"		// this one is not a filter token but a replacement token. 
#define COLORFLOW_REGEX "(.*){COLORFLOW:([a-fA-F0-9]{6,8})((?:-(?:[a-fA-F0-9]{6,8}))+)}(.*?){\\/COLORFLOW}(.*)"		// this one is not a filter token but a replacement token. 
#define PLAY_REGEX "(.*?){PLAY:(.*?)}(.*)"	// also a replacement token: plays a sound to client
#define NUMBER_OF_TOKENS 11
#define COOKIE_REGEX "^(\\d+?)/(.*?)/(.+)$"	// this one is not a filter token. It is used for reading a client's cookie 
#define ANTICAPS_REGEX "(.*?){CAPS:(\\d+\\.\\d+)\\/(\\d+)}(.*)"
#define EXIT_REGEX "(.*){EXIT}$"
#define SKIP_REGEX "(.*){SKIP}$"
#define SKIPSECTION_REGEX "(.*){SKIPSECTION}$"
#define GROUP_REGEX "(.*?){GROUPS?:(.*?)}(.*)"
#define ADMIN_REGEX "(.*?){ADMIN}(.*)"
#define NOADMIN_REGEX "(.*?){NOADMIN}(.*)"
#define CASE_REGEX "(.*?){CASE}(.*)"
#define TEAM_REGEX "(.*?){TEAM:(.*?)}(.*)"
#define STEAMID_REGEX "(.*?){(STEAM_\\d:\\d+?:\\d+?)}(.*)"
#define FLAG_ANTICAPS (1 << 10)
#define FLAG_END (1 << 11)
#define FLAG_SKIP (1 << 12)
#define FLAG_ENDSECTION (1 << 13)
#define FLAG_ADMIN (1 << 14)
#define FLAG_NOADMIN (1 << 15)
#define FLAG_IGNORE (1 << 16)


// Plugin definitions
public Plugin:myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
};

/*
 * Structure for action group data
 */
enum enumActionGroup
{
	ag_id = 0,  // unique id number of the action group
	ag_keepPoints,  // 0 = penalty poins are never restored on reconnecting players, 1 = restore points according to cvar
	ag_action1Idx,  // index for action 1 within the global actions array
	ag_action2Idx,  // index for action 2 within the global actions array
	ag_action3Idx,  // index for action 3 within the global actions array
	ag_action1Limit,  // number of penalty points a player must reach so that action 1 is executed
	ag_action2Limit,  // number of penalty points a player must reach so that action 2 is executed
	ag_action3Limit,  // number of penalty points a player must reach so that action 3 is executed
	ag_action1Repeat,  // 0 = action 1 is only executed once (default), 1 = execute it each time the limit is exceeded
	ag_action2Repeat,  // 0 = action 2 is only executed once (default), 1 = execute it each time the limit is exceeded
	ag_action3Repeat // 0 = action 3 is only executed once (default), 1 = execute it each time the limit is exceeded
};

/*
 * Structure for config section data
 */
enum enumConfigSection
{
	cs_actionGroupIdx = 0,  // array index of corresponding action group
	cs_mode,  // mode specified in config section
	cs_filterNames,  // 1 if name filtering is enabled, 0 otherwise
	cs_penalty,  // penalty points
	cs_replaceNameIdxFrom,  // lower array index for name replacement in case of keyword or regex match
	cs_replaceNameIdxTo,  // upper array index for name replacement in case of keyword or regex match
	cs_replaceRegexIdxFrom,  // lower array index for name replacement in case of regex match
	cs_replaceRegexIdxTo,  // upper array index for name replacement in case of regex match
	cs_instantActionIdx,  // array index for instant action in case of keyword or regex match
	cs_probability,  // value between 0 and 100 representing the chance of this section to be applied (default: 100%!)
	cs_validFrom,  // time from which this section shall be active (unix timestamp, default: always)
	cs_validTo // time until this section is valid (section will be inactive from this given timestamp on! Default: never!)
};

/*
 * Structure for anti caps detection expressions
 */
enum enumAntiCaps
{
	ac_findIdx = 0,  // index of the belonging epxression/keyword
	Float:ac_ratio,  // ratio CAPS characters vs. non caps
	ac_minLetters // minimal number of letters
};

/*
 * Structure for color flows
 */
enum enumColorFlow
{
	cf_startR = 0,  // starting value: red part
	cf_startG,  // starting value: green part
	cf_startB,  // starting value: blue part
	cf_startA,  // starting value: alpha channel
	Float:cf_deltaR,  // increment per color step: red
	Float:cf_deltaG,  // increment per color step: green
	Float:cf_deltaB,  // increment per color step: blue
	Float:cf_deltaA // increment per color step: alpha channel
};

#if defined DEBUG
	char dbgchar;
	char dbgchar2;
#endif

// global cvar handles
Handle cvarEnabled;
Handle cvarAdmins;
Handle cvarKeepPoints;
Handle cvarLogLevel;

// global dynamic arrays
Handle g_ActionGroups; // list of all main sections in confing file
Handle g_PlayerPenaltyPoints; // list of arrays holding the players penalty points for each main section group
Handle g_PlayerLastActions; // list of arrays holding the last executed actions on a player
Handle g_ConfigSections; // list of all 2nd level sections ('search & replace sections') in config file
Handle g_RegexHandles; // global array for all regex handles belonging to 'find' keys in config file
Handle g_RegexHandleSections; // list of config section indexes for each handle
Handle g_RegexHandleGroups; // list of chatgroup indexes for each handle
Handle g_RegexHandleTeams; // list of filter-by-team values for each handle
Handle g_AntiCaps; // list of all anti caps filter settings found in the config file
Handle g_Actions; // list of all actions (action1, action2, action3, instant actions) found in config file
Handle g_NameReplacements; // list of all name replacement entries found in the config file
Handle g_Replacements; // list of all replacement entries found in the config file
Handle g_MatchedExpressions; // list of all matched regex handle ids when a chat entry (or player name) is being checked
Handle g_MatchedSections; // list of config section ids when a chat entry (or player name) is being checked
Handle g_GroupList; // list of all player group names found in config file (string array)
Handle g_GroupFlags; // list of all player group flags (int array)
Handle g_GroupMembers; // list of all player to chatgroup assignments found in config file (trie - steam id is key)
Handle g_SteamIdList; // list of all Steam IDs found in config file (string array)

// global static arrays
Handle g_TokenHandles[NUMBER_OF_TOKENS]; // regex handles of all 'tokens' that can be used in find keys (like '{CAPS:0.6/5}' etc)
int g_currentPenaltyPoints[MAXPLAYERS + 1];
int g_currentLastActions[MAXPLAYERS + 1];
int g_PlayerHits[MAXPLAYERS + 1];
int g_PlayerInCheck[MAXPLAYERS + 1];
int g_PlayerGroups[MAXPLAYERS + 1] =  { -1, ... }; // array holding group name indexes for clients
int g_currentSection[enumConfigSection]; // needed for config file parsing and checking: holds details about current section  
int g_currentActionGroup[enumActionGroup]; // needed for config file parsing: holds details about current action group
int g_currentInstantActionIdx;

// cookie handle
Handle g_Cookie;

// other global vars
int g_SectionDepth; // for config file parsing: keeps track of the nesting level of sections
int g_ConfigLine; // for config file parsing: keeps track of the current line number
Handle g_ColorTrie; // trie for all known color token names
int g_InWork = 0; // because the SCP plugin fires OnChatMessage for each recipient, we have to prevent multiple calls.
char g_CurrentName[MAX_NAME_LENGTH_EXTENDED + 1]; // holds the client's name for the current "chunk" of OnChatMessage events
char g_CurrentMessage[MAX_MESSAGE_LENGTH + 1]; // holds the message text for the current "chunk" of OnChatMessage events
char g_LastError[160]; // needed for config file parsing: holds the last error message
int g_ExclusiveChatClient; // for replacements in mode 4: keeps the client's id of the player to whom the message shall be presented
char g_ServerIp[16]; // for replacements in action commands: the current server's ip address
char g_ServerPort[6]; // for replacement in action commands: the current server's game port


//
// Handlers for public events
//

public OnPluginStart() {
	
	LoadTranslations("common.phrases");
	// LoadTranslations(TRANSLATIONS_FILENAME);
	
	g_ActionGroups = CreateArray(enumActionGroup);
	g_PlayerPenaltyPoints = CreateArray(MAXPLAYERS + 1);
	g_PlayerLastActions = CreateArray(MAXPLAYERS + 1);
	g_ConfigSections = CreateArray(enumConfigSection);
	g_RegexHandles = CreateArray();
	g_RegexHandleSections = CreateArray();
	g_RegexHandleGroups = CreateArray();
	g_RegexHandleTeams = CreateArray();
	g_AntiCaps = CreateArray(enumAntiCaps);
	g_Actions = CreateArray(MAX_ACTION_LENGTH);
	g_NameReplacements = CreateArray(MAX_NAME_REPLACEMENTS_LENGTH);
	g_Replacements = CreateArray(MAX_REPLACEMENT_LENGTH);
	g_MatchedExpressions = CreateArray(MAX_KEYWORD_LENGTH);
	g_MatchedSections = CreateArray();
	g_GroupList = CreateArray(MAX_GROUPNAME_LENGTH);
	g_GroupFlags = CreateArray();
	g_GroupMembers = CreateTrie();
	g_SteamIdList = CreateArray(STEAMID_LENGTH);
	
	CreateConVar(CVAR_VERSION, PLUGIN_VERSION, "Universal Chatfilter version.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD | FCVAR_SPONLY);
	cvarLogLevel = CreateConVar(CVAR_LOGLEVEL, "1", "Logging level for Universal Chatfilter. 0 = only log errors, 1 = also log actions, 2 = log actions & replacements", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvarEnabled = CreateConVar(CVAR_ENABLED, "1", "1 to enable the Universal Chatfilter, 0 to turn it off.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarAdmins = CreateConVar(CVAR_ADMINS, "1", "1 to filter, 0 to bypass the chat filtering for admins.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarKeepPoints = CreateConVar(CVAR_KEEPPOINTS, "1", "Chatfilter: 1 to restore the players penalty points on reconnect, 0 to erase them.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	RegAdminCmd(COMMAND_RELOAD, LoadConfigHandler, ADMFLAG_CUSTOM1, "Universal Chatfilter: Reload the plugin configuration file");
	RegConsoleCmd(COMMAND_STATUS, ShowStatusHandler, "Universal Chatfilter: Show plugin status and player information");
	RegAdminCmd(COMMAND_RESETPLAYER, PlayerCommandHandler, ADMFLAG_CUSTOM1, "Universal Chatfilter: Reset a player's penalty points to zero");
	RegAdminCmd(COMMAND_GROUP, PlayerCommandHandler, ADMFLAG_CUSTOM1, "Universal Chatfilter: Assign a player to a group, so that group specific filters are applied (non permanent)");
	RegAdminCmd(COMMAND_UNGROUP, PlayerCommandHandler, ADMFLAG_CUSTOM1, "Universal Chatfilter: Take a player out of his or her group (non permanent)");
	RegAdminCmd(COMMAND_SHOWURL, ShowUrlHandler, ADMFLAG_CUSTOM1, "Universal Chatfilter: Presents a given URL to one or more players");
	HookConVarChange(cvarEnabled, EnableChanged);
	HookEvent("player_changename", OnNameChanged);
	
	g_Cookie = RegClientCookie("DataCookie", "Cookie for the Chatfilter plugin", CookieAccess_Private);
	
	// prepare the different token regexes, which can be used in filter expressions
	// analyse a client's cookie
	g_TokenHandles[0] = CompileRegex(COOKIE_REGEX, PCRE_CASELESS & PCRE_DOTALL);
	// anti caps filter
	g_TokenHandles[1] = CompileRegex(ANTICAPS_REGEX, PCRE_CASELESS);
	// 'END' expression filter
	g_TokenHandles[2] = CompileRegex(EXIT_REGEX, PCRE_CASELESS);
	// 'SKIP' expression filter
	g_TokenHandles[3] = CompileRegex(SKIP_REGEX, PCRE_CASELESS);
	// 'ENDSECTION' expression filter
	g_TokenHandles[4] = CompileRegex(SKIPSECTION_REGEX, PCRE_CASELESS);
	// 'GROUP' expression filter
	g_TokenHandles[5] = CompileRegex(GROUP_REGEX, PCRE_CASELESS);
	// 'ADMIN' expression filter
	g_TokenHandles[6] = CompileRegex(ADMIN_REGEX, PCRE_CASELESS);
	// 'NOADMIN' expression filter
	g_TokenHandles[7] = CompileRegex(NOADMIN_REGEX, PCRE_CASELESS);
	// 'CASE' expression filter (= regex flag)
	g_TokenHandles[8] = CompileRegex(CASE_REGEX, PCRE_CASELESS);
	// 'TEAM' expression filter
	g_TokenHandles[9] = CompileRegex(TEAM_REGEX, PCRE_CASELESS);
	// 'STEAMID' expression filter
	g_TokenHandles[10] = CompileRegex(STEAMID_REGEX, PCRE_CASELESS);
	
	// store server ip and port globally
	int hostip = GetConVarInt(FindConVar("hostip"));
	Format(g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
		(hostip >> 24) & 0x000000FF, 
		(hostip >> 16) & 0x000000FF, 
		(hostip >> 8) & 0x000000FF, 
		hostip & 0x000000FF);
	ConVar hostport = FindConVar("hostport");
	hostport.GetString(g_ServerPort, sizeof(g_ServerPort));
	
	CheckColorTrie();
	AutoExecConfig();
}

public OnPluginEnd() {
	// clear the stuff read from config file
	ResetConfigArrays();
	// close the trie handles
	if (g_GroupMembers != INVALID_HANDLE)
		CloseHandle(g_GroupMembers);
	// close all token regex handles
	for (new i = 0; i < NUMBER_OF_TOKENS; i++)
	if (g_TokenHandles[i] != INVALID_HANDLE)
		CloseHandle(g_TokenHandles[i]);
}

public void OnConfigsExecuted() {
	if (GetConVarBool(cvarEnabled)) {
		MyLoadConfig();
		ProcessAllClientNames();
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	if (client <= MAXPLAYERS) {
		ClearPoints(client, true);
	}
	return true;
}

public OnClientDisconnect(client) {
	if (client <= MAXPLAYERS) {
		WriteClientCookie(client);
		ClearPoints(client, true);
	}
}

public EnableChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "1") == 0) {
			// re-read config when enabled
			MyLoadConfig();
			ProcessAllClientNames();
			PrintToChatAll("%sChatfilter \x01enabled.", PLUGIN_PREFIX);
		} else {
			PrintToChatAll("%sChatfilter \x01disabled.", PLUGIN_PREFIX);
		}
	}
}

public Action:LoadConfigHandler(client, args) {
	MyLoadConfig();
	if (g_LastError[0] == '\0')
		ReplyToCommand(client, "%sConfiguration reloaded", PLUGIN_PREFIX);
	else
		ReplyToCommand(client, "%sConfiguration file parsing failed! %s", PLUGIN_PREFIX, g_LastError);
	return Plugin_Handled;
}

MyLoadConfig() {
	g_SectionDepth = 0;
	g_ConfigLine = 0;
	ResetConfigArrays();
	char g_ConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, g_ConfigFile, sizeof(g_ConfigFile), "configs/%s", CONFIG_FILENAME);
	
	g_LastError = "";
	Handle parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);
	SMC_SetRawLine(parser, Config_NewLine);
	SMC_ParseFile(parser, g_ConfigFile);
	CloseHandle(parser);
	// process the group members definition
	GroupClient(0);
}

public SMCResult:Config_NewLine(Handle:parser, const char[] line, int lineno) {
	g_ConfigLine = lineno;
	return SMCParse_Continue;
}


public SMCResult:Config_NewSection(Handle:parser, const String:name[], bool:quotes) {
	new SMCResult:result = SMCParse_Continue;
	g_SectionDepth++;
	
	if (g_SectionDepth == 1) {
		// new action group
		g_currentActionGroup[ag_id] = -1;
		g_currentActionGroup[ag_keepPoints] = 1;
		g_currentActionGroup[ag_action1Idx] = -1;
		g_currentActionGroup[ag_action2Idx] = -1;
		g_currentActionGroup[ag_action3Idx] = -1;
		g_currentActionGroup[ag_action1Limit] = -1;
		g_currentActionGroup[ag_action2Limit] = -1;
		g_currentActionGroup[ag_action3Limit] = -1;
		g_currentActionGroup[ag_action1Repeat] = 0;
		g_currentActionGroup[ag_action2Repeat] = 0;
		g_currentActionGroup[ag_action3Repeat] = 0;
		g_currentInstantActionIdx = -1;		// is used as default value for the search & replace sections within this action group
	} else if (g_SectionDepth == 2) {
		// new search & replace group
		if (GetArraySize(g_ConfigSections) > MAX_CONFIG_SECTIONS) {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of search & replace sections exceeds limit of %d", g_ConfigLine, MAX_CONFIG_SECTIONS);
			LogError(g_LastError);
		} else {
			// store counters for current section (are processed again at end of section)
			g_currentSection[cs_replaceNameIdxFrom] = GetArraySize(g_NameReplacements);
			g_currentSection[cs_replaceRegexIdxFrom] = GetArraySize(g_Replacements);
			g_currentSection[cs_instantActionIdx] = g_currentInstantActionIdx;
			g_currentSection[cs_mode] = DEFAULT_MODE;
			g_currentSection[cs_penalty] = DEFAULT_PENALTY;
			g_currentSection[cs_filterNames] = DEFAULT_FILTERNAMES;
			g_currentSection[cs_probability] = 100; // default: apply always!
			g_currentSection[cs_validFrom] = DEFAULT_VALIDFROM;
			g_currentSection[cs_validTo] = DEFAULT_VALIDTO;
		}
	} // (ignore any other section nesting level...)
	return result;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	new SMCResult:result = SMCParse_Continue;
	decl intVal;
	// take action only depending on key name, don't bother section nesting here (make things easier for everybody!)
	if (strcmp(key, "find", false) == 0 || strcmp(key, "ignore", false) == 0) {
		if (GetArraySize(g_RegexHandles) <= MAX_REGEXES) {
			new tokenFlags = 0;
			decl Handle:rxHdl;
			new groupIdx = -1;
			new teamIdx = -1;
			decl String:filter[MAX_KEYWORD_LENGTH];
			new substrings = MatchRegex(g_TokenHandles[2], value);
			new flags = PCRE_CASELESS;
			if (substrings > 0) {
				// expression with 'EXIT' condition
				GetRegexSubString(g_TokenHandles[2], 1, filter, sizeof(filter));
				tokenFlags |= FLAG_END;
			} else {
				strcopy(filter, sizeof(filter), value);
			}
			substrings = MatchRegex(g_TokenHandles[3], filter);
			if (substrings > 0) {
				// expression with 'SKIP' condition
				GetRegexSubString(g_TokenHandles[3], 1, filter, sizeof(filter));
				tokenFlags |= FLAG_SKIP;
			}
			substrings = MatchRegex(g_TokenHandles[4], filter);
			if (substrings > 0) {
				// expression with 'SKIPSECTION' condition
				GetRegexSubString(g_TokenHandles[4], 1, filter, sizeof(filter));
				tokenFlags |= FLAG_ENDSECTION;
			}
			substrings = MatchRegex(g_TokenHandles[1], filter);
			if (substrings > 0) {
				// expression with anti caps lock detection
				new acd[enumAntiCaps];
				if (GetRegexSubString(g_TokenHandles[1], 2, filter, sizeof(filter))) {
					acd[ac_findIdx] = GetArraySize(g_RegexHandles);
					acd[ac_ratio] = StringToFloat(filter);
					if (GetRegexSubString(g_TokenHandles[1], 3, filter, sizeof(filter)))
						acd[ac_minLetters] = StringToInt(filter);
					else
						acd[ac_minLetters] = 5;
					PushArrayArray(g_AntiCaps, acd[0]);
					// combine substrings 1 + 4 for new filter expression
					GetRegexSubString(g_TokenHandles[1], 1, filter, sizeof(filter));
					GetRegexSubString(g_TokenHandles[1], 4, filter[strlen(filter)], sizeof(filter) - strlen(filter));
					tokenFlags |= FLAG_ANTICAPS;
				}
			}
			substrings = MatchRegex(g_TokenHandles[5], filter);
			if (substrings > 0) {
				// expression with group detection
				if (GetRegexSubString(g_TokenHandles[5], 2, filter, sizeof(filter))) {
					groupIdx = FindStringInArray(g_GroupList, filter);
					// combine substrings 1 + 3 for new filter expression
					GetRegexSubString(g_TokenHandles[5], 1, filter, sizeof(filter));
					GetRegexSubString(g_TokenHandles[5], 3, filter[strlen(filter)], sizeof(filter) - strlen(filter));
				}
			}
			substrings = MatchRegex(g_TokenHandles[6], filter);
			if (substrings > 0) {
				// expression with admin detection
				tokenFlags |= FLAG_ADMIN;
				// combine substrings 1 + 2 for new filter expression
				GetRegexSubString(g_TokenHandles[6], 1, filter, sizeof(filter));
				GetRegexSubString(g_TokenHandles[6], 2, filter[strlen(filter)], sizeof(filter) - strlen(filter));
			}
			substrings = MatchRegex(g_TokenHandles[7], filter);
			if (substrings > 0) {
				// expression with no admin detection
				tokenFlags |= FLAG_NOADMIN;
				// combine substrings 1 + 2 for new filter expression
				GetRegexSubString(g_TokenHandles[7], 1, filter, sizeof(filter));
				GetRegexSubString(g_TokenHandles[7], 2, filter[strlen(filter)], sizeof(filter) - strlen(filter));
			}
			substrings = MatchRegex(g_TokenHandles[8], filter);
			if (substrings > 0) {
				// expression with case sensitive flag
				flags = 0; // erase the default value PCRE_CASELESS
				// combine substrings 1 + 2 for new filter expression
				GetRegexSubString(g_TokenHandles[8], 1, filter, sizeof(filter));
				GetRegexSubString(g_TokenHandles[8], 2, filter[strlen(filter)], sizeof(filter) - strlen(filter));
			}
			substrings = MatchRegex(g_TokenHandles[9], filter);
			if (substrings > 0) {
				// expression with team detection
				if (GetRegexSubString(g_TokenHandles[9], 2, filter, sizeof(filter))) {
					teamIdx = StringToInt(filter);
					// combine substrings 1 + 3 for new filter expression
					GetRegexSubString(g_TokenHandles[9], 1, filter, sizeof(filter));
					GetRegexSubString(g_TokenHandles[9], 3, filter[strlen(filter)], sizeof(filter) - strlen(filter));
				}
			}
			substrings = MatchRegex(g_TokenHandles[10], filter);
			if (substrings > 0) {
				// expression with Steam Id detection
				if (GetRegexSubString(g_TokenHandles[10], 2, filter, sizeof(filter))) {
					if (GetArraySize(g_SteamIdList) <= MAX_STEAMIDS) {
						PushArrayString(g_SteamIdList, filter);
						// put the Steam Id array index into the upper bits of the token flags
						tokenFlags |= (GetArraySize(g_SteamIdList) << 22);
#if defined DEBUG
						PrintToServer("Got token 'STEAMID' in regex id %d. (%s) Debug: %d, %d, %d", GetArraySize(g_RegexHandles), filter, 11, (11 | (3 << 22)), ((11 | (3 << 22)) >> 22) );
#endif
					}
					// combine substrings 1 + 3 for new filter expression
					GetRegexSubString(g_TokenHandles[10], 1, filter, sizeof(filter));
					GetRegexSubString(g_TokenHandles[10], 3, filter[strlen(filter)], sizeof(filter) - strlen(filter));
				}
			}
			if (strcmp(key, "ignore", false) == 0) {
				// expression shall be ignored
				tokenFlags |= FLAG_IGNORE;
#if defined DEBUG
				PrintToServer("Got token 'IGNORE' in regex id %d. Remaining filter expression: %s", GetArraySize(g_RegexHandles), filter);
#endif
			}
			// compile the rest of the filter expression
			rxHdl = CompileRegex(filter, flags);
			if (rxHdl != INVALID_HANDLE) {
				PushArrayCell(g_RegexHandles, rxHdl);
				PushArrayCell(g_RegexHandleSections, GetArraySize(g_ConfigSections) | tokenFlags);
				PushArrayCell(g_RegexHandleGroups, groupIdx);
				PushArrayCell(g_RegexHandleTeams, teamIdx);
				// CloseHandle(rxHdl); <- don't do this! It would immediately invalidate the handle we have just pushed to the array!
			} else {
				result = SMCParse_Halt;
				Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: '%s' is not a valid regular expression", g_ConfigLine, value);
				LogError(g_LastError);
			}
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of regex elements exceeds limit of %d", g_ConfigLine, MAX_REGEXES);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "action1", false) == 0) {
		if (g_currentActionGroup[ag_action1Idx] == -1)
			if (GetArraySize(g_Actions) <= MAX_ACTIONS) {
				PushArrayString(g_Actions, value);
				g_currentActionGroup[ag_action1Idx] = GetArraySize(g_Actions) - 1;
			} else {
				result = SMCParse_Halt;
				Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of action elements exceeds limit of %d", g_ConfigLine, MAX_ACTIONS);
				LogError(g_LastError);
			}
	} else if (strcmp(key, "action2", false) == 0) {
		if (g_currentActionGroup[ag_action2Idx] == -1)
			if (GetArraySize(g_Actions) <= MAX_ACTIONS) {
				PushArrayString(g_Actions, value);
				g_currentActionGroup[ag_action2Idx] = GetArraySize(g_Actions) - 1;
			} else {
				result = SMCParse_Halt;
				Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of action elements exceeds limit of %d", g_ConfigLine, MAX_ACTIONS);
				LogError(g_LastError);
			}
	} else if (strcmp(key, "action3", false) == 0) {
		if (g_currentActionGroup[ag_action3Idx] == -1)
			if (GetArraySize(g_Actions) <= MAX_ACTIONS) {
				PushArrayString(g_Actions, value);
				g_currentActionGroup[ag_action3Idx] = GetArraySize(g_Actions) - 1;
			} else {
				result = SMCParse_Halt;
				Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of action elements exceeds limit of %d", g_ConfigLine, MAX_ACTIONS);
				LogError(g_LastError);
			}
	} else if (strcmp(key, "instant action", false) == 0) {
		if (g_currentSection[cs_instantActionIdx] == -1)
			if (GetArraySize(g_Actions) <= MAX_ACTIONS) {
				PushArrayString(g_Actions, value);
				if (g_SectionDepth == 1) {
					// we are within an action group - so only set the default for new search & replace sections
					g_currentInstantActionIdx = GetArraySize(g_Actions) - 1;
				} else { 
					// we are within a search & replace sections - so set it directly
					g_currentSection[cs_instantActionIdx] = GetArraySize(g_Actions) - 1;
				}
#if defined DEBUG
				PrintToServer("Found an instant action for group idx %d. (%s is action idx %d)", GetArraySize(g_ActionGroups) + 1, value, GetArraySize(g_Actions) - 1);
#endif
			} else {
				result = SMCParse_Halt;
				Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of action elements exceeds limit of %d", g_ConfigLine, MAX_ACTIONS);
				LogError(g_LastError);
			}
	} else if (strcmp(key, "limit1", false) == 0) {
		intVal = StringToInt(value);
		g_currentActionGroup[ag_action1Limit] = intVal;
	} else if (strcmp(key, "limit2", false) == 0) {
		intVal = StringToInt(value);
		g_currentActionGroup[ag_action2Limit] = intVal;
	} else if (strcmp(key, "limit3", false) == 0) {
		intVal = StringToInt(value);
		g_currentActionGroup[ag_action3Limit] = intVal;
	} else if (strcmp(key, "repeat1", false) == 0) {
		intVal = StringToInt(value);
		if (intVal >= 0 && intVal <= 1) {
			g_currentActionGroup[ag_action1Repeat] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'repeat1': %s (only 0 or 1 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "repeat2", false) == 0) {
		intVal = StringToInt(value);
		if (intVal >= 0 && intVal <= 1) {
			g_currentActionGroup[ag_action2Repeat] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'repeat2': %s (only 0 or 1 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "repeat3", false) == 0) {
		intVal = StringToInt(value);
		if (intVal >= 0 && intVal <= 1) {
			g_currentActionGroup[ag_action3Repeat] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'repeat3': %s (only 0 or 1 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "filter names", false) == 0) {
		intVal = StringToInt(value);
		if (intVal >= 0 && intVal <= 1) {
			g_currentSection[cs_filterNames] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'filter names': %s (only 0 or 1 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "section id", false) == 0) {
		g_currentActionGroup[ag_id] = StringToInt(value);
	} else if (strcmp(key, "keep penalty", false) == 0) {
		intVal = StringToInt(value);
		if (intVal >= 0 && intVal <= 1) {
			g_currentActionGroup[ag_keepPoints] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'keep points': %s (only 0 or 1 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "name replacement", false) == 0) {
		if (GetArraySize(g_NameReplacements) <= MAX_REPLACEMENTS) {
			PushArrayString(g_NameReplacements, value);
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of name replacement elements exceeds limit of %d", g_ConfigLine, MAX_REPLACEMENTS);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "replacement", false) == 0) {
		if (GetArraySize(g_Replacements) <= MAX_REPLACEMENTS) {
			// RTrim replacement value if needed
			decl String:valueTrimmed[MAX_REPLACEMENT_LENGTH];
			strcopy(valueTrimmed, sizeof(valueTrimmed), value);
			while (strlen(valueTrimmed) > 0 && value[strlen(valueTrimmed) - 1] == ' ')
				valueTrimmed[strlen(valueTrimmed) - 1] = '\x0';
			PushArrayString(g_Replacements, valueTrimmed);
			// Check if there are {PLAY:...} tags in the replacement and precache sounds if so
			Handle rxHdl = CompileRegex(PLAY_REGEX);
			intVal = 1;
			char file[PLATFORM_MAX_PATH];
			new i = 0;
			while (intVal > 0) {
				intVal = MatchRegex(rxHdl, value[i]);
				if (intVal > 0) {
					// precache sound and add to download table
					GetRegexSubString(rxHdl, 2, file, sizeof(file));
					i = strlen(file);
					if (file[0] != '\0') {
						PrecacheSound(file);
						Format(file, sizeof(file), "sound/%s", file);
						AddFileToDownloadsTable(file);
					}
					// set string index to next possible position
					GetRegexSubString(rxHdl, 1, file, sizeof(file));
					i += strlen(file);
				}
			}
			CloseHandle(rxHdl);
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Number of regex replacement elements exceeds limit of %d", g_ConfigLine, MAX_REPLACEMENTS);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "mode", false) == 0) {
		intVal = StringToInt(value);
		if (intVal > 0 && intVal <= 4) {
			g_currentSection[cs_mode] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'mode': %s (only 1 to 4 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "penalty", false) == 0) {
		intVal = StringToInt(value);
		if (intVal >= 0 && intVal <= 999) {
			g_currentSection[cs_penalty] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'penalty': %s (only values between 0 and 999 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "valid from", false) == 0) {
		intVal = StringToEpoch(value);
		if (intVal >= DEFAULT_VALIDFROM && intVal <= DEFAULT_VALIDTO) {
			g_currentSection[cs_validFrom] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'valid from': %s (only values between '2018-12-30 00:00' and '2038-01-19 03:14' allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "valid to", false) == 0) {
		intVal = StringToEpoch(value);
		if (intVal >= DEFAULT_VALIDFROM && intVal <= DEFAULT_VALIDTO) {
			g_currentSection[cs_validTo] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'valid to': %s (only values between '2018-12-30 00:00' and '2038-01-19 03:14' allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else if (strcmp(key, "group", false) == 0) {
		intVal = FindStringInArray(g_GroupList, value);
		if (intVal == -1) {
			// new group: put in GroupList and check if additional tag is given
			char groupname[MAX_GROUPNAME_LENGTH];
			strcopy(groupname, sizeof(groupname), value);
			intVal = StrContains(groupname, "{");
			if (intVal >= 0) {
				groupname[intVal] = '\0';
				PushArrayCell(g_GroupFlags, 0); // 0 means that the group membership is NOT restored on reconnect!
			} else
				PushArrayCell(g_GroupFlags, 1); // 1 means that the group membership will be restored on reconnect
			PushArrayString(g_GroupList, groupname);
#if defined DEBUG
			PrintToServer("Got group '%s' with flag %d in config file. Number of groups: %d", groupname, (intVal >= 0 ? 0 : 1), GetArraySize(g_GroupList));
#endif
		}
	} else if (strcmp(key, "probability", false) == 0 || strcmp(key, "chance", false) == 0) {
		intVal = StringToInt(value);
		if (intVal >= 0 && intVal <= 100) {
			g_currentSection[cs_probability] = intVal;
		} else {
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid value specified for 'probability': %s (only values between 0 and 100 allowed)", g_ConfigLine, value);
			LogError(g_LastError);
		}
	} else {
		intVal = FindStringInArray(g_GroupList, key);
		if (intVal >= 0) {
			// key is a group name: put value in GroupMembers trie
			SetTrieValue(g_GroupMembers, value, intVal, true);
#if defined DEBUG
			PrintToServer("Put steam id '%s' into group '%s'", value, key);
#endif
		}
	}
	
	return result;
}

public SMCResult:Config_EndSection(Handle:parser) {
	new SMCResult:result = SMCParse_Continue;
	if (g_SectionDepth == 1) {
		// action group ending
		if (g_currentActionGroup[ag_id] != -1) {
			PushArrayArray(g_ActionGroups, g_currentActionGroup[0]);
			PushArrayArray(g_PlayerPenaltyPoints, g_currentPenaltyPoints[0]);
			PushArrayArray(g_PlayerLastActions, g_currentLastActions[0]);
		} else {
			// we have a problem - no proper action group id set!
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid or no action group id specified for current group.", g_ConfigLine);
			LogError(g_LastError);
		}
	} else if (g_SectionDepth == 2) {
		// search & replace group ending
		if (g_currentActionGroup[ag_id] != -1) {
			// store counter boundaries of current section
			if (g_currentSection[cs_replaceNameIdxFrom] == GetArraySize(g_NameReplacements)) {
				g_currentSection[cs_replaceNameIdxFrom] = -1;
				g_currentSection[cs_replaceNameIdxTo] = -1;
			} else {
				g_currentSection[cs_replaceNameIdxTo] = GetArraySize(g_NameReplacements) - 1;
			}
			if (g_currentSection[cs_replaceRegexIdxFrom] == GetArraySize(g_Replacements)) {
				g_currentSection[cs_replaceRegexIdxFrom] = -1;
				g_currentSection[cs_replaceRegexIdxTo] = -1;
			} else {
				g_currentSection[cs_replaceRegexIdxTo] = GetArraySize(g_Replacements) - 1;
			}
			g_currentSection[cs_actionGroupIdx] = GetArraySize(g_ActionGroups);
			PushArrayArray(g_ConfigSections, g_currentSection[0]);
		} else {
			// we have a problem - no proper action group id set!
			result = SMCParse_Halt;
			Format(g_LastError, sizeof(g_LastError), "Error in config file line %d: Invalid or no action group id specified for current section.", g_ConfigLine);
			LogError(g_LastError);
		}
	}
	g_SectionDepth--;
	return result;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {
	if (halted)
		LogError("Configuration parsing stopped!");
	if (failed)
		LogError("Configuration parsing failed!");
}

public OnClientPostAdminCheck(client) {
	ProcessClientName(client);
}

public OnClientAuthorized(client) {
	// check the group definitions for client's steam id
	if (!IsFakeClient(client))
		GroupClient(client);
}

/**
 * Handler game event 'player_changename'. Checks the client's name. 
 * 
 * @param client 	client id
 * @noreturn
 */
public Action:OnNameChanged(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	char newName[MAX_NAME_LENGTH_EXTENDED];
	GetEventString(event, "newname", newName, sizeof(newName));
	
#if defined DEBUG				
	PrintToServer("[Universal Chatfilter] event 'player_changename' fired. Client id %d, name '%s'", client, newName); // DEBUG
#endif
	
	// process client's name only if the client is not in the process of checking
	if (g_PlayerInCheck[client] == 0) {
		g_PlayerInCheck[client] = 1;
		ProcessClientName(client, newName, sizeof(newName));
	}
	// set timer to reset the checking status (for cooldown...)	
	CreateTimer(1.0, Timer_CheckName, client);
	
	return Plugin_Handled;
}

/**
 * Handler OnClientCookiesCached. Restores client's penalty and hit counter, if needed. 
 * 
 * @param client 	client id
 * @noreturn
 */
public OnClientCookiesCached(client) {
	if (GetConVarBool(cvarKeepPoints) && g_Cookie != INVALID_HANDLE)
		ReadClientCookie(client);
}

/**
 * Handler for resetting the client's flag for being name checked. 
 * (needed to prevent recursive checks, but also potentially dangerous. Users could change their
 * names within the timer limit and won't be checked again...) 
 * 
 * @param timer 		handle for the timer
 * @param client		client id
 */
public Action:Timer_CheckName(Handle:timer, any:client) {
	g_PlayerInCheck[client] = 0;
}

/**
 * Handler for 'sm_chatfilter_status' command. Lists all player's penalty points. 
 * 
 * @param client 	client id
 * @args			Arguments given for the command
 *
 */
public Action:ShowStatusHandler(client, args) {
	decl String:playerName[MAX_NAME_LENGTH];
	decl String:steamID[STEAMID_LENGTH];
	decl String:output[160 * (32 + 14)];
	decl String:line[160];
	// show some stuff about the plugin
	Format(output, sizeof(output), "\r\n%s (%s) Status Information\r\n\r\n", PLUGIN_NAME, PLUGIN_VERSION);
	if (GetConVarBool(cvarEnabled))
		playerName = "enabled";
	else
		playerName = "disabled";
	Format(line, sizeof(line), "Status:                        Plugin %s\r\n", playerName);
	StrCat(output, sizeof(output), line);
	if (GetConVarBool(cvarAdmins))
		playerName = "on";
	else
		playerName = "off";
	Format(line, sizeof(line), "Admin chat filtering:          %s\r\n", playerName);
	StrCat(output, sizeof(output), line);
	if (GetConVarBool(cvarKeepPoints))
		playerName = "on";
	else
		playerName = "off";
	Format(line, sizeof(line), "Keep penalty on reconnect:     %s\r\n", playerName);
	StrCat(output, sizeof(output), line);
	Format(line, sizeof(line), "Number of search expressions:  %d\r\n", GetArraySize(g_RegexHandles));
	StrCat(output, sizeof(output), line);
	Format(line, sizeof(line), "Number of replacements:        %d\r\n", GetArraySize(g_Replacements));
	StrCat(output, sizeof(output), line);
	Format(line, sizeof(line), "Number of name replacements:   %d\r\n", GetArraySize(g_NameReplacements));
	StrCat(output, sizeof(output), line);
	char groupNames[MAX_EXPRESSION_LENGTH];
	new y = GetArraySize(g_GroupList);
	if (y > 0) {
		char thisGroup[MAX_GROUPNAME_LENGTH];
		groupNames = "(";
		for (new i = 0; i < y; i++) {
			GetArrayString(g_GroupList, i, thisGroup, sizeof(thisGroup));
			StrCat(groupNames, sizeof(groupNames), thisGroup);
			StrCat(groupNames, sizeof(groupNames), ", ");
		}
		groupNames[strlen(groupNames) - 2] = ')';
		groupNames[strlen(groupNames) - 1] = '\0';
	}
	Format(line, sizeof(line), "Number of groups:              %d %s\r\n\r\n", GetArraySize(g_GroupList), groupNames);
	StrCat(output, sizeof(output), line);
	StrCat(output, sizeof(output), "Player statistics:\r\n");
	new maxNameLen = 0;
	Handle aryClients = CreateArray();
	// sum up all player's penalty points into on table
	new thisPP[MAXPLAYERS + 1] = {0, ... };
	SumUpPoints(thisPP[0]);
	// collect connected players and determine max name length
	decl len;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && !IsFakeClient(i)) {
			GetClientName(i, playerName, sizeof(playerName));
			PushArrayCell(aryClients, i);
			len = StrLenMB(playerName);
			if (len > maxNameLen)
				maxNameLen = len;
		}
	}
	// show player's penalty points as a table
	decl String:padStr[MAX_NAME_LENGTH + 3];
	for (new i = 0; i < MAX_NAME_LENGTH + 3; i++)
	padStr[i] = ' ';
	len = maxNameLen + 3 - strlen("name");
	if (len < 0)
		len = 1;
	padStr[len] = '\0';
	Format(line, sizeof(line), "# userid  name %sauthid                 penalty  hits  group\r\n", padStr);
	StrCat(output, sizeof(output), line);
	padStr[len] = ' ';
	y = GetArraySize(aryClients);
	decl userid;
	decl thisClient;
	decl String:group[MAX_GROUPNAME_LENGTH];
	for (new i = 0; i < y; i++) {
		thisClient = GetArrayCell(aryClients, i);
		if (thisClient > 0) {
			GetClientName(thisClient, playerName, sizeof(playerName));
			steamID[0] = '[';
			GetClientAuthId(thisClient, AuthId_Steam2, steamID[1], sizeof(steamID) - 1);
			steamID[strlen(steamID)] = ']';
			steamID[strlen(steamID) + 1] = '\0';
			userid = GetClientUserId(thisClient);
			if (g_PlayerGroups[thisClient] >= 0)
				GetArrayString(g_GroupList, g_PlayerGroups[thisClient], group, sizeof(group));
			else
				group = "-";
			padStr[maxNameLen + 1 - StrLenMB(playerName)] = '\0';
			Format(line, sizeof(line), "#%7d  \"%s\" %s%-24s%-9d%-6d%s\r\n", userid, playerName, padStr, steamID, thisPP[thisClient], g_PlayerHits[thisClient], group);
			StrCat(output, sizeof(output), line);
			padStr[maxNameLen + 1 - StrLenMB(playerName)] = ' ';
		}
	}
	ReplyToCommand(client, output);
	return Plugin_Handled;
}

/**
 * Handler for all player related commands. These are: 'sm_chatfilter_reset', 'sm_chatfilter_group',
 * and 'sm_chatfilter_ungroup'. 
 * 
 * @param client 	client id
 * @args			Arguments given for the command
 *
 */
public Action:PlayerCommandHandler(client, args) {
	new commandType = 0;
	// determine command
	decl String:strTarget[MAX_NAME_LENGTH];
	GetCmdArg(0, strTarget, sizeof(strTarget));
	if (strcmp(strTarget, COMMAND_RESETPLAYER, false) == 0)
		commandType = 1;
	else if (strcmp(strTarget, COMMAND_GROUP, false) == 0)
		commandType = 2;
	else if (strcmp(strTarget, COMMAND_UNGROUP, false) == 0)
		commandType = 3;
	
	if (args < 1 && commandType == 1)
		ReplyToCommand(client, "%sUsage: %s <name|#userid> [<section id>])", PLUGIN_PREFIX, strTarget);
	else if (args < 2 && commandType == 2)
		ReplyToCommand(client, "%sUsage: %s <name|#userid> <group>", PLUGIN_PREFIX, strTarget);
	if (args < 1 && commandType == 3)
		ReplyToCommand(client, "%sUsage: %s <name|#userid>", PLUGIN_PREFIX, strTarget);
	else {
		GetCmdArg(1, strTarget, sizeof(strTarget));
		
		char targetName[MAX_TARGET_LENGTH];
		decl targetList[MAXPLAYERS + 1];
		decl targetCount;
		bool tn_is_ml;
		if ((targetCount = ProcessTargetString(
					strTarget, 
					client, 
					targetList, 
					MAXPLAYERS, 
					COMMAND_FILTER_CONNECTED + COMMAND_FILTER_NO_BOTS, 
					targetName, 
					sizeof(targetName), 
					tn_is_ml)) <= 0) {
			ReplyToTargetError(client, targetCount);
		} else {
			decl String:param2[MAX_GROUPNAME_LENGTH];
			if (args >= 2)
				GetCmdArg(2, param2, sizeof(param2));
			for (new i = 0; i < targetCount; i++) {
				switch (commandType) {
					case 1: {
						// sm_chatfilter_reset
						new sectionID = StringToInt(param2);
						if (sectionID == 0) {
							ClearPoints(targetList[i]);
							ReplyToCommand(client, "%s%N's penalty points reset to 0.", PLUGIN_PREFIX, targetList[i]);
						} else {
							ClearPoints(targetList[i], false, sectionID);
							ReplyToCommand(client, "%s%N's penalty points for section id %d reset to 0.", PLUGIN_PREFIX, targetList[i], sectionID);
						}
					}
					case 2: {
						// sm_chatfilter_group
						new idx = FindStringInArray(g_GroupList, param2);
						if (idx >= 0) {
							g_PlayerGroups[targetList[i]] = idx;
							ReplyToCommand(client, "%sPlayer '%N' is now assigned to group '%s'.", PLUGIN_PREFIX, targetList[i], param2);
						} else
							ReplyToCommand(client, "%sPlayer '%N' could not be assigned to group '%s'. Probably the group does not exist?", PLUGIN_PREFIX, targetList[i], param2);
					}
					case 3: {
						// sm_chatfilter_ungroup
						g_PlayerGroups[targetList[i]] = -1;
						ReplyToCommand(client, "%sPlayer '%N' is not a member of any group any more.", PLUGIN_PREFIX, targetList[i]);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

/**
 * Handler for presenting an arbitrary URL to a certain target.
 * 
 * @param client 	client id
 * @args			Arguments given for the command
 *
 */
public Action:ShowUrlHandler(client, args) {
	char strTarget[MAX_NAME_LENGTH];
	GetCmdArg(0, strTarget, sizeof(strTarget));
	if (args < 2)
		ReplyToCommand(client, "%sUsage: %s <name|#userid> \"<url>\" [\"<title>\"]", PLUGIN_PREFIX, strTarget);
	else {
		GetCmdArg(1, strTarget, sizeof(strTarget));
		
		char targetName[MAX_TARGET_LENGTH];
		decl targetList[MAXPLAYERS + 1];
		decl targetCount;
		bool tn_is_ml;
		if ((targetCount = ProcessTargetString(
					strTarget, 
					client, 
					targetList, 
					MAXPLAYERS, 
					COMMAND_FILTER_CONNECTED + COMMAND_FILTER_NO_BOTS, 
					targetName, 
					sizeof(targetName), 
					tn_is_ml)) <= 0) {
			ReplyToTargetError(client, targetCount);
		} else {
			char url[512];
			GetCmdArg(2, url, sizeof(url));
			char title[64];
			title = "";
			if (args > 2)
				GetCmdArg(3, title, sizeof(title));
			KeyValues kv = new KeyValues("data");
			kv.SetString("title", title);
			kv.SetNum("type", MOTDPANEL_TYPE_URL);
			kv.SetString("msg", url);
			for (new i = 0; i < targetCount; i++) {
				//ShowMOTDPanel(targetList[i], title, url, MOTDPANEL_TYPE_URL);
				ShowVGUIPanel(targetList[i], "info", kv, true);
#if defined DEBUG
				PrintToServer("Executing command: ShowMOTDPanel(%d, '%s', '%s', MOTDPANEL_TYPE_URL);", targetList[i], title, url);
#endif
			}
		}
	}
	return Plugin_Handled;
}

/**
 * Handler for any appearing chat message (thanks to simple-chatprocessor.smx) 
 * 
 * @param client 		The client index of the player who sent the chat message (Byref)
 * @param recipients	The handle to the client index adt array of the players who should recieve the chat message
 * @param name			The client's name of the player who sent the chat message (Byref)
 * @param message		The contents of the chat message (Byref)
 * @noreturn
 *
 */
public Action:OnChatMessage(&client, Handle:recipients, String:name[], String:message[]) {
	
#if defined DEBUG
	PrintToServer("[Universal Chatfilter] Handler OnChatMessage: \"%s\". No of recipients %d / client id %d / in work: %d", message, GetArraySize(recipients), client, g_InWork); // DEBUG
#endif
	if (g_InWork == 0) {
		// mark that we have started working on this chat message
		g_InWork = 1;
		new Action:result = ProcessChat(client, name, message);
		if (g_InWork == 1) {
			// save the current name & message
			CleanColorCodeFragments(name);
			CleanColorCodeFragments(message);
			strcopy(g_CurrentName, sizeof(g_CurrentName), name);
			strcopy(g_CurrentMessage, sizeof(g_CurrentMessage), message);
		}
		RequestFrame(Frame_OnChatMessage, g_InWork);
		return result;
	} else if ((g_InWork == 2) && (client != g_ExclusiveChatClient)) {
		// block statement for all others
		return Plugin_Stop;
	} else {
		// else just re-use the processed name & message (and pray the maxlen's are correct...)
		strcopy(name, sizeof(g_CurrentName), g_CurrentName);
		strcopy(message, sizeof(g_CurrentMessage), g_CurrentMessage);
#if defined DEBUG
		PrintToServer("[Universal Chatfilter] Re-using name & message: \"%s\" & \"%s\"", name, message); // DEBUG
#endif		
		return Plugin_Changed;
	}
}

/**
 * Handler for any appearing chat message for Keith Warren's Chat-Processor (the simple-chatprocessor.smx is depricated!)
 * 
 * @param client 		The client index of the player who sent the chat message (Byref)
 * @param recipients	The handle to the client index adt array of the players who should recieve the chat message
 * @param flag			Flags of the chat message (Byref))
 * @param name			The client's name of the player who sent the chat message (Byref)
 * @param message		The contents of the chat message (Byref)
 * @noreturn
 *
 */
public Action:CP_OnChatMessage(&client, Handle:recipients, String:flag[], String:name[], String:message[], bool & bProcessColors, bool & bRemoveColors) {
	bProcessColors = false;
	OnChatMessage(client, recipients, name, message);
}

public void Frame_OnChatMessage(any data) {
	// reset the in-work-indicator
	g_InWork = 0;
#if defined DEBUG
	PrintToServer("[Universal Chatfilter] Frame_OnChatMessage entered. Indicator reset."); // DEBUG
#endif
}

//
// Private functions
//

/**
 * Checks if the plugin is enabled for the given client 
 * 
 * @param client 	client id
 * @return 			true if it is enabled, otherwise false
 *
 */
CheckEnabled(client) {
	if (GetConVarBool(cvarEnabled)) {
		if (client && IsClientConnected(client) && !IsFakeClient(client)) {
			if (GetUserAdmin(client) != INVALID_ADMIN_ID)
				return GetConVarBool(cvarAdmins);
			else
				return true;
		} else
			return false;
	} else
		return false;
}

/**
 * Sets the client's penalty points to zero. Traverses all action groups.
 * Also resets the client's hit counter and last action tracking.
 * 
 * @param client 		client id
 * @param clearGroup 	true, if the players group assignment shall be erased as well
 * @param sectionID 	id of config section whose points shall be erased. Default 0 = all sections
 * @noreturn
 *
 */
void ClearPoints(const client, bool clearGroup = false, sectionID = 0) {
	new maxlen = GetArraySize(g_PlayerPenaltyPoints);
	decl thisPlayerArray[MAXPLAYERS + 1];
	decl thisActionGroup[enumActionGroup];
	for (new i = 0; i < maxlen; i++) {
		GetArrayArray(g_ActionGroups, i, thisActionGroup[0]);
		if (thisActionGroup[ag_id] == sectionID || sectionID == 0) {
			GetArrayArray(g_PlayerPenaltyPoints, i, thisPlayerArray[0]);
			thisPlayerArray[client] = 0;
			SetArrayArray(g_PlayerPenaltyPoints, i, thisPlayerArray[0]);
			GetArrayArray(g_PlayerLastActions, i, thisPlayerArray[0]);
			thisPlayerArray[client] = -1;
			SetArrayArray(g_PlayerLastActions, i, thisPlayerArray[0]);
		}
	}
	g_PlayerHits[client] = 0;
	if (clearGroup) {
		g_PlayerInCheck[client] = 0;
		g_PlayerGroups[client] = -1;
	}
}

/**
 * Sums up all player's penalty points into one given array. Traverses all action groups.
 * Currently only used by the status command.
 *
 * @param client 	client id
 * @noreturn
 *
 */
void SumUpPoints(penaltyPointsArray[]) {
	new maxgroups = GetArraySize(g_PlayerPenaltyPoints);
	decl thisPenaltyPoints[MAXPLAYERS + 1];
	decl y;
	for (new i = 0; i < maxgroups; i++) {
		GetArrayArray(g_PlayerPenaltyPoints, i, thisPenaltyPoints[0]);
		for (y = 1; y < MAXPLAYERS + 1; y++)
		penaltyPointsArray[y] += thisPenaltyPoints[y];
	}
}

/**
 * Writes the client cookie containing the penalty points for each action group and the global hit counter.
 * 
 * @param client 	client id
 * @noreturn
 *
 */
WriteClientCookie(const client) {
	new maxlen = GetArraySize(g_PlayerPenaltyPoints);
	decl thisPenaltyPoints[MAXPLAYERS + 1];
	decl thisActionGroup[enumActionGroup];
	char cookieString[MAX_COOKIE_LENGTH];
	char thisPenalty[24];
	char group[MAX_GROUPNAME_LENGTH];
	if (g_PlayerGroups[client] >= 0)
		if (GetArrayCell(g_GroupFlags, g_PlayerGroups[client]) > 0) // only save group if it was defined as sticky
		GetArrayString(g_GroupList, g_PlayerGroups[client], group, sizeof(group));
	// first save global hit counter and the group name
	Format(cookieString, sizeof(cookieString), "%d/%s/", g_PlayerHits[client], group);
	// then loop all action groups and construct the cookie string
	for (new i = 0; i < maxlen; i++) {
		GetArrayArray(g_PlayerPenaltyPoints, i, thisPenaltyPoints[0]);
		GetArrayArray(g_ActionGroups, i, thisActionGroup[0]);
		if (thisActionGroup[ag_keepPoints] > 0) {
			Format(thisPenalty, sizeof(thisPenalty), "%d|%d;", thisActionGroup[ag_id], thisPenaltyPoints[client]);
			StrCat(cookieString, sizeof(cookieString), thisPenalty);
		}
	}
	if (cookieString[strlen(cookieString) - 1] == ';')
		cookieString[strlen(cookieString) - 1] = '\0';
	SetClientCookie(client, g_Cookie, cookieString);
#if defined DEBUG		
	PrintToServer("[Universal Chatfilter] Writing client cookie: %s", cookieString); // DEBUG
#endif
}

/**
 * Reads the client cookie containing the penalty points for each action group and the global hit counter.
 * 
 * @param client 	client id
 * @return			true on success, false otherwise
 *
 */
bool ReadClientCookie(const client) {
	bool result = false;
	decl String:cookieString[MAX_COOKIE_LENGTH];
	GetClientCookie(client, g_Cookie, cookieString, sizeof(cookieString));
#if defined DEBUG		
	PrintToServer("[Universal Chatfilter] Reading client cookie: %s", cookieString); // DEBUG
#endif
	if (MatchRegex(g_TokenHandles[0], cookieString) == 4) {
		decl String:subString[MAX_COOKIE_LENGTH];
		// read hit counter
		GetRegexSubString(g_TokenHandles[0], 1, subString, sizeof(subString));
		g_PlayerHits[client] = StringToInt(subString);
		// read the group name
		GetRegexSubString(g_TokenHandles[0], 2, subString, sizeof(subString));
		new idx = FindStringInArray(g_GroupList, subString);
		if (idx >= 0 && GetArrayCell(g_GroupFlags, idx) > 0)
			g_PlayerGroups[client] = idx;
		// read pentaly points list
		GetRegexSubString(g_TokenHandles[0], 3, subString, sizeof(subString));
		char penalties[MAX_CONFIG_SECTIONS][24];
		ExplodeString(subString, ";", penalties, MAX_CONFIG_SECTIONS, 24);
		new i = 0;
		decl pos;
		decl len;
		decl thisAgId;
		decl thisPP[MAXPLAYERS + 1];
		result = true;
		while (penalties[i][0] != '\0' && i < MAX_CONFIG_SECTIONS) {
			pos = StrContains(penalties[i], "|");
			len = strlen(penalties[i]);
			if (pos >= 0 && pos + 1 < len) {
				penalties[i][pos] = '\0';
				thisAgId = StringToInt(penalties[i]);
				idx = FindActionGroupArray(thisAgId);
				if (idx >= 0) {
					GetArrayArray(g_PlayerPenaltyPoints, idx, thisPP[0]);
					thisPP[client] = StringToInt(penalties[i][pos + 1]);
					SetArrayArray(g_PlayerPenaltyPoints, idx, thisPP[0]);
				}
			}
			i++;
		}
	}
	if (!result && cookieString[0] != '\0')
		LogMessage("%L: Invalid cookie content '%s'. Cannot restore penalty points.", client, cookieString);
	return result;
}


/** 
 * Checks the names of all connected clients name and processes any actions if needed.
 * Called internally when the plugin is loaded or re-enabled.
 *
 * @noreturn
 */
void ProcessAllClientNames() {
	new maxClients = GetMaxClients();
	for (new i = 1; i <= maxClients; ++i)
	if (IsClientConnected(i) && !IsFakeClient(i))
		ProcessClientName(i);
}


/** 
 * Checks a client's name and processes any actions if needed.
 *
 * @param client		client id
 * @noreturn
 */
void ProcessClientName(client, String:name[] = "", const maxlen = 0) {
	
	if (CheckEnabled(client)) {
		decl String:clientName[MAX_NAME_LENGTH_EXTENDED];
		if (maxlen > 0)
			strcopy(clientName, sizeof(clientName), name);
		else
			GetClientName(client, clientName, sizeof(clientName));
		
		// process client's name
#if defined DEBUG		
		PrintToServer("[Universal Chatfilter] Now checking client's name: %s", clientName); // DEBUG
#endif
		
		if (CheckForRegexes(client, clientName, sizeof(clientName), "", 1)) {
			// we had a hit!
			ChargePoints(client);
			g_PlayerInCheck[client] = 2; // to prevent the name being checked again
			CleanColorCodeFragments(clientName);
#if defined DEBUG				
			PrintToServer("[Universal Chatfilter] Now changing client's name into: %s", clientName); // DEBUG
#endif
			SetClientInfo(client, "name", clientName);
			ProcessActions(client);
		}
	}
}

/** 
 * Checks a text chat entry and processes it and any actions if needed.
 *
 * @param client		client id
 * @param recipients	The handle to the client index adt array of the players who should recieve the chat message
 * @param name			The contents of the chat message sender (by ref)
 * @param message		The contents of the chat message (by ref)
 * @return				Plugin_Continue if nothing happened, Plugin_Handled otherwise
 */
Action:ProcessChat(&client, String:name[], String:message[]) {
	
	new Action:result = Plugin_Continue;
	
	if (CheckEnabled(client)) {
		
		TrimString(message);
		
		// clumsy approach, but I don't find any other way: check first byte for detecting color codes and ignore these
		decl offset;
		switch (message[0]) {
			case '\x03', '\x04', '\x05': {
				offset = 1;
			}
			case '\x07': {
				offset = 7;
			}
			case '\x08': {
				offset = 9;
			}
			default: {
				offset = 0;
			}
		}
		// process given speech expression
		if (CheckForRegexes(client, message[offset], MAX_EXPRESSION_LENGTH - offset, name, MAX_NAME_LENGTH_EXTENDED)) {
			
			// we had a hit!
			ChargePoints(client);
			result = Plugin_Changed;
			
			if (strlen(message) > offset) {
#if defined DEBUG				
				PrintToServer("[Universal Chatfilter] Replacing original message by: %s", message); // DEBUG
#endif
			} else
				result = Plugin_Stop;
			
			// perform action(s) if defined
			ProcessActions(client);
		}
	}
#if defined DEBUG
	PrintToServer("[Universal Chatfilter] Leaving ProcessChat now."); // DEBUG
#endif	
	return result;
}

/** 
 * Charges the penalty points contained in the g_MatchedSections array to a client
 * and increments the hit counter. The client's cookie is NOT set here.
 *
 * @param client				client id
 * @param penalty				penalty points to be charged
 * @noreturn
 */
void ChargePoints(const client) {
	g_PlayerHits[client] += 1;
	new max = GetArraySize(g_MatchedSections);
	decl thisPP[MAXPLAYERS + 1];
	for (new i = 0; i < max; i++) {
		// somewhat tricky: first copy the needed config section information into g_currentSection
		GetArrayArray(g_ConfigSections, GetArrayCell(g_MatchedSections, i), g_currentSection[0]);
		// then get the right penalty pointer arry, modify it and write it back
		GetArrayArray(g_PlayerPenaltyPoints, g_currentSection[cs_actionGroupIdx], thisPP[0]);
		thisPP[client] += g_currentSection[cs_penalty];
		SetArrayArray(g_PlayerPenaltyPoints, g_currentSection[cs_actionGroupIdx], thisPP[0]);
	}
}

/** 
 * Processes all actions currently held by the global array for matched actions,
 * depending on clients penalty points in the corresponding action group
 *
 * @param client				client id
 * @noreturn
 */
void ProcessActions(const client) {
	decl String:actionString[MAX_ACTION_LENGTH];
	new matchedSecs = GetArraySize(g_MatchedSections);
	decl thisPP[MAXPLAYERS + 1];
	decl i;
	decl section;
	decl lastAction;
	for (i = 0; i < matchedSecs; i++) {
		section = GetArrayCell(g_MatchedSections, i);
		if (GetArrayArray(g_ConfigSections, section, g_currentSection[0])) {
#if defined DEBUG				
	PrintToServer("[Universal Chatfilter] ***** PROCESSACTIONS ***** Checking section %d with instant action idx %d", section, g_currentSection[cs_instantActionIdx]); // DEBUG
#endif
			// check for instant action
			if (g_currentSection[cs_instantActionIdx] != -1) {
				GetArrayString(g_Actions, g_currentSection[cs_instantActionIdx], actionString, sizeof(actionString));
				ExecuteAction(client, actionString, sizeof(actionString), i);
#if defined DEBUG				
				PrintToServer("[Universal Chatfilter] ProcessActions has executed this instant action: %s", actionString); // DEBUG
#endif
			}
			// action3, action2 or action1 check (only one of these will be executed)
			actionString[0] = '\0';
			if (GetArrayArray(g_ActionGroups, g_currentSection[cs_actionGroupIdx], g_currentActionGroup[0]) > 0) {
				// get last actions
				GetArrayArray(g_PlayerLastActions, g_currentSection[cs_actionGroupIdx], g_currentLastActions[0]);
				lastAction = g_currentLastActions[client];
				// get penalty points into thisPP array
				GetArrayArray(g_PlayerPenaltyPoints, g_currentSection[cs_actionGroupIdx], thisPP[0]);
				// check for penalties
				if (thisPP[client] >= g_currentActionGroup[ag_action3Limit] && g_currentActionGroup[ag_action3Limit] != -1) {
					if (g_currentActionGroup[ag_action3Idx] != -1
						 && (g_currentActionGroup[ag_action3Repeat] || g_currentActionGroup[ag_action3Idx] != lastAction)) {
						GetArrayString(g_Actions, g_currentActionGroup[ag_action3Idx], actionString, sizeof(actionString));
						lastAction = g_currentActionGroup[ag_action3Idx];
					}
				} else if (thisPP[client] >= g_currentActionGroup[ag_action2Limit] && g_currentActionGroup[ag_action2Limit] != -1) {
					if (g_currentActionGroup[ag_action2Idx] != -1
						 && (g_currentActionGroup[ag_action2Repeat] || g_currentActionGroup[ag_action2Idx] != lastAction)) {
						GetArrayString(g_Actions, g_currentActionGroup[ag_action2Idx], actionString, sizeof(actionString));
						lastAction = g_currentActionGroup[ag_action2Idx];
					}
				} else if (thisPP[client] >= g_currentActionGroup[ag_action1Limit] && g_currentActionGroup[ag_action1Limit] != -1) {
					if (g_currentActionGroup[ag_action1Idx] != -1
						 && (g_currentActionGroup[ag_action1Repeat] || g_currentActionGroup[ag_action1Idx] != lastAction)) {
						GetArrayString(g_Actions, g_currentActionGroup[ag_action1Idx], actionString, sizeof(actionString));
						lastAction = g_currentActionGroup[ag_action1Idx];
					}
				}
				if (actionString[0] != '\0') {
#if defined DEBUG
					PrintToServer("[Universal Chatfilter] Trying to execute this command: %s", actionString);
#endif
					g_currentLastActions[client] = lastAction;
					SetArrayArray(g_PlayerLastActions, g_currentSection[cs_actionGroupIdx], g_currentLastActions[0]);
					// and execute
					ExecuteAction(client, actionString, sizeof(actionString), i);
				}
			}
		}
	}
	// clean up here to free memory
	ClearArray(g_MatchedExpressions);
	ClearArray(g_MatchedSections);
}

/** 
 * Executes a server command. These labels will be replaced before execution:
 *   #userid 		-> will be replaced by the client's user id, preceeded by a hash (e.g. #12)
 *   @name			-> will be replaced by the client's name, no quotation marks around it!
 *   @steamid		-> will be replaced by the client's steam id (format: steam_x:n:nnnnnn), no quotation marks around it!
 *   @match			-> the matching word/expression, no quotation marks around it!
 *	 @serverip		-> the server's ip4 address
 *	 @serverport	-> the server's port for the current game
 *
 * @param client				client id
 * @param actionString			Command that will be executed via ServerCommand()
 * @param maxlen				Max length of command string buffer
 * @param matchedExpressionsIdx	Index for array of matched words/expressions.
 */
void ExecuteAction(const client, char[] actionString, const maxlen, const matchedExpressionsIdx) {
	ReplaceClientTags(client, actionString, maxlen);
	decl String:matchedKeyword[MAX_KEYWORD_LENGTH];
	if (matchedExpressionsIdx < GetArraySize(g_MatchedExpressions)) {
		GetArrayString(g_MatchedExpressions, matchedExpressionsIdx, matchedKeyword, sizeof(matchedKeyword));
		ReplaceString(actionString, maxlen, "@match", matchedKeyword, false);
	}
#if defined DEBUG
	PrintToServer("[Universal Chatfilter] Executing server command: %s", actionString);
#endif
	// keep track of this action
	if (GetConVarInt(cvarLogLevel) > 0)
		LogMessage("%L triggered action: %s", client, actionString);
	// execute it
	ServerCommand(actionString);
}

/** 
 * Replaces client related tags within a string expression:
 *   #userid 		-> will be replaced by the client's user id, preceeded by a hash (e.g. #12)
 *   @name			-> will be replaced by the client's name, no quotation marks around it!
 *   @steamid		-> will be replaced by the client's steam id (format: steam_x:n:nnnnnn), no quotation marks around it!
 *	 @serverip		-> the server's ip4 address
 *	 @serverport	-> the server's port for the current game
 *
 * @param client				client id
 * @param expression			String expression containing the tags
 * @param maxlen				Max length of expression string buffer
 * @noreturn
 */
void ReplaceClientTags(const client, String:expression[], const maxlen) {
	decl String:clientName[MAX_NAME_LENGTH_EXTENDED];
	GetClientName(client, clientName, sizeof(clientName));
	decl String:clientNo[10];
	Format(clientNo, sizeof(clientNo), "#%d", GetClientUserId(client));
	decl String:steamID[STEAMID_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	ReplaceString(expression, maxlen, "#userid", clientNo, false);
	ReplaceString(expression, maxlen, "@name", clientName, false);
	ReplaceString(expression, maxlen, "@steamid", steamID, false);
	ReplaceString(expression, maxlen, "@serverip", g_ServerIp, false);
	ReplaceString(expression, maxlen, "@serverport", g_ServerPort, false);
}

/** 
 * Checks the expression for a keyword match. Depending on mode it will
 * either just update the expression string by replacing the matched words
 * (mode = 1) or replace the whole expression with a replacement string 
 * (mode = 2) or just leave it and return (mode = 3).
 *
 * @param message			Chat message to be processed ('replacement' keys apply)
 * @param name				Name of the player ('name replacmenet' keys apply)
 * @return					True, if we had at least one hit. False otherwise
 */
CheckForRegexes(const client, String:expression[], const expressionMaxlen, String:name[], const nameMaxlen) {
	
	bool result = false;
	new regexIdx = 0;
	new regexMax = GetArraySize(g_RegexHandles);
	char keyword[MAX_KEYWORD_LENGTH] = "";
	decl String:replace[MAX_REPLACEMENT_LENGTH];
	decl section;
	new lastSection = -1;
	decl idx;
	new resultMode;
	bool doLoop = true;
	bool nameReplacement = (name[0] == '\0');
	new expressionOffset = 0;
	
	// clear array for matches
	ClearArray(g_MatchedExpressions);
	ClearArray(g_MatchedSections);
	// loop regexes
	new substrings;
	new skipSection = -1;
	new skipActionGroup = -1;
	decl groupIdx;
	decl thisTeamIdx;
	new teamIdx = -1;
	decl bool:steamIdMatch;
	if (IsClientInGame(client))
		teamIdx = GetClientTeam(client);
	new now = GetTime();
	while (regexIdx < regexMax && doLoop) {
		section = GetArrayCell(g_RegexHandleSections, regexIdx);
		groupIdx = GetArrayCell(g_RegexHandleGroups, regexIdx);
		thisTeamIdx = GetArrayCell(g_RegexHandleTeams, regexIdx);
		if (UnflagSection(section) != lastSection) {
			GetArrayArray(g_ConfigSections, UnflagSection(section), g_currentSection[0]);
			lastSection = UnflagSection(section);
		}
#if defined DEBUG
		PrintToServer("[Universal Chatfilter] Section %d, regex %d / Probability: %d", section, regexIdx, g_currentSection[cs_probability]);
		PrintToServer("[Universal Chatfilter] Expression: '%s' (Offset %d)", regexIdx, expression, expressionOffset);
#endif		
		if ((nameReplacement == false || (nameReplacement && g_currentSection[cs_filterNames]))
			 && (UnflagSection(section) != skipSection)
			 && (g_currentSection[cs_actionGroupIdx] != skipActionGroup)
			 && (expression[expressionOffset] != '\0')
			 && (g_currentSection[cs_probability] == 100 || GetRandomInt(1, 100) <= g_currentSection[cs_probability])
			 && (g_currentSection[cs_validFrom] <= now)
			 && (g_currentSection[cs_validTo] > now)) {
			
			if (((groupIdx >= 0 && g_PlayerGroups[client] == groupIdx) || groupIdx < 0)
				 && (thisTeamIdx == -1 || thisTeamIdx == teamIdx)) {
				
#if defined DEBUG
				PrintToServer("[Universal Chatfilter] Now checking regex ID %d Expression: '%s' (Offset %d)", regexIdx, expression[expressionOffset], expressionOffset);
#endif
				if ((section >> 22) > 0) {
					// regex has a Steam Id array index
					decl String:steamID1[STEAMID_LENGTH];
					decl String:steamID2[STEAMID_LENGTH];
					GetArrayString(g_SteamIdList, (section >> 22) - 1, steamID1, sizeof(steamID1));
					GetClientAuthId(client, AuthId_Steam2, steamID2, sizeof(steamID2));
					steamIdMatch = (strcmp(steamID1, steamID2) == 0);
				} else
					steamIdMatch = true;
				
				if (section & FLAG_ANTICAPS) {
					// regex has an anti caps filter setting
					if (CheckExpressionIndexForCaps(expression, regexIdx))
						substrings = MatchRegex(GetArrayCell(g_RegexHandles, regexIdx), expression[expressionOffset]);
					else
						substrings = 0;
					section -= FLAG_ANTICAPS;
				} else
					substrings = MatchRegex(GetArrayCell(g_RegexHandles, regexIdx), expression[expressionOffset]);
				
				if (substrings > 0
					 && steamIdMatch
					 && ((section & FLAG_ADMIN) == 0 || (GetUserAdmin(client) != INVALID_ADMIN_ID))
					 && ((section & FLAG_NOADMIN) == 0 || (GetUserAdmin(client) == INVALID_ADMIN_ID))) {
					// we have a hit!
					result = true;
					if (section & FLAG_END) {
						doLoop = false;
					}
					if (section & FLAG_SKIP || section & FLAG_IGNORE) {
						skipSection = UnflagSection(section);
					}
					if (section & FLAG_ENDSECTION) {
						skipActionGroup = g_currentSection[cs_actionGroupIdx];
					}
					
					if ((section & FLAG_IGNORE) == 0) {
						section = UnflagSection(section);
						// push matched word and section onto global arrays for further actions
						GetRegexSubString(GetArrayCell(g_RegexHandles, regexIdx), 0, keyword, sizeof(keyword));
						PushArrayString(g_MatchedExpressions, keyword);
						PushArrayCell(g_MatchedSections, section);
						
						// calculate the offset for the next regex check (don't just step to the next regex after one hit!)
						expressionOffset += StrContains(expression[expressionOffset], keyword) + strlen(keyword);
						
#if defined DEBUG
						PrintToServer("[Universal Chatfilter] We had a regex hit in section %d. PP: %d. Found %d substrings. (%s) New offset: %d", section, g_currentSection[cs_penalty], substrings, expression[expressionOffset], expressionOffset);
#endif
						if (((g_currentSection[cs_mode] == 3) || (g_currentSection[cs_mode] == 4)) && nameReplacement)
							// there is no blocking in changing names...
							resultMode = 2;
						else
							resultMode = g_currentSection[cs_mode];
						if (resultMode == 4) {
							// block for all others but the client who issued the expression
							g_InWork = 2;
							g_ExclusiveChatClient = client;
							resultMode = 1;
						}
						if (resultMode == 3) {
							// block entire expression
							g_InWork = 2;
							g_ExclusiveChatClient = 0;
							expression[0] = '\0';
							break;
						} else {
							// if there is a replacement regex, apply it
							if (g_currentSection[cs_replaceRegexIdxFrom] >= 0) {
								idx = GetRandomInt(g_currentSection[cs_replaceRegexIdxFrom], g_currentSection[cs_replaceRegexIdxTo]);
								GetArrayString(g_Replacements, idx, replace, sizeof(replace));
								// Process regex replacement special vars
								ProcessRegexReplacementString(client, GetArrayCell(g_RegexHandles, regexIdx), substrings, replace, sizeof(replace), expressionMaxlen);
							} else
								// otherwise don't replace anything
								replace[0] = '\0';
							if (resultMode == 2 && replace[0] != '\0') {
								// replace complete expression
								if (GetConVarInt(cvarLogLevel) > 1)
									LogMessage("%L triggered expression replacement. Expression '%s' is replaced by '%s' (maxlen %d)", client, expression, replace, expressionMaxlen);
								strcopy(expression, expressionMaxlen, replace);
								
							} else if (replace[0] != '\0') {
								// replace just this word and continue
								if (GetConVarInt(cvarLogLevel) > 1)
									LogMessage("%L triggered keyword replacement. In Expression '%s' the part '%s' is replaced by '%s' (maxlen %d)", client, expression, keyword, replace, expressionMaxlen);
								// adjust the expression offset, if needed
								idx = strlen(expression);
								ReplaceString(expression, expressionMaxlen, keyword, replace, true);
								if (idx != strlen(expression))
									expressionOffset += strlen(expression) - idx;
							}
							
							// if there is a name replacement (and we are not in name checking mode), apply this as well
							// (the name is always replaced completely!)
							if (!nameReplacement && g_currentSection[cs_replaceNameIdxFrom] >= 0) {
								idx = GetRandomInt(g_currentSection[cs_replaceNameIdxFrom], g_currentSection[cs_replaceNameIdxTo]);
								GetArrayString(g_NameReplacements, idx, replace, sizeof(replace));
#if defined DEBUG
								PrintToServer("[Universal Chatfilter] We have a name replacement! Section %d, replacement: %s.", section, replace);
#endif							
								// Process regex replacement special vars
								ProcessRegexReplacementString(client, GetArrayCell(g_RegexHandles, regexIdx), substrings, replace, sizeof(replace), expressionMaxlen);
								// replace the name
								if (GetConVarInt(cvarLogLevel) > 1)
									LogMessage("%L triggered name replacement. Name '%s' is replaced by '%s'", client, name, replace);
								strcopy(name, nameMaxlen, replace);
							}
							
							//if (resultMode == 2) break;	// not a good idea to just stop processing after one mode 2 hit... 
							
						}
					} else {
						regexIdx++;
						expressionOffset = 0;
					}
				} else {
					regexIdx++;
					expressionOffset = 0;
				}
			} else {
				regexIdx++;
				expressionOffset = 0;
			}
		} else {
			regexIdx++;
			expressionOffset = 0;
		}
	}
	return result;
}

/** 
 * Processes specials tags for regex replacement strings:
 *   $0 is replaced by the complete matched string of the regex handle
 *   $1 is replaced by the first matched substring of the regex handle
 *   $2 is replaced by the 2nd matched substring of the regex handle
 *   .
 *   .
 *   $9 is replaced by the 9th matched substring of the regex handle
 *   (who would ever need more than 9 matched substrings?!)
 *
 * There are two modifiers: 'L', and 'U'. For example:  
 *   $L1 converts the 1st matched substring to lowercase letters.
 *   $U3 converts the 3rd matched substring to uppercase letters.
 *
 * @param client			client id
 * @param regexHandle		regular expression handle
 * @param substrings		number of mached substrings for the handle
 * @param expression		string expression which is processed
 * @param maxlen			maxlen of string buffer/expression
 * @noreturn
 */
void ProcessRegexReplacementString(const client, const Handle:regexHandle, substrings, String:expression[], const maxlen, const maxMessageLen) {
	ReplaceClientTags(client, expression, maxlen);
	decl String:search[4];
	decl String:replace[MAX_EXPRESSION_LENGTH * 3];
#if defined DEBUG
	PrintToServer("[Universal Chatfilter] Entering ProcessRegexReplacementString! Substrings %d, Expression: %s.", substrings, expression);
#endif
	for (new i = 0; i < 10; i++) {
		Format(search, sizeof(search), "$%d", i);
		if (i < substrings) {
			// check for tags and replace if needed
			if (GetRegexSubString(regexHandle, i, replace, sizeof(replace))) {
#if defined DEBUG
				//PrintToServer("[Universal Chatfilter] i: %d, search: %s, replace: %s", i, search, replace);
#endif				
				ReplaceString(expression, maxlen, search, replace, false);
				Format(search, sizeof(search), "$L%d", i);
				if (StrContains(expression, search, false) != -1) {
					StringToLower(replace);
					ReplaceString(expression, maxlen, search, replace, false);
				}
				Format(search, sizeof(search), "$U%d", i);
				if (StrContains(expression, search, false) != -1) {
					StringToUpper(replace);
					ReplaceString(expression, maxlen, search, replace, false);
				}
			}
		} else {
			// erase all tags that are not needed
			ReplaceString(expression, maxlen, search, "", false);
			Format(search, sizeof(search), "$L%d", i);
			ReplaceString(expression, maxlen, search, "", false);
			Format(search, sizeof(search), "$U%d", i);
			ReplaceString(expression, maxlen, search, "", false);
		}
	}
	// Process 'PLAY' tags
	Handle regex = CompileRegex(PLAY_REGEX);
	substrings = 1;
	char file[PLATFORM_MAX_PATH];
	decl maxClients;
	while (substrings > 0) {
		substrings = MatchRegex(regex, expression);
#if defined DEBUG
		PrintToServer("[Universal Chatfilter] 'PLAY' tag check: '%s' - Substrings: %d", expression, substrings);
#endif				
		if (substrings > 0) {
			// get the sound and play it
			GetRegexSubString(regex, 2, file, sizeof(file));
			if (GetConVarInt(cvarLogLevel) > 1)
				LogMessage("%L triggered playing sound '%s'", client, file);
			maxClients = GetMaxClients();
			for (new i = 1; i <= maxClients; ++i)
			if (IsClientConnected(i) && !IsFakeClient(i))
				ClientCommand(i, "playgamesound \"%s\"", file);
			// erase tag from expression
			GetRegexSubString(regex, 1, file, sizeof(file));
			expression[strlen(file)] = '\0';
			GetRegexSubString(regex, 3, expression[strlen(file)], maxlen - strlen(file));
			//StrCat(expression, maxlen, file);
#if defined DEBUG
			PrintToServer("[Universal Chatfilter] Expression after playing sound: '%s'", expression);
#endif				
		}
	}
	CloseHandle(regex);
	// Process color tags in expression
	ProcessColorCodes(expression, maxlen, client);
	// Process color flow tags in expression
	ProcessColorFlows(expression, maxlen);
}

/** 
 * Converts a String to lowercase chars (by ref!)
 *
 * @param string		string expression to be converted (by ref)
 * @return				number of checked letters
 */
StringToLower(String:string[]) {
	new n = 0;
	while (string[n] != '\0' && n < 256) {
		string[n] = CharToLower(string[n]);
		n++;
	}
	return n;
}

/** 
 * Converts a String to uppercase chars (by ref!)
 *
 * @param string		string expression to be converted (by ref)
 * @return				number of checked letters
 */
StringToUpper(String:string[]) {
	new n = 0;
	while (string[n] != '\0' && n < 256) {
		string[n] = CharToUpper(string[n]);
		n++;
	}
	return n;
}

/** 
 * Gets the number of non space chars in a string - multibyte safe!
 *
 * @param string		string expression
 * @return				number of checked letters
 */
GetNonSpaceChars(String:string[]) {
	new n = 0;
	new i = 0;
	while (string[i] != '\0') {
		if (string[i] != ' ' && (string[i] & 0xc0) != 0x80)
			n++;
		i++;
	}
	return n;
}

/** 
 * Checks if the string ends with an incomplete color code and cuts it off
 *
 * @param string		string expression
 * @return				true, if there was a color code, false otherwises
 */
CleanColorCodeFragments(String:string[]) {
	new max = strlen(string) - 1;
	if (max < 0) max = 0;
	new i = max;
	while (i > 0 && i > (max - 9)) {
		if ((string[i] == '\x07' && (max - i) < 7) || (string[i] == '\x08' && (max - i) < 9)) {
#if defined DEBUG
			PrintToServer("[Universal Chatfilter] CleanColorCodeFragments - Now cutting off! i: %d", i);
#endif
			string[i] = '\0';
			return true;
		}
		i--;
	}
	return false;
}

/** 
 * Fetches the corresponding anti CAPS settings and checks the expression.
 *
 * @param expression		string expression to be checked
 * @param expressionIndex	index of the expression (referring to g_RegexHandles array)
 * @return					true if the given Strings contains too much capital letters, false otherwise
 */
bool CheckExpressionIndexForCaps(const String:expression[], const expressionIndex) {
	new maxlen = GetArraySize(g_AntiCaps);
	decl thisACL[enumAntiCaps];
	for (new i = 0; i < maxlen; i++) {
		GetArrayArray(g_AntiCaps, i, thisACL[0]);
		if (thisACL[ac_findIdx] == expressionIndex)
			return CheckForCaps(expression, thisACL[ac_ratio], thisACL[ac_minLetters]);
	}
	return false;
}

/** 
 * Checks the expression for an excessive use of CAPS.
 *
 * @param expression		String expression to be checked
 * @param capsRatio			Ratio of CAPS characters contained in all relevant letters
 * @param minLetters		minimum number of relevant characters (that can be either uppercase or lowercase)
 * @return					true if the given Strings contains too much capital letters, false otherwise
 */
bool CheckForCaps(const String:expression[], const float capsRatio, const minLetters) {
	bool result = false;
	new lowerCaseChars;
	new upperCaseChars;
	decl lc;
	decl uc;
	new ignoreCounter;
	new maxlen = strlen(expression);
	for (new i = 0; i < maxlen; i++) {
		if (ignoreCounter == 0) {
			if (expression[i] == '\x07') {
				// attention: we have a RGB color indicator: ignore the next 6 chars...
				ignoreCounter = 6;
			} else if (expression[i] == '\x08') {
				// attention: we have a RGB color indicator: ignore the next 8 chars...
				ignoreCounter = 8;
			} else {
				lc = CharToLower(expression[i]);
				uc = CharToUpper(expression[i]);
				if (lc != uc)
					if (lc == expression[i])
						lowerCaseChars++;
					else
						upperCaseChars++;
			}
		} else
			ignoreCounter--;
	}
	if (lowerCaseChars + upperCaseChars >= minLetters) {
		float ratio = FloatDiv(float(upperCaseChars), float(lowerCaseChars + upperCaseChars));
		if (ratio >= capsRatio)
			result = true;
	}
	return result;
}


/** 
 * Clean up on exit and close all handles (and sub-handles)
 *
 * @noreturn
 */
void ResetConfigArrays() {
	ClearArray(g_ActionGroups);
	ClearArray(g_PlayerPenaltyPoints);
	decl i;
	for (i = 0; i < sizeof(g_currentPenaltyPoints); i++)
	g_currentPenaltyPoints[i] = 0;
	for (i = 0; i < sizeof(g_currentLastActions); i++)
	g_currentLastActions[i] = -1;
	ClearArray(g_ConfigSections);
	if (g_RegexHandles != INVALID_HANDLE)
		for (i = 0; i < GetArraySize(g_RegexHandles); i++)
	CloseHandle(GetArrayCell(g_RegexHandles, i));
	ClearArray(g_RegexHandles);
	ClearArray(g_RegexHandleSections);
	ClearArray(g_RegexHandleGroups);
	ClearArray(g_RegexHandleTeams);
	ClearArray(g_AntiCaps);
	ClearArray(g_Actions);
	ClearArray(g_NameReplacements);
	ClearArray(g_Replacements);
	ClearArray(g_MatchedExpressions);
	ClearArray(g_MatchedSections);
	ClearArray(g_GroupList);
	ClearArray(g_GroupFlags);
	ClearArray(g_SteamIdList);
	if (g_GroupMembers != INVALID_HANDLE)
		ClearTrie(g_GroupMembers);
}


/** 
 * Find the action group array by its action group id and
 * copy it to the global variable g_currentActionGroup
 *
 * @param actionGroupID		id number of requested action group
 * @return					index of array g_ActionGroups, -1 if id was not found
 */
FindActionGroupArray(int actionGroupID) {
	g_currentActionGroup[ag_id] = -1;
	new numGroups = GetArraySize(g_ActionGroups);
	for (new i = 0; i < numGroups; i++) {
		GetArrayArray(g_ActionGroups, i, g_currentActionGroup[0]);
		if (g_currentActionGroup[ag_id] == actionGroupID)
			return i;
	}
	return -1;
}

/** 
 * Takes a config file section index and removes all token
 * flags
 *
 * @param section		index of config section
 * @return				index without flags like FLAG_ANTICAPS, FLAG_END etc.
 */
UnflagSection(const section) {
	return (section & 1023);
}

/** 
 * Converts a string in the format YYYY-MM-DD hh:mm into an unix timestamp
 *
 * @param timeString	string containing the DateTime value
 * @return				unix timestamp
 */
StringToEpoch(const String:timeValue[]) {
	new result = 0;
	char timeString[25];
	// this is hacky! Because I could not figure out, how to do this in genuine
	// sourcepawn, I let sqlite do the work...
	Handle db = SQLite_UseDatabase("sourcemod-local", g_LastError, sizeof(g_LastError)); //SQL_Connect("storage-local", true);
	if (db != INVALID_HANDLE) {
		// first take care of quotes and copy the datetime string
		new offset = 0;
		if (timeValue[0] == '"')
			offset = 1;
		strcopy(timeString, sizeof(timeString), timeValue[offset]);
		if (timeString[strlen(timeString) - 1] == '"')
			timeString[strlen(timeString) - 1] == '\0';
		char sql[51];
		Format(sql, sizeof(sql), "select strftime('%%s', '%s')", timeString);
		Handle rowHandle = SQL_Query(db, sql);
		if (rowHandle != INVALID_HANDLE) {
			if (SQL_FetchRow(rowHandle)) {
				result = SQL_FetchInt(rowHandle, 0);
			} else
				LogError("Error in StringToEpoch, could not fetch first row from this resultset: '%s'", sql);
			CloseHandle(rowHandle);
		} else
			LogError("Error in StringToEpoch, could not execute this sql: '%s'", sql);
		CloseHandle(db);
	} else
		LogError("Error in StringToEpoch, could not connect to SQLite database 'sourcemod-local': %s", g_LastError);
#if defined DEBUG
	PrintToServer("[Universal Chatfilter] Routine StringToEpoch: Converted DateTime '%s' to int value %d", timeString, result);
#endif
	return result;
}

/** 
 * Put a client or all clients into a group according to his or her steam id.
 * Uses the GroupMembers trie to determine the group.
 *
 * @param client		client id of player. If client = 0, all players will be checked and grouped.
 * @return				index of group list names array, -1 if no group was found
 */
GroupClient(const client) {
	decl String:steamID[STEAMID_LENGTH];
	new groupIdx = -1;
	if (client > 0) {
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		if (GetTrieValue(g_GroupMembers, steamID, groupIdx))
			g_PlayerGroups[client] = groupIdx;
		return groupIdx;
	} else {
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && !IsFakeClient(i)) {
				GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));
				if (GetTrieValue(g_GroupMembers, steamID, groupIdx))
					g_PlayerGroups[i] = groupIdx;
			}
		}
		return 0;
	}
}

/**
 * Replaces color tags in a string with color codes
 *
 * @param buffer		String.
 * @param client		Optional client index to use for {teamcolor} tags, or 0 for none
 * @noreturn
 * 
 * On error/Errors:		If the client index passed for client is invalid or not in game.
 */
void ProcessColorCodes(String:buffer[], maxlen = MAX_EXPRESSION_LENGTH, client = 0) {
	ReplaceString(buffer, maxlen, "{default}", "\x01", false);
	if (client > 0)
		if (IsClientInGame(client))
		ReplaceString(buffer, maxlen, "{teamcolor}", "\x03", false);
	
	decl String:tag[32], String:buff[32], String:output[maxlen];
	strcopy(output, maxlen, buffer);
	// Since the string's size is going to be changing, output will hold the replaced string and we'll search buffer
	
	Handle regex = CompileRegex(COLORTAG_REGEX);
	Handle regexRGB = CompileRegex(RGB_REGEX);
	new substrings = 1;
	decl colorValue;
	while (substrings > 0) {
		substrings = MatchRegex(regex, output);
		if (substrings > 0) {
			GetRegexSubString(regex, 1, tag[1], sizeof(tag) - 1);
			StringToLower(tag);
			if (GetTrieValue(g_ColorTrie, tag[1], colorValue)) {
				Format(buff, sizeof(buff), "\x07%06X", colorValue);
				tag[0] = '{';
				tag[strlen(tag) + 1] = '\0';
				tag[strlen(tag)] = '}';
#if defined DEBUG
				//PrintToServer("[Universal Chatfilter] Color token replacement. Now replacing '%s' with '%s'", tag, buff);
#endif
				ReplaceString(output, maxlen, tag, buff, false);
			} else {
				// invalid token given: erase to prevent endless loop...
				GetRegexSubString(regex, 0, tag, sizeof(tag));
				ReplaceString(output, maxlen, tag, "", false);
			}
			
		} else {
			substrings = MatchRegex(regexRGB, output);
			if (substrings > 0) {
				GetRegexSubString(regexRGB, 1, tag, sizeof(tag));
				StringToUpper(tag);
#if defined DEBUG
				PrintToServer("[Universal Chatfilter] Color RGB replacement. Substring 1: '%s'", tag);
#endif				
				if (strlen(tag) == 6)
					Format(buff, sizeof(buff), "\x07%s", tag);
				else
					Format(buff, sizeof(buff), "\x08%08s", tag);
				GetRegexSubString(regexRGB, 0, tag, sizeof(tag));
#if defined DEBUG
				PrintToServer("[Universal Chatfilter] Color RGB replacement. Now replacing '%s' with '%s'", tag, buff);
#endif
				ReplaceString(output, maxlen, tag, buff, false);
			}
		}
	}
	CloseHandle(regex);
	CloseHandle(regexRGB);
	strcopy(buffer, maxlen, output);
}

/**
 * Handles color flow tags in a string by placing calculated colors
 * (Pretty cool feature!)
 *
 * @param expression		String to be checked
 * @noreturn
 */
void ProcessColorFlows(String:expression[], maxlen) {
	// copy the expression for further processing
	decl String:output[maxlen];
	decl String:substring[maxlen];
	decl String:leftover[maxlen];
	strcopy(output, maxlen, expression);
	
	Handle regex = CompileRegex(COLORFLOW_REGEX);
	new substrings = 1;
	decl String:temp[maxlen];
	decl String:hex[3];
	decl visibleChars;
	decl charStartIdx;
	decl intVal;
	float StepsPerChar;
	float FlowsPerChar;
	
	float flowIdx;
	decl lastFlowIdx;
	decl thisFlowIdx;
	float stepIdx;
	decl lastStepIdx;
	decl thisStepIdx;
	float thisR;
	float thisG;
	float thisB;
	float thisA;
	
#if defined DEBUG
	PrintToServer("[Universal Chatfilter] Now checking color flow. maxlen %d / expression '%s'", maxlen, expression);
#endif	
	while (substrings > 0) {
		substrings = MatchRegex(regex, output);
		if (substrings > 0) {
			// get the starting character index
			GetRegexSubString(regex, 1, temp, maxlen);
			charStartIdx = strlen(temp);
			// get the text to be "rainbowed"
			GetRegexSubString(regex, substrings - 2, substring, maxlen);
			visibleChars = GetNonSpaceChars(substring);
			// calculate the number of possible color steps and the char to color step ratio
			GetRegexSubString(regex, substrings - 1, leftover, maxlen);
			GetRegexSubString(regex, 2, temp, maxlen);
			intVal = (strlen(temp) == 6 ? 7 : 9);
			new numberOfSteps = (MAX_MESSAGE_LENGTH - charStartIdx - strlen(substring) - strlen(leftover) - 8) / intVal;	// the - 8 is just to be sure... 
#if defined DEBUG
			PrintToServer("[Universal Chatfilter] maxlen - charStartIdx - strlen(substring) - strlen(leftover) %d %d %d %d", MAX_MESSAGE_LENGTH, charStartIdx, strlen(substring), strlen(leftover));
#endif
			if (numberOfSteps < 0)
				numberOfSteps = 1;
			else if (numberOfSteps > visibleChars)
				numberOfSteps = visibleChars;
			if (visibleChars > 1) visibleChars--;
			StepsPerChar = FloatDiv(float(numberOfSteps), float(visibleChars));
#if defined DEBUG
			PrintToServer("[Universal Chatfilter] Visible Chars: %d / Color Steps: %d / Ratio: %f", visibleChars, numberOfSteps, StepsPerChar);
#endif	
			// set up the color flows
			char rgba[10][10];
			GetRegexSubString(regex, 3, temp, maxlen);
			new numberOfFlows = ExplodeString(temp[1], "-", rgba, 10, 10);
			FlowsPerChar = FloatDiv(float(numberOfFlows), float(visibleChars));
			new flows[numberOfFlows][enumColorFlow];
			for (new i = 0; i < numberOfFlows; i++) {
				if (i == 0) {
					// first flow: get the starting color codes from regex substring
					GetRegexSubString(regex, 2, temp, maxlen);
				} else {
					// otherwise get the starting color codes from rgba array
					strcopy(temp, maxlen, rgba[i - 1]);
				}
				strcopy(hex, sizeof(hex), temp[0]);
				flows[i][cf_startR] = StringToInt(hex, 16);
				strcopy(hex, sizeof(hex), temp[2]);
				flows[i][cf_startG] = StringToInt(hex, 16);
				strcopy(hex, sizeof(hex), temp[4]);
				flows[i][cf_startB] = StringToInt(hex, 16);
				if (strlen(temp) == 8) {
					strcopy(hex, sizeof(hex), temp[6]);
					flows[i][cf_startA] = StringToInt(hex, 16);
				} else
					flows[i][cf_startA] = 255;
				strcopy(temp, maxlen, rgba[i]);
				strcopy(hex, sizeof(hex), temp[0]);
				flows[i][cf_deltaR] = FloatDiv(float(StringToInt(hex, 16) - flows[i][cf_startR]), FloatDiv(float(visibleChars), float(numberOfFlows)));
				strcopy(hex, sizeof(hex), temp[2]);
				flows[i][cf_deltaG] = FloatDiv(float(StringToInt(hex, 16) - flows[i][cf_startG]), FloatDiv(float(visibleChars), float(numberOfFlows)));
				strcopy(hex, sizeof(hex), temp[4]);
				flows[i][cf_deltaB] = FloatDiv(float(StringToInt(hex, 16) - flows[i][cf_startB]), FloatDiv(float(visibleChars), float(numberOfFlows)));
				if (strlen(temp) == 8) {
					strcopy(hex, sizeof(hex), temp[6]);
					flows[i][cf_deltaA] = FloatDiv(float(StringToInt(hex, 16) - flows[i][cf_startA]), FloatDiv(float(visibleChars), float(numberOfFlows)));
				} else
					flows[i][cf_deltaA] = 0.0;
#if defined DEBUG
				PrintToServer("[Universal Chatfilter] Color flow no %d. R: %d / G: %d / B: %d / A: %d / Deltas: %f %f %f %f", i, (flows[i][cf_startR]), (flows[i][cf_startG]), (flows[i][cf_startB]), (flows[i][cf_startA]), flows[i][cf_deltaR], flows[i][cf_deltaG], flows[i][cf_deltaB], flows[i][cf_deltaA]);
#endif	
			}
			// loop the substring
			flowIdx = 0.0;
			lastFlowIdx = -1;
			stepIdx = 0.0;
			lastStepIdx = -1;
			intVal = charStartIdx; // used as character (byte) index for output here
			for (new i = 0; i < strlen(substring); i++) {
				thisFlowIdx = RoundToZero(flowIdx);
				if (thisFlowIdx >= numberOfFlows)
					thisFlowIdx = numberOfFlows - 1;
				if (thisFlowIdx != lastFlowIdx) {
#if defined DEBUG
					PrintToServer("[Universal Chatfilter] flowIdx: %f / thisFlowIdx: %d / i: %d / FlowsPerChar: %f / StepsPerChar: %f", flowIdx, thisFlowIdx, i, FlowsPerChar, StepsPerChar);
#endif	
					// a new color flow starts
					lastFlowIdx = thisFlowIdx;
					thisR = float(flows[thisFlowIdx][cf_startR]);
					thisG = float(flows[thisFlowIdx][cf_startG]);
					thisB = float(flows[thisFlowIdx][cf_startB]);
					thisA = float(flows[thisFlowIdx][cf_startA]);
				}
				thisStepIdx = RoundToZero(stepIdx);
				if (thisStepIdx >= numberOfSteps)
					thisStepIdx = numberOfSteps - 1;
				if (thisStepIdx != lastStepIdx) {
					// a new color step has to be written to the output
					lastStepIdx = thisStepIdx;
					if (RoundFloat(thisA) == 255)
						Format(temp, 20, "\x07%02X%02X%02X", RoundFloat(thisR), RoundFloat(thisG), RoundFloat(thisB));
					else
						Format(temp, 20, "\x08%02X%02X%02X%02X", RoundFloat(thisR), RoundFloat(thisG), RoundFloat(thisB), RoundFloat(thisA));
					strcopy(output[intVal], maxlen - intVal, temp);
#if defined DEBUG
					PrintToServer("[Universal Chatfilter] stepIdx: %f / thisStepIdx: %d / i: %d / StepsPerChar: %f / strlen(): %d (%s) %d %d %d %d", stepIdx, thisStepIdx, i, StepsPerChar, strlen(temp), temp, RoundFloat(thisR), RoundFloat(thisG), RoundFloat(thisB), RoundFloat(thisA));
#endif
					intVal += strlen(temp);
				}
				// copy current character to output - multi byte save and color code aware!
				if (substring[i] == '\x07') {
					// color code - 7 bytes
					for (new j = 0; j < 7; j++)
					output[intVal + j] = substring[i + j];
					i += 7 - 1;
					intVal += 7;
				} else if (substring[i] == '\x08') {
					// color code - 9 bytes
					for (new j = 0; j < 9; j++)
					output[intVal + j] = substring[i + j];
					i += 9 - 1;
					intVal += 9;
				} else if ((substring[i] & 0xC0) == 0xC0) {
					// multi byte - starting char
					output[intVal] = substring[i];
					intVal++;
					i++;
					while ((substring[i] & 0xC0) == 0x80) {
						// multi byte - following char
						output[intVal] = substring[i];
						intVal++;
						i++;
					}
					i--;
				} else {
					// regular single byte char (ASCII)
					output[intVal] = substring[i];
					intVal++;
				}
				if (substring[i] != ' ' && visibleChars > 1) {  // no need for fancy flow when there are only 2 chars!
					flowIdx = FloatAdd(flowIdx, FlowsPerChar);
					stepIdx = FloatAdd(stepIdx, StepsPerChar);
					thisR = FloatAdd(thisR, flows[thisFlowIdx][cf_deltaR]);
					thisG = FloatAdd(thisG, flows[thisFlowIdx][cf_deltaG]);
					thisB = FloatAdd(thisB, flows[thisFlowIdx][cf_deltaB]);
					thisA = FloatAdd(thisA, flows[thisFlowIdx][cf_deltaA]);
				}
			}
			// lastly, append the leftover
			strcopy(output[intVal], maxlen - intVal, leftover);
		}
	}
	CloseHandle(regex);
	strcopy(expression, maxlen, output);
}

/**
 * Checks if the colors trie is initialized and initializes it if it's not (used internally)
 * 
 * @noreturn
 */
void CheckColorTrie() {
	if (g_ColorTrie == INVALID_HANDLE) {
		g_ColorTrie = InitColorTrie();
	}
}
/**
 * Inits the color trie and returns the handle.
 *
 * @return	Handle for the color trie
 */
Handle:InitColorTrie() {
	Handle hTrie = CreateTrie();
	SetTrieValue(hTrie, "aliceblue", 0xF0F8FF);
	SetTrieValue(hTrie, "allies", 0x4D7942); // same as Allies team in DoD:S
	SetTrieValue(hTrie, "ancient", 0xEB4B4B); // same as Ancient item rarity in Dota 2
	SetTrieValue(hTrie, "antiquewhite", 0xFAEBD7);
	SetTrieValue(hTrie, "aqua", 0x00FFFF);
	SetTrieValue(hTrie, "aquamarine", 0x7FFFD4);
	SetTrieValue(hTrie, "arcana", 0xADE55C); // same as Arcana item rarity in Dota 2
	SetTrieValue(hTrie, "axis", 0xFF4040); // same as Axis team in DoD:S
	SetTrieValue(hTrie, "azure", 0x007FFF);
	SetTrieValue(hTrie, "beige", 0xF5F5DC);
	SetTrieValue(hTrie, "bisque", 0xFFE4C4);
	SetTrieValue(hTrie, "black", 0x000000);
	SetTrieValue(hTrie, "blanchedalmond", 0xFFEBCD);
	SetTrieValue(hTrie, "blue", 0x99CCFF); // same as BLU/Counter-Terrorist team color
	SetTrieValue(hTrie, "blueviolet", 0x8A2BE2);
	SetTrieValue(hTrie, "brown", 0xA52A2A);
	SetTrieValue(hTrie, "burlywood", 0xDEB887);
	SetTrieValue(hTrie, "cadetblue", 0x5F9EA0);
	SetTrieValue(hTrie, "chartreuse", 0x7FFF00);
	SetTrieValue(hTrie, "chocolate", 0xD2691E);
	SetTrieValue(hTrie, "collectors", 0xAA0000); // same as Collector's item quality in TF2
	SetTrieValue(hTrie, "common", 0xB0C3D9); // same as Common item rarity in Dota 2
	SetTrieValue(hTrie, "community", 0x70B04A); // same as Community item quality in TF2
	SetTrieValue(hTrie, "coral", 0xFF7F50);
	SetTrieValue(hTrie, "cornflowerblue", 0x6495ED);
	SetTrieValue(hTrie, "cornsilk", 0xFFF8DC);
	SetTrieValue(hTrie, "corrupted", 0xA32C2E); // same as Corrupted item quality in Dota 2
	SetTrieValue(hTrie, "crimson", 0xDC143C);
	SetTrieValue(hTrie, "cyan", 0x00FFFF);
	SetTrieValue(hTrie, "darkblue", 0x00008B);
	SetTrieValue(hTrie, "darkcyan", 0x008B8B);
	SetTrieValue(hTrie, "darkgoldenrod", 0xB8860B);
	SetTrieValue(hTrie, "darkgray", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgrey", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgreen", 0x006400);
	SetTrieValue(hTrie, "darkkhaki", 0xBDB76B);
	SetTrieValue(hTrie, "darkmagenta", 0x8B008B);
	SetTrieValue(hTrie, "darkolivegreen", 0x556B2F);
	SetTrieValue(hTrie, "darkorange", 0xFF8C00);
	SetTrieValue(hTrie, "darkorchid", 0x9932CC);
	SetTrieValue(hTrie, "darkred", 0x8B0000);
	SetTrieValue(hTrie, "darksalmon", 0xE9967A);
	SetTrieValue(hTrie, "darkseagreen", 0x8FBC8F);
	SetTrieValue(hTrie, "darkslateblue", 0x483D8B);
	SetTrieValue(hTrie, "darkslategray", 0x2F4F4F);
	SetTrieValue(hTrie, "darkslategrey", 0x2F4F4F);
	SetTrieValue(hTrie, "darkturquoise", 0x00CED1);
	SetTrieValue(hTrie, "darkviolet", 0x9400D3);
	SetTrieValue(hTrie, "deeppink", 0xFF1493);
	SetTrieValue(hTrie, "deepskyblue", 0x00BFFF);
	SetTrieValue(hTrie, "dimgray", 0x696969);
	SetTrieValue(hTrie, "dimgrey", 0x696969);
	SetTrieValue(hTrie, "dodgerblue", 0x1E90FF);
	SetTrieValue(hTrie, "exalted", 0xCCCCCD); // same as Exalted item quality in Dota 2
	SetTrieValue(hTrie, "firebrick", 0xB22222);
	SetTrieValue(hTrie, "floralwhite", 0xFFFAF0);
	SetTrieValue(hTrie, "forestgreen", 0x228B22);
	SetTrieValue(hTrie, "frozen", 0x4983B3); // same as Frozen item quality in Dota 2
	SetTrieValue(hTrie, "fuchsia", 0xFF00FF);
	SetTrieValue(hTrie, "fullblue", 0x0000FF);
	SetTrieValue(hTrie, "fullred", 0xFF0000);
	SetTrieValue(hTrie, "gainsboro", 0xDCDCDC);
	SetTrieValue(hTrie, "genuine", 0x4D7455); // same as Genuine item quality in TF2
	SetTrieValue(hTrie, "ghostwhite", 0xF8F8FF);
	SetTrieValue(hTrie, "gold", 0xFFD700);
	SetTrieValue(hTrie, "goldenrod", 0xDAA520);
	SetTrieValue(hTrie, "gray", 0xCCCCCC); // same as spectator team color
	SetTrieValue(hTrie, "grey", 0xCCCCCC);
	SetTrieValue(hTrie, "green", 0x3EFF3E);
	SetTrieValue(hTrie, "greenyellow", 0xADFF2F);
	SetTrieValue(hTrie, "haunted", 0x38F3AB); // same as Haunted item quality in TF2
	SetTrieValue(hTrie, "honeydew", 0xF0FFF0);
	SetTrieValue(hTrie, "hotpink", 0xFF69B4);
	SetTrieValue(hTrie, "immortal", 0xE4AE33); // same as Immortal item rarity in Dota 2
	SetTrieValue(hTrie, "indianred", 0xCD5C5C);
	SetTrieValue(hTrie, "indigo", 0x4B0082);
	SetTrieValue(hTrie, "ivory", 0xFFFFF0);
	SetTrieValue(hTrie, "khaki", 0xF0E68C);
	SetTrieValue(hTrie, "lavender", 0xE6E6FA);
	SetTrieValue(hTrie, "lavenderblush", 0xFFF0F5);
	SetTrieValue(hTrie, "lawngreen", 0x7CFC00);
	SetTrieValue(hTrie, "legendary", 0xD32CE6); // same as Legendary item rarity in Dota 2
	SetTrieValue(hTrie, "lemonchiffon", 0xFFFACD);
	SetTrieValue(hTrie, "lightblue", 0xADD8E6);
	SetTrieValue(hTrie, "lightcoral", 0xF08080);
	SetTrieValue(hTrie, "lightcyan", 0xE0FFFF);
	SetTrieValue(hTrie, "lightgoldenrodyellow", 0xFAFAD2);
	SetTrieValue(hTrie, "lightgray", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgrey", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgreen", 0x99FF99);
	SetTrieValue(hTrie, "lightpink", 0xFFB6C1);
	SetTrieValue(hTrie, "lightsalmon", 0xFFA07A);
	SetTrieValue(hTrie, "lightseagreen", 0x20B2AA);
	SetTrieValue(hTrie, "lightskyblue", 0x87CEFA);
	SetTrieValue(hTrie, "lightslategray", 0x778899);
	SetTrieValue(hTrie, "lightslategrey", 0x778899);
	SetTrieValue(hTrie, "lightsteelblue", 0xB0C4DE);
	SetTrieValue(hTrie, "lightyellow", 0xFFFFE0);
	SetTrieValue(hTrie, "lime", 0x00FF00);
	SetTrieValue(hTrie, "limegreen", 0x32CD32);
	SetTrieValue(hTrie, "linen", 0xFAF0E6);
	SetTrieValue(hTrie, "magenta", 0xFF00FF);
	SetTrieValue(hTrie, "maroon", 0x800000);
	SetTrieValue(hTrie, "mediumaquamarine", 0x66CDAA);
	SetTrieValue(hTrie, "mediumblue", 0x0000CD);
	SetTrieValue(hTrie, "mediumorchid", 0xBA55D3);
	SetTrieValue(hTrie, "mediumpurple", 0x9370D8);
	SetTrieValue(hTrie, "mediumseagreen", 0x3CB371);
	SetTrieValue(hTrie, "mediumslateblue", 0x7B68EE);
	SetTrieValue(hTrie, "mediumspringgreen", 0x00FA9A);
	SetTrieValue(hTrie, "mediumturquoise", 0x48D1CC);
	SetTrieValue(hTrie, "mediumvioletred", 0xC71585);
	SetTrieValue(hTrie, "midnightblue", 0x191970);
	SetTrieValue(hTrie, "mintcream", 0xF5FFFA);
	SetTrieValue(hTrie, "mistyrose", 0xFFE4E1);
	SetTrieValue(hTrie, "moccasin", 0xFFE4B5);
	SetTrieValue(hTrie, "mythical", 0x8847FF); // same as Mythical item rarity in Dota 2
	SetTrieValue(hTrie, "navajowhite", 0xFFDEAD);
	SetTrieValue(hTrie, "navy", 0x000080);
	SetTrieValue(hTrie, "normal", 0xB2B2B2); // same as Normal item quality in TF2
	SetTrieValue(hTrie, "oldlace", 0xFDF5E6);
	SetTrieValue(hTrie, "olive", 0x9EC34F);
	SetTrieValue(hTrie, "olivedrab", 0x6B8E23);
	SetTrieValue(hTrie, "orange", 0xFFA500);
	SetTrieValue(hTrie, "orangered", 0xFF4500);
	SetTrieValue(hTrie, "orchid", 0xDA70D6);
	SetTrieValue(hTrie, "palegoldenrod", 0xEEE8AA);
	SetTrieValue(hTrie, "palegreen", 0x98FB98);
	SetTrieValue(hTrie, "paleturquoise", 0xAFEEEE);
	SetTrieValue(hTrie, "palevioletred", 0xD87093);
	SetTrieValue(hTrie, "papayawhip", 0xFFEFD5);
	SetTrieValue(hTrie, "peachpuff", 0xFFDAB9);
	SetTrieValue(hTrie, "peru", 0xCD853F);
	SetTrieValue(hTrie, "pink", 0xFFC0CB);
	SetTrieValue(hTrie, "plum", 0xDDA0DD);
	SetTrieValue(hTrie, "powderblue", 0xB0E0E6);
	SetTrieValue(hTrie, "purple", 0x800080);
	SetTrieValue(hTrie, "rare", 0x4B69FF); // same as Rare item rarity in Dota 2
	SetTrieValue(hTrie, "red", 0xFF4040); // same as RED/Terrorist team color
	SetTrieValue(hTrie, "rosybrown", 0xBC8F8F);
	SetTrieValue(hTrie, "royalblue", 0x4169E1);
	SetTrieValue(hTrie, "saddlebrown", 0x8B4513);
	SetTrieValue(hTrie, "salmon", 0xFA8072);
	SetTrieValue(hTrie, "sandybrown", 0xF4A460);
	SetTrieValue(hTrie, "seagreen", 0x2E8B57);
	SetTrieValue(hTrie, "seashell", 0xFFF5EE);
	SetTrieValue(hTrie, "selfmade", 0x70B04A); // same as Self-Made item quality in TF2
	SetTrieValue(hTrie, "sienna", 0xA0522D);
	SetTrieValue(hTrie, "silver", 0xC0C0C0);
	SetTrieValue(hTrie, "skyblue", 0x87CEEB);
	SetTrieValue(hTrie, "slateblue", 0x6A5ACD);
	SetTrieValue(hTrie, "slategray", 0x708090);
	SetTrieValue(hTrie, "slategrey", 0x708090);
	SetTrieValue(hTrie, "snow", 0xFFFAFA);
	SetTrieValue(hTrie, "springgreen", 0x00FF7F);
	SetTrieValue(hTrie, "steelblue", 0x4682B4);
	SetTrieValue(hTrie, "strange", 0xCF6A32); // same as Strange item quality in TF2
	SetTrieValue(hTrie, "tan", 0xD2B48C);
	SetTrieValue(hTrie, "teal", 0x008080);
	SetTrieValue(hTrie, "thistle", 0xD8BFD8);
	SetTrieValue(hTrie, "tomato", 0xFF6347);
	SetTrieValue(hTrie, "turquoise", 0x40E0D0);
	SetTrieValue(hTrie, "uncommon", 0xB0C3D9); // same as Uncommon item rarity in Dota 2
	SetTrieValue(hTrie, "unique", 0xFFD700); // same as Unique item quality in TF2
	SetTrieValue(hTrie, "unusual", 0x8650AC); // same as Unusual item quality in TF2
	SetTrieValue(hTrie, "valve", 0xA50F79); // same as Valve item quality in TF2
	SetTrieValue(hTrie, "vintage", 0x476291); // same as Vintage item quality in TF2
	SetTrieValue(hTrie, "violet", 0xEE82EE);
	SetTrieValue(hTrie, "wheat", 0xF5DEB3);
	SetTrieValue(hTrie, "white", 0xFFFFFF);
	SetTrieValue(hTrie, "whitesmoke", 0xF5F5F5);
	SetTrieValue(hTrie, "yellow", 0xFFFF00);
	SetTrieValue(hTrie, "yellowgreen", 0x9ACD32);
	return hTrie;
}

/**
 * Calculates the printed length of a string - multibyte-safe!
 *
 */
stock StrLenMB(const String:str[])
{
	new len = strlen(str);
	new count;
	for (new i; i < len; i++)
	count += ((str[i] & 0xc0) != 0x80) ? 1 : 0;
	return count;
}

//
// Debug functions - not to be meant in release version!
//

#if defined DEBUG

void Debug_PrintArray(const Handle:arrayHandle, const bool:isNum) {
	decl value;
	decl String:valueString[255];
	for (new i = 0; i < GetArraySize(arrayHandle); i++) {
		if (isNum) {
			value = GetArrayCell(arrayHandle, i);
			PrintToServer("%d: %d", i, value);
		} else {
			GetArrayString(arrayHandle, i, valueString, sizeof(valueString));
			PrintToServer("%d: %s", i, valueString);
		}
	}
}

#endif