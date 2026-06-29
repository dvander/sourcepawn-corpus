#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "2.3.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

Database DB = null;

char queryError[256];

int clientCredits[MAXPLAYERS + 1];
int clientMenuUsage[MAXPLAYERS + 1];
int clientVipSpawnUsage[MAXPLAYERS + 1];

char playerID[MAXPLAYERS + 1][64];

ConVar g_timerTime, g_timerCreditsReceival, g_ak47Cost, g_ak47Enable, g_m4a4Cost, g_m4a4Enable, g_m4a1sCost, g_m4a1sEnable, g_awpCost, g_awpEnable, g_maxMenuUsage, g_healthShotCost, g_healthShotEnable, g_taGrenadeCost, g_taGrenadeEnable, g_vipSpawnMax, g_vipSpawnCost, g_vipSpawnEnable, g_displayMenuRoundStart, g_hpAtRoundStart, g_hpAtKill, g_hpAtHeadshot;
int timerTime, timerCreditsReceival, ak47Cost, ak47Enable, m4a4Cost, m4a4Enable, m4a1sCost, m4a1sEnable, awpCost, awpEnable, maxMenuUsage, healthShotCost, healthShotEnable, taGrenadeCost, taGrenadeEnable, vipSpawnMax, vipSpawnCost, vipSpawnEnable, displayMenuRoundStart, hpAtRoundStart, hpAtKill, hpAtHeadshot;

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[SpirT] VipMenu - Databases Update",
	author = PLUGIN_AUTHOR,
	description = "A Awesome VipMenu with a brand new Database Update feature.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	char cfgDir[256] = "cfg/SpirT";
	if(!DirExists(cfgDir))
	{
		CreateDirectory(cfgDir, 511);
	}
	
	//Database Connection & Initial Querys
	DB = SQL_Connect("spirt_vipmenu", true, queryError, sizeof(queryError));
	
	if(DB == null)
	{
		PrintToServer("[SpirT - VIPMENU] There was an error while connecting to the database: %s", queryError);
	}
	else
	{
		PrintToServer("[SpirT - VIPMENU] Connection to database established");
		CreateDatabaseTables();
	}
	
	RegAdminCmd("sm_vipcredits", Command_VipCredits, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_vipmenu", Command_VipMenu, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_vipspawn", Command_VipSpawn, ADMFLAG_RESERVATION);
	HookEvent("round_start", RoundStart);
	HookEvent("player_death", PlayerDeath);
	
	g_timerTime = CreateConVar("spirt_vipmenu_timer_time", "10", "Interval in seconds that players need to wait to receive more credits to play. Only players with flag A will be able to receive them. 0 = disable");
	g_timerCreditsReceival = CreateConVar("spirt_vipmenu_timer_credits_receival", "10", "Amount of credits that players will receive for playing. Only players with flag A will be able to receive them. 0 = disable");
	g_ak47Cost = CreateConVar("spirt_vipmenu_ak47_price", "100", "Amount of credits needed to buy the pack AK47 + DEAGLE. 0 = free");
	g_ak47Enable = CreateConVar("spirt_vipmenu_ak47_enable", "1", "Enable or disable item in VIPMenu. 1 = enable 0 = disable");
	g_m4a4Cost = CreateConVar("spirt_vipmenu_m4a4_price", "100", "Amount of credits needed to buy the pack M4A4 + DEAGLE. 0 = free");
	g_m4a4Enable = CreateConVar("spirt_vipmenu_m4a4_enable", "1", "Enable or disable item in VIPMenu. 1 = enable 0 = disable");
	g_m4a1sCost = CreateConVar("spirt_vipmenu_m4a1s_price", "100", "Amount of credits needed to buy the pack M4A1-S + DEAGLE. 0 = free");
	g_m4a1sEnable = CreateConVar("spirt_vipmenu_m4a1s_enable", "1", "Enable or disable item in VIPMenu. 1 = enable 0 = disable");
	g_awpCost = CreateConVar("spirt_vipmenu_awp_price", "100", "Amount of credits needed to buy the pack AWP + DEAGLE. 0 = free");
	g_awpEnable = CreateConVar("spirt_vipmenu_awp_enable", "1", "Enable or disable item in VIPMenu. 1 = enable 0 = disable");
	g_maxMenuUsage = CreateConVar("spirt_vipmenu_max_uses", "2", "Maximum number of uses that a player can have for VIPMenu per round");
	g_healthShotCost = CreateConVar("spirt_vipmenu_healthshot_price", "50", "Amount of credits needed to buy the pack HealthShot. 0 = free");
	g_healthShotEnable = CreateConVar("spirt_vipmenu_healthshot_enable", "1", "Enable or disable item in VIPMenu. 1 = enable 0 = disable");
	g_taGrenadeCost = CreateConVar("spirt_vipmenu_tagrenade_price", "50", "Amount of credits needed to buy the pack TA Grenade. 0 = free");
	g_taGrenadeEnable = CreateConVar("spirt_vipmenu_tagrenade_enable", "1", "Enable or disable item in VIPMenu. 1 = enable 0 = disable");
	g_vipSpawnCost = CreateConVar("spirt_vipmenu_vipspawn_cost", "200", "Amount of credits needed to buy a VIPSpawn. 0 = free");
	g_vipSpawnMax = CreateConVar("spirt_vipmenu_vipspawn_max_uses", "1", "Maximum number of uses that a player can have for VIPSpawn per round.");
	g_vipSpawnEnable = CreateConVar("spirt_vipmenu_vipspawn_enable", "1", "Enable or Disable VIPSpawn. 1 = enable 0 = disable");
	g_displayMenuRoundStart = CreateConVar("spirt_vipmenu_display_round_start", "1", "Displays VIPMenu at Round Start. 1 = enable 0 = disable.");
	g_hpAtRoundStart = CreateConVar("spirt_vipmenu_start_hp", "110", "HP that a player will have at round start");
	g_hpAtKill = CreateConVar("spirt_vipmenu_kill_hp", "10", "HP that a player will receive when killing");
	g_hpAtHeadshot = CreateConVar("spirt_vipmenu_headshot_hp", "10", "HP that a player will receive when killing with an headshot");
	
	AutoExecConfig(true, "vipmenu", "SpirT");
}

