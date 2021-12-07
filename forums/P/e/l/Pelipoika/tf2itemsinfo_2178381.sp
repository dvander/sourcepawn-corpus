////////////////////////////////////////
/*                                    */
/*   Plugin:    TF2 Items Info        */
/*   Version:   1.8.17.7              */
/*                                    */
/*   Created:   11 Apr 2012           */
/*   Released:  15 Apr 2012           */
/*   Modified:  21 Nov 2013           */
/*                                    */
/*   Credits:                         */
/*    Asher "asherkin" Baker          */
/*    FlaminSarge                     */
/*    Leonid "Leonardo" Kuchinov      */
/*    Mecha The Slag                  */
/*                                    */
/*   Description:                     */
/*    Obtaining TF2 items info from   */
/*    items_game.txt                  */
/*                                    */
/*   Plugin structure:                */
/*   - Including Libraries            */
/*   - Defined Variables              */
/*   - Enumerics                      */
/*   - Global Variables               */
/*   - Plugin Information             */
/*   - SourceMod Events               */
/*   - Command handlers               */
/*   - CVar handlers                  */
/*   - Private functions              */
/*   - Native functions               */
/*   - SQL handlers                   */
/*   - Stock functions                */
/*   -- ItemData_* functions          */
/*   -- AttribData_* functions        */
/*   -- Validating functions          */
/*   -- FlaminSarge's KvCopyDataToKv  */
/*                                    */
////////////////////////////////////////

/////////////////////////
/* Including Libraries */
/////////////////////////

#include <sourcemod>
#include <tf2_stocks>
#include <tf2itemsinfo>
#include <tf2items>

///////////////////////
/* Defined Variables */
///////////////////////

#pragma semicolon 1

#define PLUGIN_VERSION		"1.8.17.7-20131121"

#define SEARCH_MINLENGTH	2
#define SEARCH_ITEMSPERPAGE	20

#define ERROR_NONE		0		// PrintToServer only
#define ERROR_LOG		(1<<0)	// use LogToFile
#define ERROR_BREAKF	(1<<1)	// use ThrowError
#define ERROR_BREAKN	(1<<2)	// use ThrowNativeError
#define ERROR_BREAKP	(1<<3)	// use SetFailState
#define ERROR_NOPRINT	(1<<4)	// don't use PrintToServer

///////////////
/* Enumerics */
///////////////

enum ItemDataType
{
	ItemData_DefinitionID,
	ItemData_Property,
	ItemData_Name,
	ItemData_MLName,
	ItemData_MLSlotName,
	ItemData_MLDescription,
	ItemData_ClassName,
	ItemData_Slot,
	ItemData_ListedSlot,
	ItemData_Tool,
	ItemData_MinLevel,
	ItemData_MaxLevel,
	ItemData_Quality,
	ItemData_UsedBy,
	ItemData_Attributes,
	ItemData_EquipRegions,
	ItemData_LogName,
	ItemData_LogIcon,
	ItemData_KeyValues
};
enum AttribDataType
{
	AttribData_Index,
	AttribData_Property,
	AttribData_Name,
	AttribData_AttribName,
	AttribData_AttribClass,
	AttribData_AttribType,
	AttribData_MinValue,
	AttribData_MaxValue,
	AttribData_DescrString,
	AttribData_DescrFormat,
	AttribData_Group,
	AttribData_KeyValues
};

//////////////////////
/* Global Variables */
//////////////////////

new Handle:sm_tf2ii_version = INVALID_HANDLE;
new Handle:sm_tf2ii_logs = INVALID_HANDLE;
new Handle:sm_tf2ii_fix01 = INVALID_HANDLE;

new bool:bUseLogs = true;
new nFix01State = 0;

new Handle:hForward_ItemSchemaUpdated = INVALID_HANDLE;
new Handle:hForward_OnSearchCommand = INVALID_HANDLE;
new Handle:hForward_OnFindItems = INVALID_HANDLE;

new iHighestItemDefID = 0;
new iHighestAttribID = 0;

new Handle:g_hItemData = INVALID_HANDLE;
new Handle:g_hItemDataKeys = INVALID_HANDLE;
new Handle:g_hAttribData = INVALID_HANDLE;
new Handle:g_hAttribDataKeys = INVALID_HANDLE;
new Handle:g_hQNames = INVALID_HANDLE;
new Handle:g_hEffects = INVALID_HANDLE;
new Handle:hEquipConflicts = INVALID_HANDLE;

////////////////////////
/* Plugin Information */
////////////////////////

public Plugin:myinfo = {
	name = "[DEV] TF2ItemsInfo",
	author = "Leonardo",
	description = "items_game.txt parser",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
};

//////////////////////
/* SourceMod Events */
//////////////////////

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	CreateNative( "TF2II_IsItemSchemaPrecached", Native_IsItemSchemaPrecached );

	CreateNative( "TF2II_IsValidItemID", Native_IsValidItemID );
	CreateNative( "TF2II_GetItemClass", Native_GetItemClass );
	CreateNative( "TF2II_GetItemSlot", Native_GetItemSlot );
	CreateNative( "TF2II_GetItemSlotName", Native_GetItemSlotName );
	CreateNative( "TF2II_GetListedItemSlot", Native_GetListedItemSlot );
	CreateNative( "TF2II_GetListedItemSlotName", Native_GetListedItemSlotName );
	CreateNative( "TF2II_GetItemQuality", Native_GetItemQuality );
	CreateNative( "TF2II_GetItemQualityName", Native_GetItemQualityName );
	CreateNative( "TF2II_IsItemUsedByClass", Native_IsItemUsedByClass );
	CreateNative( "TF2II_GetItemMinLevel", Native_GetItemMinLevel );
	CreateNative( "TF2II_GetItemMaxLevel", Native_GetItemMaxLevel );
	CreateNative( "TF2II_GetItemNumAttributes", Native_GetNumAttributes );
	CreateNative( "TF2II_GetItemAttributeName", Native_GetAttributeName );
	CreateNative( "TF2II_GetItemAttributeID", Native_GetAttributeID );
	CreateNative( "TF2II_GetItemAttributeValue", Native_GetAttributeValue );
	CreateNative( "TF2II_GetItemAttributes", Native_GetItemAttributes );
	CreateNative( "TF2II_GetToolType", Native_GetToolType );
	CreateNative( "TF2II_ItemHolidayRestriction", Native_ItemHolidayRestriction );
	CreateNative( "TF2II_GetItemEquipRegions", Native_GetItemEquipRegions );
	CreateNative( "TF2II_IsConflictRegions", Native_IsConflictRegions );
	CreateNative( "TF2II_GetItemName", Native_GetItemName );
	CreateNative( "TF2II_ItemHasProperty", Native_ItemHasProperty );

	CreateNative( "TF2II_IsValidAttribID", Native_IsValidAttribID );
	CreateNative( "TF2II_GetAttribName", Native_GetAttribName );
	CreateNative( "TF2II_GetAttribClass", Native_GetAttribClass );
	CreateNative( "TF2II_GetAttribDispName", Native_GetAttribDispName );
	CreateNative( "TF2II_GetAttribMinValue", Native_GetAttribMinValue );
	CreateNative( "TF2II_GetAttribMaxValue", Native_GetAttribMaxValue );
	CreateNative( "TF2II_GetAttribGroup", Native_GetAttribGroup );
	CreateNative( "TF2II_GetAttribDescrString", Native_GetAttribDescrString );
	CreateNative( "TF2II_GetAttribDescrFormat", Native_GetAttribDescrFormat );
	CreateNative( "TF2II_HiddenAttrib", Native_HiddenAttrib );
	CreateNative( "TF2II_GetAttribEffectType", Native_GetAttribEffectType );
	CreateNative( "TF2II_AttribStoredAsInteger", Native_AttribStoredAsInteger );
	CreateNative( "TF2II_AttribHasProperty", Native_AttribHasProperty );

	CreateNative( "TF2II_GetItemKeyValues", Native_GetItemKeyValues );
	CreateNative( "TF2II_GetItemKey", Native_GetItemKey );
	CreateNative( "TF2II_GetItemKeyFloat", Native_GetItemKeyFloat );
	CreateNative( "TF2II_GetItemKeyString", Native_GetItemKeyString );
	CreateNative( "TF2II_GetAttribKeyValues", Native_GetAttribKeyValues );
	CreateNative( "TF2II_GetAttribKey", Native_GetAttribKey );
	CreateNative( "TF2II_GetAttribKeyFloat", Native_GetAttribKeyFloat );
	CreateNative( "TF2II_GetAttribKeyString", Native_GetAttribKeyString );

	CreateNative( "TF2II_GetQualityByName", Native_GetQualityByName );
	CreateNative( "TF2II_GetQualityName", Native_GetQualityName );
	CreateNative( "TF2II_GetAttributeIDByName", Native_GetAttributeIDByName );
	CreateNative( "TF2II_GetAttributeNameByID", Native_GetAttributeNameByID );

	CreateNative( "TF2II_FindItems", Native_FindItems );
	CreateNative( "TF2II_ListAttachableEffects", Native_ListEffects );
	CreateNative( "TF2II_ListEffects", Native_ListEffects );

	// Obsolete
	CreateNative( "TF2II_IsPromotionalItem", Native_DeprecatedFunction );
	CreateNative( "TF2II_IsUpgradeableStockWeapon", Native_DeprecatedFunction );
	CreateNative( "TF2II_IsFestiveStockWeapon", Native_DeprecatedFunction );
	CreateNative( "TF2II_FindItemsIDsByCond", Native_FindItemsIDsByCond );

	hForward_ItemSchemaUpdated = CreateGlobalForward( "TF2II_OnItemSchemaUpdated", ET_Ignore );
	hForward_OnSearchCommand = CreateGlobalForward( "TF2II_OnSearchCommand", ET_Ignore, Param_Cell, Param_String, Param_CellByRef, Param_Cell );
	hForward_OnFindItems = CreateGlobalForward( "TF2II_OnFindItems", ET_Ignore, Param_String, Param_String, Param_Cell, Param_String, Param_CellByRef );

	RegPluginLibrary( "tf2itemsinfo" );

	return APLRes_Success;
}

