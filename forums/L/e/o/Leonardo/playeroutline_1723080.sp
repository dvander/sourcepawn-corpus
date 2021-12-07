#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.1.1"
#define NOTIFY_TAG "[SM]"

new Handle:sm_outline_version = INVALID_HANDLE;
new Handle:sm_outline_enabled = INVALID_HANDLE;
new Handle:sm_outline_notify = INVALID_HANDLE;
new Handle:sm_outline_logs = INVALID_HANDLE;
new Handle:sm_outline_forall = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:hCookie = INVALID_HANDLE;

new bool:bPluginEnabled = true;
new bool:bNotifyEnabled = true;
new bool:bLogsEnabled = false;
new bool:bEnabledForAll = false;

new bool:bOutlineActive[MAXPLAYERS+1] = { false, ... };
new bool:bSupportsGlows = false;

public Plugin:myinfo =
{
	name = "Player Outline",
	author = "ReFlexPoison (edit by Leonardo)",
	description = "Enable/Disable Player Outlines (Based on HP Pull)",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=186806"
}

public OnPluginStart()
{
	LoadTranslations( "common.phrases" );

	sm_outline_version = CreateConVar( "sm_outline_version", PLUGIN_VERSION, "Player Outline Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD );
	SetConVarString( sm_outline_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_outline_version, OnConVarChanged_PluginVersion );

	sm_outline_enabled = CreateConVar("sm_outline_enabled", bPluginEnabled?"1":"0", "Enable Player Outline\n0=Disabled\n1=Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange( sm_outline_enabled, OnConVarChanged );
	
	sm_outline_notify = CreateConVar("sm_outline_notify", bNotifyEnabled?"1":"0", "Enable Notifications of Player Outline Toggles in Chat\n0=Disabled\n1=Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange( sm_outline_notify, OnConVarChanged );
	
	sm_outline_logs = CreateConVar("sm_outline_logs", bLogsEnabled?"1":"0", "Enable Logs of Player Outline Toggles\n0=Disabled\n1=Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange( sm_outline_logs, OnConVarChanged );
	
	sm_outline_forall = CreateConVar("sm_outline_forall", bEnabledForAll?"1":"0", "Enable Logs of Player Outline Toggles\n0=Disabled\n1=Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange( sm_outline_forall, OnConVarChanged );

	RegConsoleCmd( "sm_outlineon", CmdOutline, "Usage: sm_outlineon [targets]" );
	RegConsoleCmd( "sm_outlineoff", CmdOutline, "Usage: sm_outlineoff [targets]" );
	RegConsoleCmd( "sm_outlinetoggle", CmdOutline, "Usage: sm_outlinetoggle [targets]" );
	RegConsoleCmd( "sm_outline", CmdSetOutline, "Usage: sm_outline [targets] [0/1]" );
	
	hCookie = RegClientCookie( "outline_state", "", CookieAccess_Private );
	
	HookEvent( "player_activate", Event_PlayerActivate, EventHookMode_Post );

	AutoExecConfig( true, "plugin.playeroutlines" );
}

public OnAllPluginLoaded()
{
	new Handle:hTopMenu;
	if( LibraryExists("adminmenu") && ( hTopMenu = GetAdminTopMenu() ) != INVALID_HANDLE )
		OnAdminMenuReady( hTopMenu );
}

public OnLibraryRemoved( const String:strLibraryName[] )
	if( strcmp( strLibraryName, "adminmenu") == 0 )
		hAdminMenu = INVALID_HANDLE;

public OnConfigsExecuted()
{
	bPluginEnabled = GetConVarBool( sm_outline_enabled );
	bNotifyEnabled = GetConVarBool( sm_outline_notify );
	bLogsEnabled = GetConVarBool( sm_outline_logs );
	bEnabledForAll = GetConVarBool( sm_outline_forall );
}

public OnGameFrame()
{
	if( !bPluginEnabled )
		return;
	
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
		if( IsValidClient(iClient) )
		{
			if( !bSupportsGlows )
			{
				decl String:strNetClass[16];
				GetEntityNetClass( iClient, strNetClass, sizeof(strNetClass) );
				bSupportsGlows = FindSendPropOffs( strNetClass, "m_bGlowEnabled" ) != -1;
				if( !bSupportsGlows )
					SetFailState( "This game/mod doesn't support %s::m_bGlowEnabled", strNetClass );
			}
			
			SetEntProp( iClient, Prop_Send, "m_bGlowEnabled", IsPlayerAlive(iClient) && ( bOutlineActive[iClient] || bEnabledForAll ) );
		}
}

public Action:CmdOutline( iClient, nArgs )
{
	decl String:strCommand[16];
	GetCmdArg( 0, strCommand, sizeof(strCommand) );
	
	if( nArgs )
	{
		if( !CheckCommandAccess( iClient, "sm_outline_target", ADMFLAG_GENERIC ) )
		{
			ReplyToCommand( iClient, "%s %t.", NOTIFY_TAG, "No Access" );
			return Plugin_Handled;
		}
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		decl String:targets[65];
		GetCmdArg( 1, targets, sizeof(targets) );
		if((target_count = ProcessTargetString(targets, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError( iClient, target_count);
			return Plugin_Handled;
		}
		
		for(new i = 0; i < target_count; i++)
			if( IsValidClient( target_list[i] ) )
			{
				SetOutlineState( target_list[i], ( strcmp(strCommand,"sm_outlineon",false)==0 ? 1 : ( strcmp(strCommand,"sm_outlineoff",false)==0 ? 0 : -1 ) ) );
				LogClientAction( iClient, target_list[i] );
			}
		
		ReplyToCommand( iClient, "Done." );
		return Plugin_Handled;
	}
	else if( IsValidClient( iClient ) )
	{
		SetOutlineState( iClient, ( strcmp(strCommand,"sm_outlineon",false)==0 ? 1 : ( strcmp(strCommand,"sm_outlineoff",false)==0 ? 0 : -1 ) ) );
		LogClientAction( iClient, iClient );
		return Plugin_Handled;
	}
	else if( iClient == 0 )
	{
		ReplyToCommand( iClient, "Usage: %s [targets]", strCommand );
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:CmdSetOutline( iClient, nArgs )
{
	decl String:strCommand[16];
	GetCmdArg( 0, strCommand, sizeof(strCommand) );
	
	if( nArgs >= 2 )
	{
		if( !CheckCommandAccess( iClient, "sm_outline_target", ADMFLAG_GENERIC ) )
		{
			ReplyToCommand( iClient, "%s %t.", NOTIFY_TAG, "No Access" );
			return Plugin_Handled;
		}
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		decl String:targets[65];
		GetCmdArg( 1, targets, sizeof(targets) );
		if((target_count = ProcessTargetString(targets, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError( iClient, target_count);
			return Plugin_Handled;
		}
		
		decl String:strState[4], iState;
		GetCmdArg( 2, strState, sizeof(strState) );
		if( IsCharNumeric(strState[0]) )
			iState = StringToInt(strState);
		else
			iState = -1;
		if( iState < 0 ) iState = -1;
		if( iState > 1 ) iState = 1;
		
		for(new i = 0; i < target_count; i++)
			if( IsValidClient( target_list[i] ) )
			{
				SetOutlineState( target_list[i], iState );
				LogClientAction( iClient, target_list[i] );
			}
		
		ReplyToCommand( iClient, "Done." );
		return Plugin_Handled;
	}
	else if( IsValidClient( iClient ) )
	{
		if( nArgs == 1 )
		{
			decl String:strState[4];
			GetCmdArg( 1, strState, sizeof(strState) );
			if( !IsCharNumeric(strState[0]) )
			{
				if(!CheckCommandAccess(iClient, "sm_outline_target", ADMFLAG_GENERIC))
				{
					ReplyToCommand( iClient, "%s %t.", NOTIFY_TAG, "No Access" );
					return Plugin_Handled;
				}
				
				decl String:target_name[MAX_TARGET_LENGTH];
				decl target_list[MAXPLAYERS];
				decl target_count;
				decl bool:tn_is_ml;
				decl String:targets[65];
				GetCmdArg( 1, targets, sizeof(targets) );
				if((target_count = ProcessTargetString(targets, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
				{
					ReplyToTargetError( iClient, target_count);
					return Plugin_Handled;
				}
				
				for(new i = 0; i < target_count; i++)
					if( IsValidClient( target_list[i] ) )
					{
						SetOutlineState( target_list[i] );
						LogClientAction( iClient, target_list[i] );
					}
				
				return Plugin_Handled;
			}
			new bool:bState = !!StringToInt(strState);
			SetOutlineState( iClient, _:bState );
			LogClientAction( iClient, iClient );
		}
		else
		{
			SetOutlineState( iClient );
			LogClientAction( iClient, iClient );
		}
		return Plugin_Handled;
	}
	else if( iClient == 0 )
	{
		ReplyToCommand( iClient, "Usage: %s [targets] [0/1]", strCommand );
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

public Event_PlayerActivate( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt(hEvent, "userid") );
	if( !IsValidClient(iClient) )
		return;
	
	if( IsFakeClient(iClient) )
	{
		SetOutlineState( iClient, 0 );
		return;
	}
	
	decl String:strState[4];
	GetClientCookie( iClient, hCookie, strState, sizeof(strState) );
	
	new iState = 0;
	if( IsCharNumeric(iState) )
		iState = StringToInt(strState);
	if( iState < 0 ) iState = 0;
	if( iState > 1 ) iState = 1;
	
	SetOutlineState( iClient, iState );
}

//////////////
//ADMIN MENU//
//////////////

public OnAdminMenuReady( Handle:hTopMenu )
{
	if( hTopMenu == hAdminMenu )
		return;
	hAdminMenu = hTopMenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory( hAdminMenu, ADMINMENU_PLAYERCOMMANDS );
	if( player_commands != INVALID_TOPMENUOBJECT )
		AddToTopMenu( hAdminMenu, "sm_outline", TopMenuObject_Item, AdminMenu_Outline, player_commands, "sm_outline_target", ADMFLAG_GENERIC );
}

public AdminMenu_Outline( Handle:hTopMenu, TopMenuAction:action, TopMenuObject:object_id, iCaller, String:strBuffer[], iBufferLength )
	if(action == TopMenuAction_DisplayOption)
		Format( strBuffer, iBufferLength, "Outline Glow Player" );
	else if( action == TopMenuAction_SelectOption )
		DisplayOutlineMenu( iCaller );

public MenuHandler_Outline(Handle:menu, MenuAction:action, iClient, iItem)
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( iItem == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu( hAdminMenu, iClient, TopMenuPosition_LastCategory );
	}
	else if(action == MenuAction_Select)
	{
		decl String:strSelection[16];
		GetMenuItem(menu, iItem, strSelection, sizeof(strSelection));
		new iTarget = GetClientOfUserId( StringToInt(strSelection) );
		if( !IsValidClient( iTarget ) )
			PrintToChat( iClient, "%s %t", NOTIFY_TAG, "Player no longer available" );
		else 
		{
			if( !CanUserTarget( iClient, iTarget ) )
				PrintToChat( iClient, "%s %t", NOTIFY_TAG, "Unable to target" );
			else
			{
				SetOutlineState( iTarget );
				LogClientAction( iClient, iTarget );
				
				if( IsValidClient( iClient ) )
					DisplayOutlineMenu( iClient );
			}
		}
	}

DisplayOutlineMenu( iCaller )
{
	new Handle:hMenu = CreateMenu( MenuHandler_Outline );

	SetMenuTitle( hMenu, "Outline Player:" );
	SetMenuExitBackButton( hMenu, true );

	AddTargetsToMenu( hMenu, iCaller, true, false );

	DisplayMenu( hMenu, iCaller, MENU_TIME_FOREVER );
}

//////////
//STOCKS//
//////////

stock LogClientAction( iClient, iTarget )
{
	if( !( iClient == 0 || IsValidClient( iClient ) ) )
		return;
	if( !IsValidClient(iTarget) )
		return;
	
	if( bLogsEnabled )
		LogAction( iClient, iTarget, "%s \"%L\" outline glow for \"%L\"", NOTIFY_TAG, ( bOutlineActive[ iTarget ] ? "Enabled" : "Disabled" ), iTarget );
	
	if( bNotifyEnabled )
		ShowActivity2( iClient, NOTIFY_TAG, " %s outline glow for %N", ( bOutlineActive[ iTarget ] ? "Enabled" : "Disabled" ), iTarget );
}

stock bool:SetOutlineState( iClient, iNewState = -1 )
{
	if( iClient <= 0 || iClient > MaxClients )
		return false;
	
	if( iNewState >= 0 && iNewState <= 1 )
		bOutlineActive[ iClient ] = bool:iNewState;
	else
		bOutlineActive[ iClient ] = !bOutlineActive[ iClient ];
	
	if( !IsFakeClient( iClient ) )
	{
		decl String:strState[4];
		IntToString( _:bOutlineActive[ iClient ], strState, sizeof(strState) );
		SetClientCookie( iClient, hCookie, strState );
	}
	
	return bOutlineActive[iClient];
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	if( !IsClientInGame(iClient) ) return false;
	return !IsClientInKickQueue(iClient);
}