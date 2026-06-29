#pragma semicolon 1
#pragma dynamic 200000 

#include <sourcemod>
#include <morecolors>
#include <clientprefs>
#include <SteamWorks>
#include <smjansson>

#define PLUGIN_NAME "[CSGO] OPSkins"
#define PLUGIN_VERSION "1.0.2"

#define OPSKINS_URL "http://opskins.com/api/v1.php"
#define OPSKINS_GETITEMS "get_items"
#define OPSKINS_ADDTOCART "add_to_cart"
#define OPSKINS_SEARCH "search"
#define MaxDataEntries 500

new Handle:hConVars[8] = {INVALID_HANDLE, ...};
new bool:cv_bPluginStatus, Float:cv_fReloadData, String:cv_sAPIKey[64], cv_iMaxEntries, cv_iMaxData, String:cv_sMainMenuCommand[64], Float:cv_fAdvertTimer;

//Menu Handles
new Handle:hMainMenu;
new Handle:hBrowseLatest;
new Handle:hSearchMain;
new Handle:hSearchTypes;
new Handle:hSearchGrades;
new Handle:hPreferenceTypes;
new Handle:hPreferenceGrades;
new Handle:hPreferencesMenu;
new Handle:hPreferenceSorting;

new bool:bIsDataParsed;
new bool:bLateLoad;

//Items Data
//ItemsData[ID][sID]
//ItemsData[ID][sName]
//ItemsData[ID][sAmount]
enum eItemsData
{
	String:sID[32],
	String:sName[128],
	String:sAmount[32],
}
new ItemsData[MaxDataEntries][eItemsData];
new iItemsAmount;

new bool:bSearchItem[MAXPLAYERS + 1];
new String:sSearchTypes[MAXPLAYERS + 1][64];
new String:sSearchGrades[MAXPLAYERS + 1][64];

//Preference Client Cookie Handles
new Handle:g_hSorting;
new Handle:g_hTypes;
new Handle:g_hGrades;
new Handle:g_hStatTrak;

//Players Prefs
//PrefData[client][sSorting];
//PrefData[client][sTypes];
//PrefData[client][sGrades];
enum ePlayerPrefs
{
	String:sSorting[4],
	String:sTypes[4],
	String:sGrades[4],
	bool:bStatTrak,
}
new PrefData[MAXPLAYERS + 1][ePlayerPrefs];

new Handle:hTrie_ConfigData_Types;
new Handle:hTrie_ConfigData_Grades;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Keith Warren (Drixevel)",
	description = "Allows players to access the latest items, searching & purchases for OPskins.com.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:sError[], err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		Format(sError, err_max, "This plug-in only works for Counter-Strike: Global Offensive.");
		return APLRes_Failure;
	}
		
	bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("OPSkins.phrases");
	
	hConVars[0] = CreateConVar("opskins_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hConVars[1] = CreateConVar("sm_opskins_status", "1", "Status of the plugin: (1 = on, 0 = off | default: 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[2] = CreateConVar("sm_opskins_reload_data", "30", "Amount of minutes for the plugin to reload data: (default: 30, DO NOT GO UNDER)", FCVAR_PLUGIN, true, 31.0);
	hConVars[3] = CreateConVar("sm_opskins_api_key", "", "OPSkins API key to use: (api.opskins.com/portal/signup/)", FCVAR_PROTECTED);
	hConVars[4] = CreateConVar("sm_opskins_latest_entries", "10", "Amount of latest entries to show: (default: 10)", FCVAR_PLUGIN, true, 1.0);
	hConVars[5] = CreateConVar("sm_opskins_max_entries", "500", "Maximum amount of items to pull from the OPSkins API: (default: 500, DO NOT GO ABOVE)", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	hConVars[6] = CreateConVar("sm_opskins_command", "opskins", "Command to type in-game for the main menu: (default: opskins)", FCVAR_PLUGIN);
	hConVars[7] = CreateConVar("sm_opskins_advertisement", "120", "Amount of seconds for the plugin to post the advertisement: (default: 120, 0 = disabled)", FCVAR_PLUGIN, true, 1.0);
	
	for (new i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], HandleCvars);
	}
	
	RegConsoleCmd("sm_search", Search, "Search for items in the OPSkins database.");
	RegConsoleCmd("sm_searcht", SearchType, "Search for items with types in the OPSkins database.");
	RegConsoleCmd("sm_searchtype", SearchType, "Search for items with types in the OPSkins database.");
	RegConsoleCmd("sm_searchg", SearchGrade, "Search for items with grades in the OPSkins database.");
	RegConsoleCmd("sm_searchgrade", SearchGrade, "Search for items with grades in the OPSkins database.");
	RegConsoleCmd("sm_tst", ToggleStatTrak, "Toggle items to be searched via StatTrak status in the OPSkins database.");
	RegConsoleCmd("sm_togglestattrak", ToggleStatTrak, "Toggle items to be searched via StatTrak status in the OPSkins database.");
	RegConsoleCmd("sm_cancelsearch", CancelSearch, "Cancel any current searches currently under queue.");
	RegConsoleCmd("sm_cancels", CancelSearch, "Cancel any current searches currently under queue.");
	RegAdminCmd("sm_reloaddata", ReloadData, ADMFLAG_ROOT, "Reload all the data currently stored in the plugin from the OPSkins web server.");
	RegAdminCmd("sm_reloadlatest", ReloadLatest, ADMFLAG_ROOT, "Reload the latest entries in the latest items menu from data.");
	
	hTrie_ConfigData_Types = CreateTrie();
	hTrie_ConfigData_Grades = CreateTrie();
	
	g_hSorting = RegClientCookie("opskins_sorting", "Sorting options to use while search through items.", CookieAccess_Public);
	g_hTypes = RegClientCookie("opskins_types", "Item types to search for while search through items.", CookieAccess_Public);
	g_hGrades = RegClientCookie("opskins_grades", "Item grades to search for while search through items.", CookieAccess_Public);
	g_hStatTrak = RegClientCookie("opskins_stattrak", "Enable or disable StatTrak items while search through items.", CookieAccess_Public);
	
	AutoExecConfig();
}