public OnPluginStart()
{
	sm_tf2ii_version = CreateConVar( "sm_tf2ii_version", PLUGIN_VERSION, "TF2 Items Info Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	SetConVarString( sm_tf2ii_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2ii_version, OnConVarChanged_PluginVersion );

	HookConVarChange( sm_tf2ii_logs = CreateConVar( "sm_tf2ii_logs", bUseLogs ? "1" : "0", "Enable/disable logs", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( sm_tf2ii_fix01 = CreateConVar( "sm_tf2ii_fix01", "0", "Fix items with 'string' attributes:\n0 - disabled, 1 - skip 'string' attributes, 2 - skip items with 'string' attributes.", FCVAR_PLUGIN, true, 0.0, true, 2.0 ), OnConVarChanged );

	decl String:strGameDir[8];
	GetGameFolderName( strGameDir, sizeof(strGameDir) );
	if( !StrEqual( strGameDir, "tf", false ) && !StrEqual( strGameDir, "tf_beta", false ) )
		Error( ERROR_BREAKP|ERROR_LOG, _, "THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!" );

	RegAdminCmd( "sm_tf2ii_killdata", Command_Test_KillData, ADMFLAG_ROOT );

	RegConsoleCmd( "sm_si", Command_FindItems, "[TF2II] Find items by name." );
	RegConsoleCmd( "sm_fi", Command_FindItems, "[TF2II] Find items by name." );
	RegConsoleCmd( "sm_sic", Command_FindItemsByClass, "[TF2II] Find items by item class name." );
	RegConsoleCmd( "sm_fic", Command_FindItemsByClass, "[TF2II] Find items by item class name." );
	RegConsoleCmd( "sm_ii", Command_PrintInfo, "[TF2II] Print info about item (by id)." );
	RegConsoleCmd( "sm_pi", Command_PrintInfo, "[TF2II] Print info about item (by id)." );
	RegConsoleCmd( "sm_sa", Command_FindAttributes, "[TF2II] Find attributes by id or name." );
	RegConsoleCmd( "sm_fa", Command_FindAttributes, "[TF2II] Find attributes by id or name." );
	RegConsoleCmd( "sm_sac", Command_FindAttributesByClass, "[TF2II] Find attributes by attribute class name." );
	RegConsoleCmd( "sm_fac", Command_FindAttributesByClass, "[TF2II] Find attributes by attribute class name." );

	PrecacheItemSchema();
	ReloadConfigs();
}

GetConVars()
{
	bUseLogs = GetConVarBool( sm_tf2ii_logs );

	nFix01State = GetConVarInt( sm_tf2ii_fix01 );
}

//////////////////////
/* Command handlers */
//////////////////////
public Action:Command_Test_KillData( iClient, iArgs )
{
#if 0
	ReplyToCommand( iClient, "Killing data:" );
	for( new i = 0; i <= iHighestItemDefID; i++ )
		if( ItemData_Destroy( i ) )
			ReplyToCommand( iClient, "Item %d deleted;", i );
	ReplyToCommand( iClient, "Done." );
#else
	ReplyToCommand( iClient, "Disabled feature." );
#endif
	return Plugin_Handled;
}

public Action:Command_FindItems( iClient, nArgs )
{
	if( iClient < 0 || iClient > MaxClients )
		return Plugin_Continue;

	decl String:strCmdName[16];
	GetCmdArg( 0, strCmdName, sizeof(strCmdName) );
	if( nArgs < 1 )
	{
		ReplyToCommand( iClient, "Usage: %s <name> [pagenum]", strCmdName );
		return Plugin_Handled;
	}

	new iPage = 0;
	if( nArgs >= 2 )
	{
		decl String:strPage[8];
		GetCmdArg( 2, strPage, sizeof(strPage) );
		if( IsCharNumeric(strPage[0]) )
		{
			iPage = StringToInt( strPage );
			if( iPage < 1 )
				iPage = 1;
		}
	}

	decl String:strSearch[64];
	if( iPage )
		GetCmdArg( 1, strSearch, sizeof(strSearch) );
	else
	{
		iPage = 1;
		GetCmdArgString( strSearch, sizeof(strSearch) );
		StripQuotes( strSearch );
	}
	TrimString( strSearch );
	if( strlen( strSearch ) < SEARCH_MINLENGTH && !IsCharNumeric(strSearch[0]) )
	{
		ReplyToCommand( iClient, "Too short name! Minimum: %d chars", SEARCH_MINLENGTH );
		return Plugin_Handled;
	}

	decl String:strBuffer[64];
	new iItemDefID, nCells = GetArraySize( g_hItemData ), Handle:hData, Handle:hResults = CreateArray( 16 );
	for( new iCell = 0; iCell < nCells; iCell++ )
	{
		iItemDefID = -1;
		hData = INVALID_HANDLE;
		
		hData = Handle:GetArrayCell( g_hItemData, iCell );
		if( hData != INVALID_HANDLE )
			iItemDefID = GetArrayCell( hData, _:ItemData_DefinitionID );
		
		if( 0 <= iItemDefID <= iHighestItemDefID && ItemData_GetString( iItemDefID, ItemData_Name, strBuffer, sizeof(strBuffer) ) && StrContains( strBuffer, strSearch, false ) > -1 )
		{
			PushArrayCell( hResults, iItemDefID );
			PushArrayString( hResults, strBuffer );
		}
	}


	Call_StartForward( hForward_OnSearchCommand );
	Call_PushCell( iClient );
	Call_PushString( strSearch );
	Call_PushCellRef( hResults );
	Call_PushCell( 0 );
	Call_Finish();


	new iResults = RoundFloat( float( GetArraySize( hResults ) ) / 2.0 );
	
	decl String:strMessage[250];
	
	Format( strMessage, sizeof(strMessage), "Found %d items (page:%d/%d):", iResults, ( iResults ? iPage : 0 ), RoundToCeil( float( iResults ) / float(SEARCH_ITEMSPERPAGE) ) );
	ReplyToCommand( iClient, strMessage );
	
	
	iPage--;
	new iMin = iPage * SEARCH_ITEMSPERPAGE;
	iMin = ( iMin < 0 ? 0 : iMin );
	new iMax = iPage * SEARCH_ITEMSPERPAGE + SEARCH_ITEMSPERPAGE;
	iMax = ( iMax >= iResults ? iResults : iMax );
	
	if( iResults )
		for( new i = iMin; i < iMax; i++ )
		{
			GetArrayString( hResults, 2 * i + 1, strBuffer, sizeof(strBuffer) );
			Format( strMessage, sizeof(strMessage), "- %d: %s", GetArrayCell( hResults, 2 * i ), strBuffer );
			ReplyToCommand( iClient, strMessage );
		}

	CloseHandle( hResults );

	return Plugin_Handled;
}
public Action:Command_FindItemsByClass( iClient, nArgs )
{
	if( iClient < 0 || iClient > MaxClients )
		return Plugin_Continue;

	decl String:strCmdName[16];
	GetCmdArg( 0, strCmdName, sizeof(strCmdName) );
	if( nArgs < 1 )
	{
		ReplyToCommand( iClient, "Usage: %s <classname> [pagenum]", strCmdName );
		return Plugin_Handled;
	}

	new iPage = 0;
	if( nArgs >= 2 )
	{
		decl String:strPage[8];
		GetCmdArg( 2, strPage, sizeof(strPage) );
		if( IsCharNumeric(strPage[0]) )
		{
			iPage = StringToInt( strPage );
			if( iPage < 1 )
				iPage = 1;
		}
	}

	decl String:strSearch[64];
	if( iPage )
		GetCmdArg( 1, strSearch, sizeof(strSearch) );
	else
	{
		iPage = 1;
		GetCmdArgString( strSearch, sizeof(strSearch) );
		StripQuotes( strSearch );
	}
	TrimString( strSearch );
	if( strlen( strSearch ) < SEARCH_MINLENGTH && !IsCharNumeric(strSearch[0]) )
	{
		ReplyToCommand( iClient, "Too short name! Minimum: %d chars", SEARCH_MINLENGTH );
		return Plugin_Handled;
	}

	decl String:strBuffer[TF2II_ITEMCLASS_LENGTH];
	new iItemDefID, nCells = GetArraySize( g_hItemData ), Handle:hData, Handle:hResults = CreateArray( 16 );
	for( new iCell = 0; iCell < nCells; iCell++ )
	{
		iItemDefID = -1;
		hData = INVALID_HANDLE;
		
		hData = Handle:GetArrayCell( g_hItemData, iCell );
		if( hData != INVALID_HANDLE )
			iItemDefID = GetArrayCell( hData, _:ItemData_DefinitionID );
		
		if( 0 <= iItemDefID <= iHighestItemDefID && ItemData_GetString( iItemDefID, ItemData_ClassName, strBuffer, sizeof(strBuffer) ) && StrContains( strBuffer, strSearch, false ) > -1 )
		{
			ItemData_GetString( iItemDefID, ItemData_Name, strBuffer, sizeof(strBuffer) );
			PushArrayCell( hResults, iItemDefID );
			PushArrayString( hResults, strBuffer );
		}
	}


	Call_StartForward( hForward_OnSearchCommand );
	Call_PushCell( iClient );
	Call_PushString( strSearch );
	Call_PushCellRef( hResults );
	Call_PushCell( 1 );
	Call_Finish();


	new iResults = RoundFloat( float( GetArraySize( hResults ) ) / 2.0 );
	
	decl String:strMessage[250];
	
	Format( strMessage, sizeof(strMessage), "Found %d items (page:%d/%d):", iResults, ( iResults ? iPage : 0 ), RoundToCeil( float( iResults ) / float(SEARCH_ITEMSPERPAGE) ) );
	ReplyToCommand( iClient, strMessage );
	
	
	iPage--;
	new iMin = iPage * SEARCH_ITEMSPERPAGE;
	iMin = ( iMin < 0 ? 0 : iMin );
	new iMax = iPage * SEARCH_ITEMSPERPAGE + SEARCH_ITEMSPERPAGE;
	iMax = ( iMax >= iResults ? iResults : iMax );

	if( iResults )
		for( new i = iMin; i < iMax; i++ )
		{
			GetArrayString( hResults, 2 * i + 1, strBuffer, sizeof(strBuffer) );
			Format( strMessage, sizeof(strMessage), "- %d: %s", GetArrayCell( hResults, 2 * i ), strBuffer );
			ReplyToCommand( iClient, strMessage );
		}

	CloseHandle( hResults );

	return Plugin_Handled;
}
public Action:Command_PrintInfo( iClient, nArgs )
{
	if( iClient < 0 || iClient > MaxClients )
		return Plugin_Continue;

	decl String:strCmdName[16];
	GetCmdArg( 0, strCmdName, sizeof(strCmdName) );
	if( nArgs < 1 )
	{
		if( StrEqual( "sm_pi", strCmdName, false ) )
			ReplyToCommand( iClient, "The Pi number: 3.1415926535897932384626433832795028841971..." );
		else
			ReplyToCommand( iClient, "Usage: %s <id>  [pagenum]", strCmdName );
		return Plugin_Handled;
	}

	decl String:strItemID[32];
	GetCmdArg( 1, strItemID, sizeof(strItemID) );
	new iItemDefID = StringToInt(strItemID);
	if( !ItemHasProp( iItemDefID, TF2II_PROP_VALIDITEM ) )
	{
		ReplyToCommand( iClient, "Item #%d is invalid!", iItemDefID );
		return Plugin_Handled;
	}

	decl String:strMessage[250], String:strBuffer[128];

	ReplyToCommand( iClient, "==================================================" );

	Format( strMessage, sizeof(strMessage), "Item Definition Index: %d", iItemDefID );
	ReplyToCommand( iClient, strMessage );

	ItemData_GetString( iItemDefID, ItemData_Name, strBuffer, sizeof(strBuffer) );
	Format( strMessage, sizeof(strMessage), "Item Name: %s", strBuffer );
	ReplyToCommand( iClient, strMessage );

	ItemData_GetString( iItemDefID, ItemData_ClassName, strBuffer, sizeof(strBuffer) );
	if( strlen( strBuffer ) )
	{
		Format( strMessage, sizeof(strMessage), "Item Class: %s", strBuffer );
		ReplyToCommand( iClient, strMessage );
	}

	ItemData_GetString( iItemDefID, ItemData_Slot, strBuffer, sizeof(strBuffer) );
	if( strlen( strBuffer ) )
	{
		Format( strMessage, sizeof(strMessage), "Item Slot: %s", strBuffer );
		ReplyToCommand( iClient, strMessage );
	}

	ItemData_GetString( iItemDefID, ItemData_ListedSlot, strBuffer, sizeof(strBuffer) );
	if( strlen( strBuffer ) )
	{
		Format( strMessage, sizeof(strMessage), "Listed Item Slot: %s", strBuffer );
		ReplyToCommand( iClient, strMessage );
	}

	Format( strMessage, sizeof(strMessage), "Level bounds: [%d...%d]", ItemData_GetCell( iItemDefID, ItemData_MinLevel ), ItemData_GetCell( iItemDefID, ItemData_MaxLevel ) );
	ReplyToCommand( iClient, strMessage );

	ItemData_GetString( iItemDefID, ItemData_Quality, strBuffer, sizeof(strBuffer) );
	if( strlen(strBuffer) )
	{
		Format( strMessage, sizeof(strMessage), "Quality: %s (%d)", strBuffer, _:GetQualityByName(strBuffer) );
		ReplyToCommand( iClient, strMessage );
	}

	ItemData_GetString( iItemDefID, ItemData_Tool, strBuffer, sizeof(strBuffer) );
	if( strlen(strBuffer) )
	{
		Format( strMessage, sizeof(strMessage), "Tool type: %s", strBuffer );
		ReplyToCommand( iClient, strMessage );
	}

	new bool:bBDAYRestriction = ItemHasProp( iItemDefID, TF2II_PROP_BDAY_STRICT );
	new bool:bHOFMRestriction = ItemHasProp( iItemDefID, TF2II_PROP_HOFM_STRICT );
	new bool:bXMASRestriction = ItemHasProp( iItemDefID, TF2II_PROP_XMAS_STRICT );
	if( bBDAYRestriction || bHOFMRestriction || bXMASRestriction )
		ReplyToCommand( iClient, "Holiday restriction:" );
	if( bBDAYRestriction )
		ReplyToCommand( iClient, "- birthday" );
	if( bHOFMRestriction )
		ReplyToCommand( iClient, "- halloween_or_fullmoon" );
	if( bXMASRestriction )
		ReplyToCommand( iClient, "- christmas" );

	new iUsedByClass = ItemData_GetCell( iItemDefID, ItemData_UsedBy );
	ReplyToCommand( iClient, "Used by classes:" );
	if( iUsedByClass <= TF2II_CLASS_NONE )
		ReplyToCommand( iClient, "- None (%d)", iUsedByClass );
	else if( iUsedByClass == TF2II_CLASS_ALL )
		ReplyToCommand( iClient, "- Any (%d)", iUsedByClass );
	else
	{
		if( iUsedByClass & TF2II_CLASS_SCOUT )
			ReplyToCommand( iClient, "- Scout (%d)", iUsedByClass & TF2II_CLASS_SCOUT );
		if( iUsedByClass & TF2II_CLASS_SNIPER )
			ReplyToCommand( iClient, "- Sniper (%d)", iUsedByClass & TF2II_CLASS_SNIPER );
		if( iUsedByClass & TF2II_CLASS_SOLDIER )
			ReplyToCommand( iClient, "- Soldier (%d)", iUsedByClass & TF2II_CLASS_SOLDIER );
		if( iUsedByClass & TF2II_CLASS_DEMOMAN )
			ReplyToCommand( iClient, "- Demoman (%d)", iUsedByClass & TF2II_CLASS_DEMOMAN );
		if( iUsedByClass & TF2II_CLASS_MEDIC )
			ReplyToCommand( iClient, "- Medic (%d)", iUsedByClass & TF2II_CLASS_MEDIC );
		if( iUsedByClass & TF2II_CLASS_HEAVY )
			ReplyToCommand( iClient, "- Heavy (%d)", iUsedByClass & TF2II_CLASS_HEAVY );
		if( iUsedByClass & TF2II_CLASS_PYRO )
			ReplyToCommand( iClient, "- Pyro (%d)", iUsedByClass & TF2II_CLASS_PYRO );
		if( iUsedByClass & TF2II_CLASS_SPY )
			ReplyToCommand( iClient, "- Spy (%d)", iUsedByClass & TF2II_CLASS_SPY );
		if( iUsedByClass & TF2II_CLASS_ENGINEER )
			ReplyToCommand( iClient, "- Engineer (%d)", iUsedByClass & TF2II_CLASS_ENGINEER );
	}

	new iAttribID, Handle:hAttributes = Handle:ItemData_GetCell( iItemDefID, ItemData_Attributes );
	if( hAttributes != INVALID_HANDLE )
	{
		ReplyToCommand( iClient, "Attributes:" );
		for( new a = 0; a < GetArraySize(hAttributes); a += 2 )
		{
			iAttribID = GetArrayCell( hAttributes, a );
			AttribData_GetString( iAttribID, AttribData_Name, strBuffer, sizeof(strBuffer) );
			Format( strMessage, sizeof(strMessage), "- %s (%d) - %f", strBuffer, iAttribID, Float:GetArrayCell( hAttributes, a+1 ) );
			ReplyToCommand( iClient, strMessage );
		}
	}
	
	if( nArgs >= 2 )
	{
		GetCmdArg( 2, strBuffer, sizeof(strBuffer) );
		if( StringToInt( strBuffer ) > 0 )
		{
			ReplyToCommand( iClient, "=================== EXTRA INFO ===================" );
			
			ItemData_GetString( iItemDefID, ItemData_MLName, strBuffer, sizeof(strBuffer) );
			if( strlen( strBuffer ) )
			{
				Format( strMessage, sizeof(strMessage), "Item ML Name: %s", strBuffer );
				ReplyToCommand( iClient, strMessage );
			}
			
			ReplyToCommand( iClient, "Proper name: %s", ItemHasProp( iItemDefID, TF2II_PROP_PROPER_NAME ) ? "true" : "false" );
			
			ItemData_GetString( iItemDefID, ItemData_LogName, strBuffer, sizeof(strBuffer) );
			if( strlen( strBuffer ) )
			{
				Format( strMessage, sizeof(strMessage), "Kill Log Name: %s", strBuffer );
				ReplyToCommand( iClient, strMessage );
			}
			
			ItemData_GetString( iItemDefID, ItemData_LogIcon, strBuffer, sizeof(strBuffer) );
			if( strlen( strBuffer ) )
			{
				Format( strMessage, sizeof(strMessage), "Kill Log Icon: %s", strBuffer );
				ReplyToCommand( iClient, strMessage );
			}
			
			new Handle:hEquipRegions = Handle:ItemData_GetCell( iItemDefID, ItemData_EquipRegions );
			if( hEquipRegions != INVALID_HANDLE )
			{
				ReplyToCommand( iClient, "Equipment regions:" );
				for( new r = 0; r < GetArraySize(hEquipRegions); r++ )
				{
					GetArrayString( hEquipRegions, r, strBuffer, sizeof(strBuffer) );
					Format( strMessage, sizeof(strMessage), "- %s", strBuffer );
					ReplyToCommand( iClient, strMessage );
				}
			}
			
			new Handle:hKV = Handle:ItemData_GetCell( iItemDefID, ItemData_KeyValues );
			if( hKV != INVALID_HANDLE )
			{
				if( KvJumpToKey( hKV, "model_player_per_class", false ) )
				{
					ReplyToCommand( iClient, "Models per class:" );
					
					KvGetString( hKV, "scout", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Scout: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "soldier", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Soldier: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "sniper", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Sniper: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "demoman", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Demoman: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "Medic", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Medic: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "heavy", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Heavy: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "pyro", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Pyro: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "spy", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Spy: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGetString( hKV, "engineer", strBuffer, sizeof(strBuffer) );
					if( strlen(strBuffer) )
					{
						Format( strMessage, sizeof(strMessage), "- Engineer: %s", strBuffer );
						ReplyToCommand( iClient, strMessage );
					}
					
					KvGoBack( hKV );
				}
				else
				{
					KvGetString( hKV, "model_world", strBuffer, sizeof(strBuffer) );
					Format( strMessage, sizeof(strMessage), "World model: %s", strBuffer );
					ReplyToCommand( iClient, strMessage );
				}
				
				KvGetString( hKV, "model_player", strBuffer, sizeof(strBuffer) );
				Format( strMessage, sizeof(strMessage), "View model: %s", strBuffer );
				ReplyToCommand( iClient, strMessage );
				
				new nStyles = 1;
				if( KvJumpToKey( hKV, "visuals", false ) && KvJumpToKey( hKV, "styles", false ) && KvGotoFirstSubKey( hKV ) )
				{
					while( KvGotoNextKey( hKV ) )
						nStyles++;
					KvGoBack( hKV );
					KvGoBack( hKV );
					KvGoBack( hKV );
				}
				Format( strMessage, sizeof(strMessage), "Number of styles: %d", nStyles );
				ReplyToCommand( iClient, strMessage );
			}
		}
	}

	ReplyToCommand( iClient, "==================================================" );

	return Plugin_Handled;
}
public Action:Command_FindAttributes( iClient, nArgs )
{
	if( iClient < 0 || iClient > MaxClients )
		return Plugin_Continue;

	decl String:strCmdName[16];
	GetCmdArg( 0, strCmdName, sizeof(strCmdName) );
	if( nArgs < 1 )
	{
		ReplyToCommand( iClient, "Usage: %s <id|name> [pagenum]", strCmdName );
		return Plugin_Handled;
	}

	new iPage = 0;
	if( nArgs >= 2 )
	{
		decl String:strPage[8];
		GetCmdArg( 2, strPage, sizeof(strPage) );
		if( IsCharNumeric(strPage[0]) )
		{
			iPage = StringToInt( strPage );
			if( iPage < 1 )
				iPage = 1;
		}
	}

	decl String:strSearch[64];
	if( iPage )
		GetCmdArg( 1, strSearch, sizeof(strSearch) );
	else
	{
		iPage = 1;
		GetCmdArgString( strSearch, sizeof(strSearch) );
		StripQuotes( strSearch );
	}
	TrimString( strSearch );
	if( strlen( strSearch ) < SEARCH_MINLENGTH && !IsCharNumeric(strSearch[0]) )
	{
		ReplyToCommand( iClient, "Too short name! Minimum: %d chars", SEARCH_MINLENGTH );
		return Plugin_Handled;
	}

	if( IsCharNumeric(strSearch[0]) )
	{
		new iAttribute = StringToInt(strSearch);
		if( !( 0 < iAttribute <= iHighestAttribID ) )
			ReplyToCommand( iClient, "Attribute #%d is out of bounds [1...%d]", iAttribute, iHighestAttribID );

		decl String:strBuffer[128];
		if( !IsValidAttribID( iAttribute ) )
		{
			ReplyToCommand( iClient, "Attribute #%d doesn't exists", iAttribute );
			return Plugin_Handled;
		}

		ReplyToCommand( iClient, "==================================================" );

		ReplyToCommand( iClient, "Attribute Index: %d", iAttribute );

		AttribData_GetString( iAttribute, AttribData_Name, strBuffer, sizeof(strBuffer) );
		ReplyToCommand( iClient, "Working Name: %s", strBuffer );

		AttribData_GetString( iAttribute, AttribData_AttribName, strBuffer, sizeof(strBuffer) );
		if( strlen( strBuffer ) )
			ReplyToCommand( iClient, "Display Name: %s", strBuffer );

		AttribData_GetString( iAttribute, AttribData_DescrString, strBuffer, sizeof(strBuffer) );
		if( strlen( strBuffer ) )
			ReplyToCommand( iClient, "Description String: %s", strBuffer );

		AttribData_GetString( iAttribute, AttribData_DescrFormat, strBuffer, sizeof(strBuffer) );
		if( strlen( strBuffer ) )
			ReplyToCommand( iClient, "Description Format: %s", strBuffer );

		AttribData_GetString( iAttribute, AttribData_AttribClass, strBuffer, sizeof(strBuffer) );
		if( strlen( strBuffer ) )
			ReplyToCommand( iClient, "Class: %s", strBuffer );

		AttribData_GetString( iAttribute, AttribData_AttribType, strBuffer, sizeof(strBuffer) );
		if( strlen( strBuffer ) )
			ReplyToCommand( iClient, "Type: %s", strBuffer );

		AttribData_GetString( iAttribute, AttribData_Group, strBuffer, sizeof(strBuffer) );
		if( strlen( strBuffer ) )
			ReplyToCommand( iClient, "Group: %s", strBuffer );


		ReplyToCommand( iClient, "Bounds of value: [%0.2f...%0.2f]", Float:AttribData_GetCell( iAttribute, AttribData_MinValue ), Float:AttribData_GetCell( iAttribute, AttribData_MaxValue ) );

		if( AttribHasProp( iAttribute, TF2II_PROP_EFFECT_POSITIVE ) )
			ReplyToCommand( iClient, "Effect Type: positive" );
		else if( AttribHasProp( iAttribute, TF2II_PROP_EFFECT_NEGATIVE ) )
			ReplyToCommand( iClient, "Effect Type: negative" );
		else
			ReplyToCommand( iClient, "Effect Type: neutral" );

		ReplyToCommand( iClient, "Hidden: %s", ( AttribHasProp( iAttribute, TF2II_PROP_HIDDEN ) ? "true" : "false" ) );

		ReplyToCommand( iClient, "As Integer: %s", ( AttribHasProp( iAttribute, TF2II_PROP_STORED_AS_INTEGER ) ? "true" : "false" ) );

		ReplyToCommand( iClient, "==================================================" );

		return Plugin_Handled;
	}

	new Handle:hResults = CreateArray( RoundToFloor( TF2II_ATTRIBNAME_LENGTH / 4.0 ) );
	decl String:strAttribName[2][TF2II_ATTRIBNAME_LENGTH], String:strPrintName[TF2II_ATTRIBNAME_LENGTH*2+3];
	new iAttribID, nCells = GetArraySize( g_hAttribData ), Handle:hData;
	for( new iCell = 0; iCell < nCells; iCell++ )
	{
		iAttribID = 0;
		hData = INVALID_HANDLE;
		
		hData = Handle:GetArrayCell( g_hAttribData, iCell );
		if( hData != INVALID_HANDLE )
			iAttribID = GetArrayCell( hData, _:AttribData_Index );
		
		if( 0 < iAttribID <= iHighestAttribID )
		{
			AttribData_GetString( iAttribID, AttribData_Name, strAttribName[0], sizeof(strAttribName[]) );
			AttribData_GetString( iAttribID, AttribData_AttribName, strAttribName[1], sizeof(strAttribName[]) );
			if( strlen(strAttribName[0]) > 0 && StrContains( strAttribName[0], strSearch, false ) >= 0 || strlen(strAttribName[1]) > 0 && StrContains( strAttribName[1], strSearch, false ) >= 0 )
			{
				PushArrayCell( hResults, iAttribID );
				if( strAttribName[1][0] != '\0' && !StrEqual( strAttribName[1], strAttribName[0], false ) )
				{
					Format( strPrintName, sizeof(strPrintName), "%s (%s)", strAttribName[1], strAttribName[0] );
					PushArrayString( hResults, strPrintName );
				}
				else
					PushArrayString( hResults, strAttribName[0] );
			}
		}
	}


	new iResults = RoundFloat( float( GetArraySize( hResults ) ) / 2.0 );
	
	decl String:strMessage[250];
	
	Format( strMessage, sizeof(strMessage), "Found %d attributes (page:%d/%d):", iResults, ( iResults ? iPage : 0 ), RoundToCeil( float( iResults ) / float(SEARCH_ITEMSPERPAGE) ) );
	ReplyToCommand( iClient, strMessage );
	
	
	iPage--;
	new iMin = iPage * SEARCH_ITEMSPERPAGE;
	iMin = ( iMin < 0 ? 0 : iMin );
	new iMax = iPage * SEARCH_ITEMSPERPAGE + SEARCH_ITEMSPERPAGE;
	iMax = ( iMax >= iResults ? iResults : iMax );

	if( iResults )
		for( new i = iMin; i < iMax; i++ )
		{
			GetArrayString( hResults, 2 * i + 1, strPrintName, sizeof(strPrintName) );
			Format( strMessage, sizeof(strMessage), "- %d: %s", GetArrayCell( hResults, 2 * i ), strPrintName );
			ReplyToCommand( iClient, strMessage );
		}

	CloseHandle( hResults );

	return Plugin_Handled;
}
public Action:Command_FindAttributesByClass( iClient, nArgs )
{
	if( iClient < 0 || iClient > MaxClients )
		return Plugin_Continue;

	decl String:strCmdName[16];
	GetCmdArg( 0, strCmdName, sizeof(strCmdName) );
	if( nArgs < 1 )
	{
		ReplyToCommand( iClient, "Usage: %s <name> [pagenum]", strCmdName );
		return Plugin_Handled;
	}

	new iPage = 0;
	if( nArgs >= 2 )
	{
		decl String:strPage[8];
		GetCmdArg( 2, strPage, sizeof(strPage) );
		if( IsCharNumeric(strPage[0]) )
		{
			iPage = StringToInt( strPage );
			if( iPage < 1 )
				iPage = 1;
		}
	}

	decl String:strSearch[64];
	if( iPage )
		GetCmdArg( 1, strSearch, sizeof(strSearch) );
	else
	{
		iPage = 1;
		GetCmdArgString( strSearch, sizeof(strSearch) );
		StripQuotes( strSearch );
	}
	TrimString( strSearch );
	if( strlen( strSearch ) < SEARCH_MINLENGTH && !IsCharNumeric(strSearch[0]) )
	{
		ReplyToCommand( iClient, "Too short name! Minimum: %d chars", SEARCH_MINLENGTH );
		return Plugin_Handled;
	}

	new Handle:hResults = CreateArray( RoundToFloor( TF2II_ATTRIBNAME_LENGTH / 4.0 ) );
	decl String:strAttribName[2][TF2II_ATTRIBNAME_LENGTH], String:strPrintName[TF2II_ATTRIBNAME_LENGTH*2+3], String:strAttribClass[TF2II_ATTRIBCLASS_LENGTH];
	new iAttribID, nCells = GetArraySize( g_hAttribData ), Handle:hData;
	for( new iCell = 0; iCell < nCells; iCell++ )
	{
		iAttribID = 0;
		hData = INVALID_HANDLE;
		
		hData = Handle:GetArrayCell( g_hAttribData, iCell );
		if( hData != INVALID_HANDLE )
			iAttribID = GetArrayCell( hData, _:AttribData_Index );
		
		if( 0 < iAttribID <= iHighestAttribID )
		{
			AttribData_GetString( iAttribID, AttribData_AttribClass, strAttribClass, sizeof(strAttribClass) );
			if( StrContains( strAttribClass, strSearch, false ) >= 0 )
			{
				PushArrayCell( hResults, iAttribID );
				AttribData_GetString( iAttribID, AttribData_Name, strAttribName[0], sizeof(strAttribName[]) );
				AttribData_GetString( iAttribID, AttribData_AttribName, strAttribName[1], sizeof(strAttribName[]) );
				if( strAttribName[1][0] != '\0' && !StrEqual( strAttribName[1], strAttribName[0], false ) )
				{
					Format( strPrintName, sizeof(strPrintName), "%s (%s)", strAttribName[1], strAttribName[0] );
					PushArrayString( hResults, strPrintName );
				}
				else
					PushArrayString( hResults, strAttribName[0] );
			}
		}
	}


	new iResults = RoundFloat( float( GetArraySize( hResults ) ) / 2.0 );
	
	decl String:strMessage[250];
	
	Format( strMessage, sizeof(strMessage), "Found %d attirubtes (page:%d/%d):", iResults, ( iResults ? iPage : 0 ), RoundToCeil( float( iResults ) / float(SEARCH_ITEMSPERPAGE) ) );
	ReplyToCommand( iClient, strMessage );
	
	
	iPage--;
	new iMin = iPage * SEARCH_ITEMSPERPAGE;
	iMin = ( iMin < 0 ? 0 : iMin );
	new iMax = iPage * SEARCH_ITEMSPERPAGE + SEARCH_ITEMSPERPAGE;
	iMax = ( iMax >= iResults ? iResults : iMax );

	if( iResults )
		for( new i = iMin; i < iMax; i++ )
		{
			GetArrayString( hResults, 2 * i + 1, strPrintName, sizeof(strPrintName) );
			Format( strMessage, sizeof(strMessage), "- %d: %s", GetArrayCell( hResults, 2 * i ), strPrintName );
			ReplyToCommand( iClient, strMessage );
		}

	CloseHandle( hResults );

	return Plugin_Handled;
}

///////////////////
/* CVar handlers */
///////////////////

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	GetConVars();

///////////////////////
/* Private functions */
///////////////////////

PrecacheItemSchema()
{
	decl String:strBuffer[128], String:strQueryERegions[512], String:strQueryAttribs[512];
	new iIndex, iProperty, iUsedByClass, iLevel;
	new Handle:hDataContainer = INVALID_HANDLE;
	iHighestItemDefID = 0;
	iHighestAttribID = 0;

	if( g_hItemData != INVALID_HANDLE )
	{
		for( new i = 0; i < GetArraySize( g_hItemData ); i++ )
		{
			hDataContainer = Handle:GetArrayCell( g_hItemData, i );
			if( hDataContainer != INVALID_HANDLE )
			{
				if( Handle:GetArrayCell( hDataContainer, _:ItemData_Attributes ) != INVALID_HANDLE )
					CloseHandle( Handle:GetArrayCell( hDataContainer, _:ItemData_Attributes ) );
				if( Handle:GetArrayCell( hDataContainer, _:ItemData_EquipRegions ) != INVALID_HANDLE )
					CloseHandle( Handle:GetArrayCell( hDataContainer, _:ItemData_EquipRegions ) );
				if( Handle:GetArrayCell( hDataContainer, _:ItemData_KeyValues ) != INVALID_HANDLE )
					CloseHandle( Handle:GetArrayCell( hDataContainer, _:ItemData_KeyValues ) );
				CloseHandle( hDataContainer );
			}
			hDataContainer = INVALID_HANDLE;
			SetArrayCell( g_hItemData, i, _:hDataContainer );
		}
		CloseHandle( g_hItemData );
	}
	g_hItemData = CreateArray();

	if( g_hItemDataKeys != INVALID_HANDLE )
		CloseHandle( g_hItemDataKeys );
	g_hItemDataKeys = CreateKeyValues( "ItemData_Keys" );

	if( g_hQNames != INVALID_HANDLE )
		CloseHandle( g_hQNames );
	g_hQNames = CreateTrie();

	if( g_hAttribData != INVALID_HANDLE )
	{
		for( new i = 0; i < GetArraySize( g_hAttribData ); i++ )
		{
			hDataContainer = Handle:GetArrayCell( g_hAttribData, i );
			if( hDataContainer != INVALID_HANDLE )
			{
				if( Handle:GetArrayCell( hDataContainer, _:AttribData_KeyValues ) != INVALID_HANDLE )
					CloseHandle( Handle:GetArrayCell( hDataContainer, _:AttribData_KeyValues ) );
				CloseHandle( hDataContainer );
			}
			hDataContainer = INVALID_HANDLE;
			SetArrayCell( g_hAttribData, i, _:hDataContainer );
		}
		CloseHandle( g_hAttribData );
	}
	g_hAttribData = CreateArray();

	if( g_hAttribDataKeys != INVALID_HANDLE )
		CloseHandle( g_hAttribDataKeys );
	g_hAttribDataKeys = CreateKeyValues( "AttribData_Keys" );

	if( g_hEffects != INVALID_HANDLE )
		CloseHandle( g_hEffects );
	g_hEffects = CreateArray();

	decl String:strFilePath[PLATFORM_MAX_PATH] = "scripts/items/items_game.txt";
	if( !FileExists( strFilePath , true) )
	{
		Error( ERROR_BREAKP|ERROR_LOG, _, "Couldn't found file: %s", strFilePath );
		return;
	}

	new Handle:hItemSchema = CreateKeyValues( "items_game" );
	if( !FileToKeyValues( hItemSchema, strFilePath ) )
		if( !IsDedicatedServer() )
			Error( ERROR_BREAKP|ERROR_LOG, _, "THIS PLUGIN IS FOR DEDICATED SERVERS!" );
		else
			Error( ERROR_BREAKP|ERROR_LOG, _, "Failed to parse file: %s", strFilePath );
	KvRewind( hItemSchema );
	
	
	// Parse 'items_game.txt' KeyValues
	
	if( KvJumpToKey( hItemSchema, "qualities", false ) )
	{
		new Handle:hQualities = CreateKeyValues( "qualities" );
		KvCopySubkeys( hItemSchema, hQualities );
		KvGoBack( hItemSchema );

		KvRewind( hQualities );
		if( KvGotoFirstSubKey( hQualities ) )
		{
			decl String:strIndex[16], String:strQualityName[TF2II_ITEMQUALITY_LENGTH];
			do
			{
				KvGetSectionName( hQualities, strQualityName, sizeof(strQualityName) );
				KvGetString( hQualities, "value", strIndex, sizeof(strIndex) );
				if( IsCharNumeric( strIndex[0] ) )
					SetTrieString( g_hQNames, strIndex, strQualityName );
			}
			while( KvGotoNextKey( hQualities ) );
		}

		CloseHandle( hQualities );
	}

	if( hEquipConflicts != INVALID_HANDLE )
		CloseHandle( hEquipConflicts );
	hEquipConflicts = INVALID_HANDLE;
	if( KvJumpToKey( hItemSchema, "equip_conflicts", false ) )
	{
		hEquipConflicts = CreateKeyValues( "equip_conflicts" );
		KvCopySubkeys( hItemSchema, hEquipConflicts );
		KvGoBack( hItemSchema );
	}

	new Handle:hPrefabs = INVALID_HANDLE;
	if( KvJumpToKey( hItemSchema, "prefabs", false ) )
	{
		hPrefabs = CreateKeyValues( "prefabs" );
		KvCopySubkeys( hItemSchema, hPrefabs );
		KvGoBack( hItemSchema );
	}

	new Handle:hItems = INVALID_HANDLE;
	if( KvJumpToKey( hItemSchema, "items", false ) )
	{
		hItems = CreateKeyValues( "items" );
		KvCopySubkeys( hItemSchema, hItems );
		KvGoBack( hItemSchema );
	}

	if( KvJumpToKey( hItemSchema, "attributes", false ) )
	{
		new Handle:hAttributes, Handle:hSubAttributes;

		hAttributes = CreateKeyValues( "attributes" );
		KvCopySubkeys( hItemSchema, hAttributes );
		KvGoBack( hItemSchema );

		KvRewind( hAttributes );
		if( KvGotoFirstSubKey( hAttributes ) )
			do
			{
				hDataContainer = INVALID_HANDLE;
				
				iProperty = TF2II_PROP_INVALID;

				KvGetSectionName( hAttributes, strBuffer, sizeof(strBuffer) );
				iIndex = StringToInt( strBuffer );
				if( iIndex <= 0 )
					continue;

				hDataContainer = AttribData_Create( iIndex );
				if( hDataContainer == INVALID_HANDLE )
				{
					Error( ERROR_LOG, _, "Attrib #%d: Failed to create data container!", iIndex );
					continue;
				}

				iProperty |= TF2II_PROP_VALIDATTRIB;

				hSubAttributes = CreateKeyValues( "attributes" );
				KvCopySubkeys( hAttributes, hSubAttributes );
				AttribData_SetCell( iIndex, AttribData_KeyValues, _:hSubAttributes );
				hSubAttributes = INVALID_HANDLE; // free

				KvGetString( hAttributes, "name", strBuffer, sizeof(strBuffer), "" );
				AttribData_SetString( iIndex, AttribData_Name, strBuffer );

				KvGetString( hAttributes, "attribute_class", strBuffer, sizeof(strBuffer), "" );
				AttribData_SetString( iIndex, AttribData_AttribClass, strBuffer );
				KvGetString( hAttributes, "attribute_name", strBuffer, sizeof(strBuffer), "" );
				AttribData_SetString( iIndex, AttribData_AttribName, strBuffer );
				KvGetString( hAttributes, "attribute_type", strBuffer, sizeof(strBuffer), "" );
				AttribData_SetString( iIndex, AttribData_AttribType, strBuffer );

				KvGetString( hAttributes, "description_string", strBuffer, sizeof(strBuffer), "" );
				AttribData_SetString( iIndex, AttribData_DescrString, strBuffer );
				KvGetString( hAttributes, "description_format", strBuffer, sizeof(strBuffer), "" );
				AttribData_SetString( iIndex, AttribData_DescrFormat, strBuffer );

				AttribData_SetCell( iIndex, AttribData_MinValue, _:KvGetFloat( hAttributes, "min_value", 1.0 ) );
				AttribData_SetCell( iIndex, AttribData_MaxValue, _:KvGetFloat( hAttributes, "max_value", 1.0 ) );

				KvGetString( hAttributes, "effect_type", strBuffer, sizeof(strBuffer), "" );
				if( StrEqual( strBuffer, "positive", false ) )
					iProperty |= TF2II_PROP_EFFECT_POSITIVE;
				else if( StrEqual( strBuffer, "negative", false ) )
					iProperty |= TF2II_PROP_EFFECT_NEGATIVE;
				else // assume 'neutral' type
					iProperty |= TF2II_PROP_EFFECT_NEUTRAL;

				if( !!KvGetNum( hAttributes, "hidden", 0 ) )
					iProperty |= TF2II_PROP_HIDDEN;
				if( !!KvGetNum( hAttributes, "stored_as_integer", 0 ) )
					iProperty |= TF2II_PROP_STORED_AS_INTEGER;

				//KvGetString( hAttributes, "armory_desc", strBuffer, sizeof(strBuffer), "" );

				AttribData_SetCell( iIndex, AttribData_Property, iProperty );

				if( iIndex > iHighestAttribID )
					iHighestAttribID = iIndex;

				hDataContainer = INVALID_HANDLE;
			}
			while( KvGotoNextKey( hAttributes ) );

		CloseHandle( hAttributes );
	}

	if( KvJumpToKey( hItemSchema, "attribute_controlled_attached_particles", false ) )
	{
		new Handle:hACAP = INVALID_HANDLE;
		decl String:strEBuffer[8];

		hACAP = CreateKeyValues( "attribute_controlled_attached_particles" );
		KvCopySubkeys( hItemSchema, hACAP );
		KvGoBack( hItemSchema );

		KvRewind( hACAP );
		if( KvGotoFirstSubKey( hACAP ) )
			do
			{
				KvGetSectionName( hACAP, strEBuffer, sizeof( strEBuffer ) );
				if( strlen(strEBuffer) > 0 && IsCharNumeric( strEBuffer[0] ) )
					PushArrayCell( g_hEffects, StringToInt( strEBuffer ) );
			}
			while( KvGotoNextKey( hACAP ) );

		CloseHandle( hACAP );
	}

	CloseHandle( hItemSchema );


	new bool:bPrefab, p, nPrefabs, nBranches, bool:bStringAttrib, iAttribID;
	new Handle:hIAttributes = INVALID_HANDLE;
	new Handle:hEquipRegions = INVALID_HANDLE;
	new Handle:hTree = INVALID_HANDLE;
	new Handle:hSubItems = INVALID_HANDLE;
	decl String:strPrefabs[4][32];

	KvRewind( hItems );
	if( KvGotoFirstSubKey( hItems ) )
		do
		{
			bStringAttrib = false;
			
			bPrefab = false;
			hDataContainer = INVALID_HANDLE;

			iProperty = TF2II_PROP_INVALID;
			iUsedByClass = TF2II_CLASS_NONE;


			KvGetSectionName( hItems, strBuffer, sizeof(strBuffer) );
			if( !IsCharNumeric( strBuffer[0] ) )
				continue;
			iIndex = StringToInt( strBuffer );
			if( iIndex < 0 )
				continue;
			
			hDataContainer = ItemData_Create( iIndex );
			if( hDataContainer == INVALID_HANDLE )
			{
				Error( ERROR_LOG, _, "Item #%d: Failed to create data container!", iIndex );
				continue;
			}

			iProperty |= TF2II_PROP_VALIDITEM;

			// get tree of prefabs
			if( hTree != INVALID_HANDLE )
				CloseHandle( hTree );
			hTree = CreateArray( 8 );

			do
			{
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "prefab", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) > 0 && hPrefabs != INVALID_HANDLE )
				{
					nPrefabs = ExplodeString( strBuffer, " ", strPrefabs, sizeof(strPrefabs), sizeof(strPrefabs[]) );
					for( p = 0; p < nPrefabs; p++ )
					{
						TrimString( strPrefabs[p] );
						KvRewind( hPrefabs );
						bPrefab = KvJumpToKey( hPrefabs, strPrefabs[p], false );
						if( bPrefab )
						{
							if( hSubItems == INVALID_HANDLE )
							{
								hSubItems = CreateKeyValues( "items" );
								KvCopySubkeys( hPrefabs, hSubItems );
							}
							else
								KvCopyDataToKv( hPrefabs, hSubItems, true );
							PushArrayString( hTree, strPrefabs[p] );
						}
					}
				}
				else
					bPrefab = false;
			}
			while( bPrefab );
			nBranches = GetArraySize(hTree);
			
			if( hSubItems == INVALID_HANDLE )
			{
				hSubItems = CreateKeyValues( "items" );
				KvCopySubkeys( hItems, hSubItems );
			}
			else
				KvCopyDataToKv( hItems, hSubItems, true );
			ItemData_SetCell( iIndex, ItemData_KeyValues, _:hSubItems );
			hSubItems = INVALID_HANDLE;

			KvGetString( hItems, "name", strBuffer, sizeof(strBuffer), "" );
			ItemData_SetString( iIndex, ItemData_Name, strBuffer );

			// if bPrefab is true, so check prefab AND item section (for overrides),
			// otherwise - only item section
			for( p = 0; p <= nBranches; p++ )
			{
				if( p >= nBranches )
					bPrefab = false;
				else
				{
					bPrefab = true;
					GetArrayString( hTree, nBranches - p - 1, strBuffer, sizeof(strBuffer) );
					KvRewind( hPrefabs );
					KvJumpToKey( hPrefabs, strBuffer, false );
				}
				
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_name", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
					ItemData_SetString( iIndex, ItemData_MLName, strBuffer );
				
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_description", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
					ItemData_SetString( iIndex, ItemData_MLDescription, strBuffer );
				
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_type_name", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
					ItemData_SetString( iIndex, ItemData_MLSlotName, strBuffer );

				// is it a base item?
				if( KvGetNum( ( bPrefab ? hPrefabs : hItems ), "baseitem", 0 ) > 0 )
					iProperty |= TF2II_PROP_BASEITEM;

				// item levels
				iLevel = KvGetNum( ( bPrefab ? hPrefabs : hItems ), "min_ilevel", 0 );
				if( iLevel > 0 )
					ItemData_SetCell( iIndex, ItemData_MinLevel, iLevel );
				iLevel = KvGetNum( ( bPrefab ? hPrefabs : hItems ), "max_ilevel", 0 );
				if( iLevel > 0 )
					ItemData_SetCell( iIndex, ItemData_MaxLevel, iLevel );

				// item quality
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_quality", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
					ItemData_SetString( iIndex, ItemData_Quality, strBuffer );

				// tool type
				if( KvJumpToKey( ( bPrefab ? hPrefabs : hItems ), "tool", false ) )
				{
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "type", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						ItemData_SetString( iIndex, ItemData_Tool, strBuffer );
					KvGoBack( bPrefab ? hPrefabs : hItems );
				}

				// equip region(s)
				strQueryERegions[0] = '\0';
				hEquipRegions = Handle:ItemData_GetCell( iIndex, ItemData_EquipRegions );
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "equip_region", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
				{
					if( hEquipRegions == INVALID_HANDLE )
						hEquipRegions = CreateArray( 4 );
					PushArrayString( hEquipRegions, strBuffer );
					strcopy( strQueryERegions, sizeof( strQueryERegions ), strBuffer );
				}
				if( KvJumpToKey( ( bPrefab ? hPrefabs : hItems ), "equip_regions", false ) )
				{
					if( KvGotoFirstSubKey( ( bPrefab ? hPrefabs : hItems ), false ) )
					{
						if( hEquipRegions == INVALID_HANDLE )
							hEquipRegions = CreateArray( 4 );
						do
						{
							KvGetSectionName( ( bPrefab ? hPrefabs : hItems ), strBuffer, sizeof(strBuffer) );
							PushArrayString( hEquipRegions, strBuffer );
							Format( strQueryERegions, sizeof( strQueryERegions ), "%s%s%s", strQueryERegions, strlen( strQueryERegions ) ? "," : "", strBuffer );
						}
						while( KvGotoNextKey( ( bPrefab ? hPrefabs : hItems ), false ) );
						KvGoBack( bPrefab ? hPrefabs : hItems );
					}
					KvGoBack( bPrefab ? hPrefabs : hItems );
				}
				ItemData_SetCell( iIndex, ItemData_EquipRegions, _:hEquipRegions );
				hEquipRegions = INVALID_HANDLE;

				// used by classes
				if( KvJumpToKey( ( bPrefab ? hPrefabs : hItems ), "used_by_classes", false ) )
				{
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "scout", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_SCOUT;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "sniper", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_SNIPER;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "soldier", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_SOLDIER;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "demoman", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_DEMOMAN;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "medic", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_MEDIC;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "heavy", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_HEAVY;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "pyro", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_PYRO;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "spy", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_SPY;
					KvGetString( ( bPrefab ? hPrefabs : hItems ), "engineer", strBuffer, sizeof(strBuffer), "" );
					if( strlen( strBuffer ) )
						iUsedByClass |= TF2II_CLASS_ENGINEER;
					ItemData_SetCell( iIndex, ItemData_UsedBy, iUsedByClass );
					KvGoBack( bPrefab ? hPrefabs : hItems );
				}

				// item slot
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_slot", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
				{
					ItemData_SetString( iIndex, ItemData_Slot, strBuffer );
					ItemData_SetString( iIndex, ItemData_ListedSlot, strBuffer );
				}

				// classname
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_class", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
				{
					if( strcmp( strBuffer, "tf_weapon_revolver", false ) == 0 )
						ItemData_SetString( iIndex, ItemData_Slot, "primary" );
					ItemData_SetString( iIndex, ItemData_ClassName, strBuffer );
				}

				// capabilities
				if( KvJumpToKey( ( bPrefab ? hPrefabs : hItems ), "capabilities", false ) )
				{
					if( KvGetNum( ( bPrefab ? hPrefabs : hItems ), "paintable", 0 ) )
						iProperty |= TF2II_PROP_PAINTABLE;
					KvGoBack( bPrefab ? hPrefabs : hItems );
				}

				// holiday restriction
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "holiday_restriction", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
				{
					if( StrEqual( strBuffer, "birthday", false ) )
						iProperty |= TF2II_PROP_BDAY_STRICT;
					if( StrEqual( strBuffer, "halloween_or_fullmoon", false ) )
						iProperty |= TF2II_PROP_HOFM_STRICT;
					if( StrEqual( strBuffer, "christmas", false ) )
						iProperty |= TF2II_PROP_XMAS_STRICT;
				}

				// propername
				if( KvGetNum( ( bPrefab ? hPrefabs : hItems ), "propername", 0 ) )
					iProperty |= TF2II_PROP_PROPER_NAME;

				// kill log name/icon
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_logname", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
					ItemData_SetString( iIndex, ItemData_LogName, strBuffer );
				KvGetString( ( bPrefab ? hPrefabs : hItems ), "item_iconname", strBuffer, sizeof(strBuffer), "" );
				if( strlen( strBuffer ) )
					ItemData_SetString( iIndex, ItemData_LogIcon, strBuffer );

				// attributes
				strQueryAttribs[0] = '\0';
				if( KvJumpToKey( ( bPrefab ? hPrefabs : hItems ), "attributes", false ) )
				{
					if( KvGotoFirstSubKey( bPrefab ? hPrefabs : hItems ) )
					{
						hIAttributes = Handle:ItemData_GetCell( iIndex, ItemData_Attributes );
						if( hIAttributes == INVALID_HANDLE )
							hIAttributes = CreateArray();
						do
						{
							KvGetString( ( bPrefab ? hPrefabs : hItems ), "value", strBuffer, sizeof(strBuffer) );
							if( StringToFloat( strBuffer ) == 0.0 && !( ( strBuffer[0] == '-' || strBuffer[0] == '.' ) && IsCharNumeric( strBuffer[1] ) || IsCharNumeric( strBuffer[0] ) ) )
							{
								bStringAttrib = true;
								if( nFix01State == 1 )
									continue;
								else if( nFix01State == 2 )
									break;
							}
							KvGetSectionName( ( bPrefab ? hPrefabs : hItems ), strBuffer, sizeof(strBuffer) );
							iAttribID = GetAttribIDByName( strBuffer );
							PushArrayCell( hIAttributes, iAttribID );
							PushArrayCell( hIAttributes, _:KvGetFloat( ( bPrefab ? hPrefabs : hItems ), "value", 0.0 ) );
							Format( strQueryAttribs, sizeof( strQueryAttribs ), "%s%s%d,%.3f", strQueryAttribs, strlen( strQueryAttribs ) ? ";" : "", iAttribID, KvGetFloat( ( bPrefab ? hPrefabs : hItems ), "value", 0.0 ) );
						}
						while( KvGotoNextKey( bPrefab ? hPrefabs : hItems ) );
						if( !bStringAttrib )
							ItemData_SetCell( iIndex, ItemData_Attributes, _:hIAttributes );
						else
							CloseHandle( hIAttributes );
						hIAttributes = INVALID_HANDLE;
						KvGoBack( bPrefab ? hPrefabs : hItems );
					}
					KvGoBack( bPrefab ? hPrefabs : hItems );
				}
				
				if( nFix01State == 2 && bStringAttrib )
					break;
			}
			
			if( nFix01State == 2 && bStringAttrib )
			{
				ItemData_Destroy( iIndex );
				continue;
			}

			ItemData_SetCell( iIndex, ItemData_Property, iProperty );
			
			if( iIndex > iHighestItemDefID )
				iHighestItemDefID = iIndex;
			
			hDataContainer = INVALID_HANDLE;
		}
		while( KvGotoNextKey( hItems ) );


	if( hTree != INVALID_HANDLE )
		CloseHandle( hTree );
	if( hItems != INVALID_HANDLE )
		CloseHandle( hItems );
	if( hPrefabs != INVALID_HANDLE )
		CloseHandle( hPrefabs );

	Error( ERROR_NONE, _, "Item schema is parsed: %d items, %d attributes, %d effects.", GetArraySize( g_hItemData ), GetArraySize( g_hAttribData ), GetArraySize( g_hEffects ) );

	Call_StartForward( hForward_ItemSchemaUpdated );
	Call_Finish();
}

ReloadConfigs()
{
	decl String:strBuffer[128];

	new Handle:hItemConfig = CreateKeyValues("items_config");

	decl String:strFilePath[PLATFORM_MAX_PATH] = "data/tf2itemsinfo.txt";
	BuildPath( Path_SM, strFilePath, sizeof(strFilePath), strFilePath );
	if( !FileExists( strFilePath ) )
	{
		Error( ERROR_LOG, _, "Missing config file, making empty at %s", strFilePath );
		KeyValuesToFile( hItemConfig, strFilePath );
		CloseHandle( hItemConfig );
		return;
	}

	FileToKeyValues( hItemConfig, strFilePath );
	KvRewind( hItemConfig );

	if( KvGotoFirstSubKey( hItemConfig ) )
	{
		new iItemDefID, iProperty;
		do
		{
			KvGetSectionName( hItemConfig, strBuffer, sizeof(strBuffer) );
			if( !IsCharNumeric( strBuffer[0] ) )
				continue;
			iItemDefID = StringToInt( strBuffer );
			if( !( 0 <= iItemDefID <= iHighestItemDefID ) )
				continue;

			iProperty = ItemData_GetCell( iItemDefID, ItemData_Property );
			if( KvGetNum( hItemConfig, "unusual", 0 ) )
				iProperty |= TF2II_PROP_UNUSUAL;
			if( KvGetNum( hItemConfig, "vintage", 0 ) )
				iProperty |= TF2II_PROP_VINTAGE;
			if( KvGetNum( hItemConfig, "strange", 0 ) )
				iProperty |= TF2II_PROP_STRANGE;
			if( KvGetNum( hItemConfig, "haunted", 0 ) )
				iProperty |= TF2II_PROP_HAUNTED;
			if( KvGetNum( hItemConfig, "halloween", 0 ) )
				iProperty |= TF2II_PROP_HALLOWEEN;
			if( KvGetNum( hItemConfig, "promotional", 0 ) )
				iProperty |= TF2II_PROP_PROMOITEM;
			if( KvGetNum( hItemConfig, "genuine", 0 ) )
				iProperty |= TF2II_PROP_GENUINE;
			if( KvGetNum( hItemConfig, "medieval", 0 ) )
				iProperty |= TF2II_PROP_MEDIEVAL;
			ItemData_SetCell( iItemDefID, ItemData_Property, iProperty );
		}
		while( KvGotoNextKey( hItemConfig ) );
	}

	CloseHandle( hItemConfig );

	Error( ERROR_NONE, _, "Item config loaded." );
}

_:GetAttribIDByName( const String:strSearch[] )
{
	if( strlen(strSearch) == 0 )
		return -1;

	decl String:strAttribName[TF2II_ATTRIBNAME_LENGTH];
	new iAttribID, nCells = GetArraySize( g_hAttribData ), Handle:hData;
	for( new i = 0; i < nCells; i++ )
	{
		iAttribID = -1;
		hData = INVALID_HANDLE;
		
		hData = Handle:GetArrayCell( g_hAttribData, i );
		if( hData != INVALID_HANDLE )
			iAttribID = GetArrayCell( hData, _:AttribData_Index );
		
		if( 0 < iAttribID <= iHighestAttribID )
		{
			AttribData_GetString( iAttribID, AttribData_Name, strAttribName, sizeof(strAttribName) );
			if( strcmp( strAttribName, strSearch, false ) == 0 )
				return iAttribID;
		}
	}

	return -1;
}
TF2ItemQuality:GetQualityByName( const String:strSearch[] )
{
	if( strlen(strSearch) == 0 )
		return TF2ItemQuality:-1;

	decl String:strIndex[16], String:strQualityName[TF2II_ATTRIBNAME_LENGTH];
	for( new i = 0; i < GetTrieSize(g_hQNames); i++ )
	{
		IntToString( i, strIndex, sizeof(strIndex) );
		if( GetTrieString( g_hQNames, strIndex, strQualityName, sizeof(strQualityName) ) )
			if( strcmp( strQualityName, strSearch, false ) == 0 )
				return TF2ItemQuality:i;
	}

	return TF2ItemQuality:-1;
}

//////////////////////
/* Native functions */
//////////////////////

public Native_IsItemSchemaPrecached( Handle:hPlugin, nParams )
{
	return g_hItemData != INVALID_HANDLE;
}

public Native_IsValidItemID( Handle:hPlugin, nParams )
{
	return IsValidItemID( GetNativeCell(1) );
}
public Native_GetItemName( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = !!ItemData_GetString( _:GetNativeCell(1), ItemData_Name, strBuffer, iBufferLength );
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetItemClass( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = !!ItemData_GetString( _:GetNativeCell(1), ItemData_ClassName, strBuffer, iBufferLength );
	new TFClassType:iPlayerClass = nParams >= 4 ? ( TFClassType:GetNativeCell(4) ) : TFClass_Unknown;
	if( StrEqual( strBuffer, "tf_weapon_shotgun", false ) )
		switch( iPlayerClass )
		{
			case TFClass_Soldier:	Format(	strBuffer,	iBufferLength,	"%s_soldier",	strBuffer	);
			case TFClass_Heavy:		Format(	strBuffer,	iBufferLength,	"%s_hwg",		strBuffer	);
			case TFClass_Pyro:		Format(	strBuffer,	iBufferLength,	"%s_pyro",		strBuffer	);
			case TFClass_Engineer:	Format(	strBuffer,	iBufferLength,	"%s_primary",	strBuffer	);
		}
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetItemSlot( Handle:hPlugin, nParams )
{
	decl String:strSlot[TF2II_ITEMSLOT_LENGTH];
	//decl String:strClass[TF2II_ITEMCLASS_LENGTH];
	if( ItemData_GetString( GetNativeCell(1), ItemData_Slot, strSlot, sizeof(strSlot) ) )
	{
		new TFClassType:iPClass = nParams >= 2 ? (TFClassType:GetNativeCell(2)) : TFClass_Unknown;
		//ItemData_GetString( GetNativeCell(1), ItemData_ClassName, strClass, sizeof(strClass) );
		return _:TF2II_GetSlotByName( /*StrEqual( strClass, "tf_weapon_revolver", false ) && iPClass == TFClass_Spy ? "primary" :*/ strSlot, iPClass );
	}
	return -1;
}
public Native_GetItemSlotName( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = !!ItemData_GetString( GetNativeCell(1), ItemData_Slot, strBuffer, iBufferLength );
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetListedItemSlot( Handle:hPlugin, nParams )
{
	decl String:strSlot[TF2II_ITEMSLOT_LENGTH];
	if( ItemData_GetString( GetNativeCell(1), ItemData_ListedSlot, strSlot, sizeof(strSlot) ) )
	{
		new TFClassType:iPClass = nParams >= 2 ? (TFClassType:GetNativeCell(2)) : TFClass_Unknown;
		return _:TF2II_GetSlotByName( strSlot, iPClass );
	}
	return -1;
}
public Native_GetListedItemSlotName( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = !!ItemData_GetString( GetNativeCell(1), ItemData_ListedSlot, strBuffer, iBufferLength );
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetItemQuality( Handle:hPlugin, nParams )
{
	decl String:strQuality[TF2II_ITEMQUALITY_LENGTH];
	if( ItemData_GetString( GetNativeCell(1), ItemData_Quality, strQuality, sizeof(strQuality) ) )
		return _:GetQualityByName( strQuality );
	return -1;
}
public Native_GetItemQualityName( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = !!ItemData_GetString( GetNativeCell(1), ItemData_Quality, strBuffer, iBufferLength );
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetToolType( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = !!ItemData_GetString( GetNativeCell(1), ItemData_Tool, strBuffer, iBufferLength );
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_IsItemUsedByClass( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	if( !IsValidItemID(iItemDefID) )
		return false;

	new iClass = TF2II_CLASS_NONE;
	switch( GetNativeCell(2) )
	{
		case TFClass_Scout:
			iClass = TF2II_CLASS_SCOUT;
		case TFClass_Sniper:
			iClass = TF2II_CLASS_SNIPER;
		case TFClass_Soldier:
			iClass = TF2II_CLASS_SOLDIER;
		case TFClass_DemoMan:
			iClass = TF2II_CLASS_DEMOMAN;
		case TFClass_Medic:
			iClass = TF2II_CLASS_MEDIC;
		case TFClass_Heavy:
			iClass = TF2II_CLASS_HEAVY;
		case TFClass_Pyro:
			iClass = TF2II_CLASS_PYRO;
		case TFClass_Spy:
			iClass = TF2II_CLASS_SPY;
		case TFClass_Engineer:
			iClass = TF2II_CLASS_ENGINEER;
		case TFClass_Unknown:
			iClass = TF2II_CLASS_ALL;
		default:
			return false;
	}
	return (ItemData_GetCell( iItemDefID, ItemData_UsedBy ) & iClass);
}
public Native_GetItemMinLevel( Handle:hPlugin, nParams )
{
	return ItemData_GetCell( GetNativeCell(1), ItemData_MinLevel );
}
public Native_GetItemMaxLevel( Handle:hPlugin, nParams )
{
	return ItemData_GetCell( GetNativeCell(1), ItemData_MaxLevel );
}
public Native_GetNumAttributes( Handle:hPlugin, nParams )
{
	new Handle:hAttributes = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_Attributes );
	if( hAttributes == INVALID_HANDLE )
		return 0;
	return RoundToFloor( float( GetArraySize( hAttributes ) ) / 2.0 );
}
public Native_GetAttributeName( Handle:hPlugin, nParams )
{
	new Handle:hAttributes = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_Attributes );
	if( hAttributes == INVALID_HANDLE )
		return false;

	new a = GetNativeCell(2) * 2;
	if( a >= GetArraySize(hAttributes) )
		return false;

	new iAttributeNameLength = GetNativeCell(4);
	decl String:strAttributeName[iAttributeNameLength+1];
	new bool:bResult = AttribData_GetString( GetArrayCell( hAttributes, a ), AttribData_Name, strAttributeName, iAttributeNameLength ) > 0;
	SetNativeString( 2, strAttributeName, iAttributeNameLength );
	return bResult;
}
public Native_GetAttributeID( Handle:hPlugin, nParams )
{
	new Handle:hAttributes = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_Attributes );
	if( hAttributes == INVALID_HANDLE )
		return 0;
	new a = GetNativeCell(2) * 2;
	return ( a < GetArraySize(hAttributes) ? GetArrayCell( hAttributes, a ) : 0 );
}
public Native_GetAttributeValue( Handle:hPlugin, nParams )
{
	new Handle:hAttributes = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_Attributes );
	if( hAttributes == INVALID_HANDLE )
		return 0;
	new a = GetNativeCell(2) * 2 + 1;
	return ( a < GetArraySize(hAttributes) ? GetArrayCell( hAttributes, a ) : 0 );
}
public Native_GetItemAttributes( Handle:hPlugin, nParams )
{
	new Handle:hAttributes = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_Attributes );
	if( hAttributes == INVALID_HANDLE )
		return _:INVALID_HANDLE;
	new Handle:hCopy = CloneArray( hAttributes );
	new Handle:hOutput = CloneHandle( hCopy, hPlugin );
	CloseHandle( hCopy );
	//new Handle:hOutput = CloneArray( hAttributes );
	return _:hOutput;
}
public Native_ItemHolidayRestriction( Handle:hPlugin, nParams )
{
	new iItemDefID = GetNativeCell(1);
	new TFHoliday:holiday = TFHoliday:GetNativeCell(2);
	switch( holiday )
	{
		case TFHoliday_Birthday:
			return ItemHasProp( iItemDefID, TF2II_PROP_BDAY_STRICT );
		case TFHoliday_Halloween,TFHoliday_FullMoon,TFHoliday_HalloweenOrFullMoon:
			return ItemHasProp( iItemDefID, TF2II_PROP_HOFM_STRICT );
		case TFHoliday_Christmas:
			return ItemHasProp( iItemDefID, TF2II_PROP_XMAS_STRICT );
	}
	return false;
}
public Native_GetItemEquipRegions( Handle:hPlugin, nParams )
{
	new Handle:hEquipRegions = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_EquipRegions );
	if( hEquipRegions == INVALID_HANDLE )
		return _:INVALID_HANDLE;
	hEquipRegions = CloneArray( hEquipRegions );
	new Handle:hOutput = CloneHandle( hEquipRegions, hPlugin );
	CloseHandle( hEquipRegions );
	return _:hOutput;
}
public Native_ItemHasProperty( Handle:hPlugin, nParams )
{
	return ItemHasProp( GetNativeCell(1), GetNativeCell(2) );
}

public Native_GetItemKeyValues( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_KeyValues );
	if( hKeyValues == INVALID_HANDLE )
		return _:INVALID_HANDLE;
	new Handle:hCopy = CreateKeyValues( "item_data" );
	KvCopySubkeys( hKeyValues, hCopy );
	new Handle:hOutput = CloneHandle( hCopy, hPlugin );
	CloseHandle( hCopy );
	return _:hOutput;
}
public Native_GetItemKey( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_KeyValues );

	if( hKeyValues == INVALID_HANDLE )
		return 0;

	decl String:strKey[65];
	GetNativeString( 2, strKey, sizeof(strKey) );

	KvRewind( hKeyValues );
	return KvGetNum( hKeyValues, strKey, 0 );
}
public Native_GetItemKeyFloat( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_KeyValues );

	if( hKeyValues == INVALID_HANDLE )
		return 0;

	decl String:strKey[65];
	GetNativeString( 2, strKey, sizeof(strKey) );

	KvRewind( hKeyValues );
	return _:KvGetFloat( hKeyValues, strKey, 0.0 );
}
public Native_GetItemKeyString( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:ItemData_GetCell( GetNativeCell(1), ItemData_KeyValues );

	if( hKeyValues == INVALID_HANDLE )
		return;

	decl String:strKey[65];
	GetNativeString( 2, strKey, sizeof(strKey) );

	new iBufferLength = GetNativeCell(4);
	decl String:strBuffer[iBufferLength+1];

	KvRewind( hKeyValues );
	KvGetString( hKeyValues, strKey, strBuffer, iBufferLength, "" );
	SetNativeString( 3, strBuffer, iBufferLength );
}

