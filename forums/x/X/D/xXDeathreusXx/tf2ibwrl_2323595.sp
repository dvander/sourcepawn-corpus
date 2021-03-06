#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <tf2items>
#define REQUIRE_PLUGIN
#include <tf2idb>
#include <itemsapi>

#define PLUGIN_VERSION		"1.0.0-20150704"
#define PLUGIN_UPDATE_URL	"pffft"

public Plugin:myinfo = {
	name = "[TF2Items] Bot Weapon Randomizer Lite",
	author = "Leonardo, Deathreus",
	description = "Give random weapons to bots",
	version = PLUGIN_VERSION,
	url = ""
};

////////////////////
/* Debug Printing */
////////////////////

#define ERROR_NONE		0		// PrintToServer only
#define ERROR_LOG		(1<<0)	// use LogToFile
#define ERROR_BREAKF	(1<<1)	// use ThrowError
#define ERROR_BREAKN	(1<<2)	// use ThrowNativeError
#define ERROR_BREAKP	(1<<3)	// use SetFailState
#define ERROR_NOPRINT	(1<<4)	// don't use PrintToServer

//////////////////////
/* Global Variables */
//////////////////////

// Forwards
//new Handle:hForward_OnGiveItem = INVALID_HANDLE;

// Console Variables
new Handle:tf2items_botweprand_version = INVALID_HANDLE;
new Handle:tf2items_bwr_enable = INVALID_HANDLE;
new Handle:tf2items_bwr_memory = INVALID_HANDLE;
new Handle:tf2items_bwr_checkforempty = INVALID_HANDLE;
new Handle:tf2items_bwr_checkformode = INVALID_HANDLE;
new Handle:tf2items_bwr_checkforstocks = INVALID_HANDLE;
new Handle:tf2items_bwr_checkdelay = INVALID_HANDLE;
new Handle:tf2items_bwr_config = INVALID_HANDLE;
new Handle:tf2items_bwr_logs = INVALID_HANDLE;
new Handle:tf2items_bwr_actionchance = INVALID_HANDLE;
new Handle:tf2items_bwr_debug = INVALID_HANDLE;
#if defined _updater_included
new Handle:tf2items_bwr_updater = INVALID_HANDLE;
#endif
new Handle:tf_bot_melee_only = INVALID_HANDLE;
new Handle:mp_stalemate_enable = INVALID_HANDLE;
new Handle:mp_stalemate_meleeonly = INVALID_HANDLE;

// Values of CVars
new bool:bPluginEnabled = true;
new bool:bMemory = true;
new bool:bCheckForEmpty = true;
new bool:bCheckForMode = true;
new bool:bCheckForStocks = true;
new Float:flCheckDelay = 0.1;
new bool:bUseLogs = true;
new iActionChance = 20;
new bool:bDebugMode = false;
#if defined _updater_included
new bool:bAutoUpdate = true;
#endif
new String:strConfigName[PLATFORM_MAX_PATH] = "tf2ibwr.schema.txt";

// Current Game Variables
new bool:bBotMelee = false;
new bool:bSuddenDeathEnabled = false;
new bool:bSuddenDeathMelee = false;
new bool:bMedieval = false;
new bool:bMannVsMachines = false;
new bool:bBirthday = false;
new bool:bHalloweenOrFullMoon = false;
new bool:bChristmas = false;

// SDK Calls
new Handle:hSDKEquipWearable = INVALID_HANDLE;

// Data Storage
new Handle:hPaints = INVALID_HANDLE;
new Handle:hEffects = INVALID_HANDLE;
new Handle:hItems = INVALID_HANDLE;
new Handle:hItemSets = INVALID_HANDLE;
new Handle:hSettings = INVALID_HANDLE;

