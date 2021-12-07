#pragma semicolon 1

#include <sdktools>

#define PLUGIN_VERSION "1.0.3b"

public Plugin:myinfo =
{
	name = "Request Bomb",
	author = "RedSword / Bob Le Ponge",
	description = "Allow people to request bomb for the upcoming round start.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//defines for color code
#define COLOR_NORMAL	"\x01"
#define COLOR_CLIENT	"\x03"
#define COLOR_CMD		"\x05"

//Cvars
new Handle:g_requestBomb;

new Handle:g_requestBomb_verboseAsk;
new Handle:g_requestBomb_verboseGive;
new Handle:g_requestBomb_verboseNoAsk;

//Vars
new bool:g_bIsMapDe;
new bool:g_isRequesting[ MAXPLAYERS + 1 ];
new g_iNumberRequests;

public OnPluginStart()
{
	//CVARs
	CreateConVar( "requestbombversion", PLUGIN_VERSION, "Request Bomb version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_requestBomb = CreateConVar( "requestbomb", "1", "Is the plugin enabled ? 0=No, 1=Yes. Def. 1", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_requestBomb_verboseAsk = CreateConVar( "requestbomb_verbose_request", "1", "Tell people when a teamate request the bomb. 0=No, 1=Yes (Always, default), 2=Yes (When dead).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	g_requestBomb_verboseGive = CreateConVar( "requestbomb_verbose_give", "1", "Tell people when a teamate is given the bomb. 0=No, 1=Yes (Always, default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_requestBomb_verboseNoAsk = CreateConVar( "requestbomb_verbose_unrequested", "1", "Tell people about the plugin when bomb isn't requested. 0=No, 1=Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	//Config
	AutoExecConfig( true, "requestbomb" );
	
	//Hooks on events
	HookEvent( "round_start", Event_RoundStart );
	
	//Translation file
	LoadTranslations( "common.phrases" );
	LoadTranslations( "requestbomb.phrases" );
	
	RegConsoleCmd( "sm_requestbomb", Command_RequestBomb, "sm_requestbomb" );
	RegConsoleCmd( "sm_rb", Command_RequestBomb, "sm_rb" );
	RegConsoleCmd( "sm_requestc4", Command_RequestBomb, "sm_requestc4" );
	RegConsoleCmd( "sm_rc4", Command_RequestBomb, "sm_rc4" );
}

public OnMapStart()
{
	g_bIsMapDe = bool:GameRules_GetProp( "m_bMapHasBombTarget" );
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_requestBomb ) == 1 && g_bIsMapDe )
	{
		CreateTimer( 0.1, GiveBombDelayed );
	}
}

//Check if bomber's state changed
public Action:GiveBombDelayed(Handle:timer) //UserId used to prevent a possible problem if someone would leave and take bomber's "state" within 0.5 sec (lol)
{
	if ( g_iNumberRequests == 0 )
	{
		if ( GetConVarInt( g_requestBomb_verboseNoAsk ) )
		{
			verboseUnrequestedBomb( );
		}
		return Plugin_Continue;
	}
	
	decl requesters[ g_iNumberRequests ];
	new count;
	
	//Add ids to array
	for ( new i = 1; i <= MaxClients; ++i )
	{
		//Player is in game; since we remove when he disconnect
		
		if ( IsClientInGame( i ) && 
				IsPlayerAlive( i ) &&
				GetClientTeam( i ) == 2 &&
				g_isRequesting[ i ] )
			requesters[ count++ ] = i;
	}
	
	if ( count == 0 ) //Avoid people switching team potential problem
	{
		return Plugin_Continue;
	}
	
	//Remove bomb
	removeBomb( );
	
	//Give bomb to random player
	new iReceiver = requesters[ GetRandomInt( 0, count - 1 ) ];
	
	verboseGivingBomb( iReceiver, requesters, count );
	
	GivePlayerItem( iReceiver, "weapon_c4" );
	
	//Reset requests
	resetCount( );
	
	return Plugin_Continue;
}

public Action:Command_RequestBomb(client, args)
{
	if ( !GetConVarInt( g_requestBomb ) || !g_bIsMapDe )
		return Plugin_Continue;
	
	//Prevent people from outside to run the command
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	//Prevent non-terro from requesting
	if ( GetClientTeam( client ) != 2 )
		return Plugin_Handled;
	
	if ( g_isRequesting[ client ] )
	{
		PrintToChat( client, "\x04[SM] \x01%t", "Already requesting" );
	}
	else
	{
		g_isRequesting[ client ] = true;
		++g_iNumberRequests;
		verboseRequestingBomb( client );
	}
	
	return Plugin_Handled;
}

//=====SM Forwards

//Clean array
public OnClientDisconnect(iClient)
{
	if ( g_isRequesting[ iClient ] == true )
		--g_iNumberRequests;
	
	g_isRequesting[ iClient ] = false;
}

//=====Privates

//Remove the bomb from the game
removeBomb()
{
	new iBomber;
	
	//Get the bomber
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( IsClientConnected( i ) &&
				IsClientInGame( i ) && 
				IsPlayerAlive( i ) &&
				GetPlayerWeaponSlot( i, 4 ) != -1 ) //if the player is carrying the bomb
		{
			iBomber = i; //We found the bomber, no need to continue in the loop
			break;
		}
	}
	
	//Remove bomb
	if (iBomber != 0) //If bomber is a player
	{
		decl String:sClassName[128];  
		
		new iEntIndex = GetPlayerWeaponSlot( iBomber, 4 );
		
		GetEdictClassname( iEntIndex, sClassName, sizeof(sClassName) );  
		if ( StrEqual( sClassName, "weapon_c4", false ) )  
		{
			RemovePlayerItem( iBomber, iEntIndex ); 
			AcceptEntityInput( iEntIndex, "kill" );
		}
	}
	else //If it's the world
	{
		for (new iEntIndex = ( MaxClients + 1 ); iEntIndex < GetMaxEntities(); ++iEntIndex)
		{
			if ( IsValidEntity( iEntIndex ) )
			{  
				decl String:sClassName[ 128 ];  
				GetEdictClassname( iEntIndex, sClassName, sizeof(sClassName) );
				if ( StrEqual( sClassName, "weapon_c4", false ) )
				{
					AcceptEntityInput( iEntIndex, "kill" );
					return;
				}
			}
		}
	}
}

