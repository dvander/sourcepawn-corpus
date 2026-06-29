#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <adminmenu>

#define PLUGIN_VERSION "1.1.6-201400822"
#define PLUGIN_MSG_PREFIX "[NMP-GW] "

#define PATH_ITEMS_DATA "data/nmrih_items_data.txt"

#define SPAWNITEM_DISTANCE		100.0
#define SPAWNITEM_OFFSET		15.0

#define ADMINMENU_GIVE_ITEM		0
#define ADMINMENU_GIVE_TARGET	1
#define ADMINMENU_SPAWN_ITEM	2
#define ADMINMENU_SPAWN_TARGET	3

#define ADMINMENU_NEW_CATEGORY	1


enum
{
	FindItem_FoundNothing = 0,
	FindItem_InvalidArg = -1,
	FindItem_NoAccess = -2,
	FindItem_NotAvaliable = -3
};


new Handle:nmp_giveweapons_version = INVALID_HANDLE;
new Handle:nmp_gw_silent = INVALID_HANDLE;

new bool:bSilentAdmin = true;

new Handle:hItemsData = INVALID_HANDLE;

#if defined _adminmenu_included
new Handle:hLastTopMenu = INVALID_HANDLE;
new String:szSelectedItem[MAXPLAYERS+1][33];
#endif

