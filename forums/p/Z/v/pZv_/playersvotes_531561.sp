#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2.2"

public Plugin:myinfo =
{
	name = "Players Votes",
	author = "pZv!",
	description = "Votekick, Voteban & Votemap",
	version = PLUGIN_VERSION,
	url = ""
};

#define KICK 0
#define BAN 1
#define MAP 2

new bool:g_bVotedFor[3][MAXPLAYERS+1][MAXPLAYERS+1];

new g_nLastVote[MAXPLAYERS+1];

new Handle:g_hVoteRatio[3] = {INVALID_HANDLE, ...};
new Handle:g_hVoteMinimum[3] = {INVALID_HANDLE, ...};
new Handle:g_hVoteDelay[3] = {INVALID_HANDLE, ...};
new Handle:g_hVoteBanTime = INVALID_HANDLE;
new Handle:g_hVoteImmunity = INVALID_HANDLE;
new Handle:g_hVoteMapsFile = INVALID_HANDLE;
new Handle:g_hVotesInterval = INVALID_HANDLE;

new Handle:g_hMapList = INVALID_HANDLE;
new Handle:g_hLastMaps = INVALID_HANDLE;
new nFileTime;

new Handle:g_hVoteMapLast = INVALID_HANDLE;

new g_nStartTime;

new bool:g_bVoteAction;

