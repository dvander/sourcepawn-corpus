/* * * * * * * * * * * * * * * * * *
 *                                 *
 *    - TF2 Auto Items Manager -   *
 *          by Leonardo            *
 *                                 *
 * * * * * * * * * * * * * * * * * *
 * Q: Why I made it?               *
 * A: Because it's easy way to     *
 * fast add item to the special    *
 * someone.                        *
 *                                 *
 * Q: Why I trying to equip player *
 * twice?                          *
 * A: First time plugin trying to  *
 * edit item, if player has it.    *
 * Otherside plugin trying to gave *
 * new one.                        *
 * * * * * * * * * * * * * * * * * */


/*  * * * * * * * * * * * * * * * * *
 * 			- Navigation -			*
 *  * * * * * * * * * * * * * * * * *
 * Events:							*
 *  OnPluginStart()					*
 *  OnAllPluginsLoaded()			*
 *  OnPluginEnd()					*
 *  OnLibraryAdded()				*
 *  OnLibraryRemoved()				*
 *  OnMapStart()					*
 *  OnMapEnd()						*
 *  OnClientPutInServer()			*
 *  OnClientDisconnect_Post()		*
 *  TF2Items_OnGiveNamedItem()		*
 *  Event_UpdateItems()				*
 *  OnSuddenDeathStart()			*
 *  OnSuddenDeathEnd()				*
 *  OnPlayerSpawn()					*
 *  OnPlayerActivate()				*
 *  OnPlayerDeathPre()				*
 *  OnPlayerChanged()				*
 * 									*
 * Timers:							*
 *  Timer_AfterUpdateItems()		*
 *  Timer_StripPlayerItems()		*
 *  Timer_EventUpdateItems()		*
 *  Timer_UpdateHealth()			*
 *  Timer_SetVisualModel()			*
 *  Timer_SetWearableItemModel()	*
 *  Timer_LateLevelChanger()		*
 *  Timer_LateLevelChanger2()		*
 *  Timer_ShowGameText()			*
 *  Timer_KillGameText()			*
 *  Timer_UpdateData()				*
 * 									*
 * SQL functions:					*
 *  SQL_UpdatePlayerItems()			*
 *  SQL_ErrorCheckCallback()		*
 * 									*
 * Commands:						*
 *  Command_MyItems()				*
 *  Command_RewindUpdateTimer()		*
 *  Command_CookieChanger()			*
 *  Command_BuildObject()			*
 * 									*
 * Menus:							*
 *  CookieMenu_TopMenu()			*
 *  SendCookieSettingsMenu()		*
 *  Menu_CookieSettings()			*
 *  SendCookieItemMenu()			*
 *  Menu_CookieSettingsItems()		*
 * 									*
 * ConVars changing:				*
 *  OnConVarChanged_PluginVersion()	*
 *  OnConVarChanged_Medieval()		*
 *  OnConVarChanged_TogglePlugin()	*
 *  OnConVarChanged_ToggleDebug()	*
 *  OnConVarChanged_MeleeMode()		*
 *  OnConVarChanged_CrabMode()		*
 *  OnConVarChanged_TFDodgeBall()	*
 *  OnConVarChanged_CivilianFix()	*
 * 									*
 * Natives:							*
 *  Native_AddItemToPlayer()		*
 *  Native_TransferItem()			*
 *  Native_TriggerUpdate()			*
 *  Native_GetEquipedItemID()		*
 * 									*
 * Stocks and other funstions:		*
 *  TF2_GetClassName()				*
 *  TF2_GetClassBits()				*
 *  FindEntityByClassname2()		*
 *  TF2_GetItemSlot()				*
 *  RemoveWearable()				*
 *  RemoveAllWearable()				*
 *  TF2_EquipWearable()				*
 *  TF2_RemoveWearable()			*
 *  ItemFoundEvent()				*
 *  CheckForSpecialGameMode()		*
 *  TF2_IsMedievalMode()			*
 *  TF2_IsDeathmatch()				*
 *  MeleeModeDisarm()				*
 *  TFDBModeDisarm()				*
 *  SetWearableItemModel()			*
 *  * * * * * * * * * * * * * * * * */

#pragma semicolon 1

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <clientprefs>
#include <tf2items>
#include <attachables>
#include <tf2autoitems>
#include <visweps>
#undef REQUIRE_PLUGIN
#tryinclude <autoupdate>

#define PLUGIN_VERSION				"1.5.1e"

#define SOUND_SUCCESS				"vo/announcer_success.wav"

#define AUTOUPDATE_HOST				"files.xpenia.pp.ru"
#define AUTOUPDATE_PATH				"/sourcemod/tf2aim/autoupdate.xml"

#define QUERY_CLASS_ANY				0
#define QUERY_CLASS_SCOUT			(1<<0)
#define QUERY_CLASS_SNIPER			(1<<1)
#define QUERY_CLASS_SOLDIER			(1<<2)
#define QUERY_CLASS_DEMOMAN			(1<<3)
#define QUERY_CLASS_MEDIC			(1<<4)
#define QUERY_CLASS_HWGUY			(1<<5)
#define QUERY_CLASS_PYRO			(1<<6)
#define QUERY_CLASS_SPY				(1<<7)
#define QUERY_CLASS_ENGINEER		(1<<8)
#define QUERY_CLASS_CIVILIAN		(1<<9)

#define UNLOCK_DELAY				2

#if defined _autoupdate_included
new bool:g_bAutoUpdLoaded = false;
#endif
new bool:g_bSDKFuncLoaded = false;

new String:g_sFilePath[256] = "";
new String:g_sItemsPath[256] = "";

new Handle:g_hSDKFunc_EquipWearable = INVALID_HANDLE;
new Handle:g_hSDKFunc_RemoveWearable = INVALID_HANDLE;
new Handle:g_hSDKFunc_MaxHealth = INVALID_HANDLE;

new Handle:g_hDataBase = INVALID_HANDLE;

new Handle:g_hPlayerItems = INVALID_HANDLE;
//new Handle:g_hGlobalItems = INVALID_HANDLE;
new Handle:g_hItemsValues = INVALID_HANDLE;

new Handle:g_hCookie_Item[10][TF2ItemSlot_MaxSlots];

new Handle:g_hUpdatingTimer = INVALID_HANDLE;

new Handle:g_cvVersion = INVALID_HANDLE;
new Handle:g_cvMedieval = INVALID_HANDLE;
new Handle:g_cvMeleeMode = INVALID_HANDLE;

new g_iWearable[MAXPLAYERS+1][TF2ItemSlot_MaxSlots];
new g_iEquiped[MAXPLAYERS+1][TF2ItemSlot_MaxSlots];
new g_iCookie[MAXPLAYERS+1][10][TF2ItemSlot_MaxSlots];
new g_bQueue2Change[MAXPLAYERS+1][TF2ItemSlot_MaxSlots];
new bool:g_bLocked[MAXPLAYERS+1];

new g_iItemSlot[5000] = { -1, ... };

new bool:g_bActive = true;
new _:g_iDebug = 0;
new bool:g_bMapChanging = false;
new bool:g_bSuddenDeath = false;
new bool:g_bMedieval = false;
new bool:g_bMeleeMode = false;
new bool:g_bCrabMode = false;
new bool:g_bTFDBMode = false;
new bool:g_bCivilianFix = true;

new Handle:g_hForwardEquiped = INVALID_HANDLE;

new g_iAmmoOffset = -1;

public Plugin:myinfo = {
	name = "[TF2] Auto Items Manager",
	author = "Leonardo",
	description = "Autoupdate Item list from DB",
	version = PLUGIN_VERSION,
	url = "http://xpenia.pp.ru"
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	if(bLateLoad)
	{
		LogError("Plugin is not allowed to be late loaded!");
		return APLRes_Failure;
	}
	
	CreateNative("TF2AIM_AddItem", Native_AddItemToPlayer);
	CreateNative("TF2AIM_TransferItem", Native_TransferItem);
	CreateNative("TF2AIM_TriggerUpdate", Native_TriggerUpdate);
	CreateNative("TF2AIM_GetEquipedItemID", Native_GetEquipedItemID);
	
	RegPluginLibrary("tf2autoitems");
	
	return APLRes_Success;
}

/***********
*  Events  *
************/