public Plugin:myinfo = {
	name = "[NMRiH] Give Weapons",
	author = "Leonardo",
	description = "Give weapons and items.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};


public OnPluginStart()
{
	LoadTranslations( "core.phrases.txt" );
	LoadTranslations( "common.phrases.txt" );
	LoadTranslations( "nmp_giveweapons.phrases.txt" );
	
	nmp_giveweapons_version = CreateConVar( "nmp_giveweapons_version", PLUGIN_VERSION, "NoMorePlugins Give Weapons", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD );
	SetConVarString( nmp_giveweapons_version, PLUGIN_VERSION );
	HookConVarChange( nmp_giveweapons_version, OnConVarChanged_Version );
	
	HookConVarChange( nmp_gw_silent = CreateConVar( "nmp_gw_silent", bSilentAdmin ? "1" : "0", "Hide admin activity.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	
	RegAdminCmd( "sm_give", Command_Give, ADMFLAG_SLAY, "Usage: sm_give <targets> <weapon|item>" );
	RegAdminCmd( "sm_spawni", Command_SpawnItem, ADMFLAG_KICK, "Usage: sm_spawni <weapon|item> [targets|x y z]" );
	RegAdminCmd( "sm_gw_reload", Command_ReloadConfigs, ADMFLAG_ROOT );
	RegAdminCmd( "sm_gw_scan", Command_Scan, ADMFLAG_GENERIC );
	
#if defined _adminmenu_included
	for( new i = 0; i <= MAXPLAYERS; i++ )
		OnClientDisconnect_Post( i );
#endif
}

#if defined _adminmenu_included
public OnAllPluginsLoaded()
{
	new Handle:hTopMenu;
	if( LibraryExists( "adminmenu" ) && ( hTopMenu = GetAdminTopMenu() ) != INVALID_HANDLE )
		OnAdminMenuReady( hTopMenu );
}

public OnLibraryRemoved( const String:szLibName[] )
	if( StrEqual( szLibName, "adminmenu" ) )
		hLastTopMenu = INVALID_HANDLE;
#endif

public OnConfigsExecuted()
{
	bSilentAdmin = GetConVarBool( nmp_gw_silent );
	
	if( hItemsData == INVALID_HANDLE )
		ReadItemsData();
}


#if defined _adminmenu_included
public OnClientPutInServer( iClient )
	OnClientDisconnect_Post( iClient );

public OnClientDisconnect_Post( iClient )
	if( 0 <= iClient <= MAXPLAYERS )
		szSelectedItem[iClient][0] = '\0';
#endif


public OnConVarChanged( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	OnConfigsExecuted();

public OnConVarChanged_Version( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	if( strcmp( szNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );


public Action:Command_Give( iClient, nArgs )
{
	if( nArgs < 2 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_give <targets> <weapon/item>", PLUGIN_MSG_PREFIX );
		return Plugin_Handled;
	}
	
	new String:szBuffer[121];
	new iTargets[MAXPLAYERS+1], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	new String:szClassname[21], String:szItemName[2][32], bool:bItemNameIsML, iMaxAmmo[2];
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
	switch( FindItemEx( iClient, szBuffer, szClassname, sizeof( szClassname ), szItemName[0], sizeof( szItemName[] ), szItemName[1], sizeof( szItemName[] ), bItemNameIsML, iMaxAmmo[0], iMaxAmmo[1] ) )
	{
		case 1: {}
		case FindItem_FoundNothing:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Matching" );
			return Plugin_Handled;
		}
		case FindItem_InvalidArg:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Argument", szBuffer );
			return Plugin_Handled;
		}
		case FindItem_NoAccess:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Access" );
			return Plugin_Handled;
		}
		case FindItem_NotAvaliable:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Cannot Give" );
			return Plugin_Handled;
		}
		default:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Multiple Items" );
			return Plugin_Handled;
		}
	}
	
	new bool:bBandages = StrEqual( szClassname, "item_bandages", true );
	new bool:bFirstAid = StrEqual( szClassname, "item_first_aid", true );
	new bool:bPills = StrEqual( szClassname, "item_pills", true );
	new bool:bWalkieTalkie = StrEqual( szClassname, "item_walkietalkie", true );
	
	for( new iEntity, iPAmmoOffs, i = 0; i < nTargets; i++ )
	{
		iEntity = -1;
		
		if( bBandages )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "_bandageCount" ) )
				continue;
		}
		else if( bFirstAid )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "_hasFirstAidKit" ) )
				continue;
		}
		else if( bPills )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "m_bHasPills" ) )
				continue;
		}
		else if( bWalkieTalkie )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "m_bHasWalkieTalkie" ) )
				continue;
		}
		else for( new j = 0; j < 48; j++ )
		{
			iEntity = GetEntPropEnt( iTargets[i], Prop_Send, "m_hMyWeapons", j );
			if( IsValidEdict( iEntity ) )
			{
				GetEntityClassname( iEntity, szBuffer, sizeof( szBuffer ) );
				if( StrEqual( szClassname, szBuffer, false ) )
					break;
			}
			iEntity = -1;
		}
		
		if( iEntity == -1 )
		{
			iEntity = GivePlayerItem( iTargets[i], szClassname );
			if( !IsValidEdict( iEntity ) )
			{
				LogMessage( "Failed to give '%s' to player %L (by %N)", szClassname, iTargets[i], iClient );
				ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Entity", szClassname );
				continue;
			}
		}
		
		iPAmmoOffs = FindDataMapOffs( iTargets[i], "m_iAmmo" );
		if( iMaxAmmo[0] > 0 )
			SetEntData( iTargets[i], ( iPAmmoOffs + GetEntProp( iEntity, Prop_Data, "m_iPrimaryAmmoType" ) * 4 ), iMaxAmmo[0], _, true );
		if( iMaxAmmo[1] > 0 )
			SetEntData( iTargets[i], ( iPAmmoOffs + GetEntProp( iEntity, Prop_Data, "m_iSecondaryAmmoType" ) * 4 ), iMaxAmmo[1], _, true );
		
		AcceptEntityInput( iEntity, "Use", iTargets[i], iTargets[i] );
		
		if( !bSilentAdmin && !bTargetNameML )
			ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Give 2 T" : "NMP Activity Give 2", szItemName[1], iTargets[i] );
		LogAction( iClient, iTargets[i], "gave '%s'", szClassname );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Give T" : "NMP Activity Give", szItemName[1], szTargetName );
	
	return Plugin_Handled;
}

