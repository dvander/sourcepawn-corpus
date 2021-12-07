#pragma semicolon 1
#include <sourcemod>
#include <tDownloadCache>
#include <tinyxml>
//#include <smlib>
#include <regex>

#define VERSION 		"0.0.3"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new Handle:g_hCvarAnnounce = INVALID_HANDLE;
new Handle:g_hCvarAnnAdminOnly = INVALID_HANDLE;
new Handle:g_hCvarShowHighlander = INVALID_HANDLE;
new Handle:g_hCvarMaxAge = INVALID_HANDLE;

new bool:g_bEnabled;
new bool:g_bAnnounce;
new bool:g_bAnnounceAdminOnly;
new bool:g_bShowHighlander;
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
	g_hCvarShowHighlander = CreateConVar("sm_tetf2ldivision_highlander", "0", "Show the highlander instead of the 6on6 team.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAnnounce = CreateConVar("sm_tetf2ldivision_announce", "1", "Announce players on connect.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAnnAdminOnly = CreateConVar("sm_tetf2ldivision_announce_adminsonly", "0", "Announce players on connect to admins only.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarMaxAge = CreateConVar("sm_tetf2ldivision_maxage", "7", "Update infos about all players every x-th day.", FCVAR_PLUGIN, true, 1.0, true, 31.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);
	HookConVarChange(g_hCvarAnnounce, Cvar_Changed);
	HookConVarChange(g_hCvarAnnAdminOnly, Cvar_Changed);
	HookConVarChange(g_hCvarShowHighlander, Cvar_Changed);
	HookConVarChange(g_hCvarMaxAge, Cvar_Changed);


	// Match season information by regex. Overkill, but eaaase.
	g_hRegExSeason = CompileRegex("Season (\\d\\d)");

	// Create the cache directory if it does not exist
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/etf2lcache/");

	if(!DirExists(sPath)) {
		CreateDirectory(sPath, 493);
	}


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

	// Provide a command for clients
	RegConsoleCmd("sm_div", Command_ShowDivisions);
	RegConsoleCmd("sm_divdetail", Command_ShowPlayerDetail);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_bAnnounce = GetConVarBool(g_hCvarAnnounce);
	g_bAnnounceAdminOnly = GetConVarBool(g_hCvarAnnAdminOnly);
	g_bShowHighlander = GetConVarBool(g_hCvarShowHighlander);
	g_iMaxAge = GetConVarInt(g_hCvarMaxAge) * (24 * 60 * 60);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();

	// Reload data if plugin got enabled or the team-mode got switched
	if((convar == g_hCvarEnabled && g_bEnabled) || convar == g_hCvarShowHighlander) {
		for(new iClient = 1; iClient <= MaxClients; iClient++) {
			if(IsClientInGame(iClient) && !IsFakeClient(iClient)) {
				new String:sAuthId[32];
				GetClientAuthString(iClient, sAuthId, sizeof(sAuthId));
				UpdateClientData(iClient, sAuthId);
			}
		}
	}
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

				//Color_ChatSetSubject(iClient);
				//Client_PrintToChat(client, false, msg);
				PrintToChat(client, msg);
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

				//Color_ChatSetSubject(iClient);
				//Client_PrintToChat(client, false, msg);
				PrintToChat(client, msg);
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

	new String:sFriendId[64];
	AuthIDToFriendID(auth, sFriendId, sizeof(sFriendId));

	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/etf2lcache/%s.xml", sFriendId);

	new String:sWebPath[255] = "/feed/player/?steamid=";
	StrCat(sWebPath, sizeof(sWebPath), auth);

	DC_UpdateFile(sPath, "etf2l.org", 80, sWebPath, g_iMaxAge, OnEtf2lDataReady, iClient);
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
	Format(msg, maxlen, "\x03%N\x01", iClient);

	new bool:bRegistered = false;
	new bool:bActive = false;
	new String:sSteamId[32];
	new String:sDisplayName[255];
	new String:sTeamName[255];
	new String:sDivision[32];
	new String:sEvent[255];

	GetTrieString(g_hPlayerData[iClient], "SteamId", sSteamId, sizeof(sSteamId));
	GetTrieString(g_hPlayerData[iClient], "DisplayName", sDisplayName, sizeof(sDisplayName));
	GetTrieString(g_hPlayerData[iClient], "TeamName", sTeamName, sizeof(sTeamName));
	GetTrieString(g_hPlayerData[iClient], "Division", sDivision, sizeof(sDivision));
	GetTrieString(g_hPlayerData[iClient], "Event", sEvent, sizeof(sEvent));
	GetTrieValue(g_hPlayerData[iClient],  "Registered", bRegistered);
	GetTrieValue(g_hPlayerData[iClient],  "Active", bActive);

	if(bRegistered) {
		//Player is registered
		Format(msg, maxlen, "%s \x01(%s)\x01", msg, sDisplayName);

		if(strlen(sTeamName) > 0) {
			//Player has a 6on6 Team
			Format(msg, maxlen, "%s, \x05%s\x01", msg, sTeamName);

			if(strlen(sDivision) > 0) {
				Format(msg, maxlen, "%s, \x05%s\x01, %s", msg, sEvent, sDivision);
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
	LogToGame("ETF2L: %s", msg);

	for (new i=1; i<=MaxClients;i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			if(g_bAnnounceAdminOnly && GetUserAdmin(i) == INVALID_ADMIN_ID)
				continue;

			//Color_ChatSetSubject(iClient);
			//Client_PrintToChat(i, false, msg);
			PrintToChat(i, msg);
		}
	}
}


public Handle:ReadPlayer(iClient, String:sWrongFile[]) {
	new Handle:hResult = INVALID_HANDLE;

	new String:file[PLATFORM_MAX_PATH];
	Format(file, sizeof(file), "./tf/%s", sWrongFile);

	new Handle:hTxDoc = TinyXml_CreateDocument();
	if(!TinyXml_LoadFile(hTxDoc, file)) {
		LogError("Could not load file: %s", file);
		CloseHandle(hTxDoc);
		return hResult;
	}

	new Handle:hRoot = TinyXml_RootElement(hTxDoc);
	if(hRoot == INVALID_HANDLE) {
		LogError("Document has no root element: %s", file);
		return hResult;
	}

	new Handle:hPlayer = TinyXml_FirstChildElement(hRoot);

	new bool:bRegistered = false;
	new bool:bActive = false;
	new String:sSteamId[32];
	new String:sDisplayName[255];
	new String:sTeamName[255];
	new String:sDivision[32];
	new String:sEvent[255];
	new String:sPlayerId[12];

	if(hPlayer != INVALID_HANDLE) {
		bRegistered = true;

		TinyXml_GetAttribute(hPlayer, "id", sPlayerId, sizeof(sPlayerId));
		TinyXml_GetAttribute(hPlayer, "steamid", sSteamId, sizeof(sSteamId));

		//Find DisplayName
		new Handle:hDisplayName = TinyXml_FirstChildElement(hPlayer, "displayname");
		if(hDisplayName != INVALID_HANDLE) {
			TinyXml_GetText(hDisplayName, sDisplayName, sizeof(sDisplayName));
			CloseHandle(hDisplayName);
		} else {
			LogMessage("Could not find <Displayname> Section");
		}

		//Find Teams Section
		new Handle:hTeams = TinyXml_FirstChildElement(hPlayer, "teams");

		if(hTeams != INVALID_HANDLE) {
			new Handle:hTeam = TinyXml_FirstChildElement(hTeams);

			while(hTeam != INVALID_HANDLE) {
				new String:sTeamType[255];
				TinyXml_GetAttribute(hTeam, "type", sTeamType, sizeof(sTeamType));

				if(StrEqual(sTeamType, g_bShowHighlander ? "Highlander" : "6on6")) {
					TinyXml_GetAttribute(hTeam, "name", sTeamName, sizeof(sTeamName));

					new iLatestComp = 0;
					new String:sTempDivision[16];
					new Handle:hComp = TinyXml_FirstChildElement(hTeam);
					while(hComp != INVALID_HANDLE) {
						new String:sCompId[5];
						TinyXml_GetAttribute(hComp, "id", sCompId, sizeof(sCompId));
						new iCompId = StringToInt(sCompId);

						if(iCompId > iLatestComp) {
							if(TinyXml_GetAttribute(hComp, "division", sTempDivision, sizeof(sTempDivision)) > 0) {
								iLatestComp = iCompId;
								sDivision = sTempDivision;
								bActive = true;
								TinyXml_GetAttribute(hComp, "name", sEvent, sizeof(sEvent));

								if(MatchRegex(g_hRegExSeason, sEvent) > 0) {
									new String:sYear[4];
									GetRegexSubString(g_hRegExSeason, 1, sYear, sizeof(sYear));

									Format(sEvent, sizeof(sEvent), "Season %s", sYear);
								}
							}
						}

						new Handle:hCompNext = TinyXml_NextSiblingElement(hComp);
						CloseHandle(hComp);
						hComp = hCompNext;
					}

					CloseHandle(hTeam);
					break;
				}

				new Handle:hTeamNext = TinyXml_NextSiblingElement(hTeam);
				CloseHandle(hTeam);
				hTeam = hTeamNext;
			}

			CloseHandle(hTeams);
		} else {
			LogMessage("Could not find <Teams> Section");
		}
		CloseHandle(hPlayer);

		hResult = CreateTrie();
		SetTrieString(hResult, "SteamId", sSteamId);
		SetTrieString(hResult, "PlayerId", sPlayerId);
		SetTrieString(hResult, "DisplayName", sDisplayName);
		SetTrieString(hResult, "TeamName", sTeamName);
		SetTrieString(hResult, "Division", sDivision);
		SetTrieString(hResult, "Event", sEvent);
		SetTrieValue(hResult, "Registered", bRegistered);
		SetTrieValue(hResult, "Active", bActive);
	}

	CloseHandle(hRoot);
	CloseHandle(hTxDoc);
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