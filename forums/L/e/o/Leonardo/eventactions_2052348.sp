#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "0.2.0a-20131024"

#define ERROR_NONE		0		// PrintToServer only
#define ERROR_LOG		(1<<0)	// use LogToFile
#define ERROR_BREAKF	(1<<1)	// use ThrowError
#define ERROR_BREAKN	(1<<2)	// use ThrowNativeError
#define ERROR_BREAKP	(1<<3)	// use SetFailState
#define ERROR_NOPRINT	(1<<4)	// don't use PrintToServer

new Handle:sm_event_action_version = INVALID_HANDLE;
new Handle:sm_ea_enabled = INVALID_HANDLE;
new Handle:sm_ea_logs = INVALID_HANDLE;
new Handle:sm_ea_debug = INVALID_HANDLE;

new bool:bEnabled = false;
new bool:bUseLogs = false;
new bool:bDebug = false;

new String:strConfigFile[PLATFORM_MAX_PATH];
new String:strEventHookModes[_:EventHookMode][] = { "Pre", "Post", "PostNoCopy" };
new Function:fEventHookCallbacks[_:EventHookMode] = { EventHook_Pre, EventHook_Post, EventHook_PostNoCopy };

new Handle:hEventActions = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "[DEV] Event Actions",
	author = "Leonardo",
	description = "Do actions based on events",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
}


