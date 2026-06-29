/****************************************************************************************************
[ANY] Name Sleuth
*****************************************************************************************************/
/* 	
	Description:
				NameSleuth is an extremely accurate and powerful plugin which bans people who use name stealer / faker cheats.
				It works by verifying the clients name with steam servers and then using a convar query to determine if the client is using a hack.
				
				It is fully compatible with sm_rename and no false positives are triggered because sourcemod does not modify the client name variable.
				
				As clients names are set from Steam and then synced to the game, it is impossible for the client to change the "name" variable client side
				without using a cheat or modification to the games files.
				
				It also checks if a cheat falsely responds to a ConVar Query and bans for that.
				
				This is a sufficient replacement to plugins such as Name Change Punisher because it accurately determines a real hacker vs somebody changing names too many times on steam, 
				but it is only currently compatible with games that support SteamWorks.
			
				Additionally, It has been tested with a cheat to confirm that everything works as it should.
				
	Requirements:
				SteamWorks: https://forums.alliedmods.net/showthread.php?t=229556
	
	ChangeLog:
				0.1	- First public release.
				0.2	- 
					- Properly done web request now.
					- Removed Janson and using VDF / KeyValues now.
					- General code cleanup.
					- Woops, protected the API Key cvar!
				0.3 - 
					- Revived plugin.
				0.4 - 
					- Fixed cache causing false bans (Thanks Techno, Kinsi, DeathKnife for help over Discord).
				0.5 - 
					- Regex the player profile as we can't rely on the fucking Steam API.
					- Ban if the ConVar Query lies about the player name variable.
				0.6 - 
					- Fix special HTML characters causing false detection (Thanks GamerX for reporting the bug)
					- Remove checking GetClientInfo against ConVar query as it triggers a false when sm_rename is used.
					- Added OnClientSettingsChanged forward so we can still check even if the server limits the name changes.
				
				0.7 - 
					- Fix false positive by using a better Regex string because Sourcemod Regex does not support global modifier.
*/

#include <autoexecconfig>
#include <SteamWorks>
#include <regex>

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>

/****************************************************************************************************
DEFINES
*****************************************************************************************************/
#define PLUGIN_NAME "[ANY] Name Sleuth"
#define PLUGIN_URL "https://www.fragdeluxe.com"
#define PLUGIN_DESC "Anti name faking done right"
#define PLUGIN_VERSION "0.7"
#define PLUGIN_AUTHOR "SM9(); (xCoderx)"

#define LoopConnectedClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1, false))

/****************************************************************************************************
ETIQUETTE.
*****************************************************************************************************/
#pragma dynamic 131072
#pragma newdecls required
#pragma semicolon 1

/****************************************************************************************************
BOOLS.
*****************************************************************************************************/
bool g_bClientBanned[MAXPLAYERS + 1] = false;
bool g_bSourceBans = false;
bool g_bCheckingName[MAXPLAYERS + 1];

/****************************************************************************************************
INTS.
*****************************************************************************************************/
int g_iFailures[MAXPLAYERS + 1];

/****************************************************************************************************
STRINGS.
*****************************************************************************************************/
char g_szSteamId64[MAXPLAYERS + 1][64];
char g_szLog[PLATFORM_MAX_PATH];

/****************************************************************************************************
CONVARS.
*****************************************************************************************************/

public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESC, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	if (!HookEventEx("player_changename", Event_PlayerNameChange)) {
		SetFailState("Unable to hook player_changename event");
	}
	
	CreateConVar("namesleuth_ver", PLUGIN_VERSION, "NameSleuth Version");
	
	LoopConnectedClients(iClient) {
		if (GetClientAuthId(iClient, AuthId_SteamID64, g_szSteamId64[iClient], sizeof(g_szSteamId64))) {
			RequestNameFromSteam(iClient, g_szSteamId64[iClient]);
		}
	}
	
	BuildPath(Path_SM, g_szLog, sizeof(g_szLog), "logs/NameSleuth.log");
	
	if (LibraryExists("sourcebans")) {
		g_bSourceBans = GetFeatureStatus(FeatureType_Native, "SourceBans_BanPlayer") == FeatureStatus_Available;
	}
}

public APLRes AskPluginLoad2(Handle hNyself, bool bLate, char[] chError, int iErrMax)
{
	RegPluginLibrary("NameSleuth");
	MarkNativeAsOptional("SourceBans_BanPlayer");
	
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] szName) {
	if (StrEqual(szName, "sourcebans")) {
		g_bSourceBans = GetFeatureStatus(FeatureType_Native, "SourceBans_BanPlayer") == FeatureStatus_Available;
	}
}