// Bots' Equipment Data
new TFClassType:nLastTFClass[MAXPLAYERS+1] = { TFClass_Unknown, ... };
new Handle:hLastEquipment[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new bool:bRemoveOtherWeapons[MAXPLAYERS+1] = { false, ... };

//////////////////////
/* SourceMod Events */
//////////////////////

public OnPluginStart()
{
	// Create PluginVersion cvar first
	tf2items_botweprand_version = CreateConVar("tf2items_botweprand_version", PLUGIN_VERSION, "TF2Items Bot Weapon Randomizer", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(tf2items_botweprand_version, PLUGIN_VERSION, true, true);
	HookConVarChange(tf2items_botweprand_version, OnConVarChanged_PluginVersion);
	
	// Make sure it's Trade Fashion 2
	decl String:strGameDir[8];
	GetGameFolderName(strGameDir, sizeof(strGameDir));
	if(!StrEqual(strGameDir, "tf", false) && !StrEqual(strGameDir, "tf_beta", false))
		Error(ERROR_BREAKP|ERROR_LOG, _, "This plugin only works with TEam Fortress 2");
	
	// Create all other cvars
	tf2items_bwr_enable = CreateConVar("tf2items_bwr_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	tf2items_bwr_memory = CreateConVar("tf2items_bwr_memory", "1", "Toggle item saving", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	tf2items_bwr_debug = CreateConVar("tf2items_bwr_debug", "0", "Toggle debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	tf2items_bwr_logs = CreateConVar("tf2items_bwr_logs", "1", "Enable/disable logs", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	tf2items_bwr_config = CreateConVar("tf2items_bwr_config", strConfigName, "", FCVAR_PLUGIN);
	tf2items_bwr_checkforempty = CreateConVar("tf2items_bwr_checkforempty", "1", "Should it give weapons if none are found?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	tf2items_bwr_checkformode = CreateConVar("tf2items_bwr_checkformode", "1", "Toggle checking for suddendeath/medeival modes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	tf2items_bwr_checkforstocks = CreateConVar("tf2items_bwr_checkforstocks", "1", "Toggle checking if it should give stocks", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	tf2items_bwr_checkdelay = CreateConVar("tf2items_bwr_checkdelay", "0.1", "Force delay in doing it's checks", FCVAR_PLUGIN, true, 0.0, true, 0.25);
	
	HookConVarChange(tf2items_bwr_enable, OnConVarChanged);
	HookConVarChange(tf2items_bwr_memory, OnConVarChanged);
	HookConVarChange(tf2items_bwr_debug, OnConVarChanged);
	HookConVarChange(tf2items_bwr_logs, OnConVarChanged);
	HookConVarChange(tf2items_bwr_config, OnConVarChanged_ConfigName);
	HookConVarChange(tf2items_bwr_checkforempty, OnConVarChanged);
	HookConVarChange(tf2items_bwr_checkformode, OnConVarChanged);
	HookConVarChange(tf2items_bwr_checkforstocks, OnConVarChanged );
	HookConVarChange(tf2items_bwr_checkdelay, OnConVarChanged);
	
	// Game specified cvars
	tf2items_bwr_actionchance = CreateConVar("tf2items_bwr_actionchance", "20", "", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	tf_bot_melee_only = FindConVar("tf_bot_melee_only");
	mp_stalemate_enable = FindConVar("mp_stalemate_enable");
	mp_stalemate_meleeonly = FindConVar("mp_stalemate_meleeonly");
	
	HookConVarChange(tf2items_bwr_actionchance, OnConVarChanged);
	HookConVarChange(tf_bot_melee_only, OnConVarChanged);
	HookConVarChange(mp_stalemate_enable, OnConVarChanged);
	HookConVarChange(mp_stalemate_meleeonly, OnConVarChanged);
	
	// Hooking event
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", OnInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	
	// Config file reload commands
	RegAdminCmd("tf2items_bwr_refresh", Command_RefreshConfig, ADMFLAG_GENERIC);
	RegAdminCmd("tf2items_bwr_reload", Command_RefreshConfig, ADMFLAG_GENERIC);
	RegAdminCmd("tf2ibwr_refresh", Command_RefreshConfig, ADMFLAG_GENERIC);
	RegAdminCmd("tf2ibwr_reload", Command_RefreshConfig, ADMFLAG_GENERIC);
	RegAdminCmd("tf2ibwr_getchance", Command_GetItemChance, ADMFLAG_GENERIC);
	
	// Hooking SDK Calls
	decl String:strFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strFilePath, sizeof(strFilePath), "gamedata/tf2items.randomizer.txt");
	if(FileExists(strFilePath))
	{
		new Handle:hGameConf = LoadGameConfigFile( "tf2items.randomizer");
		if(hGameConf != INVALID_HANDLE)
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable");
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			hSDKEquipWearable = EndPrepSDKCall();
			if(hSDKEquipWearable == INVALID_HANDLE)
			{
				// Old gamedata
				StartPrepSDKCall(SDKCall_Player);
				PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "EquipWearable");
				PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
				hSDKEquipWearable = EndPrepSDKCall();
				if(hSDKEquipWearable == INVALID_HANDLE)
					Error(ERROR_LOG, _, "Could not initialize call for CTFPlayer::EquipWearable. Disabling wearables.");
			}
			CloseHandle(hGameConf);
		}
	}
	else
		Error(ERROR_LOG, _, "Could not locate tf2items.randomizer gamedata. Disabling wearables.");
	
	for(new iClient = 0; iClient <= MAXPLAYERS; iClient++)
		ClearMemory(iClient);
	
	AutoExecConfig(true);

	// Getting default cvars values
	OnConfigsExecuted();
	
	// Loading configs
	LoadConfigFile();
	if(LibraryExists("tf2idb"))
		TF2IDB_OnItemSchemaUpdated();
}

public OnLibraryAdded(const String:strLibrary[]) {
	if(StrEqual(strLibrary, "tf2idb", false))
		TF2IDB_OnItemSchemaUpdated();
}

public OnMapStart() {
	IsArenaMap(true);
}

public OnConfigsExecuted()
{
	// Plugin cvars
	bPluginEnabled = GetConVarBool(tf2items_bwr_enable);
	bMemory = GetConVarBool(tf2items_bwr_memory);
	bCheckForEmpty = GetConVarBool(tf2items_bwr_checkforempty);
	bCheckForMode = GetConVarBool(tf2items_bwr_checkformode);
	bCheckForStocks = GetConVarBool(tf2items_bwr_checkforstocks);
	flCheckDelay = GetConVarFloat(tf2items_bwr_checkdelay);
	if(flCheckDelay < 0.0) SetConVarFloat(tf2items_bwr_checkdelay, 0.0, false, true);
	GetConVarString(tf2items_bwr_config, strConfigName, sizeof(strConfigName));
	bUseLogs = GetConVarBool(tf2items_bwr_logs);
	
	new bool:bNewDebugMode = GetConVarBool(tf2items_bwr_debug);
	if(bNewDebugMode != bDebugMode)
	{
		Error( _, _, "Debug mode is now %s", bNewDebugMode?"Enabled":"Disabled");
		bDebugMode = bNewDebugMode;
	}
	
	// Game cvars
	iActionChance = GetConVarInt(tf2items_bwr_actionchance);
	bBotMelee = GetConVarBool(tf_bot_melee_only);
	bSuddenDeathEnabled = GetConVarBool(mp_stalemate_enable);
	bSuddenDeathMelee = GetConVarBool(mp_stalemate_meleeonly);
}

public OnGameFrame()
{
	bMedieval = !!GameRules_GetProp("m_bPlayingMedieval");
	bMannVsMachines = !!GameRules_GetProp("m_bPlayingMannVsMachine");
}

public TF2IDB_OnItemSchemaUpdated()
{
	if(hPaints != INVALID_HANDLE)
		CloseHandle(hPaints);
	hPaints = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item WHERE tool_type='paint_can'");
	if(GetArraySize(hPaints) <= 0)
	{
		// Don't waste memory
		CloseHandle(hPaints);
		hPaints = INVALID_HANDLE;
	}
	
	if(hEffects != INVALID_HANDLE)
		CloseHandle(hEffects);
	hEffects = TF2IDB_ListParticles();
	if(GetArraySize(hEffects) <= 0)
	{
		// Don't waste memory
		CloseHandle(hEffects);
		hEffects = INVALID_HANDLE;
	}
}

public OnClientPutInServer(iClient) {
	ClearMemory(iClient);
}

public OnClientDisconnect(iClient) {
	ClearMemory(iClient);
}

///////////////////
/* CVar handlers */
///////////////////

public OnConVarChanged_PluginVersion(Handle:hConVar, const String:strOldValue[], const String:strNewValue[]) {
	if(strcmp(strNewValue, PLUGIN_VERSION, false) != 0)
		SetConVarString(hConVar, PLUGIN_VERSION, true, true);
}

public OnConVarChanged_ConfigName(Handle:hConVar, const String:strOldValue[], const String:strNewValue[]) {
	Format(strConfigName, sizeof(strConfigName), strNewValue);
	LoadConfigFile();
}

public OnConVarChanged(Handle:hConVar, const String:strOldValue[], const String:strNewValue[]) {
	OnConfigsExecuted();
}

//////////////////////
/* Command handlers */
//////////////////////

public Action:Command_RefreshConfig(iClient, nArgs) {
	LoadConfigFile();
	return Plugin_Handled;
}

public Action:Command_GetItemChance(iClient, nArgs)
{
	if(nArgs < 2)
	{
		ReplyToCommand( iClient, "Usage: tf2ibwr_getchance <d|u|p|v|g|s|c> <item_id>" );
		return Plugin_Handled;
	}
	
	decl String:strBuffer[32];
	
	GetCmdArg(2, strBuffer, sizeof(strBuffer));
	if(!IsCharNumeric(strBuffer[0]))
	{
		ReplyToCommand(iClient, "Invalid item index!");
		return Plugin_Handled;
	}
	new iIndex = StringToInt(strBuffer);
	
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if(strBuffer[0] == 'd')
		strcopy(strBuffer, sizeof(strBuffer), "drop_chance");
	else if(strBuffer[0] == 'u')
		strcopy(strBuffer, sizeof(strBuffer), "unusual_chance");
	else if(strBuffer[0] == 'p')
		strcopy(strBuffer, sizeof(strBuffer), "paint_chance");
	else if(strBuffer[0] == 'v')
		strcopy(strBuffer, sizeof(strBuffer), "vintage_chance");
	else if(strBuffer[0] == 'g')
		strcopy(strBuffer, sizeof(strBuffer), "genuine_chance");
	else if(strBuffer[0] == 's')
		strcopy(strBuffer, sizeof(strBuffer), "strange_chance");
	else if(strBuffer[0] == 'c')
		strcopy(strBuffer, sizeof(strBuffer), "community_chance");
	else
	{
		ReplyToCommand(iClient, "Invalid chance type!");
		return Plugin_Handled;
	}
	
	FloatToString(GetItemChance(iIndex, strBuffer), strBuffer, sizeof(strBuffer));
	ReplyToCommand(iClient, "Item #%d: chance %s", iIndex, strBuffer);
	return Plugin_Handled;
}

////////////////////////////
/* Team Fortress 2 Events */
////////////////////////////

public OnPlayerSpawn(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iBot = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidBot(iBot))
		return;
	
	if(bSuddenDeathMelee && TF2_IsSuddenDeath())
	{
		if(bDebugMode)
			Error(ERROR_LOG|ERROR_NOPRINT, _, "Checking for sudden death (OnPlayerSpawn). (client:%d,userid:%d,class:%d)", iBot, GetClientUserId(iBot), TF2_GetPlayerClass(iBot));
		
		CheckSuddenDeath(iBot);
		
		if(FixTPose(iBot) < 0)
			Error(bDebugMode ? ERROR_LOG|ERROR_NOPRINT : ERROR_NONE, _, "Failed to fix Civilian Pose (OnPlayerSpawn)! (client:%d,userid:%d,class:%d)", iBot, GetClientUserId(iBot), TF2_GetPlayerClass(iBot));
	}
}

public OnInventoryApplication(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iUserID = GetEventInt(hEvent, "userid");
	new iBot = GetClientOfUserId(iUserID);
	
	if(!IsValidBot(iBot))
		return;
	
	if(bPluginEnabled)
		CreateTimer(flCheckDelay, Timer_OnInventoryApplication, iUserID, TIMER_FLAG_NO_MAPCHANGE);
}

public OnPlayerDeath(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iBot = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new iHuman = GetClientOfUserId( GetEventInt(hEvent, "userid"));
	if(!IsValidBot(iBot) || !IsValidClient(iHuman) || IsFakeClient(iHuman))
		return;
	
	if(IsItMyChance(float(iActionChance)))
	{
		FakeClientCommand(iBot, "+use_action_slot_item");
		FakeClientCommand(iBot, "-use_action_slot_item");
	}
}

public Action:TF2_OnIsHolidayActive(TFHoliday:hHoliday, &bool:bResult)
{
	if(hHoliday == TFHoliday_Birthday)
		bBirthday = bResult;
	else if(hHoliday == TFHoliday_HalloweenOrFullMoon)
		bHalloweenOrFullMoon = bResult;
	else if(hHoliday == TFHoliday_Christmas)
		bChristmas = bResult;
	return Plugin_Continue;
}

///////////////////////
/* Delayed functions */
///////////////////////

public Action:Timer_OnInventoryApplication(Handle:hTimer, any:iUserID)
{
	new iClient = GetClientOfUserId(iUserID);
	
	if(!IsValidBot(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Stop;
	
	// Check for class
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if(nLastTFClass[iClient] != iClass)
		ClearMemory(iClient);
	nLastTFClass[iClient] = iClass;
	if(!(TFClass_Unknown < iClass < TFClassType))
		return Plugin_Stop;
	
	if(bDebugMode)
	{
		Error(ERROR_LOG|ERROR_NOPRINT, _, "--------------------------------------------------");
		Error(ERROR_LOG|ERROR_NOPRINT, _, "Client: %L", iClient);
	}
	
	// Convert class number to class bits
	new iClassBits = (1 << (_:iClass - 1));
	
	// Get class name
	decl String:strCurClassName[16];
	GetTFClassName(iClass, strCurClassName, sizeof(strCurClassName));
	
	if(bDebugMode)
		Error(ERROR_LOG|ERROR_NOPRINT, _, "Class: %s (%d, %X)", strCurClassName, iClass, iClassBits);
	
	// Select possible slots
	new Handle:hFreeSlots = CreateArray(6);
	switch(iClass)
	{
		case TFClass_Spy:
		{
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Primary, "primary", strCurClassName);
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Sapper, "building", strCurClassName);
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Melee, "melee", strCurClassName);
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_PDA, "pda", strCurClassName);
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_PDA2, "pda2", strCurClassName);
		}
		case TFClass_Engineer:
		{
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Primary, "primary", strCurClassName);
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Secondary, "secondary", strCurClassName);
			if( bSuddenDeathMelee && TF2_IsSuddenDeath() || bBotMelee)
				CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Melee, "melee", strCurClassName);
			else
			{
				CheckSlot(iClient, hFreeSlots, TF2ItemSlot_PDA, "pda", strCurClassName);
				CheckSlot(iClient, hFreeSlots, TF2ItemSlot_PDA2, "pda2", strCurClassName);
			}
		}
		default:
		{
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Primary, "primary", strCurClassName);
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Secondary, "secondary", strCurClassName);
			CheckSlot(iClient, hFreeSlots, TF2ItemSlot_Melee, "melee", strCurClassName);
		}
	}
	if(GetArraySize(hFreeSlots) <= 0)
	{
		CloseHandle(hFreeSlots);
		if(bDebugMode)
		{
			Error(ERROR_LOG|ERROR_NOPRINT, _, "No free slots, finishing.");
			Error(ERROR_LOG|ERROR_NOPRINT, _, "--------------------------------------------------");
		}
		return Plugin_Stop;
	}
	
	// Array of items to equip
	new Handle:hItemList = CreateArray();
	new Handle:hEquipment = CreateArray(4);
	
	if(hLastEquipment[iClient] == INVALID_HANDLE)
		hLastEquipment[iClient] = CreateArray(4);
	
	// Array of used equipment regions
	new Handle:hEquipRegions;
	new Handle:hUsedEquipRegions = CreateArray(8);
	
	new bool:bUsingMemory = false;
	new bool:bUsingItemSet = false;
	
	decl String:strItemSlot[64], String:strItemClass[64];
	new iSlot, iArraySize;
	
	if(bMemory && GetArraySize(hLastEquipment[iClient]) > 0)
		bUsingMemory = true;
	
	if(!bUsingMemory)
	{
		ClearMemory(iClient, false);
		
		// Find random ItemSet
		if(IsItMyChance(KvGetFloat(hSettings, "itemset_echance")))
		{
			KvRewind(hItemSets);
			if(KvGotoFirstSubKey(hItemSets))
			{
				// Find random itemsets
				decl String:strItemSet[256], String:strSlot[16], String:strClassName[16], String:strItemEquipRegion[32];
				decl String:strRequiredSlots[3][16] = { "primary", "secondary", "melee" };
				new Handle:hListOfItemSets = CreateArray(64), w, i, iValidItem;
				do
				{
					KvGetSectionName(hItemSets, strItemSet, sizeof(strItemSet));
					
					if(GetItemSetChance(strItemSet) <= 0.0)
						continue;
					
					KvGetString(hItemSets, "class", strClassName, sizeof(strClassName), "");
					if(
						strlen(strClassName) <= 0
						|| !StrEqual(strClassName, "scout", false)
						&& !StrEqual(strClassName, "sniper", false)
						&& !StrEqual(strClassName, "soldier", false)
						&& !StrEqual(strClassName, "demoman", false)
						&& !StrEqual(strClassName, "medic", false)
						&& !StrEqual(strClassName, "heavy", false)
						&& !StrEqual(strClassName, "pyro", false)
						&& !StrEqual(strClassName, "spy", false)
						&& !StrEqual(strClassName, "engineer", false)
					)
					{
						Error(ERROR_LOG, _, "Error while parsing config file: ItemSet '%s' has invalid 'class' field!", strItemSet);
						continue;
					}
					if(!StrEqual(strClassName, strCurClassName, false))
						continue;
					
					// Check for valid weapons from ItemSet
					iValidItem = 1;
					if(KvGetNum(hItemSets, "strip", 0) > 0)
					{
						for(w = 0; w < sizeof(strRequiredSlots); w++)
						{
							i = -1;
							if(KvJumpToKey(hItemSets, strRequiredSlots[w], false))
							{
								i = KvGetNum(hItemSets, "item_id", -1);
								KvGoBack(hItemSets);
							}
							if(i <= -1 )
								i = KvGetNum(hItemSets, strRequiredSlots[w], -1);
							
							iValidItem = IsValidItem(i, strCurClassName);
							if(iValidItem == 0)
								break;
						}
					}
					else
					{
						iArraySize = GetArraySize(hFreeSlots);
						for(w = 0; w < iArraySize; w++)
						{
							i = -1;
							GetArrayString(hFreeSlots, w, strSlot, sizeof(strSlot));
							if(KvJumpToKey(hItemSets, strSlot, false))
							{
								i = KvGetNum(hItemSets, "item_id", -1);
								KvGoBack(hItemSets);
							}
							if(i <= -1)
								i = KvGetNum( hItemSets, strSlot, -1);
							
							iValidItem = IsValidItem(i, strCurClassName);
							if(iValidItem == 0)
								break;
						}
					}
					if(iValidItem > 0)
					{
						if(!!KvGetNum( hItemSets, "strip", 0) && iValidItem == 1)
							Error(ERROR_LOG, _, "Error while parsing config file: ItemSet '%s' has no valid weapons!", strItemSet);
						continue;
					}
					
					PushArrayString(hListOfItemSets, strItemSet);
				}
				while(KvGotoNextKey(hItemSets));
				
				// Select itemset
				decl String:strItemClassname[64], String:strItemQuality[16], String:strAttribIndex[16];
				new e, iResults = GetArraySize(hListOfItemSets) - 1, bool:bValidItem;
				new iItemID, iItemLevel, iItemQuality, nItemAttribs, iItemAIndexes[TF2IDB_MAX_ATTRIBUTES], Float:flItemAValues[TF2IDB_MAX_ATTRIBUTES];
				while(iResults >= 0 && !bUsingItemSet)
				{
					TakeRandStringFromArrayEx(hListOfItemSets, iResults, strItemSet, sizeof(strItemSet));
					
					if( !IsItMyChance(GetItemSetChance(strItemSet)) && iResults >= 0)
						continue;
					
					KvRewind(hItemSets);
					if(!KvJumpToKey(hItemSets, strItemSet, false))
						continue;
					
					iArraySize = GetArraySize(hFreeSlots);
					for(iSlot = 0; iSlot < iArraySize; iSlot++)
					{
						iItemID = -1;
						bValidItem = false;
						
						GetArrayString(hFreeSlots, iSlot, strItemSlot, sizeof(strItemSlot));
						if(strlen(strItemSlot) && KvJumpToKey(hItemSets, strItemSlot, false))
						{
							iItemID = KvGetNum(hItemSets, "item_id", -1);
							
							bValidItem = IsValidItem(iItemID, strCurClassName) == 0;
							if(bValidItem)
							{
								decl iLevelMin, iLevelMax;
								TF2IDB_GetItemLevels(iItemID, iLevelMin, iLevelMax);
								iItemLevel = KvGetNum(hItemSets, "level", GetRandInt(iLevelMin, iLevelMax));
								
								iItemQuality = KvGetNum(hItemSets, "quality", -1);
								if(iItemQuality <= -1)
								{
									TF2IDB_GetItemQualityName(iItemID, strItemQuality, sizeof(strItemQuality));
									iItemQuality = _:TF2IDB_GetItemQuality(iItemID);
								}
								
								TF2IDB_GetItemClass(iItemID, strItemClassname, sizeof(strItemClassname), iClass);
								
								nItemAttribs = 0;
								if(KvGetNum(hItemSets, "preserve-attributes", 1) > 0)
								{
									nItemAttribs = ItemsApi_GetNumAttributes(iItemID);
									TF2IDB_GetItemAttributes(iItemID, iItemAIndexes, flItemAValues);
								}
								
								if(nItemAttribs < TF2IDB_MAX_ATTRIBUTES)
									if(KvJumpToKey(hItemSets, "attributes", false))
									{
										if(KvGotoFirstSubKey(hItemSets))
										{
											do
											{
												KvGetSectionName(hItemSets, strAttribIndex, sizeof(strAttribIndex));
												if(IsCharNumeric(strAttribIndex[0]))
												{
													iItemAIndexes[nItemAttribs] = StringToInt(strAttribIndex);
													if(KvGetNum( hItemSets, "integer", 0) > 0)
														flItemAValues[nItemAttribs] = Float:KvGetNum(hItemSets, "value", 0);
													else
														flItemAValues[nItemAttribs] = KvGetFloat(hItemSets, "value", 0.0);
													nItemAttribs++;
												}
											}
											while(KvGotoNextKey(hItemSets) && nItemAttribs < TF2IDB_MAX_ATTRIBUTES);
											KvGoBack(hItemSets);
										}
										KvGoBack(hItemSets);
									}
								
								PushArrayCell(hEquipment, _:CreateItem(iItemID, strItemClassname, TF2ItemQuality:iItemQuality, iItemLevel, nItemAttribs, iItemAIndexes, flItemAValues));
							}
							KvGoBack(hItemSets);
						}
						
						if(iItemID <= -1)
						{
							iItemID = KvGetNum(hItemSets, strItemSlot, -1);
							bValidItem = IsValidItem(iItemID, strCurClassName) == 0;
							if(bValidItem)
								PushArrayCell(hItemList, iItemID);
						}
						
						if(!bValidItem)
							continue;
						
						RemoveFromArray(hFreeSlots, iSlot--);
						iArraySize--;
						
						hEquipRegions = TF2IDB_GetItemEquipRegions(iItemID);
						if(hEquipRegions != INVALID_HANDLE)
						{
							for(e = 0; e < GetArraySize(hEquipRegions); e++)
							{
								GetArrayString(hEquipRegions, e, strItemEquipRegion, sizeof(strItemEquipRegion));
								PushArrayString(hUsedEquipRegions, strItemEquipRegion);
							}
							CloseHandle(hEquipRegions);
						}
					}
					
					bRemoveOtherWeapons[iClient] = !!KvGetNum(hItemSets, "strip", 0);
					bUsingItemSet = true;
				}
				CloseHandle(hListOfItemSets);
			}
		}
		
		iArraySize = GetArraySize(hFreeSlots);
		if(!bRemoveOtherWeapons[iClient] && iArraySize > 0)
		{
			// Find random items
			decl String:strEquipRegion[2][32];
			new Handle:hListOfItems, k, Handle:hResults, iResults, iItemDefID, e1, e2, bool:bEquipRegionConflict;
			for(iSlot = 0; iSlot < iArraySize; iSlot++)
			{
				GetArrayString(hFreeSlots, iSlot, strItemSlot, sizeof(strItemSlot));
				
				if(bDebugMode)
					Error(ERROR_LOG|ERROR_NOPRINT, _, "Finding new items... (slot: %s)", strItemSlot);
				
				//========Fetch Items========//
				//new String:strQuery[128];
				//Format(strQuery, sizeof(strQuery), "SELECT a.id FROM tf2idb_item a JOIN tf2idb_class b ON a.id=b.id WHERE b.class='%s' AND slot='%s'", strCurClassName, strItemSlot);
				//hResults = TF2IDB_FindItemCustom(strQuery);
				//===========================//
				
				iResults = GetArraySize(hResults);
				if(iResults <= 0)
				{
					CloseHandle(hResults);
					if(bDebugMode)
						Error(ERROR_LOG|ERROR_NOPRINT, _, "No items found. (slot: %s)", strItemSlot);
					continue;
				}
				hListOfItems = CreateArray();
				for(k = 0; k < iResults; k++)
				{
					iItemDefID = GetArrayCell(hResults, k);
					
					if(IsValidItem(iItemDefID, strCurClassName) > 0)
						continue;
					
					// Check for equipment regions conflicts
					hEquipRegions = TF2IDB_GetItemEquipRegions(iItemDefID);
					if(hEquipRegions != INVALID_HANDLE)
					{
						bEquipRegionConflict = false;
						for(e1 = 0; e1 < GetArraySize( hUsedEquipRegions ); e1++)
						{
							GetArrayString(hUsedEquipRegions, e1, strEquipRegion[0], sizeof(strEquipRegion[]));
							for(e2 = 0; e2 < GetArraySize( hEquipRegions ); e2++)
							{
								GetArrayString(hEquipRegions, e2, strEquipRegion[1], sizeof(strEquipRegion[]) );
								bEquipRegionConflict = TF2IDB_DoRegionsConflict(strEquipRegion[0], strEquipRegion[1]);
								if(bEquipRegionConflict)
									break;
							}
							if(bEquipRegionConflict)
								break;
						}
						CloseHandle(hEquipRegions);
						if(bEquipRegionConflict)
							continue;
					}
					
					PushArrayCell(hListOfItems, iItemDefID);
				}
				CloseHandle(hResults);
				
				if(GetArraySize(hListOfItems) <= 0)
				{
					CloseHandle(hListOfItems);
					if(bDebugMode)
						Error(ERROR_LOG|ERROR_NOPRINT, _, "No items found. (filtered slot: %s)", strItemSlot);
					continue;
				}
				
				// Select item
				iItemDefID = -1;
				iResults = GetArraySize(hListOfItems) - 1;
				while(iResults >= 0 && iItemDefID == -1)
				{
					iItemDefID = TakeRandCellFromArrayEx(hListOfItems, iResults);
					if(!IsItMyChance(GetItemChance(iItemDefID, "drop_chance", strCurClassName)))
						iItemDefID = -1;
				}
				CloseHandle(hListOfItems);
				
				if(iItemDefID > -1) // Preventing equiping an invalid item
				{
					PushArrayCell(hItemList, iItemDefID);
					
					RemoveFromArray(hFreeSlots, iSlot--);
					iArraySize--;
					
					hEquipRegions = TF2IDB_GetItemEquipRegions(iItemDefID);
					if(hEquipRegions != INVALID_HANDLE)
					{
						for(e2 = 0; e2 < GetArraySize(hEquipRegions); e2++)
						{
							GetArrayString(hEquipRegions, e2, strEquipRegion[1], sizeof(strEquipRegion[]));
							PushArrayString(hUsedEquipRegions, strEquipRegion[1]);
						}
						CloseHandle(hEquipRegions);
					}
				}
			}
		}
		
		
		// Generate TF2Items objects
		iArraySize = GetArraySize(hItemList);
		if(iArraySize > 0)
		{
			decl String:strQualityName[16];
			new iItemDefID, iLevel, iLevelMin, iLevelMax, TF2ItemQuality:iQuality;
			new nAttribs, iAIndexes[TF2IDB_MAX_ATTRIBUTES], Float:flAValues[TF2IDB_MAX_ATTRIBUTES];
			for(new n = 0; n < iArraySize; n++)
			{
				iItemDefID = GetArrayCell(hItemList, n);
				
				// Get default data
				
				TF2IDB_GetItemClass(iItemDefID, strItemClass, sizeof(strItemClass), iClass);
				
				TF2IDB_GetItemSlotName(iItemDefID, strItemSlot, sizeof(strItemSlot));
				
				TF2IDB_GetItemLevels(iItemDefID, iLevelMin, iLevelMax);
				iLevel = GetRandInt(iLevelMin, iLevelMax);
				
				TF2IDB_GetItemQualityName(iItemDefID, strQualityName, sizeof(strQualityName));
				iQuality = TF2IDB_GetItemQuality(iItemDefID);
				
				nAttribs = ItemsApi_GetNumAttributes(iItemDefID);
				TF2IDB_GetItemAttributes(iItemDefID, iAIndexes, flAValues);
				
				// SAVED!
				PushArrayCell(hEquipment, _:CreateItem(iItemDefID, strItemClass, iQuality, iLevel, nAttribs, iAIndexes, flAValues));
				
				if(bDebugMode)
					Error(ERROR_LOG|ERROR_NOPRINT, _, "Adding item #%d. (slot:%s)", iItemDefID, strItemSlot);
			}
		}
		
		// Update memory
		if(bMemory)
		{
			hLastEquipment[iClient] = CloneArray(hEquipment);
			//if(bDebugMode)
			//	Error(ERROR_LOG|ERROR_NOPRINT, _, "%N - memory in - %d items", iClient, GetArraySize(hLastEquipment[iClient]));
		}
	}
	else
	{
		hEquipment = CloneArray(hLastEquipment[iClient]);
		//if(bDebugMode)
		//	Error(ERROR_LOG|ERROR_NOPRINT, _, "%N - memory out - %d items", iClient, GetArraySize(hLastEquipment[iClient]));
	}
	CloseHandle(hUsedEquipRegions);
	CloseHandle(hItemList);
	
	// Remove unused slots (ItemSet option)
	if(bRemoveOtherWeapons[iClient] && GetArraySize(hFreeSlots) > 0)
	{
		for(iSlot = 0; iSlot < GetArraySize(hFreeSlots); iSlot++)
		{
			GetArrayString(hFreeSlots, iSlot, strItemSlot, sizeof(strItemSlot));
			if(StrEqual("primary", strItemSlot, false))
				TF2_RemoveWeaponSlot(iClient, _:TF2ItemSlot_Primary);
			else if(StrEqual("melee", strItemSlot, false))
				TF2_RemoveWeaponSlot(iClient, _:TF2ItemSlot_Melee);
			else if(StrEqual("secondary", strItemSlot, false ) && iClass != TFClass_Spy)
				TF2_RemoveWeaponSlot(iClient, _:TF2ItemSlot_Secondary);
			else if(StrEqual("building", strItemSlot, false ) && iClass == TFClass_Spy)
				TF2_RemoveWeaponSlot(iClient, _:TF2ItemSlot_Sapper );
			if(iClass == TFClass_Spy || iClass == TFClass_Engineer )
			{
				if(StrEqual("pda", strItemSlot, false))
					TF2_RemoveWeaponSlot(iClient, _:TF2ItemSlot_PDA);
				else if(StrEqual("pda2", strItemSlot, false))
					TF2_RemoveWeaponSlot(iClient, _:TF2ItemSlot_PDA2);
			}
		}
	}
	CloseHandle(hFreeSlots);
	
	// Give those items!
	new nGivenItems, iItemSlot, Handle:hCell, Handle:hItem, iItem;
	for(new m = 0; m < GetArraySize(hEquipment); m++)
	{
		hCell = Handle:GetArrayCell(hEquipment, m);
		if(hCell == INVALID_HANDLE)
			continue;
		
		hItem = CloneHandle(hCell);
		if(!bMemory)
			CloseHandle(Handle:GetArrayCell(hEquipment, m));
		
		if(bDebugMode)
			Error(ERROR_LOG|ERROR_NOPRINT, _, "Giving item #%d.", TF2Items_GetItemIndex(hItem));
		
		iItemSlot = _:GetItemSlotNumber(TF2Items_GetItemIndex(hItem), TF2_GetPlayerClass(iClient));
		
		TF2Items_GetClassname(hItem, strItemClass, sizeof(strItemClass));
		if(StrEqual(strItemClass, "saxxy", false))
			TF2_RemoveWeaponSlot(iClient, iItemSlot);
		
		iItem = TF2Items_GiveNamedItem(iClient, hItem);
		CloseHandle(hItem);
		if(!IsValidEdict(iItem))
		{
			if(bDebugMode)
				Error(ERROR_LOG|ERROR_NOPRINT, _, "Failed to generate item #%d!", TF2Items_GetItemIndex(hItem));
			else
				Error(ERROR_LOG, _, "Failed to generate item #%d! (client:%d,userid:%d,class:%d)", TF2Items_GetItemIndex(hItem), iClient, GetClientUserId(iClient), iClass);
			continue;
		}
		
		if(StrContains(strItemClass, "tf_weapon", false) == 0 || strcmp(strItemClass, "saxxy", false) == 0)
		{
			TF2_RemoveWeaponSlot(iClient, iItemSlot);
			EquipPlayerWeapon(iClient, iItem);
			nGivenItems++;
		}
	}
	CloseHandle(hEquipment);
	
	if(bDebugMode)
		Error(ERROR_LOG|ERROR_NOPRINT, _, "Checking for sudden death (Timer_OnInventoryApplication).");
	
	if(iClass == TFClass_Spy)
		PrepareSappers(iClient);
	
	CheckSuddenDeath(iClient);
	
	if(FixTPose(iClient) < 0)
		if(bDebugMode)
			Error(ERROR_LOG|ERROR_NOPRINT, _, "Failed to fix Civilian Pose (Timer_OnInventoryApplication)!");
		else
			Error(_, _, "Failed to fix Civilian Pose (Timer_OnInventoryApplication)! (client:%d,userid:%d,class:%d)", iClient, GetClientUserId(iClient), iClass);
	
	if(bDebugMode)
	{
		Error(ERROR_LOG|ERROR_NOPRINT, _, "%d item(s) given, finishing.", nGivenItems);
		Error(ERROR_LOG|ERROR_NOPRINT, _, "--------------------------------------------------");
	}
	
	return Plugin_Stop;
}