public Native_IsValidAttribID( Handle:hPlugin, nParams )
{
	return IsValidAttribID( GetNativeCell(1) );
}
public Native_GetAttribName( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = AttribData_GetString( GetNativeCell(1), AttribData_Name, strBuffer, iBufferLength ) > 0;
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetAttribClass( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = AttribData_GetString( GetNativeCell(1), AttribData_AttribClass, strBuffer, iBufferLength ) > 0;
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetAttribDispName( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = AttribData_GetString( GetNativeCell(1), AttribData_AttribName, strBuffer, iBufferLength ) > 0;
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetAttribMinValue( Handle:hPlugin, nParams )
{
	return AttribData_GetCell( GetNativeCell(1), AttribData_MinValue );
}
public Native_GetAttribMaxValue( Handle:hPlugin, nParams )
{
	return AttribData_GetCell( GetNativeCell(1), AttribData_MaxValue );
}
public Native_GetAttribGroup( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = AttribData_GetString( GetNativeCell(1), AttribData_Group, strBuffer, iBufferLength ) > 0;
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetAttribDescrString( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = AttribData_GetString( GetNativeCell(1), AttribData_DescrString, strBuffer, iBufferLength ) > 0;
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_GetAttribDescrFormat( Handle:hPlugin, nParams )
{
	new iBufferLength = GetNativeCell(3);
	decl String:strBuffer[iBufferLength+1];
	new bool:bResult = AttribData_GetString( GetNativeCell(1), AttribData_DescrFormat, strBuffer, iBufferLength ) > 0;
	SetNativeString( 2, strBuffer, iBufferLength );
	return bResult;
}
public Native_HiddenAttrib( Handle:hPlugin, nParams )
{
	return AttribHasProp( GetNativeCell(1), TF2II_PROP_HIDDEN );
}
public Native_GetAttribEffectType( Handle:hPlugin, nParams )
{
	new iAttribID = GetNativeCell(1);
	if( AttribHasProp( iAttribID, TF2II_PROP_EFFECT_POSITIVE ) )
		return 1;
	else if( AttribHasProp( iAttribID, TF2II_PROP_EFFECT_NEGATIVE ) )
		return -1;
	return 0;
}
public Native_AttribStoredAsInteger( Handle:hPlugin, nParams )
{
	return AttribHasProp( GetNativeCell(1), TF2II_PROP_STORED_AS_INTEGER );
}
public Native_AttribHasProperty( Handle:hPlugin, nParams )
{
	return AttribHasProp( GetNativeCell(1), GetNativeCell(2) );
}

public Native_GetAttribKeyValues( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:AttribData_GetCell( GetNativeCell(1), AttribData_KeyValues );
	if( hKeyValues == INVALID_HANDLE )
		return _:INVALID_HANDLE;
	new Handle:hCopy = CreateKeyValues( "attribute_data" );
	KvCopySubkeys( hKeyValues, hCopy );
	new Handle:hOutput = CloneHandle( hCopy, hPlugin );
	CloseHandle( hCopy );
	return _:hOutput;
}
public Native_GetAttribKey( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:AttribData_GetCell( GetNativeCell(1), AttribData_KeyValues );

	if( hKeyValues == INVALID_HANDLE )
		return 0;

	decl String:strKey[65];
	GetNativeString( 2, strKey, sizeof(strKey) );

	KvRewind( hKeyValues );
	return KvGetNum( hKeyValues, strKey, 0 );
}
public Native_GetAttribKeyFloat( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:AttribData_GetCell( GetNativeCell(1), AttribData_KeyValues );

	if( hKeyValues == INVALID_HANDLE )
		return 0;

	decl String:strKey[65];
	GetNativeString( 2, strKey, sizeof(strKey) );

	KvRewind( hKeyValues );
	return _:KvGetFloat( hKeyValues, strKey, 0.0 );
}
public Native_GetAttribKeyString( Handle:hPlugin, nParams )
{
	new Handle:hKeyValues = Handle:AttribData_GetCell( GetNativeCell(1), AttribData_KeyValues );

	if( hKeyValues == INVALID_HANDLE )
		return;

	decl String:strKey[65];
	GetNativeString( 2, strKey, sizeof(strKey) );

	new iBufferLength = GetNativeCell(4);
	decl String:strBuffer[iBufferLength+1];

	KvRewind( hKeyValues );
	KvGetString( hKeyValues, strKey, strBuffer, iBufferLength, "" );
	SetNativeString( 3, strBuffer, iBufferLength );
}

public Native_IsConflictRegions( Handle:hPlugin, nParams )
{
	decl String:strERA[16], String:strERB[16];
	GetNativeString( 1, strERA, sizeof(strERA) );
	GetNativeString( 2, strERB, sizeof(strERB) );

	if( strcmp( strERA, strERB, false ) == 0 )
		return true;

	decl String:strBuffer[16];
	if( hEquipConflicts != INVALID_HANDLE )
	{
		KvRewind( hEquipConflicts );
		if( KvJumpToKey( hEquipConflicts, strERA, false ) )
		{
			if( KvGotoFirstSubKey( hEquipConflicts, false ) )
				do
				{
					KvGetSectionName( hEquipConflicts, strBuffer, sizeof(strBuffer) );
					if( strcmp( strBuffer, strERB, false ) == 0 )
						return true;
				}
				while( KvGotoNextKey( hEquipConflicts, false ) );
		}
		else if( KvJumpToKey( hEquipConflicts, strERB, false ) )
		{
			if( KvGotoFirstSubKey( hEquipConflicts, false ) )
				do
				{
					KvGetSectionName( hEquipConflicts, strBuffer, sizeof(strBuffer) );
					if( strcmp( strBuffer, strERA, false ) == 0 )
						return true;
				}
				while( KvGotoNextKey( hEquipConflicts, false ) );
		}
	}

	return false;
}
public Native_GetQualityByName( Handle:hPlugin, nParams )
{
	decl String:strQualityName[TF2II_ITEMQUALITY_LENGTH];
	GetNativeString( 1, strQualityName, TF2II_ITEMQUALITY_LENGTH-1 );
	return _:GetQualityByName( strQualityName );
}
public Native_GetQualityName( Handle:hPlugin, nParams )
{
	new iQualityNum = GetNativeCell(1);
	new _:iQualityNameLength = GetNativeCell(3);
	decl String:strQualityName[iQualityNameLength+1];
	decl String:strIndex[16];
	IntToString( iQualityNum, strIndex, sizeof(strIndex) );
	new bool:bResult = GetTrieString( g_hQNames, strIndex, strQualityName, iQualityNameLength );
	SetNativeString( 2, strQualityName, iQualityNameLength );
	return bResult;
}
public Native_GetAttributeIDByName( Handle:hPlugin, nParams )
{
	decl String:strAttribName[TF2II_ATTRIBNAME_LENGTH];
	GetNativeString( 1, strAttribName, TF2II_ATTRIBNAME_LENGTH-1 );
	return GetAttribIDByName( strAttribName );
}
public Native_GetAttributeNameByID( Handle:hPlugin, nParams )
{
	new iAttribID = GetNativeCell(1);
	new _:iAttribNameLength = GetNativeCell(3);
	decl String:strAttribName[iAttribNameLength+1];
	new bool:bResult = AttribData_GetString( iAttribID, AttribData_Name, strAttribName, iAttribNameLength ) > 0;
	SetNativeString( 2, strAttribName, iAttribNameLength );
	return bResult;
}

public Native_FindItemsIDsByCond( Handle:hPlugin, nParams )
{
	Error( ERROR_LOG|ERROR_NOPRINT, SP_ERROR_NATIVE, "Deprecated function. Use TF2II_FindItems instead." );

	new Handle:hResults = CreateArray();

	decl String:strClass[64], String:strSlot[64], String:strTool[64];
	GetNativeString( 1, strClass, sizeof(strClass) );
	new iSlot = GetNativeCell(2);
	GetNativeString( 3, strSlot, sizeof(strSlot) );
	GetNativeString( 6, strTool, sizeof(strTool) );
	new bool:bClassFilter = GetNativeCell(4);
	new nClasses = _:TFClassType;
	new bool:bUsedByClass[nClasses];
	new iUsedByClass = TF2II_CLASS_NONE;

	if( bClassFilter )
	{
		GetNativeArray( 5, bUsedByClass, nClasses-1 );
		for( new c = 0; c < nClasses; c++ )
			if( bUsedByClass[c] )
				iUsedByClass |= ( 1 << ( c - 1 ) );
	}

	if( strlen(strSlot) <= 0 && iSlot > -1 )
		switch( TF2ItemSlot:iSlot )
		{
			case TF2ItemSlot_Primary:	strcopy( strSlot, sizeof(strSlot), "primary" );
			case TF2ItemSlot_Secondary:	strcopy( strSlot, sizeof(strSlot), "secondary" );
			case TF2ItemSlot_Melee:		strcopy( strSlot, sizeof(strSlot), "melee" );
			case TF2ItemSlot_Building:	strcopy( strSlot, sizeof(strSlot), "building" );
			case TF2ItemSlot_PDA1:		strcopy( strSlot, sizeof(strSlot), "pda" );
			case TF2ItemSlot_PDA2:		strcopy( strSlot, sizeof(strSlot), "pda2" );
			//case TF2ItemSlot_Head:		strcopy( strSlot, sizeof(strSlot), "head" );
			case TF2ItemSlot_Misc:		strcopy( strSlot, sizeof(strSlot), "misc" );
			case TF2ItemSlot_Action:	strcopy( strSlot, sizeof(strSlot), "action" );
		}

	decl String:strBuffer[128];
	new iItemDefID, nCells = GetArraySize( g_hItemData ), Handle:hData;
	for( new i = 0; i < nCells; i++ )
	{
		iItemDefID = -1;
		hData = INVALID_HANDLE;
		
		hData = Handle:GetArrayCell( g_hItemData, i );
		if( hData != INVALID_HANDLE )
			iItemDefID = GetArrayCell( hData, _:ItemData_DefinitionID );
		
		if( 0 <= iItemDefID <= iHighestItemDefID )
		{
			if( strlen(strSlot) > 0 && !( ItemData_GetString( iItemDefID, ItemData_Slot, strBuffer, sizeof(strBuffer) ) && strcmp( strSlot, strBuffer, false ) == 0 ) )
				continue;
			if( strlen(strClass) > 0 && !( ItemData_GetString( iItemDefID, ItemData_ClassName, strBuffer, sizeof(strBuffer) ) && strcmp( strClass, strBuffer, false ) == 0 ) )
				continue;
			if( strlen(strTool) > 0 && !( ItemData_GetString( iItemDefID, ItemData_Tool, strBuffer, sizeof(strBuffer) ) && strcmp( strTool, strBuffer, false ) == 0 ) )
				continue;
			if( iUsedByClass > TF2II_CLASS_NONE && !( iUsedByClass & ItemData_GetCell( iItemDefID, ItemData_UsedBy ) ) )
				continue;
			PushArrayCell( hResults, iItemDefID );
		}
	}

	Call_StartForward( hForward_OnFindItems );
	Call_PushString( strClass );
	Call_PushString( strSlot );
	Call_PushCell( iUsedByClass );
	Call_PushString( strTool );
	Call_PushCellRef( hResults );
	Call_Finish();

	new Handle:hReturn = CloneHandle( hResults, hPlugin );
	CloseHandle( hResults );
	return _:hReturn;
}
public Native_FindItems( Handle:hPlugin, nParams )
{
	new Handle:hResults = CreateArray();
	
	decl String:strClass[64], String:strSlot[64], String:strTool[64];
	GetNativeString( 1, strClass, sizeof(strClass) );
	GetNativeString( 2, strSlot, sizeof(strSlot) );
	new iUsedByClass = GetNativeCell(3);
	GetNativeString( 4, strTool, sizeof(strTool) );
	
	if( g_hItemData != INVALID_HANDLE )
	{
		decl String:strBuffer[128];
		new iItemDefID, nCells = GetArraySize( g_hItemData ), Handle:hData;
		for( new iCell = 0; iCell < nCells; iCell++ )
		{
			iItemDefID = -1;
			hData = INVALID_HANDLE;
			
			hData = Handle:GetArrayCell( g_hItemData, iCell );
			if( hData != INVALID_HANDLE )
				iItemDefID = GetArrayCell( hData, _:ItemData_DefinitionID );
			
			if( !( 0 <= iItemDefID <= iHighestItemDefID ) )
				continue;
			
			if( iUsedByClass > TF2II_CLASS_NONE && !( iUsedByClass & GetArrayCell( hData, _:ItemData_UsedBy ) ) )
				continue;
			
			if( strlen( strClass ) )
			{
				GetArrayString( hData, _:ItemData_ClassName, strBuffer, sizeof(strBuffer) );
				if( !strlen(strBuffer) || !StrEqual( strClass, strBuffer, false ) )
					continue;
			}
			
			if( strlen( strSlot ) )
			{
				GetArrayString( hData, _:ItemData_Slot, strBuffer, sizeof(strBuffer) );
				if( !strlen( strBuffer ) || !StrEqual( strSlot, strBuffer, false ) )
					continue;
			}

			if( strlen( strTool ) > 0 )
			{
				GetArrayString( hData, _:ItemData_Tool, strBuffer, sizeof(strBuffer) );
				if( !strlen( strBuffer ) || !StrEqual( strTool, strBuffer, false ) )
					continue;
			}

			PushArrayCell( hResults, iItemDefID );
		}
	}

	Call_StartForward( hForward_OnFindItems );
	Call_PushString( strClass );
	Call_PushString( strSlot );
	Call_PushCell( iUsedByClass );
	Call_PushString( strTool );
	Call_PushCellRef( hResults );
	Call_Finish();

	new Handle:hReturn = CloneHandle( hResults, hPlugin );
	CloseHandle( hResults );
	return _:hReturn;
}
public Native_ListEffects( Handle:hPlugin, nParams )
{
	new bool:bAllEffects = !!GetNativeCell(1);

	new iEffect, Handle:hResults = CreateArray(), Handle:hReturn = INVALID_HANDLE;
	if( g_hEffects != INVALID_HANDLE )
	{
		if( bAllEffects )
			hResults = CloneArray( g_hEffects );
		else
			for( new i = 0; i < GetArraySize( g_hEffects ); i++ )
			{
				iEffect = GetArrayCell( g_hEffects, i );
				if( iEffect > 5 && iEffect != 20 && iEffect != 28 )
					PushArrayCell( hResults, iEffect );
			}
		hReturn = CloneHandle( hResults, hPlugin );
		CloseHandle( hResults );
	}

	return _:hReturn;
}

public Native_DeprecatedFunction( Handle:hPlugin, nParams )
{
	Error( ERROR_BREAKN|ERROR_LOG|ERROR_NOPRINT, SP_ERROR_ABORTED, "Deprecated function." );
	return 0;
}

//////////////////
/* SQL handlers */
//////////////////

public SQL_ErrorCheck( Handle:hOwner, Handle:hQuery, const String:strError[], any:iUnused )
	if( strlen( strError ) )
		LogError( "MySQL DB error: %s", strError );

/////////////////////
/* Stock functions */
/////////////////////

stock Error( iFlags = ERROR_NONE, iNativeErrCode = SP_ERROR_NONE, const String:strMessage[], any:... )
{
	decl String:strBuffer[1024];
	VFormat( strBuffer, sizeof(strBuffer), strMessage, 4 );

	if( iFlags )
	{
		if( (iFlags & ERROR_LOG) && bUseLogs )
		{
			decl String:strFile[PLATFORM_MAX_PATH];
			FormatTime( strFile, sizeof(strFile), "%Y%m%d" );
			Format( strFile, sizeof(strFile), "TF2II%s", strFile );
			BuildPath( Path_SM, strFile, sizeof(strFile), "logs/%s.log", strFile );
			LogToFileEx( strFile, strBuffer );
		}

		if( iFlags & ERROR_BREAKF )
			ThrowError( strBuffer );
		if( iFlags & ERROR_BREAKN )
			ThrowNativeError( iNativeErrCode, strBuffer );
		if( iFlags & ERROR_BREAKP )
			SetFailState( strBuffer );

		if( iFlags & ERROR_NOPRINT )
			return;
	}

	PrintToServer( "[TF2ItemsInfo] %s", strBuffer );
}

//////////////////////////
/* ItemData_* functions */
//////////////////////////

stock Handle:ItemData_Create( iItemDefID, bReplace = true )
{
	new Handle:hArray = INVALID_HANDLE;

	new iIndex = ItemData_GetIndex( iItemDefID );
	if( iIndex >= 0 && iIndex < GetArraySize(g_hItemData) )
	{
		hArray = Handle:GetArrayCell( g_hItemData, iIndex );
		if( hArray != INVALID_HANDLE )
		{
			if( bReplace )
			{
				ItemData_Destroy( iItemDefID );
				hArray = ItemData_CreateArray( iItemDefID );
				SetArrayCell( g_hItemData, iIndex, _:hArray );
			}
			return hArray;
		}
	}

	hArray = ItemData_CreateArray( iItemDefID );
	ItemData_SetIndex( iItemDefID, PushArrayCell( g_hItemData, _:hArray ) );
	return hArray;
}
stock Handle:ItemData_CreateArray( iItemDefID = -1 )
{
	new Handle:hArray = CreateArray( 16 );
	PushArrayCell( hArray, iItemDefID );
	PushArrayCell( hArray, TF2II_PROP_INVALID );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "tf_wearable" );
	PushArrayString( hArray, "none" );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayCell( hArray, 1 );
	PushArrayCell( hArray, 1 );
	PushArrayString( hArray, "normal" );
	PushArrayCell( hArray, TF2II_CLASS_NONE );
	PushArrayCell( hArray, _:INVALID_HANDLE );
	PushArrayCell( hArray, _:INVALID_HANDLE );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayCell( hArray, _:INVALID_HANDLE );
	if( GetArraySize(hArray) != _:ItemDataType )
	{
		CloseHandle( hArray );
		Error( ERROR_BREAKP, _, "Contact author and say about ItemData array size." );
	}
	return hArray;
}
stock bool:ItemData_Destroy( iItemDefID )
{
	new iIndex = ItemData_GetIndex( iItemDefID );
	if( iIndex >= 0 && iIndex < GetArraySize(g_hItemData) )
	{
		new Handle:hArray = Handle:GetArrayCell( g_hItemData, iIndex );
		if( hArray != INVALID_HANDLE )
		{
			if( Handle:GetArrayCell( hArray, _:ItemData_Attributes ) != INVALID_HANDLE )
				CloseHandle( Handle:GetArrayCell( hArray, _:ItemData_Attributes ) );
			if( Handle:GetArrayCell( hArray, _:ItemData_EquipRegions ) != INVALID_HANDLE )
				CloseHandle( Handle:GetArrayCell( hArray, _:ItemData_EquipRegions ) );
			if( Handle:GetArrayCell( hArray, _:ItemData_KeyValues ) != INVALID_HANDLE )
				CloseHandle( Handle:GetArrayCell( hArray, _:ItemData_KeyValues ) );
			CloseHandle( hArray );
			return true;
		}
	}
	return false;
}

stock ItemData_GetIndex( iItemDefID )
{
	decl String:strItemDefID[16];
	IntToString( iItemDefID, strItemDefID, sizeof(strItemDefID) );
	return g_hItemDataKeys != INVALID_HANDLE ? KvGetNum( g_hItemDataKeys, strItemDefID, -1 ) : -1;
}
stock ItemData_SetIndex( iItemDefID, iIndex )
{
	decl String:strItemDefID[16];
	IntToString( iItemDefID, strItemDefID, sizeof(strItemDefID) );
	if( g_hItemDataKeys != INVALID_HANDLE )
	{
		KvSetNum( g_hItemDataKeys, strItemDefID, iIndex );
		return true;
	}
	return false;
}

stock ItemData_GetCell( iItemDefID, ItemDataType:iIDType )
{
	new iIndex = ItemData_GetIndex( iItemDefID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hItemData ) )
		return 0;

	new iType = _:iIDType;
	if( iType < 0 || iType >= _:ItemDataType )
		return 0;

	new Handle:hArray = Handle:GetArrayCell( g_hItemData, iIndex );
	if( hArray != INVALID_HANDLE )
		return GetArrayCell( hArray, iType );
	return 0;
}
stock bool:ItemData_SetCell( iItemDefID, ItemDataType:iIDType, iValue )
{
	new iIndex = ItemData_GetIndex( iItemDefID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hItemData ) )
		return false;

	new iType = _:iIDType;
	if( iType < 0 || iType >= _:ItemDataType )
		return false;

	new Handle:hArray = Handle:GetArrayCell( g_hItemData, iIndex );
	if( hArray != INVALID_HANDLE )
	{
		SetArrayCell( hArray, iType, iValue );
		return true;
	}
	return false;
}

stock ItemData_GetString( iItemDefID, ItemDataType:iIDType, String:strValue[], iValueLength )
{
	new iIndex = ItemData_GetIndex( iItemDefID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hItemData ) )
		return 0;

	new iType = _:iIDType;
	if( iType < 0 || iType >= _:ItemDataType )
		return 0;

	new Handle:hArray = Handle:GetArrayCell( g_hItemData, iIndex );
	if( hArray != INVALID_HANDLE )
		return GetArrayString( hArray, iType, strValue, iValueLength );
	return 0;
}
stock ItemData_SetString( iItemDefID, ItemDataType:iIDType, const String:strValue[] )
{
	new iIndex = ItemData_GetIndex( iItemDefID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hItemData ) )
		return 0;

	new iType = _:iIDType;
	if( iType < 0 || iType >= _:ItemDataType )
		return 0;

	new Handle:hArray = Handle:GetArrayCell( g_hItemData, iIndex );
	if( hArray != INVALID_HANDLE )
		return SetArrayString( hArray, iType, strValue );
	return 0;
}