public Action:Command_SpawnItem( iClient, nArgs )
{
	if( iClient < 0 || iClient > MaxClients || iClient != 0 && !IsClientInGame( iClient ) )
		return Plugin_Continue;
	
	new String:szBuffer[121], bool:bOverrideCoords = false;
	new iTargets[MAXPLAYERS+1], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	new String:szClassname[21], String:szItemName[2][32], bool:bItemNameIsML, iMaxAmmo[2];
	
	new Float:vecTarget[3], Float:vecEyeAngles[3];
	if( nArgs == 2 )
	{
		GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
		if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
		{
			ReplyToTargetError( iClient, nTargets );
			return Plugin_Handled;
		}
	}
	else if( nArgs == 4 )
	{
		for( new i = 0; i < 3; i++ )
		{
			GetCmdArg( i + 1, szBuffer, sizeof( szBuffer ) );
			StringToFloatEx( szBuffer, vecTarget[i] );
		}
		bOverrideCoords = true;
		nTargets = 1;
	}
	else if( iClient == 0 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_spawni <weapon|item> <targets|x y z>", PLUGIN_MSG_PREFIX );
		return Plugin_Handled;
	}
	else if( nArgs == 1 )
	{
		iTargets[0] = iClient;
		nTargets = 1;
	}
	else
	{
		ReplyToCommand( iClient, "%sUsage: sm_spawni <weapon|item> [targets|x y z]", PLUGIN_MSG_PREFIX );
		return Plugin_Handled;
	}
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	switch( FindItemEx( iClient, szBuffer, szClassname, sizeof( szClassname ), szItemName[0], sizeof( szItemName[] ), szItemName[1], sizeof( szItemName[] ), bItemNameIsML, iMaxAmmo[0], iMaxAmmo[1] ) )
	{
		case 1: {}
		case FindItem_FoundNothing:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Matching" );
			return Plugin_Handled;
		}
		case FindItem_InvalidArg:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Argument", szBuffer );
			return Plugin_Handled;
		}
		case FindItem_NoAccess:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Access" );
			return Plugin_Handled;
		}
		case FindItem_NotAvaliable:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Cannot Spawn" );
			return Plugin_Handled;
		}
		default:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Multiple Items" );
			return Plugin_Handled;
		}
	}
	
	new iEntity = CreateEntityByName( szClassname );
	if( !IsValidEdict( iEntity ) )
	{
		LogMessage( "Failed to spawn '%s' (by %N)", szClassname, iClient );
		ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Entity", szClassname );
		return Plugin_Handled;
	}
	
	new Float:vecEyeOrigin[3], Float:vecMaxs[3];
	for( new c = 0; c < nTargets; c++ )
	{
		if( !bOverrideCoords )
		{
			GetClientEyePosition( iTargets[c], vecEyeOrigin );
			GetClientEyeAngles( iTargets[c], vecEyeAngles );
			GetEntPropVector( iTargets[c], Prop_Send, "m_vecMaxs", vecMaxs );
			
			vecEyeAngles[0] = 0.0;
			vecEyeAngles[2] = 0.0;
			
			new Handle:hRay = TR_TraceRayFilterEx( vecEyeOrigin, vecEyeAngles, MASK_PLAYERSOLID, RayType_Infinite, Callback_TraceFilter );
			if( !TR_DidHit( hRay ) )
			{
				CloseHandle( hRay );
				continue;
			}
			
			new Float:vecRayHit[3], Float:vecBuffer[3];
			
			TR_GetEndPosition( vecRayHit, hRay );
			CloseHandle( hRay );
			
			GetAngleVectors( vecEyeAngles, vecBuffer, NULL_VECTOR, NULL_VECTOR );
			
			new Float:flDistance = FloatAbs( GetVectorDistance( vecEyeOrigin, vecRayHit, false ) );
			if( flDistance > SPAWNITEM_DISTANCE )
				flDistance -= SPAWNITEM_DISTANCE;
			else
				flDistance = 0.0;
			flDistance += vecMaxs[0] + SPAWNITEM_OFFSET;
			
			for( new i = 0; i < 3; i++ )
				vecTarget[i] = vecRayHit[i] + vecBuffer[i] * -flDistance;
			
			
			// Anti Ceiling Stuck
			
			vecBuffer[0] = vecTarget[0];
			vecBuffer[1] = vecTarget[1];
			vecBuffer[2] = vecTarget[2] + vecMaxs[2];
			
			hRay = TR_TraceRayFilterEx( vecTarget, vecBuffer, MASK_PLAYERSOLID, RayType_EndPoint, Callback_TraceFilter );
			if( TR_DidHit( hRay ) )
			{
				TR_GetEndPosition( vecRayHit, hRay );
				CloseHandle( hRay );
				
				flDistance = FloatAbs( GetVectorDistance( vecTarget, vecRayHit, false ) );
				if( flDistance >= vecMaxs[2] )
					vecTarget[2] -= ( vecMaxs[2] + SPAWNITEM_OFFSET );
				else if( 0.0 < flDistance < vecMaxs[2] )
					vecTarget[2] -= ( vecMaxs[2] - flDistance + SPAWNITEM_OFFSET );
			}
			else
				CloseHandle( hRay );
		}
		
		DispatchSpawn( iEntity );
		TeleportEntity( iEntity, vecTarget, vecEyeAngles, NULL_VECTOR );
		ActivateEntity( iEntity );
		//AcceptEntityInput( iEntity, "Use", iTargets[c], iTargets[c] );
		
		if( bOverrideCoords )
		{
			if( !bSilentAdmin )
				ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Placed T" : "NMP Activity Placed", szItemName[1] );
			LogAction( iClient, -1, "placed '%s' @ %.2f %.2f %.2f", szClassname, vecTarget[0], vecTarget[1], vecTarget[2] );
		}
		else
		{
			if( !bSilentAdmin && !bTargetNameML )
				ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Spawn 2 T" : "NMP Activity Spawn 2", szItemName[1], iTargets[c] );
			LogAction( iClient, iTargets[c], "spawned '%s'", szClassname );
		}
	}
	
	if( !bOverrideCoords && !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Spawn T" : "NMP Activity Spawn", szItemName[1], szTargetName );
	
	return Plugin_Handled;
}
public bool:Callback_TraceFilter( iEntity, iContentsMask )
{
	if( IsValidEntity( iEntity ) && !IsValidEdict( iEntity ) )
		return true;
	new String:strClassname[32];
	GetEdictClassname( iEntity, strClassname, sizeof( strClassname ) );
	if( StrEqual( strClassname, "player", false ) )
		return false;
	return true;
}

