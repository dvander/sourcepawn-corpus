//Changelog = little optimization + DODS support + instant switch for teams + invinc more late
//Sources & credits from where I've taken the three default sounds :
//http://www.tf2sounds.com/

#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>
#include <teamsmanagementinterface>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.2.5"

public Plugin:myinfo =
{
	name = "Teams Management Interface",
	author = "RedSword / Bob Le Ponge",
	description = "Interface for managing teams (scrambling and switching players only at the moment)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//CVars
//scramble related
//others
new Handle:g_tmi_delay;
new Handle:g_tmi_blockDmg;

new Handle:g_tmi_sound;
new Handle:g_tmi_fadeColor;
new Handle:g_tmi_fadeColor_duration;

//sounds
#define	SOUNDS_STRING_PREPREFIX			"sound/"
#define	SOUNDS_STRING_PREFIX_SCRAMBLE	"misc/tmi_scramble"
//#define	SOUNDS_STRING_PREFIX_GENERIC	"misc/tmi_generic" //can be useful in the incoming versions
#define	SOUNDS_STRING_SUFFIX			".mp3"
new any:g_iSoundsCountScramble;
//new any:g_iSoundsCountGeneric; //can be useful in the incoming versions

//Vars
new bool:g_blockDamageOnPlayer;

//Sounds
new bool:g_bShouldPlaySound;

//FadeColor
new bool:g_bShouldFadeColor;

//Mod specific
enum Working_Mod
{
	GAME_UNKNOWN = 0,
	GAME_CSS = 1,
	GAME_CSGO = 2,
	GAME_DODS = 3
};

new Working_Mod:g_currentMod;

//Mod specific vars

//CSS = None
//DODS
new g_iPlayerPlayingCount_DODS;

//Timer
new bool:g_bTimerCanAct;

//A Teams Management Request
//The individuals ones; array[0] is for teams ones
new Handle:g_hTMRequestPlugin[ MAXPLAYERS + 1 ];
new g_iTMRequestReasonId[ MAXPLAYERS + 1 ];
new g_iTMRequestPriority[ MAXPLAYERS + 1 ];
new g_iTMRequestActionId[ MAXPLAYERS + 1 ];
new any:g_iTMRequestCustomValue[ MAXPLAYERS + 1 ];
new g_iTMRequestFlags[ MAXPLAYERS + 1 ];

//Forwards
new Handle:g_hForward_OnTMAcceptedReq = INVALID_HANDLE;
new Handle:g_hForward_OnTMAbandonedReq = INVALID_HANDLE;
new Handle:g_hForward_OnTMExecutedReq = INVALID_HANDLE;

//===== Forwards

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary( "teamsmanagement.core" );
	CreateNative( "RequestTeamsManagement", Native_RequestTeamsManagement );
	CreateNative( "CancelTeamsManagement", Native_CancelTeamsManagement );
	return APLRes_Success;
}