public OnPluginStart()
{
	decl String:sGameDir[8];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if(!StrEqual(sGameDir, "tf", false) && !StrEqual(sGameDir, "tf_beta", false))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	LoadTranslations("common.phrases.txt");
	LoadTranslations("tf2autoitems.phrases.txt");
	
	g_cvVersion = CreateConVar("sm_tf2aim_version", PLUGIN_VERSION, "TF2 Auto Items Manager version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
	HookConVarChange(g_cvVersion, OnConVarChanged_PluginVersion);
	
	HookConVarChange(CreateConVar("sm_tf2aim_debug", "0", _, FCVAR_PLUGIN), OnConVarChanged_ToggleDebug);
	
	HookConVarChange(CreateConVar("sm_tf2aim_active", "1", "Enable/disable giving items", FCVAR_PLUGIN|FCVAR_NOTIFY), OnConVarChanged_TogglePlugin);
	
	g_cvMeleeMode = CreateConVar("sm_tf2aim_meleeonly", "0", "Allow only melee and non-combat weapons", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(g_cvMeleeMode, OnConVarChanged_MeleeMode);
	
	HookConVarChange(CreateConVar("sm_tf2aim_crabmode", "0", "Allow only PDAs and Huntsmans", FCVAR_PLUGIN|FCVAR_NOTIFY), OnConVarChanged_CrabMode);
	
	HookConVarChange(CreateConVar("sm_tf2aim_equipfix", "1", "Force equip first weapon (civilian pose fix)", FCVAR_PLUGIN|FCVAR_NOTIFY), OnConVarChanged_CivilianFix);
	
	if(FindConVar("sm_dodgeball_enabled")!=INVALID_HANDLE)
		HookConVarChange(FindConVar("sm_dodgeball_enabled"), OnConVarChanged_TFDodgeBall);
	
	if(!SQL_CheckConfig("tf2items"))
		SetFailState("Can't connect to DB: 'tf2items' config not found in databases.cfg");
	decl String:sError[256];
	g_hDataBase = SQL_Connect("tf2items", true, sError, sizeof(sError));
	if(g_hDataBase==INVALID_HANDLE)
		SetFailState("Can't connect to DB: %s", sError);
	
	g_iAmmoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	
	new Handle:hGameConf = LoadGameConfigFile("tf2autoitems");
	if(hGameConf!=INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "EquipWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDKFunc_EquipWearable = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDKFunc_RemoveWearable = EndPrepSDKCall();
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayer_GetMaxHealth");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDKFunc_MaxHealth = EndPrepSDKCall();

		CloseHandle(hGameConf);
		g_bSDKFuncLoaded = true;
	}
	else
		SetFailState("Couldn't load gamedata from tf2autoitems.txt");
	
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "data/tf2itemlist.txt");
	if(!FileExists(g_sFilePath))
	{
		new Handle:hDataFile = OpenFile(g_sFilePath, "a");
		WriteFileLine(hDataFile, "items");
		WriteFileLine(hDataFile, "{");
		WriteFileLine(hDataFile, "}");
		CloseHandle(hDataFile);
	}
	g_hPlayerItems = CreateKeyValues("items");
	Timer_UpdateData(INVALID_HANDLE, 1);
	
	g_sItemsPath = "./scripts/items/items_game.txt";
	if(!FileExists(g_sItemsPath))
		SetFailState("Wow! Can't found file: %s", g_sItemsPath);
	g_hItemsValues = CreateKeyValues("items_game");
	FileToKeyValues(g_hItemsValues, g_sItemsPath);
	
	RegServerCmd("sm_tf2aim_rewindupdater", Command_RewindUpdateTimer);
	AddCommandListener(Command_BuildObject, "build");
	
	HookEvent("post_inventory_application", Event_UpdateItems, EventHookMode_Post);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_activate", OnPlayerActivate, EventHookMode_Post);
	HookEvent("player_team", OnPlayerChanged, EventHookMode_Post);
	HookEvent("player_changeclass", OnPlayerChanged, EventHookMode_Post);
	
	HookEvent("teamplay_suddendeath_begin", OnSuddenDeathStart,  EventHookMode_Pre);
	HookEvent("teamplay_suddendeath_end", OnSuddenDeathEnd,  EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnSuddenDeathEnd,  EventHookMode_Pre);
	
	g_hForwardEquiped = CreateGlobalForward("TF2AIM_OnGiveCustomItem", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_CellByRef);
}

public OnAllPluginsLoaded()
{
	if(GetExtensionFileStatus("clientprefs.ext")==1 && SQL_CheckConfig("clientprefs"))
	{
		// 0 - primary
		// 1 - secondary
		// 2 - melee
		// 3 - PDA
		// 4 - PDA2
		// 5 - Hat
		// 6 - Misc
		// 7 - Action (unused)
		
		decl String:sCookieName[64], String:sCookieDescr[64], String:sTF2Classname[16];
		for(new iClass=0; iClass<10; iClass++)
		{
			TF2_GetClassName(iClass, sTF2Classname, sizeof(sTF2Classname));
			Format(sCookieName, sizeof(sCookieName), "tf2autoitems_item_%i_0", iClass);
			Format(sCookieDescr, sizeof(sCookieDescr), "Item for %s (primary)", sTF2Classname);
			g_hCookie_Item[iClass][0] = RegClientCookie(sCookieName, sCookieDescr, CookieAccess_Private);
			Format(sCookieName, sizeof(sCookieName), "tf2autoitems_item_%i_1", iClass);
			Format(sCookieDescr, sizeof(sCookieDescr), "Item for %s (secondary)", sTF2Classname);
			g_hCookie_Item[iClass][1] = RegClientCookie(sCookieName, sCookieDescr, CookieAccess_Private);
			Format(sCookieName, sizeof(sCookieName), "tf2autoitems_item_%i_2", iClass);
			Format(sCookieDescr, sizeof(sCookieDescr), "Item for %s (melee)", sTF2Classname);
			g_hCookie_Item[iClass][2] = RegClientCookie(sCookieName, sCookieDescr, CookieAccess_Private);
			Format(sCookieName, sizeof(sCookieName), "tf2autoitems_item_%i_3", iClass);
			Format(sCookieDescr, sizeof(sCookieDescr), "Item for %s (pda)", sTF2Classname);
			g_hCookie_Item[iClass][3] = RegClientCookie(sCookieName, sCookieDescr, CookieAccess_Private);
			Format(sCookieName, sizeof(sCookieName), "tf2autoitems_item_%i_4", iClass);
			Format(sCookieDescr, sizeof(sCookieDescr), "Item for %s (pda2)", sTF2Classname);
			g_hCookie_Item[iClass][4] = RegClientCookie(sCookieName, sCookieDescr, CookieAccess_Private);
			Format(sCookieName, sizeof(sCookieName), "tf2autoitems_item_%i_5", iClass);
			Format(sCookieDescr, sizeof(sCookieDescr), "Item for %s (hat)", sTF2Classname);
			g_hCookie_Item[iClass][5] = RegClientCookie(sCookieName, sCookieDescr, CookieAccess_Private);
			Format(sCookieName, sizeof(sCookieName), "tf2autoitems_item_%i_6", iClass);
			Format(sCookieDescr, sizeof(sCookieDescr), "Item for %s (misc)", sTF2Classname);
			g_hCookie_Item[iClass][6] = RegClientCookie(sCookieName, sCookieDescr, CookieAccess_Private);
		}
		
		SetCookieMenuItem(CookieMenu_TopMenu, 0, "TF2 Auto Items");
		
		RegConsoleCmd("sm_myitems", Command_MyItems, "Show TF2 Auto Items menu");
		RegConsoleCmd("sm_items", Command_MyItems, "Show TF2 Auto Items menu");
		RegConsoleCmd("myitems", Command_MyItems, "Show TF2 Auto Items menu");
		RegConsoleCmd("items", Command_MyItems, "Show TF2 Auto Items menu");
		RegAdminCmd("sm_tf2aim_cookie", Command_CookieChanger, ADMFLAG_ROOT);
	}
	else
		SetFailState("Can't load Clientprefs extension!");
	
#if defined _autoupdate_included
	g_bAutoUpdLoaded = LibraryExists("pluginautoupdate");
	
	if(g_bAutoUpdLoaded)
		AutoUpdate_AddPlugin(AUTOUPDATE_HOST, AUTOUPDATE_PATH, PLUGIN_VERSION);
#endif
}

public OnPluginEnd()
{
	g_hDataBase = INVALID_HANDLE;
	g_hPlayerItems = INVALID_HANDLE;
	g_hItemsValues = INVALID_HANDLE;
	for(new i=0; i<10; i++)
		for(new ii=0; ii<TF2ItemSlot_MaxSlots; ii++)
			g_hCookie_Item[i][ii] = INVALID_HANDLE;

#if defined _autoupdate_included
	if(g_bAutoUpdLoaded)
		AutoUpdate_RemovePlugin();
#endif
}

#if defined _autoupdate_included
public OnLibraryAdded(const String:sName[])
	if(StrEqual(sName, "pluginautoupdate"))
	{
		g_bAutoUpdLoaded = true;
		AutoUpdate_AddPlugin(AUTOUPDATE_HOST, AUTOUPDATE_PATH, PLUGIN_VERSION);
	}

public OnLibraryRemoved(const String:sName[])
	if(StrEqual(sName, "pluginautoupdate"))
		g_bAutoUpdLoaded = false;
#endif

public OnMapStart()
{
	g_bMapChanging = false;
	
	g_bSuddenDeath = false;
	
	TF2_IsMedievalMode();
	
	TF2_IsDeathmatch();
	
	if(FindConVar("sm_dodgeball_enabled")!=INVALID_HANDLE)
		g_bTFDBMode = GetConVarBool(FindConVar("sm_dodgeball_enabled"));
	else
		g_bTFDBMode = false;
	
	for(new iCell=0; iCell<=MAXPLAYERS; iCell++)
	{
		g_bLocked[iCell] = false;
		for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
		{
			g_iWearable[iCell][iSlot] = -1;
			g_iEquiped[iCell][iSlot] = -1;
			g_bQueue2Change[iCell][iSlot] = true;
		}
	}
	
	if(GuessSDKVersion()==SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
	
	// Golden Wrench Notification
	PrecacheSound(SOUND_SUCCESS, true);
	
	new String:sDLPath[1024], String:sLine[4096];
	BuildPath(Path_SM, sDLPath, sizeof(sDLPath), "configs/tf2aim.downloads.txt");
	new Handle:hFile = OpenFile(sDLPath, "r");
	new String:sFileFormat[5];
	new iLineCounter = 0;
	if(hFile!=INVALID_HANDLE)
	{
		while(!IsEndOfFile(hFile))
		{
			iLineCounter++;
			ReadFileLine(hFile, sLine, sizeof(sLine));
			
			if(strlen(sLine)<=1) // ignore empty line
				continue;
			
			sLine[strlen(sLine)-1] = '\0';
			
			if(strlen(sLine)<=1) // ignore empty line again
				continue;
			if(StrContains("#", sLine, false)==0) // ignore comments
				continue;
			
			if(FileExists(sLine, true) || FileExists(sLine, false))
			{
				Format(sFileFormat, sizeof(sFileFormat),"%s%s%s%s", sLine[strlen(sLine)-4], sLine[strlen(sLine)-3], sLine[strlen(sLine)-2], sLine[strlen(sLine)-1]);
				
				if(strcmp(sFileFormat, ".dep", false)==0 || strcmp(sFileFormat, ".exe", false)==0 || strcmp(sFileFormat, ".bin", false)==0)
					continue; // To do: add dep-files parser...
				
				AddFileToDownloadsTable(sLine);
				
				if(strcmp(sFileFormat, ".vmt", false)==0)
				{
					if(!IsDecalPrecached(sLine))
						if(!bool:PrecacheDecal(sLine, true))
							LogError("Line $i: Failed to precache decal %s", iLineCounter, sLine);
					continue;
				}
			}
		}
		CloseHandle(hFile);
	}
	else
	{
		// First start
		hFile = OpenFile(sDLPath, "w");
		WriteFileLine(hFile, "# Add one file per line.");
		WriteFileLine(hFile, "# Example: models/weapons/c_wrench/c_wrench.mdl");
		WriteFileLine(hFile, "#");
		WriteFileLine(hFile, "");
		FlushFile(hFile);
		CloseHandle(hFile);
	}
	
	//SQL_TQuery(g_hDataBase, SQL_UpdateGlobalItems, "SELECT `id`, `plrclass`, `defindex`, `itemclass`, `slot`, `syslevel`, `event`, `dispname`, `cmodel`, `attrib0`, `attrib1`, `attrib2`, `attrib3`, `attrib4`, `attrib5`, `attrib6`, `attrib7`, `attrib8`, `attrib9`, `attrib10`, `attrib11`, `attrib12`, `attrib13`, `attrib14`, `attrib15` FROM `global_items`");
	
	//if(g_hUpdatingTimer!=INVALID_HANDLE)
	//{
	//	KillTimer(g_hUpdatingTimer);
	//	g_hUpdatingTimer = INVALID_HANDLE;
	//}
	g_hUpdatingTimer = CreateTimer(60.0, Timer_UpdateData, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	g_bMapChanging = true;
	g_hUpdatingTimer = INVALID_HANDLE;
}

public OnClientPutInServer(iClient)
{
	for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
	{
		g_iWearable[iClient][iSlot] = -1;
		g_iEquiped[iClient][iSlot] = -1;
		g_bQueue2Change[iClient][iSlot] = true;
	}
	g_bLocked[iClient] = false;
}

public OnClientDisconnect_Post(iClient)
{
	for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
	{
		g_iWearable[iClient][iSlot] = -1;
		g_iEquiped[iClient][iSlot] = -1;
		g_bQueue2Change[iClient][iSlot] = true;
	}
	g_bLocked[iClient] = false;
}

public Action:TF2Items_OnGiveNamedItem(iClient, String:sClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
	if(!g_bActive || g_bMapChanging) // giving is inactive! ignoring everything
		return Plugin_Continue;
	
	static bool:bLocked;
	static iLastCall;
	if(bLocked)
		if((GetTime()-UNLOCK_DELAY)>iLastCall)
			bLocked = false; // something wrong happend, so unlock after 2 sec
		else
			return Plugin_Continue;
	iLastCall = GetTime();
	
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient) || GetClientTeam(iClient)<=1 || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	if(hItemOverride != INVALID_HANDLE)
		return Plugin_Continue;
	
	new iItemSlot = TF2_GetItemSlot(iItemDefinitionIndex);
	if(iItemSlot<=-1 || iItemSlot>=TF2ItemSlot_Action)
		return Plugin_Continue;
	
	if(g_iDebug>=2)
		PrintToConsole(iClient, "TF2AIM: checking slot %i, item %i", iItemSlot, iItemDefinitionIndex);
	
	if(!CheckForSpecialGameMode(iItemDefinitionIndex, iItemSlot))
		return Plugin_Handled;
	
	if(!g_bLocked[iClient])
	{
		g_bLocked[iClient] = true;
		RemoveAllWearable(iClient);
	}
	
	bLocked = true;
	
	new String:sClientAuth[32];
	GetClientAuthString(iClient, sClientAuth, sizeof(sClientAuth));
	
	new Handle:hItem = INVALID_HANDLE, String:sItemID[16], Handle:hWData, Handle:hLData;
	new iClientClass, iDefIndex, iSlot, iQuality, iLevel/*, bool:bGotForThisSlot = false*/;
	KvRewind(g_hPlayerItems);
	if(KvJumpToKey(g_hPlayerItems, sClientAuth, false))
		if(KvGotoFirstSubKey(g_hPlayerItems))
		{
			iClientClass = _:TF2_GetPlayerClass(iClient);
			new iClientFlags = GetUserFlagBits(iClient);
			new iClientClassBits = TF2_GetClassBits(iClientClass);
			new i, iPlayerClass, iExpDate, String:sItemClass[129], String:sItemTitle[65], String:sCustomModel[769], iAttrs, String:sAttrID[16], iAttrIDs[16], Float:fAttrValues[16];
			do {
				KvGetSectionName(g_hPlayerItems, sItemID, sizeof(sItemID));
				iDefIndex = KvGetNum(g_hPlayerItems, "DefIndex");
				KvGetString(g_hPlayerItems, "item_name", sItemTitle, sizeof(sItemTitle));
				KvGetString(g_hPlayerItems, "item_class", sItemClass, sizeof(sItemClass));
				iSlot = KvGetNum(g_hPlayerItems, "item_slot", 2);
				iQuality = KvGetNum(g_hPlayerItems, "item_quality", 6);
				iLevel = KvGetNum(g_hPlayerItems, "item_level", 1);
				iPlayerClass = KvGetNum(g_hPlayerItems, "used_by_class", 0);
				KvGetString(g_hPlayerItems, "custom_model", sCustomModel, sizeof(sCustomModel));
				iExpDate = KvGetNum(g_hPlayerItems, "expiration_date", 0);
				
				if(iItemSlot!=iSlot)
					continue;
				
				if(iPlayerClass!=0 && !(iPlayerClass & iClientClassBits))
					continue;
				
				if(g_iCookie[iClient][iClientClass-1][iItemSlot]!=StringToInt(sItemID))
					continue;
				
				if(iExpDate>0)
					if(GetTime()>iExpDate)
					{
						if(g_iDebug>=2)
							PrintToConsole(iClient, "Can't equip item #%s: item is outdated", sItemID);
						continue;
					}
				
				if(iItemDefinitionIndex<=30) // fix bug with normal items
				{
					if(iDefIndex<=30 && iQuality!=TF2ItemQuality_Normal)
						iQuality = TF2ItemQuality_Normal;
					else if(iDefIndex>30)
					{
						bLocked = false;
						g_iEquiped[iClient][iItemSlot] = -1;
						if(g_iDebug>=2)
							PrintToConsole(iClient, "Found item %s which will be given later", sItemID);
						return Plugin_Handled;
					}
				}
				
				if(!StrEqual(sCustomModel, ""))
				{
					if(!IsModelPrecached(sCustomModel))
						if(FileExists(sCustomModel, true) || FileExists(sCustomModel, false))
						{
							if(PrecacheModel(sCustomModel, true)<=0)
							{
								LogError("Can't precache model: model couldn't be precached: %s", sCustomModel);
								continue;
							}
						}
						else
						{
							LogError("Can't precache model: models file not found: %s", sCustomModel);
							continue;
						}
					
					if(StrContains(sClassName, "tf_wearable", false)==0)
					{
						hWData = CreateDataPack();
						CreateDataTimer(0.5, Timer_SetWearableItemModel, hWData, TIMER_DATA_HNDL_CLOSE);
						WritePackCell(hWData, iClient);
						WritePackCell(hWData, iDefIndex);
						WritePackString(hWData, sCustomModel);
						WritePackString(hWData, sClassName);
					}
					else if(StrContains(sClassName, "tf_weapon", false)==0)
					{
						bLocked = false;
						g_iEquiped[iClient][iItemSlot] = -1;
						return Plugin_Handled;
					}
				}
				else
					if(StrContains(sClassName, "tf_wearable", false)==0)
						if(iItemDefinitionIndex!=iDefIndex)
							if((iClientFlags & ADMFLAG_ROOT)==0)
								continue;
				
				if(!StrEqual(sClassName, sItemClass, false)) // otherside this thing will being divided by NULL
				{
					bLocked = false;
					g_iEquiped[iClient][iItemSlot] = -1;
					return Plugin_Handled;
				}
				
				hItem = TF2Items_CreateItem(OVERRIDE_ITEM_DEF|OVERRIDE_ITEM_LEVEL|OVERRIDE_ITEM_QUALITY|OVERRIDE_ATTRIBUTES);
				TF2Items_SetItemIndex(hItem, iDefIndex);
				if(iLevel>=128 || iLevel<1)
				{
					TF2Items_SetLevel(hItem, GetRandomInt(1,127));
					hLData = CreateDataPack();
					CreateDataTimer(0.25, Timer_LateLevelChanger, hLData, TIMER_DATA_HNDL_CLOSE);
					WritePackCell(hLData, iClient);
					WritePackCell(hLData, iDefIndex);
					WritePackCell(hLData, iLevel);
					WritePackString(hLData, sClassName);
				}
				else
					TF2Items_SetLevel(hItem, iLevel);
				TF2Items_SetQuality(hItem, iQuality);
				if(KvJumpToKey(g_hPlayerItems, "attributes", false) && KvGotoFirstSubKey(g_hPlayerItems))
				{
					iAttrs = 0;
					do {
						KvGetSectionName(g_hPlayerItems, sAttrID, sizeof(sAttrID));
						iAttrIDs[iAttrs] = StringToInt(sAttrID);
						fAttrValues[iAttrs] = KvGetFloat(g_hPlayerItems, "value", 0.0);
						iAttrs++;
					} while(KvGotoNextKey(g_hPlayerItems));
					TF2Items_SetNumAttributes(hItem, iAttrs);
					for(i=0; i<iAttrs; i++)
						TF2Items_SetAttribute(hItem, i, iAttrIDs[i], fAttrValues[i]);
					KvGoBack(g_hPlayerItems);
					KvGoBack(g_hPlayerItems);
				}
				else
					TF2Items_SetNumAttributes(hItem, 0);
				
				if(g_iDebug>=2)
					PrintToConsole(iClient, "replaced %i with %i (%s)", iItemDefinitionIndex, iDefIndex, sItemID);
				
				g_iEquiped[iClient][iItemSlot] = StringToInt(sItemID);
				g_bQueue2Change[iClient][iItemSlot] = false;
				break; // not longer need to find anymore
			} while(KvGotoNextKey(g_hPlayerItems));
		}
	
	if(hItem!=INVALID_HANDLE)
	{
		bLocked = false;
		
		hItemOverride = hItem;
		
		Call_StartForward(g_hForwardEquiped);
		Call_PushCell(iClient);
		Call_PushCell(StringToInt(sItemID));
		Call_PushCell(iDefIndex);
		Call_PushString(sClassName);
		Call_PushCell(iSlot);
		Call_PushCell(iQuality);
		Call_PushCell(iLevel);
		Call_PushString("");
		Call_PushCell(-1);
		Call_Finish();
		
		return Plugin_Changed;
	}
	/*else
	{
		decl String:sCurrentDay[6];
		FormatTime(sCurrentDay, sizeof(sCurrentDay), "%d%m");
		if(StrEqual(sCurrentDay, "0803"))
		{
			if(iItemSlot==TF2ItemSlot_Head)
			{
				hItem = TF2Items_CreateItem(OVERRIDE_ITEM_QUALITY|OVERRIDE_ATTRIBUTES);
				TF2Items_SetQuality(hItem, 5);
				TF2Items_SetNumAttributes(hItem, 2);
				TF2Items_SetAttribute(hItem, 0, 134, ( bool:GetRandomInt(0,1) ? 19.0 : 18.0 ));
				TF2Items_SetAttribute(hItem, 1, 142, float(16711935));
				hItemOverride = hItem;
				bLocked = false;
				return Plugin_Changed;
			}
			
			if(iItemSlot==TF2ItemSlot_Misc)
			{
				hItem = TF2Items_CreateItem(OVERRIDE_ITEM_QUALITY|OVERRIDE_ATTRIBUTES);
				TF2Items_SetQuality(hItem, 5);
				TF2Items_SetNumAttributes(hItem, 1);
				TF2Items_SetAttribute(hItem, 0, 142, float(16711935));
				hItemOverride = hItem;
				bLocked = false;
				return Plugin_Changed;
			}
		}
	}*/
	
	bLocked = false;
	g_iEquiped[iClient][iItemSlot] = iItemDefinitionIndex;
	return Plugin_Continue;
}

public Event_UpdateItems(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients)
		return;
	
	//RemoveAllWearable(iClient);
	
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		CreateTimer(0.05, Timer_EventUpdateItems, iClient);
		CreateTimer(0.10, Timer_AfterUpdateItems, iClient);
	}
	
	return;
}

public OnSuddenDeathStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	g_bSuddenDeath = true;
	
	for(new iClient=1; iClient<=MaxClients; iClient++)
		if(IsClientConnected(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient))
			CreateTimer(0.1, Timer_StripPlayerItems, iClient);
}

public OnSuddenDeathEnd(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
	g_bSuddenDeath = false;

public OnPlayerSpawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients)
		return;
	
	//RemoveAllWearable(iClient);
	
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
		if(g_bActive && (g_bMedieval || g_bSuddenDeath || g_bMeleeMode || g_bCrabMode || g_bTFDBMode))
		{
			if(g_iDebug>=1)
				PrintToServer("TF2AIM: special gamemodes: %i %i %i %i %i", g_bMedieval, g_bSuddenDeath, g_bMeleeMode, g_bCrabMode, g_bTFDBMode);
			CreateTimer(1.0, Timer_StripPlayerItems, iClient);
		}
	
	return;
}

public OnPlayerActivate(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient))
		return;
	
	RemoveAllWearable(iClient);
	
	if(IsFakeClient(iClient))
		return;
	
	// Set default value of cookies
	new String:sCookie[32];
	for(new iClass=0; iClass<10; iClass++)
		for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
			if(g_hCookie_Item[iClass][iSlot]!=INVALID_HANDLE)
			{
				GetClientCookie(iClient, g_hCookie_Item[iClass][iSlot], sCookie, sizeof(sCookie));
				if(StrEqual(sCookie, ""))
				{
					SetClientCookie(iClient, g_hCookie_Item[iClass][iSlot], "-1");
					g_iCookie[iClient][iClass][iSlot] = -1;
				}
				else
					g_iCookie[iClient][iClass][iSlot] = StringToInt(sCookie);
			}
	
	Timer_UpdateData(INVALID_HANDLE, 1);
	
	return;
}

public Action:OnPlayerDeathPre(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient))
		return Plugin_Continue;
	
	if(GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	
	for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
		if(iSlot!=TF2ItemSlot_Melee)
			g_iEquiped[iClient][iSlot] = -1;
	
	RemoveAllWearable(iClient);
	
	return Plugin_Continue;
}

public OnPlayerChanged(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient))
		return;
	
	for(new iSlot; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
	{
		g_iEquiped[iClient][iSlot] = -1;
		g_bQueue2Change[iClient][iSlot] = true;
	}
	
	return;
}

/***********
*  Timers  *
************/

