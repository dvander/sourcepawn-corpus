#pragma semicolon 1

#define PLUGIN_AUTHOR "Totenfluch"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <regex>

#pragma newdecls required

Regex urlPattern;
RegexError theError;
bool locked[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Smart URL Remover", 
	author = PLUGIN_AUTHOR, 
	description = "Removes all Links from Player Names", 
	version = PLUGIN_VERSION, 
	url = "https://totenfluch.de"
};

public void OnPluginStart() {
	HookEvent("player_spawn", onPlayerSpawn);
	HookEvent("player_changename", onPlayerNameChange, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("SayText2"), SayText2, true);
	
	char error[256];
	urlPattern = CompileRegex("([ ]*[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[:0-9]{0,6})|([ ]*[-a-zA-Z0-9]*(([.])([a-zA-Z]){2,5}))", PCRE_CASELESS, error, sizeof(error), theError);
	if (!StrEqual(error, ""))
		LogError(error);
}

public void OnClientPostAdminCheck(int client) {
	locked[client] = false;
}

public Action onPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char cname[MAX_NAME_LENGTH + 8];
	GetClientName(client, cname, sizeof(cname));
	char match[MAX_NAME_LENGTH + 8];
	bool changed = false;
	MatchRegex(urlPattern, cname, theError);
	if (GetRegexSubString(urlPattern, 0, match, sizeof(match))) {
		if (changed)
			return;
		ReplaceString(cname, sizeof(cname), match, "", false);
		if (StrEqual(cname, ""))
			strcopy(cname, sizeof(cname), "NoName");
		locked[client] = true;
		SetClientName(client, cname);
		changed = true;
	}
}

public Action onPlayerNameChange(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (locked[client])
		return Plugin_Changed;
	char cname[MAX_NAME_LENGTH + 8];
	GetClientName(client, cname, sizeof(cname));
	char match[MAX_NAME_LENGTH + 8];
	MatchRegex(urlPattern, cname, theError);
	if (GetRegexSubString(urlPattern, 0, match, sizeof(match))) {
		if (locked[client])
			return Plugin_Changed;
		ReplaceString(cname, sizeof(cname), match, "", false);
		if (StrEqual(cname, ""))
			strcopy(cname, sizeof(cname), "NoName");
		locked[client] = true;
		SetClientName(client, cname);
		locked[client] = false;
	}
	
	return Plugin_Changed;
}

// BY https://forums.alliedmods.net/member.php?u=67162
public Action SayText2(UserMsg msg_id, Handle bf, int[] players, int playersNum, bool reliable, bool init) {
	if (!reliable)
		return Plugin_Continue;
	
	char buffer[25];
	
	if (GetUserMessageType() == UM_Protobuf) {
		PbReadString(bf, "msg_name", buffer, sizeof(buffer));
		if (StrEqual(buffer, "#Cstrike_Name_Change"))
			return Plugin_Handled;
		
	} else {
		BfReadChar(bf);
		BfReadChar(bf);
		BfReadString(bf, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, "#Cstrike_Name_Change"))
			return Plugin_Handled;
		
	}
	return Plugin_Continue;
} 