////////////////////////////
/* AttribData_* functions */
////////////////////////////

stock Handle:AttribData_Create( iAttribID, bReplace = true )
{
	new Handle:hArray = INVALID_HANDLE;

	new iIndex = AttribData_GetIndex( iAttribID );
	if( iIndex >= 0 && iIndex < GetArraySize(g_hAttribData) )
	{
		hArray = Handle:GetArrayCell( g_hAttribData, iIndex );
		if( hArray != INVALID_HANDLE )
		{
			if( bReplace )
			{
				AttribData_Destroy( iAttribID );
				hArray = AttribData_CreateArray( iAttribID );
				SetArrayCell( g_hAttribData, iIndex, _:hArray );
			}
			return hArray;
		}
	}

	hArray = AttribData_CreateArray( iAttribID );
	AttribData_SetIndex( iAttribID, PushArrayCell( g_hAttribData, _:hArray ) );
	return hArray;
}
stock Handle:AttribData_CreateArray( iAttribID = -1 )
{
	new Handle:hArray = CreateArray( 24 );
	PushArrayCell( hArray, iAttribID );
	PushArrayCell( hArray, TF2II_PROP_INVALID );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayCell( hArray, _:(1.0) );
	PushArrayCell( hArray, _:(1.0) );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayString( hArray, "" );
	PushArrayCell( hArray, _:INVALID_HANDLE );
	if( GetArraySize(hArray) != _:AttribDataType )
	{
		CloseHandle( hArray );
		Error( ERROR_BREAKP, _, "Contact author and say about AttribData array size." );
	}
	return hArray;
}
stock bool:AttribData_Destroy( iAttribID )
{
	new iIndex = AttribData_GetIndex( iAttribID );
	if( iIndex >= 0 && iIndex < GetArraySize(g_hAttribData) )
	{
		new Handle:hArray = Handle:GetArrayCell( g_hAttribData, iIndex );
		if( hArray != INVALID_HANDLE )
		{
			if( Handle:GetArrayCell( hArray, _:AttribData_KeyValues ) != INVALID_HANDLE )
				CloseHandle( Handle:GetArrayCell( hArray, _:AttribData_KeyValues ) );
			CloseHandle( hArray );
			return true;
		}
	}
	return false;
}