public HandleCvars(Handle:cvar, const String:sOldValue[], const String:sNewValue[])
{
	if (StrEqual(sOldValue, sNewValue, true)) return;
	
	if (cvar == hConVars[0])
	{
		SetConVarString(hConVars[0], PLUGIN_VERSION);
	}
	else if (cvar == hConVars[1])
	{
		cv_bPluginStatus = bool:StringToInt(sNewValue);
	}
	else if (cvar == hConVars[2])
	{
		cv_fReloadData = StringToFloat(sNewValue);
	}
	else if (cvar == hConVars[3])
	{
		GetConVarString(hConVars[3], cv_sAPIKey, sizeof(cv_sAPIKey));
	}
	else if (cvar == hConVars[4])
	{
		cv_iMaxEntries = StringToInt(sNewValue);
	}
	else if (cvar == hConVars[5])
	{
		cv_iMaxData = StringToInt(sNewValue);
	}
	else if (cvar == hConVars[6])
	{
		GetConVarString(hConVars[6], cv_sMainMenuCommand, sizeof(cv_sMainMenuCommand));
	}
	else if (cvar == hConVars[7])
	{
		cv_fAdvertTimer = StringToFloat(sNewValue);
	}
}

public OnConfigsExecuted()
{	
	cv_bPluginStatus = GetConVarBool(hConVars[1]);
	cv_fReloadData = GetConVarFloat(hConVars[2]);
	GetConVarString(hConVars[3], cv_sAPIKey, sizeof(cv_sAPIKey));
	cv_iMaxEntries = GetConVarInt(hConVars[4]);
	cv_iMaxData = GetConVarInt(hConVars[5]);
	GetConVarString(hConVars[6], cv_sMainMenuCommand, sizeof(cv_sMainMenuCommand));
	cv_fAdvertTimer = GetConVarFloat(hConVars[7]);
	
	if (!cv_bPluginStatus) return;
	
	if (strlen(cv_sAPIKey) == 0)
	{
		OPSkins_Log("ERROR: No API key found, please create your own and set it in the configuration file.");
		PrintToServer("ERROR: Check plugin logs for more information.");
		return;
	}
	
	new String:sCommand[64];
	Format(sCommand, sizeof(sCommand), "sm_%s", cv_sMainMenuCommand);
	RegConsoleCmd(sCommand, OpenMenu);
	
	if (bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (AreClientCookiesCached(i)) continue;
			
			OnClientCookiesCached(i);
		}
		bLateLoad = false;
	}
	
	BuildMenus();
	ParseItemsData();
	
	new Float:fTimer = cv_fReloadData * 60;
	CreateTimer(fTimer, ReParseItemsData, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(cv_fAdvertTimer, Advertisement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Advertisement(Handle:hTimer)
{
	CPrintToChatAll("%t %t", "plugin tag", "plugin advertisement", cv_sMainMenuCommand);
}

public OnClientPutInServer(client)
{
	bSearchItem[client] = false;
	sSearchTypes[client][0] = '\0';
	sSearchGrades[client][0] = '\0';
}

public OnClientCookiesCached(client)
{
	GetClientCookie(client, g_hSorting, PrefData[client][sSorting], 4);
	GetClientCookie(client, g_hTypes, PrefData[client][sTypes], 4);
	GetClientCookie(client, g_hGrades, PrefData[client][sGrades], 4);
	
	new String:sStatTrak[2];
	GetClientCookie(client, g_hStatTrak, sStatTrak, sizeof(sStatTrak));
	PrefData[client][bStatTrak] = bool:StringToInt(sStatTrak);
}

public OnClientDisconnect(client)
{
	bSearchItem[client] = false;
	sSearchTypes[client][0] = '\0';
	sSearchGrades[client][0] = '\0';
}

public Action:OpenMenu(client, args)
{
	if (!cv_bPluginStatus || !IsClientInGame(client) || !bIsDataParsed) return Plugin_Handled;
	
	DisplayMenu(hMainMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:ReloadData(client, args)
{
	if (!cv_bPluginStatus) return Plugin_Handled;
	
	CReplyToCommand(client, "%t %t", "plugin tag", "reloading item data");
	ParseItemsData();
	
	return Plugin_Handled;
}

public Action:ReloadLatest(client, args)
{
	if (!cv_bPluginStatus || !bIsDataParsed) return Plugin_Handled;
	
	CReplyToCommand(client, "%t %t", "plugin tag", "reloading latest entries");
	ReloadLatestEntries();
	
	return Plugin_Handled;
}

public Action:Search(client, args)
{
	if (!cv_bPluginStatus || !IsClientInGame(client) || !bIsDataParsed) return Plugin_Handled;
	
	if (bSearchItem[client])
	{
		CPrintToChat(client, "%t %t", "plugin tag", "search in progress");
		return Plugin_Handled;
	}
	
	new String:sInput[64];
	new length = GetCmdArgString(sInput, sizeof(sInput));
	
	if (length > 1)
	{
		SearchForItem(client, sInput, PrefData[client][sSorting], PrefData[client][sTypes], PrefData[client][sGrades], PrefData[client][bStatTrak]);
		return Plugin_Handled;
	}
	
	RequestFrame(SearchItemFrame, GetClientUserId(client));
	return Plugin_Handled;
}

public SearchItemFrame(any:data)
{
	new client = GetClientOfUserId(data);
	
	bSearchItem[client] = true;
	CPrintToChat(client, "%t %t", "plugin tag", "search in chat");
}

public Action:SearchType(client, args)
{
	if (!cv_bPluginStatus || !IsClientInGame(client) || !bIsDataParsed) return Plugin_Handled;
	
	if (bSearchItem[client])
	{
		CPrintToChat(client, "%t %t", "plugin tag", "search in progress");
		return Plugin_Handled;
	}
		
	new String:sInput[64];
	new length = GetCmdArgString(sInput, sizeof(sInput));
	
	if (length < 1)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "no search term");
		return Plugin_Handled;
	}
	
	new String:sValue[3];
	if (!GetTrieString(hTrie_ConfigData_Types, sInput, sValue, sizeof(sValue)))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "no valid types available", sInput);
		return Plugin_Handled;
	}
	
	strcopy(sSearchTypes[client], sizeof(sSearchTypes[]), sValue);
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, GetClientUserId(client));
	WritePackString(hPack, sInput);
	
	RequestFrame(SearchItemFrame_Type, hPack);
	
	return Plugin_Handled;
}