public OnPluginStart()
{
	//Allow multiples mod
	decl String:szBuffer[ 16 ];
	GetGameFolderName( szBuffer, sizeof(szBuffer) );
	
	if ( StrEqual( szBuffer, "cstrike", false ) )
		g_currentMod = Working_Mod:GAME_CSS;
	else if ( StrEqual( szBuffer, "csgo", false ) )
		g_currentMod = Working_Mod:GAME_CSGO;
	else if ( StrEqual( szBuffer, "dod", false ) )
		g_currentMod = Working_Mod:GAME_DODS;
	else
		g_currentMod = GAME_UNKNOWN;
	
	//CVARs
	CreateConVar( "teamsmanagementinterfaceversion", PLUGIN_VERSION, "Teams Management Interface's version", 
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	//Sounds
	g_tmi_sound = CreateConVar( "tmi_sound", "1", "Allow the interface to play a sound when teams are scrambled if the calling plugin doesn't. 0 = disabled, 1 = enabled. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
		
	//Fade
	g_tmi_fadeColor = CreateConVar( "tmi_fade", "1", "Allow the interface to fade-in players screens when teams are managed if the calling plugin doesn't. 0 = disabled, 1 = enabled. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_tmi_fadeColor_duration = CreateConVar( "tmi_fade_duration", "500", "Duration of the fade-in. Best values are around 250-1000. Def. 500.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1500.0 );
		
	//Other ConVars
	g_tmi_delay = CreateConVar( "tmi_delay", g_currentMod != GAME_CSGO ? "0.1" : "0.25", "Time in seconds before round start when team will be scrambled. Default 0.1 (0.25 CSGO).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.1 );
	g_tmi_blockDmg = CreateConVar( "tmi_blockdmg", "1", 
		"If damage is blocked between the moment people are changing teams and round start. 0=no, 1=yes (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	//Config
	AutoExecConfig( true, "teamsmanagementinterface" );
	
	//Hooks on events
	if ( g_currentMod != Working_Mod:GAME_DODS )
	{
		HookEvent( "round_start", Event_RoundStart );
		HookEvent( "round_end", Event_RoundEnd ); //can clean queries
	}
	else
	{
		//To count people; if 0 --> clean queries
		HookEvent("player_team", Event_PlayerTeam_DODS );
		
		HookEvent( "dod_round_start", Event_RoundStart );
		HookEvent( "dod_round_win", Event_RoundEnd ); //can clean queries
	}
	
	//Need to prevent scrambling if game end
	if ( g_currentMod == Working_Mod:GAME_CSS || g_currentMod == Working_Mod:GAME_CSGO )
		HookEvent( "cs_win_panel_match", Event_GameEnd );
	else if ( g_currentMod == Working_Mod:GAME_DODS )
		HookEvent( "dod_game_over", Event_GameEnd );
	
	//Forwards
	g_hForward_OnTMAcceptedReq = CreateGlobalForward( "OnTeamsManagementAcceptedRequest", 
		ET_Ignore, 
		Param_Any,
		Param_Cell,
		Param_Cell,
		Param_Any,
		Param_Cell,
		Param_Any,
		Param_Cell
		 );
		 
	g_hForward_OnTMAbandonedReq = CreateGlobalForward( "OnTeamsManagementAbandonedRequest", 
		ET_Ignore, 
		Param_Any,
		Param_Cell,
		Param_Cell,
		Param_Any,
		Param_Cell,
		Param_Any,
		Param_Cell
		 );
		 
	g_hForward_OnTMExecutedReq = CreateGlobalForward( "OnTeamsManagementExecutedRequest", 
		ET_Ignore, 
		Param_Any,
		Param_Cell,
		Param_Cell,
		Param_Any,
		Param_Cell,
		Param_Any,
		Param_Cell
		 );
}

//Precache sounds only
public OnConfigsExecuted()
{
	//If plugin is disabled or sound is disabled then don't precache
	if ( GetConVarInt( g_tmi_sound ) == 0 )
		return;
	
	decl String:szBufferShort[ 64 ];
	decl String:szBufferLong[ 64 ];
	
	new whereDigitIsShort = strlen( SOUNDS_STRING_PREFIX_SCRAMBLE );
	new whereIsDigitIsLong = strlen( SOUNDS_STRING_PREPREFIX ) + whereDigitIsShort;
	
	FormatEx( szBufferShort, sizeof(szBufferShort), "%s%d%s", SOUNDS_STRING_PREFIX_SCRAMBLE, 5, SOUNDS_STRING_SUFFIX ); //5--> just to say there is something
	FormatEx( szBufferLong, sizeof(szBufferLong), "%s%s", SOUNDS_STRING_PREPREFIX, szBufferShort );
	
	decl String:theDigit[ 2 ]; //2nd slot is needed for ESC char
	
	new i;
	g_iSoundsCountScramble = 0;
	//g_iSoundsCountGeneric = 0;
	
	//Up to 9 sounds
	//Scramble sounds first
	while ( i < 9 )
	{
		++i;
		
		IntToString( i, theDigit, sizeof(theDigit) );
		szBufferShort[ whereDigitIsShort ] = theDigit[ 0 ];
		szBufferLong[ whereIsDigitIsLong ] = theDigit[ 0 ];
		
		if ( FileExists( szBufferLong ) )
		{
			AddFileToDownloadsTable( szBufferLong );
			PrecacheSound( szBufferShort, true );
			++g_iSoundsCountScramble;
		}
		else
		{
			if ( i == 1)
				LogMessage("%s not found. Stopped counting sounds.", szBufferLong);
			break;
		}
	}
	
	cleanAllIndexes( );
}

public OnClientPutInServer(client)
{
	SDKHook( client, SDKHook_OnTakeDamage, Event_SDKHook_OnTakeDamage );
}

public OnMapStart()
{
	//Only needed for DODS
	if ( g_iPlayerPlayingCount_DODS != 0 )
	{
		g_iPlayerPlayingCount_DODS = 0;
		cleanAllIndexes( );
	}
}

//===== Events

public Action:Event_SDKHook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ( !g_blockDamageOnPlayer ) //Plugin not blocking dmg after scrambling 
		return Plugin_Continue;
	
	if ( damagetype == 64 && IsValidEntity( inflictor ) ) //Damage is explosion
	{
		decl String:szBuffer[ MAX_NAME_LENGTH ];
		GetEntityClassname( inflictor, szBuffer, sizeof(szBuffer) );
		
		if ( StrEqual( szBuffer, "planted_c4" ) ||
				StrEqual( szBuffer, "env_explosion" ) )
		{
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled; //Block damage
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bTimerCanAct = false; //1.2.3; this should now prevent invul (:$)
	g_blockDamageOnPlayer = false; //people can get hurt
	
	if ( g_bShouldPlaySound )
		playRandomScrambleSoundToAllPlayers( ); //Only scramble atm
	
	if ( g_bShouldFadeColor )
		fadeColorAllPlayers( );
	
	return bool:Plugin_Continue;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Needed, since 2 draw happen in a row when last player leave then join
	if ( ( ( g_currentMod == Working_Mod:GAME_CSS || g_currentMod == Working_Mod:GAME_CSGO ) && GetEventInt( event, "winner" ) > 1 ) ||
			( g_currentMod == Working_Mod:GAME_DODS && GetEventInt( event, "team" ) > 1 ) )
	{
		startTMCountdown( );
	}
	else
	{
		cleanAllIndexes( );
	}
	
	return bool:Plugin_Continue;
}

//Also handle disconnect !
public Event_PlayerTeam_DODS(Handle:event, const String:name[], bool:dontBroadcast)
{
	new newTeam = GetEventInt( event, "team" );
	new oldTeam = GetEventInt( event, "oldteam" );
	if ( newTeam > 1 && oldTeam <= 1 ) //joined an active team
	{
		++g_iPlayerPlayingCount_DODS;
	}
	else if ( newTeam <= 1 && oldTeam > 1 )
	{
		if ( --g_iPlayerPlayingCount_DODS == 0 )
		{
			cleanAllIndexes( );
		}
	}
	
	return bool:Plugin_Continue;
}



//Prevent end game scramble
public Event_GameEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bTimerCanAct = false;
	return bool:Plugin_Continue;
}

//=====Begin private (+ 1 timer)
//=====Scramble/team-swap related

startTMCountdown( )
{
	if ( g_currentMod != Working_Mod:GAME_UNKNOWN )
	{
		decl Float:timeB4Scramble; 
		
		if ( g_currentMod == Working_Mod:GAME_CSS || g_currentMod == Working_Mod:GAME_CSGO )
			timeB4Scramble = GetConVarFloat( FindConVar( "mp_round_restart_delay" ) );
		else
			timeB4Scramble = GetConVarFloat( FindConVar( "dod_bonusroundtime" ) );
		
		timeB4Scramble -= GetConVarFloat( g_tmi_delay );
		
		if ( timeB4Scramble > 0.1 ) //Minimum time to switch team correctly ( In CS that is :$ )
		{
			g_bTimerCanAct = true;
			CreateTimer( timeB4Scramble, teamsManagement, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE );
		}
		else
			teamsManagement( INVALID_HANDLE );
	}
	else
		teamsManagement( INVALID_HANDLE );
}

public Action:teamsManagement(Handle:timer)
{
	if ( !g_bTimerCanAct ) //1.2.3
	{
		return Plugin_Handled;
	}
	
	if ( GetConVarInt( g_tmi_blockDmg ) ) //Prevent friendly-fire (friend2foe / foe2friend)
		g_blockDamageOnPlayer = true;
	
	//Handle teams management first
	teamsManagement_teams();
	
	//Then individuals second
	teamsManagement_indivs();
	
	return Plugin_Handled;
}

teamsManagement_teams( )
{
	if ( g_hTMRequestPlugin[ 0 ] == INVALID_HANDLE ) 
		return;
	
	if ( g_iTMRequestActionId[ 0 ] != 0 )
	{
		//sound end-round
		if ( GetConVarInt( g_tmi_sound ) == 1 && g_iTMRequestFlags[ 0 ] & FTMI_SOUND )
			g_bShouldPlaySound = true;
			
		if ( GetConVarInt( g_tmi_fadeColor ) == 1 && g_iTMRequestFlags[ 0 ] & FTMI_FADE )
			g_bShouldFadeColor = true;
		
		//Create array and fill array
		decl playersId[ MAXPLAYERS ];
		new playersIdSize;
		
		for ( new i = 1; i <= MaxClients; ++i )
		{
			if ( IsClientInGame( i ) )
			{
				new iTeam = GetClientTeam( i );
				if ( iTeam == 2 ||
						iTeam == 3 )
				{
					playersId[ playersIdSize++ ] = i;
				}
			}
		}
		
		
		//Use array
		
		if ( playersIdSize > 0 )
		{
			if ( g_iTMRequestActionId[ 0 ] < 4 ) //1, 2, 3 = all "scrambles"
			{
				//Put at least 1 T and 1 CT
				//First setTeam
				new randomTeam = GetRandomInt( 2, 3 );
				new randomIndex = GetRandomInt( 0, playersIdSize - 1 );
				
				new randomClient = playersId[ randomIndex ];
				for ( new i = randomIndex; i < playersIdSize - 1; ++i )
				{
					playersId[ i ] = playersId[ i + 1 ];
				}
				--playersIdSize;
				
				setClientTeam( randomClient, randomTeam );
				if ( playersIdSize > 0 ) //If there is a second player; 2nd setTeam
				{
					if ( randomTeam == 2 )
					{
						randomTeam = 3; //recycle old var
					}
					else
					{
						randomTeam = 2;
					}
					
					randomIndex = GetRandomInt( 0, playersIdSize - 1 );
					
					randomClient = playersId[ randomIndex ];
					for ( new i = randomIndex; i < playersIdSize - 1; ++i )
					{
						playersId[ i ] = playersId[ i + 1 ];
					}
					--playersIdSize;
					
					setClientTeam( randomClient, randomTeam );
				}
				
				//Then, depending on reasonId
				//LOOP
				if ( g_iTMRequestActionId[ 0 ] == 2 ) //unfair scrambled
				{
					for ( new i; i < playersIdSize; ++i )
						setClientTeam( playersId[ i ], GetRandomInt( 2, 3 ) );
				}
				else if ( g_iTMRequestActionId[ 0 ] == 3 ) //specific scrambled
				{
					new requiredPlayers = ( g_iTMRequestCustomValue[ 0 ] & 0xFF ) - 1; //already put one
					new primordialTeam = g_iTMRequestCustomValue[ 0 ] >> 8;
					
					//Scramble
					decl tmpVar; //keep randomId
					for ( new i; i < playersIdSize && i < requiredPlayers; ++i )
					{
						randomTeam = GetRandomInt( 0, playersIdSize - 1 );//only use "randomTeam" for getting randomId
						tmpVar = playersId[ i ];
						playersId[ i ] = playersId[ randomTeam ];
						playersId[ randomTeam ] = tmpVar;
					}
					
					for ( new i; i < playersIdSize; ++i )
					{
						if ( requiredPlayers != 0 ) //if the primordial team has not enough people
						{
							randomTeam = primordialTeam + 2; //RECYCLING FTW
							--requiredPlayers;
						}
						else
						{
							randomTeam = any:(!primordialTeam ) + 2;
						}
						
						setClientTeam( playersId[ i ], randomTeam );
					}
				}
				else // if ( g_iTMRequestActionId[ 0 ] == 1 ) //fair scrambled
				{
					new nbRemainingToPutInEachTeam = ( playersIdSize + 1 ) / 2; //+1 to avoid 3 player problems
					new nbInT;
					new nbInCT;
					
					for ( new i; i <= playersIdSize - 1; ++i )
					{
						if ( nbInT == nbRemainingToPutInEachTeam ) //if T has enough people
						{//rest in CT
							randomTeam = 3; //RECYCLING FTW
						}
						else if ( nbInCT == nbRemainingToPutInEachTeam )
						{//rest in T
							randomTeam = 2;
						}
						else
						{
							randomTeam = GetRandomInt( 2, 3 );
							if ( randomTeam == 2 )
								++nbInT;
							else
								++nbInCT;
						}
						
						setClientTeam( playersId[ i ], randomTeam );
					}
				}
			}
			else // ( g_iTMRequestActionId[ 0 ] >= 4 ) // 4 == swap teams
			{
				for ( new i; i < playersIdSize; ++i )
				{
					setClientTeam( playersId[ i ], 5 - GetClientTeam( playersId[ i ] ) );
				}
			}
		}
	}
	
	forwardRequest( 0, g_hForward_OnTMExecutedReq );
	cleanIndex( 0 );
}
teamsManagement_indivs( )
{
	for ( new i = 1; i <= MaxClients; ++i )
	{
		manage_indiv( i );
	}
}
manage_indiv( any:iClient )
{
	if ( g_hTMRequestPlugin[ iClient ] != INVALID_HANDLE )
	{
		//Is InGame, since we take care of g_hTMRequestPlugin when client disconnect
		new iTeam = GetClientTeam(iClient);
		
		//Execute request
		switch ( g_iTMRequestActionId[ iClient ] )
		{
		case 1 :
			if ( iTeam != 1 ) //even if 0 !
			{
				ChangeClientTeam( iClient, 1 );
			}
		case 2 :
			if ( iTeam == 3 ) //I should add a "FTMI_FORCESWITCH" someday for this <.<
			{
				setClientTeam( iClient, 2 );
			}
		case 3 :
			if ( iTeam == 2 ) //I should add a "FTMI_FORCESWITCH" someday for this <.<
			{
				setClientTeam( iClient, 3 );
			}
		case 4 :
			if ( iTeam > 1 ) //I should add a "FTMI_FORCESWITCH" someday for this <.<
			{
				setClientTeam( iClient, iTeam == 2 ? 3 : 2 );
			}
		}
		
		forwardRequest( iClient, g_hForward_OnTMExecutedReq );
		cleanIndex( iClient );
	}
}

//Take for granted that the iClient is in team 2 or 3
setClientTeam(any:iClient, any:iTeam)
{
	if ( IsClientInGame( iClient ) && GetClientTeam( iClient ) != iTeam )
	{
		if ( g_currentMod == Working_Mod:GAME_DODS )
		{
			//Based on dod_teammanager_source.sp
			if ( IsPlayerAlive( iClient ) )
			{
				ChangeClientTeam( iClient, 1 );
			}
		}
		
		if ( g_currentMod == Working_Mod:GAME_CSS || g_currentMod == Working_Mod:GAME_CSGO )
			CS_SwitchTeam( iClient, iTeam );
		else 
			ChangeClientTeam( iClient, iTeam );
		
		if ( g_currentMod == Working_Mod:GAME_DODS )
		{
			//Based on dod_teammanager_source.sp
			ShowVGUIPanel( iClient, iTeam == 3 ? "class_ger" : "class_us", INVALID_HANDLE, false );
		}
	}
}

//=====End scramble/team-swap related

playRandomScrambleSoundToAllPlayers( )
{
	g_bShouldPlaySound = false;
	
	if ( g_iSoundsCountScramble == 0 )
	{
		LogMessage( "Couldn't precache sounds ; they may not have been found." );
		return;
	}
	
	decl String:szBufferShort[ 64 ];
	
	FormatEx( szBufferShort, sizeof(szBufferShort), "%s%d%s", SOUNDS_STRING_PREFIX_SCRAMBLE, GetRandomInt( 1, g_iSoundsCountScramble ), SOUNDS_STRING_SUFFIX );
	
	EmitSoundToAll( szBufferShort, SOUND_FROM_PLAYER, SNDCHAN_REPLACE );
}

fadeColorAllPlayers()
{
	CreateTimer( 0.1, DelayedFadeColorAllPlayers);
}
public Action:DelayedFadeColorAllPlayers(Handle:Timer) //Needed because sometimes RoundStart seems to be too soon and therefore fade gets cleaned
{
	g_bShouldFadeColor = false;
	
	new Handle:msg;
	new iDuration = GetConVarInt( g_tmi_fadeColor_duration );
	
	//For protobuf
	new colorTeam2[4] = { 0, 0, 0, 255 };
	new colorTeam3[4] = { 0, 0, 0, 255 };
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		if ( g_currentMod != Working_Mod:GAME_DODS )
		{
			colorTeam2[ 0 ] = 255; //t
			colorTeam3[ 2 ] = 255; //ct
		}
		else
		{
			colorTeam2[ 1 ] = 255; //green = allies
			colorTeam3[ 0 ] = 255; //red = axis
		}
	}
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( !IsClientInGame( i ) )
			continue;
		
		new iTeam = GetClientTeam( i );
		
		if ( iTeam < 2 )
			continue;
		
		//see http://wiki.alliedmods.net/User_Messages
		msg = StartMessageOne( "Fade", i );
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(msg, "duration", iDuration);
			PbSetInt(msg, "hold_time", 0);
			PbSetInt(msg, "flags", 1);
			PbSetColor(msg, "clr", iTeam == 2 ? colorTeam2 : colorTeam3);
		}
		else
		{
			BfWriteShort(msg, iDuration ); //duration
			BfWriteShort(msg, 0 ); //duration until reset
			BfWriteShort(msg, 1 ); //type
			
			if ( g_currentMod != Working_Mod:GAME_DODS )
			{
				BfWriteByte(msg, iTeam == 2 ? 255 : 0); //red
				BfWriteByte(msg, 0); //green
				BfWriteByte(msg, iTeam == 2 ? 0 : 255); //blue
			}
			else
			{
				BfWriteByte(msg, iTeam == 2 ? 0 : 255); //red
				BfWriteByte(msg, iTeam == 2 ? 255 : 0); //green
				BfWriteByte(msg, 0); //blue
			}
			
			BfWriteByte(msg, 255); //alpha
		}
		
		EndMessage();
	}
}

public Native_RequestTeamsManagement(Handle:hPlugin, iNumParams)
{
	new bool:bRetVal = true;
	new nativeCell5 = GetNativeCell( 5 );
	
	//Type
	if ( GetNativeCell( 3 ) & TeamsManagementType:TMT_TEAMS )
	{
		//Priority
		if ( GetNativeCell( 2 ) == -1 || GetNativeCell( 2 ) >= g_iTMRequestPriority[ 0 ] )
		{
			if ( g_hTMRequestPlugin[ 0 ] != INVALID_HANDLE )
			{ //replace old query
				forwardRequest( 0, g_hForward_OnTMAbandonedReq );
			}
			g_hTMRequestPlugin[ 0 ] = hPlugin;
			g_iTMRequestReasonId[ 0 ] = GetNativeCell( 1 );
			g_iTMRequestPriority[ 0 ] = GetNativeCell( 2 );
			g_iTMRequestActionId[ 0 ] = GetNativeCell( 4 );
			g_iTMRequestCustomValue[ 0 ] = nativeCell5;
			g_iTMRequestFlags[ 0 ] = GetNativeCell( 6 );
			
			forwardRequest( 0, g_hForward_OnTMAcceptedReq );
			
			if ( g_iTMRequestFlags[ 0 ] & FTMI_INSTANT )
			{
				teamsManagement_teams();
			}
		}
		else
		{
			bRetVal = false;
		}
	}
	
	if ( GetNativeCell( 3 ) & TeamsManagementType:TMT_INDIVIDUALS )
	{
		if ( nativeCell5 > MAXPLAYERS ) //Prevent possible oob crashes
		{
			LogMessage( "A plugin gave a bad clientId (%d) to TMI", nativeCell5 );
			return false;
		}
		if ( GetNativeCell( 2 ) == -1 || GetNativeCell( 2 ) >= g_iTMRequestPriority[ nativeCell5 ] )
		{
			if ( g_hTMRequestPlugin[ nativeCell5 ] != INVALID_HANDLE )
			{
				forwardRequest( nativeCell5, g_hForward_OnTMAbandonedReq );
			}
			g_hTMRequestPlugin[ nativeCell5 ] = hPlugin;
			g_iTMRequestReasonId[ nativeCell5 ] = GetNativeCell( 1 );
			g_iTMRequestPriority[ nativeCell5 ] = GetNativeCell( 2 );
			g_iTMRequestActionId[ nativeCell5 ] = GetNativeCell( 4 );
			g_iTMRequestCustomValue[ nativeCell5 ] = nativeCell5;
			g_iTMRequestFlags[ nativeCell5 ] = GetNativeCell( 6 );
			
			forwardRequest( nativeCell5, g_hForward_OnTMAcceptedReq );
			
			if ( g_iTMRequestFlags[ nativeCell5 ] & FTMI_INSTANT )
			{
				manage_indiv( nativeCell5 );
			}
		}
		else
		{
			bRetVal = false;
		}
	}
	
	return bRetVal;
}
public Native_CancelTeamsManagement(Handle:hPlugin, iNumParams)
{
	new bool:retVal = false;
	new nativeCell2 = GetNativeCell( 2 );
	//Type
	if ( GetNativeCell( 1 ) & TeamsManagementType:TMT_TEAMS )
	{
		//Priority
		if ( g_hTMRequestPlugin[ 0 ] != INVALID_HANDLE && ( GetNativeCell( 2 ) == -1 || g_iTMRequestPriority[ 0 ] <= nativeCell2 ) )
		{
			forwardRequest( 0, g_hForward_OnTMAbandonedReq );
			cleanIndex( 0 );
			retVal = true;
		}
	}
	
	if ( GetNativeCell( 1 ) & TeamsManagementType:TMT_INDIVIDUALS )
	{
		if ( nativeCell2 == -1 ) 
		{
			cleanAllIndexesBut0( );
		}
		else 
		{
			for ( new i = 1; i <= MaxClients; ++i )
			{
				if ( g_hTMRequestPlugin[ i ] != INVALID_HANDLE && g_iTMRequestPriority[ i ] <= nativeCell2 )
				{
					forwardRequest( i, g_hForward_OnTMAbandonedReq );
					cleanIndex( i );
					retVal = true;
				}
			}
		}
	}
	
	return retVal;
}

forwardRequest( i, Handle:gForward )
{
	Call_StartForward( gForward );
	Call_PushCell( g_hTMRequestPlugin[ i ] );
	Call_PushCell( g_iTMRequestReasonId[ i ] );
	Call_PushCell( g_iTMRequestPriority[ i ] );
	Call_PushCell( i == 0 ? TMT_TEAMS : TMT_INDIVIDUALS );
	Call_PushCell( g_iTMRequestActionId[ i ] );
	Call_PushCell( g_iTMRequestCustomValue[ i ] );
	Call_PushCell( g_iTMRequestFlags[ i ] );
	Call_Finish();
}

public OnClientDisconnect( iClient )
{
	//if player was going to be switch; it's up to the caller plugin to make sure that doesn't affect anything
	cleanIndex( iClient );
}

cleanIndex( index )
{
	g_hTMRequestPlugin[ index ] = INVALID_HANDLE;
	g_iTMRequestReasonId[ index ] = 0;
	g_iTMRequestPriority[ index ] = 0;
	g_iTMRequestActionId[ index ] = 0;
	g_iTMRequestCustomValue[ index ] = 0;
	g_iTMRequestFlags[ index ] = 0;
}

//we have to prevent switching people after they change 
cleanAllIndexes( )
{
	//screw calling moar functions (^)
	for ( new index; index <= MAXPLAYERS; ++index )
	{
	
		g_hTMRequestPlugin[ index ] = INVALID_HANDLE;
		g_iTMRequestReasonId[ index ] = 0;
		g_iTMRequestPriority[ index ] = 0;
		g_iTMRequestActionId[ index ] = 0;
		g_iTMRequestCustomValue[ index ] = 0;
		g_iTMRequestFlags[ index ] = 0;
	}
}
cleanAllIndexesBut0( )
{
	//screw calling moar functions (^)
	for ( new index = 1; index <= MAXPLAYERS; ++index )
	{
	
		g_hTMRequestPlugin[ index ] = INVALID_HANDLE;
		g_iTMRequestReasonId[ index ] = 0;
		g_iTMRequestPriority[ index ] = 0;
		g_iTMRequestActionId[ index ] = 0;
		g_iTMRequestCustomValue[ index ] = 0;
		g_iTMRequestFlags[ index ] = 0;
	}
}