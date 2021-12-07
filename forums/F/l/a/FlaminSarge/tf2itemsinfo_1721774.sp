#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <tf2items>
#tryinclude <updater>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN
#include <tf2itemsinfo>

#define nope false
#define yep true

#define PLUGIN_VERSION "1.7.4"
#define PLUGIN_UPDATE_URL "http://files.xpenia.org/sourcemod/tf2ii/updatelist.txt"

#define DEBUG_LOGFILE "logs/tf2ii.log"

#define MAX_ATTRS_PER_ITEM 16
#define MAX_ATTRIBS 999
#define MAX_EFFECTS 99

#define PREFAB_LENGTH 32
#define ITEMCLASS_LENGTH 36
#define ITEMSLOT_LENGTH 16
#define ITEMTOOL_LENGTH 16
#define ITEMNAME_LENGTH 64
#define ITEMQUALITY_LENGTH 16
#define ATTRIBNAME_LENGTH 64

#define SEARCHNAME_MINLENGTH 4

/////////////
/* Globals */

new Handle:sm_tf2ii_version = INVALID_HANDLE;

new Handle:hSDKEquipWearable = INVALID_HANDLE;

new Handle:hForward_ItemSchemaUpdated = INVALID_HANDLE;

new Handle:hEquipConflicts = INVALID_HANDLE;

new String:strAttribData[MAX_ATTRIBS][ATTRIBNAME_LENGTH];
new _:nEffects;
new _:iEffects[MAX_EFFECTS];

new bool:bBaseItem[TF2_MAX_ITEMS];
new bool:bPaintable[TF2_MAX_ITEMS];
new bool:bItemCanBeUnusual[TF2_MAX_ITEMS];
new bool:bItemCanBeVintage[TF2_MAX_ITEMS];
new bool:bItemCanBeStrange[TF2_MAX_ITEMS];
new bool:bHauntedItem[TF2_MAX_ITEMS];
new bool:bHalloweenItem[TF2_MAX_ITEMS];
new bool:bPromotionalItem[TF2_MAX_ITEMS];
new bool:bItemCanBeGenuine[TF2_MAX_ITEMS];
new bool:bUpgradeableStockItem[TF2_MAX_ITEMS];
new bool:bFestiveStockItem[TF2_MAX_ITEMS];
new bool:bMedievalItem[TF2_MAX_ITEMS];
new bool:bBirthdayItem[TF2_MAX_ITEMS];
new bool:bHalloweenOrFullMoonItem[TF2_MAX_ITEMS];
new bool:bChristmasItem[TF2_MAX_ITEMS];

new bool:bItemExists[TF2_MAX_ITEMS];
new String:strItemName[TF2_MAX_ITEMS][ITEMNAME_LENGTH];
new String:strPrefab[TF2_MAX_ITEMS][PREFAB_LENGTH];
new String:strItemClass[TF2_MAX_ITEMS][ITEMCLASS_LENGTH];
new String:strItemSlot[TF2_MAX_ITEMS][ITEMSLOT_LENGTH];
new String:strItemTool[TF2_MAX_ITEMS][ITEMTOOL_LENGTH];
new _:iItemSlot[TF2_MAX_ITEMS];
new _:iMinLevel[TF2_MAX_ITEMS];
new _:iMaxLevel[TF2_MAX_ITEMS];
new String:strQuality[TF2_MAX_ITEMS][ITEMQUALITY_LENGTH];
new _:iQuality[TF2_MAX_ITEMS];
new bool:bUsedByClass[TF2_MAX_ITEMS][TFClassType];
new _:iAttributes[TF2_MAX_ITEMS];
new String:strAttrNames[TF2_MAX_ITEMS][MAX_ATTRS_PER_ITEM][ATTRIBNAME_LENGTH];
new _:iAttrIDs[TF2_MAX_ITEMS][MAX_ATTRS_PER_ITEM];
new Float:flAttrValues[TF2_MAX_ITEMS][MAX_ATTRS_PER_ITEM];
new Handle:hItemEquipRegions[TF2_MAX_ITEMS] = INVALID_HANDLE;

/////////////////
/* Plugin info */

public Plugin:myinfo = {
	name = "[DEV] TF2 Items Info",
	author = "Leonardo",
	description = "Obtaining item info",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	CreateNative( "TF2II_IsValidItemID", Native_IsValidItemID );
	CreateNative( "TF2II_GetItemClass", Native_GetItemClass );
	CreateNative( "TF2II_GetItemSlot", Native_GetItemSlot );
	CreateNative( "TF2II_GetItemSlotName", Native_GetItemSlotName );
	CreateNative( "TF2II_IsItemUsedByClass", Native_IsItemUsedByClass );
	CreateNative( "TF2II_GetItemMinLevel", Native_GetItemMinLevel );
	CreateNative( "TF2II_GetItemMaxLevel", Native_GetItemMaxLevel );
	CreateNative( "TF2II_GetItemQualityName", Native_GetItemQualityName );
	CreateNative( "TF2II_GetItemQuality", Native_GetItemQuality );
	CreateNative( "TF2II_GetItemNumAttributes", Native_GetNumAttributes );
	CreateNative( "TF2II_GetItemAttributeName", Native_GetAttributeName );
	CreateNative( "TF2II_GetItemAttributeID", Native_GetAttributeID );
	CreateNative( "TF2II_GetItemAttributeValue", Native_GetAttributeValue );
	CreateNative( "TF2II_GetToolType", Native_GetToolType );
	CreateNative( "TF2II_ItemHolidayRestriction", Native_ItemHolidayRestriction );
	CreateNative( "TF2II_GetItemEquipRegions", Native_GetItemEquipRegions );
	CreateNative( "TF2II_GetItemName", Native_GetItemName );

	CreateNative( "TF2II_IsBaseItem", Native_IsBaseItem );
	CreateNative( "TF2II_IsItemPaintable", Native_IsItemPaintable );
	CreateNative( "TF2II_ItemCanBeUnusual", Native_ItemCanBeUnusual );
	CreateNative( "TF2II_ItemCanBeVintage", Native_ItemCanBeVintage );
	CreateNative( "TF2II_IsPromotionalItem", Native_IsPromotionalItem );
	CreateNative( "TF2II_IsHauntedItem", Native_IsHauntedItem );
	CreateNative( "TF2II_IsHalloweenItem", Native_IsHalloweenItem );
	CreateNative( "TF2II_IsUpgradeableStockWeapon", Native_IsUpgradeableStockWeapon );
	CreateNative( "TF2II_IsFestiveStockWeapon", Native_IsFestiveStockWeapon );
	CreateNative( "TF2II_IsMedievalWeapon", Native_IsMedievalWeapon );
	CreateNative( "TF2II_ItemCanBeStrange", Native_ItemCanBeStrange );

	CreateNative( "TF2II_IsConflictRegions", Native_IsConflictRegions );

	CreateNative( "TF2II_GetAttributeIDByName", Native_GetAttributeIDByName );
	CreateNative( "TF2II_GetAttributeNameByID", Native_GetAttributeNameByID );

	CreateNative( "TF2II_FindItemsIDsByCond", Native_FindItemsIDsByCond );

	CreateNative( "TF2II_ListAttachableEffects", Native_ListAttachableEffects );

	CreateNative( "TF2II_GetNamedItem", Native_GetNamedItem );
	CreateNative( "TF2II_GiveNamedItem", Native_GiveNamedItem );

	hForward_ItemSchemaUpdated = CreateGlobalForward( "TF2II_OnItemSchemaUpdated", ET_Ignore );

	RegPluginLibrary("tf2itemsinfo");

	return APLRes_Success;
}