///////////////////////
/* Private functions */
///////////////////////

FixTPose(iClient)
{
	new iWeapon = -1;
	
	if(!IsValidBot(iClient) || !IsPlayerAlive(iClient))
		return iWeapon;
	
	for(new s = 0; s < _:TF2ItemSlot; s++)
	{
		iWeapon = GetPlayerWeaponSlot(iClient, s);
		if(IsValidEdict(iWeapon))
		{
			EquipPlayerWeapon(iClient, iWeapon);
			return iWeapon;
		}
	}
	
	return iWeapon;
}

CheckSuddenDeath(iClient)
{
	if(!(bSuddenDeathMelee && TF2_IsSuddenDeath()))
		return;
	
	if(!IsValidBot(iClient) || !IsPlayerAlive(iClient))
		return;
	
	decl String:strClassName[TF2IDB_ITEMCLASS_LENGTH];
	for(new i = 0, iWeapon; i < 48; i++)
	{
		iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i);
		if(iWeapon > 0 && IsValidEdict(iWeapon))
		{
			GetEntityClassname(iWeapon, strClassName, sizeof(strClassName));
			if(!StrEqual(strClassName, "saxxy", false ) && StrContains(strClassName, "tf_weapon", false) < 0 && StrContains(strClassName, "tf_wearable", false) < 0)
				continue;
			
			if(!(TF2IDB_GetItemSlot(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")) == TF2ItemSlot_Melee 
			|| StrContains(strClassName, "tf_wearable", false) >= 0 || StrContains(strClassName, "tf_weapon_buff_item", false) >= 0 
			|| StrContains(strClassName, "tf_weapon_lunchbox", false) >= 0))
			{
				RemovePlayerItem(iClient, iWeapon);
				AcceptEntityInput(iWeapon, "Kill");
			}
		}
	}
}