public SearchItemFrame_Type(any:data)
{
	ResetPack(data);
	
	new client = GetClientOfUserId(ReadPackCell(data));
	
	new String:sInput[64];
	ReadPackString(data, sInput, sizeof(sInput));
	
	CloseHandle(data);
	
	bSearchItem[client] = true;
	CPrintToChat(client, "%t %t", "plugin tag", "search in chat type", sInput);
}

public Action:SearchGrade(client, args)
{
	if (!cv_bPluginStatus || !IsClientInGame(client) || !bIsDataParsed) return Plugin_Handled;
	
	if (bSearchItem[client])
	{
		CPrintToChat(client, "%t %t", "plugin tag", "search in progress");
		return Plugin_Handled;
	}
		
	new String:sInput[64];
	new length = GetCmdArgString(sInput, sizeof(sInput));
	
	if (length < 1)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "no search term");
		return Plugin_Handled;
	}
	
	new String:sValue[3];
	if (!GetTrieString(hTrie_ConfigData_Grades, sInput, sValue, sizeof(sValue)))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "no valid grades available", sInput);
		return Plugin_Handled;
	}
	
	strcopy(sSearchGrades[client], sizeof(sSearchGrades[]), sValue);
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, GetClientUserId(client));
	WritePackString(hPack, sInput);
	
	RequestFrame(SearchItemFrame_Grade, hPack);
	
	return Plugin_Handled;
}

public SearchItemFrame_Grade(any:data)
{
	ResetPack(data);
	
	new client = GetClientOfUserId(ReadPackCell(data));
	
	new String:sInput[64];
	ReadPackString(data, sInput, sizeof(sInput));
	
	CloseHandle(data);
	
	bSearchItem[client] = true;
	CPrintToChat(client, "%t %t", "plugin tag", "search in chat grade", sInput);
}

public Action:ToggleStatTrak(client, args)
{
	if (!cv_bPluginStatus || !IsClientInGame(client)) return Plugin_Handled;
	
	switch (PrefData[client][bStatTrak])
	{
	case true:
		{
			SetClientCookie(client, g_hStatTrak, "0");
			PrefData[client][bStatTrak] = false;
		}
	case false:
		{
			SetClientCookie(client, g_hStatTrak, "1");
			PrefData[client][bStatTrak] = true;
		}
	}
	
	CPrintToChat(client, "%t %t", "plugin tag", "stattrak update message", PrefData[client][bStatTrak] ? "ON" : "OFF");
	
	return Plugin_Handled;
}

public Action:CancelSearch(client, args)
{
	if (!cv_bPluginStatus || !IsClientInGame(client) || !bIsDataParsed || !bSearchItem[client]) return Plugin_Handled;
	
	bSearchItem[client] = false;
	sSearchTypes[client][0] = '\0';
	sSearchGrades[client][0] = '\0';
	CPrintToChat(client, "%t %t", "plugin tag", "search cancelled");
	
	return Plugin_Handled;
}

public Action:ReParseItemsData(Handle:hTimer)
{
	if (!cv_bPluginStatus) return Plugin_Stop;
	
	OPSkins_Log("ALERT: Reloading item data via timer... [Time: %f]", cv_fReloadData);
	ParseItemsData();
	
	return Plugin_Continue;
}

ParseItemsData()
{
	OPSkins_Log("ALERT: Requesting OPSkins web server for item data...");
	bIsDataParsed = false;
	
	//http://opskins.com/api/v1.php?request=OPSKINS_GETITEMS&key=KEY&max=sMaxEntries
	new Handle:request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, OPSKINS_URL);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "request", OPSKINS_GETITEMS);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "key", cv_sAPIKey);
	
	new String:sMaxEntries[32];
	IntToString(cv_iMaxData, sMaxEntries, sizeof(sMaxEntries));
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "max", sMaxEntries);
	
	SteamWorks_SetHTTPCallbacks(request, OnAPIConnect);
	SteamWorks_SendHTTPRequest(request);
}