public Action:Command_ReloadConfigs( iClient, nArgs )
{
	if( ReadItemsData( true ) )
		ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Data Reloaded" );
	else
		ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Data Not Reloaded" );
	return Plugin_Handled;
}

public Action:Command_Scan( iClient, nArgs )
{
	if( iClient <= 0 || iClient > MaxClients || !IsClientInGame( iClient ) )
	{
		ReplyToCommand( iClient, "You must be in-game to execute this command." );
		return Plugin_Handled;
	}
	
	if( !IsPlayerAlive( iClient ) )
	{
		ReplyToCommand( iClient, "You must be alive to execute this command." );
		return Plugin_Handled;
	}
	
	PrintToServer( "> %N executed sm_gw_scan:", iClient );
	
	new iCarriedWeight = GetEntProp( iClient, Prop_Send, "_carriedWeight" );
	PrintToConsole( iClient, ">> _carriedWeight: %d", iCarriedWeight );
	PrintToServer( ">> _carriedWeight: %d", iCarriedWeight );
	
	for( new iEntity, String:szClassname[21], i = 0; i < 48; i++ )
	{
		iEntity = GetEntPropEnt( iClient, Prop_Send, "m_hMyWeapons", i );
		if( IsValidEdict( iEntity ) )
		{
			GetEntityClassname( iEntity, szClassname, sizeof( szClassname ) );
			PrintToConsole( iClient, ">>>> m_hMyWeapons (%03d): %05d %s", i, iEntity, szClassname, GetEntProp( iEntity, Prop_Send, "m_iPrimaryAmmoType" ) );
			PrintToServer( ">>>> m_hMyWeapons (%03d): %05d %s (ammotype:%d)", i, iEntity, szClassname, GetEntProp( iEntity, Prop_Send, "m_iPrimaryAmmoType" ) );
		}
	}
	
	for( new iAmmo, i = 0; i < 32; i++ )
	{
		iAmmo = GetEntProp( iClient, Prop_Send, "m_iAmmo", _, i );
		if( iAmmo )
		{
			PrintToConsole( iClient, ">>>> m_iAmmo (%03d): %d", i, iAmmo );
			PrintToServer( ">>>> m_iAmmo (%03d): %d", i, iAmmo );
		}
	}
	
	return Plugin_Handled;
}