LoadConfigFile()
{
	new String:strChances[6][] = {
		"drop_chance", "vintage_chance", "genuine_chance",
		"strange_chance", "itemset_echance", "itemset_chance"
	};
	new String:strClasses[9][] = {
		"scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"
	};
	
	if(hSettings != INVALID_HANDLE)
		CloseHandle(hSettings);
	hSettings = CreateKeyValues("settings");
	KvSetNum(hSettings, "wearables", 1);
	KvSetNum(hSettings, "action_slot", 1);
	for(new c = 0; c < sizeof(strChances); c++)
		KvSetFloat(hSettings, strChances[c], 50.0);
	
	if(hItems != INVALID_HANDLE)
		CloseHandle(hItems);
	hItems = CreateKeyValues("items");
	
	if(hItemSets != INVALID_HANDLE)
		CloseHandle(hItemSets);
	hItemSets = CreateKeyValues("itemsets");
	
	
	decl String:strFilePath[PLATFORM_MAX_PATH], String:strSectionName[64*6];
	BuildPath(Path_SM, strFilePath, sizeof(strFilePath), "configs/%s", strConfigName);
	if(!FileExists(strFilePath))
	{
		Error(ERROR_LOG, _, "Couldn't found config file: %s", strFilePath);
		return;
	}
	
	new Handle:hConfigFile = CreateKeyValues("items_config");
	if(!FileToKeyValues(hConfigFile, strFilePath))
	{
		Error(ERROR_LOG, _, "Failed to parse config file: %s", strFilePath);
		CloseHandle(hConfigFile);
		return;
	}
	KvRewind(hConfigFile);
	
	
	if(KvJumpToKey(hConfigFile, "settings", false))
	{
		KvCopySubkeys(hConfigFile, hSettings);
		KvGoBack(hConfigFile);
	}
	
	if(KvJumpToKey(hConfigFile, "itemsets", false))
	{
		KvCopySubkeys(hConfigFile, hItemSets);
		KvGoBack(hConfigFile);
	}
	
	decl String:strIndexes[64][15], String:strRange[2][8], String:strBuffer[64];
	new nParts, nSubParts, i, iMin, iMax, Float:flChance;
	if(KvJumpToKey(hConfigFile, "items", false) && KvGotoFirstSubKey(hConfigFile))
		do
		{
			KvGetSectionName(hConfigFile, strSectionName, sizeof(strSectionName));
			nParts = ExplodeString(strSectionName, ",", strIndexes, sizeof(strIndexes), sizeof(strIndexes[]));
			for(new p = 0; p < nParts; p++)
			{
				TrimString(strIndexes[p]);
				nSubParts = ExplodeString(strIndexes[p], "..", strRange, sizeof(strRange), sizeof(strRange[]));
				if(nSubParts > 1)
				{
					TrimString(strRange[0]);
					TrimString(strRange[1]);
					iMin = StringToInt(strRange[0]);
					iMax = StringToInt(strRange[1]);
					if(iMin <= 0 && !StrEqual("0", strRange[0], false) || iMax <= 0 && !StrEqual("0", strRange[1], false) || iMin > iMax)
					{
						Error(ERROR_LOG, _, "Error while parsing config file: invalid range of indexes '%s'", strIndexes[p]);
						continue;
					}
					for(new r = iMin; r <= iMax; r++)
					{
						IntToString(r, strBuffer, sizeof(strBuffer));
						KvRewind(hItems);
						if(KvJumpToKey(hItems, strBuffer, false))
							Error(ERROR_LOG, _, "Warning while parsing config file: multiple usage of index '%s'", strBuffer);
						else
							KvJumpToKey(hItems, strBuffer, true);
						for(i = 0; i < sizeof(strChances); i++)
						{
							flChance = KvGetFloat(hConfigFile, strChances[i], -1.0);
							if(flChance < 0.0 && KvJumpToKey(hConfigFile, strChances[i], false))
							{
								KvSetFloat(hItems, strChances[i], KvGetFloat(hConfigFile, "any", KvGetFloat(hSettings, strChances[i])));
								for(new j = 0; j < sizeof(strClasses); j++)
								{
									flChance = KvGetFloat(hItems, strClasses[j], -1.0);
									if( flChance >= 0.0 )
									{
										Format(strBuffer, sizeof(strBuffer), "%s_%s", strChances[i], strClasses[j]);
										KvSetFloat(hItems, strBuffer, flChance);
									}
								}
								KvGoBack(hConfigFile);
							}
							else
								KvSetFloat(hItems, strChances[i], KvGetFloat(hConfigFile, strChances[i], KvGetFloat(hSettings, strChances[i])));
						}
					}
				}
				else
				{
					i = StringToInt(strIndexes[p]);
					if(i <= 0 && !StrEqual("0", strIndexes[p], false))
					{
						Error(ERROR_LOG, _, "Error while parsing config file: invalid item index '%s'", strIndexes[p]);
						continue;
					}
					IntToString(i, strBuffer, sizeof(strBuffer));
					KvRewind(hItems);
					if(KvJumpToKey(hItems, strBuffer, false))
						Error(ERROR_LOG, _, "Warning while parsing config file: multiple usage of index '%s'", strBuffer);
					else
						KvJumpToKey(hItems, strBuffer, true);
					for(i = 0; i < sizeof(strChances); i++)
					{
						flChance = KvGetFloat(hConfigFile, strChances[i], -1.0);
						if(flChance < 0.0 && KvJumpToKey(hConfigFile, strChances[i], false))
						{
							KvSetFloat(hItems, strChances[i], KvGetFloat(hConfigFile, "any", KvGetFloat( hSettings, strChances[i])));
							for(new j = 0; j < sizeof(strClasses); j++)
							{
								flChance = KvGetFloat(hItems, strClasses[j], -1.0);
								if(flChance >= 0.0)
								{
									Format(strBuffer, sizeof(strBuffer), "%s_%s", strChances[i], strClasses[j]);
									KvSetFloat(hItems, strBuffer, flChance);
								}
							}
							KvGoBack(hConfigFile);
						}
						else
							KvSetFloat(hItems, strChances[i], KvGetFloat(hConfigFile, strChances[i], KvGetFloat(hSettings, strChances[i])));
					}
				}
			}
		}
		while(KvGotoNextKey(hConfigFile));
	
	CloseHandle(hConfigFile);
	
	Error(_, _, "Config file loaded.");
}