stock AttribData_GetIndex( iAttribID )
{
	decl String:strItemDefID[16];
	IntToString( iAttribID, strItemDefID, sizeof(strItemDefID) );
	return g_hAttribDataKeys != INVALID_HANDLE ? KvGetNum( g_hAttribDataKeys, strItemDefID, -1 ) : -1;
}
stock AttribData_SetIndex( iAttribID, iIndex )
{
	decl String:strItemDefID[16];
	IntToString( iAttribID, strItemDefID, sizeof(strItemDefID) );
	if( g_hAttribDataKeys != INVALID_HANDLE )
	{
		KvSetNum( g_hAttribDataKeys, strItemDefID, iIndex );
		return true;
	}
	return false;
}

stock AttribData_GetCell( iAttribID, AttribDataType:iADType )
{
	new iIndex = AttribData_GetIndex( iAttribID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hAttribData ) )
		return 0;

	new iType = _:iADType;
	if( iType < 0 || iType >= _:AttribDataType )
		return 0;

	new Handle:hArray = Handle:GetArrayCell( g_hAttribData, iIndex );
	if( hArray != INVALID_HANDLE )
		return GetArrayCell( hArray, iType );
	return 0;
}
stock bool:AttribData_SetCell( iAttribID, AttribDataType:iADType, iValue )
{
	new iIndex = AttribData_GetIndex( iAttribID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hAttribData ) )
		return false;

	new iType = _:iADType;
	if( iType < 0 || iType >= _:AttribDataType )
		return false;

	new Handle:hArray = Handle:GetArrayCell( g_hAttribData, iIndex );
	if( hArray != INVALID_HANDLE )
	{
		SetArrayCell( hArray, iType, iValue );
		return true;
	}
	return false;
}

