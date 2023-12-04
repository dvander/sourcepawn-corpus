/*
	Author ☠ ÄйӃи ☠ aka Райский
	VK: https://vk.com/id208053124
	Создана 15.12.2021
*/
#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <l4d_statistic>

public Plugin myinfo =
{
	name = "[L4D1(2)] Statistic Core",
	author = "AiKi aka Райский",
	description = "Keeping statistics of certain player actions on the L4D1(2) server",
	version = "1.1.0",
	url = "https://vk.com/id208053124"
};

bool g_bPrintToChat, 
	g_bEndRound,
	g_bGameTime,
	g_bL4D2 = false;

char g_sTablName[4][32],
	g_sPlayerRankName[MAXPLAYERS + 1][32],
	g_sFile[4][PLATFORM_MAX_PATH],
	g_sBasicViewTop[64];

Database g_db;
ArrayList g_dbcache;

int g_iPlayerData[MAXPLAYERS + 1][IDATA],
	g_iTempKills[MAXPLAYERS + 1],
	g_iHitBox[MAXPLAYERS + 1][HITBOXES],
	g_iCountPlayers,
	g_iAdminFlags,
	g_iCountItemFire[MAXPLAYERS + 1][IWEAPON],
	g_iCountDataKills[MAXPLAYERS + 1][IDATAKILLS];

Handle g_hTimer[MAXPLAYERS + 1],
	g_hUpdateTimer[MAXPLAYERS + 1];
KeyValues g_kvRanks;

static Handle g_hl4d_statistic_loaded;

static const char g_sWeaponList[][] =
{
	"pistol",
	"pistol_magnum",
	"autoshotgun",
	"shotgun_chrome",
	"pumpshotgun",
	"shotgun_spas",
	"smg",
	"smg_mp5",
	"smg_silenced",
	"rifle_ak47",
	"rifle_sg552",
	"rifle",
	"rifle_m60",
	"rifle_desert",
	"hunting_rifle",
	"sniper_military",
	"sniper_awp",
	"sniper_scout",
	"weapon_grenade_launcher",
	"molotov",
	"pipe_bomb",
	"vomitjar",

	"melee",
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"katana",
	"knife",
	"machete",
	"tonfa",

	"pain_pills",
	"adrenaline",
	"defibrillator",
	"first_aid_kit",
};

Handle g_fwdOnBuild;
Menu g_build_instance = null;
int g_build_client;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hl4d_statistic_loaded = CreateGlobalForward("L4D_Statistic_Loaded", ET_Ignore);

	g_fwdOnBuild = CreateGlobalForward("ST_OnBuild", ET_Ignore);
	CreateNative("ST_RegisterItem", Native_RegisterItem);

	CreateNative("GetPlayerData", Native_GetPlayerData);
	CreateNative("GetPlayerRankName", Native_GetPlayerRankName);
	CreateNative("GetPlayerHits", Native_GetPlayerHits);
	CreateNative("GetPlayerCountItemFire", Native_GetPlayerCountItemFire);
	CreateNative("GetPlayerCountDataKills", Native_GetPlayerCountDataKills);

	EngineVersion iEngine = GetEngineVersion();
	if(iEngine == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
		PrintToServer("[Left 4 Dead 2] Statistic - Started launch");
	}
	else if(iEngine == Engine_Left4Dead) PrintToServer("[Left 4 Dead] Statistic - Started launch");
	else SetFailState("Statistic plugin should only be used in the game Left 4 Dead 1(2)");

	RegPluginLibrary("l4d_statistic");
	return APLRes_Success;
}


void L4D_Statistic_Loaded()
{
	Call_StartForward(g_hl4d_statistic_loaded);
	Call_Finish();
}

public int Native_RegisterItem(Handle plugin, int numParams)
{
	if(g_build_instance == null)
		return ThrowNativeError(SP_ERROR_NATIVE, "ST_RegisterItem must called inside ST_OnBuild forward only!");
	
	char name[64];
	GetPluginFilename(plugin, name, sizeof name);
	
	if(Event_Item(name, g_build_client) == false)
		return 0;
	
	int length;
	int error = GetNativeStringLength(1, length);
	if(error != SP_ERROR_NONE)
		return ThrowNativeError(error, NULL_STRING);
	
	length += 1;
	char[] display = new char[length];
	GetNativeString(1, display, length);
	
	int style = GetNativeCell(2);
	
	if(g_build_instance.AddItem(name, display, style) == false)
		return ThrowNativeError(SP_ERROR_NATIVE, "Unable to add menu item (\"%s\", \"%s\", %i)", name, display, style);

	return 1;
}

bool ResolvePrivateForward(const char[] owner, const char[] event, Handle &plugin, Function &func)
{
	return (plugin = FindPluginByFile(owner)) != null && (func = GetFunctionByName(plugin, event)) != INVALID_FUNCTION;
}

void PerformEvent_Select(const char[] owner, int client)
{
	Handle plugin;
	Function func;
	if(ResolvePrivateForward(owner, "ST_OnSelectItem", plugin, func) == false)
		return;

	Call_StartFunction(plugin, func);
	Call_PushCell(client);
	Call_Finish();
}

void PerformEvent_Draw(const char[] owner, int client, int &style)
{
	Handle plugin;
	Function func;
	if (ResolvePrivateForward(owner, "ST_OnDrawItem", plugin, func) == false)
		return;

	Call_StartFunction(plugin, func);
	Call_PushCell(client);
	Call_PushCellRef(style);
	Call_Finish();
}

void PerformBuild(Menu menu, int client)
{
	g_build_client = client;
	g_build_instance = menu;
	Call_StartForward(g_fwdOnBuild);
	Call_Finish();
	g_build_instance = null;
}

Menu BuildMenu(int client)
{
	Menu menu = new Menu(Menu_Handler, MENU_ACTIONS_DEFAULT | MenuAction_DrawItem);
	menu.SetTitle("%T", "ModularMenuTitle", client);
	if(GetMenuItemCount(menu) < 0)
	{
		char sBuf[64];
		FormatEx(sBuf, sizeof sBuf, "%T", "NotModular", client);
		menu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	}
	else PerformBuild(menu, client);
	
	return menu;
}

void ShowModularMenu(int client)
{
	Menu menu = BuildMenu(client);
	menu.Display(client, 0);
}