#if defined _adminmenu_included
public OnAdminMenuReady( Handle:hTopMenu )
{
	if( hTopMenu == hLastTopMenu )
		return;
	hLastTopMenu = hTopMenu;
	
#if defined ADMINMENU_NEW_CATEGORY
	new TopMenuObject:hMenu = AddToTopMenu( hLastTopMenu, "nmp_gw_cmds", TopMenuObject_Category, Handle_MenuCategory, INVALID_TOPMENUOBJECT );
#else
	new TopMenuObject:hMenu = FindTopMenuCategory( hLastTopMenu, ADMINMENU_PLAYERCOMMANDS );
#endif
	if( hMenu == INVALID_TOPMENUOBJECT )
		return;
	
	AddToTopMenu( hLastTopMenu, "nmp_gw_give", TopMenuObject_Item, Handle_MenuGiveItem, hMenu, "sm_give", ADMFLAG_SLAY );
	AddToTopMenu( hLastTopMenu, "nmp_gw_spawni", TopMenuObject_Item, Handle_MenuSpawnItem, hMenu, "sm_spawni", ADMFLAG_KICK );
}

#if defined ADMINMENU_NEW_CATEGORY
public Handle_MenuCategory( Handle:hMenu, TopMenuAction:iAction, TopMenuObject:iObject, iParam, String:szBuffer[], iBufferLength )
	switch( iAction )
	{
		case TopMenuAction_DisplayOption:
			Format( szBuffer, iBufferLength, "%T", "NMP AM Category", LANG_SERVER );
		case TopMenuAction_DisplayTitle:
			Format( szBuffer, iBufferLength, "%T", "NMP AM Action", LANG_SERVER );
	}
#endif
public Handle_MenuGiveItem( Handle:hMenu, TopMenuAction:iAction, TopMenuObject:iObject, iParam, String:szBuffer[], iBufferLength )
	switch( iAction )
	{
		case TopMenuAction_DisplayOption:
			Format( szBuffer, iBufferLength, "%T", "NMP AM Give Item", LANG_SERVER );
		case TopMenuAction_SelectOption:
			ShowAdminMenu( iParam, ADMINMENU_GIVE_ITEM );
	}
public Handle_MenuSpawnItem( Handle:hMenu, TopMenuAction:iAction, TopMenuObject:iObject, iParam, String:szBuffer[], iBufferLength )
	switch( iAction )
	{
		case TopMenuAction_DisplayOption:
			Format( szBuffer, iBufferLength, "%T", "NMP AM Spawn Item", LANG_SERVER );
		case TopMenuAction_SelectOption:
			ShowAdminMenu( iParam, ADMINMENU_SPAWN_ITEM );
	}