public Action RoundStart(Event event, char[] name, bool dontBroadCast)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if(CheckCommandAccess(i, "sm_vipmenu", ADMFLAG_RESERVATION))
		{
			SetEntityHealth(i, hpAtRoundStart);
			clientMenuUsage[i] = 0;
			
			if(displayMenuRoundStart != 0)
			{
				MainMenu(i);
			}
		}
		if(CheckCommandAccess(i, "sm_vipspawn", ADMFLAG_RESERVATION))
		{
			clientVipSpawnUsage[i] = 0;
		}
	}
}

public Action PlayerDeath(Event event, char[] name, bool dontBroadCast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!CheckCommandAccess(attacker, "sm_vipmenu", ADMFLAG_RESERVATION))
	{
		return Plugin_Handled;
	}
	
	bool headshot = GetEventBool(event, "headshot");
	int currentHealth = GetClientHealth(attacker);
	if(headshot)
	{
		int newHealth = currentHealth + hpAtHeadshot;
		SetEntityHealth(attacker, newHealth);
		return Plugin_Handled;
	}
	else
	{
		int newHealth = currentHealth + hpAtKill;
		SetEntityHealth(attacker, newHealth);
		return Plugin_Handled;
	}
}

public void OnConfigsExecuted()
{
	timerTime = GetConVarInt(g_timerTime);
	timerCreditsReceival = GetConVarInt(g_timerCreditsReceival);
	ak47Cost = GetConVarInt(g_ak47Cost);
	ak47Enable = GetConVarInt(g_ak47Enable);
	m4a4Cost = GetConVarInt(g_m4a4Cost);
	m4a4Enable = GetConVarInt(g_m4a4Enable);
	m4a1sCost = GetConVarInt(g_m4a1sCost);
	m4a1sEnable = GetConVarInt(g_m4a1sEnable);
	awpCost = GetConVarInt(g_awpCost);
	awpEnable = GetConVarInt(g_awpEnable);
	maxMenuUsage = GetConVarInt(g_maxMenuUsage);
	healthShotCost = GetConVarInt(g_healthShotCost);
	healthShotEnable = GetConVarInt(g_healthShotEnable);
	taGrenadeCost = GetConVarInt(g_taGrenadeCost);
	taGrenadeEnable = GetConVarInt(g_taGrenadeEnable);
	vipSpawnMax = GetConVarInt(g_vipSpawnMax);
	vipSpawnCost = GetConVarInt(g_vipSpawnCost);	
	vipSpawnEnable = GetConVarInt(g_vipSpawnEnable);
	displayMenuRoundStart = GetConVarInt(g_displayMenuRoundStart);
	hpAtRoundStart = GetConVarInt(g_hpAtRoundStart);
	hpAtKill = GetConVarInt(g_hpAtKill);
	hpAtHeadshot = GetConVarInt(g_hpAtHeadshot);
	CreateTimer(timerTime * 1.0, GiveCreditsTimer, _, TIMER_REPEAT);
}