stock AttribData_GetString( iAttribID, AttribDataType:iADType, String:strValue[], iValueLength )
{
	new iIndex = AttribData_GetIndex( iAttribID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hAttribData ) )
		return 0;

	new iType = _:iADType;
	if( iType < 0 || iType >= _:AttribDataType )
		return 0;

	new Handle:hArray = Handle:GetArrayCell( g_hAttribData, iIndex );
	if( hArray != INVALID_HANDLE )
		return GetArrayString( hArray, iType, strValue, iValueLength );
	return 0;
}
stock AttribData_SetString( iAttribID, AttribDataType:iADType, const String:strValue[] )
{
	new iIndex = AttribData_GetIndex( iAttribID );
	if( iIndex < 0 || iIndex >= GetArraySize( g_hAttribData ) )
		return 0;

	new iType = _:iADType;
	if( iType < 0 || iType >= _:AttribDataType )
		return 0;

	new Handle:hArray = Handle:GetArrayCell( g_hAttribData, iIndex );
	if( hArray != INVALID_HANDLE )
		return SetArrayString( hArray, iType, strValue );
	return 0;
}

//////////////////////////
/* Validating functions */
//////////////////////////

stock bool:IsValidItemID( iItemDefID )
	return ( 0 <= iItemDefID <= iHighestItemDefID && ItemHasProp( iItemDefID, TF2II_PROP_VALIDITEM ) );