public OnAPIConnect(Handle:hRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		OPSkins_Log("ERROR: Issue contacting OPSkins: Status code: %d, Successful: %s", _:eStatusCode, bRequestSuccessful ? "true" : "false");
		return;
	}
	
	new String:sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "data/opskins_data.txt");
	
	if (!SteamWorks_WriteHTTPResponseBodyToFile(hRequest, sFile))
	{
		OPSkins_Log("ERROR: Issue saving data pulled from website to file '%s'!", sFile);
	}
	
	new String:sError[512], iLine, iColumn;
	new Handle:hOBJ = json_load_file_ex(sFile, sError, sizeof(sError), iLine, iColumn);
	
	if (hOBJ == INVALID_HANDLE)
	{
		OPSkins_Log("ERROR: Issue parsing JSON file after data has downloaded and saved to file: '%s' Line: %i Column: %i", sError, iLine, iColumn);
		return;
	}
	
	new Handle:hKV = CreateKeyValues("OPSkins_Data"); 
	JSONToKeyValues("Main", hOBJ, hKV); 

	KvJumpToKey(hKV, "Main");
	KvJumpToKey(hKV, "success");
	
	KvGotoFirstSubKey(hKV, false);
	
	iItemsAmount = 0;
	do {
		KvGetString(hKV, "id", ItemsData[iItemsAmount][sID], 32);
		KvGetString(hKV, "market_name", ItemsData[iItemsAmount][sName], 128);
		KvGetString(hKV, "amount", ItemsData[iItemsAmount][sAmount], 32);
		iItemsAmount++;
	} while (KvGotoNextKey(hKV, false));
	
	CloseHandle(hKV); 
	CloseHandle(hOBJ);
	
	bIsDataParsed = true;
	CPrintToChatAll("%t %t", "plugin tag", "items database reloaded");
	OPSkins_Log("ALERT: Request for items data from OPSkins web server successful!");
	
	ReloadLatestEntries();
}

BuildMenus()
{
	//Main Menu
	if (hMainMenu != INVALID_HANDLE)
	{
		CloseHandle(hMainMenu);
		hMainMenu = INVALID_HANDLE;
	}
	
	hMainMenu = CreateMenu(MenuHandle_MainMenu);
	SetMenuTitle(hMainMenu, "%t", "main menu title");
	
	new String:sFormat[255];
	Format(sFormat, sizeof(sFormat), "%t", "main menu browse");
	AddMenuItem(hMainMenu, "Browse_Latest", sFormat);
	
	Format(sFormat, sizeof(sFormat), "%t", "main menu search");
	AddMenuItem(hMainMenu, "Search", sFormat);
	
	Format(sFormat, sizeof(sFormat), "%t", "main menu items loaded", cv_iMaxEntries);
	AddMenuItem(hMainMenu, "", sFormat, ITEMDRAW_DISABLED);
	
	Format(sFormat, sizeof(sFormat), "%t", "main menu preference settings");
	AddMenuItem(hMainMenu, "Preference_Settings", sFormat);
	
	//Latest Entries Menu
	if (hBrowseLatest != INVALID_HANDLE)
	{
		CloseHandle(hBrowseLatest);
		hBrowseLatest = INVALID_HANDLE;
	}
	
	hBrowseLatest = CreateMenu(MenuHandle_LatestEntries);
	SetMenuTitle(hBrowseLatest, "%t", "latest entries title", cv_iMaxEntries);
	SetMenuExitBackButton(hBrowseLatest, true);
	
	//Search Main Menu
	if (hSearchMain != INVALID_HANDLE)
	{
		CloseHandle(hSearchMain);
		hSearchMain = INVALID_HANDLE;
	}
	
	hSearchMain = CreateMenu(MenuHandle_SearchMain);
	SetMenuTitle(hSearchMain, "%t", "search sections title");
	SetMenuExitBackButton(hSearchMain, true);
	
	Format(sFormat, sizeof(sFormat), "%t", "search sections item");
	AddMenuItem(hSearchMain, "search_item", sFormat);
	
	Format(sFormat, sizeof(sFormat), "%t", "search sections types");
	AddMenuItem(hSearchMain, "search_categories", sFormat);
	
	Format(sFormat, sizeof(sFormat), "%t", "search sections grades");
	AddMenuItem(hSearchMain, "search_grades", sFormat);
	
	//Search Types Menu
	if (hSearchTypes != INVALID_HANDLE)
	{
		CloseHandle(hSearchTypes);
		hSearchTypes = INVALID_HANDLE;
	}
	
	hSearchTypes = CreateMenu(MenuHandle_Search_Types);
	SetMenuTitle(hSearchTypes, "%t", "search types title");
	SetMenuExitBackButton(hSearchTypes, true);
	
	PullDataConfig(hSearchTypes, "type");
	
	//Search Grades Menu
	if (hSearchGrades != INVALID_HANDLE)
	{
		CloseHandle(hSearchGrades);
		hSearchGrades = INVALID_HANDLE;
	}
	
	hSearchGrades = CreateMenu(MenuHandle_Search_Grades);
	SetMenuTitle(hSearchGrades, "%t", "search types title");
	SetMenuExitBackButton(hSearchGrades, true);
	
	PullDataConfig(hSearchGrades, "grade");
	
	//Preferences & Settings Menu
	if (hPreferencesMenu != INVALID_HANDLE)
	{
		CloseHandle(hPreferencesMenu);
		hPreferencesMenu = INVALID_HANDLE;
	}
	
	hPreferencesMenu = CreateMenu(MenuHandle_PreferencesMenu);
	SetMenuTitle(hPreferencesMenu, "%t", "preferences title");
	SetMenuExitBackButton(hPreferencesMenu, true);
	
	Format(sFormat, sizeof(sFormat), "%t", "preferences items sorting");
	AddMenuItem(hPreferencesMenu, "pref_sorts", sFormat);
	
	Format(sFormat, sizeof(sFormat), "%t", "preferences items types");
	AddMenuItem(hPreferencesMenu, "pref_types", sFormat);
	
	Format(sFormat, sizeof(sFormat), "%t", "preferences items grades");
	AddMenuItem(hPreferencesMenu, "pref_grades", sFormat);
	
	Format(sFormat, sizeof(sFormat), "%t", "preferences items stattrak");
	AddMenuItem(hPreferencesMenu, "pref_stattrak", sFormat);
	
	//Preference Sorting Menu
	if (hPreferenceSorting != INVALID_HANDLE)
	{
		CloseHandle(hPreferenceSorting);
		hPreferenceSorting = INVALID_HANDLE;
	}
	
	hPreferenceSorting = CreateMenu(MenuHandle_Preference_Sorting);
	SetMenuTitle(hPreferenceSorting, "%t", "search sorting title");
	SetMenuExitBackButton(hPreferenceSorting, true);
	
	Format(sFormat, sizeof(sFormat), "%t", "none or reset");
	AddMenuItem(hPreferenceSorting, "", sFormat);
	PullDataConfig(hPreferenceSorting, "sort");
	
	//Preference Types Menu
	if (hPreferenceTypes != INVALID_HANDLE)
	{
		CloseHandle(hPreferenceTypes);
		hPreferenceTypes = INVALID_HANDLE;
	}
	
	hPreferenceTypes = CreateMenu(MenuHandle_Preference_Types);
	SetMenuTitle(hPreferenceTypes, "%t", "search types title");
	SetMenuExitBackButton(hPreferenceTypes, true);
	
	Format(sFormat, sizeof(sFormat), "%t", "none or reset");
	AddMenuItem(hPreferenceTypes, "", sFormat);
	PullDataConfig(hPreferenceTypes, "type");
	
	//Preference Grades Menu
	if (hPreferenceGrades != INVALID_HANDLE)
	{
		CloseHandle(hPreferenceGrades);
		hPreferenceGrades = INVALID_HANDLE;
	}
	
	hPreferenceGrades = CreateMenu(MenuHandle_Preference_Grades);
	SetMenuTitle(hPreferenceGrades, "%t", "search grades title");
	SetMenuExitBackButton(hPreferenceGrades, true);
	
	Format(sFormat, sizeof(sFormat), "%t", "none or reset");
	AddMenuItem(hPreferenceGrades, "", sFormat);
	PullDataConfig(hPreferenceGrades, "grade");
}

