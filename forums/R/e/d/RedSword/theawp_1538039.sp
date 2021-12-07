#include <cstrike>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	"1.1.0"

public Plugin:myinfo = 
{
	name = "The AWP - Single AWP Gameplay",
	author = "RedSword / Bob Le Ponge",
	description = "Allows a single AWP in the whole map at all time.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Defines
#define	AWP_ENT_STR		"weapon_awp"
#define	AWP_WPN_STR		"awp"
#define	CS_SLOT_KNIFE	2

//=====ConVars
new Handle:g_hEnable;
new Handle:g_hMinPlayers;

//verbose
new Handle:g_hVerbosePrefix;
new Handle:g_hVerbose_Acquire;
new Handle:g_hVerbose_AcquireDelay;

//=====Variables
new Float:g_fVerboseLastAcquire = 0.0;

//=====Forwards=====

public OnPluginStart()
{
	//=====ConVars
	//Version
	CreateConVar( "theawpversion", PLUGIN_VERSION, "The AWP - Single AWP Gameplay version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	//Options
	g_hEnable = CreateConVar( "theawp", "1", "Is the plugin enabled ? 0=No, 1=Yes. Def. 1", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hMinPlayers = CreateConVar( "theawp_minplayers", "8", "Minimum number of players needed to have the plugin enabled ? Def. 8", 
		FCVAR_PLUGIN, true, 0.0 );
	
	//Verboses
	g_hVerbosePrefix = CreateConVar( "theawp_verbose_prefix", "[TheAWP]", "Prefix to the verboses' phrases used by this plugin.", 
		FCVAR_PLUGIN );
	g_hVerbose_Acquire = CreateConVar( "theawp_verbose_acquire", "1.0", "Display to other players when a player acquire the AWP. 0=No, 1=Yes. Default 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hVerbose_AcquireDelay = CreateConVar( 
		"theawp_verbose_acquire_delay", "7.5", "Delay in seconds between two verboses' phrases concerning acquiring the AWP. Prevent abuse. Default 7.5s.", 
		FCVAR_PLUGIN, true, 0.0 );
	
	//=====Config
	AutoExecConfig( true, "theawp" );
	
	//=====Hook
	HookEvent( "item_pickup", Item_Pickup );
	
	//=====Translation
	LoadTranslations("theawp.phrases");
}

public OnMapStart()
{
	g_fVerboseLastAcquire = GetEngineTime( ) - GetConVarFloat( g_hVerbose_AcquireDelay );
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if ( !GetConVarBool(g_hEnable) )
		return Plugin_Continue;
	
	if ( !StrEqual(weapon, AWP_WPN_STR) )
		return Plugin_Continue;
	
	new bool:oneAWPexist = existXAWPs( 1 );
	if ( oneAWPexist || !hasEnoughPlayer( ) )
	{
		verboseCantAWP( client, oneAWPexist );
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

//=====Hook=====

public Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt(g_hEnable) == 1 )
	{
		decl String:szClassName[ MAX_NAME_LENGTH ];

		GetEventString( event, "item", szClassName, sizeof(szClassName) );
		
		new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		//if wpn awp is taken but there is already one on the map
		if ( StrEqual( szClassName, AWP_WPN_STR ) )
		{
			new bool:condAWPs = existXAWPs( 2 );
			if ( condAWPs || !hasEnoughPlayer( ) )
			{
				new iEntIndex = GetPlayerWeaponSlot( iClient, CS_SLOT_PRIMARY );
				//1- Strip
				RemovePlayerItem( iClient, iEntIndex ); 
				AcceptEntityInput( iEntIndex, "kill" );
				EquipPlayerWeapon( iClient, GetPlayerWeaponSlot( iClient, CS_SLOT_KNIFE ) );
				
				//2- Verbose
				verboseCantAWP( iClient, condAWPs );
			}
			else
			{
				if ( GetConVarInt( g_hVerbose_Acquire ) )
				{
					new Float:engineTime = GetEngineTime( );
					if ( g_fVerboseLastAcquire + GetConVarFloat( g_hVerbose_AcquireDelay ) < engineTime )
					{
						verboseIsAWPing( iClient );
						g_fVerboseLastAcquire = engineTime;
					}
				}
			}
		}
	}
	
	return bool:Plugin_Continue;
}

//=====Privates=====
bool:existXAWPs( nbAWPs )
{
	new awpCount;
	for ( new iEntIndex = ( MaxClients + 1 ); iEntIndex < GetMaxEntities( ); ++iEntIndex )
	{
		if ( IsValidEntity( iEntIndex ) )  
		{  
			decl String:szClassName[ MAX_NAME_LENGTH ];  
			GetEdictClassname( iEntIndex, szClassName, sizeof(szClassName) );
			if ( StrEqual( szClassName, AWP_ENT_STR ) )
				++awpCount;
			if ( awpCount == nbAWPs )
				return true;
		}
	}
	return false;
}

bool:hasEnoughPlayer()
{
	new playerCount;
	new playerCountGoal = GetConVarInt( g_hMinPlayers );
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) && GetClientTeam( i ) > 1 )  
		{  
			++playerCount;
		}
		if ( playerCount >= playerCountGoal )
			return true;
	}
	return false;
}

//=====Verbose=====

verboseCantAWP( iClient, bool:problemIsAWP )
{
	decl String:szBuffer[ 32 ];
	GetConVarString( g_hVerbosePrefix, szBuffer, sizeof(szBuffer) );
	
	if ( problemIsAWP )
	{
		decl String: szTeamName[ 32 ];
		
		getTeamNameConditionalLowerCase( getAWPTeam ( ), szTeamName, sizeof(szTeamName) );
		
		PrintToChat( iClient, "\x04%s \x01%t\x03%s\x01.", szBuffer, "One AWP", szTeamName );
	}
	else
	{
		PrintToChat( iClient, "\x04%s \x01%t", szBuffer, "Not enough players", "\x03", GetConVarInt( g_hMinPlayers ), "\x01" );
	}
}

verboseIsAWPing( iClient )
{
	decl String:szBuffer[ 32 ];
	GetConVarString( g_hVerbosePrefix, szBuffer, sizeof(szBuffer) );
	
	for ( new i = 1; i <= MaxClients; ++i )
		if ( IsClientInGame( i ) && i != iClient )
			PrintToChat( i, "\x04%s \x01%t", szBuffer, "Has AWP", "\x03", iClient, "\x01" );
}

//verbose privates

getTeamNameConditionalLowerCase( any:teamId, String:szBuffer[ ], any:size )
{
	//Team name
	if ( teamId > 1 )
	{
		GetTeamName( teamId, szBuffer, size );
		
		//Lower cases
		if ( strlen( szBuffer ) > 3 ) //4+ chars = lower
			for ( new i = 1; i < size; ++i )
				szBuffer[ i ] = CharToLower( szBuffer[ i ] );
	}
	else
		FormatEx( szBuffer, size, "%T", "No team", LANG_SERVER, "\x01" );
}

any:getAWPTeam()
{
	new iEntIndex;
	decl String:szClassName[ MAX_NAME_LENGTH ];  
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) )
		{
			iEntIndex = GetPlayerWeaponSlot( i, CS_SLOT_PRIMARY );
			if ( IsValidEntity( iEntIndex ) )
			{
				GetEdictClassname( iEntIndex, szClassName, sizeof(szClassName) );
				if ( StrEqual( szClassName, AWP_ENT_STR ) )
				{
					return GetClientTeam( i );
				}
			}
		}
	}
	
	return 0;
}