public OnPluginStart() {
	LoadTranslations("plugin.playersvotes.txt");

	CreateConVar("sm_playersvotes_version", PLUGIN_VERSION, "Players Votes Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hVoteRatio[KICK] = CreateConVar("sm_votekick_ratio", "0.60", "percent required for successful votekick.", 0, true, 0.0, true, 1.0);
	g_hVoteRatio[BAN] = CreateConVar("sm_voteban_ratio", "0.80", "percent required for successful voteban.", 0, true, 0.0, true, 1.0);
	g_hVoteRatio[MAP] = CreateConVar("sm_votemap_ratio", "0.60", "percent required for successful votemap.", 0, true, 0.0, true, 1.0);

	g_hVoteMinimum[KICK] = CreateConVar("sm_votekick_minimum", "4.0", "minimum votes required for successful votekick. -1 to disable voting", 0, true, -1.0, true, 64.0);
	g_hVoteMinimum[BAN] = CreateConVar("sm_voteban_minimum", "4.0", "minimum votes required for successful voteban. -1 to disable voting", 0, true, -1.0, true, 64.0);
	g_hVoteMinimum[MAP] = CreateConVar("sm_votemap_minimum", "4.0", "minimum votes required for successful votemap. -1 to disable voting", 0, true, -1.0, true, 64.0);

	g_hVoteDelay[KICK] = CreateConVar("sm_votekick_delay", "60.0", "time before votekick is allowed after map start", 0, true, 0.0, true, 1000.0);
	g_hVoteDelay[BAN] = CreateConVar("sm_voteban_delay", "60.0", "time before voteban is allowed after map start", 0, true, 0.0, true, 1000.0);
	g_hVoteDelay[MAP] = CreateConVar("sm_votemap_delay", "60.0", "time before votemap is allowed after map start", 0, true, 0.0, true, 1000.0);

	g_hVoteMapLast = CreateConVar("sm_votemap_lastmaps", "4.0", "last number of played maps that will not show in votemap list", 0, true, 0.0, true, 64.0);
	
	g_hVoteMapsFile = CreateConVar("sm_votemap_mapsfile", "mapcycle.txt", "file containing allowed maps for votemap");
	
	g_hVotesInterval = CreateConVar("sm_playersvotes_interval", "15.0", "interval between another vote cast", 0, true, 0.0, true, 60.0);

	g_hVoteBanTime = CreateConVar("sm_voteban_time", "25.0", "ban time in minutes|0-permanently");

	g_hVoteImmunity = CreateConVar("sm_playersvotes_immunity", "1.0", "admins with equal or higher immunity level will not be affected by votekick and voteban", 0, true, 0.0, true, 99.0);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	RegConsoleCmd("sm_mapshistory", cmdMapsHistory);

	if(!IsValidHandle(g_hMapList)) {
		g_hMapList = CreateArray(33);
	}
	if(!IsValidHandle(g_hLastMaps)) {
		g_hLastMaps = CreateArray(33);
	}

	AutoExecConfig(false);
}

public OnConfigsExecuted() {
	LoadMaps(g_hMapList, nFileTime, g_hVoteMapsFile);

	HookConVarChange(g_hVoteMapLast, RefreshMapsList);
	HookConVarChange(g_hVoteMapsFile, RefreshMapsList);
}

bool:IsLastPlayed(const String:sMap[]) {
	decl String:sMap2[64];
	new nLastNum = GetConVarInt(g_hVoteMapLast);
	new size = GetArraySize(g_hLastMaps)-1;
	new limit = size - nLastNum;
	if(limit < 0) limit = 0;
	for(new i = size; i > limit; i--) {
		GetArrayString(g_hLastMaps, i, sMap2, sizeof(sMap2));
		if(StrEqual(sMap2, sMap, false))
			return true;
	}
	return false;
}

public RefreshMapsList(Handle:convar, const String:oldValue[], const String:newValue[]) {
	LoadMaps(g_hMapList, nFileTime, g_hVoteMapsFile);
}

public OnMapStart() {
	g_nStartTime = GetTime();

	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	PushArrayString(g_hLastMaps, sMap);
	if(GetArraySize(g_hLastMaps) > 64) {
		RemoveFromArray(g_hLastMaps, 0);
	}
}

public Action:cmdMapsHistory(client, args) {
	decl String:sMap[64];
	new size = GetArraySize(g_hLastMaps)-1;
	for(new i = size; i >= 0; i--) {
		GetArrayString(g_hLastMaps, i, sMap, sizeof(sMap));
		PrintToConsole(client, "%d. > %s", i+1, sMap);
	}
	return Plugin_Handled;
}

public OnClientDisconnect(client) {
	g_nLastVote[client] = 0;
	for(new type = 0; type < 2; type++) {
		for(new i = 0; i <= MAXPLAYERS; i++) {
			g_bVotedFor[type][client][i] = false;
			g_bVotedFor[type][i][client] = false;
		}
	}
}

public Action:Command_Say(client, args) {
	if(g_bVoteAction || client == 0) return Plugin_Continue;

	decl String:text[192], String:command[64];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}

	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	GetCmdArg(0, command, sizeof(command));
	if (strcmp(command, "say2", false) == 0)
		startidx += 4;

	new nFromStart = GetTime() - g_nStartTime;
	new nFromLast = GetTime() - g_nLastVote[client];	

	if (strcmp(text[startidx], "votekick", false) == 0) {
		if(nFromLast >= GetConVarInt(g_hVotesInterval)) {
			if(nFromStart >= GetConVarInt(g_hVoteDelay[KICK])) {
				if(GetConVarInt(g_hVoteMinimum[KICK]) > -1) {
					g_nLastVote[client] = GetTime();
					DisplayVoteMenu(client, KICK);
				} else {
					PrintToChat(client, "[%t] %t", "Votekick", "is disabled");
				}
			} else {
				PrintToChat(client, "[%t] %t", "Votekick", "voting not allowed", GetConVarInt(g_hVoteDelay[KICK]) - nFromStart);
			}
		} else {
			PrintToChat(client, "[%t] %t", "Votekick", "voting not allowed again", GetConVarInt(g_hVotesInterval) - nFromLast);
		}
	} else
	if (strcmp(text[startidx], "voteban", false) == 0) {
		if(nFromLast >= GetConVarInt(g_hVotesInterval)) {
			if(nFromStart >= GetConVarInt(g_hVoteDelay[BAN])) {
				if(GetConVarInt(g_hVoteMinimum[BAN]) > -1) {
					g_nLastVote[client] = GetTime();
					DisplayVoteMenu(client, BAN);
				} else {
					PrintToChat(client, "[%t] %t", "Voteban", "is disabled");
				}
			} else {
				PrintToChat(client, "[%t] %t", "Voteban", "voting not allowed", GetConVarInt(g_hVoteDelay[BAN]) - nFromStart);
			}
		} else {
			PrintToChat(client, "[%t] %t", "Voteban", "voting not allowed again", GetConVarInt(g_hVotesInterval) - nFromLast);
		}
	} else
	if (strcmp(text[startidx], "votemap", false) == 0) {
		if(nFromLast >= GetConVarInt(g_hVotesInterval)) {
			if(nFromStart >= GetConVarInt(g_hVoteDelay[MAP])) {
				if(GetConVarInt(g_hVoteMinimum[MAP]) > -1) {
					g_nLastVote[client] = GetTime();
					DisplayVoteMenu(client, MAP);
				} else {
					PrintToChat(client, "[%t] %t", "Votemap", "is disabled");
				}
			} else {
				PrintToChat(client, "[%t] %t", "Votemap", "voting not allowed", GetConVarInt(g_hVoteDelay[MAP]) - nFromStart);
			}
		} else {
			PrintToChat(client, "[%t] %t", "Votemap", "voting not allowed again", GetConVarInt(g_hVotesInterval) - nFromLast);
		}
	}
	return Plugin_Continue;
}