public void OnLibraryRemoved(const char[] szName) {
	if (StrEqual(szName, "sourcebans")) {
		g_bSourceBans = false;
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if (IsFakeClient(iClient)) {
		return;
	}
	
	if (!GetClientAuthId(iClient, AuthId_SteamID64, g_szSteamId64[iClient], sizeof(g_szSteamId64))) {
		KickClient(iClient, "Unable to retrieve AuthId\nPlease rejoin or restart your game if this persists");
		return;
	}
	
	RequestFrame(Frame_NameChanged, GetClientUserId(iClient));
}

public Action Event_PlayerNameChange(Event eEvent, const char[] szName, bool bDontBroadcast) {
	RequestFrame(Frame_NameChanged, eEvent.GetInt("userid"));
}

public void OnClientSettingsChanged(int iClient) {
	RequestFrame(Frame_NameChanged, GetClientUserId(iClient));
}

public void Frame_NameChanged(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient, false)) {
		return;
	}
	
	RequestNameFromSteam(iClient, g_szSteamId64[iClient]);
}

public void RequestNameFromSteam(int iClient, const char[] szSteam64)
{
	if (g_bClientBanned[iClient] || g_bCheckingName[iClient]) {
		return;
	}
	
	int iTime = GetTime(); char szTime[20]; IntToString(iTime, szTime, sizeof(szTime));
	char szApiUrl[128]; Format(szApiUrl, sizeof(szApiUrl), "https://steamcommunity.com/profiles/%s/?t=%d", g_szSteamId64[iClient], iTime);
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, szApiUrl);
	
	if (hRequest == null) {
		return;
	}
	
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Pragma", "no-cache");
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Cache-Control", "no-cache");
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "t", szTime);
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	SteamWorks_SetHTTPCallbacks(hRequest, HTTP_RequestComplete);
	SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(iClient));
	SteamWorks_SendHTTPRequest(hRequest);
	
	g_bCheckingName[iClient] = true;
}

public int HTTP_RequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	bool bSuccess = true;
	
	if (!IsValidClient(iClient, false)) {
		delete hRequest;
		return;
	}
	
	int iBodySize;
	
	if (SteamWorks_GetHTTPResponseBodySize(hRequest, iBodySize)) {
		if (iBodySize <= 0) {
			bSuccess = false;
		}
	} else {
		bSuccess = false;
	}
	
	Regex rRegex = CompileRegex("<title>Steam Community :: ([^<]+)");
	int iMatches = 0;
	
	if (bSuccess) {
		char[] szBody = new char[iBodySize + 1]; 
		
		if(SteamWorks_GetHTTPResponseBodyData(hRequest, szBody, iBodySize)) {
			iMatches = rRegex.Match(szBody);
			
			if(iMatches <= 0) {
				bSuccess = false;
			}
		} else {
			bSuccess = false;
		}
	}
	
	if (!bSuccess) {
		if (++g_iFailures[iClient] == 5) {
			LogError("Failed to sucessfully check player %N's name with the steam backend after 5 attempts", iClient);
			g_iFailures[iClient] = 0;
			g_bCheckingName[iClient] = false;
		} else {
			g_bCheckingName[iClient] = false;
			RequestNameFromSteam(iClient, g_szSteamId64[iClient]);
		}
		
		delete rRegex;
	} else {
		
		DataPack dPack = CreateDataPack();
		dPack.WriteCell(iUserId);
		dPack.WriteCell(iMatches);
		dPack.WriteCell(view_as<int>(rRegex));
		dPack.Reset();
		
		QueryClientConVar(iClient, "name", Query_NameCheck, dPack);
		g_iFailures[iClient] = 0;
	}
	
	delete hRequest;
}