bool:PullDataConfig(Handle:hMenu, const String:sSection[])
{
	new Handle:hKV = CreateKeyValues("OPSkins_Configurations");
	
	new String:sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "data/opskins_configurations.cfg");
	
	if (!FileToKeyValues(hKV, sFile))
	{
		OPSkins_Log("ERROR: Data configuration file is missing! '%s'", sFile);
		return false;
	}
	
	if (!KvJumpToKey(hKV, sSection))
	{
		OPSkins_Log("ERROR: Missing section in data file: '%s' (Malformed, please fix or re-download it)", sSection);
		return false;
	}
	
	if (!KvGotoFirstSubKey(hKV, false))
	{
		OPSkins_Log("ERROR: Iterating through the configuration file is not possible: '%s' (Malformed, please fix or re-download it)", sSection);
		return false;
	}
	
	if (StrEqual(sSection, "type"))
	{
		IterateHandleSection(hTrie_ConfigData_Types, hKV, hMenu);
	}
	else if (StrEqual(sSection, "grade"))
	{
		IterateHandleSection(hTrie_ConfigData_Grades, hKV, hMenu);
	}
	
	return true;
}

IterateHandleSection(Handle:hTrie, Handle:hKV, Handle:hMenu)
{
	if (hTrie != INVALID_HANDLE) ClearTrie(hTrie);
	do {
		new String:sSectionName[255], String:sSectionValue[255];
		KvGetSectionName(hKV, sSectionName, sizeof(sSectionName));
		KvGetString(hKV, NULL_STRING, sSectionValue, sizeof(sSectionValue));
					
		AddMenuItem(hMenu, sSectionName, sSectionValue);
		SetTrieString(hTrie, sSectionValue, sSectionName);
	} while (KvGotoNextKey(hKV, false));
}