public void CreateDatabaseTables()
{
	char tablesQuery[256];
	Format(tablesQuery, sizeof(tablesQuery), "CREATE TABLE IF NOT EXISTS balance (steamid varchar(32), credits int(20));");
	DBResultSet tables = SQL_Query(DB, tablesQuery);
	
	if(tables == null)
	{
		SQL_GetError(tables, queryError, sizeof(queryError));
		PrintToServer("[SpirT - VIPMENU] There was an error while executing a query: %s", queryError);
	}
	else
	{
		PrintToServer("[SpirT - VIPMENU] Tables created & verified successfully.");
	}
}

public Action Command_VipCredits(int client, int args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	char existQuery[256];
	Format(existQuery, sizeof(existQuery), "SELECT credits FROM balance WHERE steamid = '%s';", steamid);
	DBResultSet exist = SQL_Query(DB, existQuery);
	
	if(exist == null)
	{
		SQL_GetError(exist, queryError, sizeof(queryError));
		PrintToServer("[SpirT - VIPMENU] There was an error while executing the query: %s", queryError);
	}
	else
	{
		if(exist.FetchRow())
		{
			clientCredits[client] = SQL_FetchInt(exist, 0);
			PrintToChat(client, "[SpirT - VIPMENU] You currently have %d credits.", clientCredits[client]);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	GetClientAuthId(client, AuthId_Steam2, playerID[client], sizeof(playerID[]));
	
	char existQuery[256];
	Format(existQuery, sizeof(existQuery), "SELECT credits FROM balance WHERE steamid = '%s';", playerID[client]);
	DBResultSet exist = SQL_Query(DB, existQuery);
	
	if(exist == null)
	{
		SQL_GetError(exist, queryError, sizeof(queryError));
		PrintToServer("[SpirT - VIPMENU] There was an error while executing the query: %s", queryError);
	}
	else
	{
		if(exist.FetchRow())
		{
			clientCredits[client] = SQL_FetchInt(exist, 0);
		}
		else
		{
			char newPlayerQuery[256];
			Format(newPlayerQuery, sizeof(newPlayerQuery), "INSERT INTO balance (steamid, credits) VALUES ('%s', '0');", playerID[client]);
			DBResultSet newPlayer = SQL_Query(DB, newPlayerQuery);
			
			if(newPlayer == null)
			{
				SQL_GetError(exist, queryError, sizeof(queryError));
				PrintToServer("[SpirT - VIPMENU] There was an error while executing the query: %s", queryError);
			}
			else
			{
				PrintToServer("[SpirT - VIPMENU] A new player was added to the database.");
				clientCredits[client] = 0;
			}
		}
	}
}

public Action GiveCreditsTimer(Handle timer, Handle hndl)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(CheckCommandAccess(i, "sm_vipcredits", ADMFLAG_RESERVATION))
			{
				char steamID[64];
				GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));
				clientCredits[i] = clientCredits[i] + timerCreditsReceival;
				UpdatePlayerCredits(clientCredits[i], steamID);
				PrintToChat(i, "[SpirT - VIPMENU] You received %d credits for playing in this server.", timerCreditsReceival);
			}
		}
	}
}

void UpdatePlayerCredits(int newCredits, const char[] authid)
{
	char updateCredits[256];
	Format(updateCredits, sizeof(updateCredits), "UPDATE balance SET credits = '%d' WHERE steamid = '%s';", newCredits, authid);
	DBResultSet update = SQL_Query(DB, updateCredits);
	
	if(update == null)
	{
		SQL_GetError(update, queryError, sizeof(queryError));
		PrintToServer("[SpirT - VIPMENU] There was an error while executing the query: %s", queryError);
	}
	else
	{
		PrintToServer("[SpirT - VIPMENU] Player credits updated");
	}
}