public void Query_NameCheck(QueryCookie qCookie, int iClient, ConVarQueryResult cqResult, const char[] szCvarName, const char[] szCvarValue, DataPack dPack)
{
	int iUserId = dPack.ReadCell();
	int iMatches = dPack.ReadCell();
	Regex rRegex = view_as<Regex>(dPack.ReadCell());
	delete dPack;
	
	if(GetClientOfUserId(iUserId) != iClient) {
		delete rRegex;
		return;
	}
	
	if (cqResult != ConVarQuery_Okay) {
		KickClient(iClient, "ConVar Query timeout\nplease try rejoining or restarting your game if this persists");
		delete rRegex;
		return;
	}
	
	char szGameName[384];
	
	if (!GetClientName(iClient, szGameName, sizeof(szGameName))) {
		KickClient(iClient, "Unable to retrieve Name\nPlease rejoin or restart your game if this persists");
		delete rRegex;
		return;
	}
	
	char szCvarValueFixed[384]; strcopy(szCvarValueFixed, sizeof(szCvarValueFixed), szCvarValue); FixHTML(szCvarValueFixed, sizeof(szCvarValueFixed));
	
	if (!StrEqual(szCvarValue, szGameName, false)) {
		g_bCheckingName[iClient] = false;
		delete rRegex;
		return;
	}
	
	char szSteamName[384]; bool bFound = false;
	
	for (int i = 0; i < iMatches; i++) {
		rRegex.GetSubString(1, szSteamName, sizeof(szSteamName)); 
		FixHTML(szSteamName, sizeof(szSteamName));
		
		if (!StrEqual(szCvarValueFixed, szSteamName, true)) {
			continue;
		}
		
		bFound = true;
		break;
	}
	
	if (!bFound) {
		LogToFileEx(g_szLog, "\n[Name Faker]: \nSteam Name: %s\nConsole Name: %s\n", szSteamName, szCvarValueFixed);
		NS_BanClient(iClient);
	}
	
	g_bCheckingName[iClient] = false;
	
	delete rRegex;
}

public void NS_BanClient(int iClient)
{
	g_bClientBanned[iClient] = true;
	
	if (g_bSourceBans) {
		SourceBans_BanPlayer(0, iClient, 0, "Cheating Violation");
	} else {
		char szResult[64]; ServerCommandEx(szResult, sizeof(szResult), "sm_ban #%d 0 \"[NameSleuth] Name stealer/faker detected\"", GetClientUserId(iClient));
		
		if (StrContains(szResult, "Unknown") != -1) {
			if (!BanClient(iClient, 0, BANFLAG_AUTO, "[NameSleuth] Name stealer/faker detected", "Cheating Violation")) {
				char szAuthId[64];
				
				if (GetClientAuthId(iClient, AuthId_Engine, szAuthId, sizeof(szAuthId))) {
					ServerCommand("banid \"0\" \"%s\"; writeid", szAuthId);
				}
				
				if (IsClientConnected(iClient)) {
					KickClient(iClient, "Cheating Violation");
				}
				
				LogToFileEx(g_szLog, "Ban for %N (%s) might of failed, please check manually.", iClient, szAuthId);
			}
		}
	}
}

stock int FixHTML(char[] szName, int iSize)
{
	int iReplacements = 0;
	
	iReplacements += ReplaceString(szName, iSize, "&nbsp;", " ");
	iReplacements += ReplaceString(szName, iSize, "&lt;", "<");
	iReplacements += ReplaceString(szName, iSize, "&gt;", ">");
	iReplacements += ReplaceString(szName, iSize, "&gt;", ">");
	iReplacements += ReplaceString(szName, iSize, "&amp;", "&");
	iReplacements += ReplaceString(szName, iSize, "&quot;", "\"");
	iReplacements += ReplaceString(szName, iSize, "&apos;", "'");
	iReplacements += ReplaceString(szName, iSize, "&cent;", "¢");
	iReplacements += ReplaceString(szName, iSize, "&pound;", "£");
	iReplacements += ReplaceString(szName, iSize, "&yen;", "¥");
	iReplacements += ReplaceString(szName, iSize, "&euro;", "€");
	iReplacements += ReplaceString(szName, iSize, "&copy;", "©");
	iReplacements += ReplaceString(szName, iSize, "&reg;", "®");
	
	return iReplacements;
}

public void OnClientDisconnect(int iClient) 
{
	g_bClientBanned[iClient] = false;
	g_iFailures[iClient] = 0;
	g_bCheckingName[iClient] = false;
}

stock int IsValidClient(int iClient, bool bCheckInGame)
{
	if (iClient <= 0 || iClient > MaxClients) {
		return false;
	}
	
	if (!IsClientConnected(iClient)) {
		return false;
	}
	
	if (IsFakeClient(iClient)) {
		return false;
	}
	
	if (bCheckInGame) {
		return IsClientInGame(iClient);
	}
	
	return true;
} 