stock bool:IsValidAttribID( iAttribID )
	return ( 0 < iAttribID <= iHighestAttribID && AttribHasProp( iAttribID, TF2II_PROP_VALIDATTRIB ) );

stock bool:ItemHasProp( iItemDefID, iFlags )
{
	if( !( 0 <= iItemDefID <= iHighestItemDefID ) || iFlags <= TF2II_PROP_INVALID )
		return false;
	if( ( iFlags & TF2II_PROP_VALIDITEM ) != TF2II_PROP_VALIDITEM && !IsValidItemID( iItemDefID ) )
		return false;
	return ( ItemData_GetCell( iItemDefID, ItemData_Property ) & iFlags ) == iFlags;
}
stock bool:AttribHasProp( iAttribID, iFlags )
{
	if( !( 0 < iAttribID <= iHighestAttribID ) || iFlags <= TF2II_PROP_INVALID )
		return false;
	if( ( iFlags & TF2II_PROP_VALIDATTRIB ) != TF2II_PROP_VALIDATTRIB && !IsValidAttribID( iAttribID ) )
		return false;
	return ( AttribData_GetCell( iAttribID, AttribData_Property ) & iFlags ) == iFlags;
}

stock bool:IsValidClient( _:iClient )
{
	if( iClient <= 0 || iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) || !IsClientInGame(iClient) ) return false;
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 4
	if( IsClientSourceTV(iClient) || IsClientReplay(iClient) ) return false;
