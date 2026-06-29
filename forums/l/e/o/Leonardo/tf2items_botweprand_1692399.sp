#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#include <tf2items>

#define nope false
#define yep true

#define PLUGIN_VERSION "2.0.9"

//#define DEBUG_LOGFILE "logs/tf2ibwrd.log"

#define MAX_CLASSES 10
#define MAX_ITEMS 9999
#define MAX_ATTRIBS 16
#define MAX_PREFABS 100
#define MAX_PREFAB_LENGTH 32
#define MAX_PAINTCANS 100
#define MAX_UEFFECTS 100

enum
{
	TF2ItemSlot_Primary = 0,
	TF2ItemSlot_Secondary,
	TF2ItemSlot_Melee,
	TF2ItemSlot_PDA1,
	TF2ItemSlot_PDA2,
	TF2ItemSlot_Builder,
	TF2ItemSlot_Hat = 5,
	TF2ItemSlot_Misc,
	TF2ItemSlot_Action,
	TF2ItemSlot_Maximum
};

enum 
{
	TF2ItemQuality_Normal = 0,
	TF2ItemQuality_Unknown1,
	TF2ItemQuality_Genuine = 1,
	TF2ItemQuality_Unknown2,
	TF2ItemQuality_Vintage,
	TF2ItemQuality_Unknown3,
	TF2ItemQuality_Unusual,
	TF2ItemQuality_Unique,
	TF2ItemQuality_Community,
	TF2ItemQuality_Developer,
	TF2ItemQuality_Selfmade,
	TF2ItemQuality_Customized,
	TF2ItemQuality_Strange,
	TF2ItemQuality_Completed,
	TF2ItemQuality_Haunted,
	TF2ItemQuality_Maximum
};

/////////////
/* Globals */

new Handle:tf2items_botweprand_version = INVALID_HANDLE;
new Handle:tf2items_bwr_enable = INVALID_HANDLE;
new Handle:tf2items_bwr_memory = INVALID_HANDLE;
new Handle:tf2items_bwr_checkforempty = INVALID_HANDLE;
new Handle:tf2items_bwr_checkformode = INVALID_HANDLE;
new Handle:tf2items_bwr_checkforstocks = INVALID_HANDLE;
new Handle:tf2items_bwr_checkdelay = INVALID_HANDLE;
new Handle:tf2items_bwr_config = INVALID_HANDLE;
new Handle:tf_medieval = INVALID_HANDLE;
new Handle:mp_stalemate_meleeonly = INVALID_HANDLE;
new Handle:tf2items_rnd_enabled = INVALID_HANDLE;

new bool:bPluginEnabled = yep;
new bool:bWearablesEnabled = yep;
new bool:bMemoryEnabled = yep;
new bool:bCheckForEmpty = yep;
new bool:bCheckForMode = yep;
new bool:bCheckForStocks = yep;
new Float:flCheckDelay = 0.1;
new String:strConfigName[PLATFORM_MAX_PATH] = "tf2ibwr.schema.txt";
new bool:bUnusuals = yep;
new bool:bPainted = yep;
new bool:bWhitelist = nope;
new bool:bUpgradeables = yep;
new bool:bSuddenDeathMelee = nope;
new bool:bRandomizerEnabled = nope;

new _:nLastItems[MAXPLAYERS+1][TF2ItemSlot_Maximum];
new _:nLastItemAttrs[MAXPLAYERS+1][TF2ItemSlot_Maximum][MAX_ATTRIBS];
new Float:flLastItemAttrValues[MAXPLAYERS+1][TF2ItemSlot_Maximum][MAX_ATTRIBS];
new TFClassType:nLastTF2Class[MAXPLAYERS+1];

new bool:bSuddenDeath = nope;
new bool:bMedieval = nope;
new TFHoliday:curHoliday;

new Handle:hSDKEquipWearable = INVALID_HANDLE;
new Handle:hConfigFile = INVALID_HANDLE;
new Handle:hItemSchema = INVALID_HANDLE;

new Float:flItemsChances[MAX_ITEMS];
new _:iItemsPerClass[MAX_CLASSES][TF2ItemQuality_Maximum][MAX_ITEMS];
new _:iItemCountPerClass[MAX_CLASSES][TF2ItemQuality_Maximum];

new String:strPrefabNames[MAX_PREFABS][MAX_PREFAB_LENGTH];
new String:strPrefabs[MAX_PREFABS][11][MAX_PREFAB_LENGTH];
new _:nPrefabs;
new _:iPaints[MAX_PAINTCANS], _:iTeamPaints[MAX_PAINTCANS];
new _:nPaints, _:nTeamPaints;
new _:iUnusualEffects[MAX_UEFFECTS];
new _:nUnusualEffects;

#if defined DEBUG_LOGFILE
new bool:bDebugItemChecked[MAX_ITEMS];
#endif

/////////////////
/* Plugin info */

public Plugin:myinfo = {
	name = "[TF2Items] Bot Weapon Randomizer",
	author = "Leonardo",
	description = "Give random weapon to bots",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
};

////////////
/* Events */

public OnPluginStart()
{
	tf2items_botweprand_version = CreateConVar("tf2items_botweprand_version", PLUGIN_VERSION, "TF2 Bot Weapon Randomizer", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(tf2items_botweprand_version, PLUGIN_VERSION, yep, yep);
	HookConVarChange(tf2items_botweprand_version, OnConVarChanged_PluginVersion);
	
	decl String:sGameDir[8];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if(!StrEqual(sGameDir, "tf", nope) && !StrEqual(sGameDir, "tf_beta", nope))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	tf2items_bwr_enable = CreateConVar("tf2items_bwr_enable", ( bPluginEnabled ? "1" : "0" ), "", FCVAR_PLUGIN|FCVAR_NOTIFY, yep, 0.0, yep, 1.0);
	HookConVarChange(tf2items_bwr_enable, OnConVarChanged);
	
	tf2items_bwr_memory = CreateConVar("tf2items_bwr_memory", ( bMemoryEnabled ? "1" : "0" ), "", FCVAR_PLUGIN|FCVAR_NOTIFY, yep, 0.0, yep, 1.0);
	HookConVarChange(tf2items_bwr_memory, OnConVarChanged);
	
	tf2items_bwr_checkforempty = CreateConVar("tf2items_bwr_checkforempty", ( bCheckForEmpty ? "1" : "0" ), "", FCVAR_PLUGIN, yep, 0.0, yep, 1.0);
	HookConVarChange(tf2items_bwr_checkforempty, OnConVarChanged);
	
	tf2items_bwr_checkformode = CreateConVar("tf2items_bwr_checkformode", ( bCheckForMode ? "1" : "0" ), "", FCVAR_PLUGIN, yep, 0.0, yep, 1.0);
	HookConVarChange(tf2items_bwr_checkformode, OnConVarChanged);
	
	tf2items_bwr_checkforstocks = CreateConVar("tf2items_bwr_checkforstocks", ( bCheckForStocks ? "1" : "0" ), "", FCVAR_PLUGIN, yep, 0.0, yep, 1.0);
	HookConVarChange(tf2items_bwr_checkforstocks, OnConVarChanged);
	
	tf2items_bwr_checkdelay = CreateConVar("tf2items_bwr_checkdelay", "0.1", "", FCVAR_PLUGIN, yep, 0.0, yep, 0.25);
	HookConVarChange(tf2items_bwr_checkdelay, OnConVarChanged);
	
	tf2items_bwr_config = CreateConVar("tf2items_bwr_config", strConfigName, "", FCVAR_PLUGIN);
	HookConVarChange(tf2items_bwr_config, OnConVarChanged_ConfigName);
	
	tf_medieval = FindConVar( "tf_medieval" );
	HookConVarChange(tf_medieval, OnConVarChanged_Medieval);
	mp_stalemate_meleeonly = FindConVar( "mp_stalemate_meleeonly" );
	HookConVarChange(mp_stalemate_meleeonly, OnConVarChanged);
	
	bSuddenDeath = nope;
	TF2_IsMedieval();
	
	//HookEvent("player_spawn", OnHookedEvent, EventHookMode_Post);
	HookEvent("post_inventory_application", OnHookedEvent, EventHookMode_Post);
	HookEvent("teamplay_suddendeath_begin", OnSuddenDeath, EventHookMode_Pre);
	HookEvent("teamplay_suddendeath_end", OnSuddenDeath, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnSuddenDeath, EventHookMode_Pre);
	
	RegAdminCmd("tf2items_bwr_refresh", Command_RefreshConfig, ADMFLAG_GENERIC);
	
	new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
	if( hGameConf != INVALID_HANDLE )
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "EquipWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		hSDKEquipWearable = EndPrepSDKCall();
		
		CloseHandle(hGameConf);
	}
	
	OnConfigsExecuted();
}