////////////
/* Events */

public OnPluginStart()
{
	sm_tf2ii_version = CreateConVar("sm_tf2ii_version", PLUGIN_VERSION, "TF2 Items Info Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(sm_tf2ii_version, PLUGIN_VERSION, yep, yep);
	HookConVarChange(sm_tf2ii_version, OnConVarChanged_PluginVersion);

	if( !IsDedicatedServer() )
		SetFailState("THIS PLUGIN IS FOR DEDICATED SERVER ONLY!");

	decl String:sGameDir[8];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if( strcmp(sGameDir, "tf", nope) != 0 && strcmp(sGameDir, "tf_beta", nope) != 0 )
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");

	RegAdminCmd("sm_tf2ii_refresh", Command_RefreshConfig, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tf2ii_reload", Command_RefreshConfig, ADMFLAG_GENERIC);

	RegConsoleCmd( "sm_tf2ii_search", Command_Search, "Find items by name." );
	RegConsoleCmd( "sm_tf2ii_find", Command_Search, "Find items by name." );
	RegConsoleCmd( "sm_tf2ii_s", Command_Search, "Find items by name." );
	RegConsoleCmd( "sm_tf2ii_f", Command_Search, "Find items by name." );
	RegConsoleCmd( "sm_searchitems", Command_Search, "[TF2II] Find items by name." );
	RegConsoleCmd( "sm_finditems", Command_Search, "[TF2II] Find items by name." );
	RegConsoleCmd( "sm_si", Command_Search, "[TF2II] Find items by name." );
	//RegConsoleCmd( "sm_fi", Command_Search, "[TF2II] Find items by name." );

	decl String:strFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strFilePath, sizeof(strFilePath), "gamedata/tf2items.randomizer.txt");
	if( FileExists( strFilePath ) )
	{
		new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
		if( hGameConf != INVALID_HANDLE )
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "EquipWearable");
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			hSDKEquipWearable = EndPrepSDKCall();

			CloseHandle(hGameConf);
		}
	}

	ReloadConfigs();
	PrecacheItemSchema();

	Call_StartForward( hForward_ItemSchemaUpdated );
	Call_Finish();
}

//////////////////
/* CVars & CMDs */

public Action:Command_RefreshConfig( iClient, iArgs )
{
	ReloadConfigs();
	PrecacheItemSchema();

	Call_StartForward( hForward_ItemSchemaUpdated );
	Call_Finish();

	return Plugin_Handled;
}

public Action:Command_Search( iClient, iArgs )
{
	if( iClient < 0 || iClient > MaxClients )
		return Plugin_Continue;

	decl String:strCmdName[16];
	GetCmdArg( 0, strCmdName, sizeof(strCmdName) );
	if( iArgs < 1 )
	{
		ReplyToCommand( iClient, "Usage: %s <name>", strCmdName );
		return Plugin_Handled;
	}

	decl String:strSearch[16];
	GetCmdArg( 1, strSearch, sizeof(strSearch) );
	if( strlen( strSearch ) < SEARCHNAME_MINLENGTH )
	{
		ReplyToCommand( iClient, "Too short name! Minimum: %d chars", SEARCHNAME_MINLENGTH );
		return Plugin_Handled;
	}

	new i, Handle:hResults = CreateArray();

	for( i = 0; i < TF2_MAX_ITEMS; i++ )
		if( bItemExists[i] && StrContains( strItemName[i], strSearch, false ) > -1 )
			PushArrayCell( hResults, i );

	decl String:strMessage[250];

	Format( strMessage, sizeof(strMessage), "Found %d items:", GetArraySize(hResults) );
	ReplyToCommand( iClient, strMessage );

	if( GetArraySize(hResults) > 0 )
		for( i = 0; i < GetArraySize(hResults); i++ )
		{
			Format( strMessage, sizeof(strMessage), "%d: %s", GetArrayCell( hResults, i ), strItemName[ GetArrayCell( hResults, i ) ] );
			ReplyToCommand( iClient, strMessage );
		}

	CloseHandle( hResults );

	return Plugin_Handled;
}