public Action Command_VipMenu(int client, int args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[SpirT - VIPMENU] You must be alive to use VIPMenu");
		return Plugin_Handled;
	}
	
	if(clientMenuUsage[client] == maxMenuUsage)
	{
		PrintToChat(client, "[SpirT - VIPMENU] You have exceeded the maximum allowed uses of VIPMenu this round. Please wait for the next one!");
		return Plugin_Handled;
	}
	
	MainMenu(client);
	return Plugin_Handled;
}

Menu MainMenu(int client)
{
	Menu menu = new Menu(MainHandle, MENU_ACTIONS_ALL);
	menu.SetTitle("VIPMenu");
	menu.AddItem("1", "Guns");
	menu.AddItem("2", "Extras");
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return menu;
}

public int MainHandle(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char choice[64];
		menu.GetItem(item, choice, sizeof(choice));
		
		if(StrEqual(choice, "1"))
		{
			GunsMenu(client);
		}
		else if(StrEqual(choice, "2"))
		{
			ExtrasMenu(client);
		}
	}
}

Menu GunsMenu(int client)
{
	Menu menu = new Menu(GunsHandle, MENU_ACTIONS_ALL);
	menu.SetTitle("VIPMenu - Guns");
	char item1[128];
	Format(item1, sizeof(item1), "AK47 + DEAGLE [%d]", ak47Cost);

	CheckItemAvailability(menu, "1", item1, ak47Enable);
	
	char item2[128];
	Format(item2, sizeof(item2), "M4A4 + DEAGLE [%d]", m4a4Cost);
	
	CheckItemAvailability(menu, "2", item2, m4a4Enable);
	
	char item3[128];
	Format(item3, sizeof(item3), "M4A1-S + DEAGLE [%d]", m4a1sCost);
	
	CheckItemAvailability(menu, "3", item3, m4a1sEnable);
	
	char item4[128];
	Format(item4, sizeof(item4), "AWP + DEAGLE [%d]", awpCost);
	
	CheckItemAvailability(menu, "4", item4, awpEnable);
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return menu;
}

void CheckItemAvailability(Menu menu, const char[] itemNumber, const char[] itemString, int enabled)
{
	if(enabled != 0)
	{
		AddMenuItem(menu, itemNumber, itemString);
	}
}

public int GunsHandle(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char choice[64];
		menu.GetItem(item, choice, sizeof(choice));
		
		if(StrEqual(choice, "1"))
		{
			if(clientCredits[client] >= ak47Cost)
			{
				DisarmPrimary(client, "weapon_ak47");
				DisarmPistol(client, "weapon_deagle");
				clientCredits[client] = clientCredits[client] - ak47Cost;
				UpdatePlayerCredits(clientCredits[client], playerID[client]);
				clientMenuUsage[client]++;
			}
			else
			{
				PrintToChat(client, "[SpirT - VIPMENU] You don't have enough credits to buy this pack");
			}
		}
		else if(StrEqual(choice, "2"))
		{
			if(clientCredits[client] >= m4a4Cost)
			{
				DisarmPrimary(client, "weapon_m4a1");
				DisarmPistol(client, "weapon_deagle");
				clientCredits[client] = clientCredits[client] - m4a4Cost;
				UpdatePlayerCredits(clientCredits[client], playerID[client]);
				clientMenuUsage[client]++;
			}
			else
			{
				PrintToChat(client, "[SpirT - VIPMENU] You don't have enough credits to buy this pack");
			}
		}
		else if(StrEqual(choice, "3"))
		{
			if(clientCredits[client] >= m4a1sCost)
			{
				DisarmPrimary(client, "weapon_m4a1_silencer");
				DisarmPistol(client, "weapon_deagle");
				clientCredits[client] = clientCredits[client] - m4a1sCost;
				UpdatePlayerCredits(clientCredits[client], playerID[client]);
				clientMenuUsage[client]++;
			}
			else
			{
				PrintToChat(client, "[SpirT - VIPMENU] You don't have enough credits to buy this pack");
			}
		}
		else if(StrEqual(choice, "4"))
		{
			if(clientCredits[client] >= awpCost)
			{
				DisarmPrimary(client, "weapon_awp");
				DisarmPistol(client, "weapon_deagle");
				clientCredits[client] = clientCredits[client] - awpCost;
				UpdatePlayerCredits(clientCredits[client], playerID[client]);
				clientMenuUsage[client]++;
			}
			else
			{
				PrintToChat(client, "[SpirT - VIPMENU] You don't have enough credits to buy this pack");
			}
		}
	}
}