stock ShowAdminMenu( iClient, nType )
{
	if( !( 0 < iClient <= MaxClients ) || !IsClientInGame( iClient ) )
		return;
	
	CancelClientMenu( iClient );
	
	new Handle:hMenu;
	switch( nType )
	{
		case ADMINMENU_GIVE_ITEM:		hMenu = CreateMenu( Menu_GiveItem );
		case ADMINMENU_GIVE_TARGET:		hMenu = CreateMenu( Menu_GiveTarget );
		case ADMINMENU_SPAWN_ITEM:		hMenu = CreateMenu( Menu_SpawnItem );
		case ADMINMENU_SPAWN_TARGET:	hMenu = CreateMenu( Menu_SpawnTarget );
		default:						return;
	}
	
	new String:szBuffer[3][121];
	if( nType == ADMINMENU_GIVE_TARGET || nType == ADMINMENU_SPAWN_TARGET )
	{
		Format( szBuffer[0], sizeof( szBuffer[] ), "%T", "NMP AM Select Target", LANG_SERVER );
		SetMenuTitle( hMenu, szBuffer[0] );
		
		Format( szBuffer[0], sizeof( szBuffer[] ), "%T", "all alive players", LANG_SERVER );
		AddMenuItem( hMenu, "@alive", szBuffer[0] );
		
		if( IsPlayerAlive( iClient ) )
		{
			Format( szBuffer[0], sizeof( szBuffer[] ), "%N (%d)", iClient, GetClientUserId( iClient ) );
			AddMenuItem( hMenu, "@me", szBuffer[0] );
		}
		
		for( new i = 1; i <= MaxClients; i++ )
			if( i != iClient && IsClientInGame( i ) && IsPlayerAlive( i ) )
			{
				Format( szBuffer[0], sizeof( szBuffer[] ), "#%d", GetClientUserId( i ) );
				Format( szBuffer[1], sizeof( szBuffer[] ), "%N (%d)", i, GetClientUserId( i ) );
				
				AddMenuItem( hMenu, szBuffer[0], szBuffer[1] );
			}
	}
	else
	{
		Format( szBuffer[0], sizeof( szBuffer[] ), "%T", "NMP AM Select Item", LANG_SERVER );
		SetMenuTitle( hMenu, szBuffer[0] );
		
		if( hItemsData != INVALID_HANDLE )
		{
			new Handle:hItems = CreateKeyValues( "items" );
			KvRewind( hItemsData );
			KvCopySubkeys( hItemsData, hItems );
			if( KvJumpToKey( hItems, "items" ) && KvGotoFirstSubKey( hItems ) )
				do
				{
					KvGetString( hItems, "classname", szBuffer[2], sizeof( szBuffer[] ) );
					if( szBuffer[2][0] == '\0' )
						continue;
					
					KvGetString( hItems, "type", szBuffer[1], sizeof( szBuffer[] ) );
					if( szBuffer[1][0] != '\0' )
					{
						GetTypeMLString( szBuffer[1], szBuffer[1], sizeof( szBuffer[] ) );
						Format( szBuffer[1], sizeof( szBuffer[] ), "%T", szBuffer[1], LANG_SERVER );
					}
					else
						strcopy( szBuffer[1], sizeof( szBuffer[] ), "unknown" );
					
					KvGetString( hItems, "name_short", szBuffer[0], sizeof( szBuffer[] ) );
					if( szBuffer[0][0] == '\0' )
					{
						KvGetString( hItems, "name_ml", szBuffer[0], sizeof( szBuffer[] ) );
						if( szBuffer[0][0] == '\0' )
							Format( szBuffer[0], sizeof( szBuffer[] ), "Weapon_%s_short", szBuffer[2] );
						Format( szBuffer[1], sizeof( szBuffer[] ), "%T (%s)", szBuffer[0], LANG_SERVER, szBuffer[1], LANG_SERVER );
					}
					else
						Format( szBuffer[1], sizeof( szBuffer[] ), "%s (%s)", szBuffer[0], szBuffer[1], LANG_SERVER );
					
					AddMenuItem( hMenu, szBuffer[2], szBuffer[1] );
				}
				while( KvGotoNextKey( hItems ) );
			CloseHandle( hItems );
		}
	}
	
	SetMenuExitButton( hMenu, nType != ADMINMENU_GIVE_TARGET && nType != ADMINMENU_SPAWN_TARGET );
	SetMenuExitBackButton( hMenu, nType == ADMINMENU_GIVE_TARGET || nType == ADMINMENU_SPAWN_TARGET );
	DisplayMenu( hMenu, iClient, MENU_TIME_FOREVER );
}

