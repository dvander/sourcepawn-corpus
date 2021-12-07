/**
	Credits : 
	Sylv@in, patneze, DoCky and EmBouT for 
		[Python] Limitation awp (eventscript plugin; does almost the same thing as mine).
		Awp Restrict is based on it, since it was the first one (AFAIK) to allow individual awp restriction.
		Also, the ES version was in french only. I'm making it multilingual.
*/
#pragma semicolon 1

#include <cstrike>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Red's AWP Wide Restriction",
	author = "RedSword / Bob Le Ponge",
	description = "Allows team, individual and minimum players awp restrictions.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
//Defines
#define	AWP_ENT_STR			"weapon_awp"
#define	AWP_WPN_STR			"awp"
#define	AWP_COST			4750
#define	CS_SLOT_KNIFE		2
#define	HUGE_FLOAT_VALUE	999999999999.9

//Needed to drop a weapon (Credits : dalto)
new Handle:g_hDropWeapon = INVALID_HANDLE;

//=====Cvars
new Handle:g_rawr;

new Handle:g_rawr_action_inbuyzone;
new Handle:g_rawr_action_outbuyzone;
new Handle:g_rawr_action_respect16k;

new Handle:g_rawr_minplayers;
new Handle:g_rawr_minplayers_bothteams;

new Handle:g_rawr_teamlimit;
new Handle:g_rawr_teamlimit_continuity;

new Handle:g_rawr_playerlimit;
new Handle:g_rawr_playerlimit_wait;
new Handle:g_rawr_playerlimit_recover;
new Handle:g_rawr_playerlimit_connect;

new Handle:g_rawr_verbose_prefix;
new Handle:g_rawr_verbose_reason;
new Handle:g_rawr_verbose_onuse;
new Handle:g_rawr_verbose_waitover;

//=====Vars
new bool:g_bCanRegisterAwpViaPickup;
new bool:g_bHasRegisteredThisRound[ MAXPLAYERS + 1 ];
new g_iNbRoundsWithAwp[ MAXPLAYERS + 1 ];
new g_iNbRoundsToWait[ MAXPLAYERS + 1 ];
new Float:g_fTimeGrapAwp[ MAXPLAYERS + 1 ];

enum ReasonCantAwp
{
	NONE = 0	,
	WAITING		,
	MINPLAYERS	,
	TEAMLIMIT
};


new Float:g_fTimeLimit; //related to buytime

//Prevent re-running a function
new g_iBuyZone; //If the player is in a buyzone
new g_iAccount; //$$$
new Float:g_fBuytime;
new String:g_szVerbosePrefix[ 8 ];

//===== Forwards