public bool Event_Item(const char[] name, int client)
{
	return true;
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_DrawItem:
		{
			char name[64];
			int style;
			menu.GetItem(param, name, sizeof name, style);
			
			PerformEvent_Draw(name, client, style);
			
			return style;
		}
		case MenuAction_Select:
		{
			char name[64];
			menu.GetItem(param, name, sizeof name);
			PerformEvent_Select(name, client);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public int Native_GetPlayerData(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int data = GetNativeCell(2);
	if(!IsClient(client))
		ThrowNativeError(7, "Client index %i is invalid", client);
	return g_iPlayerData[client][data];
}

public int Native_GetPlayerRankName(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if(!IsClient(client))
		ThrowNativeError(7, "Client index %i is invalid", client);

	SetNativeString(2, g_sPlayerRankName[client], GetNativeCell(3), false);
	return 0;
}

public int Native_GetPlayerHits(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int hit = GetNativeCell(2);
	if(!IsClient(client))
		ThrowNativeError(7, "Client index %i is invalid", client);
	return g_iHitBox[client][hit];
}

public int Native_GetPlayerCountItemFire(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int index = GetNativeCell(2);
	if(!IsClient(client))
		ThrowNativeError(7, "Client index %i is invalid", client);
	return g_iCountItemFire[client][index];
}

public int Native_GetPlayerCountDataKills(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int index = GetNativeCell(2);
	if(!IsClient(client))
		ThrowNativeError(7, "Client index %i is invalid", client);
	return g_iCountDataKills[client][index];
}

public void OnPluginStart()
{
	BuildPath(Path_SM, g_sFile[0], PLATFORM_MAX_PATH, "configs/l4d_statistic/ranks.ini");
	BuildPath(Path_SM, g_sFile[1], PLATFORM_MAX_PATH, "configs/l4d_statistic/settings.ini");
	BuildPath(Path_SM, g_sFile[2], PLATFORM_MAX_PATH, "configs/l4d_statistic/top_menu.ini");
	BuildPath(Path_SM, g_sFile[3], PLATFORM_MAX_PATH, "configs/l4d_statistic/admin_menu.ini");

	LoadAllConfigs();

	g_dbcache = new ArrayList(ByteCountToCells(33));
	if(SQL_CheckConfig("l4d_statistic")) 
		Database.Connect(Statistic_DatabaseConnect, "l4d_statistic");
	else 
		SetFailState("Section \"l4d_statistic\" not found in databases.cfg"); 


	HookEvent("round_start", ev_round_start);
	HookEvent("finale_win", ev_finale_win);
	HookEvent("round_end", ev_round_end);
	HookEvent("player_death", ev_player_death);
	HookEvent("witch_killed", ev_witch_killed);
	if(g_bL4D2)
	{
		HookEvent("charger_killed", ev_infected_death);
		HookEvent("spitter_killed", ev_infected_death);
		HookEvent("jockey_killed", ev_infected_death);
	}
	HookEvent("hunter_headshot", ev_infected_death);
	HookEvent("infected_death", ev_infected_death);
	HookEvent("tank_killed", ev_infected_death);
	HookEvent("boomer_exploded", ev_infected_death);

	HookEvent("pills_used", ev_med_used);
	HookEvent("adrenaline_used", ev_med_used);
	HookEvent("defibrillator_used", ev_med_used);
	HookEvent("heal_success", ev_med_used);

	HookEventEx("player_hurt",	ev_player_hurt);
	HookEventEx("weapon_fire", ev_weapon_fire);
	HookEventEx("infected_hurt", ev_infected_hurt);

	RegConsoleCmd("sm_st", Command_St, "Show statistics");
	RegConsoleCmd("sm_rank", Command_St, "Show statistics");
	RegConsoleCmd("sm_top", Command_Top, "Show top players");

	RegConsoleCmd("sm_resetmyrank", ResetMyCommand, "Reset my statistics");

	LoadTranslations("l4d_statistic.phrases");
}

public void OnAllPluginsLoaded()
{
	L4D_Statistic_Loaded();
}

public void Statistic_DatabaseConnect(Database db, const char[] error, any data)
{
	if(db == null)
		SetFailState("[L4D1(2)] Statistic No database connection: %s", error);
	else
	{
		char sCformat[4096];
		g_db = db;
		db.SetCharset("utf8");
		db.Format(sCformat, sizeof sCformat, "CREATE TABLE IF NOT EXISTS `%s` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `nicname` VARCHAR(64) NOT NULL, `steamid` VARCHAR(32) NOT NULL, `rank` VARCHAR(32) NOT NULL, `gametime` int(11) NOT NULL, `finalewin` int(11) NOT NULL, `PlayerDead` int(11) NOT NULL, `Player_Fire` int(11) NOT NULL, `Player_Hurt` int(11) NOT NULL, `Player_Damage` int(11) NOT NULL);", g_sTablName[0]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		db.Format(sCformat, sizeof sCformat, "CREATE TABLE IF NOT EXISTS `%s` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `steamid` VARCHAR(32) NOT NULL, `NULL_HITBOX` int(11) NOT NULL, `HEAD` int(11) NOT NULL, `CHEST` int(11) NOT NULL, `STOMACH` int(11) NOT NULL, `LEFT_ARM` int(11) NOT NULL, `RIGHT_ARM` int(11) NOT NULL, `LEFT_LEG` int(11) NOT NULL, `RIGHT_LEG` int(11) NOT NULL);", g_sTablName[1]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		db.Format(sCformat, sizeof sCformat, "CREATE TABLE IF NOT EXISTS `%s` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `steamid` VARCHAR(32) NOT NULL, `pistol` int(11) NOT NULL, `pistol_magnum` int(11) NOT NULL, `autoshotgun` int(11) NOT NULL, `shotgun_chrome` int(11) NOT NULL, `pumpshotgun` int(11) NOT NULL, `shotgun_spas` int(11) NOT NULL, `smg` int(11) NOT NULL, `smg_mp5` int(11) NOT NULL, `smg_silenced` int(11) NOT NULL, `rifle_ak47` int(11) NOT NULL, `rifle_sg552` int(11) NOT NULL, `rifle` int(11) NOT NULL, `rifle_m60` int(11) NOT NULL, `rifle_desert` int(11) NOT NULL, `hunting_rifle` int(11) NOT NULL, `sniper_military` int(11) NOT NULL, `sniper_awp` int(11) NOT NULL, `sniper_scout` int(11) NOT NULL, `weapon_grenade_launcher` int(11) NOT NULL, `molotov` int(11) NOT NULL, `pipe_bomb` int(11) NOT NULL, `vomitjar` int(11) NOT NULL, `melee` int(11) NOT NULL, `baseball_bat` int(11) NOT NULL, `cricket_bat` int(11) NOT NULL, `crowbar` int(11) NOT NULL, `electric_guitar` int(11) NOT NULL, `fireaxe` int(11) NOT NULL, `frying_pan` int(11) NOT NULL, `katana` int(11) NOT NULL, `knife` int(11) NOT NULL, `machete` int(11) NOT NULL, `tonfa` int(11) NOT NULL, `pain_pills` int(11) NOT NULL, `adrenaline` int(11) NOT NULL, `defibrillator` int(11) NOT NULL, `first_aid_kit` int(11) NOT NULL);", g_sTablName[2]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		db.Format(sCformat, sizeof sCformat, "CREATE TABLE IF NOT EXISTS `%s` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `nicname` VARCHAR(64) NOT NULL, `steamid` VARCHAR(32) NOT NULL, `infected_death` int(11) NOT NULL, `tank_killed` int(11) NOT NULL, `boomer_exploded` int(11) NOT NULL, `hunter_headshot` int(11) NOT NULL, `charger_killed` int(11) NOT NULL, `spitter_killed` int(11) NOT NULL, `jockey_killed` int(11) NOT NULL, `witch_killed` int(11) NOT NULL, `survivor_killed` int(11) NOT NULL);", g_sTablName[3]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		db.Format(sCformat, sizeof sCformat, "ALTER TABLE `%s` ADD UNIQUE(`steamid`);", g_sTablName[0]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		db.Format(sCformat, sizeof sCformat, "ALTER TABLE `%s` ADD UNIQUE(`steamid`);", g_sTablName[1]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		db.Format(sCformat, sizeof sCformat, "ALTER TABLE `%s` ADD UNIQUE(`steamid`);", g_sTablName[2]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		db.Format(sCformat, sizeof sCformat, "ALTER TABLE `%s` ADD UNIQUE(`steamid`);", g_sTablName[3]);
		db.Query(St_SQL_Table, sCformat, _, DBPrio_Normal);

		LoadPlayers();
	}
}

public void OnMapStart()
{
	g_bEndRound = false;
}

public void OnClientPostAdminCheck(int client)
{
	if(IsClient(client))
	{
		ClearDataPlayer(client);
		GetStMySql(client, 0);
		GetStMySql(client, 2, g_sBasicViewTop);
		g_hTimer[client] = CreateTimer(1.0, CounterTime, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		g_hUpdateTimer[client] = CreateTimer(15.0, UpdateSqlTime, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		if(g_bPrintToChat)
			CreateTimer(1.0, WelcomeTime, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action WelcomeTime(Handle timer, any uid)
{
	char sName[MAX_NAME_LENGTH];
	int client = GetClientOfUserId(uid);
	GetClientName(client, sName, MAX_NAME_LENGTH);
	if(g_iPlayerData[client][PlayerTop] <= 0)
		PrintToChatAll("%t","Welcome1", sName);
	else
		PrintToChatAll("%t", "Welcome2", g_sPlayerRankName[client], sName, g_iPlayerData[client][PlayerTop]);

	if(GetGamePlayers() < g_iCountPlayers)
		PrintToChat(client, "%t", "FewPlayers", GetGamePlayers(), g_iCountPlayers);
	return Plugin_Stop;
}

public Action UpdateSqlTime(Handle timer, any uid)
{
	int client = GetClientOfUserId(uid);
	if(!g_bEndRound)
	{
		GetStMySql(client, 1);
		GetStMySql(client, 0);
		GetStMySql(client, 2, g_sBasicViewTop);
		return Plugin_Continue;
	}
	else
	{
		if (g_hUpdateTimer[client] != null)
		{
			KillTimer(g_hUpdateTimer[client]);
			g_hUpdateTimer[client] = null;
		}
	}
	return Plugin_Stop;
}

public Action CounterTime(Handle timer, any uid)
{
	int client = GetClientOfUserId(uid);
	if(!g_bEndRound)
	{
		g_iPlayerData[client][GmameTime]++;
		return Plugin_Continue;
	}
	else
	{
		if (g_hTimer[client] != null)
		{
			KillTimer(g_hTimer[client]);
			g_hTimer[client] = null;
		}
	}
	return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
	GetStMySql(client, 1);
	ClearDataPlayer(client);
}

void ClearDataPlayer(int client)
{
	if(g_hTimer[client] != null)
	{
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = null;
	}

	if(g_hUpdateTimer[client] != null)
	{
		KillTimer(g_hUpdateTimer[client]);
		g_hUpdateTimer[client] = null;
	}
	for(int num = 0; num < IDATA; num++)
		g_iPlayerData[client][num] = 0;
	for(int num = 0; num < HITBOXES; num++)
		g_iHitBox[client][num] = 0;
	for(int num = 0; num < IWEAPON; num++)
		g_iCountItemFire[client][num] = 0;
	for(int num = 0; num < IDATAKILLS; num++)
		g_iCountDataKills[client][num] = 0;
	g_iTempKills[client] = 0;
	g_sPlayerRankName[client] = NULL_STRING;
}

public void St_OnClientPostAdminCheck(Database db, DBResultSet result, const char[] sError, any iUserId)
{
	if(/*result == null || */sError[0])
	{
		LogError("St_OnClientPostAdminCheck: %s", sError);
		return;
	}

	int client = GetClientOfUserId(iUserId);
	if(!IsClient(client))
		return;

	if(result.FetchRow())
	{
		result.FetchString(3, g_sPlayerRankName[client], sizeof g_sPlayerRankName);
		g_iPlayerData[client][GmameTime] = result.FetchInt(4);
		g_iPlayerData[client][FinaleWin] = result.FetchInt(5);
		g_iPlayerData[client][PlayerDead] = result.FetchInt(6);
		g_iPlayerData[client][Player_Fire] = result.FetchInt(7);
		g_iPlayerData[client][Player_Hurt] = result.FetchInt(8);
		g_iPlayerData[client][Player_Damage] = result.FetchInt(9);
	}
	else if(!result.FetchRow())
	{
		char sSteamId[32], nicname[32], sQuery[512];
		GetClientName(client, nicname, sizeof nicname);
		GetClientAuthId(client, AuthId_Steam2, sSteamId, sizeof sSteamId);
		g_db.Format(sQuery, sizeof sQuery, "INSERT INTO `%s` (`nicname`, `steamid`, `rank`, `gametime`, `finalewin`, `PlayerDead`, `Player_Fire`, `Player_Hurt`, `Player_Damage`) VALUES ('%s', '%s', 'Calibration', '0', '0', '0', '0', '0', '0');", g_sTablName[0], nicname, sSteamId);
		g_db.Query(St_SQL_Table, sQuery);
	}
}

public void St_OnClientPostAdminCheckHits(Database db, DBResultSet result, const char[] sError, any iUserId)
{
	if(sError[0])
	{
		LogError("St_OnClientPostAdminCheckHits: %s", sError);
		return;
	}

	int client = GetClientOfUserId(iUserId);
	if(!IsClient(client))
		return;

	if(result.FetchRow())
	{
		for(int num = 0; num < HITBOXES; num++)
			g_iHitBox[client][num] = result.FetchInt(num+2);
	}
	else if(!result.FetchRow())
	{
		char sSteamId[32], sQuery[512];
		GetClientAuthId(client, AuthId_Steam2, sSteamId, sizeof sSteamId);
		g_db.Format(sQuery, sizeof sQuery, "INSERT INTO `%s` (`steamid`, `NULL_HITBOX`, `HEAD`, `CHEST`, `STOMACH`, `LEFT_ARM`, `RIGHT_ARM`, `LEFT_LEG`, `RIGHT_LEG`) VALUES ('%s', '0', '0', '0', '0', '0', '0', '0', '0');", g_sTablName[1], sSteamId);
		g_db.Query(St_SQL_Table, sQuery);
	}
}

public void St_OnClientPostAdminCheckIWEAPON(Database db, DBResultSet result, const char[] sError, any iUserId)
{
	if(sError[0])
	{
		LogError("St_OnClientPostAdminCheckIWEAPON: %s", sError);
		return;
	}

	int client = GetClientOfUserId(iUserId);
	if(!IsClient(client))
		return;

	if(result.FetchRow())
	{
		for(int num = 0; num < IWEAPON; num++)
			g_iCountItemFire[client][num] = result.FetchInt(num+2);
	}
	else if(!result.FetchRow())
	{
		char sSteamId[32], sQuery[2048];
		GetClientAuthId(client, AuthId_Steam2, sSteamId, sizeof sSteamId);
		g_db.Format(sQuery, sizeof sQuery, "INSERT INTO `%s` (`steamid`, `pistol`, `pistol_magnum`, `autoshotgun`, `shotgun_chrome`, `pumpshotgun`, `shotgun_spas`, `smg`, `smg_mp5`, `smg_silenced`, `rifle_ak47`, `rifle_sg552`, `rifle`, `rifle_m60`, `rifle_desert`, `hunting_rifle`, `sniper_military`, `sniper_awp`, `sniper_scout`, `weapon_grenade_launcher`, `molotov`, `pipe_bomb`, `vomitjar`, `melee`, `baseball_bat`, `cricket_bat`, `crowbar`, `electric_guitar`, `fireaxe`, `frying_pan`, `katana`, `knife`, `machete`, `tonfa`, `pain_pills`, `adrenaline`, `defibrillator`, `first_aid_kit`) VALUES ('%s','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0');", g_sTablName[2], sSteamId);
		g_db.Query(St_SQL_Table, sQuery);
	}
}

public void St_OnClientPostAdminCheckIDATAKILLS(Database db, DBResultSet result, const char[] sError, any iUserId)
{
	if(sError[0])
	{
		LogError("St_OnClientPostAdminCheckIDATAKILLS: %s", sError);
		return;
	}

	int client = GetClientOfUserId(iUserId);
	if(!IsClient(client))
		return;

	if(result.FetchRow())
	{
		for(int num = 0; num < IDATAKILLS; num++)
			g_iCountDataKills[client][num] = result.FetchInt(num+3);
	}
	else if(!result.FetchRow())
	{
		char sSteamId[32], nicname[32], sQuery[1024];
		GetClientName(client, nicname, sizeof nicname);
		GetClientAuthId(client, AuthId_Steam2, sSteamId, sizeof sSteamId);
		g_db.Format(sQuery, sizeof sQuery, "INSERT INTO `%s` (`nicname`, `steamid`, `infected_death`, `tank_killed`, `boomer_exploded`, `hunter_headshot`, `charger_killed`, `spitter_killed`, `jockey_killed`, `witch_killed`, `survivor_killed`) VALUES ('%s','%s','0','0','0','0','0','0','0','0','0');", g_sTablName[3], nicname, sSteamId);
		g_db.Query(St_SQL_Table, sQuery);
	}
}

void GetStMySql(int client, int num, char[] data = "infected_death")
{
	char sQuery[2048], sSteamId[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamId, sizeof sSteamId);
	switch(num)
	{
		case 0: // Получить данные
		{
			g_db.Format(sQuery, sizeof sQuery, "SELECT * FROM `%s` WHERE `steamid` = '%s';", g_sTablName[0], sSteamId);
			g_db.Query(St_OnClientPostAdminCheck, sQuery, GetClientUserId(client));

			g_db.Format(sQuery, sizeof sQuery, "SELECT * FROM `%s` WHERE `steamid` = '%s';", g_sTablName[1], sSteamId);
			g_db.Query(St_OnClientPostAdminCheckHits, sQuery, GetClientUserId(client));

			g_db.Format(sQuery, sizeof sQuery, "SELECT * FROM `%s` WHERE `steamid` = '%s';", g_sTablName[2], sSteamId);
			g_db.Query(St_OnClientPostAdminCheckIWEAPON, sQuery, GetClientUserId(client));

			g_db.Format(sQuery, sizeof sQuery, "SELECT * FROM `%s` WHERE `steamid` = '%s';", g_sTablName[3], sSteamId);
			g_db.Query(St_OnClientPostAdminCheckIDATAKILLS, sQuery, GetClientUserId(client));
		}
		case 1: // Обновить данные
		{
			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `rank` = '%s', `gametime`= '%i', `finalewin`= '%i', `PlayerDead` = '%i', `Player_Fire` = '%i', `Player_Hurt` = '%i', `Player_Damage` = '%i' WHERE `steamid` = '%s';", g_sTablName[0], GetNameRanks(client, g_sBasicViewTop), g_iPlayerData[client][GmameTime], g_iPlayerData[client][FinaleWin], g_iPlayerData[client][PlayerDead], g_iPlayerData[client][Player_Fire], g_iPlayerData[client][Player_Hurt], g_iPlayerData[client][Player_Damage], sSteamId);
			g_db.Query(St_SQL_Table, sQuery);

			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `NULL_HITBOX` = '%i', `HEAD`= '%i', `CHEST`= '%i', `STOMACH`= '%i', `LEFT_ARM`= '%i', `RIGHT_ARM`= '%i', `LEFT_LEG` = '%i', `RIGHT_LEG` = '%i' WHERE `steamid` = '%s';", g_sTablName[1], g_iHitBox[client][NULL_HITBOX], g_iHitBox[client][HEAD], g_iHitBox[client][CHEST], g_iHitBox[client][STOMACH], g_iHitBox[client][LEFT_ARM], g_iHitBox[client][RIGHT_ARM], g_iHitBox[client][LEFT_LEG], g_iHitBox[client][RIGHT_LEG], sSteamId);
			g_db.Query(St_SQL_Table, sQuery);

			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `pistol` = '%i', `pistol_magnum`= '%i', `autoshotgun`= '%i', `shotgun_chrome`= '%i', `pumpshotgun`= '%i', `shotgun_spas`= '%i', `smg` = '%i', `smg_mp5` = '%i', `smg_silenced` = '%i', `rifle_ak47` = '%i', `rifle_sg552` = '%i', `rifle` = '%i', `rifle_m60` = '%i', `rifle_desert` = '%i', `hunting_rifle` = '%i', `sniper_military` = '%i', `sniper_awp` = '%i', `sniper_scout` = '%i', `weapon_grenade_launcher` = '%i', `molotov` = '%i', `pipe_bomb` = '%i', `vomitjar` = '%i', `melee` = '%i', `baseball_bat` = '%i', `cricket_bat` = '%i', `crowbar` = '%i', `electric_guitar` = '%i', `fireaxe` = '%i', `frying_pan` = '%i', `katana` = '%i', `knife` = '%i', `machete` = '%i', `tonfa` = '%i', `pain_pills` = '%i', `adrenaline` = '%i', `defibrillator` = '%i', `first_aid_kit` = '%i'  WHERE `steamid` = '%s';", g_sTablName[2], g_iCountItemFire[client][pistol], g_iCountItemFire[client][pistol_magnum], g_iCountItemFire[client][autoshotgun], g_iCountItemFire[client][shotgun_chrome], g_iCountItemFire[client][pumpshotgun], g_iCountItemFire[client][shotgun_spas], g_iCountItemFire[client][smg], g_iCountItemFire[client][smg_mp5], g_iCountItemFire[client][smg_silenced], g_iCountItemFire[client][rifle_ak47], g_iCountItemFire[client][rifle_sg552],  g_iCountItemFire[client][rifle], g_iCountItemFire[client][rifle_m60], g_iCountItemFire[rifle_desert][smg_mp5], g_iCountItemFire[client][hunting_rifle], g_iCountItemFire[client][sniper_military], g_iCountItemFire[client][sniper_awp], g_iCountItemFire[client][sniper_scout], g_iCountItemFire[client][weapon_grenade_launcher], g_iCountItemFire[client][molotov], g_iCountItemFire[client][pipe_bomb], g_iCountItemFire[client][vomitjar], g_iCountItemFire[client][melee], g_iCountItemFire[client][baseball_bat], g_iCountItemFire[client][cricket_bat], g_iCountItemFire[client][crowbar], g_iCountItemFire[client][electric_guitar], g_iCountItemFire[client][fireaxe], g_iCountItemFire[client][frying_pan], g_iCountItemFire[client][katana], g_iCountItemFire[client][knife], g_iCountItemFire[client][machete], g_iCountItemFire[client][tonfa], g_iCountItemFire[client][pain_pills], g_iCountItemFire[client][adrenaline], g_iCountItemFire[client][defibrillator], g_iCountItemFire[client][first_aid_kit], sSteamId);
			g_db.Query(St_SQL_Table, sQuery);

			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `infected_death` = '%i', `tank_killed`= '%i', `boomer_exploded`= '%i', `hunter_headshot`= '%i', `charger_killed`= '%i', `spitter_killed`= '%i', `jockey_killed` = '%i', `witch_killed` = '%i', `survivor_killed` = '%i' WHERE `steamid` = '%s';", g_sTablName[3], g_iCountDataKills[client][infected_death], g_iCountDataKills[client][tank_killed], g_iCountDataKills[client][boomer_exploded], g_iCountDataKills[client][hunter_headshot], g_iCountDataKills[client][charger_killed], g_iCountDataKills[client][spitter_killed], g_iCountDataKills[client][jockey_killed], g_iCountDataKills[client][witch_killed], g_iCountDataKills[client][survivor_killed], sSteamId);
			g_db.Query(St_SQL_Table, sQuery);
		}
		case 2:
		{
			// Получить топ позицию
			g_db.Format(sQuery, sizeof sQuery, "SELECT COUNT(*) FROM `%s` WHERE `%s` >= (SELECT `%s` FROM `%s` WHERE `steamid` = '%s');", g_sTablName[3], data, data, g_sTablName[3], sSteamId);
			g_db.Query(St_GetPosTop, sQuery, GetClientUserId(client));
		}
	}
}

// Обновить прохождение карты
public Action ev_finale_win(Event event, const char[] name, bool dontBroadcast)
{
	if(GetGamePlayers() < g_iCountPlayers)
		return Plugin_Handled;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClient(i))
		{
			g_iPlayerData[i][FinaleWin]++;
			GetStMySql(i, 1);
		}
	}
	return Plugin_Handled;
}

public Action ev_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if(GetGamePlayers() < g_iCountPlayers)
		return Plugin_Handled;

	if(IsClient(attacker) && IsClient(client) && attacker != client && GetClientTeam(attacker) == 2 && GetClientTeam(client) == 2)
	{
		g_iCountDataKills[attacker][survivor_killed]++;
		GetStMySql(attacker, 1);
	}

	if(IsClient(client))
	{
		g_iPlayerData[client][PlayerDead]++;
		GetStMySql(client, 1);
	}
	return Plugin_Handled;
}

public Action ev_round_start(Event event, const char[] name, bool dontBroadcast)
{
	g_bEndRound = false;
	if(GetGamePlayers() < g_iCountPlayers)
		return Plugin_Handled;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClient(client))
		{
			if (g_hTimer[client] != null)
			{
				KillTimer(g_hTimer[client]);
				g_hTimer[client] = null;
			}
			if (g_hUpdateTimer[client] != null)
			{
				KillTimer(g_hUpdateTimer[client]);
				g_hUpdateTimer[client] = null;
			}
			g_hTimer[client] = CreateTimer(1.0, CounterTime, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			g_hUpdateTimer[client] = CreateTimer(15.0, UpdateSqlTime, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			GetStMySql(client, 1);
			GetStMySql(client, 0);
		}
	}
	return Plugin_Handled;
}

public Action ev_round_end(Event event, const char[] name, bool dontBroadcast)
{
	g_bEndRound = true;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClient(i))
			GetStMySql(i, 1);
	}
	return Plugin_Handled;
}

public Action ev_witch_killed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!IsClient(client) || GetGamePlayers() < g_iCountPlayers)
		return Plugin_Handled;

	g_iCountDataKills[client][witch_killed]++;

	return Plugin_Handled;
}

public Action ev_infected_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));

	if(!IsClient(client) || GetGamePlayers() < g_iCountPlayers)
		return Plugin_Handled;

	char sEvent[32];
	event.GetName(sEvent, sizeof sEvent);

	if(StrEqual(sEvent, "infected_death", true))
		g_iCountDataKills[client][infected_death]++;
	else if(StrEqual(sEvent, "tank_killed", true)) 
		g_iCountDataKills[client][tank_killed]++;
	else if(StrEqual(sEvent, "boomer_exploded", true))
		g_iCountDataKills[client][boomer_exploded]++;
	else if(StrEqual(sEvent, "hunter_headshot", true))
		g_iCountDataKills[client][hunter_headshot]++;
	if(g_bL4D2)
	{
		if(StrEqual(sEvent, "charger_killed", true))
			g_iCountDataKills[client][charger_killed]++;
		else if(StrEqual(sEvent, "spitter_killed", true))
			g_iCountDataKills[client][spitter_killed]++;
		else if(StrEqual(sEvent, "jockey_killed", true))
			g_iCountDataKills[client][jockey_killed]++;
	}

	return Plugin_Handled;
}


public void ev_med_used(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!IsClient(client) || GetGamePlayers() < g_iCountPlayers)
		return;

	char sEvent[32];
	event.GetName(sEvent, sizeof sEvent);

	if(StrEqual(sEvent, "pills_used", true))
		g_iCountItemFire[client][pain_pills]++;
	else if(StrEqual(sEvent, "adrenaline_used", true))
		g_iCountItemFire[client][adrenaline]++;
	else if(StrEqual(sEvent, "defibrillator", true))
		g_iCountItemFire[client][defibrillator]++;
	else if(StrEqual(sEvent, "heal_success", true))
		g_iCountItemFire[client][first_aid_kit]++;
	return;
}

public Action ev_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!IsClient(attacker) || GetGamePlayers() < g_iCountPlayers)
		return Plugin_Handled;

	g_iPlayerData[attacker][Player_Hurt]++;
	g_iPlayerData[attacker][Player_Damage] += event.GetInt("dmg_health");

	int hit_group = event.GetInt("hitgroup");
	if(hit_group == 0)
		return Plugin_Handled;

	g_iHitBox[attacker][hit_group]++;

	return Plugin_Handled;
}

public Action ev_infected_hurt(Event event, const char[] name, bool dontBroadcast)
{

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if(!IsClient(attacker) || GetGamePlayers() < g_iCountPlayers)
		return Plugin_Handled;

	g_iPlayerData[attacker][Player_Hurt]++;
	g_iPlayerData[attacker][Player_Damage] += event.GetInt("amount");

	int hit_group = event.GetInt("hitgroup");
	if(hit_group == 0)
		return Plugin_Handled;

	g_iHitBox[attacker][hit_group]++;

	return Plugin_Handled;
}

public void ev_weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsClient(client))
		return;

	char sWeapon[64];
	event.GetString("weapon", sWeapon, sizeof sWeapon);
	if(StrEqual(sWeapon, "pain_pills") || StrEqual(sWeapon,"adrenaline") || StrEqual(sWeapon,"defibrillator") || StrEqual(sWeapon,"first_aid_kit"))
		return;

	if(StrEqual(sWeapon, "melee"))
	{
		g_iCountItemFire[client][melee]++;
		char sWeapons[32];
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", sWeapons, sizeof sWeapons);
		SetUseWeapon(client, sWeapons);
		return;
	}

	SetUseWeapon(client, sWeapon);
	g_iPlayerData[client][Player_Fire]++;
	return;
}