#endif
	return true;
}

//////////////////////////////////
/* FlaminSarge's KvCopyDataToKv */
//////////////////////////////////

stock KvCopyDataToKv( Handle:hSource, Handle:hDest, bool:bIAmASubKey = false )
{
	decl String:strNodeName[128];
	decl String:strNodeValue[1024];
	if( !bIAmASubKey || KvGotoFirstSubKey( hSource, false ) )
	{
		do
		{
			// You can read the section/key name by using KvGetSectionName here.
			KvGetSectionName( hSource, strNodeName, sizeof(strNodeName) );
			if( KvGotoFirstSubKey( hSource, false ) )
			{
				// Current key is a section. Browse it recursively.
				KvJumpToKey( hDest, strNodeName, true );
				KvCopyDataToKv( hSource, hDest );
				KvGoBack( hSource );
				KvGoBack( hDest );
			}
			else
			{
				// Current key is a regular key, or an empty section.
				if( KvGetDataType( hSource, NULL_STRING ) != KvData_None )
				{
					// Read value of key here. You can also get the key name
					// by using KvGetSectionName here.
					KvGetString( hSource, NULL_STRING, strNodeValue, sizeof(strNodeValue) );
					KvSetString( hDest, strNodeName, strNodeValue );
				}
				else
				{
					// Found an empty sub section. It can be handled here if necessary.
				}
			}
		}
		while( KvGotoNextKey( hSource, false ) );
		
		if( bIAmASubKey )
			KvGoBack( hSource );
	}
}