public OnPluginStart( )
{
	//CVARs
	CreateConVar( "redsawpwiderestrictionversion", PLUGIN_VERSION, "Red's AWP Wide Restriction's plugin's version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	g_rawr = CreateConVar( "rawr", "1", "Is the plugin enabled ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	//Actions
	g_rawr_action_inbuyzone = CreateConVar( "rawr_action_inbuyzone", "2", 
	"What action to do with an restricted AWP in a buyzone (+ enough buytime) ? 0=strip, 1=drop, 2=refund. Def. 2.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	g_rawr_action_outbuyzone = CreateConVar( "rawr_action_outbuyzone", "1", 
	"What action to do with an restricted AWP out of a buyzone (or not enough buytime) ? 0=strip, 1=drop. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_rawr_action_respect16k = CreateConVar( "rawr_action_respect16k", "1", 
	"When refunding an AWP, respect 16k cash limit ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	//Minplayers
	g_rawr_minplayers = CreateConVar( "rawr_minplayers", "5", 
	"Minimum players in game required to buy AWPs. Def. 5.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_rawr_minplayers_bothteams = CreateConVar( "rawr_minplayers_bothteams", "1", 
	"Does both teams need to have the minimum players count to enable AWPs or should total player count be considered (i.e. 7v3 != 5v5). 0=Total players, 1=Both teams. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	//Teamlimit
	g_rawr_teamlimit = CreateConVar( "rawr_teamlimit", "1", 
	"Maximum AWPs allowed per team. 0=No maximum. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_rawr_teamlimit_continuity = CreateConVar( "rawr_teamlimit_continuity", "2", 
	"Who should get AWP if more there is more AWP than teamlimit CVar's value at round start (i.e. enemy AWPer changes team --> 2awpVS0awp). 0=Least intensive AWPer, 1=Most intensive AWPer, 2=Most intensive AWPer (seconds based). Def. 2 (continuity prevail).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	
	//Individual limit
	g_rawr_playerlimit = CreateConVar( "rawr_playerlimit", "3", 
	"How long (in round) can someone use an AWP. 0=disable 1+= number of rounds.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_rawr_playerlimit_wait = CreateConVar( "rawr_playerlimit_wait", "3", 
	"How long (in round) before someone can someone re-use an AWP after having reached the limit of rounds. Min 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 1.0 );
	g_rawr_playerlimit_recover = CreateConVar( "rawr_playerlimit_recover", "0", 
	"Does someone who doesn't touch an AWP during one round has his awp-use count reduced by 1 (doesn't count in 'wait' mode) ? 0=No, 1=Yes. Def. 0.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_rawr_playerlimit_connect = CreateConVar( "rawr_playerlimit_connect", "1", 
	"How long (in round) should someone that just joined wait before being able to use a AWP ? Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	
	//Verboses
	g_rawr_verbose_prefix = CreateConVar( "rawr_verbose_prefix", "[SM]", 
	"Prefix attached to verboses' phrases. Default is '[SM]'.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY );
	g_rawr_verbose_reason = CreateConVar( "rawr_verbose_reason", "1.0", 
	"Tell the players why they're dropping an AWP. 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_rawr_verbose_onuse = CreateConVar( "rawr_verbose_onuse", "1.0", 
	"Tell the players their AWP informations when they get one. 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_rawr_verbose_waitover = CreateConVar( "rawr_verbose_waitover", "1.0", 
	"Tell the players when they can AWP due to recovery/waiting). 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	//Config
	AutoExecConfig( true, "redsawpwiderestriction" );
	
	//Hooks on events
	HookEvent( "round_start", Event_RoundStart );
	HookEvent( "round_freeze_end", Event_OnFreezeEnd );
	HookEvent( "round_end", Event_RoundEnd );
	HookEvent( "item_pickup", Event_ItemPickup );
	HookEvent( "player_death", Event_PlayerDeath );
	
	//Hooks ConVar changes
	HookConVarChange( FindConVar( "mp_buytime" ), ConVarChange_BuyTime );
	HookConVarChange( g_rawr_verbose_prefix, ConVarChange_VerbosePrefix );
	
	//Translation file
	LoadTranslations( "redsawpwiderestriction.phrases" );
	
	//Load game config + allow weapon drop (Credits : dalto + AltPluzF4)
	new Handle:hGameConf = LoadGameConfigFile("wpndrop-cstrike.games");
	if (Handle:hGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/wpndrop-cstrike.games.txt not loadable");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hDropWeapon = EndPrepSDKCall( );
	
	//Prevent re-running a function
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
	g_fBuytime = GetConVarFloat( FindConVar( "mp_buytime" ) );
	GetConVarString( g_rawr_verbose_prefix, g_szVerbosePrefix, sizeof(g_szVerbosePrefix) );
}

public OnClientPutInServer( iClient )
{
	g_iNbRoundsToWait[ iClient ] = GetConVarInt( g_rawr_playerlimit_connect );
}

public OnClientDisconnect( iClient )
{
	g_iNbRoundsWithAwp[ iClient ] = 0;
	g_iNbRoundsToWait[ iClient ] = 0;
	g_bHasRegisteredThisRound[ iClient ] = false;
	g_fTimeGrapAwp[ iClient ] = HUGE_FLOAT_VALUE;
}

//===== Hooks : Events =====
//Loop through all players to check & register their awps
public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( !GetConVarBool( g_rawr ) )
		return bool:Plugin_Continue;
	
	g_fTimeLimit = GetEngineTime( ) + ( g_fBuytime * 60.0 ); //will be reaffected on freeze end; avoid someone buying and not being refunded
	
	//Get AWPs and players counts
	decl tAwpers[ MaxClients ];
	new tAwpCount;
	decl ctAwpers[ MaxClients ];
	new ctAwpCount;
	new tCount;
	new ctCount;
	getAwpsAndPlayerCount( tAwpers, tAwpCount, ctAwpers, ctAwpCount, tCount, ctCount );
	
	//Strip Awps if not enough players : first restriction
	new minPlayers = GetConVarInt( g_rawr_minplayers );
	new bool:bothTeams = GetConVarBool( g_rawr_minplayers_bothteams );
	if ( 	( bothTeams && ( tCount < minPlayers && ctCount < minPlayers ) ) ||
			( !bothTeams && tCount + ctCount < minPlayers )
			)
	{
		if ( tAwpCount )
			stripPlayersPrimary( tAwpers, tAwpCount, bothTeams, minPlayers );
		if ( ctAwpCount )
			stripPlayersPrimary( ctAwpers, ctAwpCount, bothTeams, minPlayers );
	}
	else //we have enough players; now we have to check individual restriction : 2nd restriction
	{
		new playerLimit = GetConVarInt( g_rawr_playerlimit );
		if ( playerLimit )
		{
			if ( tAwpCount )
				enforceIndivsRestriction( tAwpers, tAwpCount );
			if ( ctAwpCount )
				enforceIndivsRestriction( ctAwpers, ctAwpCount );
		}
		
		//Player able to wear awps have them; now check team restriction : 3rd restriction
		new teamLimit = GetConVarInt( g_rawr_teamlimit );
		if ( teamLimit )
		{
			if ( tAwpCount )
				enforceTeamRestriction( tAwpers, tAwpCount, teamLimit );
			if ( ctAwpCount )
				enforceTeamRestriction( ctAwpers, ctAwpCount, teamLimit );
		}
		
		resetRegistrationNewRound( );
		registersAwpsNewRound( tAwpers, tAwpCount );
		registersAwpsNewRound( ctAwpers, ctAwpCount );
	}
	
	g_bCanRegisterAwpViaPickup = true;
	
	return bool:Plugin_Continue;
}
public Action:Event_OnFreezeEnd(Handle:p_hEvent, const String:name[], bool:dontBroadcast)
{
	//If plugin is enabled
	if ( GetConVarInt( g_rawr ) )
		g_fTimeLimit = GetEngineTime( ) + ( g_fBuytime * 60.0 );
	
	return Plugin_Continue;
}

public Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	//This allow people to take AWPs on the ground, even if someone of their team normally prevent it
	//g_rawr_teamlimit_continuity will then be used to determined who keeps it (on round start)
	g_bCanRegisterAwpViaPickup = false;
	
	if ( GetEventInt( event, "winner" ) == 1 || GetConVarInt( g_rawr ) == 0 ) //draw "enough player joins so restart game" / "people left"
		return bool:Plugin_Continue;
	
	//For everyone that didn't use awp this round, remove one to their count (if recovering is enabled)
	if ( GetConVarBool( g_rawr_playerlimit_recover ) )
	{
		for ( new i = 1; i <= MaxClients; ++i )
		{
			if ( g_bHasRegisteredThisRound[ i ] == false && g_iNbRoundsWithAwp[ i ] ) //if player didn<t awp this round and isn't waiting
			{
				--g_iNbRoundsWithAwp[ i ];
			}
		}
	}
	new maxRoundsWithAwp = GetConVarInt( g_rawr_playerlimit );
	new waitTime = GetConVarInt( g_rawr_playerlimit_wait );
	for ( new i = 1; i <= MaxClients; ++i )
	{
		//Decrement wait rounds
		if ( g_iNbRoundsToWait[ i ] )
		{
			if ( --g_iNbRoundsToWait[ i ] == 0 )
			{
				verboseCanNowAwp( i );
			}
		}
		
		//g_bHasRegisteredThisRound
		if ( g_bHasRegisteredThisRound[ i ] == true )
		{
			if ( ++g_iNbRoundsWithAwp[ i ] == maxRoundsWithAwp )
			{
				g_iNbRoundsWithAwp[ i ] = 0;
				g_iNbRoundsToWait[ i ] = waitTime;
			}
		}
	}
	
	return bool:Plugin_Continue;
}

//Need to check if awp first (cause if not; it can be before player spawn)
public Event_ItemPickup( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( !GetConVarInt( g_rawr ) || !g_bCanRegisterAwpViaPickup )
		return bool:Plugin_Continue;
	
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	decl String:szBuffer[ MAX_NAME_LENGTH ];
	GetEventString( event, "item", szBuffer, sizeof(szBuffer) );
	
	//Remove AWP if no requirements met else keep
	if ( StrEqual( szBuffer, AWP_WPN_STR ) )
	{
		//CHECKS
		new ReasonCantAwp:preventAwpReason = preventAwp( iClient );
		if ( preventAwpReason == ReasonCantAwp:NONE )
		{
			registerAwpOnPickup( iClient );
		}
		else
		{
			switch ( preventAwpReason )
			{
				case ( ReasonCantAwp:WAITING ) :
				{
					verboseCantAwpWaiting( iClient );
				}
				case ( ReasonCantAwp:MINPLAYERS ) : 
				{
					verboseCantAwpNotEnoughPlayers( iClient, GetConVarBool( g_rawr_minplayers_bothteams ), GetConVarInt( g_rawr_minplayers ) );
				}
				case ( ReasonCantAwp:TEAMLIMIT ) : 
				{
					verboseLostAwpTeamLimitPriority( iClient, GetConVarInt( g_rawr_teamlimit ) );
				}
			}
			
			if ( isClientInBuyzone( iClient ) )
				removeAwpFromAwperInBuyzone( iClient );
			else
				removeAwpFromAwperOutBuyzone( iClient );
		}
	}
	
	return bool:Plugin_Continue;
}


public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	//Player certainly doesn't have AWP anymore so reset his timer
	new iVictim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( iVictim > 0 )
		g_fTimeGrapAwp[ iVictim ] = HUGE_FLOAT_VALUE;
	
	return bool:Plugin_Continue;
}

//===== Hooks : ConVar =====
public ConVarChange_BuyTime( Handle:conVar, const String:oldvalue[], const String:newvalue[] )
{
	g_fBuytime = StringToFloat( newvalue );
	g_fTimeLimit = GetEngineTime( ) + ( g_fBuytime * 60.0 );
}
public ConVarChange_VerbosePrefix( Handle:conVar, const String:oldvalue[], const String:newvalue[] )
{
	strcopy( g_szVerbosePrefix, sizeof(g_szVerbosePrefix), newvalue );
}

//===== Privates =====

//getAwpers in teams; used on round start
getAwpsAndPlayerCount( tAwpers[], &any:tAwpCount, ctAwpers[], &any:ctAwpCount, &any:tCount, &any:ctCount )
{
	new iTeam;
	new iSlot;
	decl String:szWpn[ MAX_NAME_LENGTH ];
	
	for ( new i = 1; i <= MaxClients; ++i)
	{
		if ( IsClientInGame( i ) && IsPlayerAlive( i ) ) //function used only on roundStart so everyone is Alive
		{
			iTeam = GetClientTeam( i );
			if ( iTeam >= 2 )
			{
				//Team players counts
				if ( iTeam == 2 )
					++tCount;
				else
					++ctCount;
				
				//Awp counts
				iSlot = GetPlayerWeaponSlot( i, CS_SLOT_PRIMARY );
				if ( iSlot != -1 && IsValidEntity( iSlot ) )
				{
					GetEdictClassname( iSlot, szWpn, sizeof(szWpn) );
					
					if ( StrEqual( szWpn, AWP_ENT_STR ) )
					{
						if ( iTeam == 2 )
						{
							tAwpers[ tAwpCount++ ] = i;
						}
						else
						{
							ctAwpers[ ctAwpCount++ ] = i;
						}
					}
				}
			}
		}
	}
}

//OnWpnPickup; return reason
ReasonCantAwp:preventAwp( iClient )
{
	if ( g_iNbRoundsToWait[ iClient ] > 0 )
		return ReasonCantAwp:WAITING;
	
	new iClientTeam = GetClientTeam( iClient );
	new iTeam;
	new iSlot;
	decl String:szWpn[ MAX_NAME_LENGTH ];
	
	new iNbAwpsInTeam;
	new nbT;
	new nbCT;
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) )
		{
			iTeam = GetClientTeam( i );
			
			if ( iTeam == 2 )
			{
				++nbT;
			}
			else if ( iTeam == 3 )
			{
				++nbCT;
			}
			
			if ( IsPlayerAlive( i ) && iClientTeam == iTeam )
			{
				iSlot = GetPlayerWeaponSlot( i, CS_SLOT_PRIMARY );
				if ( iSlot != -1 && IsValidEntity( iSlot ) )
				{
					GetEdictClassname( iSlot, szWpn, sizeof(szWpn) );
					
					if ( StrEqual( szWpn, AWP_ENT_STR ) )
					{
						++iNbAwpsInTeam;
					}
				}
			}
			
		}
	}
	
	new minPlayers = GetConVarInt( g_rawr_minplayers );
	new bothTeams = GetConVarBool( g_rawr_minplayers_bothteams );
	if ( 	( bothTeams && ( nbT < minPlayers && nbCT < minPlayers ) ) ||
			( !bothTeams && nbT + nbCT < minPlayers )
			)
		return ReasonCantAwp:MINPLAYERS;
	
	new maxAwpsPerTeam = GetConVarInt( g_rawr_teamlimit );
	if ( iNbAwpsInTeam > maxAwpsPerTeam && maxAwpsPerTeam > 0 )
		return ReasonCantAwp:TEAMLIMIT;
	
	return ReasonCantAwp:NONE;
}

//--Strips & removes

//We receive players in a array. They all have been checked previously so no need to valid ent check
stripPlayersPrimary( awpers[], any:size, bool:bothTeams, minPlayers )
{
	new iCurrentAwper;
	for ( new i; i < size; ++i )
	{
		iCurrentAwper = awpers[ i ];
		
		//1- Strip/refund
		stripAwpFromAwper( iCurrentAwper, GetConVarInt( g_rawr_action_inbuyzone ) == 2 );
		
		//2- Verbose
		verboseCantAwpNotEnoughPlayers( iCurrentAwper, bothTeams, minPlayers );
	}
}

//Individual restriction
enforceIndivsRestriction( awpers[], &any:size )
{
	new iCurrentAwper;
	for ( new i = size - 1; i >= 0; --i )
	{
		iCurrentAwper = awpers[ i ];
		if ( g_iNbRoundsToWait[ iCurrentAwper ] ) //possibly waiting (i.e. just connected)
		{ //Need to strip/drop/refund
			removeAwpFromAwperInBuyzone( iCurrentAwper );
			
			verboseCantAwpWaiting( iCurrentAwper );
			
			//We've one less AWPers, need to clean array
			removeIndexFromArray( awpers, size, i );
		}
	}
}

//Team restriction
enforceTeamRestriction( awpers[], &any:size, const limitPerTeam ) //limitPerTeam > 0
{
	if ( size <= limitPerTeam )
		return;
	
	new continuityPrevail = GetConVarInt( g_rawr_teamlimit_continuity );
	new value_minOrMax;
	new Float:oldestTime; //oldest --> lowest
	
	new iAwper;
	
	decl idxHavingValue[ MaxClients ];
	new nbIdxHavingValue;
	
	if ( continuityPrevail != 2 ) //if round based
	{
		while ( size > limitPerTeam )
		{
			//First loop : get min/max value
			for ( new i; i < size; ++i )
			{
				iAwper = awpers[ i ];
				if ( ( continuityPrevail && g_iNbRoundsWithAwp[ iAwper ] < value_minOrMax ) ||
						( !continuityPrevail && g_iNbRoundsWithAwp[ iAwper ] > value_minOrMax ) )
				{
					value_minOrMax = g_iNbRoundsWithAwp[ iAwper ];
				}
			}
			
			nbIdxHavingValue = 0;
			//2nd loop : Go over all awpers and get their index so we can remove a random one
			for ( new i; i < size; ++i )
			{
				iAwper = awpers[ i ];
				if ( g_iNbRoundsWithAwp[ iAwper ] == value_minOrMax )
				{
					idxHavingValue[ nbIdxHavingValue++ ] = i;
				}
			}
			
			//3rd loop : Remove one random awper as long as it is needed (and that we can)
			new randomIndex;
			new randomAwperIndex;
			while ( nbIdxHavingValue > 0 && size > limitPerTeam )
			{
				//Get random awper index
				randomIndex = GetRandomInt( 0, --nbIdxHavingValue );
				randomAwperIndex = idxHavingValue[ randomIndex ];
				
				iAwper = awpers[ randomAwperIndex ];
				removeAwpFromAwperInBuyzone( iAwper );
				verboseLostAwpTeamLimitPriority( iAwper, limitPerTeam );
				
				//Remove awper index and therefore index
				removeIndexFromArray( awpers, size, randomAwperIndex );
			}
		}
	}
	else //time based
	{
		new oldestAwperIndex;
		while ( size > limitPerTeam )
		{
			//1- Get awper with oldest value
			oldestTime = HUGE_FLOAT_VALUE;
			for ( new i; i < size; ++i )
			{
				iAwper = awpers[ i ];
				if ( oldestTime > g_fTimeGrapAwp[ iAwper ] ) //Since it is float chances that people pick-up wpn at the same time are so weak that I don't bother random it
				{
					oldestTime = g_fTimeGrapAwp[ iAwper ];
					oldestAwperIndex = i;
					removeAwpFromAwperInBuyzone( iAwper );
					verboseLostAwpTeamLimitPriority( iAwper, limitPerTeam );
				}
			}
			//2- Remove it
			removeIndexFromArray( awpers, size, oldestAwperIndex );
		}
	}
}

//Remove AWP from an AWPer. We do consider the client to be valid with a valid awp
//While inbuyzone/roundstart
removeAwpFromAwperInBuyzone( iClient )
{
	new cvarInBuyZone = GetConVarInt( g_rawr_action_inbuyzone );
	switch ( cvarInBuyZone )
	{
		case 1 : //drop
		{
			SDKCall( g_hDropWeapon, iClient, GetPlayerWeaponSlot( iClient, CS_SLOT_PRIMARY ), true, true );
		}
		default : //refund and strip
		{
			stripAwpFromAwper( iClient, cvarInBuyZone == 2 );
		}
	}
	ClientCommand( iClient, "play buttons/weapon_cant_buy.wav" );
}

removeAwpFromAwperOutBuyzone( iClient )
{
	if ( !GetConVarBool( g_rawr_action_outbuyzone ) )
		stripAwpFromAwper( iClient );
	else
		SDKCall( g_hDropWeapon, iClient, GetPlayerWeaponSlot( iClient, CS_SLOT_PRIMARY ), true, true );
		
	ClientCommand( iClient, "play buttons/weapon_cant_buy.wav" );
}

//Strip AWP from an AWPer. We do consider the client to be valid with a valid awp
stripAwpFromAwper( iClient, bool:refund=false )
{
	//Remove
	new iAwpEnt = GetPlayerWeaponSlot( iClient, CS_SLOT_PRIMARY );
	RemovePlayerItem( iClient, iAwpEnt ); 
	AcceptEntityInput( iAwpEnt, "kill" );
	
	//Switch to knife
	new iKnifeEnt = GetPlayerWeaponSlot( iClient, CS_SLOT_KNIFE );
	if ( iKnifeEnt != -1 ) //A certain plugin allows knife drop; if server has it and player dropped it then player will be naked :o
		EquipPlayerWeapon( iClient, iKnifeEnt );
	
	if ( refund )
	{
		new iMoney = GetEntData( iClient, g_iAccount );
		iMoney += AWP_COST;
		SetEntData( iClient, g_iAccount, ( iMoney > 16000 && GetConVarBool( g_rawr_action_respect16k ) ) ? 16000 : iMoney );
	}
}

//Buyzone
bool:isClientInBuyzone( iClient )
{
	return GetEntData( iClient, g_iBuyZone, 1 ) && GetEngineTime( ) < g_fTimeLimit;
}

//Index
removeIndexFromArray( array[], &any:size, indexToRemove )
{
	for ( new var = indexToRemove; var < size - 1; ++var )
	{
		array[ var ] = array[ var + 1 ];
	}
	--size;
}

//Registration related
resetRegistrationNewRound( )
{
	for ( new i = 1; i <= MaxClients; ++i )
	{
		g_bHasRegisteredThisRound[ i ] = false;
	}
}

registersAwpsNewRound( awpers[], const size )
{
	new iAwper;
	for ( new i = size - 1; i >= 0; --i )
	{
		iAwper = awpers[ i ];
		g_bHasRegisteredThisRound[ iAwper ] = true;
		verboseRegisteredAwp( iAwper );
	}
}

registerAwpOnPickup( iClient )
{
	if ( g_bHasRegisteredThisRound[ iClient ] == false )
	{
		g_bHasRegisteredThisRound[ iClient ] = true;
		verboseRegisteredAwp( iClient );
		g_fTimeGrapAwp[ iClient ] = GetEngineTime( );
	}
}

//===== Verboses =====

verboseCanNowAwp( const iClient )
{
	if ( GetConVarBool( g_rawr_verbose_waitover ) )
		PrintToChat( iClient, "\x04%s \x01%t", g_szVerbosePrefix, "CanNowAwp" ); 
}
verboseCantAwpNotEnoughPlayers( const iClient, const bool:bothTeams, const minPlayers )
{
	if ( GetConVarBool( g_rawr_verbose_reason ) )
		PrintToChat( iClient, "\x04%s \x01%t %t", g_szVerbosePrefix, "NotEnoughPlayers2Awp", 
			bothTeams ? "NotEnoughPlayers2AwpBothTeams" : "NotEnoughPlayers2AwpNotBothTeams",
			"\x04", minPlayers, "\x01" );
}
verboseCantAwpWaiting( const iClient ) //if == false --> additionnal "awpedtoomanytimes"
{
	if ( GetConVarBool( g_rawr_verbose_reason ) )
	{
		decl String:szBuffer[ 128 ];
		FormatEx( szBuffer, sizeof(szBuffer), "\x04%s\x01", g_szVerbosePrefix );
		
		if ( g_iNbRoundsToWait[ iClient ] == GetConVarInt( g_rawr_playerlimit_wait ) )
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "AwpedTooManyTimes", iClient );
		
		PrintToChat( iClient, "%s %t", szBuffer, "Waiting", 
			"\x04", 
			g_iNbRoundsToWait[ iClient ], 
			"\x01" );
	}
}
verboseLostAwpTeamLimitPriority( const iClient, const limitPerTeam )
{
	if ( GetConVarBool( g_rawr_verbose_reason ) )
		PrintToChat( iClient, "\x04%s \x01%t", g_szVerbosePrefix, "TeamLimit-Priority", "\x04", limitPerTeam, "\x01" );
}
verboseRegisteredAwp( const iClient )
{
	if ( GetConVarBool( g_rawr_verbose_onuse ) )
		PrintToChat( iClient, "\x04%s \x01%t", g_szVerbosePrefix, "RegisteredAwp", "\x04", g_iNbRoundsWithAwp[ iClient ] + 1, "\x01", 
			"\x04", GetConVarInt( g_rawr_playerlimit ), "\x01" );
}