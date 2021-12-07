#pragma semicolon 1

#define PLUGIN_AUTHOR "Totenfluch"
#define PLUGIN_VERSION "2.00"

#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#include <store>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <map_workshop_functions>
#include <emitsoundany>
#include <multicolors>


#pragma newdecls required


#define MAX_Item 1024

enum Item {
	Float:gXPos, 
	Float:gYPos, 
	Float:gZPos, 
	bool:gIsActive, 
	gAuraRef, 
	gItemRef
}

int g_eItemSpawnPoints[MAX_Item][Item];
int g_iLoadedItem = 0;
int g_iActiveItem = 0;

int g_iBlueGlow;

ArrayList randomNumbers;


/* CVARS */

Handle g_hItemPath;
char g_cItemPath[255];

Handle g_hPickupSoundPath;
char g_cPickupSoundPath[255];

Handle g_hAuraPath;
char g_cAuraPath[255];

Handle g_hPickupEffectPath;
char g_cPickupEffectPath[255];

Handle g_hPickupCredits;
int g_iPickupCredits;

Handle g_hSpawnMode;
int g_iSpawnMode;

Handle g_hSpawnAmount;
int g_iSpawnAmount;

Handle g_hMinSpawnAmount;
int g_iMinSpawnAmount;

Handle g_hMaxSpawnAmount;
int g_iMaxSpawnAmount;

Handle g_hnSpawnAmount;
int g_inSpawnAmount;
int g_iAntiExploidSpawnAmount;

Handle g_hEnableAntiAbuse;
bool g_bEnableAntiAbuse;

Handle g_hpSpawnDelay;
int g_ipSpawnDelay;

Handle g_hSoundMode;
int g_iSoundMode;

Handle g_hChatTag;
char g_cChatTag[64];

Handle g_hItemName;
char g_cItemName[64];

Handle g_hUseMySQL;
char g_cUseMySQL[64];

int g_iRespawnDelays[MAX_Item];

Handle g_hModelScale;
float g_fModelScale;

Handle g_hZAxisOffset;
float g_fZAxisOffset;

Database g_DB;
bool g_bMySQLEnabled = false;

public Plugin myinfo = 
{
	name = "Event Items Spawner", 
	author = PLUGIN_AUTHOR, 
	description = "Spawns Items that can be collected", 
	version = PLUGIN_VERSION, 
	url = "http://ggc-base.de"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_itemspawns", addSpawnPointsMenu, ADMFLAG_GENERIC, "Opens the Item spawn menu");
	RegAdminCmd("sm_itemspawnsreload", cmdForceReload, ADMFLAG_GENERIC, "Reloads the points");
	RegAdminCmd("sm_itemmaps", getLoadedMaps, ADMFLAG_GENERIC, "Prints all maps without spawnpoints");
	
	HookEvent("round_start", onRoundStart);
	
	LoadTranslations("eventItems.phrases");
	
	AutoExecConfig_SetFile("eventItems");
	AutoExecConfig_SetCreateFile(true);
	
	g_hItemPath = AutoExecConfig_CreateConVar("event_itemPath", "models/coop/challenge_coin.mdl", "Itempath of Item Spawn");
	g_hAuraPath = AutoExecConfig_CreateConVar("event_auraPath", "", "Particle Name of Aura (optional)");
	g_hPickupEffectPath = AutoExecConfig_CreateConVar("event_PickupEffectPath", "", "Particle Name of Pickup Effect (optional)");
	g_hPickupSoundPath = AutoExecConfig_CreateConVar("event_PickupSoundPath", "", "Sound to play when item is picked up");
	g_hPickupCredits = AutoExecConfig_CreateConVar("event_pickupCredits", "10", "Credits awarded for Pickup");
	g_hSpawnMode = AutoExecConfig_CreateConVar("event_spawnMode", "4", ">>SpawnMode<<-> 1 -> x Per Player | 2 -> Up to 10*x | 3 -> Random from min to Max | 4 -> Random with n active and p(s) delay");
	g_hSpawnAmount = AutoExecConfig_CreateConVar("event_spawnAmount", "1", "Amount x for >>SpawnMode 1 AND 2<<");
	g_hMinSpawnAmount = AutoExecConfig_CreateConVar("event_minSpawnAmount", "15", "Min Amount for >>SpawnMode 3<<");
	g_hMaxSpawnAmount = AutoExecConfig_CreateConVar("event_maxSpawnAmount", "25", "Max Amount for >>SpawnMode 3<<");
	g_hSoundMode = AutoExecConfig_CreateConVar("event_soundMode", "2", "1 -> To Client on Pickup | 2 -> Ambient sound from Position | 3 -> Sound to all");
	g_hnSpawnAmount = AutoExecConfig_CreateConVar("event_nSpawnAmount", "3", "n Spawn amount for >>SpawnMode 4<<");
	g_hEnableAntiAbuse = AutoExecConfig_CreateConVar("event_antiExploid", "1", "reduces amount (n) for >>4<< to the players on the server if set on 1");
	g_hpSpawnDelay = AutoExecConfig_CreateConVar("event_pSpawnDelay", "300", "Spawn delay for >>SpawnMode 4<< in seconds");
	g_hChatTag = AutoExecConfig_CreateConVar("event_chatTag", "GGC", "Chattag to append in front of all prints");
	g_hItemName = AutoExecConfig_CreateConVar("event_itemName", "Coin", "Name of the Item for PrintToChat");
	g_hUseMySQL = AutoExecConfig_CreateConVar("event_useMysql", "eventItems", "MySQL Config Name - leave blank for none");
	g_hModelScale = AutoExecConfig_CreateConVar("event_modelScale", "0.65", "Scales the Model (Not working for all models!)");
	g_hZAxisOffset = AutoExecConfig_CreateConVar("event_zAxisOffset", "30.0", "Moves the Item Up and Down (can be negative)");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}

