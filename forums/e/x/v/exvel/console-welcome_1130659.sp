#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.1.2"

#define LANG_LEN 30
#define FILE_LINE_LEN 300

public Plugin:myinfo = 
{
	name = "Console Welcome Message",
	author = "exvel",
	description = "Prints welcome message into the client's console on join",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new Handle:cvar_PluginEnabled = INVALID_HANDLE;
new Handle:cvar_IgnoreMapChanges = INVALID_HANDLE;

new Handle:g_hAdtWelcomeMsgPacks = INVALID_HANDLE;
new Handle:g_hAdtWelcomeMsgLangs = INVALID_HANDLE;

new bool:g_bPlayed[MAXPLAYERS+1] = {false,...};

public OnPluginStart()
{
	CreateConVar("sm_console_welcome_version", PLUGIN_VERSION, "Console Welcome Message Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_PluginEnabled = CreateConVar("sm_console_welcome", "1", "Console Welcome Message, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_IgnoreMapChanges = CreateConVar("sm_console_welcome_ingnore_mapchanges", "1", "Don't print welcome message to client after map change", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_hAdtWelcomeMsgPacks = CreateArray();
	g_hAdtWelcomeMsgLangs = CreateArray(LANG_LEN);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	LoadTranslations("common.phrases");
}

LoadWelcomeMessages()
{
	decl String:szMainPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szMainPath, sizeof(szMainPath), "configs");
	
	decl String:szPath[PLATFORM_MAX_PATH];
	
	Format(szPath, sizeof(szPath), "%s\\console_welcome.txt", szMainPath);
	MsgFileToDatapack("main", szPath);
	
	Format(szPath, sizeof(szPath), "%s\\console_welcome_admin.txt", szMainPath);
	MsgFileToDatapack("admin", szPath);
	
	decl String:szLangName[LANG_LEN];
	decl String:szLangCode[5];
	for (new i = 0; i < GetLanguageCount(); i++)
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

public OnConfigsExecuted()
{
	if (!GetConVarBool(cvar_PluginEnabled))
		return;
	
	ClearHandles();
	LoadWelcomeMessages();
}

public OnClientPostAdminCheck(client)
{
	if (!GetConVarBool(cvar_PluginEnabled) || IsFakeClient(client))
		return;
	
	if (g_bPlayed[client] && GetConVarBool(cvar_IgnoreMapChanges))
		return;
	
	g_bPlayed[client] = true;
	
	decl String:szLangName[LANG_LEN];
	GetLanguageInfo(GetClientLanguage(client), _, _, szLangName, sizeof(szLangName));
	StringToLower(szLangName);
	
	new index = -1;
	
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

ClearHandles()
{
	for (new i = 0; i < GetArraySize(g_hAdtWelcomeMsgPacks); i++)
	{
		CloseHandle(GetArrayCell(g_hAdtWelcomeMsgPacks, i));
	}
	
	ClearArray(g_hAdtWelcomeMsgPacks);
	ClearArray(g_hAdtWelcomeMsgLangs);
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bPlayed[client] = false;
}

MsgFileToDatapack(const String:szAlias[], const String:szPath[])
{
	if (!FileExists(szPath))
		return;
	
	new Handle:hFile = OpenFile(szPath, "rt");
	if (hFile == INVALID_HANDLE)
		return;
	
	new Handle:hMsgPack = CreateDataPack();
	
	decl String:szLine[FILE_LINE_LEN];
	while (!IsEndOfFile(hFile) && ReadFileLine(hFile, szLine, sizeof(szLine)))
	{
		WritePackString(hMsgPack, szLine);
	}
	
	PushArrayCell(g_hAdtWelcomeMsgPacks, hMsgPack);
	PushArrayString(g_hAdtWelcomeMsgLangs, szAlias);
	
	CloseHandle(hFile);
}

PrintWelcomeMsg(client, Handle:hMsgPack)
{
	// {server_name}
	decl String:szServerName[200];
	GetConVarString(FindConVar("hostname"), szServerName, sizeof(szServerName));
	
	// {player_name}
	decl String:szClientName[MAX_NAME_LENGTH];
	GetClientName(client, szClientName, sizeof(szClientName));
	
	// {time}
	decl String:szTime[20];
	FormatTime(szTime, sizeof(szTime), "%H:%M");
	
	// {time_12}
	decl String:szTime12[20];
	FormatTime(szTime12, sizeof(szTime12), "%I:%M");
	
	// {date}
	decl String:szDate[20];
	FormatTime(szDate, sizeof(szDate), "%d/%m/%Y");
	
	// {date_us}
	decl String:szDateUS[20];
	FormatTime(szDateUS, sizeof(szDateUS), "%m/%d/%Y");
	
	// {map}
	decl String:szMap[PLATFORM_MAX_PATH];
	GetCurrentMap(szMap, sizeof(szMap));
	
	// {nextmap}
	new String:szNextMap[PLATFORM_MAX_PATH];
	GetNextMap(szNextMap, sizeof(szNextMap));
	
	// {server_ip}
	decl String:szServerAdress[40];
	decl String:szIP[20];
	decl String:szPort[18];
	GetConVarString(FindConVar("ip"), szIP, sizeof(szIP));
	GetConVarString(FindConVar("hostport"), szPort, sizeof(szPort));
	Format(szServerAdress, sizeof(szServerAdress), "%s:%s", szIP, szPort);
	
	// {tickrate}
	new TickRate = RoundToNearest(1.0 / GetTickInterval());
	decl String:szTickRate[10];
	Format(szTickRate, sizeof(szTickRate), "%d", TickRate);
	
	// {max_players}
	new VisiblePlayers = GetConVarInt(FindConVar("sv_visiblemaxplayers"));
	if (VisiblePlayers == -1)
		VisiblePlayers = MaxClients;
	decl String:szVisiblePlayers[5];
	Format(szVisiblePlayers, sizeof(szVisiblePlayers), "%d", VisiblePlayers);
	
	// {player_count}
	decl String:szPlayerCount[5];
	Format(szPlayerCount, sizeof(szPlayerCount), "%d", GetClientCount(false));
	
	// {timeleft}
	new TimeLeft;
	new String:szTimeLeft[20];
	if (GetMapTimeLeft(TimeLeft))
	{
		new Mins, Secs;
		
		if (TimeLeft >= 0)
		{
			Mins = TimeLeft / 60;
			Secs = TimeLeft % 60;
			Format(szTimeLeft, sizeof(szTimeLeft), "%d:%02d", Mins, Secs);
		}
	}
	
	// {player_ip}
	decl String:szClientIP[20];
	GetClientIP(client, szClientIP, sizeof(szClientIP));
	
	// {player_country}
	new String:szClientCountry[45];
	GeoipCountry(szClientIP, szClientCountry, sizeof(szClientCountry));
	
	// {server_uptime}
	new ServerUptime = RoundToFloor(GetEngineTime());
	new Days = ServerUptime / 60 / 60 / 24;
	new Hours = (ServerUptime / 60 / 60) % 24;
	new Mins = (ServerUptime / 60) % 60;
	decl String:szServerUptime[30];
	Format(szServerUptime, sizeof(szServerUptime), "%d days %02d hours %02d minutes", Days, Hours, Mins);
	
	// {is_admin}
	decl String:szIsAdmin[8];
	if (GetUserFlagBits(client))
	{
		Format(szIsAdmin, sizeof(szIsAdmin), "%T", "Yes", client);
	}
	else
	{
		Format(szIsAdmin, sizeof(szIsAdmin), "%T", "No", client);
	}
	
	// {player_steamid}
	decl String:szSteam[35];
	GetClientAuthString(client, szSteam, sizeof(szSteam));
	
	// {player_language}
	decl String:szClientLang[LANG_LEN];
	GetLanguageInfo(GetClientLanguage(client), _, _, szClientLang, sizeof(szClientLang));
	
	// {server_language}
	decl String:szServerLang[LANG_LEN];
	GetLanguageInfo(GetServerLanguage(), _, _, szServerLang, sizeof(szServerLang));
	
	ResetPack(hMsgPack);
	decl String:szLine[FILE_LINE_LEN];
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

stock ClearString(String:szStr[])
{
	szStr[0] = 0;
}

stock StringToLower(String:szStr[])
{
	for (new i = 0; szStr[i] != 0; i++)
	{
		szStr[i] = CharToLower(szStr[i]);
	}
}