public Menu_GiveItem( Handle:hMenu, MenuAction:iAction, iParam1, iParam2 )
	switch( iAction )
	{
		case MenuAction_End:
			CloseHandle( hMenu );
		case MenuAction_Cancel:
			if( iParam2 == MenuCancel_ExitBack && hLastTopMenu != INVALID_HANDLE )
				DisplayTopMenu( hLastTopMenu, iParam1, TopMenuPosition_LastCategory );
		case MenuAction_Select:
		{
			GetMenuItem( hMenu, iParam2, szSelectedItem[iParam1], sizeof( szSelectedItem[] ) );
			ShowAdminMenu( iParam1, ADMINMENU_GIVE_TARGET );
		}
	}
public Menu_GiveTarget( Handle:hMenu, MenuAction:iAction, iParam1, iParam2 )
	switch( iAction )
	{
		case MenuAction_End:
			CloseHandle( hMenu );
		case MenuAction_Cancel:
			if( iParam2 == MenuCancel_ExitBack && hLastTopMenu != INVALID_HANDLE )
				ShowAdminMenu( iParam1, ADMINMENU_GIVE_ITEM );
		case MenuAction_Select:
		{
			new String:szBuffer[48];
			GetMenuItem( hMenu, iParam2, szBuffer, sizeof( szBuffer ) );
			FakeClientCommand( iParam1, "sm_give %s %s", szBuffer, szSelectedItem[iParam1] );
			ShowAdminMenu( iParam1, ADMINMENU_GIVE_TARGET );
		}
	}
public Menu_SpawnItem( Handle:hMenu, MenuAction:iAction, iParam1, iParam2 )
	switch( iAction )
	{
		case MenuAction_End:
			CloseHandle( hMenu );
		case MenuAction_Cancel:
			if( iParam2 == MenuCancel_ExitBack && hLastTopMenu != INVALID_HANDLE )
				DisplayTopMenu( hLastTopMenu, iParam1, TopMenuPosition_LastCategory );
		case MenuAction_Select:
		{
			GetMenuItem( hMenu, iParam2, szSelectedItem[iParam1], sizeof( szSelectedItem[] ) );
			ShowAdminMenu( iParam1, ADMINMENU_SPAWN_TARGET );
		}
	}
public Menu_SpawnTarget( Handle:hMenu, MenuAction:iAction, iParam1, iParam2 )
	switch( iAction )
	{
		case MenuAction_End:
			CloseHandle( hMenu );
		case MenuAction_Cancel:
			if( iParam2 == MenuCancel_ExitBack && hLastTopMenu != INVALID_HANDLE )
				ShowAdminMenu( iParam1, ADMINMENU_SPAWN_ITEM );
		case MenuAction_Select:
		{
			new String:szBuffer[48];
			GetMenuItem( hMenu, iParam2, szBuffer, sizeof( szBuffer ) );
			FakeClientCommand( iParam1, "sm_spawni %s %s", szSelectedItem[iParam1], szBuffer );
			ShowAdminMenu( iParam1, ADMINMENU_SPAWN_TARGET );
		}
	}
#endif


stock ReadItemsData( bool:bReload = false )
{
	if( hItemsData != INVALID_HANDLE )
	{
		if( bReload )
		{
			CloseHandle( hItemsData );
			hItemsData = INVALID_HANDLE;
		}
		else
			return true;
	}
	
	new String:szFile[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, szFile, sizeof( szFile ), PATH_ITEMS_DATA );
	if( !FileExists( szFile ) )
	{
		LogError( "Failed to open file '%s'!", PATH_ITEMS_DATA );
		return false;
	}
	
	hItemsData = CreateKeyValues( "items_data" );
	if( !FileToKeyValues( hItemsData, szFile ) )
	{
		CloseHandle( hItemsData );
		hItemsData = INVALID_HANDLE;
		LogError( "Failed to parse file '%s'!", PATH_ITEMS_DATA );
		return false;
	}
	
	return true;
}