public Action cmdForceReload(int client, int args) {
	forceReload();
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client) {
	if (!g_bMySQLEnabled)
		return;
	char playerid[20];
	GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	char initQuery[512];
	Format(initQuery, sizeof(initQuery), "INSERT IGNORE INTO `eventItems_stats` (`Id`, `playername`, `playerid`, `amount`) VALUES (NULL, '%s', '%s', '0');", clean_playername, playerid);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, initQuery);
}

public void OnConfigsExecuted() {
	GetConVarString(g_hItemPath, g_cItemPath, sizeof(g_cItemPath));
	GetConVarString(g_hAuraPath, g_cAuraPath, sizeof(g_cAuraPath));
	GetConVarString(g_hPickupEffectPath, g_cPickupEffectPath, sizeof(g_cPickupEffectPath));
	GetConVarString(g_hPickupSoundPath, g_cPickupSoundPath, sizeof(g_cPickupSoundPath));
	g_iPickupCredits = GetConVarInt(g_hPickupCredits);
	g_iSpawnMode = GetConVarInt(g_hSpawnMode);
	g_iSpawnAmount = GetConVarInt(g_hSpawnAmount);
	g_iSoundMode = GetConVarInt(g_hSoundMode);
	g_iMinSpawnAmount = GetConVarInt(g_hMinSpawnAmount);
	g_iMaxSpawnAmount = GetConVarInt(g_hMaxSpawnAmount);
	GetConVarString(g_hChatTag, g_cChatTag, sizeof(g_cChatTag));
	GetConVarString(g_hItemName, g_cItemName, sizeof(g_cItemName));
	g_inSpawnAmount = GetConVarInt(g_hnSpawnAmount);
	g_ipSpawnDelay = GetConVarInt(g_hpSpawnDelay);
	g_fModelScale = GetConVarFloat(g_hModelScale);
	g_fZAxisOffset = GetConVarFloat(g_hZAxisOffset);
	g_bEnableAntiAbuse = GetConVarBool(g_hEnableAntiAbuse);
	g_iAntiExploidSpawnAmount = g_inSpawnAmount;
	
	GetConVarString(g_hUseMySQL, g_cUseMySQL, sizeof(g_cUseMySQL));
	if (!StrEqual(g_cUseMySQL, "")) {
		char error[256];
		g_DB = SQL_Connect(g_cUseMySQL, true, error, sizeof(error));
		char createTableQuery[2048];
		Format(createTableQuery, sizeof(createTableQuery), "CREATE TABLE IF NOT EXISTS eventItems_stats ( `Id` BIGINT NULL DEFAULT NULL AUTO_INCREMENT , `playername` VARCHAR(64) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL , `playerid` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL , `amount` INT NOT NULL , PRIMARY KEY (`Id`),  UNIQUE KEY `playerid` (`playerid`)) ENGINE = InnoDB CHARSET=utf8 COLLATE utf8_bin;");
		SQL_TQuery(g_DB, SQLErrorCheckCallback, createTableQuery);
		g_bMySQLEnabled = true;
	}
	
	if (!StrEqual(g_cPickupSoundPath, ""))
		PrecacheSoundAny(g_cPickupSoundPath, true);
	
	if (g_iSpawnMode == 4)
		for (int i = 0; i < g_inSpawnAmount; i++)
	g_iRespawnDelays[i] = 0;
	
	if (g_bMySQLEnabled) {
		char retrieveStatsCommandString[64];
		Format(retrieveStatsCommandString, sizeof(retrieveStatsCommandString), "sm_%ss", g_cItemName);
		if (!CommandExists(retrieveStatsCommandString))
			RegConsoleCmd(retrieveStatsCommandString, retrieveStatsCommand, "Shows the amount of Event Items you have collected");
		
		char topListCommand[64];
		Format(topListCommand, sizeof(topListCommand), "sm_%stop", g_cItemName);
		if (!CommandExists(topListCommand))
			RegConsoleCmd(topListCommand, getTopCollectors, "Lists the best collectors on the Server");
	}
	
	char amountCommand[64];
	Format(amountCommand, sizeof(amountCommand), "sm_%samount", g_cItemName);
	if (!CommandExists(amountCommand))
		RegConsoleCmd(amountCommand, getItemAmount, "returns the amount of active Items");
}

