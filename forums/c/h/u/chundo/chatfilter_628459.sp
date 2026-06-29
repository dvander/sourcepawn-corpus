/*
	Chat text filter
	Written by chundo (chundo@mefightclub.com)

	Licensed under the GPLv3

	This plugin can operate in 3 modes when a filtered keyword is detected:
	1 - Replace the offending text with a admin-specified replacement
	2 - Replace only the matching text with an admin-specified replace
		(or **** if none is specified)
	3 - Block the text completely

	Additionally, you can trigger custom admin actions based on keyword.

	Make sure that chatfilter.cfg is in your sourcemod/configs/ directory. The config
	file is KeyValues format. Each section contains a list of keywords, the action(s) to
	take, and a list of replacement phrases to choose from. You can have multiple
	sections to create amusing replacements for specific keywords.

	Example chatfilter.cfg:
		"kickables" {
			"keyword"		"cunt"
			"action"		"kick"
		}
		"gay-slurs" {
			"keyword"		"fag"
			"keyword"		"homo"
			"replace"		"I quite enjoyed the locker room scenes in Top Gun."
			"replace"		"Show tunes would be lame if they weren't so FABULOUS."
			"name-replace"	"Barbara Streisand"
			"name-replace"	"Larry Craig"
		}
		"insults" {
			"keyword"		"n00b"
			"keyword"		"noob"
			"replace"		"How do I shot gun?"
			"replace"		"Mom says I should lay off the the hot pockets."
		}
	 
	CVars:
		sm_chatfilter_enable 1				// Enable this plugin
		sm_chatfilter_mode 1				// Defaults to "replace" mode
		sm_chatfilter_names 0				// Also filter player names (using name-replace in config)
		sm_chatfilter_limit	3				// Max number of times a player can trigger the filter
		sm_chatfilter_limit_action "gag"	// Action taken when player reaches filter limit
											// Valid actions: any server command ("sm_" can be
											// omitted) that takes a client parameter

	Commands:
		sm_chatfilter_setwordoftheday		// Set the "word of the day"
		sm_chatfilter_deletewordoftheday	// Delete "word of the day"
	 
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define CF_PLUGIN_VERSION "0.4"
#define CF_CONFIG_FILE 200
#define CF_MAX_WORDS 200
#define CF_MAX_REPLACE 50
#define CF_MAX_NAME_REPLACE 50
#define CF_MAX_ACTIONS 50

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Chat Filter",
	author = "chundo",
	description = "Configurable filter for text chat and player names",
	version = CF_PLUGIN_VERSION,
	url = "http://www.mefightclub.com/"
};

new bool:g_cfLoaded;

new Handle:cvarCFEnabled;
new Handle:cvarCFMode;
new Handle:cvarCFAdmins;
new Handle:cvarCFNames;
new Handle:cvarCFLimit;
new Handle:cvarCFLimitAction;
new Handle:cvarCFConsole;

new String:g_cfConfigFile[PLATFORM_MAX_PATH];

new String:g_cfKeywords[CF_MAX_WORDS][32];
new String:g_cfActions[CF_MAX_ACTIONS][32];
new String:g_cfReplace[CF_MAX_REPLACE][191];
new String:g_cfNameReplace[CF_MAX_NAME_REPLACE][50];
new g_cfActionMap[CF_MAX_WORDS][CF_MAX_ACTIONS];
new g_cfReplaceMap[CF_MAX_WORDS][CF_MAX_REPLACE];
new g_cfNameReplaceMap[CF_MAX_WORDS][CF_MAX_NAME_REPLACE];
new g_cfKeywordCt;
new g_cfActionCt;
new g_cfReplaceCt;
new g_cfNameReplaceCt;

new String:g_cfTmpKeywords[CF_MAX_WORDS][32];
new String:g_cfTmpActions[CF_MAX_WORDS][32];
new String:g_cfTmpReplace[CF_MAX_REPLACE][191];
new String:g_cfTmpNameReplace[CF_MAX_REPLACE][50];
new g_cfTmpKeywordIdx;
new g_cfTmpActionIdx;
new g_cfTmpReplaceIdx;
new g_cfTmpNameReplaceIdx;

new g_cfPlayerOffenses[MAXPLAYERS];
new g_cfPlayerInCheck[MAXPLAYERS];

public OnPluginStart() {
	LoadTranslations("chatfilter.phrases");
	g_cfLoaded = false;
	CreateConVar("sm_chatfilter_version", CF_PLUGIN_VERSION, "Chat Filter version.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvarCFEnabled = CreateConVar("sm_chatfilter_enable", "1", "1 is on, 0 is off.", FCVAR_PLUGIN);
	cvarCFMode = CreateConVar("sm_chatfilter_mode", "1", "1 for replace, 2 for censor, 3 for block.", FCVAR_PLUGIN);
	cvarCFAdmins = CreateConVar("sm_chatfilter_admins", "0", "1 to filter, 0 to bypass filter for admins.", FCVAR_PLUGIN);
	cvarCFConsole = CreateConVar("sm_chatfilter_console", "0", "1 to filter, 0 to bypass filter for console.", FCVAR_PLUGIN);
	cvarCFNames = CreateConVar("sm_chatfilter_names", "0", "Filter player names as well as chat.  1 is on, 0 is off.", FCVAR_PLUGIN);
	cvarCFLimit = CreateConVar("sm_chatfilter_limit", "0", "The number of times a player can be chatfiltered before additional action is taken.", FCVAR_PLUGIN);
	cvarCFLimitAction = CreateConVar("sm_chatfilter_limit_action", "gag", "The action to take when a player reaches the chatfilter limit.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_chatfilter_reload", CF_LoadConfigHandler);
	RegConsoleCmd("say", CF_SayHandler);
	RegConsoleCmd("say_team", CF_SayTeamHandler);
	RegAdminCmd("sm_chatfilter_setwordoftheday", CF_SetWordOfTheDay, ADMFLAG_CONVARS, "Set the word of the day and action to take");
	RegAdminCmd("sm_chatfilter_deletewordoftheday", CF_DeleteWordOfTheDay, ADMFLAG_CONVARS, "Set the word of the day and action to take");
	HookConVarChange(cvarCFEnabled, CF_EnableChanged);
	HookConVarChange(cvarCFNames, CF_FilterNamesChanged);
	AutoExecConfig();
}

public OnMapStart() {
	g_cfLoaded = false;
	if (GetConVarBool(cvarCFEnabled)) {
		if (!g_cfLoaded) {
			CF_LoadConfig();
		}
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	if (client < MAXPLAYERS) {
		g_cfPlayerOffenses[client] = 0;
	}
	return true;
}

public OnClientDisconnect(client) {
	if (client < MAXPLAYERS) {
		g_cfPlayerOffenses[client] = 0;
	}
}

public CF_EnableChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "1") == 0) {
			if (!g_cfLoaded)
				CF_LoadConfig();
			PrintToChatAll("\x01[SM] \x04Chatfilter \x01enabled.");
		} else {
			PrintToChatAll("\x01[SM] \x04Chatfilter \x01disabled.");
		}
	}
}

public CF_FilterNamesChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "1") == 0) {
			LogMessage("Enabled name filtering");
			new maxClients = GetMaxClients();
			for (new i = 1; i <= maxClients; ++i)
				if (IsClientConnected(i))
					CheckClientName(i);
		}
	}
}

public Action:CF_LoadConfigHandler(client, args) {
	CF_LoadConfig();
	ReplyToCommand(client, "Chatfilter configuration reloaded");
}

CF_LoadConfig() {
	g_cfKeywordCt = 0;
	g_cfActionCt = 0;
	g_cfReplaceCt = 0;
	g_cfNameReplaceCt = 0;

	BuildPath(Path_SM, g_cfConfigFile, sizeof(g_cfConfigFile), "configs/chatfilter.cfg");

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);
	SMC_ParseFile(parser, g_cfConfigFile);
	CloseHandle(parser);
}

public SMCResult:Config_NewSection(Handle:parser, const String:name[], bool:quotes) {
	g_cfTmpKeywordIdx = 0;
	g_cfTmpActionIdx = 0;
	g_cfTmpReplaceIdx = 0;
	g_cfTmpNameReplaceIdx = 0;
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	if (strcmp(key, "keyword", false) == 0) {
		strcopy(g_cfTmpKeywords[g_cfTmpKeywordIdx++], 32, value);
	} else if (strcmp(key, "action", false) == 0) {
		strcopy(g_cfTmpActions[g_cfTmpActionIdx++], 32, value);
	} else if (strcmp(key, "replace", false) == 0) {
		strcopy(g_cfTmpReplace[g_cfTmpReplaceIdx++], 191, value);
	} else if (strcmp(key, "name-replace", false) == 0) {
		strcopy(g_cfTmpNameReplace[g_cfTmpNameReplaceIdx++], 50, value);
	}
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) {
	new SMCResult:result = SMCParse_Continue;
	new keywordIdx[g_cfTmpKeywordIdx];
	new keywordCt = 0;

	if (g_cfTmpKeywordIdx > 0) {
		for (new i = 0; i < g_cfTmpKeywordIdx; ++i) {
			new existing = CF_ArrayIndex(g_cfKeywords, g_cfTmpKeywords[i], g_cfKeywordCt);
			if (existing == -1) {
				new idx = g_cfKeywordCt++;
				if (idx < CF_MAX_WORDS) {
					g_cfKeywords[idx] = g_cfTmpKeywords[i];
					keywordIdx[i] = idx;
					keywordCt++;
				} else {
					result = SMCParse_Halt;
					LogError("Number of action elements exceeds limit of %d", CF_MAX_WORDS);
					break;
				}
			}
		}
	}
	
	if (g_cfTmpActionIdx > 0) {
		for (new i = 0; i < g_cfTmpActionIdx; ++i) {
			new existing = CF_ArrayIndex(g_cfActions, g_cfTmpActions[i], g_cfActionCt);
			if (existing == -1) {
				new idx = g_cfActionCt++;
				if (idx < CF_MAX_ACTIONS) {
					g_cfActions[idx] = g_cfTmpActions[i];
					for (new j = 0; j < keywordCt; ++j) {
						g_cfActionMap[keywordIdx[j]][i] = idx;
					}
				} else {
					result = SMCParse_Halt;
					LogError("Number of action elements exceeds limit of %d", CF_MAX_ACTIONS);
					break;
				}
			}
		}
	}
	for (new j = 0; j < keywordCt; ++j) {
		if (g_cfTmpActionIdx < CF_MAX_ACTIONS) {
			g_cfActionMap[keywordIdx[j]][g_cfTmpActionIdx] = -1;
		}
	}
	
	if (g_cfTmpReplaceIdx > 0) {
		for (new i = 0; i < g_cfTmpReplaceIdx; ++i) {
			new existing = CF_ArrayIndex(g_cfReplace, g_cfTmpReplace[i], g_cfReplaceCt);
			if (existing == -1) {
				new idx = g_cfReplaceCt++;
				if (idx < CF_MAX_REPLACE) {
					g_cfReplace[idx] = g_cfTmpReplace[i];
					for (new j = 0; j < keywordCt; ++j) {
						g_cfReplaceMap[keywordIdx[j]][i] = idx;
					}
				} else {
					result = SMCParse_Halt;
					LogError("Number of replace elements exceeds limit of %d", CF_MAX_REPLACE);
					break;
				}
			}
		}
	}
	for (new j = 0; j < keywordCt; ++j) {
		if (g_cfTmpReplaceIdx < CF_MAX_REPLACE) {
			g_cfReplaceMap[keywordIdx[j]][g_cfTmpReplaceIdx] = -1;
		}
	}
	
	if (g_cfTmpNameReplaceIdx > 0) {
		for (new i = 0; i < g_cfTmpNameReplaceIdx; ++i) {
			new existing = CF_ArrayIndex(g_cfNameReplace, g_cfTmpNameReplace[i], g_cfNameReplaceCt);
			if (existing == -1) {
				new idx = g_cfNameReplaceCt++;
				if (idx < CF_MAX_NAME_REPLACE) {
					g_cfNameReplace[idx] = g_cfTmpNameReplace[i];
					for (new j = 0; j < keywordCt; ++j) {
						g_cfNameReplaceMap[keywordIdx[j]][i] = idx;
					}
				} else {
					result = SMCParse_Halt;
					LogError("Number of name-replace elements exceeds limit of %d", CF_MAX_NAME_REPLACE);
					break;
				}
			}
		}
	}
	for (new j = 0; j < keywordCt; ++j) {
		if (g_cfTmpNameReplaceIdx < CF_MAX_NAME_REPLACE) {
			g_cfNameReplaceMap[keywordIdx[j]][g_cfTmpNameReplaceIdx] = -1;
		}
	}
	
	return result;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {
	if (halted)
		LogError("Configuration parsing was truncated due to previous errors.");
	if (failed)
		SetFailState("Configuration parsing failed.");
	g_cfLoaded = true;
}

public OnClientPutInServer(client) {
	CheckClientName(client);
}

public OnClientSettingsChanged(client) {
	if (g_cfPlayerInCheck[client] == 0) {
		g_cfPlayerInCheck[client] = 1;
		CreateTimer(1.0, Timer_CheckName, client);
	}
}

public Action:Timer_CheckName(Handle:timer, any:client) {
	CheckClientName(client);
	g_cfPlayerInCheck[client] = 0;
}

CheckClientName(client) {
	if (GetConVarBool(cvarCFEnabled) && GetConVarBool(cvarCFNames)) {
		if (client != 0 && IsClientInGame(client)) {
			decl String:clientName[64];
			GetClientName(client, clientName, sizeof(clientName));
			new String:matchedWord[64];
			new matchOffset = 0;
			new idx = CF_MatchKeyword(clientName, matchedWord, matchOffset, 0);
			if (idx != -1) {
				new String:randomName[64];
				CF_RandomItem(randomName, sizeof(randomName), g_cfNameReplaceMap[idx], g_cfNameReplace, CF_MAX_NAME_REPLACE);
				g_cfPlayerOffenses[client]++;
				new limit = GetConVarInt(cvarCFLimit);
				if (limit > 0 && g_cfPlayerOffenses[client] >= limit) {
					new String:action[32];
					GetConVarString(cvarCFLimitAction, action, sizeof(action));
					CF_DoAction(client, action);
				}

				LogMessage("Name changed to %s on %L", randomName, client);
				SetClientInfo(client, "name", randomName);
			}
		}
	}
}

public Action:CF_SetWordOfTheDay(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_chatfilter_setwordoftheday <phrase> <optional:action> <optional:replacetext>");
		return Plugin_Handled;
	}

	decl String:phrase[65];
	GetCmdArg(1, phrase, sizeof(phrase));
	decl String:action[65] = "";
	if (args > 1) {
		GetCmdArg(2, action, sizeof(action));
	}
	decl String:replace[191] = "";
	if (args > 2) {
		GetCmdArg(3, replace, sizeof(replace));
	}

	return CF_UpdateWordOfTheDay(client, phrase, action, replace);
}

public Action:CF_DeleteWordOfTheDay(client, args) {
	return CF_UpdateWordOfTheDay(client, "", "", "");
}

public Action:CF_UpdateWordOfTheDay(client, const String:phrase[], const String:action[], const String:replace[]) {
	new Handle:kv = CreateKeyValues("chatfilter");
	FileToKeyValues(kv, g_cfConfigFile);

	if (KvJumpToKey(kv, "wordoftheday")) {
		if (strlen(phrase) == 0) {
			KvDeleteKey(kv, "keyword");
		} else {
			KvSetString(kv, "keyword", phrase);
		}
		if (strlen(action) != 0) {
			KvSetString(kv, "action", action);
		}
		if (strlen(replace) != 0) {
			KvSetString(kv, "replace", replace);
		}
	} else {
		ReplyToCommand(client, "[SM] Please add a \"wordoftheday\" section to your chatfilter.cfg first");
	}

	KvRewind(kv);
	KeyValuesToFile(kv, g_cfConfigFile);
	CloseHandle(kv);
	CF_LoadConfig();

	if (strlen(phrase) > 0) {
		ShowActivity(client, "%t", "New word of the day! Find it and get a prize!");
	} else {
		ShowActivity(client, "%t", "Word of the day deleted.");
	}

	return Plugin_Handled;
}

public Action:CF_SayHandler(client, args) {
	return CF_CheckChat(client, args, false);
}

public Action:CF_SayTeamHandler(client, args) {
	return CF_CheckChat(client, args, true);
}

public Action:CF_CheckChat(client, args, bool:teamonly) {
	new bool:enabled = GetConVarBool(cvarCFEnabled);
	if (client != 0) {
		new AdminId:admin = GetUserAdmin(client);
		if (admin != INVALID_ADMIN_ID) {
			//enabled = !GetAdminFlag(admin, Admin_Generic, Access_Effective) || GetConVarBool(cvarCFAdmins);
			enabled = GetConVarBool(cvarCFAdmins);
		}
	} else {
		enabled = GetConVarBool(cvarCFConsole);
	}
	if (enabled) {
		decl String:clientName[64];
		GetClientName(client, clientName, 64);

		decl String:originalstring[191];
		GetCmdArgString(originalstring, sizeof(originalstring));
		
		decl String:speech[191];
		if (originalstring[0] == '"')
			strcopy(speech, strlen(originalstring)-1, originalstring[1]);
		else 
			strcopy(speech, sizeof(originalstring), originalstring);
		
		new String:matchedWord[191];
		new matchOffset = 0;
		new idx = CF_MatchKeyword(speech, matchedWord, matchOffset, 0);
		if (idx != -1) {
			LogMessage("Filtered chat - %s : %s [%d]", clientName, originalstring, g_cfPlayerOffenses[client] + 1);
			new mode = GetConVarInt(cvarCFMode);
			if (mode == 1) {
				new String:randomPhrase[191] = "****";
				CF_RandomItem(randomPhrase, sizeof(randomPhrase), g_cfReplaceMap[idx], g_cfReplace, CF_MAX_REPLACE);
				CF_PrintToChat(client, randomPhrase, teamonly);
				CF_DoKeywordActions(client, idx);
			} else if (mode == 2) {
				new String:chatfilteredPhrase[191];
				strcopy(chatfilteredPhrase, sizeof(chatfilteredPhrase), speech);
				// Need to check for more chatfiltered words now
				while (idx != -1) {
					new String:randomPhrase[191] = "****";
					CF_RandomItem(randomPhrase, sizeof(randomPhrase), g_cfReplaceMap[idx], g_cfReplace, CF_MAX_REPLACE);
					ReplaceString(chatfilteredPhrase, sizeof(chatfilteredPhrase), matchedWord, randomPhrase);
					CF_DoKeywordActions(client, idx);
					idx = CF_MatchKeyword(chatfilteredPhrase, matchedWord, matchOffset, idx);
				}
				CF_PrintToChat(client, chatfilteredPhrase, teamonly);
			} else if (mode == 3) {
				CF_DoKeywordActions(client, idx);
			}
			g_cfPlayerOffenses[client]++;
			new limit = GetConVarInt(cvarCFLimit);
			if (limit > 0 && g_cfPlayerOffenses[client] == limit) {
				new String:action[32];
				GetConVarString(cvarCFLimitAction, action, sizeof(action));
				CF_DoAction(client, action);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

// Private funcs

CF_DoKeywordActions(client, idx) {
	if (client != 0) {
		new String:action[32];
		for (new i = 0; i < CF_MAX_ACTIONS; ++i) {
			if (g_cfActionMap[idx][i] == -1) {
				break;
			}
			strcopy(action, sizeof(action), g_cfActions[g_cfActionMap[idx][i]]);
			CF_DoAction(client, action);
		}
	}
}

CF_DoAction(client, const String:action[]) {
	if (client != 0) {
		new String:command[64];
		new flags = 0;
		new String:description[64];
		new String:sm_action[32] = "sm_";
		StrCat(sm_action, sizeof(sm_action), action);

		new String:clientName[64];
		GetClientName(client, clientName, 64);

		new Handle:citer = GetCommandIterator();
		if (citer != INVALID_HANDLE) {
			while (ReadCommandIterator(citer, command, sizeof(command), flags, description, sizeof(description))) {
				if (strcmp(action, command) == 0) {
					strcopy(sm_action, sizeof(sm_action), action);
					break;
				} else if (strcmp(sm_action, command) == 0) {
					break;
				}
			}
			CloseHandle(citer);
			if (strcmp(sm_action, "sm_kick") == 0 || strcmp(sm_action, "kick") == 0) {
				LogMessage("Kicked %s", clientName);
				KickClient(client, "Inappropriate behavior or username");
			} else if (strcmp(sm_action, "sm_ban") == 0 || strcmp(sm_action, "ban") == 0) {
				LogMessage("Banned %s", clientName);
				BanClient(client, 60, BANFLAG_AUTO, "Innapporiate behavior or username", "Inappropriate behavior or username");
			} else {
				LogMessage("Ran %s on %s", sm_action, clientName);
				ServerCommand("%s #%d", sm_action, GetClientUserId(client));
			}
		} else {
			LogError("Could not find action: %s", sm_action);
		}
	}
}

CF_PrintToChat(client, const String:text[], bool:teamonly) {
	new String:nm[255];
	new String:clientName[64];
	GetClientName(client, clientName, sizeof(clientName));
	new String:label[96];

	if (client == 0) {
		Format(label, sizeof(label), "%s :", clientName);
	} else {
		Format(label, sizeof(label), "\x01%s%s\x03%s \x01:",
			IsClientInGame(client) ? (IsPlayerAlive(client) ? "" : "*DEAD* ") : "*SPEC* ",
			(teamonly ? "(Team) " : ""),
			clientName);
	}

	Format(nm, sizeof(nm), "%s  %s", label, text);
	new maxClients = GetMaxClients();
	for (new j = 1; j <= maxClients; j++) {
		if(IsClientConnected(j)) {
			new bool:sendMessage = true;
			if (client != 0) {
				if (teamonly && GetClientTeam(j) == GetClientTeam(client)) {
					sendMessage = true;
				}
				if (IsClientInGame(client) && IsClientInGame(j) && !IsPlayerAlive(client) && IsPlayerAlive(j)) {
					sendMessage = false;
				}
			}
			if(sendMessage) {
				CF_SayText(j, client, nm);
			}
		}
	}
	PrintToServer(nm);
}

CF_SayText(target, client, const String:message[]) {
	decl Handle:buffer;
	if (target == 0) {
		buffer = StartMessageAll("SayText2");
	} else {
		buffer = StartMessageOne("SayText2", target);
	}
	if (buffer != INVALID_HANDLE) {
		BfWriteByte(buffer, client);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
} 

CF_ArrayIndex(const String:ary[][], String:value[], max) {
	for (new i = 0; i < max; ++i) {
		if (strcmp(String:ary[i], value) == 0) {
			return i;
		}
	}
	return -1;
}

CF_MatchKeyword(const String:value[], String:match[], &offset, keywordidx) {
	for (new i = keywordidx; i < g_cfKeywordCt; ++i) {
		if ((offset = StrContains(value, g_cfKeywords[i], false)) != -1 ) {
			strcopy(match, strlen(g_cfKeywords[i])+1, value[offset]);
			match[offset+strlen(g_cfKeywords[i])+1] = '\0';
			return i;
		}
	}
	return -1;
}

bool:CF_RandomItem(String:phrase[], plen, const map[], const String:lookup[][], maxlength) {
	new max = 0;
	for (new j = max; j < maxlength; ++j) {
		if (map[j] == -1) {
			max = j - 1;
			break;
		}
	}
	if (max > -1) {
		new rnd = GetRandomInt(0, max);
		strcopy(phrase, plen, lookup[map[rnd]]);
		return true;
	}
	return false;
}