void SetUseWeapon(int client, const char[] sWeapon)
{
	for(int weapon = 0; weapon < IWEAPON; weapon++)
	{
		if(!strcmp(sWeapon, g_sWeaponList[weapon]))
			g_iCountItemFire[client][weapon]++;
	}
}

public Action ResetMyCommand(int client, int args)
{
	char sQuery[2048], sSteam[32];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof sSteam);
	g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `rank` = 'none', `gametime`= '0', `finalewin`= '0', `PlayerDead` = '0', `Player_Fire` = '0', `Player_Hurt` = '0', `Player_Damage` = '0' WHERE `steamid` = '%s'", g_sTablName[0], sSteam);
	g_db.Query(St_SQL_Table, sQuery);
	g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `NULL_HITBOX` = '0', `HEAD`= '0', `CHEST`= '0', `STOMACH`= '0', `LEFT_ARM`= '0', `RIGHT_ARM`= '0', `LEFT_LEG` = '0', `RIGHT_LEG` = '0' WHERE `steamid` = '%s'", g_sTablName[1], sSteam);
	g_db.Query(St_SQL_Table, sQuery);
	g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `pistol` = '0', `pistol_magnum`= '0', `autoshotgun`= '0', `shotgun_chrome`= '0', `pumpshotgun`= '0', `shotgun_spas`= '0', `smg` = '0', `smg_mp5` = '0', `smg_silenced` = '0', `rifle_ak47` = '0', `rifle_sg552` = '0', `rifle` = '0', `rifle_m60` = '0', `rifle_desert` = '0', `hunting_rifle` = '0', `sniper_military` = '0', `sniper_awp` = '0', `sniper_scout` = '0', `weapon_grenade_launcher` = '0', `molotov` = '0', `pipe_bomb` = '0', `vomitjar` = '0', `melee` = '0', `baseball_bat` = '0', `cricket_bat` = '0', `crowbar` = '0', `electric_guitar` = '0', `fireaxe` = '0', `frying_pan` = '0', `katana` = '0', `knife` = '0', `machete` = '0', `tonfa` = '0', `pain_pills` = '0', `adrenaline` = '0', `defibrillator` = '0', `first_aid_kit` = '0'  WHERE `steamid` = '%s';", g_sTablName[2], sSteam);
	g_db.Query(St_SQL_Table, sQuery, GetClientUserId(client));
	g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `infected_death` = '0', `tank_killed`= '0', `boomer_exploded`= '0', `hunter_headshot`= '0', `charger_killed`= '0', `spitter_killed`= '0', `jockey_killed` = '0', `witch_killed` = '0', `survivor_killed` = '0' WHERE `steamid` = '%s';", g_sTablName[3], sSteam);
	g_db.Query(St_SQL_Table, sQuery, GetClientUserId(client));

	GetStMySql(client, 0);

	PrintToChat(client, "%t - %t", "Tag", "ResetMyRank");
	return Plugin_Handled;
}