public OnAllPluginsLoaded()
{
	tf2items_rnd_enabled = FindConVar("tf2items_rnd_enabled");
	if( tf2items_rnd_enabled == INVALID_HANDLE )
		bRandomizerEnabled = nope;
	else
		HookConVarChange(tf2items_rnd_enabled, OnConVarChanged);
}

public OnMapStart()
{
	PrecacheItemSchema();
	LoadConfigFile();
	
	bSuddenDeath = nope;
	TF2_IsMedieval();
}

public OnConfigsExecuted()
{
	bPluginEnabled = GetConVarBool(tf2items_bwr_enable);
	bMemoryEnabled = GetConVarBool(tf2items_bwr_memory);
	bCheckForEmpty = GetConVarBool(tf2items_bwr_checkforempty);
	bCheckForMode = GetConVarBool(tf2items_bwr_checkformode);
	bCheckForStocks = GetConVarBool(tf2items_bwr_checkforstocks);
	flCheckDelay = GetConVarFloat(tf2items_bwr_checkdelay);
	GetConVarString( tf2items_bwr_config, strConfigName, sizeof(strConfigName) );
	bSuddenDeathMelee = GetConVarBool(mp_stalemate_meleeonly);
	bRandomizerEnabled = ( tf2items_rnd_enabled != INVALID_HANDLE ? GetConVarBool(tf2items_rnd_enabled) : nope );
}

public OnClientPostAdminCheck(iClient)
{
	ClearMemory(iClient);
}

public Action:OnHookedEvent(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iBot = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if( !IsValidBot(iBot) || !IsPlayerAlive(iBot) )
		return Plugin_Continue;
	
	if( !bPluginEnabled || bRandomizerEnabled )
		return Plugin_Continue;
	
	CreateTimer( flCheckDelay, Timer_HookedEvent, iBot );
	
	return Plugin_Continue;
}
public Action:Timer_HookedEvent( Handle:hTimer, any:iBot )
{
	if( !IsValidBot(iBot) || !IsPlayerAlive(iBot) )
		return Plugin_Handled;
	
	if( nLastTF2Class[iBot] != TF2_GetPlayerClass(iBot) )
		ClearMemory(iBot);
	nLastTF2Class[iBot] = TF2_GetPlayerClass(iBot);
	
	new bool:bIgnoreSlots[TF2ItemSlot_Maximum] = { nope, ... };
	new iEntity, iItemDefID, iLevel, iQuality;
	if( bCheckForEmpty || bCheckForStocks )
		for( new iSlot = 0; iSlot <= TF2ItemSlot_Melee; iSlot++ )
		{
			iEntity = GetPlayerWeaponSlot( iBot, iSlot );
			if( IsValidEntity( iEntity ) )
			{
				if( bCheckForStocks )
				{
					iItemDefID = GetEntProp( iEntity, Prop_Send, "m_iItemDefinitionIndex" );
					iLevel = GetEntProp( iEntity, Prop_Send, "m_iEntityLevel" );
					iQuality = GetEntProp( iEntity, Prop_Send, "m_iEntityQuality" );
					if( !( IsStockWeapon( iItemDefID ) && iLevel == 1 && iQuality == TF2ItemQuality_Normal ) )
						bIgnoreSlots[iSlot] = yep;
				}
			}
			else
				if( bCheckForEmpty )
					bIgnoreSlots[iSlot] = yep;
		}
	bIgnoreSlots[TF2ItemSlot_Action] = yep;
	
	if( bSuddenDeathMelee && bSuddenDeath && bCheckForMode )
	{
		if( IsValidEntity( GetPlayerWeaponSlot( iBot, TF2ItemSlot_Primary ) ) )
			TF2_RemoveWeaponSlot( iBot, TF2ItemSlot_Primary );
		if( IsValidEntity( GetPlayerWeaponSlot( iBot, TF2ItemSlot_Secondary ) ) )
			TF2_RemoveWeaponSlot( iBot, TF2ItemSlot_Secondary );
		if( TF2_GetPlayerClass( iBot ) == TFClass_Engineer )
		{
			if( IsValidEntity( GetPlayerWeaponSlot( iBot, TF2ItemSlot_PDA1 ) ) )
				TF2_RemoveWeaponSlot( iBot, TF2ItemSlot_PDA1 );
			if( IsValidEntity( GetPlayerWeaponSlot( iBot, TF2ItemSlot_PDA2 ) ) )
				TF2_RemoveWeaponSlot( iBot, TF2ItemSlot_PDA2 );
			if( IsValidEntity( GetPlayerWeaponSlot( iBot, TF2ItemSlot_Builder ) ) )
				TF2_RemoveWeaponSlot( iBot, TF2ItemSlot_Builder );
		}
	}
	
	GiveMeNewItemsPlease( iBot, bIgnoreSlots );
	
	return Plugin_Handled;
}

public Action:OnSuddenDeath(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	bSuddenDeath = ( strcmp( strEventName, "teamplay_suddendeath_begin", nope ) == 0 );
	return Plugin_Continue;
}

public Action:TF2_OnIsHolidayActive( TFHoliday:holiday, &bool:bResult )
{
	if( bResult )
		curHoliday = holiday;
	return Plugin_Continue;
}

//////////////////
/* CVars & CMDs */

public Action:Command_RefreshConfig(iClient, iArgs)
{
	PrecacheItemSchema();
	LoadConfigFile();
	return Plugin_Handled;
}