public OnConVarChanged_PluginVersion(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	if( strcmp(sNewValue, PLUGIN_VERSION, nope) != 0 )
		SetConVarString(hConVar, PLUGIN_VERSION, yep, yep);

///////////////
/* Functions */

PrecacheItemSchema()
{
	new i, iClass, iAttrib;

	for( new iItem = 0; iItem < TF2_MAX_ITEMS; iItem++ )
	{
		bItemExists[iItem] = nope;
		strItemName[iItem] = "";
		strPrefab[iItem] = "";
		strItemClass[iItem] = "";
		strItemSlot[iItem] = "";
		strItemTool[iItem] = "";
		iItemSlot[iItem] = -1;
		iMinLevel[iItem] = -1;
		iMaxLevel[iItem] = -1;
		strQuality[iItem] = "";
		iQuality[iItem] = -1;
		bBaseItem[iItem] = nope;
		bPaintable[iItem] = nope;

		if( hItemEquipRegions[iItem] != INVALID_HANDLE )
			CloseHandle( hItemEquipRegions[iItem] );
		hItemEquipRegions[iItem] = INVALID_HANDLE;

		for( iClass = 0; iClass < _:TFClassType; iClass++ )
			bUsedByClass[iItem][iClass] = nope;

		iAttributes[iItem] = 0;
		for( iAttrib = 0; iAttrib < MAX_ATTRS_PER_ITEM; iAttrib++ )
		{
			strAttrNames[iItem][iAttrib] = "";
			iAttrIDs[iItem][iAttrib] = 0;
			flAttrValues[iItem][iAttrib] = 0.0;
		}
	}

	for( iAttrib = 0; iAttrib < MAX_ATTRIBS; iAttrib++ )
		strAttribData[iAttrib] = "";

	nEffects = 0;
	for( i = 0; i < MAX_EFFECTS; i++ )
		iEffects[i] = 0;


	decl String:strFilePath[PLATFORM_MAX_PATH] = "./scripts/items/items_game.txt";
	if( !FileExists( strFilePath ) )
		SetFailState( "Couldn't found file: %s", strFilePath );
	new Handle:hItemSchema = CreateKeyValues("items_game");
	FileToKeyValues( hItemSchema, strFilePath );
	KvRewind( hItemSchema );

	if( hEquipConflicts != INVALID_HANDLE )
		CloseHandle( hEquipConflicts );
	hEquipConflicts = INVALID_HANDLE;
	if( KvJumpToKey( hItemSchema, "equip_conflicts", nope ) )
	{
		hEquipConflicts = CreateKeyValues( "equip_conflicts" );
		KvCopySubkeys( hItemSchema, hEquipConflicts );
		KvGoBack( hItemSchema );
	}

	new Handle:hPrefabs = INVALID_HANDLE;
	if( KvJumpToKey( hItemSchema, "prefabs", nope ) )
	{
		hPrefabs = CreateKeyValues( "prefabs" );
		KvCopySubkeys( hItemSchema, hPrefabs );
		KvGoBack( hItemSchema );
	}

	new Handle:hItems = INVALID_HANDLE;
	if( KvJumpToKey( hItemSchema, "items", nope ) )
	{
		hItems = CreateKeyValues( "items" );
		KvCopySubkeys( hItemSchema, hItems );
		KvGoBack( hItemSchema );
	}

	if( KvJumpToKey( hItemSchema, "attributes", nope ) )
	{
		new Handle:hAttributes = INVALID_HANDLE;
		decl String:strABuffer[2][ATTRIBNAME_LENGTH];

		hAttributes = CreateKeyValues( "attributes" );
		KvCopySubkeys( hItemSchema, hAttributes );
		KvRewind( hAttributes );
		if( KvGotoFirstSubKey( hAttributes ) )
			do
			{
				KvGetSectionName( hAttributes, strABuffer[0], ATTRIBNAME_LENGTH-1 );
				KvGetString( hAttributes, "name", strABuffer[1], ATTRIBNAME_LENGTH-1, "" );
				if( strlen(strABuffer[1]) > 0 && IsCharNumeric(strABuffer[0][0]) && StringToInt(strABuffer[0]) >= 0 && StringToInt(strABuffer[0]) < MAX_ATTRIBS )
					Format( strAttribData[StringToInt(strABuffer[0])], ATTRIBNAME_LENGTH-1, "%s", strABuffer[1] );
			}
			while( KvGotoNextKey( hAttributes ) );

		CloseHandle( hAttributes );
		KvGoBack( hItemSchema );
	}

	if( KvJumpToKey( hItemSchema, "attribute_controlled_attached_particles", nope ) )
	{
		new Handle:hEffects = INVALID_HANDLE;
		decl String:strEBuffer[8];
		new iEffectID;

		hEffects = CreateKeyValues( "attribute_controlled_attached_particles" );
		KvCopySubkeys( hItemSchema, hEffects );
		KvRewind( hEffects );
		if( KvGotoFirstSubKey( hEffects ) )
			do
			{
				KvGetSectionName( hEffects, strEBuffer, sizeof(strEBuffer) );
				if( strlen(strEBuffer) > 0 && IsCharNumeric(strEBuffer[0]) )
				{
					iEffectID = StringToInt(strEBuffer);
					iEffects[nEffects++] = iEffectID;
				}
			}
			while( KvGotoNextKey( hEffects ) );

		CloseHandle( hEffects );
		KvGoBack( hItemSchema );
	}
	CloseHandle(hItemSchema);

	decl String:strBuffer[128];
	new iItemDefID, bool:bUsePrefab, iTry, nItems;

	KvRewind( hItems );
	if( KvGotoFirstSubKey( hItems ) )
		do
		{
			bUsePrefab = nope;

			KvGetSectionName( hItems, strBuffer, sizeof(strBuffer) );
			if( !IsCharNumeric( strBuffer[0] ) )
				continue;
			iItemDefID = StringToInt( strBuffer );
			if( iItemDefID >= TF2_MAX_ITEMS )
			{
				LogError("Reached items limit. Please, contact plugin author!");
				continue;
			}

			// name
			KvGetString( hItems, "name", strItemName[iItemDefID], ITEMNAME_LENGTH-1, "" );

			// prefab
			KvGetString( hItems, "prefab", strPrefab[iItemDefID], PREFAB_LENGTH-1, "" );
			if( strlen( strPrefab[iItemDefID] ) > 0 && hPrefabs != INVALID_HANDLE )
			{
				KvRewind( hPrefabs );
				if( KvJumpToKey( hPrefabs, strPrefab[iItemDefID], nope ) )
					bUsePrefab = yep;
			}

			// if bUsePrefab is true, so check prefab AND item section (for overrides),
			// otherwise - only item section
			for( iTry = 0; iTry < 2; iTry++ )
			{
				// is it's a base item?
				if( !bBaseItem[iItemDefID] )
					bBaseItem[iItemDefID] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "baseitem", 0 );

				KvGetString( ( bUsePrefab ? hPrefabs : hItems ), "item_class", strBuffer, sizeof(strBuffer), "" );
				if( strlen(strBuffer)>0 )
					Format( strItemClass[iItemDefID], ITEMCLASS_LENGTH-1, strBuffer );

				// item levels
				if( iMinLevel[iItemDefID] == -1 )
					iMinLevel[iItemDefID] = KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "min_ilevel", -1 );
				if( iMaxLevel[iItemDefID] == -1 )
					iMaxLevel[iItemDefID] = KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "max_ilevel", -1 );

				// item quality
				KvGetString( ( bUsePrefab ? hPrefabs : hItems ), "item_quality", strBuffer, sizeof(strBuffer), "" );
				if( strlen(strBuffer)>0 )
					Format( strQuality[iItemDefID], ITEMQUALITY_LENGTH-1, strBuffer );

				if( strlen( strQuality[iItemDefID] ) > 0 )
				{
					if( strcmp( strQuality[iItemDefID], "normal", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Normal;
					else if( strcmp( strQuality[iItemDefID], "rarity1", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Genuine;
					else if( strcmp( strQuality[iItemDefID], "rarity2", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Rarity2;
					else if( strcmp( strQuality[iItemDefID], "vintage", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Vintage;
					else if( strcmp( strQuality[iItemDefID], "rarity3", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Rarity3;
					else if( strcmp( strQuality[iItemDefID], "rarity4", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Unusual;
					else if( strcmp( strQuality[iItemDefID], "unique", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Unique;
					else if( strcmp( strQuality[iItemDefID], "community", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Community;
					else if( strcmp( strQuality[iItemDefID], "developer", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Developer;
					else if( strcmp( strQuality[iItemDefID], "customized", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Customized;
					else if( strcmp( strQuality[iItemDefID], "selfmade", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Selfmade;
					else if( strcmp( strQuality[iItemDefID], "strange", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Strange;
					else if( strcmp( strQuality[iItemDefID], "completed", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Completed;
					else if( strcmp( strQuality[iItemDefID], "haunted", nope ) == 0 )
						iQuality[iItemDefID] = TF2ItemQuality_Haunted;
				}

				// item slot
				KvGetString( ( bUsePrefab ? hPrefabs : hItems ), "item_slot", strBuffer, sizeof(strBuffer), "" );
				if( strlen(strBuffer)>0 )
					Format( strItemSlot[iItemDefID], ITEMSLOT_LENGTH-1, strBuffer );

				if( strlen(strItemClass[iItemDefID])>0 && strcmp( strItemClass[iItemDefID], "tf_weapon_revolver", nope ) == 0 )
					Format( strItemSlot[iItemDefID], ITEMSLOT_LENGTH-1, "primary" );

				if( strlen( strItemSlot[iItemDefID] ) > 0 )
				{
					if( strcmp( strItemSlot[iItemDefID], "primary", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_Primary;
					else if( strcmp( strItemSlot[iItemDefID], "secondary", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_Secondary;
					else if( strcmp( strItemSlot[iItemDefID], "melee", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_Melee;
					else if( strcmp( strItemSlot[iItemDefID], "pda", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_PDA1;
					else if( strcmp( strItemSlot[iItemDefID], "pda2", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_PDA2;
					else if( strcmp( strItemSlot[iItemDefID], "building", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_Building;
					else if( strcmp( strItemSlot[iItemDefID], "head", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_Hat;
					else if( strcmp( strItemSlot[iItemDefID], "misc", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_Misc;
					else if( strcmp( strItemSlot[iItemDefID], "action", nope ) == 0 )
						iItemSlot[iItemDefID] = TF2ItemSlot_Action;
				}

				// equip region
				KvGetString( ( bUsePrefab ? hPrefabs : hItems ), "equip_region", strBuffer, sizeof(strBuffer), "" );
				if( strlen(strBuffer)>0 )
				{
					if( hItemEquipRegions[iItemDefID] == INVALID_HANDLE )
						hItemEquipRegions[iItemDefID] = CreateArray(4);
					PushArrayString( hItemEquipRegions[iItemDefID], strBuffer );
				}

				// equip regions
				if( KvJumpToKey( ( bUsePrefab ? hPrefabs : hItems ), "equip_regions", nope ) )
				{
					if( KvGotoFirstSubKey( ( bUsePrefab ? hPrefabs : hItems ), nope ) )
					{
						do
						{
							KvGetSectionName( ( bUsePrefab ? hPrefabs : hItems ), strBuffer, sizeof(strBuffer) );
							if( hItemEquipRegions[iItemDefID] == INVALID_HANDLE )
								hItemEquipRegions[iItemDefID] = CreateArray(4);
							PushArrayString( hItemEquipRegions[iItemDefID], strBuffer );
						}
						while( KvGotoNextKey( ( bUsePrefab ? hPrefabs : hItems ), nope ) );
						KvGoBack( bUsePrefab ? hPrefabs : hItems );
					}
					KvGoBack( bUsePrefab ? hPrefabs : hItems );
				}

				// tool type
				if( KvJumpToKey( ( bUsePrefab ? hPrefabs : hItems ), "tool", nope ) )
				{
					KvGetString( ( bUsePrefab ? hPrefabs : hItems ), "type", strBuffer, sizeof(strBuffer), "" );
					if( strlen(strBuffer)>0 )
						Format( strItemTool[iItemDefID], ITEMTOOL_LENGTH-1, strBuffer );
					KvGoBack( bUsePrefab ? hPrefabs : hItems );
				}

				// used by classes
				if( KvJumpToKey( ( bUsePrefab ? hPrefabs : hItems ), "used_by_classes", nope ) )
				{
					bUsedByClass[iItemDefID][TFClass_Scout] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "scout", 0 );
					bUsedByClass[iItemDefID][TFClass_Sniper] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "sniper", 0 );
					bUsedByClass[iItemDefID][TFClass_Soldier] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "soldier", 0 );
					bUsedByClass[iItemDefID][TFClass_DemoMan] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "demoman", 0 );
					bUsedByClass[iItemDefID][TFClass_Medic] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "medic", 0 );
					bUsedByClass[iItemDefID][TFClass_Heavy] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "heavy", 0 );
					bUsedByClass[iItemDefID][TFClass_Pyro] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "pyro", 0 );
					bUsedByClass[iItemDefID][TFClass_Spy] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "spy", 0 );
					bUsedByClass[iItemDefID][TFClass_Engineer] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "engineer", 0 );
					KvGoBack( bUsePrefab ? hPrefabs : hItems );
				}

				// shotgun classname fix
				if( strlen(strItemClass[iItemDefID])>0 && strcmp( strItemClass[iItemDefID], "tf_weapon_shotgun", nope ) == 0 )
				{
					if( bUsedByClass[iItemDefID][TFClass_Soldier] )
						Format( strItemClass[iItemDefID], ITEMCLASS_LENGTH-1, "%s_soldier", strItemClass[iItemDefID] );
					else if( bUsedByClass[iItemDefID][TFClass_Heavy] )
						Format( strItemClass[iItemDefID], ITEMCLASS_LENGTH-1, "%s_hwg", strItemClass[iItemDefID] );
					else if( bUsedByClass[iItemDefID][TFClass_Pyro] )
						Format( strItemClass[iItemDefID], ITEMCLASS_LENGTH-1, "%s_pyro", strItemClass[iItemDefID] );
					else if( bUsedByClass[iItemDefID][TFClass_Engineer] )
						Format( strItemClass[iItemDefID], ITEMCLASS_LENGTH-1, "%s_primary", strItemClass[iItemDefID] );
				}

				// capabilities
				if( KvJumpToKey( ( bUsePrefab ? hPrefabs : hItems ), "capabilities", nope ) )
				{
					bPaintable[iItemDefID] = !!KvGetNum( ( bUsePrefab ? hPrefabs : hItems ), "paintable", _:bPaintable[iItemDefID] );
					KvGoBack( bUsePrefab ? hPrefabs : hItems );
				}

				// holiday restriction
				KvGetString( ( bUsePrefab ? hPrefabs : hItems ), "holiday_restriction", strBuffer, sizeof(strBuffer), "" );
				if( strlen(strBuffer)>0 )
				{
					bBirthdayItem[iItemDefID] = ( strcmp( strBuffer, "birthday", nope ) == 0 );
					bHalloweenOrFullMoonItem[iItemDefID] = ( strcmp( strBuffer, "halloween_or_fullmoon", nope ) == 0 );
					bChristmasItem[iItemDefID] = ( strcmp( strBuffer, "christmas", nope ) == 0 );
				}

				// attributes
				if( KvJumpToKey( ( bUsePrefab ? hPrefabs : hItems ), "attributes", nope ) )
				{
					iAttributes[iItemDefID] = 0;
					if( KvGotoFirstSubKey( bUsePrefab ? hPrefabs : hItems ) )
					{
						do
						{
							KvGetSectionName( ( bUsePrefab ? hPrefabs : hItems ), strAttrNames[iItemDefID][iAttributes[iItemDefID]], ATTRIBNAME_LENGTH-1 );
							iAttrIDs[iItemDefID][iAttributes[iItemDefID]] = GetAttribIDByName( strAttrNames[iItemDefID][iAttributes[iItemDefID]] );
							flAttrValues[iItemDefID][iAttributes[iItemDefID]] = KvGetFloat( ( bUsePrefab ? hPrefabs : hItems ), "value", 0.0 );
							iAttributes[iItemDefID]++;
						}
						while( KvGotoNextKey( bUsePrefab ? hPrefabs : hItems ) );
						KvGoBack( bUsePrefab ? hPrefabs : hItems );
					}
					KvGoBack( bUsePrefab ? hPrefabs : hItems );
				}

				if( !bUsePrefab )
					break;
				bUsePrefab = nope;
			}

			bItemExists[iItemDefID] = yep;
			nItems++;
		}
		while( KvGotoNextKey( hItems ) );


	if( hItems != INVALID_HANDLE )
		CloseHandle( hItems );
	if( hPrefabs != INVALID_HANDLE )
		CloseHandle( hPrefabs );


	LogMessage( "Item schema precached. Got %d items", nItems );
}

ReloadConfigs()
{
	decl String:strBuffer[128];

	new Handle:hItemConfig = CreateKeyValues("items_config");

	decl String:strFilePath[PLATFORM_MAX_PATH] = "data/tf2itemsinfo.txt";
	BuildPath( Path_SM, strFilePath, sizeof(strFilePath), strFilePath );
	if( !FileExists( strFilePath ) )
	{
		LogError( "Missing config file, making empty at %s", strFilePath );
		KeyValuesToFile( hItemConfig, strFilePath );
		CloseHandle(hItemConfig);
		return;
	}

	FileToKeyValues( hItemConfig, strFilePath );
	KvRewind( hItemConfig );

	if( KvGotoFirstSubKey( hItemConfig ) )
	{
		new iItemDefID;
		do
		{
			KvGetSectionName( hItemConfig, strBuffer, sizeof(strBuffer) );
			if( !IsCharNumeric( strBuffer[0] ) )
				continue;
			iItemDefID = StringToInt( strBuffer );
			if( iItemDefID >= TF2_MAX_ITEMS )
				continue;

			bItemCanBeUnusual[iItemDefID] = !!KvGetNum( hItemConfig, "unusual", 0 );
			bItemCanBeVintage[iItemDefID] = !!KvGetNum( hItemConfig, "vintage", 0 );
			bItemCanBeStrange[iItemDefID] = !!KvGetNum( hItemConfig, "strange", 0 );
			bHauntedItem[iItemDefID] = !!KvGetNum( hItemConfig, "haunted", 0 );
			bHalloweenItem[iItemDefID] = !!KvGetNum( hItemConfig, "halloween", 0 );
			bPromotionalItem[iItemDefID] = !!KvGetNum( hItemConfig, "promotional", 0 );
			bItemCanBeGenuine[iItemDefID] = !!KvGetNum( hItemConfig, "genuine", 0 );
			bUpgradeableStockItem[iItemDefID] = !!KvGetNum( hItemConfig, "upgradeable", 0 );
			bFestiveStockItem[iItemDefID] = !!KvGetNum( hItemConfig, "festive", 0 );
			bMedievalItem[iItemDefID] = !!KvGetNum( hItemConfig, "medieval", 0 );
		}
		while( KvGotoNextKey( hItemConfig ) );
	}

	CloseHandle( hItemConfig );

	LogMessage( "Item config loaded." );
}

_:GetAttribIDByName( const String:strAttribName[] )
{
	if( strlen(strAttribName) == 0 )
		return -1;

	for( new i = 0; i < MAX_ATTRIBS; i++ )
		if( strlen(strAttribData[i]) > 0 && strcmp( strAttribData[i], strAttribName, nope ) == 0 )
			return i;

	return -1;
}

bool:GetAttribNameByID( iAttribID, String:strAttribName[], iAttribNameLength )
{
	if( iAttribID >= 0 && iAttribID < MAX_ATTRIBS && strlen(strAttribData[iAttribID]) > 0 )
	{
		Format( strAttribName, iAttribNameLength, "%s", strAttribData[iAttribID] );
		return yep;
	}

	return nope;
}

/////////////
/* Natives */

public Native_IsValidItemID( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return IsValidItemID( iItemDefID );
}

public Native_GetItemClass( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	SetNativeString( 2, ( IsValidItemID( iItemDefID ) ? strItemClass[iItemDefID] : "" ), GetNativeCell(3) );
}

public Native_GetItemSlot( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? iItemSlot[iItemDefID] : -1 );
}
public Native_GetItemSlotName( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	SetNativeString( 2, ( IsValidItemID( iItemDefID ) ? strItemSlot[iItemDefID] : "" ), GetNativeCell(3) );
}

public Native_IsItemUsedByClass( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	new iClass = GetNativeCell(2);
	return ( IsValidItemID( iItemDefID ) && iClass >= 0 && iClass < _:TFClassType ? bUsedByClass[iItemDefID][iClass] : nope );
}

public Native_IsItemPaintable( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bPaintable[iItemDefID] : nope );
}

public Native_IsBaseItem( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bBaseItem[iItemDefID] : nope );
}

public Native_GetItemMinLevel( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? iMinLevel[iItemDefID] : -1 );
}
public Native_GetItemMaxLevel( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? iMaxLevel[iItemDefID] : -1 );
}

public Native_GetItemQualityName( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	SetNativeString( 2, ( IsValidItemID( iItemDefID ) ? strQuality[iItemDefID] : "" ), GetNativeCell(3) );
	return IsValidItemID( iItemDefID );
}
public Native_GetItemQuality( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? iQuality[iItemDefID] : -1 );
}

public Native_GetNumAttributes( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? iAttributes[iItemDefID] : -1 );
}
public Native_GetAttributeName( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	new iAttribNum = GetNativeCell(2);
	SetNativeString( 3, ( IsValidItemID( iItemDefID ) && iAttribNum >= 0 && iAttribNum < MAX_ATTRS_PER_ITEM ? strAttrNames[iItemDefID][iAttribNum] : "" ), GetNativeCell(4) );
	return ( IsValidItemID( iItemDefID ) && iAttribNum >= 0 && iAttribNum < MAX_ATTRS_PER_ITEM );
}
public Native_GetAttributeID( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	new iAttribNum = GetNativeCell(2);
	return ( IsValidItemID( iItemDefID ) && iAttribNum >= 0 && iAttribNum < MAX_ATTRS_PER_ITEM ? iAttrIDs[iItemDefID][iAttribNum] : 0 );
}
public Native_GetAttributeValue( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	new iAttribNum = GetNativeCell(2);
	return _:( IsValidItemID( iItemDefID ) && iAttribNum >= 0 && iAttribNum < MAX_ATTRS_PER_ITEM ? flAttrValues[iItemDefID][iAttribNum] : 0.0 );
}
public Native_GetToolType( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	SetNativeString( 2, ( IsValidItemID( iItemDefID ) ? strItemTool[iItemDefID] : "" ), GetNativeCell(3) );
	return IsValidItemID( iItemDefID );
}
public Native_ItemHolidayRestriction( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	new TFHoliday:holiday = TFHoliday:GetNativeCell(2);
	if( !IsValidItemID( iItemDefID ) )
		return nope;
	switch( holiday )
	{
		case TFHoliday_Birthday:
			return bBirthdayItem[iItemDefID];
		case TFHoliday_Halloween,TFHoliday_FullMoon,TFHoliday_HalloweenOrFullMoon:
			return bHalloweenOrFullMoonItem[iItemDefID];
		case TFHoliday_Christmas:
			return bChristmasItem[iItemDefID];
	}
	return nope;
}
public Native_GetItemEquipRegions( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	if( !IsValidItemID( iItemDefID ) )
		return _:INVALID_HANDLE;
	return _:( hItemEquipRegions[ iItemDefID ] != INVALID_HANDLE ? CloneHandle( hItemEquipRegions[ iItemDefID ], hPlugin ) : INVALID_HANDLE );
}
public Native_GetItemName( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	SetNativeString( 2, ( IsValidItemID( iItemDefID ) ? strItemName[iItemDefID] : "" ), GetNativeCell(3) );
	return IsValidItemID( iItemDefID );
}

public Native_IsConflictRegions( Handle:hPlugin, nParams )
{
	decl String:strERA[16], String:strERB[16];
	GetNativeString( 1, strERA, sizeof(strERA) );
	GetNativeString( 2, strERB, sizeof(strERB) );

	if( strcmp( strERA, strERB, nope ) == 0 )
		return yep;

	decl String:strBuffer[16];
	if( hEquipConflicts != INVALID_HANDLE )
	{
		KvRewind( hEquipConflicts );
		if( KvJumpToKey( hEquipConflicts, strERA, nope ) )
		{
			if( KvGotoFirstSubKey( hEquipConflicts, nope ) )
				do
				{
					KvGetSectionName( hEquipConflicts, strBuffer, sizeof(strBuffer) );
					if( strcmp( strBuffer, strERB, nope ) == 0 )
						return yep;
				}
				while( KvGotoNextKey( hEquipConflicts, nope ) );
		}
		else if( KvJumpToKey( hEquipConflicts, strERB, nope ) )
		{
			if( KvGotoFirstSubKey( hEquipConflicts, nope ) )
				do
				{
					KvGetSectionName( hEquipConflicts, strBuffer, sizeof(strBuffer) );
					if( strcmp( strBuffer, strERA, nope ) == 0 )
						return yep;
				}
				while( KvGotoNextKey( hEquipConflicts, nope ) );
		}
	}

	return nope;
}

public Native_GetAttributeIDByName( Handle:hPlugin, nParams )
{
	decl String:strAttribName[ATTRIBNAME_LENGTH];
	GetNativeString( 1, strAttribName, ATTRIBNAME_LENGTH-1 );
	return GetAttribIDByName( strAttribName );
}
public Native_GetAttributeNameByID( Handle:hPlugin, nParams )
{
	new iAttribID = GetNativeCell(1);
	new _:iAttribNameLength = GetNativeCell(3);
	decl String:strAttribName[iAttribNameLength+1];
	new bool:bResult = GetAttribNameByID( iAttribID, strAttribName, iAttribNameLength );
	SetNativeString( 2, strAttribName, iAttribNameLength );
	return bResult;
}

public Native_FindItemsIDsByCond( Handle:hPlugin, nParams )
{
	new Handle:hResults = CreateArray();

	new iSlot = GetNativeCell(2);

	decl String:strClass[ITEMCLASS_LENGTH], String:strSlot[ITEMSLOT_LENGTH], String:strTool[ITEMTOOL_LENGTH];
	GetNativeString( 1, strClass, ITEMCLASS_LENGTH-1);
	GetNativeString( 3, strSlot, ITEMSLOT_LENGTH-1);
	GetNativeString( 6, strTool, ITEMTOOL_LENGTH-1);

	new iClasses = _:TFClassType, bool:bClasses[iClasses], bool:bCanUse;
	new bool:bFilterClass = !!GetNativeCell(4);
	GetNativeArray( 5, bClasses, iClasses );

	new iClass;
	for( new iItem = 0; iItem < TF2_MAX_ITEMS; iItem++ )
		if( bItemExists[iItem] )
		{
			if( iSlot != -1 )
				if( iItemSlot[iItem] != iSlot )
					continue;

			if( strlen(strSlot) > 0 )
				if( !( strlen( strItemSlot[iItem] ) > 0 && strcmp( strSlot, strItemSlot[iItem], nope ) == 0 ) )
					continue;

			if( strlen(strClass) > 0 )
				if( !( strlen( strItemClass[iItem] ) > 0 && strcmp( strClass, strItemClass[iItem], nope ) == 0 ) )
					continue;

			if( strlen(strTool) > 0 )
				if( !( strlen( strItemTool[iItem] ) > 0 && strcmp( strTool, strItemTool[iItem], nope ) == 0 ) )
					continue;

			if( bFilterClass )
			{
				bCanUse = nope;
				for( iClass = 0; iClass < _:TFClassType; iClass++ )
					if( bUsedByClass[iItem][iClass] == yep && bClasses[iClass] == bUsedByClass[iItem][iClass] )
						bCanUse = yep;
				if( !bCanUse )
					continue;
			}

			PushArrayCell( hResults, iItem );
		}
	new Handle:hReturn = CloneHandle(hResults, hPlugin);
	CloseHandle(hResults);
	return _:hReturn;
}

public Native_ListAttachableEffects( Handle:hPlugin, nParams )
{
	new bool:bAllEffects = !!GetNativeCell(1);
	new Handle:hResults = CreateArray();
	for( new i = 0; i < nEffects; i++ )
		if( bAllEffects || iEffects[i] > 5 && iEffects[i] != 20 )
			PushArrayCell( hResults, iEffects[i] );
	new Handle:hReturn = CloneHandle(hResults, hPlugin);
	CloseHandle(hResults);
	return _:hReturn;
}

public Native_ItemCanBeUnusual( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bItemCanBeUnusual[iItemDefID] : nope );
}
public Native_ItemCanBeVintage( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bItemCanBeVintage[iItemDefID] : nope );
}
public Native_IsHauntedItem( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bHauntedItem[iItemDefID] : nope );
}
public Native_IsHalloweenItem( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bHauntedItem[iItemDefID] || bHalloweenItem[iItemDefID] : nope );
}
public Native_IsPromotionalItem( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	new bool:bGenuineOnly = !!GetNativeCell(2);
	return ( IsValidItemID( iItemDefID ) ? bPromotionalItem[iItemDefID] && ( bGenuineOnly ? bItemCanBeGenuine[iItemDefID] : yep ) : nope );
}
public Native_IsUpgradeableStockWeapon( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bUpgradeableStockItem[iItemDefID] : nope );
}
public Native_IsFestiveStockWeapon( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bFestiveStockItem[iItemDefID] : nope );
}
public Native_IsMedievalWeapon( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	if( IsValidItemID( iItemDefID ) )
	{
		if( iItemSlot[iItemDefID] >= TF2ItemSlot_Hat && iItemSlot[iItemDefID] <= TF2ItemSlot_Action )
			return yep;
		if( iItemSlot[iItemDefID] == TF2ItemSlot_Melee )
			return yep;
		if( bMedievalItem[iItemDefID] )
			return yep;
	}
	return nope;
}
public Native_ItemCanBeStrange( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	return ( IsValidItemID( iItemDefID ) ? bItemCanBeStrange[iItemDefID] : nope );
}

public Native_GetNamedItem( Handle:hPlugin, nParams )
{
#if defined _tf2items_included
	new iItemDefID = GetNativeCell(1);
	if( !IsValidItemID( iItemDefID ) )
		return _:INVALID_HANDLE;

	new iCustomQuality = GetNativeCell(2);
	if( iCustomQuality <= 0 || iCustomQuality >= TF2ItemQuality_Maximum )
		iCustomQuality = TF2ItemQuality_Unique;
	if( bBaseItem[iItemDefID] )
		iCustomQuality = TF2ItemQuality_Normal;

	new iLevel = GetNativeCell(3);
	if( iLevel <= 0 || iLevel >= 128 )
		iLevel = 1;

	new Handle:hItem = TF2Items_CreateItem( OVERRIDE_ALL|FORCE_GENERATION );
	if( strcmp( strItemClass[iItemDefID], "saxxy", nope ) == 0 )
		TF2Items_SetFlags( hItem, OVERRIDE_ALL );
	TF2Items_SetClassname( hItem, strItemClass[iItemDefID] );
	TF2Items_SetItemIndex( hItem, iItemDefID );
	TF2Items_SetQuality( hItem, iCustomQuality );
	TF2Items_SetLevel( hItem, iLevel );
	TF2Items_SetNumAttributes( hItem, iAttributes[iItemDefID] );
	if( iAttributes[iItemDefID] )
		for( new a; a < iAttributes[iItemDefID]; a++ )
			TF2Items_SetAttribute( hItem, a, iAttrIDs[iItemDefID][a], flAttrValues[iItemDefID][a] );
	new Handle:hReturn = CloneHandle(hItem, hPlugin);
	CloseHandle(hItem);
	return _:hReturn;
#else
	return _:INVALID_HANDLE;
#endif
}
public Native_GiveNamedItem( Handle:hPlugin, nParams )
{
#if defined _tf2items_included
	new iClient = GetNativeCell(1);
	if( !IsValidClient( iClient ) || !IsPlayerAlive( iClient ) )
		return -1;

	new iItemDefID = GetNativeCell(2);
	if( !IsValidItemID( iItemDefID ) )
		return -1;

	new iCustomQuality = GetNativeCell(3);
	if( iCustomQuality <= 0 || iCustomQuality >= TF2ItemQuality_Maximum )
		iCustomQuality = TF2ItemQuality_Unique;
	if( bBaseItem[iItemDefID] )
		iCustomQuality = TF2ItemQuality_Normal;

	new iLevel = GetNativeCell(4);
	if( iLevel <= 0 || iLevel >= 128 )
		iLevel = 1;

	new Handle:hItem = TF2Items_CreateItem( OVERRIDE_ALL|FORCE_GENERATION );
	if( strcmp( strItemClass[iItemDefID], "saxxy", nope ) == 0 )
		TF2Items_SetFlags( hItem, OVERRIDE_ALL );
	TF2Items_SetClassname( hItem, strItemClass[iItemDefID] );
	TF2Items_SetItemIndex( hItem, iItemDefID );
	TF2Items_SetQuality( hItem, iCustomQuality );
	TF2Items_SetLevel( hItem, iLevel );
	TF2Items_SetNumAttributes( hItem, iAttributes[iItemDefID] );
	if( iAttributes[iItemDefID] )
		for( new a; a < iAttributes[iItemDefID]; a++ )
			TF2Items_SetAttribute( hItem, a, iAttrIDs[iItemDefID][a], flAttrValues[iItemDefID][a] );

	new iEntity = TF2Items_GiveNamedItem( iClient, hItem );
	CloseHandle( hItem );
	if( IsValidEntity( iEntity ) )
	{
		if( StrContains( strItemClass[iItemDefID], "tf_wearable", nope ) == 0 && hSDKEquipWearable )
		{
			if( IsValidEntity( GetPlayerWeaponSlot( iClient, iItemSlot[iItemDefID] ) ) )
				TF2_RemoveWeaponSlot( iClient, iItemSlot[iItemDefID] );
			SDKCall( hSDKEquipWearable, iClient, iEntity );
			return iEntity;
		}
		else if( StrContains( strItemClass[iItemDefID], "tf_weapon", nope ) == 0 )
		{
			if( IsValidEntity( GetPlayerWeaponSlot( iClient, iItemSlot[iItemDefID] ) ) )
				TF2_RemoveWeaponSlot( iClient, iItemSlot[iItemDefID] );
			EquipPlayerWeapon( iClient, iEntity );
			return iEntity;
		}
	}
#endif

	return -1;
}

////////////
/* Stocks */

stock bool:IsValidItemID( iItemDefID = -1 )
{
	return ( iItemDefID >= 0 && iItemDefID < TF2_MAX_ITEMS && bItemExists[iItemDefID] );
}
stock bool:IsValidClient( _:iClient )
{
	if( iClient <= 0 ) return nope;
	if( iClient > MaxClients ) return nope;
	if( !IsClientConnected(iClient) ) return nope;
	return IsClientInGame(iClient);
}