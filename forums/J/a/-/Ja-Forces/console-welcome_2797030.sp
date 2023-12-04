#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.1.3"
#define CVAR_FLAGS	FCVAR_NOTIFY

#define LANG_LEN 30
#define FILE_LINE_LEN 300

public Plugin myinfo = 
{
	name = "Console Welcome Message",
	author = "exvel",
	description = "Prints welcome message into the client's console on join",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=122498"
}

ConVar cvar_PluginEnabled = null;
ConVar cvar_IgnoreMapChanges = null;

Handle g_hAdtWelcomeMsgPacks = null;
Handle g_hAdtWelcomeMsgLangs = null;

bool g_bPlayed[MAXPLAYERS+1] = { false, ... };

public void OnPluginStart()
{
	CreateConVar("sm_console_welcome_version", PLUGIN_VERSION, "Console Welcome Message Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_PluginEnabled = CreateConVar("sm_console_welcome", "1", "Console Welcome Message, 0 = off/1 = on", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_IgnoreMapChanges = CreateConVar("sm_console_welcome_ingnore_mapchanges", "1", "Don't print welcome message to client after map change", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	g_hAdtWelcomeMsgPacks = CreateArray();
	g_hAdtWelcomeMsgLangs = CreateArray(LANG_LEN);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	LoadTranslations("common.phrases");
	
	AutoExecConfig(true, "console_welcome");
}

public void OnConfigsExecuted()
{
	if (!cvar_PluginEnabled.BoolValue)
		return;
	
	ClearHandles();
	LoadWelcomeMessages();
}

public void OnClientPostAdminCheck(int client)
{
	if (!cvar_PluginEnabled.BoolValue || IsFakeClient(client))
		return;
	
	if (g_bPlayed[client] && cvar_IgnoreMapChanges.BoolValue)
		return;
	
	g_bPlayed[client] = true;
	
	char szLangName[LANG_LEN];
	GetLanguageInfo(GetClientLanguage(client), _, _, szLangName, sizeof(szLangName));
	StringToLower(szLangName);
	
	int index = -1;
	
	// if admin
	if (GetUserFlagBits(client) && (index = FindStringInArray(g_hAdtWelcomeMsgLangs, "admin")) != -1)
	{
		PrintWelcomeMsg(client, GetArrayCell(g_hAdtWelcomeMsgPacks, index));
	}
	// if regular user
	else if ((index = FindStringInArray(g_hAdtWelcomeMsgLangs, szLangName)) != -1)
	{
		PrintWelcomeMsg(client, GetArrayCell(g_hAdtWelcomeMsgPacks, index));
	}
	// if no language found
	else if ((index = FindStringInArray(g_hAdtWelcomeMsgLangs, "main")) != -1)
	{
		PrintWelcomeMsg(client, GetArrayCell(g_hAdtWelcomeMsgPacks, index));
	}
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bPlayed[client] = false;
}

void ClearHandles()
{
	for (int i = 0; i < GetArraySize(g_hAdtWelcomeMsgPacks); i++)
	{
		CloseHandle(GetArrayCell(g_hAdtWelcomeMsgPacks, i));
	}
	
	ClearArray(g_hAdtWelcomeMsgPacks);
	ClearArray(g_hAdtWelcomeMsgLangs);
}

void LoadWelcomeMessages()
{
	char szMainPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szMainPath, sizeof(szMainPath), "configs");
	
	char szPath[PLATFORM_MAX_PATH];
	
	Format(szPath, sizeof(szPath), "%s\\console_welcome.txt", szMainPath);
	MsgFileToDatapack("main", szPath);
	
	Format(szPath, sizeof(szPath), "%s\\console_welcome_admin.txt", szMainPath);
	MsgFileToDatapack("admin", szPath);
	
	char szLangName[LANG_LEN];
	char szLangCode[5];
	for (int i = 0; i < GetLanguageCount(); i++)
	{
		GetLanguageInfo(i, szLangCode, sizeof(szLangCode), szLangName, sizeof(szLangName));
		StringToLower(szLangName);
		Format(szPath, sizeof(szPath), "%s\\console_welcome_%s.txt", szMainPath, szLangCode);
		MsgFileToDatapack(szLangName, szPath);
	}
	
	if (GetArraySize(g_hAdtWelcomeMsgPacks) == 0)
	{
		LogError("No welcome messages was found in the \"%s\" folder!", szMainPath);
		return;
	}
}