resetCount()
{
	for ( new i = 1; i <= MaxClients; ++i )
	{
		g_isRequesting[ i ] = false;
	}
	g_iNumberRequests = 0;
}

//=====Privates : verboses

/*Tell all terro that they can request the bomb
*/
verboseUnrequestedBomb( )
{
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) && 
				GetClientTeam( i ) == 2 )
		{
			PrintToChat( i, "\x04[SM] \x01%t", "Unrequested", COLOR_CMD, COLOR_NORMAL, COLOR_CMD, COLOR_NORMAL );
		}
	}
}

/*iClient is requesting the bomb :
-	Tell him he's eligible to get it next round.
-	Tell teamates that he might get it. CVar 0 / 1 / 2 (2=dead)
*/
verboseRequestingBomb( any:iClient )
{
	PrintToChat( iClient, "\x04[SM] \x01%t", "Now eligible" );
	
	new verboseLevel = GetConVarInt( g_requestBomb_verboseAsk );
	
	if ( verboseLevel == 0 )
		return;
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) && 
				GetClientTeam( i ) == 2 &&
				( !IsPlayerAlive( i ) || 
				( IsPlayerAlive( i ) && verboseLevel == 1 ) ) )
		{
			PrintToChat( i, "\x04[SM] \x01%t", "Teamate requests", COLOR_CLIENT, iClient, COLOR_NORMAL, COLOR_CMD, COLOR_NORMAL, COLOR_CMD, COLOR_NORMAL );
		}
	}
}

/*Bomb is given to iClient :
-	Tell him he receive the bomb because he requested it.
-	Tell teamates that requested it that they didn't get it. CVar
*/
verboseGivingBomb( any:iClient, any:requesters[], any:count )
{
	PrintToChat( iClient, "\x04[SM] \x01%t", "Receive bomb" );
	
	if ( GetConVarInt( g_requestBomb_verboseGive ) == 0 )
		return;
	
	for ( new i; i < count; ++i )
	{
		if ( requesters[ i ] != iClient )
			PrintToChat( requesters[ i ], "\x04[SM] \x01%t", "Teamate receive", COLOR_CLIENT, iClient, COLOR_NORMAL );
	}
}