public OnRequestItemPurchase(Handle:hRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode, any:data)
{
	new client = GetClientOfUserId(data);
	
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		OPSkins_Log("ERROR: Issue contacting OPSkins: Status code: %d, Successful: %s", _:eStatusCode, bRequestSuccessful ? "true" : "false");
		return;
	}
	
	new size;
	SteamWorks_GetHTTPResponseBodySize(hRequest, size);
	
	new String:sBody[size];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, size);
	
	new Handle:json = json_load(sBody);
	new created = json_object_get_int(json, "created");
	
	if (created == 401)
	{
		CPrintToChat(client, "%t %t", "plugin tag", "item already purchased");
		return;
	}
	
	CPrintToChat(client, "%t %t", "plugin tag", "item in checkout");
	ShowMOTDPanel(client, "OPSkins - Website", "http://opskins.com/sourcemod.html", MOTDPANEL_TYPE_URL);
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (!IsClientInGame(client) || !bSearchItem[client]) return Plugin_Continue;
	
	if (RestrictSearchCommands(sArgs[0]))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnClientSayCommand_Post(client, const String:sCommand[], const String:sArgs[])
{
	if (!IsClientInGame(client) || !bSearchItem[client] || RestrictSearchCommands(sArgs[0])) return;
	
	if (strlen(sSearchTypes[client]) != 0)
	{
		SearchForItem(client, sArgs[0], PrefData[client][sSorting], sSearchTypes[client], PrefData[client][sGrades], PrefData[client][bStatTrak]);
		sSearchTypes[client][0] = '\0';
	}
	else if (strlen(sSearchGrades[client]) != 0)
	{
		SearchForItem(client, sArgs[0], PrefData[client][sSorting], PrefData[client][sTypes], sSearchGrades[client], PrefData[client][bStatTrak]);
		sSearchGrades[client][0] = '\0';
	}
	else
	{
		SearchForItem(client, sArgs[0], PrefData[client][sSorting], PrefData[client][sTypes], PrefData[client][sGrades], PrefData[client][bStatTrak]);
	}
}

bool:RestrictSearchCommands(const String:sArgs[])
{
	if (StrEqual(sArgs[0], "!search") ||
		StrEqual(sArgs[0], "/search") ||
		StrEqual(sArgs[0], "!searchtype") ||
		StrEqual(sArgs[0], "/searchtype") ||
		StrEqual(sArgs[0], "!searchgrade") ||
		StrEqual(sArgs[0], "/searchgrade"))
	{
		return true;
	}
	return false;
}

SearchForItem(client, const String:sSearch_Source[], const String:sSorting_Source[], const String:sTypes_Source[], const String:sGrades_Source[], bool:bStatTrak_Source = false)
{
	CPrintToChat(client, "%t %t", "plugin tag", "searching for item", sSearch_Source);
	bSearchItem[client] = true;
	
	//http://opskins.com/api/v1.php?request=OPSKINS_SEARCH&key=KEY
	//&param = Search Text.
	//&st = bool:StatTrak items
	//&min = minimum amount of money to search in.
	//&max = maximum amount of money to search in.
	//&sort = sorting options. (specified in the client settings)
	//&type = types of items to search for. (specified in the built-in array)
	//&grade = upgrades for items. (specified in the built-in array)
	new Handle:request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, OPSKINS_URL);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "request", OPSKINS_SEARCH);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "key", cv_sAPIKey);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "param", sSearch_Source);
	
	if (strlen(sSorting_Source) != 0)
	{
		SteamWorks_SetHTTPRequestGetOrPostParameter(request, "sort", sSorting_Source);
	}
	if (strlen(sTypes_Source) != 0)
	{
		SteamWorks_SetHTTPRequestGetOrPostParameter(request, "type", sTypes_Source);
	}
	
	if (strlen(sGrades_Source) != 0)
	{
		SteamWorks_SetHTTPRequestGetOrPostParameter(request, "grade", sGrades_Source);
	}
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "st", bStatTrak_Source ? "1" : "0");
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, GetClientUserId(client));
	WritePackString(hPack, sSearch_Source);
	SteamWorks_SetHTTPRequestContextValue(request, hPack);
	
	SteamWorks_SetHTTPCallbacks(request, OnRequestItemSearch);
	SteamWorks_SendHTTPRequest(request);
}

public OnRequestItemSearch(Handle:hRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode, any:data)
{
	ResetPack(data);
	
	new client = GetClientOfUserId(ReadPackCell(data));
	
	new String:sSearch[64];
	ReadPackString(data, sSearch, sizeof(sSearch));
	
	CloseHandle(data);
	
	if (!bSearchItem[client]) return;
	
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		OPSkins_Log("ERROR: Issue contacting OPSkins: Status code: %d, Successful: %s", _:eStatusCode, bRequestSuccessful ? "true" : "false");
		return;
	}
	
	new size;
	SteamWorks_GetHTTPResponseBodySize(hRequest, size);
	
	new String:sBody[size];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, size);
	
	new String:sError[512], iLine, iColumn;
	new Handle:hOBJ = json_load_ex(sBody, sError, sizeof(sError), iLine, iColumn);
	
	if (hOBJ == INVALID_HANDLE)
	{
		OPSkins_Log("ERROR: Issue parsing JSON data from memory during item search: '%s' Line: %i Column: %i", sError, iLine, iColumn);
		return;
	}
	
	new Handle:hMenu = CreateMenu(MenuHandle_SearchResults);
	SetMenuTitle(hMenu, "%t", "results from search title", sSearch);
	SetMenuExitBackButton(hMenu, true);
	
	new Handle:hKV = CreateKeyValues("OPSkins_SearchResults");
	JSONToKeyValues("Main", hOBJ, hKV);
	
	KvJumpToKey(hKV, "Main");
	KvJumpToKey(hKV, "success");
	
	KvGotoFirstSubKey(hKV, false);
	
	do {
		new String:sID2[32];
		KvGetString(hKV, "id", sID2, sizeof(sID2));
		
		new String:sName2[128];
		KvGetString(hKV, "market_name", sName2, sizeof(sName2));
		
		if (strlen(sName2) == 0) continue;
		
		new String:sAmount2[32];
		KvGetString(hKV, "amount", sAmount2, sizeof(sAmount2));
		
		new String:sDisplay[255];
		Format(sDisplay, sizeof(sDisplay), "%s [%s OP]", sName2, sAmount2);
		AddMenuItem(hMenu, sID2, sDisplay);
	} while (KvGotoNextKey(hKV, false));
		
	if (GetMenuItemCount(hMenu) > 0)
	{
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
	else
	{
		CPrintToChat(client, "%t %t", "plugin tag", "no items found via search", sSearch);
	}
	
	CloseHandle(hKV);
	CloseHandle(hOBJ);
	
	bSearchItem[client] = false;
	CPrintToChat(client, "%t %t", "plugin tag", "search complete");
}
/////////////////////////////////////////////////////////
//Menu Handlers