Menu ExtrasMenu(int client)
{
	Menu menu = new Menu(ExtrasHandle, MENU_ACTIONS_ALL);
	menu.SetTitle("VIPMenu - Extras");
	
	char item1[128];
	Format(item1, sizeof(item1), "HealthShot [%d]", healthShotCost);
	
	CheckItemAvailability(menu, "1", item1, healthShotEnable);
	
	char item2[128];
	Format(item2, sizeof(item2), "TA Grenade [%d]", taGrenadeCost);
	
	CheckItemAvailability(menu, "2", item2, taGrenadeEnable);
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return menu;
}

public int ExtrasHandle(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char choice[64];
		menu.GetItem(item, choice, sizeof(choice));
		
		if(StrEqual(choice, "1"))
		{
			if(clientCredits[client] >= healthShotCost)
			{
				GivePlayerItem(client, "weapon_healthshot");
				clientCredits[client] = clientCredits[client] - healthShotCost;
				UpdatePlayerCredits(clientCredits[client], playerID[client]);
				clientMenuUsage[client]++;
			}
			else
			{
				PrintToChat(client, "[SpirT - VIPMENU] You don't have enough credits to buy this pack");
			}
		}
		else if(StrEqual(choice, "2"))
		{
			if(clientCredits[client] >= taGrenadeCost)
			{
				GivePlayerItem(client, "weapon_tagrenade");
				clientCredits[client] = clientCredits[client] - taGrenadeCost;
				UpdatePlayerCredits(clientCredits[client], playerID[client]);
				clientMenuUsage[client]++;
			}
			else
			{
				PrintToChat(client, "[SpirT - VIPMENU] You don't have enough credits to buy this pack");
			}
		}
	}
}

void DisarmPrimary(int client, const char[] newPrimary)
{
	int slot1 = GetPlayerWeaponSlot(client, 0);
	if(!IsValidEntity(slot1))
	{
		GivePlayerItem(client, newPrimary);
	}
	else
	{
		RemovePlayerItem(client, slot1);
		GivePlayerItem(client, newPrimary);
	}
}

void DisarmPistol(int client, const char[] newPistol)
{
	int slot1 = GetPlayerWeaponSlot(client, 1);
	if(!IsValidEntity(slot1))
	{
		GivePlayerItem(client, newPistol);
	}
	else
	{
		RemovePlayerItem(client, slot1);
		GivePlayerItem(client, newPistol);
	}
}

public Action Command_VipSpawn(int client, int args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(IsPlayerAlive(client))
	{
		PrintToChat(client, "[SpirT - VIPMENU] You must be dead to use VIPSpawn.");
		return Plugin_Handled;
	}
	
	if(vipSpawnEnable == 0)
	{
		PrintToChat(client, "[SpirT - VIPMENU] Sorry, but this feature is currently disabled!");
		return Plugin_Handled;
	}
	
	if(clientVipSpawnUsage[client] >= vipSpawnMax)
	{
		PrintToChat(client, "[SpirT - VIPMENU] Sorry, but you have already exceeded the maximum allowed uses of VIPSpawn this round. Please wait for the next one.");
		return Plugin_Handled;
	}
	
	if(vipSpawnCost != 0)
	{
		if(clientCredits[client] >= vipSpawnCost)
		{
			clientCredits[client] = clientCredits[client] - vipSpawnCost;
			CS_RespawnPlayer(client);
			clientVipSpawnUsage[client]++;
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "[SpirT - VIPMENU] You don't have enough credits to buy a VIPSpawn.");
			return Plugin_Handled;
		}
	}
	else
	{
		CS_RespawnPlayer(client);
		clientVipSpawnUsage[client]++;
		return Plugin_Handled;
	}
}