ClearMemory(iClient, bool:bFull = true)
{
	if(iClient < 0 || iClient > MAXPLAYERS)
		return;
	
	new Handle:hItem;
	if(hLastEquipment[iClient] != INVALID_HANDLE)
	{
		if(GetArraySize(hLastEquipment[iClient]) > 0)
			for(new i = 0; i < GetArraySize(hLastEquipment[iClient]); i++)
				if((hItem = Handle:GetArrayCell(hLastEquipment[iClient], i)) != INVALID_HANDLE)
					CloseHandle(hItem);
		CloseHandle(hLastEquipment[iClient]);
	}
	hLastEquipment[iClient] = INVALID_HANDLE;
	
	bRemoveOtherWeapons[iClient] = false;
	
	if(bFull)
		nLastTFClass[iClient] = TFClass_Unknown;
}

CheckSlot(iClient, &Handle:hSlots, TF2ItemSlot:iSlot, const String:strSlotName[], const String:strPlayerClass[] = "")
{
	if(!IsValidBot(iClient) || !IsPlayerAlive(iClient))
		return;
	
	new iCurWeapon = GetPlayerWeaponSlot(iClient, _:iSlot);
	if(IsValidEdict(iCurWeapon))
	{
		new iItemDefID = GetEntProp(iCurWeapon, Prop_Send, "m_iItemDefinitionIndex");
		//new Handle:hBaseItem = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item WHERE baseitem=1");
		if(!bCheckForStocks || TF2IDB_ItemIsBaseItem(iItemDefID) && GetEntProp(iCurWeapon, Prop_Send, "m_iEntityQuality") == _:TF2ItemQuality_Normal)
		{
			if(IsValidItem(iItemDefID, strPlayerClass) > 0)
				TF2_RemoveWeaponSlot(iClient, _:iSlot);
			PushArrayString(hSlots, strSlotName);
		}
	}
	else if(!bCheckForEmpty || bCheckForMode && bMedieval)
		PushArrayString(hSlots, strSlotName);
}