DisplayVoteMenu(client, type) {
	new Handle:hVoteMenu;
	hVoteMenu = CreateMenu(Handler_VoteMenu);
	decl String:sPrefix[1], String:sTitle[32];
	switch(type) {
		case KICK: {
			Format(sTitle, sizeof(sTitle), "%t:", "Votekick");
			SetMenuTitle(hVoteMenu, sTitle);
			sPrefix[0] = 'k';
		}
		case BAN: {
			Format(sTitle, sizeof(sTitle), "%t:", "Voteban");
			SetMenuTitle(hVoteMenu, sTitle);
			sPrefix[0] = 'b';
		}
		case MAP: {
			Format(sTitle, sizeof(sTitle), "%t:", "Votemap");
			SetMenuTitle(hVoteMenu, sTitle);
			sPrefix[0] = 'm';
		}
		default: {
			CloseHandle(hVoteMenu);
			return;
		}
	}
	if(type == MAP) {
		decl String:sMap[65], String:sCurrentMap[65], String:sPos[4];
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
		new num = GetArraySize(g_hMapList);
		new required, votes;
		for(new i = 0; i < num; i++) {
			GetArrayString(g_hMapList, i, sMap, sizeof(sMap));
			Format(sPos, sizeof(sPos), "%s%d", sPrefix, i);
			if(IsMapValid(sMap) && StrEqual(sMap, sCurrentMap) == false && IsLastPlayed(sMap) == false) {
				votes = VotesFor(i, type, required);
				Format(sMap, sizeof(sMap), "%s [%d/%d]", sMap, votes, required);
				AddMenuItem(hVoteMenu, sPos, sMap);
			}
		}
	} else {
		decl String:sName[72], String:sClient[4]; 
		new num = GetMaxClients(), flags;
		new required, votes;
		for(new i = 1; i <= num; i++) {
			if (!IsClientInGame(i)) continue;	
			if(IsFakeClient(i)) continue;

			if(i == client) {
				flags = ITEMDRAW_DISABLED;
			} else {
				flags = ITEMDRAW_DEFAULT;
			}
			Format(sClient, sizeof(sClient), "%s%d", sPrefix, i);
			votes = VotesFor(i, type, required);
			Format(sName, sizeof(sName), "%N [%d/%d]", i, votes, required);
			AddMenuItem(hVoteMenu, sClient, sName, flags);
		}
	}
	SetMenuExitButton(hVoteMenu, true);
	DisplayMenu(hVoteMenu, client, 30);
}

public Handler_VoteMenu(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else
	if (action == MenuAction_Select){
		decl String:sUserId[4];
		new target, type;
		GetMenuItem(menu, param2, sUserId, sizeof(sUserId), _, "", 0);
		if(sUserId[0] == 'k') type = KICK;
		else
		if(sUserId[0] == 'b') type = BAN;
		else
		if(sUserId[0] == 'm') type = MAP;

		target = StringToInt(sUserId[1]);
		if(type == MAP) {
			for(new i = 0; i <= MAXPLAYERS; i++) {
				g_bVotedFor[type][param1][i] = false;
			}
			g_bVotedFor[type][param1][target] = true;
			CheckVotes(param1, target, type);
		} else {
			if(target > 0) {
				if(IsClientInGame(target) && !IsFakeClient(target)) {
					g_bVotedFor[type][param1][target] = true;
					CheckVotes(param1, target, type);
				}
			}
		}
	}
}

