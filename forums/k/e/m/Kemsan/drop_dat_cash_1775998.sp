#include <sourcemod> 
#include <sdktools>
#include <sdkhooks>

//=========== [ DEFINES ] =================

//[ SOUNDS ]
#define CASH_SOUND "ui/credits_updated.wav"

//[ MODELS ]
#define CASH_SMALL "models/items/currencypack_small.mdl"
#define CASH_MEDIUM "models/items/currencypack_medium.mdl"
#define CASH_LARGE "models/items/currencypack_large.mdl"

//[ PLUGIN ]
#define PLUGIN_NAME "[TF2] Dosh, money!"
#define PLUGIN_AUTHOR "Kemsan"
#define PLUGIN_DESCRIPTION "Drop that money!"
#define PLUGIN_VERSION "1,0"
#define PLUGIN_URL "http://kemsan.com.pl"

//=========== [ VARIABLES ] =================

//[ MAIN ]
new iCash[ 2048 ] = 0;
new bool:bBlocked[ 33 ] = false;

//[ CVARS ]
new Handle:g_hAdTimer = INVALID_HANDLE;
new Handle:g_hDropAmount = INVALID_HANDLE;

//=========== [ PLUGIN INFO ] =================
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

//=========== [ PLUGIN EVENTS ] =================
public OnPluginStart()
{
	//Create version cvar
	CreateConVar( "mvm_drop_money_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	//Create cvar for info show timer
	g_hAdTimer = CreateConVar( "mvm_drop_money_info_timer", "90.0", "Info about drop timer", FCVAR_PLUGIN | FCVAR_REPLICATED, true, 1.0 );
	
	//Create cvar for amount of dosh dropped by player
	g_hDropAmount = CreateConVar( "mvm_drop_money_amount", "50", "<= 50.0 - cash small, <= 100 - cash medium, <= 200 cash large", FCVAR_PLUGIN | FCVAR_REPLICATED, true, 1.0 );
	
	//Precache model - for reload only
	OnPrecache( );
	
	//Create info timer 
	CreateTimer( GetConVarFloat( g_hAdTimer ), Timer_ShowInfo, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT );
}


public OnClientPutInServer( iClient )
{
	//Unblock commmand
	bBlocked[ iClient ] = false;
}

public OnMapStart( )
{
	//Precache
	OnPrecache( )
}

public OnPrecache( )
{	
	//Preacache cash sound
	PrecacheSound( CASH_SOUND );
	
	//Precache cash model
	PrecacheModel( CASH_SMALL );
	PrecacheModel( CASH_MEDIUM );
	PrecacheModel( CASH_LARGE );
}

public OnDoshTouch( iEntity, iClient )
{
	//Check for vaild client
	if( IsValidClient( iClient ) )
	{	
		//Set user cash amount
		SetEntProp( iClient, Prop_Send, "m_nCurrency", GetEntProp( iClient, Prop_Send, "m_nCurrency" ) + iCash[ iEntity ] );
		
		//Check for valid candies entity
		if( IsValidEntity( iEntity ) )
		{	
			//Run sound 
			EmitSoundToClient( iClient, CASH_SOUND );
			
			//Remove candies ent
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
}

//=========== [ TIMERS ] =================
public Action:Timer_UnblockCommand( Handle:hTimer, any:iClient )
{
	//Check for valid client
	if( IsValidClient( iClient ) )
	{
		//Unblock command 
		bBlocked[ iClient ] = false;
	}
}

public Action:Timer_ShowInfo( Handle:hTimer, any:iSomething )
{
	//Print message to all 
	PrintToChatAll( "\x07%06X[MVM] \x07%06XClick mouse second button + reload to share your cash with someone!", 0xc14000, 0xFFD700 );
}

//=========== [ DOSH ] =================
public OnGameFrame( )
{
	//Loop thru all players 
	for( new iClient = 1; iClient < 32; iClient++ )
	{
			//Check for valid client 
		if( IsValidClient( iClient ) && GetClientTeam( iClient ) > 1 && GetEntProp( iClient, Prop_Send, "m_nCurrency" ) > 0 && ( GetClientButtons( iClient ) & IN_RELOAD ) && ( GetClientButtons( iClient ) & IN_ATTACK2 ) && !bBlocked[ iClient ] )
		{
			//Drop his money - now!
			SpawnDosh( GetConVarInt( g_hDropAmount ) >= 200 ? CASH_LARGE : GetConVarInt( g_hDropAmount ) >= 100 ? CASH_MEDIUM : CASH_SMALL, iClient );
			
			//Block command for 0.25sec 
			bBlocked[ iClient ] = true;
			
			//Unblock command after 0.25 sec
			CreateTimer( 0.25, Timer_UnblockCommand, iClient );
		}
	}
}

stock SpawnDosh( const String:strModel[], iClient, const iColor[ 3 ] = {255, ...} )
{
	//Get amount of cash
	new iAmount = GetEntProp( iClient, Prop_Send, "m_nCurrency" ) >= GetConVarInt( g_hDropAmount ) ? GetConVarInt( g_hDropAmount ) : GetEntProp( iClient, Prop_Send, "m_nCurrency" );
	
	//Declare some variabes
	decl Float:fPos[ 3 ];
	decl Float:fPlayerAngle[ 3 ];
	decl Float:fPlayerPosEx[ 3 ];
	decl Float:fPlayerPosAway[ 3 ];
	decl Float:fDirection[ 3 ];
	
	//Create new physics ent
	new iEnt = CreateEntityByName( "item_currencypack_custom" );
	
	//Add output for player touch
	DispatchKeyValue( iEnt, "OnPlayerTouch", "!self,Kill,0,,-1" );
	
	//Set entity model
	SetEntityModel( iEnt, strModel );
	
	//Check for valid ent
	if( IsValidEntity( iEnt ) )
	{   
		//Get client abs origin
		GetClientAbsOrigin( iClient, fPos );
		
		//Get client angles
		GetClientEyeAngles( iClient, fPlayerAngle );
		
		//Incrase position
		fPos[ 2 ] += 4;
		
		//Calc extended position 
		fPlayerPosEx[ 0 ] = Cosine( ( fPlayerAngle[ 1 ] / 180 ) * FLOAT_PI );
		fPlayerPosEx[ 1 ] = Sine( ( fPlayerAngle[ 1 ] / 180 ) * FLOAT_PI );
		fPlayerPosEx[ 2 ] = 0.0;
		
		//Scale extended position vector
		ScaleVector( fPlayerPosEx, 75.0 );
		
		//Add vectors - player position, extended position
		AddVectors( fPos, fPlayerPosEx, fPlayerPosAway );
		
		//Make new trace ray filter
		new Handle:hTraceEx = TR_TraceRayFilterEx( fPos, fPlayerPosAway, MASK_SOLID, RayType_EndPoint, ExTraceFilter );
		
		//Get trace end position
		TR_GetEndPosition( fPos, hTraceEx );
		
		//Close trace handle
		CloseHandle( hTraceEx );
		
		//Get player direction
		fDirection[ 0 ] = fPos[ 0 ];
		fDirection[ 1 ] = fPos[ 1 ];
		fDirection[ 2 ] = fPos[ 2 ] - 1024;
		
		//Make new trace ray filter
		new Handle:hTrace = TR_TraceRayFilterEx( fPos, fDirection, MASK_SOLID, RayType_EndPoint, ExTraceFilter );
		
		//Get trace end position
		TR_GetEndPosition( fPos, hTrace );
		
		//Close trace handle
		CloseHandle( hTrace );
		
		//Incrase position again
		fPos[ 2 ] += 4;
		
		//Set prop color
		SetEntityRenderColor( iEnt, iColor[0], iColor[1], iColor[2], 255 );
		
		//Teleport prop to new position
		TeleportEntity( iEnt, fPos, NULL_VECTOR, NULL_VECTOR );
		
		//Spawn ent
		DispatchSpawn( iEnt );	
		
		//Set entity model
		SetEntityModel( iEnt, strModel );
	}  
	else
	{
		LogError( "[ DOSH DROP ] Failed to drop da dosh ( %s, %d ) failed.", strModel, iClient );  
	}
	
	//Remove user money 
	SetEntProp( iClient, Prop_Send, "m_nCurrency", GetEntProp( iClient, Prop_Send, "m_nCurrency" ) - iAmount );
	
	//Set cash amount
	iCash[ iEnt ] = iAmount;
	
	//Add touch hook
	SDKHook( iEnt, SDKHook_Touch, OnDoshTouch );		
	
	//Return ent
	return iEnt;
}

//=============== [ STOCKS ] =====================
public bool:ExTraceFilter( iEnt, iContentMask )
{
	//Just return true..
	return iEnt > GetMaxClients() || !iEnt;
}

stock IsValidClient( iClient )
{
	//Check for client "ID"
	if  ( iClient <= 0 || iClient > MaxClients ) 
		return false;
	
	//Check for client is in game
	if ( !IsClientInGame( iClient ) ) 
		return false;
	
	//Declare variables to check player-replay
	decl String:strAdminName[32];
	decl String:strName[32];
	new AdminId:mAdmin;
	
	//Get client name
	GetClientName( iClient, strName, sizeof( strName ) );
	
	//Check player name = "replay" and check for fake client
	if ( strcmp( strName, "replay", false ) == 0 && IsFakeClient( iClient ) ) 
		return false;
	
	//Check for replay admin immunitet
	if ( ( mAdmin = GetUserAdmin( iClient ) ) != INVALID_ADMIN_ID )
	{
		//Get admin name
		GetAdminUsername( mAdmin, strAdminName, sizeof( strAdminName ) );
		
		//Check for admin-replay name = "Replay"
		if ( strcmp( strAdminName, "Replay", false ) == 0 ) 
			return false;
	}
	
	return true;
}