#if 0
RemoveFreeSlot(&Handle:hSlots, const String:strSlotName[])
{
	new iIndex = FindStringInArray(hSlots, strSlotName);
	if(iIndex > -1)
	{
		RemoveFromArray(hSlots, iIndex);
		return true;
	}
	return false;
}
#endif

// 0 - no errors
// 1 - invalid item
// 2 - restricted by event
IsValidItem(iItemDefID, const String:strPlayerClass[] = "")
{
	if(!TF2IDB_IsValidItemID(iItemDefID))
		return 1;
	
	new bool:bMeleeOnly = bSuddenDeathMelee && TF2_IsSuddenDeath();
	
	// Always allow tf_weapon_builder for engineer (except sudden death)
	if(iItemDefID == 28)
		return (bMeleeOnly ? 2 : 0);
	
	if(GetItemChance(iItemDefID, "drop_chance", strPlayerClass) <= 0.0)
		return 1;
	
	decl String:strItemClass[64];
	TF2IDB_GetItemClass(iItemDefID, strItemClass, sizeof(strItemClass));
	if(!(StrEqual(strItemClass, "saxxy", false) || StrContains(strItemClass, "tf_weapon", false) == 0))
		return 1;
	
	if(bMeleeOnly && GetItemSlotNumber(iItemDefID) <= TF2ItemSlot_Secondary)
		return 2;
	
	if(bCheckForMode)
	{
		if(bMedieval && !ItemCanBeMedieval(iItemDefID))
		{
			decl String:strSlot[16];
			TF2IDB_GetItemSlotName(iItemDefID, strSlot, sizeof(strSlot));
			if(!StrEqual(strSlot, "melee", false) && !StrEqual(strSlot, "head", false) && !StrEqual(strSlot, "misc", false) && !StrEqual(strSlot, "action", false) && StrContains(strSlot, "pda", false) != 0)
				return 2;
		}
		/*if(!bBirthday && TF2IDB_ItemHolidayRestriction(iItemDefID, TFHoliday_Birthday))
			return 2;
		if(!bHalloweenOrFullMoon && TF2IDB_ItemHolidayRestriction(iItemDefID, TFHoliday_HalloweenOrFullMoon))
			return 2;
		if(!bChristmas && TF2IDB_ItemHolidayRestriction(iItemDefID, TFHoliday_Christmas))
			return 2;*/
	}
	
	return 0;
}