public Action Command_St(int client, int args)
{
	GetStMySql(client, 1);
	GetStMySql(client, 0);
	PlayerMenuSt(client);
	return Plugin_Handled;
}

void PlayerMenuSt(int client)
{
	char sBuf[128];
	Menu hMenu = new Menu(ViewST);

	FormatEx(sBuf, sizeof sBuf, "%T %s", "Rank", client, g_sPlayerRankName[client]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "Position", client, g_iPlayerData[client][PlayerTop]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "Deads", client, g_iPlayerData[client][PlayerDead]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "Companies", client, g_iPlayerData[client][FinaleWin]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %s", "Played", client, IntToStringTime(g_iPlayerData[client][GmameTime]));
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "Shots", client, g_iPlayerData[client][Player_Fire]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "Hit", client, g_iPlayerData[client][Player_Hurt]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "Damage", client, g_iPlayerData[client][Player_Damage]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);

	FormatEx(sBuf, sizeof sBuf, "%T", "OpenHits", client);
	hMenu.AddItem(NULL_STRING, sBuf);
	FormatEx(sBuf, sizeof sBuf, "%T", "OpenKills", client);
	hMenu.AddItem(NULL_STRING, sBuf);
	FormatEx(sBuf, sizeof sBuf, "%T", "OpenWeaponFire", client);
	hMenu.AddItem(NULL_STRING, sBuf);
	FormatEx(sBuf, sizeof sBuf, "%T", "OpenTop", client);
	hMenu.AddItem(NULL_STRING, sBuf);
	FormatEx(sBuf, sizeof sBuf, "%T", "ModularMenuTitle", client);
	hMenu.AddItem(NULL_STRING, sBuf);

	if(ST_IsPlayerAdmin(client))
	{
		FormatEx(sBuf, sizeof sBuf, "%T", "AdminMenu", client);
		hMenu.AddItem(NULL_STRING, sBuf);
	}
	//menu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int ViewST(Menu hMenu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display: hMenu.SetTitle("%T %N:", "Title", client, client);
		case MenuAction_Select: 
		{
			switch(param)
			{
				case 8: PlayerHitsSt(client);
				case 9: OpenKills(client);
				case 10: OpenWeaponFire(client);
				case 11: StTopList(client);
				case 12: ShowModularMenu(client);
				case 13: OpenAdminMenu(client);
			}
		}
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

void OpenKills(int client)
{
	char sBuf[128];
	Menu hMenu = new Menu(OpenKillsSelect);
	hMenu.SetTitle("%T %N:", "OpenKills", client, client);

	FormatEx(sBuf, sizeof sBuf, "%T %i", "infected_death", client, g_iCountDataKills[client][infected_death]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "tank_killed", client, g_iCountDataKills[client][tank_killed]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "boomer_exploded", client, g_iCountDataKills[client][boomer_exploded]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "hunter_headshot", client, g_iCountDataKills[client][hunter_headshot]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "charger_killed", client, g_iCountDataKills[client][charger_killed]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "spitter_killed", client, g_iCountDataKills[client][spitter_killed]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "jockey_killed", client, g_iCountDataKills[client][jockey_killed]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "witch_killed", client, g_iCountDataKills[client][witch_killed]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "survivor_killed", client, g_iCountDataKills[client][survivor_killed]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int OpenKillsSelect(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void OpenWeaponFire(int client)
{
	char sBuf[128];
	Menu hMenu = new Menu(OpenWeaponFireSelect);
	hMenu.SetTitle("%T %N:", "OpenWeaponFire", client, client);

	FormatEx(sBuf, sizeof sBuf, "%T %i", "pistol", client, g_iCountItemFire[client][pistol]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "pistol_magnum", client, g_iCountItemFire[client][pistol_magnum]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "autoshotgun", client, g_iCountItemFire[client][autoshotgun]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "shotgun_chrome", client, g_iCountItemFire[client][shotgun_chrome]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "pumpshotgun", client, g_iCountItemFire[client][pumpshotgun]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "shotgun_spas", client, g_iCountItemFire[client][shotgun_spas]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "smg", client, g_iCountItemFire[client][smg]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "smg_mp5", client, g_iCountItemFire[client][smg_mp5]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "smg_silenced", client, g_iCountItemFire[client][smg_silenced]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);

	FormatEx(sBuf, sizeof sBuf, "%T %i", "rifle_ak47", client, g_iCountItemFire[client][rifle_ak47]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "rifle_sg552", client, g_iCountItemFire[client][rifle_sg552]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "rifle", client, g_iCountItemFire[client][rifle]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "rifle_m60", client, g_iCountItemFire[client][rifle_m60]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "rifle_desert", client, g_iCountItemFire[client][rifle_desert]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "hunting_rifle", client, g_iCountItemFire[client][hunting_rifle]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "sniper_military", client, g_iCountItemFire[client][sniper_military]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "sniper_awp", client, g_iCountItemFire[client][sniper_awp]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "sniper_scout", client, g_iCountItemFire[client][sniper_scout]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "weapon_grenade_launcher", client, g_iCountItemFire[client][weapon_grenade_launcher]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "molotov", client, g_iCountItemFire[client][molotov]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "pipe_bomb", client, g_iCountItemFire[client][pipe_bomb]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "vomitjar", client, g_iCountItemFire[client][vomitjar]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "melee", client, g_iCountItemFire[client][melee]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);

	FormatEx(sBuf, sizeof sBuf, "%T %i", "baseball_bat", client, g_iCountItemFire[client][baseball_bat]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "cricket_bat", client, g_iCountItemFire[client][cricket_bat]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "crowbar", client, g_iCountItemFire[client][crowbar]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "electric_guitar", client, g_iCountItemFire[client][electric_guitar]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "fireaxe", client, g_iCountItemFire[client][fireaxe]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "frying_pan", client, g_iCountItemFire[client][frying_pan]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "katana", client, g_iCountItemFire[client][katana]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "knife", client, g_iCountItemFire[client][knife]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "machete", client, g_iCountItemFire[client][machete]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "tonfa", client, g_iCountItemFire[client][tonfa]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);

	FormatEx(sBuf, sizeof sBuf, "%T %i", "pain_pills", client, g_iCountItemFire[client][pain_pills]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "adrenaline", client, g_iCountItemFire[client][adrenaline]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "defibrillator", client, g_iCountItemFire[client][defibrillator]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "first_aid_kit", client, g_iCountItemFire[client][first_aid_kit]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int OpenWeaponFireSelect(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void OpenAdminMenu(int client)
{
	Menu menu = new Menu(MenuHandler_AdminSelect);
	menu.SetTitle("%T", "AdminTitle", client);

	KeyValues kv = new KeyValues("admin_menu");
	kv.ImportFromFile(g_sFile[3]);
	char sBuf[32];
	if (kv.JumpToKey("MenuFunctions"))
	{
		if(!!kv.GetNum("reset_player", 1))
		{
			FormatEx(sBuf, sizeof sBuf, "%T", "reset_player", client);
			menu.AddItem("reset_player", sBuf);
		}
		if(!!kv.GetNum("reset_all", 1))
		{
			FormatEx(sBuf, sizeof sBuf, "%T", "reset_all", client);
			menu.AddItem("reset_all", sBuf);
		}
	}
	delete kv;

	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 0);
}

public int MenuHandler_AdminSelect(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sQuery[64];
			switch(param)
			{
				case 0:
				{
					g_db.Format(sQuery, sizeof sQuery, "SELECT * FROM `%s`", g_sTablName[0]);
					g_db.Query(St_ShowPlayerAdminMenu, sQuery, GetClientUserId(client));
				}
				case 1:
				{
					g_db.Format(sQuery, sizeof sQuery, "TRUNCATE TABLE `%s`", g_sTablName[0]);
					g_db.Query(St_SQL_Table, sQuery);
					g_db.Format(sQuery, sizeof sQuery, "TRUNCATE TABLE `%s`", g_sTablName[1]);
					g_db.Query(St_SQL_Table, sQuery);
					g_db.Format(sQuery, sizeof sQuery, "TRUNCATE TABLE `%s`", g_sTablName[2]);
					g_db.Query(St_SQL_Table, sQuery);
					g_db.Format(sQuery, sizeof sQuery, "TRUNCATE TABLE `%s`", g_sTablName[3]);
					g_db.Query(St_SQL_Table, sQuery);
					LoadPlayers();
					PrintToChat(client, "%t", "AdminResetAllChat");
					OpenAdminMenu(client);
				}
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public void St_ShowPlayerAdminMenu(Database db, DBResultSet result, const char[] error, any data)
{
	if(result == null || error[0])
		SetFailState("[L4D(2) Statistic] Failed: %s", error);

	int client = GetClientOfUserId(data);
	if(!IsClient(client))
		return;

	char sName[64], sSteamId[32], sRank[128], sBuf[256];
	Menu hMenu = new Menu(ResetUser);
	while(result.FetchRow())
	{
		result.FetchString(1, sName, sizeof sName);
		result.FetchString(2, sSteamId, sizeof sSteamId);
		result.FetchString(3, sRank, sizeof sRank);

		FormatEx(sBuf, sizeof sBuf, "[%s] %s", sRank, sName);
		hMenu.AddItem(sSteamId, sBuf);
	}
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int ResetUser(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sQuery[2048], sSteam[32];
			menu.GetItem(param, sSteam, sizeof sSteam);
			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `rank` = 'none', `gametime`= '0', `finalewin`= '0', `PlayerDead` = '0', `Player_Fire` = '0', `Player_Hurt` = '0', `Player_Damage` = '0' WHERE `steamid` = '%s'", g_sTablName[0], sSteam);
			g_db.Query(St_SQL_Table, sQuery);
			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `NULL_HITBOX` = '0', `HEAD`= '0', `CHEST`= '0', `STOMACH`= '0', `LEFT_ARM`= '0', `RIGHT_ARM`= '0', `LEFT_LEG` = '0', `RIGHT_LEG` = '0' WHERE `steamid` = '%s'", g_sTablName[1], sSteam);
			g_db.Query(St_SQL_Table, sQuery);
			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `pistol` = '0', `pistol_magnum`= '0', `autoshotgun`= '0', `shotgun_chrome`= '0', `pumpshotgun`= '0', `shotgun_spas`= '0', `smg` = '0', `smg_mp5` = '0', `smg_silenced` = '0', `rifle_ak47` = '0', `rifle_sg552` = '0', `rifle` = '0', `rifle_m60` = '0', `rifle_desert` = '0', `hunting_rifle` = '0', `sniper_military` = '0', `sniper_awp` = '0', `sniper_scout` = '0', `weapon_grenade_launcher` = '0', `molotov` = '0', `pipe_bomb` = '0', `vomitjar` = '0', `melee` = '0', `baseball_bat` = '0', `cricket_bat` = '0', `crowbar` = '0', `electric_guitar` = '0', `fireaxe` = '0', `frying_pan` = '0', `katana` = '0', `knife` = '0', `machete` = '0', `tonfa` = '0', `pain_pills` = '0', `adrenaline` = '0', `defibrillator` = '0', `first_aid_kit` = '0'  WHERE `steamid` = '%s';", g_sTablName[2], sSteam);
			g_db.Query(St_SQL_Table, sQuery, GetClientUserId(client));
			g_db.Format(sQuery, sizeof sQuery, "UPDATE `%s` SET `infected_death` = '0', `tank_killed`= '0', `boomer_exploded`= '0', `hunter_headshot`= '0', `charger_killed`= '0', `spitter_killed`= '0', `jockey_killed` = '0', `witch_killed` = '0', `survivor_killed` = '0' WHERE `steamid` = '%s';", g_sTablName[3], sSteam);
			g_db.Query(St_SQL_Table, sQuery, GetClientUserId(client));

			LoadPlayers();
			PrintToChat(client, "%t", "AdminResetPlayerChat");
			OpenAdminMenu(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

public Action Command_Top(int client, int args)
{
	StTopList(client);
	return Plugin_Handled;
}

void StTopList(int client)
{
	Menu menu = new Menu(MenuHandler_Top);
	menu.SetTitle("%T", "TopTitle", client);

	KeyValues kv = new KeyValues("TOP_MENU");
	kv.ImportFromFile(g_sFile[2]);
	if (kv.GotoFirstSubKey(true))
	{
		char item[64], sBuf[64];
		do
		{
			if(!!kv.GetNum("show", 1))
			{
				kv.GetString("name", item, sizeof item);
				FormatEx(sBuf, sizeof sBuf, "%T", item, client);
				menu.AddItem(item, sBuf);
			}
		}
		while (kv.GotoNextKey(true));
	}
	delete kv;
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 0);
}

public int MenuHandler_Top(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sBuffer[64], sQuery[256];
			menu.GetItem(param, sBuffer, sizeof sBuffer);
			if(StrEqual(sBuffer, "gametime", true))
			{
				g_bGameTime = true;
				g_db.Format(sQuery, sizeof sQuery, "SELECT `nicname`, `steamid`, `%s`  FROM `%s` ORDER BY `%s`.`%s` DESC", sBuffer, g_sTablName[0], g_sTablName[0], sBuffer);
				g_db.Query(St_GetTopList, sQuery, GetClientUserId(client));
			} 
			else
			{
				g_db.Format(sQuery, sizeof sQuery, "SELECT `nicname`, `steamid`, `%s`  FROM `%s` ORDER BY `%s`.`%s` DESC", sBuffer, g_sTablName[3], g_sTablName[3], sBuffer);
				g_db.Query(St_GetTopList, sQuery, GetClientUserId(client));
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void PlayerHitsSt(int client)
{
	char sBuf[128];
	Menu hMenu = new Menu(ViewHitsST);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "HEAD", client, g_iHitBox[client][HEAD]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "CHEST", client, g_iHitBox[client][CHEST]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "STOMACH", client, g_iHitBox[client][STOMACH]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "LEFT_ARM", client, g_iHitBox[client][LEFT_ARM]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "RIGHT_ARM", client, g_iHitBox[client][RIGHT_ARM]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "LEFT_LEG", client, g_iHitBox[client][LEFT_LEG]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	FormatEx(sBuf, sizeof sBuf, "%T %i", "RIGHT_LEG", client, g_iHitBox[client][RIGHT_LEG]);
	hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int ViewHitsST(Menu hMenu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display: hMenu.SetTitle("%T %N:", "TitleHits", client, client);
		//case MenuAction_Select:
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

public void St_GetTopList(Database db, DBResultSet result, const char[] error, any data)
{
	if(result == null || error[0])
		SetFailState("[L4D(2) Statistic] Failed: %s", error);

	int client = GetClientOfUserId(data);
	if (!IsClient(client))
		return;

	char sName[64], sSteamId[32], sBuf[128];
	Menu hMenu = new Menu(TopList);
	while(result.FetchRow())
	{
		result.FetchString(0, sName, sizeof sName);
		result.FetchString(1, sSteamId, sizeof sSteamId);
		if(g_bGameTime)
			FormatEx(sBuf, sizeof sBuf, "%s [%s]", sName, IntToStringTime(result.FetchInt(2)));
		else FormatEx(sBuf, sizeof sBuf, "%s [%i]", sName, result.FetchInt(2));
		hMenu.AddItem(sSteamId, sBuf);
	}
	g_bGameTime = false;
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int TopList(Menu hMenu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display: hMenu.SetTitle("%T", "TOP", client);
		case MenuAction_Select:
		{
			char sSteam[32], sQuery[512];
			hMenu.GetItem(param, sSteam, sizeof sSteam);

			g_db.Format(sQuery, sizeof sQuery, "SELECT * FROM `%s` WHERE `steamid` = '%s';", g_sTablName[0], sSteam);
			g_db.Query(St_ShowPlayerMenu, sQuery, GetClientUserId(client));
		}
		case MenuAction_Cancel: StTopList(client);
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

public void St_ShowPlayerMenu(Database db, DBResultSet result, const char[] error, any data)
{
	if(result == null || error[0])
		SetFailState("[L4D(2) Statistic] Failed: %s", error);

	int client = GetClientOfUserId(data);
	if (!IsClient(client))
		return;

	char sName[64], sSteamId[32], sRank[128], sBuf[128];
	Menu hMenu = new Menu(TopList);
	while(result.FetchRow())
	{
		result.FetchString(1, sName, sizeof sName);
		result.FetchString(2, sSteamId, sizeof sSteamId);
		result.FetchString(3, sRank, sizeof sRank);

		FormatEx(sBuf, sizeof sBuf, "%T %s", "Nic", client, sName);
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %s", "AuthId", client, sSteamId);
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %s", "Rank", client, sRank);
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %s", "Played", client, IntToStringTime(result.FetchInt(4)));
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %i", "Companies", client, result.FetchInt(5));
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %i", "Deads", client, result.FetchInt(6));
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %i", "Shots", client, result.FetchInt(7));
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %i", "Hit", client, result.FetchInt(8));
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);
		FormatEx(sBuf, sizeof sBuf, "%T %i", "Damage", client, result.FetchInt(9));
		hMenu.AddItem(NULL_STRING, sBuf, ITEMDRAW_DISABLED);

	}
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(client, 0);
}

public int ShowPlayerMenuSelect(Menu hMenu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display: hMenu.SetTitle("%T", "Profile", client);
		//case MenuAction_Select: StTopList(client);
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

public void St_GetPosTop(Database db, DBResultSet result, const char[] error, any data)
{
	if(result == null || error[0])
		SetFailState("[L4D(2) Statistic] Failed: %s", error);

	int client = GetClientOfUserId(data);
	if (!IsClient(client))
		return;
	if(result.FetchRow())
		g_iPlayerData[client][PlayerTop] = result.FetchInt(0);
}

public void St_SQL_Table(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null || error[0])
		SetFailState("[L4D(2) Statistic] Failed: %s", error);
}

public void OnPluginEnd()
{
	delete g_dbcache;
}

stock bool IsClient(int client)
{
	return 0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}

stock bool ST_IsPlayerAdmin(int client)
{
	return GetUserFlagBits(client) >= g_iAdminFlags;
}

stock char IntToStringTime(int Time)
{
	char sTime[32];
	int days = Time / 86400;
	Time -= days * 86400;
	int hours = Time / 3600;
	Time -= hours * 3600;
	int minutes = Time / 60;
	int seconds = Time - (minutes * 60);
	FormatEx(sTime, sizeof sTime, "%i d. %i h. %i m. %i s.", days, hours, minutes, seconds);
	return view_as<char>(sTime);
}

stock char GetNameRanks(int client, char[] sView)
{
	char sRank[32];
	g_kvRanks.Rewind();
	if (g_kvRanks.GotoFirstSubKey(true))
	{
		int iKills;
		do
		{
			iKills = view_as<int>(g_kvRanks.GetNum("kills"));
			g_kvRanks.GetString(sView, sRank, sizeof sRank, NULL_STRING);
			if(GetPlayerKills(client, sView) <= iKills)
				return view_as<char>(sRank);
		}
		while (g_kvRanks.GotoNextKey(true));
	}
	return view_as<char>(sRank);
}

stock int GetPlayerKills(int client, char[] sView)
{
	char sQuery[256], sSteam[32];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof sSteam);
	g_db.Format(sQuery, sizeof sQuery, "SELECT `%s` FROM `%s` WHERE `steamid` = '%s';", sView, g_sTablName[3], sSteam);
	g_db.Query(St_GetPlayerKills, sQuery, GetClientUserId(client));
	return g_iTempKills[client];
}

public void St_GetPlayerKills(Database db, DBResultSet result, const char[] error, any data)
{
	if(result == null || error[0])
		SetFailState("[L4D(2) Statistic] Failed: %s", error);

	int client = GetClientOfUserId(data);
	if (!IsClient(client))
		return;
	if(result.FetchRow())
		g_iTempKills[client] = result.FetchInt(0);
}

public int GetGamePlayers()
{
	int count;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClient(i))
			count++;
	}
	return count;
}

void LoadAllConfigs()
{
	KeyValues kv = new KeyValues("Configuration");
	if(kv.ImportFromFile(g_sFile[1]) && kv.JumpToKey("settings", false))
	{
		g_bPrintToChat = !!kv.GetNum("welcome_chat", 1);
		g_iCountPlayers = view_as<int>(kv.GetNum("min_count_players", 2));
		kv.GetString("basic_view_top", g_sBasicViewTop, sizeof g_sBasicViewTop, "infected_death");
		kv.GetString("players_table_name", g_sTablName[0], 32, "st_base_new");
		kv.GetString("hits_table_name", g_sTablName[1], 32, "st_base_hits");
		kv.GetString("weapon_table_name", g_sTablName[2], 32, "st_base_weapon");
		kv.GetString("kills_table_name", g_sTablName[3], 32, "st_base_kills");
		char sFlag[4];
		kv.GetString("AdminAccess", sFlag, sizeof sFlag, "z");
		g_iAdminFlags = ReadFlagString(sFlag);
		PrintToServer("[L4D1(2)] Statistics - The configuration loaded.");
	} 
	else SetFailState("[L4D1(2)] Statistics - The configuration not loaded.");

	delete kv;

	g_kvRanks = new KeyValues("RANKS");
	if(!g_kvRanks.ImportFromFile(g_sFile[0]))
	{
		g_kvRanks.JumpToKey("Calibration", true);
		g_kvRanks.SetString("kills", "1000");
		g_kvRanks.SetString("name", "Calibration");
		g_kvRanks.GoBack();
		g_kvRanks.ExportToFile(g_sFile[0]);
		PrintToServer("[L4D1(2)] Statistics - The file configs/l4d_statistic/ranks.ini is missing. I create a new one.");
	}
	g_kvRanks.ExportToFile(g_sFile[0]);
	PrintToServer("[L4D1(2)] Statistics - File ranks.ini loaded");
}

void LoadPlayers()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClient(i))
			OnClientPostAdminCheck(i);
}