public OnPluginStart()
{
	sm_event_action_version = CreateConVar( "sm_event_actions_version", PLUGIN_VERSION, "[DEV] Event Actions plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	SetConVarString( sm_event_action_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_event_action_version, OnConVarChanged_Version );
	
	HookConVarChange( sm_ea_enabled = CreateConVar( "sm_ea_enabled", bEnabled?"1":"0", _, FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( sm_ea_logs = CreateConVar( "sm_ea_logs", bUseLogs?"1":"0", _, FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( sm_ea_debug = CreateConVar( "sm_ea_debug", bDebug?"1":"0", _, FCVAR_PLUGIN ), OnConVarChanged );
	
	BuildPath( Path_SM, strConfigFile, sizeof( strConfigFile ), "data/eventactions.cfg" );
	
	LoadConfigFile();
	
	RegAdminCmd( "sm_ea_reload", Command_ReloadConfig, ADMFLAG_ROOT, "Usage: sm_ea_reload" );
}


public OnConfigsExecuted()
{
	bEnabled = GetConVarBool( sm_ea_enabled );
	bUseLogs = GetConVarBool( sm_ea_logs );
	bDebug = GetConVarBool( sm_ea_debug );
}
public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();
public OnConVarChanged_Version( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( !StrEqual( strNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );


public Action:Command_ReloadConfig( iClient, nArgs )
{
	LoadConfigFile();
	ReplyToCommand( iClient, "[DevEA] Done." );
	return Plugin_Handled;
}


public Action:EventHook_Pre( Handle:hEvent, const String:strEventName[], bool:bNoBroadcast )
{
	if( EventHandler( hEvent, strEventName, EventHookMode_Pre ) )
		return Plugin_Continue;
	else
		return Plugin_Handled;
}
public EventHook_Post( Handle:hEvent, const String:strEventName[], bool:bNoBroadcast )
	EventHandler( hEvent, strEventName, EventHookMode_Post );
public EventHook_PostNoCopy( Handle:hEvent, const String:strEventName[], bool:bNoBroadcast )
	EventHandler( hEvent, strEventName, EventHookMode_PostNoCopy );



bool:EventHandler( &Handle:hEvent, const String:strEventName[], EventHookMode:nHookMode )
{
	new bool:bReturn = true;
	
	if( !bEnabled )
		return bReturn;
	
	KvRewind( hEventActions );
	if( !KvJumpToKey( hEventActions, strEventName ) )
	{
		Error( _, ERROR_LOG, "Unexpected event hook: %s (EventHookMode_*)", strEventName );
		return bReturn;
	}
	else if( !KvJumpToKey( hEventActions, strEventHookModes[_:nHookMode] ) )
	{
		Error( _, ERROR_LOG, "Unexpected event hook: %s (EventHookMode_%s)", strEventName, strEventHookModes[_:nHookMode] );
		return bReturn;
	}
	
	if( bDebug )
		Error( _, ERROR_LOG, "Event %s (EventHookMode_%s) fired!", strEventName, strEventHookModes[_:nHookMode] );
	
	if( nHookMode != EventHookMode_Pre )
	{
		// hide your sticks and baseball bats, psychonic said
		// we can (re-)define new variables under cycles.
		new bHideEvent = KvGetNum( hEventActions, "hide", -1 );
		if( bHideEvent == 2 )
		{
			SetEventBroadcast( hEventActions, true );
			bReturn = false;
		}
		else if( 0 <= bHideEvent <= 1 )
			SetEventBroadcast( hEventActions, !(bool:bHideEvent) );
	}
	
	decl String:strBuffer[512];
	
	KvGetString( hEventActions, "sv_cmd", strBuffer, sizeof( strBuffer ), "" );
	if( strlen( strBuffer ) )
		ServerCommand( strBuffer );
	
	KvGetString( hEventActions, "cl_field", strBuffer, sizeof( strBuffer ), "" );
	if( strlen( strBuffer ) )
	{
		new iClient = -1;
		
		new iFieldType = KvGetNum( hEventActions, "cl_fieldtype", -1 );
		if( iFieldType == 1 )
			iClient = GetClientOfUserId( GetEventInt( hEvent, strBuffer ) );
		else if( iFieldType == 2 )
		{
			iClient = GetEventInt( hEvent, strBuffer );
			if( IsValidClient( iClient ) )
				iClient = GetClientUserId( iClient );
			else
				iClient = -1;
		}
		else //if( iFieldType == 0 )
			iClient = GetEventInt( hEvent, strBuffer );
		
		if( IsValidClient( iClient ) || iFieldType == 2 && iClient > -1 )
		{
			KvGetString( hEventActions, "cl_cmd", strBuffer, sizeof( strBuffer ), "" );
			if( strlen( strBuffer ) )
			{
				new iCmdType = KvGetNum( hEventActions, "cl_cmdtype", 0 );
				if( iCmdType == 2 )
					ClientCommand( iClient, strBuffer );
				else if( iCmdType == 1 )
					FakeClientCommandEx( iClient, strBuffer );
				else
					FakeClientCommand( iClient, strBuffer );
			}
		}
	}
	
	return bReturn;
}



LoadConfigFile()
{
	decl String:strEventName[128]; // I'm not sure about this string size
	
	if( hEventActions != INVALID_HANDLE )
	{
		KvRewind( hEventActions );
		if( KvGotoFirstSubKey( hEventActions ) )
			do
			{
				KvGetSectionName( hEventActions, strEventName, sizeof( strEventName ) );
				for( new m = 0; m < _:EventHookMode; m++ )
					if( KvJumpToKey( hEventActions, strEventHookModes[m] ) )
					{
						if( KvGetNum( hEventActions, "hooked", 0 ) > 0 )
							UnhookEvent( strEventName, fEventHookCallbacks[m], EventHookMode:m );
						KvGoBack( hEventActions );
					}
			}
			while( KvGotoNextKey( hEventActions ) );
		CloseHandle( hEventActions );
	}
	hEventActions = CreateKeyValues( "event_actions_v1" );
	
	if( !FileExists( strConfigFile ) )
		if( KeyValuesToFile( hEventActions, strConfigFile ) )
			Error( _, _, "Config file created." );
		else
		{
			Error( _, ERROR_LOG, "Unable to create config file!" );
			return;
		}
	else if( !FileToKeyValues( hEventActions, strConfigFile ) )
	{
		Error( _, ERROR_LOG, "Unable to read config file!" );
		return;
	}
	
	KvRewind( hEventActions );
	if( KvGotoFirstSubKey( hEventActions ) )
		do
		{
			KvGetSectionName( hEventActions, strEventName, sizeof( strEventName ) );
			for( new m = 0; m < _:EventHookMode; m++ )
				if( KvJumpToKey( hEventActions, strEventHookModes[m] ) )
				{
					if( KvGetNum( hEventActions, "hook", 1 ) == 1 )
					{
						if( HookEventEx( strEventName, fEventHookCallbacks[m], EventHookMode:m ) )
						{
							KvSetNum( hEventActions, "hooked", 1 );
							
							if( EventHookMode:m != EventHookMode_Pre && KvGetNum( hEventActions, "hide", -1 ) > -1 )
								Error( _, ERROR_LOG, "%s (%s): only EventHookMode_Pre hooked events can be removed from broadcast!", strEventName, strEventHookModes[m] );
							
							if( bDebug )
								Error( _, ERROR_LOG, "Event %s (EventHookMode_%s) hooked!", strEventName, strEventHookModes[m] );
						}
						else
							Error( _, ERROR_LOG, "Failed to hook event %s (EventHookMode_%s)!", strEventName, strEventHookModes[m] );
					}
					else if( bDebug )
						Error( _, ERROR_LOG, "Event %s (EventHookMode_%s) skipped due to settings.", strEventName, strEventHookModes[m] );
					KvGoBack( hEventActions );
				}
		}
		while( KvGotoNextKey( hEventActions ) );
}



stock bool:IsValidClient( iClient )
	return 0 <= iClient <= MaxClients && IsClientInGame( iClient );

stock Error( iFlags = ERROR_NONE, iNativeErrCode = SP_ERROR_NONE, const String:strMessage[], any:... )
{
	decl String:strBuffer[1024];
	VFormat( strBuffer, sizeof(strBuffer), strMessage, 4 );
	
	if( iFlags )
	{
		if( iFlags & ERROR_LOG && bUseLogs )
		{
			decl String:strFile[PLATFORM_MAX_PATH];
			FormatTime( strFile, sizeof(strFile), "%Y%m%d" );
			Format( strFile, sizeof(strFile), "DevEA%s", strFile );
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
	
	PrintToServer( "[DevEA] %s", strBuffer );
}