Float:GetItemChance(iItemDefID, const String:strChanceName[], const String:strPlayerClass[] = "")
{
	decl String:strItemDefID[16];
	IntToString(iItemDefID, strItemDefID, sizeof(strItemDefID));
	KvRewind(hItems);
	if(KvJumpToKey(hItems, strItemDefID, false))
	{
		new Float:flChance = KvGetFloat(hItems, strChanceName, KvGetFloat(hSettings, strChanceName));
		if(strlen(strPlayerClass) > 0)
		{
			decl String:strBuffer[64];
			Format(strBuffer, sizeof(strBuffer), "%s_%s", strChanceName, strPlayerClass);
			return KvGetFloat(hItems, strBuffer, flChance);
		}
		return flChance;
	}
	return KvGetFloat(hSettings, strChanceName);
}
Float:GetItemSetChance(const String:strItemSet[])
{
	KvRewind(hItemSets);
	if(KvJumpToKey(hItemSets, strItemSet, false))
		return KvGetFloat(hItemSets, "chance", KvGetFloat(hSettings, "itemset_chance"));
	return KvGetFloat(hSettings, "itemset_chance");
}

/////////////////////
/* Stock functions */
/////////////////////

// Create TF2Items handle

stock Handle:CreateItem(iItemDefinitionIndex, String:strClassname[], TF2ItemQuality:iQuality = TF2ItemQuality_Unique, iLevel = 1, iNumAttributes = 0, iAttributeIDs[] = {}, Float:flAttributeValues[] = {})
{
	//new Handle:hBaseItem = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item WHERE baseitem=1");
	if(TF2IDB_ItemIsBaseItem(iItemDefinitionIndex))
	{
		if(iQuality != TF2ItemQuality_Normal)
			iQuality = TF2ItemQuality_Normal;
	}
	else if(iQuality <= TF2ItemQuality_Normal || iQuality > TF2ItemQuality:12)
		iQuality = TF2ItemQuality_Unique;
	
	new Handle:hItem = TF2Items_CreateItem(strcmp(strClassname, "saxxy", false) == 0 ? OVERRIDE_ALL : OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hItem, strClassname);
	TF2Items_SetItemIndex(hItem, iItemDefinitionIndex);
	TF2Items_SetQuality(hItem, _:iQuality);
	TF2Items_SetLevel(hItem, iLevel);
	TF2Items_SetNumAttributes(hItem, iNumAttributes);
	if(iNumAttributes > 0)
		for(new a = 0; a < (iNumAttributes > TF2IDB_MAX_ATTRIBUTES ? TF2IDB_MAX_ATTRIBUTES : iNumAttributes); a++)
			TF2Items_SetAttribute(hItem, a, iAttributeIDs[a], flAttributeValues[a]);
	return hItem;
}

// Handling errors

stock Error(iFlags = ERROR_NONE, iNativeErrCode = SP_ERROR_NONE, const String:strMessage[], any:...)
{
	decl String:strBuffer[1024];
	VFormat(strBuffer, sizeof(strBuffer), strMessage, 4);
	
	if(iFlags)
	{
		if(iFlags & ERROR_LOG && bUseLogs)
		{
			decl String:strFile[PLATFORM_MAX_PATH];
			FormatTime(strFile, sizeof(strFile), "%Y%m%d");
			Format(strFile, sizeof(strFile), "TF2IBWR%s", strFile);
			BuildPath(Path_SM, strFile, sizeof(strFile), "logs/%s.log", strFile);
			LogToFileEx(strFile, strBuffer);
		}
		
		if(iFlags & ERROR_BREAKF)
			ThrowError(strBuffer);
		if(iFlags & ERROR_BREAKN)
			ThrowNativeError(iNativeErrCode, strBuffer);
		if(iFlags & ERROR_BREAKP)
			SetFailState(strBuffer);
		
		if(iFlags & ERROR_NOPRINT)
			return;
	}
	
	PrintToServer("[TF2IBWR] %s", strBuffer);
}

// Validations