//Main Menu
public MenuHandle_MainMenu(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "Browse_Latest"))
			{
				DisplayMenu(hBrowseLatest, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(sInfo, "Search"))
			{
				DisplayMenu(hSearchMain, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(sInfo, "Preference_Settings"))
			{
				DisplayMenu(hPreferencesMenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Latest Entries Menu
public MenuHandle_LatestEntries(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));
			AddItemToCartRequest(param1, sInfo);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hMainMenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Search Main Menu
public MenuHandle_SearchMain(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "search_item"))
			{
				if (bSearchItem[param1])
				{
					CPrintToChat(param1, "%t %t", "plugin tag", "search in progress");
					DisplayMenu(hSearchMain, param1, MENU_TIME_FOREVER);
					return;
				}
				
				bSearchItem[param1] = true;
				CPrintToChat(param1, "%t %t", "plugin tag", "search in chat");
			}
			else if (StrEqual(sInfo, "search_categories"))
			{
				DisplayMenu(hSearchTypes, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(sInfo, "search_grades"))
			{
				DisplayMenu(hSearchGrades, param1, MENU_TIME_FOREVER);
			}
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hMainMenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Search Results Menu
public MenuHandle_SearchResults(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));
			AddItemToCartRequest(param1, sInfo);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hSearchMain, param1, MENU_TIME_FOREVER);
			}
		}
	case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}

//Search Types Menu
public MenuHandle_Search_Types(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			if (bSearchItem[param1])
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "search in progress");
				DisplayMenu(hSearchMain, param1, MENU_TIME_FOREVER);
				return;
			}
			
			new String:sInfo[32], String:sDisplay[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
			strcopy(sSearchTypes[param1], sizeof(sSearchTypes[]), sInfo);
			CPrintToChat(param1, "%t %t", "plugin tag", "search in chat type", sDisplay);
			bSearchItem[param1] = true;
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hSearchMain, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Search Grades Menu
public MenuHandle_Search_Grades(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			if (bSearchItem[param1])
			{
				CPrintToChat(param1, "%t %t", "plugin tag", "search in progress");
				DisplayMenu(hSearchMain, param1, MENU_TIME_FOREVER);
				return;
			}
			
			new String:sInfo[32], String:sDisplay[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
			strcopy(sSearchGrades[param1], sizeof(sSearchGrades[]), sInfo);
			CPrintToChat(param1, "%t %t", "plugin tag", "search in chat grade", sDisplay);
			bSearchItem[param1] = true;
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hSearchMain, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Preferences & Settings Menu
public MenuHandle_PreferencesMenu(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "pref_sorts"))
			{
				DisplayMenu(hPreferenceSorting, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(sInfo, "pref_types"))
			{
				DisplayMenu(hPreferenceTypes, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(sInfo, "pref_grades"))
			{
				DisplayMenu(hPreferenceGrades, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(sInfo, "pref_stattrak"))
			{
				switch (PrefData[param1][bStatTrak])
				{
					case true:
						{
							SetClientCookie(param1, g_hStatTrak, "0");
							PrefData[param1][bStatTrak] = false;
						}
					case false:
						{
							SetClientCookie(param1, g_hStatTrak, "1");
							PrefData[param1][bStatTrak] = true;
						}
				}
				
				CPrintToChat(param1, "%t %t", "plugin tag", "stattrak update message", PrefData[param1][bStatTrak] ? "ON" : "OFF");
				DisplayMenu(hPreferencesMenu, param1, MENU_TIME_FOREVER);
			}
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hMainMenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Item Sorting Menu
public MenuHandle_Preference_Sorting(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32], String:sDisplay[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
			CPrintToChat(param1, "%t %t", "plugin tag", "sorting option set", sDisplay);
			SetClientCookie(param1, g_hSorting, sInfo);
			DisplayMenu(hPreferenceSorting, param1, MENU_TIME_FOREVER);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hPreferencesMenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Item Types Menu
public MenuHandle_Preference_Types(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32], String:sDisplay[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
			CPrintToChat(param1, "%t %t", "plugin tag", "types option set", sDisplay);
			SetClientCookie(param1, g_hTypes, sInfo);
			DisplayMenu(hPreferenceTypes, param1, MENU_TIME_FOREVER);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hPreferencesMenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Item Grades Menu
public MenuHandle_Preference_Grades(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:sInfo[32], String:sDisplay[64];
			GetMenuItem(hMenu, param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
			CPrintToChat(param1, "%t %t", "plugin tag", "grades option set", sDisplay);
			SetClientCookie(param1, g_hGrades, sInfo);
			DisplayMenu(hPreferenceGrades, param1, MENU_TIME_FOREVER);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(hPreferencesMenu, param1, MENU_TIME_FOREVER);
			}
		}
	}
}

//Menu Handles End
/////////////////////////////////////////////////////////

AddItemToCartRequest(client, const String:sItemID[])
{
	new String:sSteamID[32];
	GetClientAuthString(client, sSteamID, sizeof(sSteamID));
	
	new String:sCommunityID[32];
	GetCommunityID(sSteamID, sCommunityID, sizeof(sCommunityID));
	
	//http://opskins.com/api/v1.php?request=OPSKINS_ADDTOCART&key=KEY&id64=64ID&item_id=ITEMID
	new Handle:request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, OPSKINS_URL);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "request", OPSKINS_ADDTOCART);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "key", cv_sAPIKey);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "id64", sCommunityID);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "item_id", sItemID);
	
	SteamWorks_SetHTTPRequestContextValue(request, GetClientUserId(client));
	
	SteamWorks_SetHTTPCallbacks(request, OnRequestItemPurchase);
	SteamWorks_SendHTTPRequest(request);
}