public Action retrieveStatsCommand(int client, int args) {
	if (g_bMySQLEnabled) {
		char playerid[20];
		GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
		char fetchStatsQuery[256];
		Format(fetchStatsQuery, sizeof(fetchStatsQuery), "SELECT amount FROM eventItems_stats WHERE playerid = '%s';", playerid);
		SQL_TQuery(g_DB, fetchStatsQueryCallback, fetchStatsQuery, client);
	}
	return Plugin_Handled;
}

public Action getItemAmount(int client, int args) {
	int activeItems = 0;
	for (int i = 0; i < g_iLoadedItem; i++)
	if (g_eItemSpawnPoints[i][gIsActive])
		activeItems++;
	CPrintToChat(client, "%t", "showActiveItems", g_cChatTag, activeItems, g_cItemName);
	return Plugin_Handled;
}


public void fetchStatsQueryCallback(Handle owner, Handle hndl, const char[] error, any client) {
	int amount;
	while (SQL_FetchRow(hndl)) {
		amount = SQL_FetchIntByName(hndl, "amount");
	}
	CPrintToChat(client, "%t", "showPickupAmount", g_cChatTag, amount, g_cItemName);
}


public void incrementCollectedAmount(int client) {
	addToCollectedAmount(client, 1);
}

public void addToCollectedAmount(int client, int amount) {
	if (g_bMySQLEnabled) {
		char playerid[20];
		GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
		char UpdateProgressQuery[1024];
		Format(UpdateProgressQuery, sizeof(UpdateProgressQuery), "UPDATE `eventItems_stats` SET `amount` = amount + %i WHERE `eventItems_stats`.`playerid` = '%s';", amount, playerid);
		SQL_TQuery(g_DB, SQLErrorCheckCallback, UpdateProgressQuery);
	}
}

