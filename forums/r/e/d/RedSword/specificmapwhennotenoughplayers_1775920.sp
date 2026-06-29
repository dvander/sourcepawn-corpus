//Some credit to TigerOx @ "Default Map Changer" plugin who inspired that plugin

//Note when changing map, players disconnect (NOT-post), then map end, then they disconnect-post, then map start

/**
* Changelog :
* 1.0.1 : Fixed bug when MapChooser not found. Fixed bug that could result in really long game (someone joined when no one was there; game restarted with high mp_timelimit).
* 1.1.0 : Added mp_maxrounds support. CS:GO base config should now be valid. Should now also support mapchooser_extended. Safer map change.
*/

#pragma semicolon 1

#include <sdktools>
#include <mapchooser> //for HasEndOfMapVoteFinished, CanMapChooserStartVote

#define PLUGIN_VERSION "1.1.0"
#define DEBUG_MOD

public Plugin:myinfo =
{
	name = "Specific Map When Not Enough Players",
	author = "RedSword / Bob Le Ponge",
	description = "Set a specific map when not enough players are present",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//CVars
//new Handle:g_hSMWNEP;
//new Handle:g_hSMWNEP_map;
//new Handle:g_hSMWNEP_timeExtension;
//new Handle:g_hSMWNEP_beforeVote;
//new Handle:g_hSMWNEP_nbPlayers;
//new Handle:g_hSMWNEP_verbose;

new bool:g_bIsPluginEnabled;
new String:g_szMap[ 128 ];
new g_iEnoughPlayers;
new g_iTimeInSecondsBeforeVote;
new Float:g_fTimeExtension;
new g_iTimeInSecondsToJoin;
new g_iRoundsBeforeVote;
new g_iRoundsExtension;
new String:g_szVerbosePrefix[ 16 ];
new g_bVerboseOn;

//Vars
new g_iCurrentPlayerCount;
new bool:g_bIsMapChanging;
new Handle:g_hTimerBeforeExtensionCheck;
new Handle:g_hTimerBeforeCanChangeMap;
new bool:g_bJoinTimeIsOver;
new bool:g_bMapChangeOrdered;
new bool:g_bIsFakeClient[ MAXPLAYERS + 1 ]; //used to count clients correctly (disconnect vs mapchange)
new g_iInitialTimelimit;
new g_iInitialMaxRounds;

//Handle on tier-party handles
new Handle:g_hSm_mapvote_starttime;
new Handle:g_hSm_mapvote_startround;
new Handle:g_hMp_timeLimit;
new Handle:g_hMp_maxRounds;
new Handle:g_hMp_warmupTime;

//Mod specific
enum Working_Mod
{
	GAME_CSS = 1,
	GAME_CSGO,
	GAME_ELSE
};

new Working_Mod:g_currentMod;

//===== Forwards =====

public OnPluginStart()
{
	if (!LibraryExists("mapchooser"))
	{
		SetFailState("Mapchooser needed to execute this plugin.");
		return;
	}
	
	//Allow multiples mod specific things
	decl String:szBuffer[16];
	GetGameFolderName(szBuffer, sizeof(szBuffer));
	
	if (StrEqual(szBuffer, "cstrike", false))
		g_currentMod = Working_Mod:GAME_CSS;
	else if (StrEqual(szBuffer, "csgo", false))
		g_currentMod = Working_Mod:GAME_CSGO;
	else
		g_currentMod = Working_Mod:GAME_ELSE;
	
	//CVARs
	decl Handle:hRandom; // KyleS hates handles !!! (everyone needs to know this)
	
	HookConVarChange( hRandom = CreateConVar("specificmapwhennotenoughplayersversion", PLUGIN_VERSION, "Specific Map When Not Enough Players version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD ), OnVersionChanged );
	HookConVarChange( hRandom = CreateConVar("smwnep", "1.0", "Is plugin enabled ? 0=No, 1=Yes.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0), OnPluginEnableChanged );
	g_bIsPluginEnabled = GetConVarBool( hRandom );
	HookConVarChange( hRandom = CreateConVar("smwnep_map", "de_dust2", "Specific map to be in when not enough players are present. Def. 'de_dust2'.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY ), OnSpecificMapChanged );
	GetConVarString( hRandom, g_szMap, sizeof(g_szMap) );
	HookConVarChange( hRandom = CreateConVar("smwnep_nbplayers", "8.0", "Number of players considered to be enough. Below --> specific map. Def. 8.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 128.0 ), OnNbPlayersChanged );
	g_iEnoughPlayers = GetConVarInt( hRandom );
	
	HookConVarChange( hRandom = CreateConVar("smwnep_jointime", "1.0", "Time in minutes players have to join before the map can be changed. If CSGO, warmuptime is added. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, g_currentMod != Working_Mod:GAME_CSGO ? 1.0 : 0.0 ), OnJoinTimeChanged );
	g_iTimeInSecondsToJoin = RoundToFloor( GetConVarFloat( hRandom ) * 60.0 );
	if ( g_iTimeInSecondsToJoin == 0 )
	{
		g_iTimeInSecondsToJoin = 1;
	}
	HookConVarChange( hRandom = CreateConVar("smwnep_timebeforevotetoextend", "1.0", "How long in minutes before mapchooser's vote, shall the map be extended. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0 ), OnTimeBeforeVoteChanged );
	g_iTimeInSecondsBeforeVote = RoundToFloor( GetConVarFloat( hRandom ) * 60.0 );
	if ( g_iTimeInSecondsBeforeVote == 0 )
	{
		g_iTimeInSecondsBeforeVote = 1;
	}
	HookConVarChange( hRandom = CreateConVar( "smwnep_timeextension", "5.0", "Extend map of X minutes every time the 'smwnep_timebeforevotetoextend' time is reached. Def. 5.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.5 ), OnTimeExtensionChanged );
	g_fTimeExtension = GetConVarFloat( hRandom );
	
	HookConVarChange( hRandom = CreateConVar("smwnep_roundsbeforevotetoextend", "1.0", "How many rounds before mapchooser's vote, shall the map be extended. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0 ), OnRoundsBeforeVoteChanged );
	g_iRoundsBeforeVote = GetConVarInt( hRandom );
	if ( g_iRoundsBeforeVote == 0 )
	{
		g_iRoundsBeforeVote = 1;
	}
	HookConVarChange( hRandom = CreateConVar( "smwnep_roundsextension", "3.0", "Extend map of X rounds every time the 'smwnep_roundsbeforevotetoextend' round is reached. Def. 3.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0 ), OnRoundsExtensionChanged );
	g_iRoundsExtension = GetConVarInt( hRandom );
	
	HookConVarChange( hRandom = CreateConVar("smwnep_verboseprefix", "[SM] ", "Verbose's prefix. Default '[SM] '.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY ), OnVerbosePrefixChanged );
	GetConVarString( hRandom, g_szVerbosePrefix, sizeof(g_szVerbosePrefix) );
	
	HookConVarChange( hRandom = CreateConVar("smwnep_verbose", "1.0", "Tell players what is happening. 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0), OnVerboseOnChanged );
	g_bVerboseOn = GetConVarBool( hRandom );
	
	//Config
	AutoExecConfig(true, "specificmapwhennotenoughplayers");
	
	//Count players
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) && !IsFakeClient( i ) )
		{
			++g_iCurrentPlayerCount;
		}
	}
	
	LoadTranslations("specificmapwhennotenoughplayers.phrases");
	
	//Events
	if ( g_currentMod != Working_Mod:GAME_ELSE )
	{
		HookEvent( "round_end", Event_RoundEnd );
	}
}

public OnConfigsExecuted()
{
	g_iInitialTimelimit = GetConVarInt( g_hMp_timeLimit );
	g_iInitialMaxRounds = GetConVarInt( g_hMp_maxRounds );
	
	if ( !g_bIsPluginEnabled )
		return;
	//Reset timer (as in mapchooser)
	setupExtensionTimer();
}

public OnClientConnected(iClient)
{
	if ( !IsFakeClient( iClient ) )
	{
		++g_iCurrentPlayerCount;
	}
}

public OnClientDisconnect(iClient)
{
	g_bIsFakeClient[ iClient ] = IsFakeClient( iClient );
}
public OnClientDisconnect_Post(iClient)
{
	if ( !g_bIsMapChanging && !g_bIsFakeClient[ iClient ] )
	{
		--g_iCurrentPlayerCount;
		
		checkIfShouldChangeSomething();
	}
}

public OnMapStart()
{
	g_hSm_mapvote_starttime = FindConVar( "sm_mapvote_start" );
	if ( g_hSm_mapvote_starttime == INVALID_HANDLE )
	{
		g_hSm_mapvote_starttime = FindConVar( "mce_starttime" );
	}
	g_hSm_mapvote_startround = FindConVar ( "sm_mapvote_startround" );
	if ( g_hSm_mapvote_startround == INVALID_HANDLE )
	{
		g_hSm_mapvote_startround = FindConVar( "mce_startround" );
	}
	
	g_hMp_timeLimit = FindConVar( "mp_timelimit" );
	g_hMp_maxRounds = FindConVar( "mp_maxrounds" );
	g_hMp_warmupTime = FindConVar( "mp_warmuptime" );
	g_bIsMapChanging = false;
	g_bJoinTimeIsOver = false;
	g_bMapChangeOrdered = false;
	
	if ( !g_bIsPluginEnabled )
		return;
	
	setupBeforeCanChangeMapTimer();
}

public OnMapEnd() //happen after disconnects
{
	g_bIsMapChanging = true;
	g_iCurrentPlayerCount = 0;
	
	if ( g_hTimerBeforeExtensionCheck != INVALID_HANDLE )
	{
		KillTimer( g_hTimerBeforeExtensionCheck );
		g_hTimerBeforeExtensionCheck = INVALID_HANDLE;
	}
}

public OnMapTimeLeftChanged()
{
	//timer
	CreateTimer( 0.1, Timer_DelayOnMapTimeLeftChanged );
}

//=== Events
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iWinner = GetEventInt( event, "winner" );
	if ( iWinner == 1 ) //draw "enough player joins so restart game" / "people left"--> no round++/verbose
	{
		//Reset mp_timelimit
		new cvarFlags = GetConVarFlags( g_hMp_timeLimit );
		SetConVarFlags( g_hMp_timeLimit, cvarFlags & ~FCVAR_NOTIFY );
		
		SetConVarInt( g_hMp_timeLimit, g_iInitialTimelimit );
		
		SetConVarFlags( g_hMp_timeLimit, cvarFlags );
		
		//Reset mp_maxrounds
		cvarFlags = GetConVarFlags( g_hMp_maxRounds );
		SetConVarFlags( g_hMp_maxRounds, cvarFlags & ~FCVAR_NOTIFY );
		
		SetConVarInt( g_hMp_maxRounds, g_iInitialMaxRounds );
		
		SetConVarFlags( g_hMp_maxRounds, cvarFlags );
	}
	//Teamscores are updated after RoundEnd event (be it pre or post)
	else if ( GetConVarInt( g_hMp_maxRounds ) - ( GetTeamScore(2) + GetTeamScore(3) ) <= 
		 GetConVarInt( g_hSm_mapvote_startround ) + g_iRoundsBeforeVote )
	{
		//If good map && not enough players --> extend
		if ( g_iCurrentPlayerCount < g_iEnoughPlayers )
		{
			decl String:szCurrentMap[ 128 ];
			GetCurrentMap( szCurrentMap, sizeof(szCurrentMap) );
			
			if ( StrEqual( szCurrentMap, g_szMap, false ) )
			{
				new cvarFlags = GetConVarFlags( g_hMp_maxRounds );
				SetConVarFlags( g_hMp_maxRounds, cvarFlags & ~FCVAR_NOTIFY );
				
				SetConVarInt( g_hMp_maxRounds, GetConVarInt( g_hMp_maxRounds ) + g_iRoundsExtension );
				
				SetConVarFlags( g_hMp_maxRounds, cvarFlags );
				
				verboseExtendRounds();
			}
		}
	}
	
	return bool:Plugin_Continue;
}

//=== Timers

public Action:Timer_DelayOnMapTimeLeftChanged(Handle:timer)
{
	setupExtensionTimer();
}

//Timer vote hook
public Action:Timer_ExtendMap(Handle:timer) //no need to renew timer, as OnMapTimeLeftChanged forward will be called
{
	//If good map && not enough players --> extend
	if ( g_iCurrentPlayerCount < g_iEnoughPlayers )
	{
		decl String:szCurrentMap[ 128 ];
		GetCurrentMap( szCurrentMap, sizeof(szCurrentMap) );
		
		if ( StrEqual( szCurrentMap, g_szMap, false ) )
		{
			new cvarFlags = GetConVarFlags( g_hMp_timeLimit );
			SetConVarFlags( g_hMp_timeLimit, cvarFlags & ~FCVAR_NOTIFY );
			
			ExtendMapTimeLimit( RoundToFloor( g_fTimeExtension * 60.0 ) );
			
			SetConVarFlags( g_hMp_timeLimit, cvarFlags );
			
			//Todo verbose : extend
			verboseExtendTime();
		}
	}
	
	g_hTimerBeforeExtensionCheck = INVALID_HANDLE;
	
	return Plugin_Continue;
}

public Action:Timer_PluginCanChangeMap(Handle:timer)
{
	g_bJoinTimeIsOver = true;
	g_hTimerBeforeCanChangeMap = INVALID_HANDLE;
	
	checkIfShouldChangeSomething();
	
	return Plugin_Continue;
}

//===== Private =====

checkIfShouldChangeSomething()
{
	if ( !g_bIsPluginEnabled || !g_bJoinTimeIsOver )
		return;
	
	//If we had not enough players
	if ( g_iCurrentPlayerCount < g_iEnoughPlayers )
	{
		//If 3m vote is done
		if ( HasEndOfMapVoteFinished() ) //if vote ended, not enough players --> back to specific
		{
			checkForNextMap();
		}
		else
		{
			decl String:szCurrentMap[ 128 ];
			GetCurrentMap( szCurrentMap, sizeof(szCurrentMap) );
			
			if ( !StrEqual( szCurrentMap, g_szMap, false ) )
			{
				checkForNextMap();
				SetNextMap( g_szMap );
			}
			//else
			//{
			//	//We're on the good map, do nothing
			//}
		}
	}
}

checkForNextMap()
{
	if ( !IsMapValid( g_szMap ) )
	{
		LogMessage( "Map '%s' was not found", g_szMap );
		return;
	}
	
	if ( g_iCurrentPlayerCount == 0 )
	{
		ForceChangeLevel( g_szMap, "Not enough players (SMWNEP plugin)" );
	}
	else
	{
		//SetNextMap( g_szMap ); //would work if it wasn't from mapchooser vote !! rwar
		
		new cvarFlags = GetConVarFlags( g_hMp_timeLimit );
		SetConVarFlags( g_hMp_timeLimit, cvarFlags & ~FCVAR_NOTIFY );
		
		ServerCommand( "sm_setnextmap %s", g_szMap ); //mapchooser related !
		ServerCommand( "mp_timelimit 1" ); //SetNextMap denies the vote from happening
		
		SetConVarFlags( g_hMp_timeLimit, cvarFlags );
		
		verboseMapChange();
	}
	
	g_bMapChangeOrdered = true;
}

//=== Setup timers !

setupExtensionTimer()
{
	if ( g_iInitialTimelimit == 0 ) //No timer needed when we don't have a time limit
		return;
	
	new timeBeforeExtend = GetConVarInt( g_hSm_mapvote_starttime ) * 60 + g_iTimeInSecondsBeforeVote; //wtf, in mapchooser "GetConVarInt(g_Cvar_StartTime) * 60" ?? OH RLY ??
	
	if ( g_hTimerBeforeExtensionCheck != INVALID_HANDLE )
	{
		KillTimer( g_hTimerBeforeExtensionCheck );
		g_hTimerBeforeExtensionCheck = INVALID_HANDLE;
	}
	
	new remainingTime;
	
	if ( GetMapTimeLeft( remainingTime ) && remainingTime > 0 && CanMapChooserStartVote() )
	{
		g_hTimerBeforeExtensionCheck = CreateTimer( float( remainingTime - timeBeforeExtend ), Timer_ExtendMap );
	}
}

setupBeforeCanChangeMapTimer()
{
	//if ( g_iInitialTimelimit == 0 ) //No timer needed when we don't have a time limit
	//	return; //removed in 1.1.0
	
	decl timeLimit;
	decl timeLeftSec;
	
	if ( g_hTimerBeforeCanChangeMap != INVALID_HANDLE )
	{
		KillTimer( g_hTimerBeforeCanChangeMap );
		g_hTimerBeforeCanChangeMap = INVALID_HANDLE;
	}
	
	if ( GetMapTimeLimit( timeLimit ) && timeLimit > 0 && GetMapTimeLeft( timeLeftSec ) && timeLeftSec != 0 ) 
	{
		new timeLimitSec = timeLimit * 60;
		
		//timeLeftSec = -1 if no player on map change; but we still want to start our timer
		if ( timeLeftSec == -1 )
		{
			timeLeftSec = timeLimitSec;
		}
		
		new timeElapsed = timeLimitSec - timeLeftSec;
		
		if ( timeElapsed < g_iTimeInSecondsToJoin )
		{
			g_hTimerBeforeCanChangeMap = CreateTimer( float( g_iTimeInSecondsToJoin - timeElapsed ), Timer_PluginCanChangeMap );
		}
	}
	else
	{
		//For rounds
		new totalTimeBeforeJoin = g_iTimeInSecondsToJoin;
		
		if ( g_currentMod == Working_Mod:GAME_CSGO )
		{
			totalTimeBeforeJoin += GetConVarInt( g_hMp_warmupTime );
		}
		
		g_hTimerBeforeCanChangeMap = CreateTimer( float( totalTimeBeforeJoin ), Timer_PluginCanChangeMap );
	}
}

//===== Verbose =====

verboseExtendTime()
{
	if ( g_bVerboseOn )
	{
		PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "ExtendTime", "\x04", g_fTimeExtension, "\x01" );
	}
}
verboseExtendRounds()
{
	if ( g_bVerboseOn )
	{
		PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "ExtendRounds", "\x04", g_iRoundsExtension, "\x01" );
	}
}
verboseMapChange()
{
	if ( g_bVerboseOn && !g_bMapChangeOrdered )
	{
		PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "ChangeMap", "\x04", g_szMap, "\x01" );
	}
}

//===== HookConVarChange =====

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if(!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}
public OnPluginEnableChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_bIsPluginEnabled = GetConVarBool( cvar );
	
	setupExtensionTimer();
}
public OnSpecificMapChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	strcopy( g_szMap, sizeof(g_szMap), newValue );
	
	checkIfShouldChangeSomething();
}
public OnNbPlayersChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_iEnoughPlayers = GetConVarInt( cvar );
	
	checkIfShouldChangeSomething();
}
public OnJoinTimeChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_iTimeInSecondsToJoin = RoundToFloor( GetConVarFloat( cvar ) * 60.0 );
	
	if ( g_iTimeInSecondsToJoin == 0 )
	{
		g_iTimeInSecondsToJoin = 1;
	}
	
	setupBeforeCanChangeMapTimer();
}

public OnTimeBeforeVoteChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_iTimeInSecondsBeforeVote = RoundToFloor( GetConVarFloat( cvar ) * 60.0 );
	
	if ( g_iTimeInSecondsBeforeVote == 0 )
	{
		g_iTimeInSecondsBeforeVote = 1;
	}
	
	if ( !g_bIsPluginEnabled )
		return;
	
	setupExtensionTimer();
}
public OnTimeExtensionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_fTimeExtension = GetConVarFloat( cvar );
}

public OnRoundsBeforeVoteChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_iRoundsBeforeVote = GetConVarInt( cvar );
	if ( g_iRoundsBeforeVote == 0 )
	{
		g_iRoundsBeforeVote = 1;
	}
}
public OnRoundsExtensionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_iRoundsExtension = GetConVarInt( cvar );
}

public OnVerboseOnChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	g_bVerboseOn = GetConVarBool( cvar );
}
public OnVerbosePrefixChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	strcopy( g_szVerbosePrefix, sizeof(g_szVerbosePrefix), newValue );
}