#pragma semicolon 1
#include <sourcemod>
#include <tDownloadCache>
#include <smlib>
#include <regex>

#define VERSION 		"0.1.2"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new Handle:g_hCvarAnnounce = INVALID_HANDLE;
new Handle:g_hCvarAnnAdminOnly = INVALID_HANDLE;
new Handle:g_hCvarTeamType = INVALID_HANDLE;
new Handle:g_hCvarMaxAge = INVALID_HANDLE;
new Handle:g_hCvarSeasonsOnly = INVALID_HANDLE;

new bool:g_bEnabled;
new bool:g_bAnnounce;
new bool:g_bSeasonsOnly;
new bool:g_bAnnounceAdminOnly;
new String:g_sTeamType[64];

new g_iMaxAge = 7 * (24 * 60 * 60);

new Handle:g_hRegExSeason;

new Handle:g_hPlayerData[MAXPLAYERS+1];

public Plugin:myinfo = {
	name 		= "tETF2LDivision",
	author 		= "Thrawn",
	description = "Shows a players ETF2L team and division.",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tetf2ldivision_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Create some convars
	g_hCvarEnabled = CreateConVar("sm_tetf2ldivision_enable", "1", "Enable tETF2LDivision.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarTeamType = CreateConVar("sm_tetf2ldivision_teamtype", "6on6", "The team type to show (6on6, Highlander, 2on2...).", FCVAR_PLUGIN);
	g_hCvarAnnounce = CreateConVar("sm_tetf2ldivision_announce", "1", "Announce players on connect.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarSeasonsOnly = CreateConVar("sm_tetf2ldivision_seasonsonly", "1", "Ignore placements in fun cups etc.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAnnAdminOnly = CreateConVar("sm_tetf2ldivision_announce_adminsonly", "0", "Announce players on connect to admins only.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarMaxAge = CreateConVar("sm_tetf2ldivision_maxage", "7", "Update infos about all players every x-th day.", FCVAR_PLUGIN, true, 1.0, true, 31.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);
	HookConVarChange(g_hCvarAnnounce, Cvar_Changed);
	HookConVarChange(g_hCvarAnnAdminOnly, Cvar_Changed);
	HookConVarChange(g_hCvarSeasonsOnly, Cvar_Changed);
	HookConVarChange(g_hCvarTeamType, Cvar_Changed);
	HookConVarChange(g_hCvarMaxAge, Cvar_Changed);


	// Match season information by regex. Overkill, but eaaase.
	g_hRegExSeason = CompileRegex("Season (\\d\\d)");

	// Create the cache directory if it does not exist
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/etf2lcache/");

	if(!DirExists(sPath)) {
		CreateDirectory(sPath, 493);
	}

	// Provide a command for clients
	RegConsoleCmd("sm_div", Command_ShowDivisions);
	RegConsoleCmd("sm_divdetail", Command_ShowPlayerDetail);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_bAnnounce = GetConVarBool(g_hCvarAnnounce);
	g_bAnnounceAdminOnly = GetConVarBool(g_hCvarAnnAdminOnly);
	g_bSeasonsOnly = GetConVarBool(g_hCvarSeasonsOnly);
	GetConVarString(g_hCvarTeamType, g_sTeamType, sizeof(g_sTeamType));
	g_iMaxAge = GetConVarInt(g_hCvarMaxAge) * (24 * 60 * 60);

	// Account for late loading
	// - This triggers announcements. But that shouldn't be a big deal,
	//   so we don't handle it and overcomplicate things by doing so.
	for(new iClient = 1; iClient <= MaxClients; iClient++) {
		if(IsClientInGame(iClient) && !IsFakeClient(iClient)) {
			new String:sAuthId[32];
			GetClientAuthString(iClient, sAuthId, sizeof(sAuthId));
			UpdateClientData(iClient, sAuthId);
		}
	}
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public Action:Command_ShowPlayerDetail(client, args) {
	if(!g_bEnabled) {
		ReplyToCommand(client, "tDivisions is disabled.");
		return Plugin_Handled;
	}

	if(args == 0 || args > 1) {
		ReplyToCommand(client, "No target specified. Usage: sm_divdetail <playername>");
		return Plugin_Handled;
	}

	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

	// Process the targets
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl TargetList[MAXPLAYERS], TargetCount;
	decl bool:TargetTranslate;

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI,
										   strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) {
		return Plugin_Handled;
	}

	// Apply to all targets (this can only be one, but anyway...)
	for (new i = 0; i < TargetCount; i++) {
		new iClient = TargetList[i];

		new String:sPlayerId[12];
		GetTrieString(g_hPlayerData[iClient], "PlayerId", sPlayerId, sizeof(sPlayerId));

		if(strlen(sPlayerId) <= 0) {
			ReplyToCommand(client, "Sorry. The ETF2L user-id is unknown for '%s'", strTarget);
			return Plugin_Handled;
		}

		new String:sURL[128];
		Format(sURL, sizeof(sURL), "http://etf2l.org/forum/user/%s/", sPlayerId);

		ShowMOTDPanel(client, "ETF2L Profile", sURL, MOTDPANEL_TYPE_URL);
	}

	return Plugin_Handled;


}

public Action:Command_ShowDivisions(client, args) {
	if(!g_bEnabled) {
		ReplyToCommand(client, "tDivisions is disabled.");
		return Plugin_Handled;
	}

	if(args == 0) {
		for (new iClient=1; iClient<=MaxClients;iClient++) {
			if (IsClientInGame(iClient) && !IsFakeClient(iClient) && g_hPlayerData[iClient] != INVALID_HANDLE) {
				new String:msg[253];
				GetAnnounceString(iClient, msg, sizeof(msg));

				Color_ChatSetSubject(iClient);
				Client_PrintToChat(client, false, msg);
			}
		}
	}

	if(args == 1) {
		decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

		// Process the targets
		decl String:strTargetName[MAX_TARGET_LENGTH];
		decl TargetList[MAXPLAYERS], TargetCount;
		decl bool:TargetTranslate;

		if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
											   strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
		{
			return Plugin_Handled;
		}

		// Apply to all targets
		for (new i = 0; i < TargetCount; i++) {
			new iClient = TargetList[i];
			if (IsClientInGame(iClient) && !IsFakeClient(iClient) && g_hPlayerData[iClient] != INVALID_HANDLE) {
				new String:msg[253];
				GetAnnounceString(iClient, msg, sizeof(msg));

				Color_ChatSetSubject(iClient);
				Client_PrintToChat(client, false, msg);
			}
		}
	}

	return Plugin_Handled;
}


public OnClientAuthorized(iClient, const String:auth[]) {
	if(g_bEnabled) {
		UpdateClientData(iClient, auth);
	}
}

public OnClientDisconnect(iClient) {
	if(g_hPlayerData[iClient] != INVALID_HANDLE) {
		CloseHandle(g_hPlayerData[iClient]);
		g_hPlayerData[iClient] = INVALID_HANDLE;
	}
}

public UpdateClientData(iClient, const String:auth[]) {
	if(IsFakeClient(iClient))return;

	// This is probably not necessery anymore, just use the id directly?
	new String:sFriendId[64];
	AuthIDToFriendID(auth, sFriendId, sizeof(sFriendId));

	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/etf2lcache/%s.vdf", sFriendId);

	new String:sWebPath[255];
	Format(sWebPath, sizeof(sWebPath), "/player/%s/full.vdf", auth);

	DC_UpdateFile(sPath, "api.etf2l.org", 80, sWebPath, g_iMaxAge, OnEtf2lDataReady, iClient);
}

public OnEtf2lDataReady(bool:bSuccess, Handle:hSocketData, any:iClient) {
	if(!bSuccess)return;

	new String:sPath[PLATFORM_MAX_PATH];
	GetTrieString(hSocketData, "path", sPath, sizeof(sPath));

	if(g_hPlayerData[iClient] != INVALID_HANDLE) {
		CloseHandle(g_hPlayerData[iClient]);
		g_hPlayerData[iClient] = INVALID_HANDLE;
	}

	g_hPlayerData[iClient] = ReadPlayer(iClient, sPath);

	if(g_bAnnounce && g_hPlayerData[iClient] != INVALID_HANDLE) {
		AnnouncePlayerToAll(iClient);
	}
}


public GetAnnounceString(iClient, String:msg[], maxlen) {
	Format(msg, maxlen, "{T}%N{N}", iClient);

	if(g_hPlayerData[iClient] != INVALID_HANDLE) {
		new String:sSteamId[32];
		new String:sDisplayName[255];
		new String:sTeamName[255];
		new String:sDivision[32];
		new String:sEvent[255];

		GetTrieString(g_hPlayerData[iClient], "SteamId", sSteamId, sizeof(sSteamId));
		GetTrieString(g_hPlayerData[iClient], "DisplayName", sDisplayName, sizeof(sDisplayName));

		new String:sResultKey[255];
		Format(sResultKey, sizeof(sResultKey), "team_%s", g_sTeamType);

		new Handle:hTeamData = INVALID_HANDLE;
		if(GetTrieValue(g_hPlayerData[iClient], sResultKey, hTeamData) && hTeamData != INVALID_HANDLE) {
			GetTrieString(hTeamData, "TeamName", sTeamName, sizeof(sTeamName));
			GetTrieString(hTeamData, "Division", sDivision, sizeof(sDivision));
			GetTrieString(hTeamData, "Event", sEvent, sizeof(sEvent));
		}

		//Player is registered
		Format(msg, maxlen, "%s {N}(%s){N}", msg, sDisplayName);

		if(strlen(sTeamName) > 0) {
			//Player has a 6on6 Team
			Format(msg, maxlen, "%s, {OG}%s{N}", msg, sTeamName);

			if(strlen(sDivision) > 0) {
				Format(msg, maxlen, "%s, {OG}%s{N}, %s", msg, sEvent, sDivision);
			} else {
				StrCat(msg, maxlen, ", inactive");
			}

		} else {
			StrCat(msg, maxlen, ", no team");
		}
	} else {
		StrCat(msg, maxlen, ", unregistered");
	}

	return;
}

public AnnouncePlayerToAll(iClient) {
	new String:msg[253];
	GetAnnounceString(iClient, msg, sizeof(msg));

	for (new i=1; i<=MaxClients;i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			if(g_bAnnounceAdminOnly && GetUserAdmin(i) == INVALID_ADMIN_ID)
				continue;

			Color_ChatSetSubject(iClient);
			Client_PrintToChat(i, false, msg);
		}
	}
}

public Handle:ReadPlayer(iClient, String:sPath[]) {
	new Handle:hKV = CreateKeyValues("response");
	FileToKeyValues(hKV, sPath);

	if(hKV == INVALID_HANDLE) {
		LogError("Could not parse keyvalues file '%s' for %N", sPath, iClient);
		return INVALID_HANDLE;
	}

	if(!KvJumpToKey(hKV, "player")) {
		LogError("No player entry found for %N (%s)", iClient, sPath);
		CloseHandle(hKV);
		return INVALID_HANDLE;
	}

	new iETF2LId = KvGetNum(hKV, "id", -1);
	if(iETF2LId == -1) {
		CloseHandle(hKV);
		return INVALID_HANDLE;
	}

	// Start collecting data and save it in a trie
	new Handle:hResult = CreateTrie();
	SetTrieValue(hResult, "PlayerId", iETF2LId);

	// Grab Player Details
	new String:sDisplayName[255];
	KvGetString(hKV, "name", sDisplayName, sizeof(sDisplayName), "");
	SetTrieString(hResult, "DisplayName", sDisplayName);

	new String:sSteamId[32];
	if(KvJumpToKey(hKV, "steam")) {
		KvGetString(hKV, "id", sSteamId, sizeof(sSteamId), "");
		KvGoBack(hKV);
	}
	SetTrieString(hResult, "SteamId", sSteamId);


	// Loop over all teams
	if(KvJumpToKey(hKV, "teams")) {
		if(KvGotoFirstSubKey(hKV, false)) {
			do {
				new String:sTeamType[32];
				KvGetString(hKV, "type", sTeamType, sizeof(sTeamType), "");

				new String:sTeamName[255];
				KvGetString(hKV, "name", sTeamName, sizeof(sTeamName), "");

				new String:sEvent[255];
				new String:sDivision[255];
				if(KvJumpToKey(hKV, "competitions")) {
					// Find the competition with the highest Id
					if(KvGotoFirstSubKey(hKV, false)) {
						new iHighestCompetitionId = -1;
						do {
							new String:sCompetitionId[8];
							KvGetSectionName(hKV, sCompetitionId, sizeof(sCompetitionId));

							// Filter by category if only season should be shown
							new String:sCategory[64];
							KvGetString(hKV, "category", sCategory, sizeof(sCategory), "");
							if(g_bSeasonsOnly && StrContains(sCategory, "Season", false) == -1) {
								continue;
							}

							new iCompetitionId = StringToInt(sCompetitionId);
							if(iCompetitionId > iHighestCompetitionId) {
								iHighestCompetitionId = iCompetitionId;

								KvGetString(hKV, "competition", sEvent, sizeof(sEvent));

								if(KvJumpToKey(hKV, "division")) {
									KvGetString(hKV, "name", sDivision, sizeof(sDivision));

									KvGoBack(hKV);
								}
							}
						} while(KvGotoNextKey(hKV, false));

						KvGoBack(hKV);
					}

					KvGoBack(hKV);
				}

				// Post-Processing: Strip the event name
				if(MatchRegex(g_hRegExSeason, sEvent) > 0) {
					new String:sYear[4];
					GetRegexSubString(g_hRegExSeason, 1, sYear, sizeof(sYear));

					Format(sEvent, sizeof(sEvent), "Season %s", sYear);
				}

				// Store in trie and append to result trie
				new Handle:hTeamData = CreateTrie();
				SetTrieString(hTeamData, "TeamName", sTeamName);
				SetTrieString(hTeamData, "Division", sDivision);
				SetTrieString(hTeamData, "Event", sEvent);

				new String:sResultKey[255];
				Format(sResultKey, sizeof(sResultKey), "team_%s", sTeamType);

				SetTrieValue(hResult, sResultKey, hTeamData);

			} while(KvGotoNextKey(hKV, false));

			KvGoBack(hKV);
		}

		KvGoBack(hKV);
	}

	CloseHandle(hKV);

	return hResult;
}

AuthIDToFriendID(const String:AuthID[], String:FriendID[], size) {
	decl String:sAuthId[32];
	strcopy(sAuthId, sizeof(sAuthId), AuthID);

	ReplaceString(sAuthId, strlen(sAuthId), "STEAM_", "");

	if (StrEqual(sAuthId, "ID_LAN")) {
		FriendID[0] = '\0';

		return;
	}

	decl String:toks[3][16];

	ExplodeString(sAuthId, ":", toks, sizeof(toks), sizeof(toks[]));

	//new unknown = StringToInt(toks[0]);
	new iServer = StringToInt(toks[1]);
	new iAuthID = StringToInt(toks[2]);

	new iFriendID = (iAuthID*2) + 60265728 + iServer;

	Format(FriendID, size, "765611979%d", iFriendID);
}