public void OnMapStart() {
	forceReload();
	CreateTimer(1.0, refreshTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action refreshTimer(Handle Timer) {
	if (g_iSpawnMode == 4) {
		for (int i = 0; i < g_iAntiExploidSpawnAmount; i++) {
			if (g_iRespawnDelays[i] > 1) {
				g_iRespawnDelays[i]--;
			} else if (g_iRespawnDelays[i] == 1) {
				g_iRespawnDelays[i]--;
				spawnItemOnRandomSlot();
			}
		}
	}
}

public void forceReload() {
	char Path[512];
	BuildPath(Path_SM, Path, sizeof(Path), "configs/event_Item");
	if (!DirExists(Path))
		CreateDirectory(Path, 0777);
	
	for (int i = 0; i < MAX_Item; i++) {
		g_eItemSpawnPoints[g_iLoadedItem][gXPos] = -1.0;
		g_eItemSpawnPoints[g_iLoadedItem][gYPos] = -1.0;
		g_eItemSpawnPoints[g_iLoadedItem][gZPos] = -1.0;
		g_eItemSpawnPoints[g_iLoadedItem][gIsActive] = false;
	}
	g_iLoadedItem = 0;
	g_iBlueGlow = PrecacheModel("sprites/blueglow1.vmt");
	loadItemSpawnPoints();
}

public void spawnItem(int id) {
	int eventEnt = CreateEntityByName("prop_dynamic_override");
	if (eventEnt == -1)
		return;
	char modelPath[128];
	Format(modelPath, sizeof(modelPath), g_cItemPath);
	SetEntityModel(eventEnt, modelPath);
	//DispatchKeyValue(eventEnt, "Solid", "6");
	//SetEntProp(eventEnt, Prop_Send, "m_nSolidType", 6);
	//SetEntProp(eventEnt, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
	char cId[8];
	IntToString(id, cId, sizeof(cId));
	SetEntPropString(eventEnt, Prop_Data, "m_iName", cId);
	SetEntPropFloat(eventEnt, Prop_Send, "m_flModelScale", g_fModelScale);
	DispatchSpawn(eventEnt);
	float pos[3];
	pos[0] = g_eItemSpawnPoints[id][gXPos];
	pos[1] = g_eItemSpawnPoints[id][gYPos];
	pos[2] = g_eItemSpawnPoints[id][gZPos];
	pos[2] += g_fZAxisOffset;
	TeleportEntity(eventEnt, pos, NULL_VECTOR, NULL_VECTOR);
	Entity_SetGlobalName(eventEnt, "EventItem");
	pos[2] -= g_fZAxisOffset;
	GiveEntityAura(eventEnt, g_cAuraPath, pos);
	
	int m_iRotator = CreateEntityByName("func_rotating");
	DispatchKeyValueVector(m_iRotator, "origin", pos);
	DispatchKeyValue(m_iRotator, "targetname", "Item");
	DispatchKeyValue(m_iRotator, "maxspeed", "200");
	DispatchKeyValue(m_iRotator, "friction", "0");
	DispatchKeyValue(m_iRotator, "dmg", "0");
	DispatchKeyValue(m_iRotator, "solid", "0");
	DispatchKeyValue(m_iRotator, "spawnflags", "64");
	DispatchSpawn(m_iRotator);
	
	SetVariantString("!activator");
	AcceptEntityInput(eventEnt, "SetParent", m_iRotator, m_iRotator);
	AcceptEntityInput(m_iRotator, "Start");
	
	SetEntPropEnt(eventEnt, Prop_Send, "m_hEffectEntity", m_iRotator);
	
	HookSingleEntityOutput(eventEnt, "OnStartTouch", EntOut_OnStartTouch);
	
	createTrigger(pos, cId);
	g_eItemSpawnPoints[id][gItemRef] = EntIndexToEntRef(eventEnt);
	
	g_eItemSpawnPoints[id][gIsActive] = true;
	g_iActiveItem++;
}

public void EntOut_OnStartTouch(const char[] output, int caller, int activator, float delay)
{
	if (activator < 1 || activator > MaxClients || !IsClientInGame(activator) || !IsPlayerAlive(activator))
		return;
	
	char cItemId[255];
	GetEntPropString(caller, Prop_Data, "m_iName", cItemId, sizeof(cItemId));
	int ItemId = StringToInt(cItemId);
	if (ItemId == -1)
		return;
	AcceptEntityInput(caller, "kill");
	g_eItemSpawnPoints[ItemId][gIsActive] = false;
	
	AcceptEntityInput(EntRefToEntIndex(g_eItemSpawnPoints[ItemId][gItemRef]), "kill");
	g_iActiveItem--;
	Store_SetClientCredits(activator, Store_GetClientCredits(activator) + g_iPickupCredits);
	incrementCollectedAmount(activator);
	
	if (g_iSpawnMode == 4) {
		for (int i = 0; i < g_iAntiExploidSpawnAmount; i++) {
			if (g_iRespawnDelays[i] < 1) {
				g_iRespawnDelays[i] = g_ipSpawnDelay;
				break;
			}
		}
	}
	float pos[3];
	GetClientAbsOrigin(activator, pos);
	
	if (!StrEqual(g_cPickupSoundPath, "")) {
		if (g_iSoundMode == 1)
			EmitSoundToClientAny(activator, g_cPickupSoundPath, activator, SNDCHAN_STATIC, _, _, 1.0, SNDPITCH_NORMAL);
		else if (g_iSoundMode == 2)
			EmitAmbientSoundAny(g_cPickupSoundPath, pos, _, _, _, _, _, _);
		else
			EmitSoundToAllAny(g_cPickupSoundPath, activator, SNDCHAN_STATIC, _, _, 1.0, SNDPITCH_NORMAL);
	}
	
	CPrintToChat(activator, "%t", "onCoinPickup", g_cChatTag, g_cItemName, g_iPickupCredits);
	triggerEffect(pos, g_cPickupEffectPath, 2.5);
}

public void onRoundStart(Handle event, const char[] name, bool dontBroadcast) {
	if (g_iLoadedItem == 0)
		return;
	randomNumbers = CreateArray(g_iLoadedItem, g_iLoadedItem);
	ClearArray(randomNumbers);
	for (int i = 0; i < g_iLoadedItem; i++) {
		PushArrayCell(randomNumbers, i);
	}
	
	for (int i = 0; i < MAX_Item; i++) {
		int index1 = GetRandomInt(0, (g_iLoadedItem - 1));
		int index2 = GetRandomInt(0, (g_iLoadedItem - 1));
		SwapArrayItems(randomNumbers, index1, index2);
	}
	
	if (g_iSpawnMode != 4) {
		for (int i = 0; i < MAX_Item; i++) {
			g_eItemSpawnPoints[i][gIsActive] = false;
		}
	} else {
		if (g_bEnableAntiAbuse) {
			if (g_inSpawnAmount > GetRealClientCount())
				g_iAntiExploidSpawnAmount = GetRealClientCount();
			else
				g_iAntiExploidSpawnAmount = g_inSpawnAmount;
		} else
			g_iAntiExploidSpawnAmount = g_inSpawnAmount;
		
		for (int n = 0; n < g_iLoadedItem; n++)
		if (g_eItemSpawnPoints[n][gIsActive])
			spawnItem(n);
		
		int activeTimers = 0;
		for (int i = 0; i < g_iAntiExploidSpawnAmount; i++)
		if (g_iRespawnDelays[i] > 0)
			activeTimers++;
		
		int activeItems = 0;
		for (int i = 0; i < g_iLoadedItem; i++)
		if (g_eItemSpawnPoints[i][gIsActive])
			activeItems++;
		
		if (activeTimers + activeItems < g_iAntiExploidSpawnAmount) {
			int toSpawn = g_iAntiExploidSpawnAmount - (activeTimers + activeItems);
			for (int i = 0; i < toSpawn; i++)
			spawnItemOnRandomSlot();
		}
		
	}
	/*r*/
	if (g_iSpawnMode != 1 && g_iSpawnMode != 2 && g_iSpawnMode != 3)
		return;
	
	int spawns = 0;
	if (g_iSpawnMode == 1)
		spawns = GetRealClientCount() * g_iSpawnAmount;
	else if (g_iSpawnMode == 2)
		spawns = 10 * g_iSpawnAmount;
	else
		spawns = GetRandomInt(g_iMinSpawnAmount, g_iMaxSpawnAmount);
	
	
	if (spawns > g_iLoadedItem)
		spawns = g_iLoadedItem;
	
	for (int i = 0; i < spawns; i++) {
		spawnItemOnRandomSlot();
	}
	CPrintToChatAll("%t", "coinSpawnOnRoundStart", g_cChatTag, spawns, g_cItemName);
}

public int spawnItemOnRandomSlot() {
	if (GetArraySize(randomNumbers) == 0)
		return -1;
	int spawnId = GetArrayCell(randomNumbers, 0);
	RemoveFromArray(randomNumbers, 0);
	spawnItem(spawnId);
	return spawnId;
}

public void loadItemSpawnPoints()
{
	char sRawMap[PLATFORM_MAX_PATH];
	char sMap[64];
	GetCurrentMap(sRawMap, sizeof(sRawMap));
	RemoveMapPath(sRawMap, sMap, sizeof(sMap));
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/event_Item/%s.txt", sMap);
	
	Handle hFile = OpenFile(sPath, "r");
	
	char sBuffer[512];
	char sDatas[3][32];
	
	if (hFile != INVALID_HANDLE)
	{
		while (ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
		{
			ExplodeString(sBuffer, ";", sDatas, 3, 32);
			
			g_eItemSpawnPoints[g_iLoadedItem][gXPos] = StringToFloat(sDatas[0]);
			g_eItemSpawnPoints[g_iLoadedItem][gYPos] = StringToFloat(sDatas[1]);
			g_eItemSpawnPoints[g_iLoadedItem][gZPos] = StringToFloat(sDatas[2]);
			
			g_iLoadedItem++;
		}
		
		CloseHandle(hFile);
	}
	PrintToServer("Loaded %i Item Spawn Points", g_iLoadedItem);
}

public void saveItemSpawnPoints()
{
	char sRawMap[PLATFORM_MAX_PATH];
	char sMap[64];
	GetCurrentMap(sRawMap, sizeof(sRawMap));
	RemoveMapPath(sRawMap, sMap, sizeof(sMap));
	
	CreateDirectory("configs/event_Item", 511);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/event_Item/%s.txt", sMap);
	
	
	
	Handle hFile = OpenFile(sPath, "w");
	
	if (hFile != INVALID_HANDLE)
	{
		for (int i = 0; i < g_iLoadedItem; i++) {
			WriteFileLine(hFile, "%.2f;%.2f;%.2f;", g_eItemSpawnPoints[i][gXPos], g_eItemSpawnPoints[i][gYPos], g_eItemSpawnPoints[i][gZPos]);
		}
		
		CloseHandle(hFile);
	}
	
	if (!FileExists(sPath))
		LogError("Couldn't save item spawns to  file: \"%s\".", sPath);
}

public void AddLootSpawn(int client, bool vision)
{
	float pos[3];
	if (vision) {
		float ang[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		TR_TraceRayFilter(pos, ang, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
		TR_GetEndPosition(pos);
	} else
		GetClientAbsOrigin(client, pos);
	
	TE_SetupGlowSprite(pos, g_iBlueGlow, 10.0, 1.0, 235);
	TE_SendToAll();
	
	g_eItemSpawnPoints[g_iLoadedItem][gXPos] = pos[0];
	g_eItemSpawnPoints[g_iLoadedItem][gYPos] = pos[1];
	g_eItemSpawnPoints[g_iLoadedItem][gZPos] = pos[2];
	g_iLoadedItem++;
	
	PrintToChat(client, "Added new spawnpoint at |<%.2f>:<%.2f>:<%.2f>| for type: %s", pos[0], pos[1], pos[2], g_cItemName);
	saveItemSpawnPoints();
}


public Action addSpawnPoints(int client, int args) {
	addSpawnPointsMenu(client, args);
	return Plugin_Handled;
}

public Action addSpawnPointsMenu(int client, int args)
{
	char ItemText[64];
	char ItemAim[64];
	
	Format(ItemText, sizeof(ItemText), "Spawn: %s (%i)", g_cItemName, g_iLoadedItem);
	Format(ItemAim, sizeof(ItemAim), "Spawn: %s (%i) [AIM]", g_cItemName, g_iLoadedItem);
	
	Handle panel = CreatePanel();
	SetPanelTitle(panel, "Add a Spawnpoint");
	DrawPanelText(panel, "x-x-x-x-x-x-x-x-x-x");
	DrawPanelItem(panel, ItemText);
	DrawPanelItem(panel, ItemAim);
	DrawPanelItem(panel, "Delete latest Spawnpoint");
	DrawPanelText(panel, "-------------");
	DrawPanelItem(panel, "Show Spawns");
	DrawPanelItem(panel, "Close");
	DrawPanelText(panel, "x-x-x-x-x-x-x-x-x-x");
	
	
	SendPanelToClient(panel, client, addSpawnPointsMenuHandler, 30);
	
	CloseHandle(panel);
	return Plugin_Handled;
}

public int addSpawnPointsMenuHandler(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		if (item == 1) {
			AddLootSpawn(client, false);
			addSpawnPointsMenu(client, 0);
		} else if (item == 2) {
			AddLootSpawn(client, true);
			addSpawnPointsMenu(client, 0);
		} else if (item == 3) {
			deleteLatestSpawn(client);
			addSpawnPointsMenu(client, 0);
		} else if (item == 4) {
			ShowSpawns();
			addSpawnPointsMenu(client, 0);
		}
	}
}

public void deleteLatestSpawn(int client) {
	g_iLoadedItem--;
	PrintToChat(client, "Deleted latest Spawn (%i left).", g_iLoadedItem);
	saveItemSpawnPoints();
}

public void ShowSpawns() {
	for (int i = 0; i < g_iLoadedItem; i++) {
		float pos[3];
		pos[0] = g_eItemSpawnPoints[i][gXPos];
		pos[1] = g_eItemSpawnPoints[i][gYPos];
		pos[2] = g_eItemSpawnPoints[i][gZPos];
		TE_SetupGlowSprite(pos, g_iBlueGlow, 10.0, 1.0, 235);
		TE_SendToAll();
	}
}

public int getActiveItem() {
	int count = 0;
	for (int i = 0; i < g_iLoadedItem; i++) {
		if (g_eItemSpawnPoints[i][gIsActive])
			count++;
	}
	return count;
}


stock void GiveEntityAura(any ent, char aura[255], float position[3])
{
	if (StrEqual(aura, ""))
		return;
	int AuraEntity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(AuraEntity, "start_active", "0");
	DispatchKeyValue(AuraEntity, "effect_name", aura);
	DispatchSpawn(AuraEntity);
	TeleportEntity(AuraEntity, position, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(AuraEntity);
	SetVariantString("!activator");
	AcceptEntityInput(AuraEntity, "SetParent", ent, AuraEntity, 0);
	CreateTimer(0.25, Timer_Run, AuraEntity);
}

stock void triggerEffect(float pos[3], char effect[255], float duration) {
	if (StrEqual(effect, ""))
		return;
	int spawnEffect = CreateEntityByName("info_particle_system");
	DispatchKeyValue(spawnEffect, "start_active", "0");
	DispatchKeyValue(spawnEffect, "effect_name", effect);
	DispatchSpawn(spawnEffect);
	ActivateEntity(spawnEffect);
	TeleportEntity(spawnEffect, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(spawnEffect, "Start");
	CreateTimer(duration, clearEffect, EntIndexToEntRef(spawnEffect));
}

public Action clearEffect(Handle Timer, any ent) {
	int iEnt = EntRefToEntIndex(ent);
	if (IsValidEdict(iEnt))
		if (IsValidEntity(iEnt))
		AcceptEntityInput(iEnt, "kill");
}

public Action Timer_Run(Handle Timer, any ent)
{
	if (ent > 0 && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Start");
	}
}


stock int GetRealClientCount() {
	int total = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && !IsFakeClient(i)) {
			total++;
		}
	}
	return total;
}


public int createTrigger(float pos[3], char sItemName[8])
{
	float fMiddle[3];
	int iEnt = CreateEntityByName("trigger_multiple");
	
	DispatchKeyValue(iEnt, "spawnflags", "64");
	Format(sItemName, sizeof(sItemName), "%s", sItemName);
	DispatchKeyValue(iEnt, "targetname", sItemName);
	DispatchKeyValue(iEnt, "wait", "0");
	
	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);
	SetEntProp(iEnt, Prop_Data, "m_spawnflags", 64);
	
	TeleportEntity(iEnt, pos, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(iEnt, g_cItemPath);
	
	float fMins[3];
	float fMaxs[3];
	
	fMins[0] = 30.0;
	fMins[1] = 30.0;
	fMins[2] = 30.0;
	fMaxs[0] = 30.0;
	fMaxs[1] = 30.0;
	fMaxs[2] = 30.0;
	
	
	// Have the mins always be negative
	fMins[0] = fMins[0] - fMiddle[0];
	if (fMins[0] > 0.0)
		fMins[0] *= -1.0;
	fMins[1] = fMins[1] - fMiddle[1];
	if (fMins[1] > 0.0)
		fMins[1] *= -1.0;
	fMins[2] = fMins[2] - fMiddle[2];
	if (fMins[2] > 0.0)
		fMins[2] *= -1.0;
	
	// And the maxs always be positive
	fMaxs[0] = fMaxs[0] - fMiddle[0];
	if (fMaxs[0] < 0.0)
		fMaxs[0] *= -1.0;
	fMaxs[1] = fMaxs[1] - fMiddle[1];
	if (fMaxs[1] < 0.0)
		fMaxs[1] *= -1.0;
	fMaxs[2] = fMaxs[2] - fMiddle[2];
	if (fMaxs[2] < 0.0)
		fMaxs[2] *= -1.0;
	
	SetEntPropVector(iEnt, Prop_Send, "m_vecMins", fMins);
	SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", fMaxs);
	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 2);
	
	int iEffects = GetEntProp(iEnt, Prop_Send, "m_fEffects");
	iEffects |= 32;
	SetEntProp(iEnt, Prop_Send, "m_fEffects", iEffects);
	
	HookSingleEntityOutput(iEnt, "OnStartTouch", EntOut_OnStartTouch);
}

public bool TraceRayDontHitSelf(int entity, int mask, any data) {
	if (entity == data)
		return false;
	return true;
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}


public Action getTopCollectors(int client, int args) {
	if (g_DB != INVALID_HANDLE) {
		char topCollectorsQuery[512];
		Format(topCollectorsQuery, sizeof(topCollectorsQuery), "SELECT playername,amount FROM eventItems_stats ORDER BY amount DESC LIMIT 10;");
		SQL_TQuery(g_DB, getTopCollectorsCallback, topCollectorsQuery, GetClientUserId(client));
	}
	return Plugin_Handled;
}

public void getTopCollectorsCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (hndl != INVALID_HANDLE) {
		if (isValidClient(client)) {
			Handle CreditsTopMenu = CreatePanel();
			int index = 0;
			
			char top_text[128];
			
			Format(top_text, sizeof(top_text), "%T", "topMenuTitle", client, g_cItemName);
			SetPanelTitle(CreditsTopMenu, top_text);
			
			DrawPanelText(CreditsTopMenu, "^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^");
			
			while (SQL_FetchRow(hndl)) {
				char name[MAX_NAME_LENGTH + 1];
				int top_points;
				
				SQL_FetchString(hndl, 0, name, sizeof(name));
				top_points = SQL_FetchInt(hndl, 1);
				
				Format(top_text, sizeof(top_text), "%i. %s - %i %s(s)", ++index, name, top_points, g_cItemName);
				
				DrawPanelText(CreditsTopMenu, top_text);
			}
			
			if (!index) {
				return;
			} else {
				
				DrawPanelText(CreditsTopMenu, "^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^-.-^");
				Format(top_text, sizeof(top_text), "Close");
				DrawPanelItem(CreditsTopMenu, top_text);
			}
			
			SendPanelToClient(CreditsTopMenu, client, globalPanelHandler, 60);
		}
	} else {
		LogError("SQL Error: %s", error);
	}
}

public int globalPanelHandler(Handle menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public bool isValidClient(int client) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	
	return true;
}


public Action getLoadedMaps(int client, int args)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "../../mapcycle.txt");
	
	Handle hFile = OpenFile(sPath, "r");
	
	char sBuffer[512];
	char mBuffer[256][48];
	
	int count = 0;
	if (hFile != INVALID_HANDLE) {
		while (ReadFileLine(hFile, sBuffer, sizeof(sBuffer))) {
			Format(mBuffer[count], sizeof(mBuffer), sBuffer);
			count++;
		}
		CloseHandle(hFile);
	}
	
	int fileCounter = 0;
	char fileBuffer[512][48];
	char Path[512];
	BuildPath(Path_SM, Path, sizeof(Path), "configs/event_Item");
	if (!DirExists(Path))
		return Plugin_Handled;
	
	DirectoryListing dL = OpenDirectory(Path);
	while (dL.GetNext(fileBuffer[fileCounter], sizeof(fileBuffer))) {
		ReplaceString(fileBuffer[fileCounter++], sizeof(fileBuffer), ".txt", "", false);
	}
	
	int notFoundCounter = 0;
	char notFound[256][48];
	for (int i = 0; i < count; i++) {
		for (int n = 0; n < fileCounter; n++) {
			if (StrEqual(fileBuffer[n], mBuffer[i]) && !StrEqual(fileBuffer[n], ""))
				break;
			if (n == (fileCounter - 1))
				strcopy(notFound[notFoundCounter++], sizeof(notFound), mBuffer[i]);
		}
	}
	
	CPrintToChat(client, "{green}Look in your console.");
	PrintToConsole(client, "Maps without SpawnPoints:");
	for (int i = 0; i < (notFoundCounter - 1); i++)
	PrintToConsole(client, "%s", notFound[i]);
	
	delete dL;
	return Plugin_Handled;
} 