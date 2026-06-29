#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <dhooks>

Handle g_hProcessMovementHookPre;
Handle g_hProcessMovementHookPost;

int g_iFrametimeOffset;

float g_fFrametime[MAXPLAYERS + 1];
float g_fOldFrametime[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegAdminCmd( "sm_frametime", Command_SetFrametime, ADMFLAG_ROOT );

	Handle hGameData = LoadGameConfigFile( "frametime_changer.games" );
	if( hGameData == null )
	{
		LogError( "Failed to load frametime_changer.games.txt gamedata for CCSGameMovement::ProcessMovement hook." );
		return;
	}

	Address pGameMovement = GameConfGetAddress( hGameData, "g_pGameMovement" );
	if ( pGameMovement == Address_Null )
	{
		LogError( "Failed to find g_pGameMovement address" );
		return;
	}

	int iOffset = GameConfGetOffset( hGameData, "CCSGameMovement::ProcessMovement" );
	if( iOffset == -1 )
	{
		LogError( "Can't find CCSGameMovement::ProcessMovement offset in gamedata." );
		return;
	}
	
	g_iFrametimeOffset = GameConfGetOffset( hGameData, "Frametime_Offset" );
	if( g_iFrametimeOffset == -1 )
	{
		LogError( "Can't find frametime offset in gamedata." );
		return;
	}
	
	delete hGameData;
	
	g_hProcessMovementHookPre = DHookCreate( iOffset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, DHooks_OnProcessMovementPre );
	if( g_hProcessMovementHookPre == null )
	{
		LogError( "Failed to create CCSGameMovement::ProcessMovement hook." );
		return;
	}

	DHookAddParam( g_hProcessMovementHookPre, HookParamType_CBaseEntity );
	DHookAddParam( g_hProcessMovementHookPre, HookParamType_ObjectPtr );
	DHookRaw( g_hProcessMovementHookPre, false, pGameMovement );
	
	g_hProcessMovementHookPost = DHookCreate( iOffset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, DHooks_OnProcessMovementPost );
	if( g_hProcessMovementHookPost == null )
	{
		LogError( "Failed to create CCSGameMovement::ProcessMovement hook." );
		return;
	}

	DHookAddParam( g_hProcessMovementHookPost, HookParamType_CBaseEntity );
	DHookAddParam( g_hProcessMovementHookPost, HookParamType_ObjectPtr );
	DHookRaw( g_hProcessMovementHookPost, true, pGameMovement );
}

public void OnMapStart()
{
	Address gpGlobals = GetGlobalVarsAddress();
	float frametime = view_as<float>( LoadFromAddress( gpGlobals + view_as<Address>( g_iFrametimeOffset ), NumberType_Int32 ) );
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_fFrametime[i] = frametime; // set to the default frametime.
	}
}

Address GetGlobalVarsAddress()
{
	static Address p_gpGlobals; // pointer to gpGlobals

	if( p_gpGlobals == Address_Null )
	{
		Handle hGameData = LoadGameConfigFile( "frametime_changer.games" );
		if( hGameData == null )
		{
			LogError( "Failed to load frametime_changer.games.txt gamedata for CCSGameMovement::ProcessMovement hook." );
			return Address_Null;
		}

		p_gpGlobals = GameConfGetAddress( hGameData, "gpGlobals" );
		if ( p_gpGlobals == Address_Null )
		{
			LogError( "Failed to find gpGlobals address" );
			return Address_Null;
		}
	}
	
	return view_as<Address>( LoadFromAddress( p_gpGlobals, NumberType_Int32 ) );
}

public MRESReturn DHooks_OnProcessMovementPre( Handle hParams )
{
	int client = DHookGetParam( hParams, 1 );

	Address gpGlobals = GetGlobalVarsAddress();
	g_fOldFrametime[client] = view_as<float>( LoadFromAddress( gpGlobals + view_as<Address>( g_iFrametimeOffset ), NumberType_Int32 ) );
	StoreToAddress( gpGlobals + view_as<Address>( g_iFrametimeOffset ), view_as<int>( g_fFrametime[client] ), NumberType_Int32 );
	
	return MRES_Ignored;
}

public MRESReturn DHooks_OnProcessMovementPost( Handle hParams )
{
	int client = DHookGetParam( hParams, 1 );

	Address gpGlobals = GetGlobalVarsAddress();
	StoreToAddress( gpGlobals + view_as<Address>( g_iFrametimeOffset ), view_as<int>( g_fOldFrametime[client] ), NumberType_Int32 );
	
	return MRES_Ignored;
}

public Action Command_SetFrametime( int client, int args )
{
	if( args == 1 )
	{
		char sFrametime[32];
		GetCmdArgString( sFrametime, sizeof( sFrametime ) );
		
		float frametime = StringToFloat( sFrametime );
		if( frametime > 0.0 )
		{
			g_fFrametime[client] = frametime;
		}
	}
	
	return Plugin_Handled;
}