OPSkins_Log(const String:sFormat[], any:...)
{
	new String:sLog[1024];
	VFormat(sLog, sizeof(sLog), sFormat, 2);

	new String:sDate[20];
	FormatTime(sDate, sizeof(sDate), "%Y-%m-%d", GetTime());

	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "logs/OPSkins_%s.log", sDate);
	LogToFileEx(sPath, "%s", sLog);
}

ReloadLatestEntries()
{
	if (hBrowseLatest != INVALID_HANDLE)
	{
		OPSkins_Log("ALERT: Rebuilding latest entries with %i items...", cv_iMaxEntries);
		RemoveAllMenuItems(hBrowseLatest);
		for (new i = 0; i < cv_iMaxEntries; i++)
		{
			new String:sDisplay[256];
			Format(sDisplay, sizeof(sDisplay), "%s [%s OP]", ItemsData[i][sName], ItemsData[i][sAmount]);
			AddMenuItem(hBrowseLatest, ItemsData[i][sID], sDisplay);
		}
		OPSkins_Log("ALERT: Rebuilding of latest entries complete!");
	}
}

bool:GetCommunityID(String:AuthID[], String:FriendID[], size)
{
	if(strlen(AuthID) < 11 || AuthID[0]!='S' || AuthID[6]=='I')
	{
		FriendID[0] = 0;
		return false;
	}
	new iUpper = 765611979;
	new iFriendID = StringToInt(AuthID[10])*2 + 60265728 + AuthID[8]-48;
	new iDiv = iFriendID/100000000;
	new iIdx = 9-(iDiv?iDiv/10+1:0);
	iUpper += iDiv;
	IntToString(iFriendID, FriendID[iIdx], size-iIdx);
	iIdx = FriendID[9];
	IntToString(iUpper, FriendID, size);
	FriendID[9] = iIdx;
	return true;
}

//Convert JSON to Keyvalues. (Numerous reasons why we're doing this)
public JSONToKeyValues(String:sKey[], Handle:hObj, Handle:hKV)
{
	switch(json_typeof(hObj))
	{
	case JSON_OBJECT:
		{
			KvJumpToKey(hKV, sKey, true);
			IterateJsonObject(hObj, hKV);
			KvGoBack(hKV);
		}
	case JSON_ARRAY:
		{
			KvJumpToKey(hKV, sKey, true);
			IterateJsonArray(hObj, hKV);
			KvGoBack(hKV);
		}
	case JSON_STRING:
		{
			new String:sString[1024];
			json_string_value(hObj, sString, sizeof(sString));
			KvSetString(hKV, sKey, sString);
		}
	case JSON_INTEGER:
		{
			KvSetNum(hKV, sKey, json_integer_value(hObj));
		}
	case JSON_REAL:
		{
			KvSetFloat(hKV, sKey, json_real_value(hObj));
		}
	case JSON_TRUE:
		{
			KvSetNum(hKV, sKey, 1);
		}
	case JSON_FALSE:
		{
			KvSetNum(hKV, sKey, 0);
		}
	case JSON_NULL:
		{
			KvSetString(hKV, sKey, "");
		}
	}
}

public IterateJsonArray(Handle:hArray, Handle:hKV)
{
	for (new i = 0; i < json_array_size(hArray); i++)
	{
		new Handle:hValue = json_array_get(hArray, i);
		new String:sElement[4];
		IntToString(i, sElement, sizeof(sElement));
		JSONToKeyValues(sElement, hValue, hKV);
		
		CloseHandle(hValue);
	}
}

public IterateJsonObject(Handle:hObj, Handle:hKV)
{
	new Handle:hIterator = json_object_iter(hObj);
	
	while(hIterator != INVALID_HANDLE)
	{
		new String:sKey[128];
		json_object_iter_key(hIterator, sKey, sizeof(sKey));
		
		new Handle:hValue = json_object_iter_value(hIterator);
		
		JSONToKeyValues(sKey, hValue, hKV);
		
		CloseHandle(hValue);
		hIterator = json_object_iter_next(hObj, hIterator);
	}
}
///////////////////////////////////////////////////