public OnConVarChanged_PluginVersion(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	if( strcmp(sNewValue, PLUGIN_VERSION, nope) != 0 )
		SetConVarString(hConVar, PLUGIN_VERSION, yep, yep);
public OnConVarChanged_ConfigName(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	Format( strConfigName, sizeof(strConfigName), sNewValue );
	LoadConfigFile();
}
public OnConVarChanged_Medieval(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	bMedieval = !!StringToInt( sNewValue );
public OnConVarChanged(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	OnConfigsExecuted();

///////////////
/* Functions */

PrecacheItemSchema()
{
	if( hItemSchema != INVALID_HANDLE )
		CloseHandle( hItemSchema );
	hItemSchema = INVALID_HANDLE;
	
	new String:strFilePath[PLATFORM_MAX_PATH] = "./scripts/items/items_game.txt";
	if( !FileExists( strFilePath ) )
		SetFailState( "Couldn't found file: %s", strFilePath );
	hItemSchema = CreateKeyValues("items_game");
	FileToKeyValues( hItemSchema, strFilePath );
	KvRewind( hItemSchema );
	
	LogMessage( "Item schema precached." );
	
	ScanItemsGame();
	
#if defined DEBUG_LOGFILE
	for( new i; i < MAX_ITEMS; i++)
		bDebugItemChecked[ i ] = nope;
	LogToFileEx( DEBUG_LOGFILE, "-------------------------" );
#endif
}

LoadConfigFile()
{
	if( hConfigFile != INVALID_HANDLE )
		CloseHandle( hConfigFile );
	hConfigFile = INVALID_HANDLE;
	
	for( new iItem = 0; iItem < MAX_ITEMS; iItem++ )
		flItemsChances[ iItem ] = 100.0;
	
	if( strlen(strConfigName)>0 )
	{
		new String:strFilePath[PLATFORM_MAX_PATH], String:nItemDefID[16];
		BuildPath(Path_SM, strFilePath, sizeof(strFilePath), "configs/%s", strConfigName);
		if( FileExists( strFilePath ) )
		{
			hConfigFile = CreateKeyValues("items_config");
			FileToKeyValues( hConfigFile, strFilePath );
			KvRewind( hConfigFile );
			
			if( KvJumpToKey( hConfigFile, "settings", nope ) )
			{
				bWearablesEnabled = !!KvGetNum( hConfigFile, "wearables", 1 );
				bUnusuals = !!KvGetNum( hConfigFile, "unusuals", 1 );
				bPainted = !!KvGetNum( hConfigFile, "painted", 1 );
				bWhitelist = !!KvGetNum( hConfigFile, "whitelist", 0 );
				bUpgradeables = !!KvGetNum( hConfigFile, "upgradeables", 0 );
				
				KvGoBack( hConfigFile );
			}
			
			if( bWhitelist )
				for( new iItem = 0; iItem < MAX_ITEMS; iItem++ )
					flItemsChances[ iItem ] = 0.0;
			
			if( KvJumpToKey( hConfigFile, "items", nope ) && KvGotoFirstSubKey( hConfigFile ) )
				do
				{
					KvGetSectionName( hConfigFile, nItemDefID, sizeof(nItemDefID) );
					if( !IsCharNumeric( nItemDefID[0] ) || StringToInt(nItemDefID) >= MAX_ITEMS || StringToInt(nItemDefID) < 0 )
					{
						LogError( "Error while parsing config file: invalid item index '%s'", nItemDefID );
						continue;
					}
					
					flItemsChances[ StringToInt(nItemDefID) ] = KvGetFloat( hConfigFile, "chance", ( bWhitelist ? 0.0 : 100.0 ) );
					//PrintToServer(">> items #%s chance %f", nItemDefID, flItemsChances[ StringToInt(nItemDefID) ] );
				}
				while( KvGotoNextKey( hConfigFile ) );
		
			LogMessage( "Config file loaded.", strFilePath );
		}
		else
			LogMessage( "Couldn't found config file at: %s", strFilePath );
	}
	
	ScanItemsGame();
}

ClearMemory( iBot )
{
	if( iBot <= 0 || iBot > MaxClients )
		return;
	
	new iAttr = 0;
	for( new iSlot = 0; iSlot < TF2ItemSlot_Maximum; iSlot++ )
	{
		nLastItems[iBot][iSlot] = -1;
		for( iAttr = 0; iAttr < MAX_ATTRIBS; iAttr++ )
		{
			nLastItemAttrs[iBot][iSlot][iAttr] = -1;
			flLastItemAttrValues[iBot][iSlot][iAttr] = 0.0;
		}
	}
	
	nLastTF2Class[iBot] = TFClass_Unknown;
}

GiveMeNewItemsPlease( _:iBot, bool:bIgnoreSlots[TF2ItemSlot_Maximum] = { nope, ... } )
{
	new _:iItemDefID, _:iCurItemDefID, _:iChoose, String:strItemTitle[32], String:strClassname[36], Handle:hItem = INVALID_HANDLE, _:iEntity, _:iAttr;
	
	new TFClassType:iPlayerClass = TF2_GetPlayerClass(iBot);
	for( new iSlot = 0; iSlot < TF2ItemSlot_Maximum; iSlot++ )
	{
		if( bIgnoreSlots[iSlot] )
			continue; // just no
		
		if( ( !bWearablesEnabled || hSDKEquipWearable == INVALID_HANDLE ) && ( iSlot == TF2ItemSlot_Hat || iSlot == TF2ItemSlot_Misc ) )
		{
			nLastItems[iBot][iSlot] = -1;
			for( iAttr = 0; iAttr < MAX_ATTRIBS; iAttr++ )
			{
				nLastItemAttrs[iBot][iSlot][iAttr] = -1;
				flLastItemAttrValues[iBot][iSlot][iAttr] = 0.0;
			}
			continue;
		}
		
		if(
			iSlot == TF2ItemSlot_Melee && iPlayerClass == TFClass_Engineer && ( !( bSuddenDeath || bMedieval ) || !bCheckForMode )
			|| iSlot == TF2ItemSlot_Secondary && iPlayerClass == TFClass_Spy
			|| iSlot == TF2ItemSlot_PDA1 && ( iPlayerClass != TFClass_Spy || iPlayerClass != TFClass_Engineer )
			|| iSlot == TF2ItemSlot_PDA2 && iPlayerClass != TFClass_Engineer
		)
		{
			nLastItems[iBot][iSlot] = -1;
			for( iAttr = 0; iAttr < MAX_ATTRIBS; iAttr++ )
			{
				nLastItemAttrs[iBot][iSlot][iAttr] = -1;
				flLastItemAttrValues[iBot][iSlot][iAttr] = 0.0;
			}
			continue;
		}
		
		if( bSuddenDeathMelee && bSuddenDeath && bCheckForMode )
			if( iSlot != TF2ItemSlot_Melee )
				continue;
		
		// check if current item is banned
		iCurItemDefID = -1;
		iEntity = GetPlayerWeaponSlot( iBot, iSlot );
		if( IsValidEntity( iEntity ) )
		{
			iCurItemDefID = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
			if( iCurItemDefID >= 0 && iCurItemDefID < MAX_ITEMS )
				if( flItemsChances[ iCurItemDefID ] <= 0.0 )
					TF2_RemoveWeaponSlot( iBot, iSlot );
		}
		
		// check if item in memory is banned
		if( nLastItems[iBot][iSlot] >= 0 && nLastItems[iBot][iSlot] < MAX_ITEMS )
			if( flItemsChances[ nLastItems[iBot][iSlot] ] <= 0.0 )
			{
				nLastItems[iBot][iSlot] = -1;
				for( iAttr = 0; iAttr < MAX_ATTRIBS; iAttr++ )
				{
					nLastItemAttrs[iBot][iSlot][iAttr] = -1;
					flLastItemAttrValues[iBot][iSlot][iAttr] = 0.0;
				}
			}
		
		if( !bMemoryEnabled )
		{
			nLastItems[iBot][iSlot] = -1;
			for( iAttr = 0; iAttr < MAX_ATTRIBS; iAttr++ )
			{
				nLastItemAttrs[iBot][iSlot][iAttr] = -1;
				flLastItemAttrValues[iBot][iSlot][iAttr] = 0.0;
			}
		}
		
		// clear data for functions
		strClassname = "";
		iItemDefID = nLastItems[iBot][iSlot];
		
		if( bMedieval && !( IsMedievalWeapon( iItemDefID ) || TF2ItemSlot_Melee ) && bCheckForMode )
			iItemDefID = -1;
		
		// check if bot got same item
		if( iCurItemDefID == iItemDefID && iItemDefID != -1 )
			continue;
		
		// find random item ID
		if( iItemDefID == -1 )
		{
			iChoose = GetRandInt( 0, iItemCountPerClass[ _:iPlayerClass ][ iSlot ]-1 );
			iItemDefID = iItemsPerClass[ _:iPlayerClass ][ iSlot ][ iChoose ];
			//PrintToServer( ">> class %d, slot %d, item %d (%d/%d)", _:iPlayerClass, iSlot, iItemDefID, iChoose, iItemCountPerClass[ _:iPlayerClass ][ iSlot ] );
		}
		
		// try to give item
		if( !LookForItem( iItemDefID, strItemTitle, sizeof(strItemTitle), strClassname, sizeof(strClassname), iPlayerClass, iSlot, hItem, iBot ) )
		{
			if( hItem != INVALID_HANDLE )
				CloseHandle(hItem);
			hItem = INVALID_HANDLE;
			iItemDefID = -1; // do your best, cool guy
			LookForItem( iItemDefID, strItemTitle, sizeof(strItemTitle), strClassname, sizeof(strClassname), iPlayerClass, iSlot, hItem, iBot );
		}
		
		// give it already!
		if( iItemDefID != -1 && hItem != INVALID_HANDLE )
		{
			if( strcmp( strClassname, "tf_wearable", nope ) == 0 && ( iSlot == TF2ItemSlot_Hat || iSlot == TF2ItemSlot_Misc ) )
			{
#if defined DEBUG_LOGFILE
				if( !bDebugItemChecked[ iItemDefID ] )
					LogToFileEx( DEBUG_LOGFILE, "BEGIN giving wearable item #%d", iItemDefID );
#endif
				iEntity = TF2Items_GiveNamedItem( iBot, hItem );
				if( IsValidEntity( iEntity ) )
				{
					if( hSDKEquipWearable )
						SDKCall( hSDKEquipWearable, iBot, iEntity );
				}
				else
				{
					nLastItems[iBot][iSlot] = -1;
					for( iAttr = 0; iAttr < MAX_ATTRIBS; iAttr++ )
					{
						nLastItemAttrs[iBot][iSlot][iAttr] = -1;
						flLastItemAttrValues[iBot][iSlot][iAttr] = 0.0;
					}
				}
#if defined DEBUG_LOGFILE
				if( !bDebugItemChecked[ iItemDefID ] )
				{
					LogToFileEx( DEBUG_LOGFILE, "END giving wearable item #%d", iItemDefID );
					bDebugItemChecked[ iItemDefID ] = yep;
				}
#endif
			}
			else if( StrContains( strClassname, "tf_weapon_", nope ) == 0 || StrContains( strClassname, "tf_wearable", nope ) == 0 )
			{
#if defined DEBUG_LOGFILE
				if( !bDebugItemChecked[ iItemDefID ] )
					LogToFileEx( DEBUG_LOGFILE, "BEGIN giving weapon #%d (%s)", iItemDefID, strClassname );
#endif
				if( IsValidEntity( GetPlayerWeaponSlot( iBot, iSlot ) ) )
					TF2_RemoveWeaponSlot( iBot, iSlot );
				iEntity = TF2Items_GiveNamedItem( iBot, hItem );
				if( IsValidEntity( iEntity ) )
				{
					if( StrContains( strClassname, "tf_weapon_", nope ) == 0 )
						EquipPlayerWeapon( iBot, iEntity );
					else if( StrContains( strClassname, "tf_wearable", nope ) == 0 && hSDKEquipWearable )
						SDKCall( hSDKEquipWearable, iBot, iEntity );
				}
				else
				{
					nLastItems[iBot][iSlot] = -1;
					for( iAttr = 0; iAttr < MAX_ATTRIBS; iAttr++ )
					{
						nLastItemAttrs[iBot][iSlot][iAttr] = -1;
						flLastItemAttrValues[iBot][iSlot][iAttr] = 0.0;
					}
				}
#if defined DEBUG_LOGFILE
				if( !bDebugItemChecked[ iItemDefID ] )
				{
					LogToFileEx( DEBUG_LOGFILE, "END giving weapon #%d (%s)", iItemDefID, strClassname );
					bDebugItemChecked[ iItemDefID ] = yep;
				}
#endif
			}
		}
		
		// close handle
		if( hItem != INVALID_HANDLE )
			CloseHandle(hItem);
		hItem = INVALID_HANDLE;
	}
}

ScanItemsGame()
{
	new Handle:hLocalItemSchema = INVALID_HANDLE;
	new bool:bUsedByClass[MAX_CLASSES], bool:bSlot[TF2ItemSlot_Maximum];
	new String:nItemDefID[16], String:strItemSlot[16], String:strLocalPrefab[32], String:strLocalClassname[36];
	
	for( new iPlayerClass = 0; iPlayerClass < MAX_CLASSES; iPlayerClass++ )
		for( new iItemSlot = 0; iItemSlot < TF2ItemSlot_Maximum; iItemSlot++ )
		{
			if( iItemCountPerClass[ iPlayerClass ][ iItemSlot ] > 0 )
				for( new iItem = 0; iItem < iItemCountPerClass[ iPlayerClass ][ iItemSlot ]; iItem++ )
					iItemsPerClass[ iPlayerClass ][ iItemSlot ][ iItem ] = -1;
			iItemCountPerClass[ iPlayerClass ][ iItemSlot ] = 0;
		}
	
	for( new i = 0; i < MAX_PREFABS; i++ )
	{
		strPrefabNames[i] = "";
		strPrefabs[i][0] = "";
		strPrefabs[i][1] = "";
		strPrefabs[i][2] = "";
		strPrefabs[i][3] = "";
		strPrefabs[i][4] = "";
		strPrefabs[i][5] = "";
		strPrefabs[i][6] = "";
		strPrefabs[i][7] = "";
		strPrefabs[i][8] = "";
		strPrefabs[i][9] = "";
		strPrefabs[i][10] = "";
	}
	nPrefabs = 0;
	
	for( new i = 0; i < MAX_UEFFECTS; i++ )
		iUnusualEffects[i] = -1;
	nUnusualEffects = 0;
	
	for( new i = 0; i < MAX_PAINTCANS; i++ )
	{
		iPaints[i] = -1;
		iTeamPaints[i] = -1;
	}
	nPaints = 0;
	nTeamPaints = 0;
	
	if( hItemSchema == INVALID_HANDLE )
	{
		LogError( "hItemSchema is not precached! (ScanItemsGame)" );
		return;
	}
	
	KvRewind( hItemSchema );
	hLocalItemSchema = CloneHandle( hItemSchema );
	
	// scan for prefabs
	KvRewind( hLocalItemSchema );
	if( KvJumpToKey( hLocalItemSchema, "prefabs", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
		do
		{
			KvGetSectionName( hLocalItemSchema, strPrefabNames[nPrefabs], MAX_PREFAB_LENGTH-1 );
			if( strlen(strPrefabNames[nPrefabs]) <= 0 )
				continue;
			
			KvGetString( hLocalItemSchema, "item_class", strPrefabs[nPrefabs][0], MAX_PREFAB_LENGTH-1, "" );
			KvGetString( hLocalItemSchema, "item_slot", strPrefabs[nPrefabs][1], MAX_PREFAB_LENGTH-1, "" );
			
			if( KvJumpToKey( hLocalItemSchema, "used_by_classes", nope ) )
			{
				KvGetString( hLocalItemSchema, "scout", strPrefabs[nPrefabs][2], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "sniper", strPrefabs[nPrefabs][3], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "soldier", strPrefabs[nPrefabs][4], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "demoman", strPrefabs[nPrefabs][5], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "medic", strPrefabs[nPrefabs][6], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "heavy", strPrefabs[nPrefabs][7], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "pyro", strPrefabs[nPrefabs][8], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "spy", strPrefabs[nPrefabs][9], MAX_PREFAB_LENGTH-1, "" );
				KvGetString( hLocalItemSchema, "engineer", strPrefabs[nPrefabs][10], MAX_PREFAB_LENGTH-1, "" );
				KvGoBack( hLocalItemSchema );
			}
			
			nPrefabs++;
		}
		while( KvGotoNextKey( hLocalItemSchema ) );
	
	// scan for items
	KvRewind( hLocalItemSchema );
	if( KvJumpToKey( hLocalItemSchema, "items", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
		do
		{
			strLocalClassname = "";
			strItemSlot = "";
			
			KvGetSectionName( hLocalItemSchema, nItemDefID, sizeof(nItemDefID) );
			if( !IsCharNumeric( nItemDefID[0] ) )
				continue;
			
			// check prefab
			KvGetString( hLocalItemSchema, "prefab", strLocalPrefab, sizeof(strLocalPrefab), "" );
			if( strlen(strLocalPrefab) > 0 )
				GetDataFromPrefab( strLocalPrefab, strLocalClassname, sizeof(strLocalClassname), strItemSlot, sizeof(strItemSlot), bUsedByClass );
			
			// check item class
			if( strlen(strLocalClassname) <= 0 )
			{
				KvGetString( hLocalItemSchema, "item_class", strLocalClassname, sizeof(strLocalClassname), "" );
				if( strlen(strLocalClassname) <= 0 )
					continue; // ingnore item with empty classname
			}
			
			// paint cans only
			if( strlen(strLocalPrefab) > 0 && strcmp( strLocalPrefab, "paint_can", nope ) == 0 )
			{
				iPaints[nPaints++] = StringToInt( nItemDefID );
				continue;
			}
			if( strlen(strLocalPrefab) > 0 && strcmp( strLocalPrefab, "paint_can_team_color", nope ) == 0 )
			{
				iTeamPaints[nTeamPaints++] = StringToInt( nItemDefID );
				continue;
			}
			
			// check player class
			if( KvJumpToKey( hLocalItemSchema, "used_by_classes", nope ) )
			{
				bUsedByClass[TFClass_Scout] = !!KvGetNum( hLocalItemSchema, "scout", 0 );
				bUsedByClass[TFClass_Sniper] = !!KvGetNum( hLocalItemSchema, "sniper", 0 );
				bUsedByClass[TFClass_Soldier] = !!KvGetNum( hLocalItemSchema, "soldier", 0 );
				bUsedByClass[TFClass_DemoMan] = !!KvGetNum( hLocalItemSchema, "demoman", 0 );
				bUsedByClass[TFClass_Medic] = !!KvGetNum( hLocalItemSchema, "medic", 0 );
				bUsedByClass[TFClass_Heavy] = !!KvGetNum( hLocalItemSchema, "heavy", 0 );
				bUsedByClass[TFClass_Pyro] = !!KvGetNum( hLocalItemSchema, "pyro", 0 );
				bUsedByClass[TFClass_Spy] = !!KvGetNum( hLocalItemSchema, "spy", 0 );
				bUsedByClass[TFClass_Engineer] = !!KvGetNum( hLocalItemSchema, "engineer", 0 );
				KvGoBack( hLocalItemSchema );
			}
			else // unused at all
				continue;
			
			// check item slot
			if( strlen(strItemSlot) <= 0 )
				KvGetString( hLocalItemSchema, "item_slot", strItemSlot, sizeof(strItemSlot), "" );
			if( strlen(strItemSlot) <= 0 )
				continue;
			
			if( strcmp( strLocalClassname, "tf_weapon_revolver", nope ) == 0 )
				Format(strItemSlot, sizeof(strItemSlot), "primary"); // fix revolver slot
			
			bSlot[TF2ItemSlot_Primary] = ( strcmp( strItemSlot, "primary", nope ) == 0 );
			bSlot[TF2ItemSlot_Secondary] = ( strcmp( strItemSlot, "secondary", nope ) == 0 );
			bSlot[TF2ItemSlot_Melee] = ( strcmp( strItemSlot, "melee", nope ) == 0 );
			bSlot[TF2ItemSlot_PDA1] = ( strcmp( strItemSlot, "pda", nope ) == 0 );
			bSlot[TF2ItemSlot_PDA2] = ( strcmp( strItemSlot, "pda2", nope ) == 0 );
			bSlot[TF2ItemSlot_Hat] = ( strcmp( strItemSlot, "head", nope ) == 0 );
			bSlot[TF2ItemSlot_Misc] = ( strcmp( strItemSlot, "misc", nope ) == 0 );
			bSlot[TF2ItemSlot_Action] = ( strcmp( strItemSlot, "action", nope ) == 0 );
			
			for( new iPlayerClass = 0; iPlayerClass < MAX_CLASSES; iPlayerClass++ )
				for( new iItemSlot = 0; iItemSlot < TF2ItemSlot_Maximum; iItemSlot++ )
					if( bUsedByClass[iPlayerClass] && bSlot[iItemSlot] && flItemsChances[ StringToInt( nItemDefID ) ] > 0.0 )
					{
						iItemsPerClass[ _:iPlayerClass ][ iItemSlot ][ iItemCountPerClass[ _:iPlayerClass ][ iItemSlot ] ] = StringToInt( nItemDefID );
						iItemCountPerClass[ _:iPlayerClass ][ iItemSlot ]++;
					}
		}
		while( KvGotoNextKey( hLocalItemSchema ) );
	
	// scan for paint cans
	new iEffectID, String:nEffectID[16];
	KvRewind( hLocalItemSchema );
	if( KvJumpToKey( hLocalItemSchema, "attribute_controlled_attached_particles", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
		do
		{
			KvGetSectionName( hLocalItemSchema, nEffectID, sizeof(nEffectID) );
			if( !IsCharNumeric( nEffectID[0] ) )
				continue;
			
			iEffectID = StringToInt( nEffectID );
			
			if( iEffectID == 0 || iEffectID == 1 || iEffectID == 3 )
				continue;
			
			iUnusualEffects[nUnusualEffects++] = iEffectID;
		}
		while( KvGotoNextKey( hLocalItemSchema ) );
	
	CloseHandle( hLocalItemSchema );
}

GetAttribIDByName( String:strAttribName[] )
{
	new iAttribID = -1, String:strLocalAttribID[16], String:strLocalAttribName[32];
	new Handle:hLocalItemSchema = INVALID_HANDLE;
	
	if( strlen(strAttribName) <= 0 )
		return iAttribID;
	
	if( hItemSchema == INVALID_HANDLE )
	{
		LogError( "hItemSchema is not precached! (GetAttribIDByName)" );
		return iAttribID;
	}
	
	KvRewind( hItemSchema );
	hLocalItemSchema = CloneHandle( hItemSchema );
	KvRewind( hLocalItemSchema );
	if( KvJumpToKey( hLocalItemSchema, "attributes", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
		do
		{
			KvGetSectionName( hLocalItemSchema, strLocalAttribID, sizeof(strLocalAttribID) );
			KvGetString( hLocalItemSchema, "name", strLocalAttribName, sizeof(strLocalAttribName), "" );
			if( strcmp( strAttribName, strLocalAttribName, nope ) == 0 )
			{
				iAttribID = StringToInt( strLocalAttribID );
				CloseHandle( hLocalItemSchema );
				return iAttribID;
			}
		}
		while( KvGotoNextKey( hLocalItemSchema ) );
	CloseHandle( hLocalItemSchema );
	
	return iAttribID;
}

////////////
/* Stocks */

stock bool:LookForItem( &_:iItemDefinitionIndex = -1, String:strItemTitle[], iItemTitleLength, String:strClassname[], iClassnameLength, TFClassType:iPlayerClass, _:iSlot, &Handle:hItem, _:iBot )
{
	new Handle:hLocalItemSchema = INVALID_HANDLE;
	new bool:bResult = nope, bool:bUsedByClass[MAX_CLASSES], bool:bFail = yep, bool:bUnusual = nope, bool:bVintage = nope, bool:bGenuine = nope;
	new String:nItemDefID[16], String:strItemSlot[16], String:strLocalPrefab[32], String:strLocalClassname[36];
	new iLocalItemDefID = -1, iMinItemLevel, iMaxItemLevel, nLastPaintCan;
	new String:strAttribNames[16][64], Float:flAttribValues[16], iAttribID, iAttribCounter = 0;
	
	hItem = INVALID_HANDLE;
	
	if( iSlot == TF2ItemSlot_Melee && iPlayerClass == TFClass_Engineer && ( !( bSuddenDeath || bMedieval ) || !bCheckForMode ) )
		return bResult;
	if( iSlot == TF2ItemSlot_Secondary && iPlayerClass == TFClass_Spy )
		return bResult;
	if( iSlot == TF2ItemSlot_PDA2 && iPlayerClass != TFClass_Engineer )
		return bResult;
	if( iSlot == TF2ItemSlot_PDA1 && ( iPlayerClass != TFClass_Spy || iPlayerClass != TFClass_Engineer ) )
		return bResult;
	
	if( hItemSchema == INVALID_HANDLE )
	{
		LogError( "hItemSchema is not precached! (LookForItem)" );
		return bResult;
	}
	
	KvRewind( hItemSchema );
	hLocalItemSchema = CloneHandle( hItemSchema );
	KvRewind( hLocalItemSchema );
	if( KvJumpToKey( hLocalItemSchema, "items", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
		do
		{
			strLocalClassname = "";
			strItemSlot = "";
			
			KvGetSectionName( hLocalItemSchema, nItemDefID, sizeof(nItemDefID) );
			if( !IsCharNumeric( nItemDefID[0] ) )
				continue;
			if( StringToInt( nItemDefID ) == iItemDefinitionIndex || iItemDefinitionIndex < 0 )
			{
				if( !bUpgradeables && IsUpgradeableStockWeapon( StringToInt( nItemDefID ) ) )
					if( iItemDefinitionIndex >= 0 )
						break;
					else
						continue;
				
				if( flItemsChances[ StringToInt( nItemDefID ) ] < GetRandFloat( 0.0, 100.0 ) )
					if( iItemDefinitionIndex >= 0 )
						break;
					else
						continue;
				
				if( bMedieval && !( iSlot == TF2ItemSlot_Melee || IsMedievalWeapon( StringToInt( nItemDefID ) ) ) && bCheckForMode )
					if( iItemDefinitionIndex >= 0 )
						break;
					else
						continue;
				
				if( curHoliday != TFHoliday_Birthday && StringToInt( nItemDefID ) == 537 )
					if( iItemDefinitionIndex >= 0 )
						break;
					else
						continue;
				
				if( curHoliday != TFHoliday_HalloweenOrFullMoon && IsHalloweenItem( StringToInt( nItemDefID ) ) )
					if( iItemDefinitionIndex >= 0 )
						break;
					else
						continue;
				
				// check prefab
				KvGetString( hLocalItemSchema, "prefab", strLocalPrefab, sizeof(strLocalPrefab), "" );
				if( strlen(strLocalPrefab) > 0 )
					GetDataFromPrefab( strLocalPrefab, strLocalClassname, sizeof(strLocalClassname), strItemSlot, sizeof(strItemSlot), bUsedByClass );
				
				// check item class
				if( strlen(strLocalClassname) <= 0 )
				{
					KvGetString( hLocalItemSchema, "item_class", strLocalClassname, sizeof(strLocalClassname), "" );
					if( strlen(strLocalClassname) <= 0 )
						if( iItemDefinitionIndex >= 0 )
						{
							LogError( "Requested item #%d with empty classname!", iItemDefinitionIndex );
							break;
						}
						else
							continue;
				}
				if( strlen(strClassname) > 0 && strcmp( strClassname, strLocalClassname, nope) != 0 )
				{
					if( iItemDefinitionIndex >= 0 )
					{
						LogError( "Requested item #%d with invalid classname!", iItemDefinitionIndex );
						break;
					}
					else
						continue;
				}
				
				// check player class
				if( KvJumpToKey( hLocalItemSchema, "used_by_classes", nope ) )
				{
					bFail = yep;
					switch( iPlayerClass )
					{
						case TFClass_Scout: bFail = ( KvGetNum( hLocalItemSchema, "scout", 0 ) == 0 );
						case TFClass_Sniper: bFail = ( KvGetNum( hLocalItemSchema, "sniper", 0 ) == 0 );
						case TFClass_Soldier: bFail = ( KvGetNum( hLocalItemSchema, "soldier", 0 ) == 0 );
						case TFClass_DemoMan: bFail = ( KvGetNum( hLocalItemSchema, "demoman", 0 ) == 0 );
						case TFClass_Medic: bFail = ( KvGetNum( hLocalItemSchema, "medic", 0 ) == 0 );
						case TFClass_Heavy: bFail = ( KvGetNum( hLocalItemSchema, "heavy", 0 ) == 0 );
						case TFClass_Pyro: bFail = ( KvGetNum( hLocalItemSchema, "pyro", 0 ) == 0 );
						case TFClass_Spy: bFail = ( KvGetNum( hLocalItemSchema, "spy", 0 ) == 0 );
						case TFClass_Engineer: bFail = ( KvGetNum( hLocalItemSchema, "engineer", 0 ) == 0 );
					}
					KvGoBack( hLocalItemSchema );
					if( bFail )
						if( iItemDefinitionIndex >= 0 )
						{
							LogError( "Requested item #%d cann't be used by this class! (%d)", iItemDefinitionIndex, _:iPlayerClass );
							break;
						}
						else
							continue;
				}
				else if( strlen(strLocalPrefab) > 0 && !bUsedByClass[iPlayerClass] )
				{
					if( iItemDefinitionIndex >= 0 )
					{
						LogError( "Requested item #%d cann't be used by this class! (%d)", iItemDefinitionIndex, _:iPlayerClass );
						break;
					}
					else
						continue;
				}
				else // unused at all
					if( iItemDefinitionIndex >= 0 )
					{
						LogError( "Requested technical item #%d!", iItemDefinitionIndex );
						break;
					}
					else
						continue;
				
				// check item slot
				bFail = yep;
				if( strlen(strItemSlot) <= 0 )
					KvGetString( hLocalItemSchema, "item_slot", strItemSlot, sizeof(strItemSlot), "" );
				if( strlen(strItemSlot) <= 0 )
					if( iItemDefinitionIndex >= 0 )
					{
						LogError( "Requested item #%d with empty slot!", iItemDefinitionIndex );
						break;
					}
					else
						continue;
				if( strcmp( strLocalClassname, "tf_weapon_revolver", nope ) == 0 )
					Format(strItemSlot, sizeof(strItemSlot), "primary"); // fix revolver slot
				switch( iSlot )
				{
					case TF2ItemSlot_Primary: bFail = ( strcmp( strItemSlot, "primary", nope ) != 0 );
					case TF2ItemSlot_Secondary: bFail = ( strcmp( strItemSlot, "secondary", nope ) != 0 );
					case TF2ItemSlot_Melee: bFail = ( strcmp( strItemSlot, "melee", nope ) != 0 );
					case TF2ItemSlot_PDA1: bFail = ( strcmp( strItemSlot, "pda", nope ) != 0 );
					case TF2ItemSlot_PDA2: bFail = ( strcmp( strItemSlot, "pda2", nope ) != 0 );
					case TF2ItemSlot_Hat: bFail = ( strcmp( strItemSlot, "head", nope ) != 0 );
					case TF2ItemSlot_Misc: bFail = ( strcmp( strItemSlot, "misc", nope ) != 0 );
					case TF2ItemSlot_Action: bFail = ( strcmp( strItemSlot, "action", nope ) != 0 );
				}
				if( bFail )
					if( iItemDefinitionIndex >= 0 )
					{
						LogError( "Requested item #%d cann't be used on this slot! (%d)", iItemDefinitionIndex, iSlot );
						break;
					}
					else
						continue;
				
				iMinItemLevel = KvGetNum( hLocalItemSchema, "min_ilevel", 1 );
				if( iMinItemLevel <= 0 )
					iMinItemLevel = 0;
				iMaxItemLevel = KvGetNum( hLocalItemSchema, "max_ilevel", 1 );
				
				iAttribCounter = 0;
				
				if( KvJumpToKey( hLocalItemSchema, "attributes", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
				{
					do
					{
						KvGetSectionName( hLocalItemSchema, strAttribNames[iAttribCounter], 63 );
						flAttribValues[iAttribCounter] = KvGetFloat( hLocalItemSchema, "value", 0.0 );
						iAttribCounter++;
					}
					while( KvGotoNextKey( hLocalItemSchema ) );
					KvGoBack( hLocalItemSchema );
				}
				
				bVintage = nope;
				if( CanBeVintage( StringToInt( nItemDefID ) ) && GetRandInt(0,1) || StringToInt( nItemDefID ) == 160 )
					bVintage = yep;
				
				bGenuine = nope;
				if( IsPromoItem( StringToInt( nItemDefID ), yep ) && GetRandInt(0,1) && iAttribCounter < MAX_ATTRIBS-1 )
				{
					strAttribNames[iAttribCounter] = "cannot trade";
					flAttribValues[iAttribCounter] = 1.0;
					iAttribCounter++;
					bGenuine = yep;
				}
				
				bUnusual = nope;
				if( bUnusuals && !bGenuine && CanBeUnusual( StringToInt( nItemDefID ) ) && GetRandInt(0,1) && iAttribCounter < MAX_ATTRIBS-1 )
				{
					strAttribNames[iAttribCounter] = "attach particle effect";
					flAttribValues[iAttribCounter] = float(iUnusualEffects[GetRandInt(0,nUnusualEffects-1)]);
					iAttribCounter++;
					bUnusual = yep;
				}
				
				if( KvJumpToKey( hLocalItemSchema, "capabilities", nope ) )
				{
					if( bPainted && KvGetNum( hLocalItemSchema, "paintable", 0 ) && GetRandInt(0,1) && iAttribCounter < MAX_ATTRIBS-1 )
					{
						if( GetRandInt(0,1) && iAttribCounter < MAX_ATTRIBS-2 )
						{
							nLastPaintCan = iTeamPaints[GetRandInt(0,nTeamPaints-1)];
							strAttribNames[iAttribCounter] = "set item tint RGB";
							OpenPaintCan( flAttribValues[iAttribCounter], nLastPaintCan );
							iAttribCounter++;
							strAttribNames[iAttribCounter] = "set item tint RGB 2";
							OpenPaintCan( flAttribValues[iAttribCounter], nLastPaintCan );
							iAttribCounter++;
							nLastPaintCan = -1;
						}
						else
						{
							nLastPaintCan = iPaints[GetRandInt(0,nPaints-1)];
							strAttribNames[iAttribCounter] = "set item tint RGB";
							OpenPaintCan( flAttribValues[iAttribCounter], nLastPaintCan );
							iAttribCounter++;
							nLastPaintCan = -1;
						}
					}
					KvGoBack( hLocalItemSchema );
				}
				
				KvGetString( hLocalItemSchema, "name", strItemTitle, sizeof(iItemTitleLength), "LOOKUP FAILED!" ); // hello, skyrim
				
				iLocalItemDefID = StringToInt( nItemDefID );
				Format(strClassname, iClassnameLength, "%s", strLocalClassname);
				
				// are we finished?
				if( GetRandInt(0,1) || iItemDefinitionIndex >= 0 )
				{
					bResult = yep;
					break;
				}
			}
		}
		while( KvGotoNextKey( hLocalItemSchema ) );
	CloseHandle( hLocalItemSchema );
	
	if( bResult )
	{
		if( iItemDefinitionIndex >= 0 && nLastItems[iBot][iSlot] == iItemDefinitionIndex )
		{
			iAttribCounter = 0;
			bUnusual = nope;
			for( new iAttrib = 0; iAttrib < MAX_ATTRIBS; iAttrib++ )
				if( nLastItemAttrs[iBot][iSlot][iAttrib] >= 0 )
				{
					if( nLastItemAttrs[iBot][iSlot][iAttrib] == 134 && iLocalItemDefID != 125 && iLocalItemDefID != 1899 )
						bUnusual = yep;
					iAttribCounter++;
				}
		}
		else
		{
			for( new iAttrib = 0; iAttrib < MAX_ATTRIBS; iAttrib++ )
			{
				nLastItemAttrs[iBot][iSlot][iAttrib] = -1;
				flLastItemAttrValues[iBot][iSlot][iAttrib] = 0.0;
			}
		}
		
		iItemDefinitionIndex = iLocalItemDefID;
		nLastItems[iBot][iSlot] = iItemDefinitionIndex;
		
		// create item
		hItem = TF2Items_CreateItem( OVERRIDE_ALL );
		TF2Items_SetClassname( hItem, strClassname );
		TF2Items_SetItemIndex( hItem, iItemDefinitionIndex );
		TF2Items_SetQuality( hItem, ( bUnusual ? TF2ItemQuality_Unusual : ( bVintage ? TF2ItemQuality_Vintage : ( bGenuine ? TF2ItemQuality_Genuine : GetItemQualityByDefID( iItemDefinitionIndex ) ) ) ) );
		TF2Items_SetLevel( hItem, GetRandInt( iMinItemLevel, iMaxItemLevel ) );
		TF2Items_SetNumAttributes( hItem, iAttribCounter );
		if( iAttribCounter > 0 )
			for( new iAttrib = 0; iAttrib < iAttribCounter; iAttrib++ )
			{
				if( nLastItemAttrs[iBot][iSlot][iAttrib] >= 0 )
				{
					TF2Items_SetAttribute( hItem, iAttrib, nLastItemAttrs[iBot][iSlot][iAttrib], flLastItemAttrValues[iBot][iSlot][iAttrib] );
				}
				else
				{
					iAttribID = GetAttribIDByName( strAttribNames[iAttrib] );
					TF2Items_SetAttribute( hItem, iAttrib, iAttribID, flAttribValues[iAttrib] );
					
					nLastItemAttrs[iBot][iSlot][iAttrib] = iAttribID;
					flLastItemAttrValues[iBot][iSlot][iAttrib] = flAttribValues[iAttrib];
				}
			}
	}
	
	return bResult;
}

stock bool:GetDataFromPrefab( String:strPrefab[], String:strClassname[], iClassnameLength, String:strItemSlot[], iItemSlotLength, bool:bUsedByClass[] )
{
	if( strlen(strPrefab) <= 0 )
		return nope;
	
	for( new i = 0; i < nPrefabs; i++ )
		if( strcmp( strPrefab, strPrefabNames[i], nope ) == 0 )
		{
			Format( strClassname, iClassnameLength, "%s", strPrefabs[i][0] );
			
			Format( strItemSlot, iItemSlotLength, "%s", strPrefabs[i][1] );
			
			bUsedByClass[TFClass_Scout] = !!StringToInt(strPrefabs[i][2]);
			bUsedByClass[TFClass_Sniper] = !!StringToInt(strPrefabs[i][3]);
			bUsedByClass[TFClass_Soldier] = !!StringToInt(strPrefabs[i][4]);
			bUsedByClass[TFClass_DemoMan] = !!StringToInt(strPrefabs[i][5]);
			bUsedByClass[TFClass_Medic] = !!StringToInt(strPrefabs[i][6]);
			bUsedByClass[TFClass_Heavy] = !!StringToInt(strPrefabs[i][7]);
			bUsedByClass[TFClass_Pyro] = !!StringToInt(strPrefabs[i][8]);
			bUsedByClass[TFClass_Spy] = !!StringToInt(strPrefabs[i][9]);
			bUsedByClass[TFClass_Engineer] = !!StringToInt(strPrefabs[i][10]);
			
			return yep;
		}
	
	return nope;
}

stock OpenPaintCan( &Float:flColorRGB, &_:nLastPaintCan = -1 )
{
	new Handle:hLocalItemSchema = INVALID_HANDLE, Float:flColors[2], bool:bResult = nope;
	new String:nItemDefID[16], String:strLocalPrefab[32], String:strAttribName[21];
	
	flColorRGB = 0.0;
	
	if( hItemSchema == INVALID_HANDLE )
	{
		LogError( "hItemSchema is not precached! (OpenPaintCan)" );
		return;
	}
	
	KvRewind( hItemSchema );
	hLocalItemSchema = CloneHandle( hItemSchema );
	KvRewind( hLocalItemSchema );
	if( KvJumpToKey( hLocalItemSchema, "items", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
		do
		{
			KvGetSectionName( hLocalItemSchema, nItemDefID, sizeof(nItemDefID) );
			if( !IsCharNumeric( nItemDefID[0] ) )
				continue;
			if( StringToInt( nItemDefID ) == nLastPaintCan && nLastPaintCan >= 0 || nLastPaintCan < 0 )
			{
				// check prefab only
				KvGetString( hLocalItemSchema, "prefab", strLocalPrefab, sizeof(strLocalPrefab), "" );
				if( strcmp( strLocalPrefab, "paint_can", nope ) != 0 && strcmp( strLocalPrefab, "paint_can_team_color", nope ) != 0 )
					continue;
				
				flColors[0] = 0.0;
				flColors[1] = -1.0;
				
				if( KvJumpToKey( hLocalItemSchema, "attributes", nope ) && KvGotoFirstSubKey( hLocalItemSchema ) )
				{
					do
					{
						KvGetSectionName( hLocalItemSchema, strAttribName, 20 );
						if( strcmp( "set item tint RGB", strAttribName, nope ) == 0 )
							flColors[0] = KvGetFloat( hLocalItemSchema, "value", 0.0 );
						if( strcmp( "set item tint RGB 2", strAttribName, nope ) == 0 )
							flColors[1] = KvGetFloat( hLocalItemSchema, "value", -1.0 );
					}
					while( KvGotoNextKey( hLocalItemSchema ) );
					KvGoBack( hLocalItemSchema );
					KvGoBack( hLocalItemSchema );
				}
				
				if( nLastPaintCan == -2 && flColors[1] < 0.0 )
					continue;
				
				if( nLastPaintCan < 0 )
					flColorRGB = flColors[0];
				else
					flColorRGB = flColors[1];
				
				bResult = yep;
				if( GetRandInt(0,1) || nLastPaintCan >= 0 && nLastPaintCan == StringToInt( nItemDefID ) )
					break;
			}
		}
		while( KvGotoNextKey( hLocalItemSchema ) );
	CloseHandle( hLocalItemSchema );
	
	if( bResult )
		nLastPaintCan = StringToInt( nItemDefID );
}

stock bool:IsStockWeapon( _:iItemDefinitionIndex )
{
	if( iItemDefinitionIndex >= 0 && iItemDefinitionIndex <= 30 || iItemDefinitionIndex == 735 )
		return yep;
	return nope;
}

stock bool:IsHauntedItem( _:iItemDefinitionIndex )
{
	if( iItemDefinitionIndex >= 543 && iItemDefinitionIndex <= 569 || iItemDefinitionIndex == 267 )
		return yep;
	return nope;
}

stock bool:IsHalloweenItem( _:iItemDefinitionIndex )
{
	if( IsHauntedItem(iItemDefinitionIndex) )
		return yep;
	if(
		iItemDefinitionIndex >= 268 && iItemDefinitionIndex <= 278
		|| iItemDefinitionIndex >= 578 && iItemDefinitionIndex <= 582
		|| iItemDefinitionIndex == 115
		|| iItemDefinitionIndex == 287
		|| iItemDefinitionIndex == 289
	)
		return yep;
	return nope;
}

stock bool:IsUpgradeableStockWeapon( _:iItemDefinitionIndex )
{
	if( iItemDefinitionIndex >= 190 && iItemDefinitionIndex <= 212 )
		return yep;
	if( iItemDefinitionIndex == 737 )
		return yep;
	return nope;
}

stock bool:IsPromoItem( _:iItemDefinitionIndex, bool:bGenuineOnly = nope )
{
	switch(iItemDefinitionIndex)
	{
		case	126,263,264,292,299,345,346,347,348,349,354,355,356,357,358,359,360,
				420,434,435,436,437,443,452,453,454,465,466,467,468,513,514,515,516,
				517,518,519,520,521,522,523,524,525,526,527,528,538,539,540,541,585,
				586,587,634,635,637,638,702,703,704,718,719,720,754:
			return yep;
		case	143,160,161,162,189,240,261,294,295,296,297,298,332,333,334,335,336,
				408,409,410,422,471,473,486,537,598,666,667,668,727,1899:
			return ( bGenuineOnly ? nope : yep );
	}
	return nope;
}

stock bool:CanBeVintage( _:iItemDefinitionIndex )
{
	if(
		IsStockWeapon(iItemDefinitionIndex)
		|| IsUpgradeableStockWeapon(iItemDefinitionIndex)
		|| IsPromoItem(iItemDefinitionIndex)
		|| IsHalloweenItem(iItemDefinitionIndex)
	)
		return nope;
	
	if(
		iItemDefinitionIndex == 121
		|| iItemDefinitionIndex == 125
		|| iItemDefinitionIndex == 160
		|| iItemDefinitionIndex >= 164 && iItemDefinitionIndex <= 166
		|| iItemDefinitionIndex == 169
		|| iItemDefinitionIndex == 170
		|| iItemDefinitionIndex >= 242 && iItemDefinitionIndex <= 245
	)
		return nope;
	
	if( iItemDefinitionIndex < 262 )
		return yep;
	
	return nope;
}

stock _:GetItemQualityByDefID( _:iItemDefinitionIndex )
{
	new _:iQuality = TF2ItemQuality_Unique;
	
	if( IsHauntedItem( iItemDefinitionIndex ) )
		iQuality = TF2ItemQuality_Haunted;
	
	if( IsStockWeapon( iItemDefinitionIndex ) )
		iQuality = TF2ItemQuality_Normal;
	
	return iQuality;
}

stock _:GetItemLevelByDefID( _:iItemDefinitionIndex )
{
	new iLevel = 1;
	switch( iItemDefinitionIndex )
	{
		case 125,262,335,336,360,434,435: iLevel = 1;
		case 164,343: iLevel = 5;
		case 115,116,126,165,240,261,268,269,270,271,272,273,274,275,276,277,263,279,346,347,486,408,409,410,470,473,490,491,492,514,515,516,517,518,519,520,537: iLevel = 10;
		case 422: iLevel = 13;
		case 166,333,392,443,483,484: iLevel = 15;
		case 170,189,295,299,296,345,420,432,454,1899: iLevel = 20;
		case 334: iLevel = 28;
		case 332: iLevel = 30;
		case 278,287,289,290,291: iLevel = 31;
		case 292,471: iLevel = 50;
	}
	return iLevel;
}

stock bool:CanBeUnusual( _:iItemDefinitionIndex )
{
	switch( iItemDefinitionIndex )
	{
		case	47,48,49,50,51,52,53,54,55,94,95,96,97,98,99,100,101,102,104,105,106,
				107,108,109,110,120,135,137,139,145,146,147,148,150,151,152,158,174,
				177,178,179,180,181,182,183,184,185,213,216,219,223,227,229,246,247,
				248,249,250,251,252,253,254,255,259,303,306,309,313,314,315,316,318,
				319,321,322,323,324,330,337,338,339,340,341,342,344,358,359,361,363,
				377,378,379,380,381,382,383,384,390,391,393,394,395,397,398,399,400,
				403,417,427,434,435,436,437,439,445,451,459,465,467,478,480,481,514,
				517,518,521,523,538,539,590,597,600,601,602,603,604,605,607,611,612,
				613,614,615,616,617,622,626,627,628,631,633,644,652,657,671,701,707,
				708,709,721,722,734,753:
			return yep;
	}
	return nope;
}

stock bool:TF2_IsMedieval()
{
	bMedieval = nope;
	
	if( tf_medieval == INVALID_HANDLE )
	{
		tf_medieval = FindConVar("tf_medieval");
		if( tf_medieval != INVALID_HANDLE )
		{
			HookConVarChange( tf_medieval, OnConVarChanged_Medieval );
			bMedieval = !!GetConVarInt(tf_medieval);
		}
	}
	if( GetConVarBool( tf_medieval ) )
		bMedieval = yep;
	
	new iEntity = -1;
	while( ( iEntity = FindEntityByClassname2( iEntity, "tf_logic_medieval" ) ) != -1 )
	{
		bMedieval = yep;
		break;
	}
	
	return bMedieval;
}

stock bool:IsMedievalWeapon( _:iItemDefID )
{
	if(
		IsStockWeapon( iItemDefID )
		|| iItemDefID == 42 // sandwich
		|| iItemDefID == 46 // bonk
		|| iItemDefID == 56 // huntsman
		|| iItemDefID == 57 // razorback
		|| iItemDefID == 131 // chargin targe
		|| iItemDefID == 133 // gunboats
		|| iItemDefID == 159 // dalokohs bar
		|| iItemDefID == 163 // crit-a-cola
		|| iItemDefID == 222 // mad milk
		|| iItemDefID == 231 // darwin's danger shield
		|| iItemDefID == 305 // crusaders crossbow
		|| iItemDefID == 311 // buffalo steak sandvich
		|| iItemDefID == 405 // ali babas wee booties
		|| iItemDefID == 406 // splendid screen
		|| iItemDefID == 433 // fishcake
		|| iItemDefID == 444 // mantreads
		|| iItemDefID == 608 // bootlegger
	)
		return yep;
	return nope;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
		startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

stock _:GetRandInt( _:min, _:max, _:seed = 0 )
{
	SetRandomSeed( seed != 0 ? seed : RoundFloat(GetEngineTime()) );
	return GetRandomInt( min, max );
}
stock Float:GetRandFloat( Float:min = 0.0, Float:max = 1.0, _:seed = 0 )
{
	SetRandomSeed( seed != 0 ? seed : RoundFloat(GetEngineTime()) );
	return GetRandomFloat( min, max );
}

stock bool:IsValidClient( _:iClient )
{
	if( iClient <= 0 ) return nope;
	if( iClient > MaxClients ) return nope;
	if( !IsClientConnected(iClient) ) return nope;
	return IsClientInGame(iClient);
}
stock bool:IsValidBot( _:iBot )
{
	if( !IsValidClient(iBot) ) return nope;
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 4
	if( IsClientSourceTV(iBot) ) return nope;
	if( IsClientReplay(iBot) ) return nope;
#endif
	if( GetClientTeam(iBot) <= 1 ) return nope;
	return IsFakeClient(iBot);
}