CheckVotes(voter, target, type) {
	new VotesRequired;
	new Votes = VotesFor(target, type, VotesRequired);
	decl String:sVoterName[65], String:sTargetName[65];
	GetClientName(voter, sVoterName, sizeof(sVoterName));
	if(type == KICK || type == BAN) {		
		GetClientName(target, sTargetName, sizeof(sTargetName));
	}
	if(type == KICK) {		
		PrintToChatAll("[%t] %t", "Votekick", "voted to kick", sVoterName, sTargetName);
		PrintToChatAll("[%t] %t", "Votekick", "votes required", Votes, VotesRequired);
		if(Votes >= VotesRequired) {
			if(GetConVarInt(g_hVoteImmunity) == 0 || GetAdminImmunityLevel(GetUserAdmin(target)) < GetConVarInt(g_hVoteImmunity)) {
				PrintToChatAll("[%t] %t", "Votekick", "kicked by vote", sTargetName);
				LogAction(-1, target, "Vote kick successful, kicked \"%L\" (reason \"voted by players\")", target);
						
				if(target > 0 && IsClientInGame(target)) {
					new Handle:dp;
					CreateDataTimer(5.0, DelayedVoteAction, dp);
					WritePackCell(dp, type);
					WritePackCell(dp, GetClientUserId(target));
					g_bVoteAction = true;
				}
			}
		}
	} else
	if(type == BAN) {		
		PrintToChatAll("[%t] %t", "Voteban", "voted to ban", sVoterName, sTargetName);
		PrintToChatAll("[%t] %t", "Voteban", "votes required", Votes, VotesRequired);
		if(Votes >= VotesRequired) {
			if(GetConVarInt(g_hVoteImmunity) == 0 || GetAdminImmunityLevel(GetUserAdmin(target)) < GetConVarInt(g_hVoteImmunity)) {
				PrintToChatAll("[%t] %t", "Voteban", "banned by vote", sTargetName);
				LogAction(-1, target, "Vote ban successful, banned \"%L\" (reason \"voted by players\")", target);
	
				decl String:sReason[64];
				Format(sReason, sizeof(sReason), "%t", "banned by users");
				BanClient(target, GetConVarInt(g_hVoteBanTime), BANFLAG_AUTO, "banned by users", sReason);
			}
		}
	} else
	if(type == MAP) {
		decl String:sMap[32];
		GetArrayString(g_hMapList, target, sMap, sizeof(sMap));
		if(IsMapValid(sMap)) {
			PrintToChatAll("[%t] %t", "Votemap", "voted for map", sVoterName, sMap);
			PrintToChatAll("[%t] %t", "Votemap", "votes required", Votes, VotesRequired);
			if(Votes >= VotesRequired) {
				PrintToChatAll("[%t] %t", "Votemap", "map change by vote", sMap);
				LogAction(-1, -1, "Changing map to %s due to players vote.", sMap);
				
				new Handle:dp;
				CreateDataTimer(10.0, DelayedVoteAction, dp);
				WritePackCell(dp, type);
				WritePackString(dp, sMap);
				g_bVoteAction = true;
			}
		}
	}
}

VotesFor(target, type, &required) {
	new votes = 0;
	for(new i = 1; i <= MAXPLAYERS; i++) {
		if(g_bVotedFor[type][i][target]) {
			votes++;
		}		
	}
	new max = GetMaxClients(), players = 0;
	for(new i = 1; i <= max; i++) {
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;
		players++;
	}
	new minVotes = GetConVarInt(g_hVoteMinimum[type]);
	required = RoundToNearest(players * GetConVarFloat(g_hVoteRatio[type]));
	if(required < minVotes) required = minVotes;
	return votes;
}

public Action:DelayedVoteAction(Handle:timer, Handle:dp) {
	decl String:sMap[65];
	new target, type;
	ResetPack(dp);
	type = ReadPackCell(dp);
	switch(type) {
		case KICK: {
			target = ReadPackCell(dp);
			ServerCommand("kickid %d %t", target, "kicked by users");
		}
		case MAP: {
			ReadPackString(dp, sMap, sizeof(sMap));
			ServerCommand("changelevel \"%s\"", sMap);
		}
	}	
	g_bVoteAction = false;
	return Plugin_Stop;
}