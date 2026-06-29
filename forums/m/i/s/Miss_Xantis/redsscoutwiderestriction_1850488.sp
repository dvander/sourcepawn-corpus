/**
	Credits : 
	Sylv@in, patneze, DoCky and EmBouT for 
		[Python] Limitation Scout (eventscript plugin; does almost the same thing as mine).
		Scout Restrict is based on it, since it was the first one (AFAIK) to allow individual Scout restriction.
		Also, the ES version was in french only. I'm making it multilingual.
*/
#pragma semicolon 1

#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.5.0"

public Plugin:myinfo =
{
	name = "Red's Scout Wide Restriction",
	author = "RedSword / Bob Le Ponge",
	description = "Allows team, individual and minimum players Scout restrictions.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
//Defines
#define	AWP_ENT_STR			"weapon_scout"
#define	AWP_WPN_STR			"scout"
#define	AWP_COST			2750
#define	CS_SLOT_KNIFE		2
#define	HUGE_FLOAT_VALUE	999999999999.9

//=====Cvars
new Handle:g_rawr;

new Handle:g_rawr_action_inbuyzone;
new Handle:g_rawr_action_outbuyzone;
new Handle:g_rawr_action_respect16k;

new Handle:g_rawr_minplayers;
new Handle:g_rawr_minplayers_bothteams;
new Handle:g_rawr_minplayers_roundstart;

new Handle:g_rawr_teamlimit;
new Handle:g_rawr_teamlimit_continuity;
new Handle:g_rawr_teamlimit_additional;

new Handle:g_rawr_playerlimit;
new Handle:g_rawr_playerlimit_wait;
new Handle:g_rawr_playerlimit_recover;
new Handle:g_rawr_playerlimit_connect;

new Handle:g_rawr_verbose_prefix;
new Handle:g_rawr_verbose_reason;
new Handle:g_rawr_verbose_onuse;
new Handle:g_rawr_verbose_waitover;
new Handle:g_rawr_verbose_roundstart;
new Handle:g_rawr_sound_buy;

new Handle:g_rawr_disable_prefixes;

//=====Vars
new bool:g_bCanRegisterAwpViaPickup;
new bool:g_bHasRegisteredThisRound[ MAXPLAYERS + 1 ];
new g_iNbRoundsWithAwp[ MAXPLAYERS + 1 ];
new g_iNbRoundsToWait[ MAXPLAYERS + 1 ];
new Float:g_fTimeGrapAwp[ MAXPLAYERS + 1 ];
new bool:g_bAwpsAreEnabledThisRound;
new g_ibLastRoundAwpWereEnabled; //-1 unknown, rest = bool
new bool:g_bSoundPrecached;
new bool:g_bIsMapOk;

enum ReasonCantAwp
{
	NONE = 0				,
	WAITING					,
	MINPLAYERS				,
	TEAMLIMIT				,
	MINPLAYERS_RS //Roundstart
};


new Float:g_fTimeLimit; //related to buytime

//Prevent re-running a function
new g_iBuyZone; //If the player is in a buyzone
new g_iAccount; //$$$
new Float:g_fBuytime;
new String:g_szVerbosePrefix[ 8 ];
new String:g_szBuySound[ PLATFORM_MAX_PATH - 32 ];
#define MAX_NB_PREFIXES 16
new String:g_szDisablePrefixes[ MAX_NB_PREFIXES ][ 15 ]; //16x15 ; because we need space; so 16 prefixes of 15 char

//===== Forwards

public OnPluginStart( )
{
	//CVARs
	CreateConVar( "redsawpwiderestrictionversion", PLUGIN_VERSION, "Red's Scout Wide Restriction's plugin's version", 
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_rawr = CreateConVar( "rawr", "1", "Is the plugin enabled ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Actions
	g_rawr_action_inbuyzone = CreateConVar( "rawr_action_inbuyzone", "2", 
	"What action to do with an restricted Scout in a buyzone (+ enough buytime) ? 0=strip, 1=drop, 2=refund. Def. 2.", 
		FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	g_rawr_action_outbuyzone = CreateConVar( "rawr_action_outbuyzone", "1", 
	"What action to do with an restricted Scout out of a buyzone (or not enough buytime) ? 0=strip, 1=drop. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_rawr_action_respect16k = CreateConVar( "rawr_action_respect16k", "1", 
	"When refunding an Scout, respect 16k cash limit ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Minplayers
	g_rawr_minplayers = CreateConVar( "rawr_minplayers", "5", 
	"Minimum players in game required to buy Scouts. Def. 5.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_rawr_minplayers_bothteams = CreateConVar( "rawr_minplayers_bothteams", "1", 
	"Does both teams need to have the minimum players count to enable scouts or should total player count be considered (i.e. 7v3 != 5v5). 0=Total players, 1=Both teams. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_rawr_minplayers_roundstart = CreateConVar( "rawr_minplayers_roundstart", "1", "When counting players (minplayers), do it at round start ? (If not it will be on buy/pickup) 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Teamlimit
	g_rawr_teamlimit = CreateConVar( "rawr_teamlimit", "1", 
	"Number of scouts allowed per team when rawr_minplayers is reached. 0=No maximum. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_rawr_teamlimit_continuity = CreateConVar( "rawr_teamlimit_continuity", "2", 
	"Who should get scout if more there is more scout than teamlimit CVar's value at round start (i.e. enemy scouter changes team --> 2scoutVS0scout). 0=Least intensive scouter, 1=Most intensive scouter, 2=Most intensive scouter (seconds based). Def. 2 (continuity prevail).", 
		FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	g_rawr_teamlimit_additional = CreateConVar( "rawr_teamlimit_additional", "10", 
	"How many players are needed per additional scout after the minimum amount of players has been reached. 0=Fixed limit.", 
		FCVAR_PLUGIN, true, 0.0, true, 64.0 );
	
	//Individual limit
	g_rawr_playerlimit = CreateConVar( "rawr_playerlimit", "3", 
	"How long (in round) can someone use an scout. 0=disable 1+= number of rounds.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_rawr_playerlimit_wait = CreateConVar( "rawr_playerlimit_wait", "3", 
	"How long (in round) before someone can someone re-use an scout after having reached the limit of rounds. Min 1.", 
		FCVAR_PLUGIN, true, 1.0 );
	g_rawr_playerlimit_recover = CreateConVar( "rawr_playerlimit_recover", "0", 
	"Does someone who doesn't touch an scout during one round has his scout-use count reduced by 1 (doesn't count in 'wait' mode) ? 0=No, 1=Yes. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_rawr_playerlimit_connect = CreateConVar( "rawr_playerlimit_connect", "1", 
	"How long (in round) should someone that just joined wait before being able to use a scout ? Def. 1.", 
		FCVAR_PLUGIN, true, 0.0 );
	
	//Verboses & sound
	g_rawr_verbose_prefix = CreateConVar( "rawr_verbose_prefix", "[SM] ", 
	"Prefix attached to verboses' phrases. Default is '[SM]'.", 
		FCVAR_PLUGIN );
	g_rawr_verbose_reason = CreateConVar( "rawr_verbose_reason", "1.0", 
	"Tell the players why they're dropping an scout. 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_rawr_verbose_onuse = CreateConVar( "rawr_verbose_onuse", "1.0", 
	"Tell the players their scout informations when they get one. 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_rawr_verbose_waitover = CreateConVar( "rawr_verbose_waitover", "1.0", 
	"Tell the players when they can scout due to recovery/waiting). 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_rawr_verbose_roundstart = CreateConVar( "rawr_verbose_roundstart", "1.0", 
	"Tell all the players when scout change status (to disabled/enabled) at round start. 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_rawr_sound_buy = CreateConVar("rawr_sound_buy", "buttons/weapon_cant_buy.wav", 
		"Sound to play when buying an scout is denied (leave blank to disable; relative to 'sound/' folder).",
		FCVAR_PLUGIN );
	HookConVarChange( g_rawr_sound_buy, SoundBuyChanged );
	
	//Disable
	g_rawr_disable_prefixes = CreateConVar( "rawr_disable_prefixes", "awp_ fun_ aim_", 
	"Disable the plugin with the following map prefixes. Use space (' ') as separator.", 
		FCVAR_PLUGIN );
	HookConVarChange( g_rawr_disable_prefixes, DisablePrefixesChanged );
	verifyMap();
	
	//Config
	AutoExecConfig( true, "redsscoutwiderestriction" );
	
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
	LoadTranslations( "redsscoutwiderestriction.phrases" );
	
	//Prevent re-running a function
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
	g_fBuytime = GetConVarFloat( FindConVar( "mp_buytime" ) );
	GetConVarString( g_rawr_verbose_prefix, g_szVerbosePrefix, sizeof(g_szVerbosePrefix) );
	
	g_bAwpsAreEnabledThisRound = true;
	g_ibLastRoundAwpWereEnabled = -1;
}

public OnMapStart( )
{
	//To force verbose about if AWP are disabled
	g_ibLastRoundAwpWereEnabled = -1;
	verifyMap();
}

public OnConfigsExecuted()
{
	g_bSoundPrecached = false;
	
	//Precache buy sound
	decl String:buySoundLong[ PLATFORM_MAX_PATH ];
	GetConVarString( g_rawr_sound_buy, g_szBuySound, sizeof(g_szBuySound) );
	if ( !StrEqual( g_szBuySound, "" ) )
	{
		FormatEx( buySoundLong, sizeof(buySoundLong), "sound/%s", g_szBuySound );
		if( FileExists( buySoundLong ) )
		{
			AddFileToDownloadsTable( buySoundLong );
			g_bSoundPrecached = PrecacheSound( g_szBuySound, true );
		}
	}
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

public Action:CS_OnBuyCommand( iClient, const String:weapon[] )
{
	if ( !GetConVarBool( g_rawr ) )
		return Plugin_Continue;
	
	if ( !g_bIsMapOk )
		return Plugin_Continue;
	
	if ( !StrEqual( weapon, AWP_WPN_STR ) )
		return Plugin_Continue;
	
	if ( !isClientInBuyzone( iClient ) )
		return Plugin_Continue;
	
	new ReasonCantAwp:preventAwpReason = preventAwp( iClient );
	if ( preventAwpReason != ReasonCantAwp:NONE )
	{
		verboseReasonCantAwp( preventAwpReason, iClient );
		
		//Play sound
		if ( g_bSoundPrecached && !StrEqual(g_szBuySound, "") )
		{
			EmitSoundToClient( iClient, g_szBuySound );
		}
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

//===== Hooks : Events =====
//Loop through all players to check & register their awps
public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( !GetConVarBool( g_rawr ) )
		return bool:Plugin_Continue;
	
	if ( !g_bIsMapOk )
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
	if ( 	( bothTeams && ( tCount < minPlayers || ctCount < minPlayers ) ) ||
			( !bothTeams && tCount + ctCount < minPlayers )
			)
	{
		if ( tAwpCount )
			stripPlayersPrimary( tAwpers, tAwpCount, bothTeams, minPlayers );
		if ( ctAwpCount )
			stripPlayersPrimary( ctAwpers, ctAwpCount, bothTeams, minPlayers );
		
		//No more awps
		tAwpCount = 0;
		ctAwpCount = 0;
		
		if ( g_ibLastRoundAwpWereEnabled != 0 )
		{
			//Verbose AWP Now Disabled
			verboseAllAwpStatus( false );
		}
		g_bAwpsAreEnabledThisRound = false;
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
			new teamLimitAdditional = GetConVarInt( g_rawr_teamlimit_additional );
			
			if ( teamLimitAdditional )
			{
				teamLimit += getActivePlayersCount( true ) / teamLimitAdditional;
			}
			
			if ( tAwpCount )
				enforceTeamRestriction( tAwpers, tAwpCount, teamLimit );
			if ( ctAwpCount )
				enforceTeamRestriction( ctAwpers, ctAwpCount, teamLimit );
		}
		
		if ( g_ibLastRoundAwpWereEnabled != 1 )
		{
			//Verbose AWP Now Enable
			verboseAllAwpStatus( true );
		}
		g_bAwpsAreEnabledThisRound = true;
	}
	
	//Reset awp and register people with them
	resetRegistrationNewRound( );
	registersAwpsNewRound( tAwpers, tAwpCount );
	registersAwpsNewRound( ctAwpers, ctAwpCount );
	
	g_bCanRegisterAwpViaPickup = true;
	
	return bool:Plugin_Continue;
}
public Action:Event_OnFreezeEnd(Handle:p_hEvent, const String:name[], bool:dontBroadcast)
{
	//If plugin is enabled
	if ( GetConVarInt( g_rawr ) && g_bIsMapOk )
		g_fTimeLimit = GetEngineTime( ) + ( g_fBuytime * 60.0 );
	
	return Plugin_Continue;
}

public Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	//This allow people to take AWPs on the ground, even if someone of their team normally prevent it
	//g_rawr_teamlimit_continuity will then be used to determined who keeps it (on round start)
	g_bCanRegisterAwpViaPickup = false;
	
	if ( GetEventInt( event, "winner" ) == 1 || GetConVarInt( g_rawr ) == 0 || !g_bIsMapOk ) //draw "enough player joins so restart game" / "people left"
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
	
	g_ibLastRoundAwpWereEnabled = _:g_bAwpsAreEnabledThisRound;
	
	return bool:Plugin_Continue;
}

//Need to check if awp first (cause if not; it can be before player spawn)
public Event_ItemPickup( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( !GetConVarInt( g_rawr ) || !g_bIsMapOk || !g_bCanRegisterAwpViaPickup )
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
			verboseReasonCantAwp( preventAwpReason, iClient );
			
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

//===== Timer =====

//Take for granted CVar enforcing 16k is == 1
public Action:Enforce16kDelayed( Handle:Timer, any:userId )
{
	new iClient = GetClientOfUserId( userId );
	if ( IsClientInGame( iClient ) )
	{
		if ( GetEntData( iClient, g_iAccount ) > 16000 ) //Check again, if massive buy :3
		{
			SetEntData( iClient, g_iAccount, 16000 );
		}
	}
	
	return Plugin_Continue;
}

//===== Callbacks (ConVarChange) =====
public SoundBuyChanged(Handle:cvar, String:oldValue[], String:newValue[])
{
	if ( g_bSoundPrecached && !StrEqual(oldValue, newValue) )
	{
		g_bSoundPrecached = false;
	}
}
public DisablePrefixesChanged(Handle:cvar, String:oldValue[], String:newValue[])
{
	verifyMap();
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
	if ( !g_bAwpsAreEnabledThisRound && GetConVarBool( g_rawr_minplayers_roundstart ) )
		return ReasonCantAwp:MINPLAYERS_RS;
	
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
	if ( 	( bothTeams && ( nbT < minPlayers || nbCT < minPlayers ) ) ||
			( !bothTeams && nbT + nbCT < minPlayers )
			)
		return ReasonCantAwp:MINPLAYERS;
	
	new maxAwpsPerTeam = GetConVarInt( g_rawr_teamlimit );
	new teamLimitAdditional = GetConVarInt( g_rawr_teamlimit_additional );
	
	if ( teamLimitAdditional )
	{
		maxAwpsPerTeam += getActivePlayersCount( true ) / teamLimitAdditional;
	}
	if ( iNbAwpsInTeam > maxAwpsPerTeam && maxAwpsPerTeam > 0 )
		return ReasonCantAwp:TEAMLIMIT;
	
	return ReasonCantAwp:NONE;
}

//Print the good verbose depending on why taking/buying an AWP was forbidden
verboseReasonCantAwp( ReasonCantAwp:preventAwpReason, iClient )
{
	switch ( preventAwpReason )
	{
		case ( ReasonCantAwp:WAITING ) :
		{
			verboseCantAwpWaiting( iClient );
		}
		case ( ReasonCantAwp:MINPLAYERS_RS ) :
		{
			verboseCantAwpNotEnoughPlayers( iClient, GetConVarBool( g_rawr_minplayers_bothteams ), GetConVarInt( g_rawr_minplayers ), true );
		}
		case ( ReasonCantAwp:MINPLAYERS ) : 
		{
			verboseCantAwpNotEnoughPlayers( iClient, GetConVarBool( g_rawr_minplayers_bothteams ), GetConVarInt( g_rawr_minplayers ) );
		}
		case ( ReasonCantAwp:TEAMLIMIT ) : 
		{
			new teamLimit = GetConVarInt( g_rawr_teamlimit );
			new teamLimitAdditional = GetConVarInt( g_rawr_teamlimit_additional );
			new nextAwpAt;
			if ( teamLimitAdditional )
			{
				teamLimit += getActivePlayersCount( true ) / teamLimitAdditional;
				
				new minPlayers = GetConVarInt( g_rawr_minplayers );
				new bool:bothTeams = GetConVarBool( g_rawr_minplayers_bothteams );
				nextAwpAt = ( ( ( getActivePlayersCount( true ) / teamLimitAdditional ) + 1 ) * teamLimitAdditional ) + 
					( bothTeams ? minPlayers*2 : minPlayers );
			}
			verboseLostAwpTeamLimitPriority( iClient, teamLimit, nextAwpAt );
		}
	}
}

//--Strips & removes

//We receive players in a array. They all have been checked previously so no need to valid ent check
stripPlayersPrimary( awpers[], any:size, bool:bothTeams, minPlayers )
{
	for ( new i; i < size; ++i )
	{
		//1- Strip/refund
		stripAwpFromAwper( awpers[ i ], GetConVarInt( g_rawr_action_inbuyzone ) == 2 );
		
		//2- Verbose
		verboseCantAwpNotEnoughPlayers( awpers[ i ], bothTeams, minPlayers );
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
	
	//Calculate nextAwpAt
	new nextAwpAt;
	new teamLimitAdditional = GetConVarInt( g_rawr_teamlimit_additional );
	if ( teamLimitAdditional )
	{
		new minPlayers = GetConVarInt( g_rawr_minplayers );
		new bool:bothTeams = GetConVarBool( g_rawr_minplayers_bothteams );
		nextAwpAt = ( ( ( getActivePlayersCount( true ) / teamLimitAdditional ) + 1 ) * teamLimitAdditional ) + 
			( bothTeams ? minPlayers*2 : minPlayers );
	}
	
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
				verboseLostAwpTeamLimitPriority( iAwper, limitPerTeam, nextAwpAt );
				
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
					verboseLostAwpTeamLimitPriority( iAwper, limitPerTeam, nextAwpAt );
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
			CS_DropWeapon( iClient, GetPlayerWeaponSlot( iClient, CS_SLOT_PRIMARY ), true, true );
		}
		default : //refund and strip
		{
			stripAwpFromAwper( iClient, cvarInBuyZone == 2 );
		}
	}
}

removeAwpFromAwperOutBuyzone( iClient )
{
	if ( !GetConVarBool( g_rawr_action_outbuyzone ) )
		stripAwpFromAwper( iClient );
	else
		CS_DropWeapon( iClient, GetPlayerWeaponSlot( iClient, CS_SLOT_PRIMARY ), true, true );
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
		SetEntData( iClient, g_iAccount, iMoney );
		if( iMoney > 16000 && GetConVarBool( g_rawr_action_respect16k ) )
		{
			//Fire timer to remove over 16k; useful if user didn't buy (i.e. kept during X rounds)
			CreateTimer( 0.0, Enforce16kDelayed, GetClientUserId( iClient ) );
		}
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

//v1.1.0 related
any:getActivePlayersCount( bool:shouldSubstractMinPlayers=false )
{
	new count;
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) && GetClientTeam( i ) > 1 )
		{
			++count;
		}
	}
	
	if ( shouldSubstractMinPlayers )
	{
		new minPlayers = GetConVarInt( g_rawr_minplayers );
		new bool:bothTeams = GetConVarBool( g_rawr_minplayers_bothteams );
		
		count -= bothTeams ? minPlayers * 2 : minPlayers;
	}
	
	return count;
}

//Map related
verifyMap()
{
	//1- Reset prefixes buffer
	for ( new i; i < sizeof(g_szDisablePrefixes); ++i )
	{
		g_szDisablePrefixes[ i ][ 0 ] = '\0';
	}
	
	//2- GetConVarValue
	decl String:szBufferCvar[ 256 ];
	GetConVarString( g_rawr_disable_prefixes, szBufferCvar, sizeof(szBufferCvar) );
	
	ExplodeString( szBufferCvar, " ", g_szDisablePrefixes, sizeof(g_szDisablePrefixes), sizeof(g_szDisablePrefixes[]) );
	
	//3- Mapname
	decl String:szBufferMap[ 64 ];
	GetCurrentMap( szBufferMap, sizeof(szBufferMap) );
	
	//4- Cmp
	for ( new i; i < sizeof(g_szDisablePrefixes) && g_szDisablePrefixes[ i ][ 0 ] != '\0'; ++i )
	{
		if ( StrContains( szBufferMap, g_szDisablePrefixes[ i ], false ) == 0)
		{
			g_bIsMapOk = false;
			return;
		}
	}
	
	g_bIsMapOk = true;
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

//=== A : To a client
verboseCanNowAwp( const iClient )
{
	if ( GetConVarBool( g_rawr_verbose_waitover ) )
		PrintToChat( iClient, "\x04%s\x01%t", g_szVerbosePrefix, "CanNowAwp" );
}
verboseCantAwpNotEnoughPlayers( const iClient, const bool:bothTeams, const minPlayers, bool:alternative_roundStart=false )
{
	if ( GetConVarBool( g_rawr_verbose_reason ) )
		if ( !alternative_roundStart )
			PrintToChat( iClient, "\x04%s\x01%t %t", g_szVerbosePrefix, "NotEnoughPlayers2Awp", 
				bothTeams ? "NotEnoughPlayers2AwpBothTeams" : "NotEnoughPlayers2AwpNotBothTeams",
				"\x04", minPlayers, "\x01" );
		else
			PrintToChat( iClient, "\x04%s\x01%t %t", g_szVerbosePrefix, "NEP2Awp_RS", 
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
verboseLostAwpTeamLimitPriority( const iClient, const limitPerTeam, const nextAwpAt )
{
	if ( GetConVarBool( g_rawr_verbose_reason ) )
	{
		decl String:szBuffer[ 256 ];
		
		FormatEx( szBuffer, sizeof(szBuffer), "\x04%s\x01%T", g_szVerbosePrefix, "TeamLimit-Priority", iClient, 
			"\x04", limitPerTeam, "\x01" );
			
		if ( nextAwpAt > 0 && nextAwpAt <= MaxClients )
		{
			PrintToChat( iClient, "%s %t", szBuffer, "NextAvailableAwpAt", "\x04", nextAwpAt, "\x01" );
			return;
		}
		
		PrintToChat( iClient, "%s", szBuffer );
	}
}
verboseRegisteredAwp( const iClient )
{
	if ( GetConVarBool( g_rawr_verbose_onuse ) )
		PrintToChat( iClient, "\x04%s\x01%t", g_szVerbosePrefix, "RegisteredAwp", "\x04", g_iNbRoundsWithAwp[ iClient ] + 1, "\x01", 
			"\x04", GetConVarInt( g_rawr_playerlimit ), "\x01" );
}
//=== B : To all
verboseAllAwpStatus( bool:statusIsEnabled )
{
	if ( GetConVarBool( g_rawr_verbose_roundstart ) )
		if ( statusIsEnabled )
			PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "AwpsNowEnabled", "\x03", "\x01" );
		else
			PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "AwpsNowDisabled", "\x03", "\x01" );
}