stock GetTypeMLString( const String:szType[], String:szOutput[], iOutputLength )
{
	if( hItemsData != INVALID_HANDLE )
	{
		new Handle:hTypes = CreateKeyValues( "types" );
		KvRewind( hItemsData );
		KvCopySubkeys( hItemsData, hTypes );
		if( KvJumpToKey( hTypes, "types" ) && KvJumpToKey( hTypes, szType ) )
			KvGetString( hTypes, "name", szOutput, iOutputLength );
		CloseHandle( hTypes );
	}
	if( szOutput[0] == '\0' )
		strcopy( szOutput, iOutputLength, szType );
}

stock FindItemEx( iAdmin = 0, const String:szSearch[], String:szClassname[] = "", iClassnameLen = 0, String:szItemName[] = "", iItemNameLen = 0, String:szItemNameShort[] = "", iItemNameShortLen = 0, &bool:bItemNameIsML = false, &iMaxAmmo1 = 0, &iMaxAmmo2 = 0 )
{
	new String:szBuffer[21];
	new String:szItemClass[21];
	new nFoundItems;
	new bool:bNotAvaliable = false;
	new bool:bNoAccess = false;
	
	bItemNameIsML = false;
	
	if( hItemsData != INVALID_HANDLE )
	{
		KvRewind( hItemsData );
		if( KvJumpToKey( hItemsData, "items" ) && KvGotoFirstSubKey( hItemsData ) )
			do
			{
				KvGetString( hItemsData, "classname", szItemClass, sizeof( szItemClass ) );
				
				if( !strlen( szItemClass ) || StrContains( szItemClass, szSearch, false ) == -1 )
					continue;
				
				strcopy( szClassname, iClassnameLen, szItemClass );
				
				iMaxAmmo1 = KvGetNum( hItemsData, "max_ammo_prim", 0 );
				iMaxAmmo2 = KvGetNum( hItemsData, "max_ammo_sec", 0 );
				
				KvGetString( hItemsData, "name_ml", szItemName, iItemNameLen, "" );
				if( !strlen( szItemName ) )
				{
					KvGetString( hItemsData, "name", szItemName, iItemNameLen, "" );
					if( !strlen( szItemName ) )
					{
						bItemNameIsML = true;
						Format( szItemName, iItemNameLen, "Weapon_%s", szItemClass );
					}
				}
				else
					bItemNameIsML = true;
				
				KvGetString( hItemsData, "name_short", szItemNameShort, iItemNameShortLen, "" );
				if( !strlen( szItemNameShort ) )
					Format( szItemNameShort, iItemNameShortLen, "%s_short", szItemName );
				
				if( 0 < iAdmin <= MaxClients && IsClientInGame( iAdmin ) )
				{
					KvGetString( hItemsData, "type", szBuffer, sizeof( szBuffer ), "other" );
					Format( szBuffer, sizeof( szBuffer ), "sm_give_type_%s", szBuffer );
					if( !CheckCommandAccess( iAdmin, szBuffer, ADMFLAG_KICK, true ) )
					{
						bNoAccess = true;
						continue;
					}
					
					KvGetString( hItemsData, "category", szBuffer, sizeof( szBuffer ), "other" );
					Format( szBuffer, sizeof( szBuffer ), "sm_give_category_%s", szBuffer );
					if( !CheckCommandAccess( iAdmin, szBuffer, ADMFLAG_KICK, true ) )
					{
						bNoAccess = true;
						continue;
					}
				}
				
				nFoundItems++;
			}
			while( KvGotoNextKey( hItemsData ) );
	}
	else
	{
		LogMessage( "Items data isn't loaded!" );
		
		if( strlen( szSearch ) < 4 || !(
			StrContains( szSearch, "fa_", true ) == 0
			|| StrContains( szSearch, "me_", true ) == 0
			|| StrContains( szSearch, "item_", true ) == 0
			|| StrContains( szSearch, "tool_", true ) == 0
		) )
			return FindItem_InvalidArg;
		
		strcopy( szClassname, iClassnameLen, szSearch );
		
		nFoundItems++;
	}
	
	if( nFoundItems == 0 )
	{
		if( bNotAvaliable )
			return FindItem_NotAvaliable;
		else if( bNoAccess )
			return FindItem_NoAccess;
		else
			return FindItem_FoundNothing;
	}
	
	return nFoundItems;
}