stock bool:IsValidClient(iClient)
{
	if(iClient <= 0) return false;
	if(iClient > MaxClients ) return false;
	if(!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}

stock bool:IsValidBot(iBot)
{
	if(!IsValidClient(iBot)) return false;
	if(IsClientSourceTV(iBot)) return false;
	if(IsClientReplay(iBot)) return false;
	new iTeam = GetClientTeam(iBot);
	if(iTeam <= 1) return false;
	if(bMannVsMachines && iTeam == 3) return false;
	return IsFakeClient(iBot);
}

stock bool:TF2_IsSuddenDeath()
{
	if(!bSuddenDeathEnabled || IsArenaMap())
		return false;
	return GameRules_GetRoundState() == RoundState_Stalemate;
}

stock bool:IsItemCanBeCommunity(iItem)
{
	switch(iItem)
	{
		case
			/* Stock weapons!
			4,	 // Knife
			7,	 // Wrench
			9,	 // Shotgun (Engineer)
			10,	 // Shotgun (Soldier)
			11,	 // Shotgun (Heavy)
			12,	 // Shotgun (Pyro)
			13,	 // Scattergun
			14,	 // Sniper Rifle
			15,	 // Minigun
			18,	 // Rocket launcher
			19,	 // Grenade launcher
			20,	 // Stickybomb launcher
			21,	 // Flamethrower
			29,	 // Medigun
			*/
			40,	 // Backburner
			45,	 // Force-A-Nature
			56,	 // Huntsman
			194, // Upgr Knife
			197, // Upgr Wrench
			199, // Upgr Shotgun
			200, // Upgr Scattergun
			201, // Upgr Sniper Rifle
			202, // Upgr Minigun
			205, // Upgr Rocket launcher
			206, // Upgr Grenade launcher
			207, // Upgr Stickybomb launcher
			208, // Upgr Flamethrower
			211, // Upgr Medigun
			215, // Degreaser
		: return true;
	}
	return false;
}

stock bool:ItemCanBeMedieval(iItem)
{
	switch(iItem)
	{
		case 46,163,222,812,833,1121,1145,0,190,44,221,264,317,325,349,
		355,423,450,452,474,572,648,660,880,939,954,999,1013,1071,129,
		133,226,354,444,1001,1101,6,196,128,154,357,416,447,473,
		775,1123,1127,2,192,38,153,214,326,348,457,466,593,
		739,813,834,1000,405,608,131,406,1099,1144,1,191,132,172,
		266,307,327,404,482,1082,42,159,433,8635,195,43,239,310,331,
		426,587,656,1084,1100,7,197,143,155,169,329,589,662,795,804,884,
		893,902,911,960,969,26,28,17,204,36,305,412,1079,8,198,37,173,
		304,413,1003,1143,56,1005,1092,57,58,231,642,1083,1105,3,193,171,
		232,401,4,194,225,356,461,574,638,649,665,727,794,803,883,892,
		901,910,959,968,27,30,212,59,60,297,947: return true;
	}
	return false;
}

// Dealing with numbers

stock _:GetRandInt(_:min, _:max, _:seed = 0)
{
	SetRandomSeed(seed != 0 ? seed : GetTime());
	return (max <= min ? min : GetURandomInt() % (max + 1));
}
stock Float:GetRandFloat(Float:min = 0.0, Float:max = 1.0, _:seed = 0)
{
	SetRandomSeed(seed != 0 ? seed : GetTime());
	return GetRandomFloat(min, max);
}

stock bool:IsItMyChance(Float:flChance = 0.0)
{
	new Float:flRand = GetRandFloat(0.0, 100.0);
	if(flChance <= 0.0)
		return false;
	return flRand <= flChance;
}

// Dealing with arrays

stock TakeRandCellFromArray(&Handle:hArray)
{
	new iSize = GetArraySize(hArray) - 1;
	new iRand = GetRandInt(0, iSize-1);
	new iResult = GetArrayCell(hArray, iRand);
	
	for(new i = iRand; i < iSize; i++)
		SetArrayCell(hArray, i, GetArrayCell(hArray, i+1));
	RemoveFromArray(hArray, iSize);
	
	return iResult;
}
stock TakeRandCellFromArrayEx(&Handle:hArray, &iSize)
{
	new iRand = GetRandInt(0, iSize);
	new iResult = GetArrayCell(hArray, iRand);
	
	for(new i = iRand; i < iSize; i++)
		SetArrayCell(hArray, i, GetArrayCell(hArray, i + 1));
	RemoveFromArray(hArray, iSize--);
	
	return iResult;
}

stock TakeRandStringFromArray(&Handle:hArray, String:strResult[], iResult)
{
	new iSize = GetArraySize(hArray) - 1;
	new iRand = GetRandInt(0, iSize-1);
	GetArrayString(hArray, iRand, strResult, iResult);
	
	decl String:strBuffer[iResult+1];
	for(new i = iRand; i < iSize; i++)
	{
		GetArrayString(hArray, i+1, strBuffer, iResult);
		SetArrayString(hArray, i, strBuffer);
	}
	RemoveFromArray(hArray, iSize );
}
stock TakeRandStringFromArrayEx(&Handle:hArray, &iSize, String:strResult[], iResult)
{
	new iRand = GetRandInt(0, iSize);
	GetArrayString(hArray, iRand, strResult, iResult);
	
	decl String:strBuffer[iResult+1];
	for(new i = iRand; i < iSize; i++)
	{
		GetArrayString(hArray, i+1, strBuffer, iResult);
		SetArrayString(hArray, i, strBuffer);
	}
	RemoveFromArray(hArray, iSize--);
}

// Other functions

stock PrepareSappers(iClient)
{
	if(!IsValidClient(iClient))
		return;
	
	decl String:strClassName[64];
	for(new i = 0, iWeapon; i < 48; i++)
	{
		iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i);
		if(iWeapon > 0 && IsValidEdict(iWeapon))
		{
			GetEntityClassname(iWeapon, strClassName, sizeof(strClassName));
			if(StrEqual(strClassName, "tf_weapon_builder", false) || StrEqual(strClassName, "tf_weapon_sapper", false))
			{
				SetEntProp(iWeapon, Prop_Send, "m_iObjectType", 3);
				//SetEntProp(iWeapon, Prop_Data, "m_iSubType", 3);
			}
		}
	}
}

stock GetRandStrangeCount(iItemDefID = 0)
{
	switch(iItemDefID)
	{
		case 444: // The Mantreads
			return GetRandInt(0, 900);
		case 655: // Spirit of Giving
			return GetRandInt(0, 300);
		case 735,736,810,831: // Sapper, The Red-Tape Recorder
			return GetRandInt(0, 3000);
	}
	return GetRandInt(0, 9000);
}

stock GetTFClassName(const TFClassType:iClass, String:strClassName[], iClassName)
{
	switch(iClass)
	{
		case TFClass_Scout:
			strcopy(strClassName, iClassName, "scout");
		case TFClass_Sniper:
			strcopy(strClassName, iClassName, "sniper");
		case TFClass_Soldier:
			strcopy(strClassName, iClassName, "soldier");
		case TFClass_DemoMan:
			strcopy(strClassName, iClassName, "demoman");
		case TFClass_Medic:
			strcopy(strClassName, iClassName, "medic");
		case TFClass_Heavy:
			strcopy(strClassName, iClassName, "heavy");
		case TFClass_Pyro:
			strcopy(strClassName, iClassName, "pyro");
		case TFClass_Spy:
			strcopy(strClassName, iClassName, "spy");
		case TFClass_Engineer:
			strcopy(strClassName, iClassName, "engineer");
		default:
			strcopy(strClassName, iClassName, "");
	}
}

stock TF2ItemSlot:GetItemSlotNumber(iItemDefID, TFClassType:iClass = TFClass_Unknown)
{
	decl String:strItemSlot[16];
	TF2IDB_GetItemSlotName(iItemDefID, strItemSlot, sizeof(strItemSlot));
	
	if(StrEqual(strItemSlot, "primary", false))
		return TF2ItemSlot_Primary;
	else if(StrEqual(strItemSlot, "secondary", false))
		return TF2ItemSlot_Secondary;
	else if(StrEqual(strItemSlot, "melee", false))
		return TF2ItemSlot_Melee;
	else if(StrEqual(strItemSlot, "pda", false))
		return TF2ItemSlot_PDA;
	else if(StrEqual(strItemSlot, "pda2", false))
		return TF2ItemSlot_PDA2;
	else if(StrEqual(strItemSlot, "building", false))
	{
		if(iClass == TFClass_Spy)
			return TF2ItemSlot_Sapper;
		else
			return TF2ItemSlot_Building;
	}
	else if(StrEqual(strItemSlot, "head", false))
		return TF2ItemSlot_Hat;
	else if(StrEqual(strItemSlot, "misc", false))
		return TF2ItemSlot_Misc;
	else if(StrEqual(strItemSlot, "action", false))
		return TF2ItemSlot_Action;
	else
		return TF2ItemSlot:-1;
}

stock FindIntInArray(iArray[], iSize, iItem)
{
	for(new i = 0; i < iSize; i++)
		if(iArray[i] == iItem)
			return i;
	return -1;
}

stock IsArenaMap(bool:bRecalc = false)
{
	static bool:bChecked = false;
	static bool:bArena = false;
	
	if(bRecalc || !bChecked)
	{
		new iEnt = FindEntityByClassname2(-1, "tf_logic_arena");
		bArena = (iEnt > MaxClients && IsValidEntity(iEnt));
		bChecked = true;
	}
	
	return bArena;
}

stock FindEntityByClassname2(startEnt, const String:strClassname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, strClassname);
}

stock mt_rand(min, max) {
	return RoundToNearest(GetURandomFloat() * (max - min) + min);
}