void MsgFileToDatapack(const char[] szAlias, const char[] szPath)
{
	if (!FileExists(szPath))
		return;
	
	File hFile = OpenFile(szPath, "rt");
	if (hFile == null)
		return;
	
	DataPack hMsgPack = CreateDataPack();
	
	char szLine[FILE_LINE_LEN];
	while (!IsEndOfFile(hFile) && ReadFileLine(hFile, szLine, sizeof(szLine)))
	{
		WritePackString(hMsgPack, szLine);
	}
	
	PushArrayCell(g_hAdtWelcomeMsgPacks, hMsgPack);
	PushArrayString(g_hAdtWelcomeMsgLangs, szAlias);
	
	delete hFile;
}

void PrintWelcomeMsg(int client, DataPack hMsgPack)
{
	// {server_name}
	char szServerName[200];
	GetConVarString(FindConVar("hostname"), szServerName, sizeof(szServerName));
	
	// {player_name}
	char szClientName[MAX_NAME_LENGTH];
	GetClientName(client, szClientName, sizeof(szClientName));
	
	// {time}
	char szTime[20];
	FormatTime(szTime, sizeof(szTime), "%H:%M");
	
	// {time_12}
	char szTime12[20];
	FormatTime(szTime12, sizeof(szTime12), "%I:%M");
	
	// {date}
	char szDate[20];
	FormatTime(szDate, sizeof(szDate), "%d/%m/%Y");
	
	// {date_us}
	char szDateUS[20];
	FormatTime(szDateUS, sizeof(szDateUS), "%m/%d/%Y");
	
	// {map}
	char szMap[PLATFORM_MAX_PATH];
	GetCurrentMap(szMap, sizeof(szMap));
	
	// {nextmap}
	char szNextMap[PLATFORM_MAX_PATH];
	GetNextMap(szNextMap, sizeof(szNextMap));
	
	// {server_ip}
	char szServerAdress[40];
	char szIP[20];
	char szPort[18];
	GetConVarString(FindConVar("ip"), szIP, sizeof(szIP));
	GetConVarString(FindConVar("hostport"), szPort, sizeof(szPort));
	Format(szServerAdress, sizeof(szServerAdress), "%s:%s", szIP, szPort);
	
	// {tickrate}
	int TickRate = RoundToNearest(1.0 / GetTickInterval());
	char szTickRate[10];
	Format(szTickRate, sizeof(szTickRate), "%d", TickRate);
	
	// {max_players}
	int VisiblePlayers = FindConVar("sv_visiblemaxplayers").IntValue;
	if (VisiblePlayers == -1)
		VisiblePlayers = MaxClients;
	char szVisiblePlayers[5];
	Format(szVisiblePlayers, sizeof(szVisiblePlayers), "%d", VisiblePlayers);
	
	// {player_count}
	int Count = GetRealClientCount();
	char szPlayerCount[5];
	Format(szPlayerCount, sizeof(szPlayerCount), "%d", Count);

	// {timeleft}
	int TimeLeft;
	char szTimeLeft[20];
	if (GetMapTimeLeft(TimeLeft))
	{
		int Mins, Secs;
		
		if (TimeLeft >= 0)
		{
			Mins = TimeLeft / 60;
			Secs = TimeLeft % 60;
			Format(szTimeLeft, sizeof(szTimeLeft), "%d:%02d", Mins, Secs);
		}
	}
	
	// {player_ip}
	char szClientIP[20];
	GetClientIP(client, szClientIP, sizeof(szClientIP));
	
	// {player_country}
	char szClientCountry[45];
	GeoipCountry(szClientIP, szClientCountry, sizeof(szClientCountry));
	
	// {server_uptime}
	int ServerUptime = RoundToFloor(GetEngineTime());
	int Days = ServerUptime / 60 / 60 / 24;
	int Hours = (ServerUptime / 60 / 60) % 24;
	int Mins = (ServerUptime / 60) % 60;
	char szServerUptime[30];
	Format(szServerUptime, sizeof(szServerUptime), "%d days %02d hours %02d minutes", Days, Hours, Mins);
	
	// {is_admin}
	char szIsAdmin[8];
	if (GetUserFlagBits(client))
	{
		Format(szIsAdmin, sizeof(szIsAdmin), "%T", "Yes", client);
	}
	else
	{
		Format(szIsAdmin, sizeof(szIsAdmin), "%T", "No", client);
	}
	
	// {player_steamid}
	char szSteam[35];
	GetClientAuthId(client, AuthId_Engine, szSteam, sizeof(szSteam));
	
	// {player_language}
	char szClientLang[LANG_LEN];
	GetLanguageInfo(GetClientLanguage(client), _, _, szClientLang, sizeof(szClientLang));
	
	// {server_language}
	char szServerLang[LANG_LEN];
	GetLanguageInfo(GetServerLanguage(), _, _, szServerLang, sizeof(szServerLang));
	
	hMsgPack.Reset();
	char szLine[FILE_LINE_LEN];
	while (IsPackReadable(hMsgPack, 1))
	{
		ReadPackString(hMsgPack, szLine, sizeof(szLine));
		
		ReplaceString(szLine, sizeof(szLine), "{server_name}", szServerName, false);
		ReplaceString(szLine, sizeof(szLine), "{player_name}", szClientName, false);
		ReplaceString(szLine, sizeof(szLine), "{time}", szTime, false);
		ReplaceString(szLine, sizeof(szLine), "{time_12}", szTime12, false);
		ReplaceString(szLine, sizeof(szLine), "{date}", szDate, false);
		ReplaceString(szLine, sizeof(szLine), "{date_us}", szDateUS, false);
		ReplaceString(szLine, sizeof(szLine), "{map}", szMap, false);
		ReplaceString(szLine, sizeof(szLine), "{nextmap}", szNextMap, false);
		ReplaceString(szLine, sizeof(szLine), "{timeleft}", szTimeLeft, false);
		ReplaceString(szLine, sizeof(szLine), "{tickrate}", szTickRate, false);
		ReplaceString(szLine, sizeof(szLine), "{server_ip}", szServerAdress, false);
		ReplaceString(szLine, sizeof(szLine), "{max_players}", szVisiblePlayers, false);
		ReplaceString(szLine, sizeof(szLine), "{player_count}", szPlayerCount, false);
		ReplaceString(szLine, sizeof(szLine), "{player_ip}", szClientIP, false);
		ReplaceString(szLine, sizeof(szLine), "{player_country}", szClientCountry, false);
		ReplaceString(szLine, sizeof(szLine), "{server_uptime}", szServerUptime, false);
		ReplaceString(szLine, sizeof(szLine), "{is_admin}", szIsAdmin, false);
		ReplaceString(szLine, sizeof(szLine), "{player_steamid}", szSteam, false);
		ReplaceString(szLine, sizeof(szLine), "{player_language}", szClientLang, false);
		ReplaceString(szLine, sizeof(szLine), "{server_language}", szServerLang, false);
		ReplaceString(szLine, sizeof(szLine), "\n", "");
		
		PrintToConsole(client, szLine);
	}
}

int GetRealClientCount()
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			clients++;
		}
	}
	return clients;
}

stock void StringToLower(char[] szStr)
{
	for (int i = 0; szStr[i] != 0; i++)
	{
		szStr[i] = CharToLower(szStr[i]);
	}
}

stock void ClearString(char[] szStr)
{
	szStr[0] = 0;
}