public Action:Timer_AfterUpdateItems(Handle:hTimer, any:iClient)
{
	if(!g_bCivilianFix)
		return Plugin_Handled;
	
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	new iActiveWeapon;
	for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
		if((iActiveWeapon = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
			if(IsValidEdict(iActiveWeapon))
			{
				EquipPlayerWeapon(iClient, iActiveWeapon);
				return Plugin_Handled;
			}
	LogError("Can't fix civilian pose for %L", iClient);
	
	return Plugin_Handled;
}

public Action:Timer_StripPlayerItems(Handle:hTimer, any:iClient)
{
	if(!g_bMedieval && !g_bSuddenDeath && !g_bMeleeMode && !g_bCrabMode && !g_bTFDBMode)
		return Plugin_Handled;
	
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	new iEntity = -1;
	for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
	{
		iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if(iEntity>0 && IsValidEdict(iEntity))
		{
			if(!CheckForSpecialGameMode(GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex"), iSlot))
			{
				TF2_RemoveWeaponSlot(iClient, iSlot);
				VisWep_GiveWeapon(iClient, iSlot, "-1");
				g_iEquiped[iClient][iSlot] = -1;
				g_bQueue2Change[iClient][iSlot] = true;
				if(g_iDebug>=2)
					PrintToConsole(iClient, "TF2AIM: restricted slot %i", iSlot);
			}
			
			if(iSlot==TF2ItemSlot_Melee) // there's no invalid melee afaik
				EquipPlayerWeapon(iClient, iEntity);
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_EventUpdateItems(Handle:hTimer, any:iClient)
{
	if(!g_bActive || g_bMapChanging)
		return Plugin_Handled;
	
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || GetClientTeam(iClient)<=1 || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	if(!g_bLocked[iClient])
	{
		g_bLocked[iClient] = true;
		RemoveAllWearable(iClient);
	}
	
	g_bLocked[iClient] = false;
	
	static bool:bLocked;
	static iLastCall;
	if(bLocked)
		if((GetTime()-UNLOCK_DELAY)>iLastCall)
			bLocked = false;
		else
			return Plugin_Handled;
	iLastCall = GetTime();
	
	bLocked = true;
	
	if(g_bTFDBMode)
	{
		new iEntity = -1;
		
		if((iEntity = GetPlayerWeaponSlot(iClient, 0)) != -1)
			TF2_RemoveWeaponSlot(iClient, 0);
		if((iEntity = GetPlayerWeaponSlot(iClient, 1)) != -1)
			TF2_RemoveWeaponSlot(iClient, 1);
		if((iEntity = GetPlayerWeaponSlot(iClient, 2)) != -1)
			TF2_RemoveWeaponSlot(iClient, 2);
		
		new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
		TF2Items_SetClassname(hItem, "tf_weapon_flamethrower");
		TF2Items_SetItemIndex(hItem, 208);
		TF2Items_SetLevel(hItem, GetRandomInt(1,127));
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetNumAttributes(hItem, 2);
		TF2Items_SetAttribute(hItem, 0, 1, 0.0);
		TF2Items_SetAttribute(hItem, 1, 37, 10.0);
		
		iEntity = TF2Items_GiveNamedItem(iClient, hItem);
		CloseHandle(hItem);
		
		EquipPlayerWeapon(iClient, iEntity);
		
		if(g_iAmmoOffset!=-1)
			SetEntData(iClient, (g_iAmmoOffset+12), 500, 4);
		
		iEntity = -1;
	}
	else
	{
		new String:sClientAuth[32];
		GetClientAuthString(iClient, sClientAuth, sizeof(sClientAuth));
		
		KvRewind(g_hPlayerItems);
		if(KvJumpToKey(g_hPlayerItems, sClientAuth, false))
			if(KvGotoFirstSubKey(g_hPlayerItems))
			{
				new Handle:hData = CreateDataPack(), Handle:hLData = INVALID_HANDLE;
				CreateDataTimer(0.5, Timer_SetVisualModel, hData, TIMER_DATA_HNDL_CLOSE);
				WritePackCell(hData, iClient);
				
				new iClientClass = _:TF2_GetPlayerClass(iClient);
				new iClientClassBits = TF2_GetClassBits(iClientClass);
				
				new i, iItemEntity, Handle:hItem = INVALID_HANDLE, iPlayerClass, iExpDate, String:sBuffer[PLATFORM_MAX_PATH+1+16+1+1], String:sItemID[16], iDefIndex, String:sItemClass[129], String:sItemTitle[65], String:sCustomModel[769], iSlot, iQuality, iLevel, iAttrs, String:sAttrID[16], iAttrIDs[16], Float:fAttrValues[16];
				do {
					KvGetSectionName(g_hPlayerItems, sItemID, sizeof(sItemID));
					iDefIndex = KvGetNum(g_hPlayerItems, "DefIndex");
					KvGetString(g_hPlayerItems, "item_name", sItemTitle, sizeof(sItemTitle));
					KvGetString(g_hPlayerItems, "item_class", sItemClass, sizeof(sItemClass));
					iSlot = KvGetNum(g_hPlayerItems, "item_slot", 2);
					iQuality = KvGetNum(g_hPlayerItems, "item_quality", 6);
					iLevel = KvGetNum(g_hPlayerItems, "item_level", 1);
					iPlayerClass = KvGetNum(g_hPlayerItems, "used_by_class", 0);
					KvGetString(g_hPlayerItems, "custom_model", sCustomModel, sizeof(sCustomModel));
					iExpDate = KvGetNum(g_hPlayerItems, "expiration_date", 0);
					
					if(iPlayerClass!=0 && !(iPlayerClass & iClientClassBits))
						continue;
					
					if(g_iCookie[iClient][iClientClass-1][iSlot]!=StringToInt(sItemID))
						continue;
					
					if(iExpDate>0)
						if(GetTime()>iExpDate)
							continue;
					
					if(g_bQueue2Change[iClient][iSlot])
						g_iEquiped[iClient][iSlot] = -1;
					
					if(g_iEquiped[iClient][iSlot]>=0 && !g_bQueue2Change[iClient][iSlot])
					{
						if(g_iDebug>=2)
							PrintToConsole(iClient, "TF2AIM: %L: %s: g_iEquiped[%i][%i]=%i (ignoring)", iClient, sItemID, iClient, iSlot, g_iEquiped[iClient][iSlot]);
						continue;
					}
					else
						if(g_iDebug>=2)
							PrintToConsole(iClient, "TF2AIM: %L: %s: g_iEquiped[%i][%i]=%i", iClient, sItemID, iClient, iSlot, g_iEquiped[iClient][iSlot]);
					
					if(!CheckForSpecialGameMode(iDefIndex, iSlot))
						continue;
					
					if(StrContains(sItemClass, "tf_weapon", false)==0)
						if(GetPlayerWeaponSlot(iClient, iSlot)>0)
						{
							TF2_RemoveWeaponSlot(iClient, iSlot);
							if(g_iDebug>=2)
								PrintToConsole(iClient, "TF2AIM: Stripping old weapon slot %i", iSlot);
						}
					
					if(iDefIndex<=30 && iQuality!=TF2ItemQuality_Normal)
						iQuality = TF2ItemQuality_Normal;
					
					hItem = TF2Items_CreateItem(OVERRIDE_ALL);
					TF2Items_SetClassname(hItem, sItemClass);
					TF2Items_SetItemIndex(hItem, iDefIndex);
					if(iLevel>=128 || iLevel<1)
						TF2Items_SetLevel(hItem, GetRandomInt(1,127));
					else
						TF2Items_SetLevel(hItem, iLevel);
					TF2Items_SetQuality(hItem, iQuality);
					if(KvJumpToKey(g_hPlayerItems, "attributes", false) && KvGotoFirstSubKey(g_hPlayerItems))
					{
						iAttrs = 0;
						do {
							KvGetSectionName(g_hPlayerItems, sAttrID, sizeof(sAttrID));
							iAttrIDs[iAttrs] = StringToInt(sAttrID);
							fAttrValues[iAttrs] = KvGetFloat(g_hPlayerItems, "value", 0.0);
							iAttrs++;
						} while(KvGotoNextKey(g_hPlayerItems));
						TF2Items_SetNumAttributes(hItem, iAttrs);
						for(i=0; i<iAttrs; i++)
							TF2Items_SetAttribute(hItem, i, iAttrIDs[i], fAttrValues[i]);
						KvGoBack(g_hPlayerItems);
						KvGoBack(g_hPlayerItems);
					}
					else
						TF2Items_SetNumAttributes(hItem, 0);
					
					iItemEntity = TF2Items_GiveNamedItem(iClient, hItem);
					CloseHandle(hItem);
					hItem = INVALID_HANDLE;
					
					if(!IsValidEdict(iItemEntity))
					{
						LogError("Can't create item %s %i for %L", sItemClass, iDefIndex, iClient);
						continue;
					}
					
					if(StrContains(sItemClass, "tf_weapon", false)==0)
					{
						EquipPlayerWeapon(iClient, iItemEntity);
						
						if(StrEqual(sItemClass, "tf_weapon_wrench", false) || StrEqual(sItemClass, "tf_weapon_robot_arm", false))
						{
							PrintToChat(iClient, "* %T", "Given new wrench", iClient);
							if(!StrEqual(sCustomModel, ""))
								PrintToChat(iClient, "* %T", "Given new wrench - No ways", iClient);
							else
								if(StrEqual(sItemClass, "tf_weapon_wrench", false))
									if(iQuality == 0)
										PrintToChat(iClient, "* %T", "Given new wrench - Equip normal wrench", iClient);
									else
										PrintToChat(iClient, "* %T", "Given new wrench - Equip unique wrench", iClient);
								else
									PrintToChat(iClient, "* %T", "Given new wrench - Equip robotarm", iClient);
						}
						
						if(strlen(sCustomModel)>=16)
							Format(sBuffer, sizeof(sBuffer), "%i|%s", iSlot, sCustomModel);
						else
							Format(sBuffer, sizeof(sBuffer), "%i|%i", iSlot, iDefIndex);
						WritePackString(hData, sBuffer);
					}
					else if(StrContains(sItemClass, "tf_wearable", false)==0)
					{
						TF2_EquipWearable(iClient, iItemEntity);
						SetWearableItemModel(iItemEntity, iClient, iSlot, sCustomModel);
					}
					
					if(iLevel>=128 || iLevel<1)
					{
						hLData = CreateDataPack();
						CreateDataTimer(0.05, Timer_LateLevelChanger2, hLData, TIMER_DATA_HNDL_CLOSE);
						WritePackCell(hLData, EntIndexToEntRef(iItemEntity));
						WritePackCell(hLData, iLevel);
					}
					
					g_iEquiped[iClient][iSlot] = StringToInt(sItemID);
					g_bQueue2Change[iClient][iSlot] = false;
					
					if(g_iDebug>=2)
						PrintToConsole(iClient, "TF2AIM: Equiped new item %i (slot %i) (#%s) for %L", iDefIndex, iSlot, sItemID, iClient);
					
					Call_StartForward(g_hForwardEquiped);
					Call_PushCell(iClient);
					Call_PushCell(StringToInt(sItemID));
					Call_PushCell(iDefIndex);
					Call_PushString(sItemClass);
					Call_PushCell(iSlot);
					Call_PushCell(iQuality);
					Call_PushCell(iLevel);
					Call_PushString(sCustomModel);
					Call_PushCellRef(iItemEntity);
					Call_Finish();
					
					iItemEntity = -1;
				} while(KvGotoNextKey(g_hPlayerItems));
			}
	}
	
	CreateTimer(0.325, Timer_UpdateHealth, iClient);
	
	bLocked = false;
	
	return Plugin_Handled;
}

public Action:Timer_UpdateHealth(Handle:hTimer, any:iClient)
{
	if(IsValidEntity(iClient))
	{
		new iMaxHealth = SDKCall(g_hSDKFunc_MaxHealth, iClient);
		SetEntProp(iClient, Prop_Send, "m_iHealth", iMaxHealth, 1);
		SetEntProp(iClient, Prop_Data, "m_iHealth", iMaxHealth, 1);
	}
	return Plugin_Handled;
}

public Action:Timer_SetVisualModel(Handle:hTimer, Handle:hData)
{
	ResetPack(hData);
	
	new iClient = ReadPackCell(hData);
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient) || GetClientTeam(iClient)<=1 || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	new String:sBuffer[PLATFORM_MAX_PATH+1+16+1+1], String:sBuffers[4][PLATFORM_MAX_PATH];//, iEntity;
	while(IsPackReadable(hData, 4))
	{
		ReadPackString(hData, sBuffer, sizeof(sBuffer));
		ExplodeString(sBuffer, "|", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));
		
		PrintToConsole(iClient, "TF2AIM: creating visible weapon: slot %s, model: %s", sBuffers[0], sBuffers[1]);
		
		VisWep_GiveWeapon(iClient, StringToInt(sBuffers[0]), sBuffers[1]);
	}
	
	return Plugin_Handled;
}

public Action:Timer_SetWearableItemModel(Handle:hTimer, Handle:hData)
{
	ResetPack(hData);
	
	new iClient = ReadPackCell(hData);
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || GetClientTeam(iClient)<=1 || !IsPlayerAlive(iClient) || !IsValidEdict(iClient))
		return Plugin_Handled;
	
	new iDefIndex = ReadPackCell(hData);
	new String:sWearableModel[PLATFORM_MAX_PATH];
	ReadPackString(hData, sWearableModel, sizeof(sWearableModel));
	new String:sWearableClass[128];
	ReadPackString(hData, sWearableClass, sizeof(sWearableClass));
	
	if(!IsModelPrecached(sWearableModel))
		if(FileExists(sWearableModel, false) || FileExists(sWearableModel, true))
		{
			if(PrecacheModel(sWearableModel, true)<=0)
			{
				LogError("Can't change wearable item: model couldn't be precached: %s", sWearableModel);
				return Plugin_Handled;
			}
		}
		else 
		{
			LogError("Can't change wearable item: model's file not found: %s", sWearableModel);
			return Plugin_Handled;
		}
	
	PrintToConsole(iClient, "TF2AIM: changing %s model: %s", sWearableClass, sWearableModel);
	new iEntity = -1;
	while((iEntity = FindEntityByClassname2(iEntity, sWearableClass)) != -1)
		if(GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity")==iClient)
			if(!Attachable_IsHooked(iEntity)) // real wearable
				if(GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex")==iDefIndex)
				{
					SetEntProp(iEntity, Prop_Send, "m_iEntityQuality", 0); // hide info about real item
					SetEntityModel(iEntity, sWearableModel);
				}
	
	return Plugin_Handled;
}

public Action:Timer_LateLevelChanger(Handle:hTimer, Handle:hData)
{
	ResetPack(hData);
	
	new iClient = ReadPackCell(hData);
	new iDefIndex = ReadPackCell(hData);
	new iLevel = ReadPackCell(hData);
	new String:sClassname[128];
	ReadPackString(hData, sClassname, sizeof(sClassname));
	
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	if(StrContains(sClassname, "tf_weapon", false)==0)
	{
		new iWeapon = -1;
		for(new iSlot=0; iSlot<3; iSlot++)
			if((iWeapon = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
				if(iWeapon>0 && IsValidEdict(iWeapon))
					if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")==iDefIndex)
					{
						SetEntProp(iWeapon, Prop_Send, "m_iEntityLevel", iLevel);
						ChangeEdictState(iWeapon);
						break;
					}
	}
	else
	{
		new iEntity = -1;
		while((iEntity = FindEntityByClassname2(iEntity, sClassname)) != -1)
			if(GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity")==iClient)
				if(!Attachable_IsHooked(iEntity)) // real wearable
					if(GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex")==iDefIndex)
					{
						SetEntProp(iEntity, Prop_Send, "m_iEntityLevel", iLevel);
						ChangeEdictState(iEntity);
						break;
					}
	}
	
	return Plugin_Handled;
}

public Action:Timer_LateLevelChanger2(Handle:hTimer, Handle:hData)
{
	ResetPack(hData);
	
	new iEntity = EntRefToEntIndex(ReadPackCell(hData));
	new iLevel = ReadPackCell(hData);
	
	if(iEntity>0 && IsValidEdict(iEntity))
	{
		SetEntProp(iEntity, Prop_Send, "m_iEntityLevel", iLevel);
		ChangeEdictState(iEntity);
	}
	
	return Plugin_Handled;
}

public Action:Timer_ShowGameText(Handle:hTimer, any:iClient)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient))
		return Plugin_Handled;
	
	new String:sMessage[256], iGameTextEnt = CreateEntityByName("game_text_tf");
	Format(sMessage, sizeof(sMessage), "%N has found Golden Wrench!", iClient);
	DispatchKeyValue(iGameTextEnt, "message", sMessage);
	DispatchKeyValue(iGameTextEnt, "display_to_team", "0");
	DispatchKeyValue(iGameTextEnt, "icon", "ico_notify_golden_wrench");
	DispatchKeyValue(iGameTextEnt, "targetname", "game_text13");
	DispatchKeyValue(iGameTextEnt, "background", "0");
	DispatchSpawn(iGameTextEnt);
	AcceptEntityInput(iGameTextEnt, "Display", iGameTextEnt, iGameTextEnt);
	
	CreateTimer(2.5, Timer_KillGameText, EntIndexToEntRef(iGameTextEnt));
	
	return Plugin_Handled;
}

public Action:Timer_KillGameText(Handle:hTimer, any:iEntity)
{
	iEntity = EntRefToEntIndex(iEntity);
	if(iEntity>0 && IsValidEntity(iEntity))
		AcceptEntityInput(iEntity, "kill");
	return Plugin_Handled;
}

public Action:Timer_UpdateData(Handle:hTimer, any:bExtra)
{
	if(g_bMapChanging)
	{
		if(g_hUpdatingTimer==hTimer)
			g_hUpdatingTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if(g_iDebug>=1) // E - bExtra; T - hTimer; TU - g_hUpdatingTimer
		PrintToServer("TF2AIM: Timer_UpdateData triggered (E==%i; T==%x; UT==%x)", _:bExtra, hTimer, g_hUpdatingTimer);
	
	static iLastCall;
	static iLastReCall;
	
	if(!bool:bExtra)
	{
		if((GetTime()-60)<iLastReCall)
		{
			if(g_iDebug>=1)
				PrintToServer("TF2AIM: Timer_UpdateData overlap triggered, killing timer");
			if(g_hUpdatingTimer==hTimer)
				g_hUpdatingTimer = INVALID_HANDLE;
			return Plugin_Stop;
		}
		iLastReCall = GetTime();
	}
	
	if((GetTime()-UNLOCK_DELAY)<iLastCall)
	{
		if(g_iDebug>=1)
			PrintToServer("TF2AIM: Timer_UpdateData overlap triggered");
		return Plugin_Stop;
	}
	
	iLastCall = GetTime();
	if(hTimer!=INVALID_HANDLE)
		g_hUpdatingTimer = hTimer;
	
	if(g_iDebug>=1)
		PrintToServer("TF2AIM: Timer_UpdateData passed (g_hUpdatingTimer==%x)", g_hUpdatingTimer);
	
	new String:sQuery[4096], String:sClientAuth[32];
	for(new iClient = 1; iClient <= MaxClients; iClient++)
		if(IsClientConnected(iClient) && !IsFakeClient(iClient))
		{
			GetClientAuthString(iClient, sClientAuth, sizeof(sClientAuth));
			if(StrEqual(sQuery, ""))
				Format(sQuery, sizeof(sQuery), "`p`.`steamid`='%s'", sClientAuth);
			else
				Format(sQuery, sizeof(sQuery), "%s OR `p`.`steamid`='%s'", sQuery, sClientAuth);
		}
	
	if(strlen(sQuery)<=0)
		return Plugin_Handled;
	
	Format(sQuery, sizeof(sQuery), "SELECT `p`.`id`, `p`.`steamid`, `p`.`foundmethod`, `p`.`level`, `p`.`quality`, `p`.`override`, `p`.`attrib0`, `p`.`attrib1`, `p`.`attrib2`, `p`.`attrib3`, `p`.`attrib4`, `p`.`attrib5`, `p`.`attrib6`, `p`.`attrib7`, `p`.`attrib8`, `p`.`attrib9`, `p`.`attrib10`, `p`.`attrib11`, `p`.`attrib12`, `p`.`attrib13`, `p`.`attrib14`, `p`.`attrib15`, `g`.`id`, `g`.`plrclass`, `g`.`defindex`, `g`.`itemclass`, `g`.`dispname`, `g`.`slot`, `g`.`syslevel`, `g`.`expdate`, `g`.`cmodel`, `g`.`event`, `g`.`attrib0`, `g`.`attrib1`, `g`.`attrib2`, `g`.`attrib3`, `g`.`attrib4`, `g`.`attrib5`, `g`.`attrib6`, `g`.`attrib7`, `g`.`attrib8`, `g`.`attrib9`, `g`.`attrib10`, `g`.`attrib11`, `g`.`attrib12`, `g`.`attrib13`, `g`.`attrib14`, `g`.`attrib15` FROM `player_items` AS `p` LEFT OUTER JOIN `global_items` AS `g` ON `p`.`gid`=`g`.`id` WHERE %s", sQuery);
	SQL_TQuery(g_hDataBase, SQL_UpdatePlayerItems, sQuery);
	
	return Plugin_Handled;
}

/******************
*  SQL functions  *
*******************/

/*public SQL_UpdateGlobalItems(Handle:hOwner, Handle:hQuery, const String:sError[], any:hndl)
{
	if(hQuery == INVALID_HANDLE)
	{
		LogError("DB Query error: %s", strlen(sError)>1?sError:"Unknown");
		return;
	}
	
	static bLocked;
	if(bLocked)
		return;
	bLocked = true;
	
	if(SQL_GetRowCount(hQuery) != 0)
	{
		new Handle:hKeyValues = CreateKeyValues("items_custom");
		
		new i, String:sItemID[32], iPlayerClass, iDefIndex, String:sItemClass[129], iSlot, iLevel, iEvent, String:sItemTitle[65], String:sCustomModel[769], String:sAttrs[16][17], iAttrs, String:sAttrLine[2][13];
		while(SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, sItemID, sizeof(sItemID));
			iPlayerClass = SQL_FetchInt(hQuery, 1);
			iDefIndex = SQL_FetchInt(hQuery, 2);
			SQL_FetchString(hQuery, 3, sItemClass, sizeof(sItemClass));
			iSlot = SQL_FetchInt(hQuery, 4);
			iLevel = SQL_FetchInt(hQuery, 5);
			iEvent = SQL_FetchInt(hQuery, 6);
			SQL_FetchString(hQuery, 7, sItemTitle, sizeof(sItemTitle));
			SQL_FetchString(hQuery, 8, sCustomModel, sizeof(sCustomModel));
			for(i=0; i<16; i++)
			{
				SQL_FetchString(hQuery, (9+i), sAttrs[i], 16);
				if(StrEqual(sAttrs[i], ""))
				{
					iAttrs = i;
					break;
				}
			}
			
			KvRewind(hKeyValues);
			KvJumpToKey(hKeyValues, sItemID, true);
			KvSetString(hKeyValues, "item_name", sItemTitle);
			KvSetNum(hKeyValues, "DefIndex", iDefIndex);
			KvSetString(hKeyValues, "item_class", sItemClass);
			KvSetNum(hKeyValues, "item_slot", iSlot);
			KvSetNum(hKeyValues, "syslevel", iLevel);
			KvSetNum(hKeyValues, "event_dependent", iEvent);
			KvSetString(hKeyValues, "custom_model", sCustomModel);
			KvSetNum(hKeyValues, "used_by", iPlayerClass);
			if(iAttrs>0)
			{
				KvJumpToKey(hKeyValues, "attributes", true);
				for(i=0; i<iAttrs; i++)
					if(!StrEqual(sAttrs[i], ""))
					{
						ExplodeString(sAttrs[i], "|", sAttrLine, 2, 12);
						KvSetFloat(hKeyValues, sAttrLine[0], StringToFloat(sAttrLine[1]));
					}
				KvGoBack(hKeyValues);
			}
			KvGoBack(hKeyValues);
		}
		
		KvRewind(hKeyValues);
		g_hGlobalItems = CloneHandle(hKeyValues);
		KeyValuesToFile(hKeyValues, "./scripts/items/items_custom.txt");
		CloseHandle(hKeyValues);
	}
	
	g_bReadyToWork = true;
	
	bLocked = false;
}*/

public SQL_UpdatePlayerItems(Handle:hOwner, Handle:hQuery, const String:sError[], any:hndl)
{
	static bool:bLocked = false;
	if(bLocked)
		return;
	bLocked = true;
	
	if(hQuery==INVALID_HANDLE)
	{
		LogError("DB Query error: %s", strlen(sError)>0?sError:"Unknown");
		bLocked = false;
		return;
	}
	
	new Handle:hKeyValues = CreateKeyValues("items");
	if(SQL_GetRowCount(hQuery)>0)
	{
		new i, String:sItemID[32], String:sClientAuth[32], iFoundMethod, iLevel, iQuality, iExpDate, bool:bOverride, String:sAttrs[16][17], iAttrs, iGlobalID, iPlayerClass, iDefIndex, String:sItemClass[129], String:sItemTitle[65], iSlot, iSysLevel, String:sCustomModel[769], iEvent, String:sAttrLine[2][17];
		while(SQL_FetchRow(hQuery))
		{
			iGlobalID = 0;
			iDefIndex = 0;
			sItemTitle = "";
			sItemClass = "";
			iSlot = 0;
			iQuality = 0;
			iSysLevel = 0;
			iExpDate = 0;
			iLevel = 0;
			iPlayerClass = 0;
			iEvent = 0;
			sCustomModel = "";
			iAttrs = 0;
			
			SQL_FetchString(hQuery, 0, sItemID, sizeof(sItemID));
			SQL_FetchString(hQuery, 1, sClientAuth, sizeof(sClientAuth));
			iFoundMethod = SQL_FetchInt(hQuery, 2);
			iLevel = SQL_FetchInt(hQuery, 3);
			iQuality = SQL_FetchInt(hQuery, 4);
			bOverride = bool:SQL_FetchInt(hQuery, 5);
			if(bOverride)
				for(i=0; i<16; i++)
				{
					SQL_FetchString(hQuery, (6+i), sAttrs[i], 16);
					if(sAttrs[i][0]=='\0' || StrEqual(sAttrs[i], ""))
					{
						iAttrs = i;
						break;
					}
				}
			iGlobalID = SQL_FetchInt(hQuery, 22);
			iPlayerClass = SQL_FetchInt(hQuery, 23);
			iDefIndex = SQL_FetchInt(hQuery, 24);
			SQL_FetchString(hQuery, 25, sItemClass, sizeof(sItemClass));
			SQL_FetchString(hQuery, 26, sItemTitle, sizeof(sItemTitle));
			iSlot = SQL_FetchInt(hQuery, 27);
			iSysLevel = SQL_FetchInt(hQuery, 28);
			iExpDate = SQL_FetchInt(hQuery, 29);
			SQL_FetchString(hQuery, 30, sCustomModel, sizeof(sCustomModel));
			iEvent = SQL_FetchInt(hQuery, 31);
			if(!bOverride)
				for(i=0; i<16; i++)
				{
					SQL_FetchString(hQuery, (32+i), sAttrs[i], 16);
					if(sAttrs[i][0]=='\0' || StrEqual(sAttrs[i], ""))
					{
						iAttrs = i;
						break;
					}
				}
			
			KvRewind(hKeyValues);
			KvJumpToKey(hKeyValues, sClientAuth, true);
			KvJumpToKey(hKeyValues, sItemID, true);
			KvSetNum(hKeyValues, "item_gid", iGlobalID);
			KvSetNum(hKeyValues, "DefIndex", iDefIndex);
			KvSetString(hKeyValues, "item_name", sItemTitle);
			KvSetString(hKeyValues, "item_class", sItemClass);
			KvSetNum(hKeyValues, "item_slot", iSlot);
			KvSetNum(hKeyValues, "item_quality", iQuality);
			KvSetNum(hKeyValues, "item_level", (iSysLevel==0?iLevel:iSysLevel));
			//KvSetNum(hKeyValues, "disp_level", iLevel); // unused
			if(iPlayerClass)
				KvSetNum(hKeyValues, "used_by_class", iPlayerClass);
			if(iEvent)
				KvSetNum(hKeyValues, "event_dependent", iEvent);
			if(iExpDate)
				KvSetNum(hKeyValues, "expiration_date", iExpDate);
			if(strlen(sCustomModel)>=16)
				KvSetString(hKeyValues, "custom_model", sCustomModel);
			if(iAttrs>0)
			{
				KvJumpToKey(hKeyValues, "attributes", true);
				for(i=0; i<iAttrs; i++)
					if(sAttrs[i][0]!='\0' && !StrEqual(sAttrs[i], ""))
					{
						ExplodeString(sAttrs[i], "|", sAttrLine, 2, 16);
						KvJumpToKey(hKeyValues, sAttrLine[0], true);
						KvSetFloat(hKeyValues, "value", StringToFloat(sAttrLine[1]));
						KvGoBack(hKeyValues);
					}
				KvGoBack(hKeyValues);
			}
			
			ItemFoundEvent(StringToInt(sItemID), sClientAuth, sItemTitle, iFoundMethod, iQuality);
		}
	}
	
	KvRewind(hKeyValues);
	CloseHandle(g_hPlayerItems);
	g_hPlayerItems = CloneHandle(hKeyValues);
	KvRewind(g_hPlayerItems);
	KeyValuesToFile(hKeyValues, g_sFilePath); // for debug
	CloseHandle(hKeyValues);
	
	bLocked = false;
}

public SQL_ErrorCheckCallback(Handle:hOwner, Handle:hQuery, const String:sError[], any:data)
	if(!StrEqual("", sError))
		LogError("SQL Error: %s", sError);

public SQL_CheckTransfer(Handle:hOwner, Handle:hQuery, const String:sError[], any:data)
{
	if(!StrEqual("", sError))
		LogError("SQL Error: %s", sError);
	else
		Timer_UpdateData(INVALID_HANDLE, 1);
}

/*************
*  Commands  *
**************/

public Action:Command_MyItems(iClient, iArgs)
	if(iClient>0 && iClient<=MaxClients && IsClientInGame(iClient))
	{
		SendCookieSettingsMenu(iClient, false);
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;

public Action:Command_RewindUpdateTimer(iArgs)
{
	if(g_hUpdatingTimer!=INVALID_HANDLE)
	{
		KillTimer(g_hUpdatingTimer);
		g_hUpdatingTimer = INVALID_HANDLE;
	}
	g_hUpdatingTimer = CreateTimer(60.0, Timer_UpdateData, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	Timer_UpdateData(INVALID_HANDLE, 1);
	ReplyToCommand(0, "TF2AIM: UpdateData timer rewinded.");
	return Plugin_Handled;
}

public Action:Command_CookieChanger(iClient, iArgs)
{
	if(iArgs==0)
	{
		ReplyToCommand(0, "Usage: sm_tf2aim_cookie <target> [class] [slot] [value]");
		return Plugin_Handled;
	}
	
	if(iArgs>=1)
	{
		new String:targets[128];
		new String:pclass[4];
		new ipclass;
		new String:pslot[4];
		new ipslot;
		new String:value[32];
		new String:target_name[MAX_NAME_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		
		GetCmdArg(1, targets, sizeof(targets));
		GetCmdArg(2, pclass, sizeof(pclass));
		GetCmdArg(3, pslot, sizeof(pslot));
		GetCmdArg(4, value, sizeof(value));
		
		ipclass = StringToInt(pclass);
		ipslot = StringToInt(pslot);
		
		if( (target_count = ProcessTargetString(targets, 0, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(0, target_count);
			return Plugin_Handled;
		}
		
		new i, iClass, iSlot;
		for(i=0; i<target_count; i++)
			for(iClass=0; iClass<10; iClass++)
				if(iArgs>=2 && (ipclass>0 && ipclass<10 && iClass==(ipclass-1) || ipclass<=0 || ipclass>10) || iArgs<2)
					for(iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
						if(iArgs>=3 && (ipslot>=0 && ipslot<TF2ItemSlot_MaxSlots && iSlot==ipslot || ipslot<0 || ipslot>=TF2ItemSlot_MaxSlots) || iArgs<3)
							if(g_hCookie_Item[iClass][iSlot]!=INVALID_HANDLE)
								if(iArgs==4)
								{
									if(StringToInt(value)<0)
										value = "-1";
									SetClientCookie(target_list[i], g_hCookie_Item[iClass][iSlot], value);
									g_iCookie[target_list[i]][iClass][iSlot] = StringToInt(value);
									g_bQueue2Change[target_list[i]][iSlot] = true;
									ReplyToCommand(iClient, "- (%i) %N: class %i, slot %i, new value is %s", target_list[i], target_list[i], ipclass, ipslot, value);
								}
								else
									ReplyToCommand(iClient, "- (%i) %N: class %i, slot %i, cur value is %i", target_list[i], target_list[i], iClass, iSlot, g_iCookie[target_list[i]][iClass][iSlot]);
	}
	return Plugin_Handled;
}

public Action:Command_BuildObject(iClient, const String:sCommand[], iArgs)
{
	if(g_bMedieval || g_bSuddenDeath || g_bMeleeMode)
		return Plugin_Handled;
	return Plugin_Continue;
}

/**********
*  Menus  *
***********/

public CookieMenu_TopMenu(iClient, CookieMenuAction:iAction, any:data, String:sBuffer[], sBufferSize)
	if(iAction != CookieMenuAction_DisplayOption)
		SendCookieSettingsMenu(iClient, true);

stock SendCookieSettingsMenu(iClient, bool:bExitButton=false)
{
	new Handle:hMenu = CreateMenu(Menu_CookieSettings);
	new String:sBuffer[64];
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - class select", iClient);
	SetMenuTitle(hMenu, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - reset all", iClient);
	AddMenuItem(hMenu, "resetall", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 1", iClient);
	AddMenuItem(hMenu, "scout", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 2", iClient);
	AddMenuItem(hMenu, "sniper", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 3", iClient);
	AddMenuItem(hMenu, "soldier", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 4", iClient);
	AddMenuItem(hMenu, "demo", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 5", iClient);
	AddMenuItem(hMenu, "medic", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 6", iClient);
	AddMenuItem(hMenu, "heavy", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 7", iClient);
	AddMenuItem(hMenu, "pyro", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 8", iClient);
	AddMenuItem(hMenu, "spy", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 9", iClient);
	AddMenuItem(hMenu, "engineer", sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu - title class 10", iClient);
	AddMenuItem(hMenu, "civilian", sBuffer);
	SetMenuExitBackButton(hMenu, bExitButton);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public Menu_CookieSettings(Handle:hMenu, MenuAction:iAction, iClient, iMenuItem)
	if(iAction == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(hMenu, iMenuItem, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "resetall", false))
		{
			for(new iClass=0; iClass<10; iClass++)
				for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
				{
					if(g_hCookie_Item[iClass][iSlot]!=INVALID_HANDLE)
					{
						SetClientCookie(iClient, g_hCookie_Item[iClass][iSlot], "-1");
						g_iCookie[iClient][iClass][iSlot] = -1;
					}
					g_bQueue2Change[iClient][iSlot] = true;
				}
			SendCookieSettingsMenu(iClient, GetMenuExitBackButton(hMenu));
			PrintToChat(iClient, "* %T", "Menu - all unequiped", iClient);
		}
		else if (StrEqual(sSelection, "scout", false))
			SendCookieItemMenu(iClient, 1);
		else if (StrEqual(sSelection, "sniper", false))
			SendCookieItemMenu(iClient, 2);
		else if (StrEqual(sSelection, "soldier", false))
			SendCookieItemMenu(iClient, 3);
		else if (StrEqual(sSelection, "demo", false))
			SendCookieItemMenu(iClient, 4);
		else if (StrEqual(sSelection, "medic", false))
			SendCookieItemMenu(iClient, 5);
		else if (StrEqual(sSelection, "heavy", false))
			SendCookieItemMenu(iClient, 6);
		else if (StrEqual(sSelection, "pyro", false))
			SendCookieItemMenu(iClient, 7);
		else if (StrEqual(sSelection, "spy", false))
			SendCookieItemMenu(iClient, 8);
		else if (StrEqual(sSelection, "engineer", false))
			SendCookieItemMenu(iClient, 9);
		else if (StrEqual(sSelection, "civilian", false))
			SendCookieItemMenu(iClient, 10);
	}
	else if(iAction == MenuAction_Cancel) 
	{
		if(iMenuItem == MenuCancel_ExitBack)
			ShowCookieMenu(iClient);
	}
	else if(iAction == MenuAction_End)
		CloseHandle(hMenu);

stock SendCookieItemMenu(iClient, iClientClass)
{
	new Handle:hMenu = CreateMenu(Menu_CookieSettingsItems);
	new String:sBuffer[128];
	new String:sBuffer2[64];
	new String:sItemID[32];
	Format(sBuffer, sizeof(sBuffer), "Menu - title class %i", iClientClass);
	Format(sBuffer, sizeof(sBuffer), "%T", sBuffer, iClient);
	SetMenuTitle(hMenu, sBuffer);
	
	new String:sClientAuth[32];
	GetClientAuthString(iClient, sClientAuth, sizeof(sClientAuth));
	
	KvRewind(g_hPlayerItems);
	KvGetSectionName(g_hPlayerItems, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "items") && KvJumpToKey(g_hPlayerItems, sClientAuth, false))
	{
		new iPlayerClass, String:sWeaponClass[128], String:sItemTitle[64], iSlot, iExpDate, String:sInfo[32], String:sDisplay[128];
		
		KvGotoFirstSubKey(g_hPlayerItems);
		
		decl bool:bFoundSomething;
		bFoundSomething = false;
		
		do {
			KvGetSectionName(g_hPlayerItems, sItemID, sizeof(sItemID));
			iPlayerClass = KvGetNum(g_hPlayerItems, "used_by_class", 0);
			KvGetString(g_hPlayerItems, "item_name", sItemTitle, sizeof(sItemTitle));
			iSlot = KvGetNum(g_hPlayerItems, "item_slot");
			KvGetString(g_hPlayerItems, "item_class", sWeaponClass, sizeof(sWeaponClass));
			iExpDate = KvGetNum(g_hPlayerItems, "expiration_date", 0);
			
			if(iPlayerClass!=0 && !(iPlayerClass & TF2_GetClassBits(iClientClass)))
				continue;
			
			if(!bFoundSomething)
			{
				decl String:sBuffer3[32];
				Format(sBuffer3, sizeof(sBuffer3), "disable_class%i", iClientClass);
				Format(sBuffer2, sizeof(sBuffer2), "%T", "Menu - reset", iClient);
				AddMenuItem(hMenu, sBuffer3, sBuffer2);
			}
			bFoundSomething = true;
			
			Format(sInfo, sizeof(sInfo), "item%i_class%i_slot%i", StringToInt(sItemID), iClientClass, iSlot);
			Format(sDisplay, sizeof(sDisplay), "%s%s (#%i)", (g_iCookie[iClient][iClientClass-1][iSlot]==StringToInt(sItemID)?"* ":""), sItemTitle, StringToInt(sItemID));
			AddMenuItem(hMenu, sInfo, sDisplay, ( iExpDate>0 && GetTime()>iExpDate ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT ));
		} while(KvGotoNextKey(g_hPlayerItems));
		
		if(!bFoundSomething)
		{
			Format(sBuffer2, sizeof(sBuffer2), "%T", "Menu - empty", iClient);
			AddMenuItem(hMenu, "none", sBuffer2, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		Format(sBuffer2, sizeof(sBuffer2), "%T", "Menu - empty", iClient);
		AddMenuItem(hMenu, "none", sBuffer2, ITEMDRAW_DISABLED);
	}
	
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public Menu_CookieSettingsItems(Handle:hMenu, MenuAction:iAction, iClient, iMenuItem)
{
	new String:sBuffers[3][12];
	if(iAction == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(hMenu, iMenuItem, sSelection, sizeof(sSelection));
		if(StrEqual(sSelection, "none", false))
			SendCookieSettingsMenu(iClient);
		else if(StrContains(sSelection, "disable", false)==0)
		{
			ExplodeString(sSelection, "_", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));
			ReplaceString(sBuffers[1], 11, "class", "", false);
			for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
			{
				if(g_hCookie_Item[StringToInt(sBuffers[1])-1][iSlot]!=INVALID_HANDLE)
				{
					SetClientCookie(iClient, g_hCookie_Item[StringToInt(sBuffers[1])-1][iSlot], "-1");
					g_iCookie[iClient][StringToInt(sBuffers[1])-1][iSlot] = -1;
				}
				g_bQueue2Change[iClient][iSlot] = true;
			}
			PrintToConsole(iClient, "TF2AIM: item list cleaned (class:%s|slot:-1).", sBuffers[1]);
			SendCookieItemMenu(iClient, StringToInt(sBuffers[1]));
		}
		else
		{
			decl String:TmpBuffer[12];
			ExplodeString(sSelection, "_", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));
			ReplaceString(sBuffers[0], 11, "item", "", false);
			ReplaceString(sBuffers[1], 11, "class", "", false);
			ReplaceString(sBuffers[2], 11, "slot", "", false);
			IntToString(g_iCookie[iClient][StringToInt(sBuffers[1])-1][StringToInt(sBuffers[2])], TmpBuffer, sizeof(TmpBuffer));
			if(StrEqual(TmpBuffer, sBuffers[0], false))
			{
				SetClientCookie(iClient, g_hCookie_Item[StringToInt(sBuffers[1])-1][StringToInt(sBuffers[2])], "-1");
				g_iCookie[iClient][StringToInt(sBuffers[1])-1][StringToInt(sBuffers[2])] = -1;
			}
			else
			{
				SetClientCookie(iClient, g_hCookie_Item[StringToInt(sBuffers[1])-1][StringToInt(sBuffers[2])], sBuffers[0]);
				g_iCookie[iClient][StringToInt(sBuffers[1])-1][StringToInt(sBuffers[2])] = StringToInt(sBuffers[0]);
			}
			g_bQueue2Change[iClient][StringToInt(sBuffers[2])] = true;
			PrintToConsole(iClient, "TF2AIM: item list updated (class:%s|slot:%s)", sBuffers[1], sBuffers[2]);
			SendCookieItemMenu(iClient, StringToInt(sBuffers[1]));
		}
	}
	else if(iAction == MenuAction_Cancel) 
	{
		if(iMenuItem == MenuCancel_ExitBack)
			SendCookieSettingsMenu(iClient);
	}
	else if(iAction == MenuAction_End)
		CloseHandle(hMenu);
}

/*********************
*  ConVars changing  *
**********************/

public OnConVarChanged_PluginVersion(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	if(!StrEqual(sNewValue, PLUGIN_VERSION, false))
		SetConVarString(hConVar, PLUGIN_VERSION, true, true);

public OnConVarChanged_Medieval(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	if(bool:StringToInt(sNewValue))
		g_bMedieval = true;
	else
	{
		g_bMedieval = false;
		TF2_IsMedievalMode();
	}

public OnConVarChanged_TogglePlugin(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	g_bActive = bool:StringToInt(sNewValue);

public OnConVarChanged_ToggleDebug(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	g_iDebug = StringToInt(sNewValue);

public OnConVarChanged_MeleeMode(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	if(bool:StringToInt(sNewValue))
	{
		g_bMeleeMode = true;
		if(!StrEqual(sOldValue, sNewValue, false))
			MeleeModeDisarm();
	}
	else
	{
		g_bMeleeMode = false;
		TF2_IsDeathmatch();
		if(g_bMeleeMode && !StrEqual(sOldValue, sNewValue, false))
			MeleeModeDisarm();
	}

public OnConVarChanged_CrabMode(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	g_bCrabMode = bool:StringToInt(sNewValue);

public OnConVarChanged_TFDodgeBall(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	if(bool:StringToInt(sNewValue))
	{
		g_bTFDBMode = true;
		if(!StrEqual(sOldValue, sNewValue, false))
			TFDBModeDisarm();
	}
	else
	{
		g_bTFDBMode = false;
		if(!StrEqual(sOldValue, sNewValue, false))
			TFDBModeDisarm();
	}
}

public OnConVarChanged_CivilianFix(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	g_bCivilianFix = bool:StringToInt(sNewValue);

/************
*  Natives  *
*************/

public Native_AddItemToPlayer(Handle:hPlugin, iParams)
{
	if(g_hDataBase==INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AutoItems_AddItem: Not connected to the DB");
		return;
	}
	
	new Handle:hInputData = Handle:GetNativeCellRef(1);
	
	if(hInputData==INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AutoItems_AddItem: Invalid handle hItem: %i", _:hInputData);
		return;
	}
	
	new Handle:hData = CloneHandle(hInputData);
	CloseHandle(hInputData);
	
	ResetPack(hData);
	
	new String:sClientAuth[32];
	ReadPackString(hData, sClientAuth, sizeof(sClientAuth));
	
	new iFoundMethod = ReadPackCell(hData);
	
	new iDefIndex = ReadPackCell(hData);
	
	new iQuality = ReadPackCell(hData);
	
	new iLevel = ReadPackCell(hData);
	
	new bool:bOverride = ReadPackCell(hData)!=0;
	
	new iAttributes, String:sAttributes[16][16];
	while(IsPackReadable(hData, 4))
	{
		ReadPackString(hData, sAttributes[iAttributes++], 15);
		if(StrContains(sAttributes[iAttributes], "|", false)==-1)
			iAttributes--;
	}	
	CloseHandle(hData);
	
	if(strlen(sClientAuth)<=7 || strlen(sClientAuth)>=32 || StrContains(sClientAuth, "STEAM_", false)!=0 || StrContains(sClientAuth, ":", false)==-1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_AddItem: Invalid Steam Identifer: %s", sClientAuth);
		return;
	}
	
	if(iFoundMethod<-1 || iFoundMethod>10)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_AddItem: Invalid found method: %i", iFoundMethod);
		return;
	}
	
	if(iQuality<0 || iQuality>10)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_AddItem: Invalid item quality: %i", iQuality);
		return;
	}
	
	new String:sSumAttributes[288];
	if(iAttributes==0)
		sSumAttributes = "NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL";
	else
	{
		Format(sSumAttributes, sizeof(sSumAttributes), "'%s'", sAttributes[0]);
		for(new i=1; i<16; i++)
			if(i>=iAttributes)
				Format(sSumAttributes, sizeof(sSumAttributes), "%s, NULL", sSumAttributes);
			else
				if(StrContains(sAttributes[i], "|")!=-1)
					Format(sSumAttributes, sizeof(sSumAttributes), "%s, '%s'", sSumAttributes, sAttributes[i]);
				else
				{
					ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_AddItem: Invalid attribute #%i format: %s", (i+1), sAttributes[i]);
					return;
				}
	}
	
	new String:sQuery[2048];
	Format(sQuery, sizeof(sQuery), "INSERT INTO `player_items` VALUES (NULL, '%s', CURRENT_TIMESTAMP(), %i, %i, %i, %i, %i, %s);", sClientAuth, iDefIndex, iFoundMethod, iLevel, iQuality, _:bOverride, sSumAttributes);
	SQL_TQuery(g_hDataBase, SQL_ErrorCheckCallback, sQuery);
}

public Native_TransferItem(Handle:hPlugin, iParams)
{
	if(g_hDataBase==INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_TransferItem: Not connected to the DB");
		return;
	}
	
	new iClient = GetNativeCell(2);
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || IsFakeClient(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_TransferItem: Invalid client: %i", iClient);
		return;
	}
	
	new iItemID = GetNativeCell(1);
	if(iItemID<=0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_TransferItem: Invalid player item id: %i", iItemID);
		return;
	}
	
	new String:sClientAuth[32];
	GetClientAuthString(iClient, sClientAuth, sizeof(sClientAuth));
	
	new String:sQuery[2048];
	Format(sQuery, sizeof(sQuery), "UPDATE `player_items` SET `steamid`='%s' WHERE `id`='%i';", sClientAuth, iItemID);
	SQL_TQuery(g_hDataBase, SQL_CheckTransfer, sQuery);
}

public Native_TriggerUpdate(Handle:hPlugin, iParams)
	Timer_UpdateData(INVALID_HANDLE, 1);

public Native_GetEquipedItemID(Handle:hPlugin, iParams)
{
	new iClient = GetNativeCell(1);
	new iSlot = GetNativeCell(2);
	
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_GetEquipedItemID: Invalid client: %i", iClient);
		return -1;
	}
	
	if(iSlot<0 || iSlot>=TF2ItemSlot_MaxSlots)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "TF2AIM_GetEquipedItemID: Invalid slot: %i", iSlot);
		return -1;
	}
	
	return g_iEquiped[iClient][iSlot];
}

/*******************************
*  Stocks and other funstions  *
********************************/

stock TF2_GetClassName(const iTF2Class, String:sBuffer[], const iBufferSize)
	switch(_:iTF2Class)
	{
		case 1: strcopy(sBuffer, iBufferSize, "Scout");
		case 2: strcopy(sBuffer, iBufferSize, "Sniper");
		case 3: strcopy(sBuffer, iBufferSize, "Solider");
		case 4: strcopy(sBuffer, iBufferSize, "Demoman");
		case 5: strcopy(sBuffer, iBufferSize, "Medic");
		case 6: strcopy(sBuffer, iBufferSize, "Heavy Guy");
		case 7: strcopy(sBuffer, iBufferSize, "Pyroman");
		case 8: strcopy(sBuffer, iBufferSize, "Spy");
		case 9: strcopy(sBuffer, iBufferSize, "Engineer");
		case 10: strcopy(sBuffer, iBufferSize, "Civilian");
		default: strcopy(sBuffer, iBufferSize, "Unknown");
	}

stock _:TF2_GetClassBits(const _:iTF2Class)
{
	switch(iTF2Class)
	{
		case 0: return QUERY_CLASS_ANY;
		case 1: return QUERY_CLASS_SCOUT;
		case 2: return QUERY_CLASS_SNIPER;
		case 3: return QUERY_CLASS_SOLDIER;
		case 4: return QUERY_CLASS_DEMOMAN;
		case 5: return QUERY_CLASS_MEDIC;
		case 6: return QUERY_CLASS_HWGUY;
		case 7: return QUERY_CLASS_PYRO;
		case 8: return QUERY_CLASS_SPY;
		case 9: return QUERY_CLASS_ENGINEER;
		case 10: return QUERY_CLASS_CIVILIAN;
	}
	return -1;
}

stock FindEntityByClassname2(&iStartEnt, const String:sClassname[])
{
	while(iStartEnt>-1 && !IsValidEntity(iStartEnt))
		iStartEnt--;
	return FindEntityByClassname(iStartEnt, sClassname);
}

stock TF2_GetItemSlot(const iDefIndex)
{
	decl String:sDefIndex[32];
	decl String:sItemType[128];
	IntToString(iDefIndex, sDefIndex, sizeof(sDefIndex));
	
	if(g_iItemSlot[iDefIndex]==-1)
	{
		KvRewind(g_hItemsValues);
		KvGotoFirstSubKey(g_hItemsValues);
		KvGotoNextKey(g_hItemsValues);
		if(KvJumpToKey(g_hItemsValues, sDefIndex, false))
		{
			KvGetString(g_hItemsValues, "item_slot", sItemType, sizeof(sItemType));
			if(strcmp(sItemType, "primary")==0)
			{
				if(
					iDefIndex==20 || iDefIndex==130 || iDefIndex==207 || iDefIndex==265 // pipe bomb launcher
				)
					g_iItemSlot[iDefIndex] = TF2ItemSlot_Secondary;
				else
					g_iItemSlot[iDefIndex] = TF2ItemSlot_Primary;
			}
			else if(strcmp(sItemType, "secondary")==0)
			{
				if(
					iDefIndex==24 || iDefIndex==61 || iDefIndex==161 || iDefIndex==210 || iDefIndex==224 || // revolver
					iDefIndex==19 || iDefIndex==206 || iDefIndex==308 // sticky bomb launcher
				)
					g_iItemSlot[iDefIndex] = TF2ItemSlot_Primary;
				else
					g_iItemSlot[iDefIndex] = TF2ItemSlot_Secondary;
			}
			else if(strcmp(sItemType, "melee")==0)
				g_iItemSlot[iDefIndex] = TF2ItemSlot_Melee;
			else if(strcmp(sItemType, "pda")==0)
				g_iItemSlot[iDefIndex] = TF2ItemSlot_PDA;
			else if(strcmp(sItemType, "pda2")==0)
				g_iItemSlot[iDefIndex] = TF2ItemSlot_PDA2;
			else if(strcmp(sItemType, "head")==0)
				g_iItemSlot[iDefIndex] = TF2ItemSlot_Head;
			else if(strcmp(sItemType, "misc")==0)
				g_iItemSlot[iDefIndex] = TF2ItemSlot_Misc;
			else if(strcmp(sItemType, "action")==0)
				g_iItemSlot[iDefIndex] = TF2ItemSlot_Action;
		}
	}
	return g_iItemSlot[iDefIndex];
}

stock RemoveWearable(iClient, iSlot)
{
	static bool:bLocked[MAXPLAYERS+1] = false;
	if(iClient>0 && iClient<=MaxClients)
	{
		if(!bLocked[iClient])
		{
			bLocked[iClient] = true;
			if(g_iWearable[iClient][iSlot]>0 && IsValidEntity(g_iWearable[iClient][iSlot]))
			{
				if(Attachable_IsHooked(g_iWearable[iClient][iSlot]))
					Attachable_UnhookEntity(g_iWearable[iClient][iSlot]);
				AcceptEntityInput(g_iWearable[iClient][iSlot], "Kill");
				if(g_iDebug>=2)
					if(IsClientInGame(iClient))
						PrintToServer("TF2AIM: Removed wearable (slot %i) for %L", iSlot, iClient);
					else
						PrintToServer("TF2AIM: Removed wearable (slot %i) for %i", iSlot, iClient);
			}
			g_iWearable[iClient][iSlot] = -1;
		}
		bLocked[iClient] = false;
	}
}

stock RemoveAllWearable(iClient)
	if(iClient>0 && iClient<=MaxClients)
		for(new iSlot=0; iSlot<TF2ItemSlot_MaxSlots; iSlot++)
			RemoveWearable(iClient, iSlot);

stock TF2_EquipWearable(iClient, &iEntity)
{
	if(g_bSDKFuncLoaded==false)
	{
		LogError("SDK functions aren't loaded yet");
		return;
	}
	SDKCall(g_hSDKFunc_EquipWearable, iClient, iEntity);
}

stock TF2_RemoveWearable(iClient, &iEntity)
{
	if(g_bSDKFuncLoaded==false)
	{
		LogError("SDK functions aren't loaded yet");
		return;
	}
	
	if(!IsValidEdict(iEntity))
		return;
	
	if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")==iClient)
		SDKCall(g_hSDKFunc_RemoveWearable, iClient, iEntity);
	
	AcceptEntityInput(iEntity, "Kill");
}

stock ItemFoundEvent(const iItemID, const String:sTargetAuth[], const String:sItemTitle[], iFoundMethod = 0, iQuality = 6)
{
	if(iItemID<=0 || iFoundMethod<0)
		return;
	
	new iOtherClient, String:sQuery[64], String:sClientAuth[32];
	for(new iClient = 1; iClient<=MaxClients; iClient++)
		if(IsClientConnected(iClient) && IsClientInGame(iClient))
		{
			GetClientAuthString(iClient, sClientAuth, sizeof(sClientAuth));
			if(StrEqual(sClientAuth, sTargetAuth, false))
			{
				if(StrEqual(sItemTitle, "TF_Unique_Golden_Wrench", false))
				{
					Timer_ShowGameText(INVALID_HANDLE, iClient);
					EmitSoundToAll(SOUND_SUCCESS, _, _, SNDLEVEL_RAIDSIREN);
				}
				
				decl Handle:hNewEvent;
				hNewEvent = CreateEvent("item_found");
				if(hNewEvent!=INVALID_HANDLE)
				{
					SetEventInt(hNewEvent, "player", iClient);
					SetEventInt(hNewEvent, "quality", iQuality);
					SetEventString(hNewEvent, "item", sItemTitle);
					SetEventInt(hNewEvent, "method", iFoundMethod);
					SetEventBool(hNewEvent, "propername", false);
					FireEvent(hNewEvent);
				}
				
				if(StrContains(sItemTitle, "TF_", true)!=0)
				{
					decl Handle:hBuffer;
					decl String:sMessage[512];
					Format(sMessage, sizeof(sMessage), "\x03%N\x01 %s: \x06%s\x01", iClient, "found", sItemTitle);
					for(iOtherClient=1; iOtherClient<=MaxClients; iOtherClient++)
						if(IsClientConnected(iOtherClient) && IsClientInGame(iOtherClient))
						{
							hBuffer = StartMessageOne("SayText2", iOtherClient);
							BfWriteByte(hBuffer, iClient);
							BfWriteByte(hBuffer, true);
							BfWriteString(hBuffer, sMessage);
							EndMessage();
						}
				}
				
				if(g_hDataBase!=INVALID_HANDLE)
				{
					Format(sQuery, sizeof(sQuery), "UPDATE `player_items` SET `foundmethod`=-1 WHERE `id`=%i", iItemID);
					SQL_TQuery(g_hDataBase, SQL_ErrorCheckCallback, sQuery);
				}
				
				break;
			}
		}
}

stock bool:CheckForSpecialGameMode(const iDefIndex, iItemSlot=-1)
{
	if(iItemSlot==-1)
		iItemSlot = TF2_GetItemSlot(iDefIndex);
	
	if(iItemSlot<=-1 || iItemSlot>=TF2ItemSlot_Action)
		return false; // or true?
	
	if(g_bMedieval || g_bSuddenDeath || g_bMeleeMode || g_bCrabMode || g_bTFDBMode)
	{
		if(iDefIndex==25 || iDefIndex==26 || iDefIndex==28)
			return false;
		
		if(iItemSlot<TF2ItemSlot_Melee)
		{
			if(g_bTFDBMode)
			{
				if(
					iDefIndex!=21 && 
					iDefIndex!=208 &&
					iDefIndex!=215
				)
					return false;
			}
			else if(g_bCrabMode)
			{
				if(
					iDefIndex!=56 &&
					iDefIndex!=27
				)
					return false;
			}
			else if(g_bSuddenDeath || g_bMeleeMode)
			{
				if(
					iDefIndex!=42 &&
					iDefIndex!=46 &&
					iDefIndex!=57 &&
					iDefIndex!=58 &&
					iDefIndex!=59 &&
					iDefIndex!=129 &&
					iDefIndex!=131 &&
					iDefIndex!=159 &&
					iDefIndex!=163 &&
					iDefIndex!=222 &&
					iDefIndex!=226 &&
					iDefIndex!=231 &&
					iDefIndex!=311 &&
					iDefIndex!=354
				)
					return false;
			}
			else if(g_bMedieval)
			{
				if(
					iDefIndex!=42 &&
					iDefIndex!=46 &&
					iDefIndex!=57 &&
					iDefIndex!=59 &&
					iDefIndex!=129 &&
					iDefIndex!=131 &&
					iDefIndex!=159 &&
					iDefIndex!=163 &&
					iDefIndex!=222 &&
					iDefIndex!=226 &&
					iDefIndex!=231 &&
					iDefIndex!=311 &&
					iDefIndex!=354 &&
					iDefIndex!=56 &&
					iDefIndex!=305
				)
					return false;
			}
		}
	}
	
	return true;
}

TF2_IsMedievalMode()
{
	if(g_cvMedieval==INVALID_HANDLE)
	{
		g_cvMedieval = FindConVar("tf_medieval");
		if(g_cvMedieval==INVALID_HANDLE)
			SetFailState("Can't find tf_medieval ConVar");
		else
			HookConVarChange(g_cvMedieval, OnConVarChanged_Medieval);
	}
	
	if(GetConVarBool(g_cvMedieval))
	{
		g_bMedieval = true;
		return;
	}
	
	new iEntity = -1;
	while((iEntity = FindEntityByClassname2(iEntity, "tf_logic_medieval")) != -1)
	{
		g_bMedieval = true;
		return;
	}
	
	g_bMedieval = false;
}

TF2_IsDeathmatch()
{
	if(GetConVarBool(g_cvMeleeMode))
	{
		g_bMeleeMode = true;
		return;
	}
	
	new iEntity = -1;
	while((iEntity = FindEntityByClassname2(iEntity, "info_player_deathmatch")) != -1)
	{
		g_bMeleeMode = true;
		return;
	}
	
	g_bMeleeMode = false;
}

MeleeModeDisarm()
	for(new iClient=1; iClient<=MaxClients; iClient++)
		if(IsClientConnected(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient))
			if(g_bMeleeMode)
				CreateTimer(0.5, Timer_StripPlayerItems, iClient);
			else
				TF2_RegeneratePlayer(iClient);

TFDBModeDisarm()
	for(new iClient=1; iClient<=MaxClients; iClient++)
		if(IsClientConnected(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient))
			if(g_bTFDBMode)
				CreateTimer(0.5, Timer_StripPlayerItems, iClient);
			else
				TF2_RegeneratePlayer(iClient);

SetWearableItemModel(&iEntity, iClient, iSlot=5, String:sWearableModel[]="")
{
	if(iClient<=0 || iClient>MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient) || !IsValidEdict(iClient))
		return;
	
	RemoveWearable(iClient, iSlot);
	
	if(iEntity<=0 || !IsValidEdict(iEntity))
		return;
	
	if(!IsModelPrecached(sWearableModel))
		if(FileExists(sWearableModel, true) || FileExists(sWearableModel, false))
		{
			if(PrecacheModel(sWearableModel, true)<=0)
			{
				LogError("Can't change wearable item: model couldn't be precached: %s", sWearableModel);
				return;
			}
		}
		else
		{
			LogError("Can't change wearable item: model's file not found: %s", sWearableModel);
			return;
		}
	
	
	new iTeam = GetClientTeam(iClient)-2;
	if(iTeam<0 || iTeam>1)
		iTeam = 0;
	
	PrintToConsole(iClient, "TF2AIM: creating model: %s", sWearableModel);
	
	SetEntityModel(iEntity, sWearableModel);
	SetEntProp(iEntity, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_NOSHADOW|EF_PARENT_ANIMATES);
	SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam+2);
	SetEntProp(iEntity, Prop_Send, "m_nSkin", iTeam);
	SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 11);
	SetEntProp(iEntity, Prop_Send, "m_iEntityQuality", 0); // hide description
	
	if(strlen(sWearableModel)>0)
	{
		new iEntity2 = Attachable_CreateAttachable(iClient);
		if(iEntity2>0)
		{
			SetEntityModel(iEntity2, sWearableModel);
			SetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity", iClient);
			SetEntProp(iEntity2, Prop_Send, "m_nSkin", iTeam);
			g_iWearable[iClient][iSlot] = iEntity2;
			if(g_iDebug>=2)
				PrintToServer("TF2AIM: Created wearable (slot %i) for %L with model (skin %i): %s", iSlot, iClient, iTeam, sWearableModel);
		}
		else
			PrintToChat(iClient, "* %T", "Wearable item visibility fail", iClient);
	}
	else
	{
		PrintToChat(iClient, "* %T", "Wearable item visibility fail", iClient);
		if(g_iDebug>=2)
			PrintToServer("TF2AIM: Attempted to created wearable (slot %i) for %L with empty model", iSlot, iClient);
	}
}