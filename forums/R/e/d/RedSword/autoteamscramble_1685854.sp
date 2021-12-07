//Sources & credits from where I've taken the default sounds :
//http://www.tf2sounds.com/

#pragma semicolon 1

#include <sdktools>
#include <teamsmanagementinterface>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "2.2.0"

public Plugin:myinfo =
{
	name = "Auto Team Scramble",
	author = "RedSword / Bob Le Ponge",
	description = "Scramble teams when certain conditions are met.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//CVars
new Handle:g_ats;

//when g_ats == 3
new Handle:g_ats_required_value;
new Handle:g_ats_required_team;

//scramble related
//rules
new Handle:g_ats_round;
new Handle:g_ats_bestof;
new Handle:g_ats_winstreak;
new Handle:g_ats_inequity;
//others
new Handle:g_ats_real_score;
new Handle:g_ats_minplayers;

//verbose
new Handle:g_ats_verbose_score;
new Handle:g_ats_verbose_rule;
new Handle:g_ats_verbose_scramble;

new Handle:g_ats_sound;
new Handle:g_ats_fadeColor;

//==Vars
new any:g_roundNumber; //EveryXRounds
new any:g_TScore; //BestOfx
new any:g_CTScore; //BestOfx
new bool:g_lastRoundWinnerIsT; //winstreak
new any:g_winStreak; //winstreak

//Better use of interface
#define ATS_PRIORITY 50
enum Scramble_Reason
{
	REASON_ROUND = 1,
	REASON_BESTOF,
	REASON_WINSTREAK,
	REASON_INEQUITY
};

//Mod specific
enum Working_Mod
{
	GAME_UNKNOWN = 0,
	GAME_CSS = 1,
	GAME_CSGO = 2,
	GAME_DODS = 3
};

new Working_Mod:g_currentMod;

//===== Forwards

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
	CreateConVar( "autoteamscrambleversion", PLUGIN_VERSION, "Team Scramble version", 
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_ats = CreateConVar( "ats", "1", "Is the plugin enabled? 0 = disabled, 1 = enabled (fair team), 2 = enabled (possible unfair, i.e. 12v5), 3 = for custom maps (i.e. jailbreak 2vALL, 4 = swap teams). Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 4.0 );
		
	//Rules
	g_ats_round = CreateConVar( "ats_rule_round", "0", "Scramble every X rounds. 0 = disabled, 1+ = enabled. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_ats_bestof = CreateConVar( "ats_rule_bestof", "0", "Scramble when a team win a best-of-X (odd number recommended; even will go with an additionnal round; i.e. 4 -> 5). 0 = disabled, 1+ = enabled. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_ats_winstreak = CreateConVar( "ats_rule_winstreak", "4", "Scramble when a team win X times in a row. 0 = disabled, 1+ = enabled. Def. 4.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_ats_inequity = CreateConVar( "ats_rule_inequity", "0", "Scramble when a team has a X wins lead over his opponent. 0 = disabled, 1+ = enabled. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0 );
	
	//Verboses
	g_ats_verbose_score = CreateConVar( "ats_verbose_score", "1", "Tell players the score after every rounds. 0 = disabled, 1 = enabled (Default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_ats_verbose_rule = CreateConVar( "ats_verbose_rule", "1", "Tell players every X rounds how team can get scrambled. 0 = disabled, 1+ = enabled. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_ats_verbose_scramble = CreateConVar( "ats_verbose_scramble", "1", "Tell players when team are scrambled. 0 = disabled, 1 = enabled (Default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Sounds
	g_ats_sound = CreateConVar( "ats_sound", "1", "Ask TMI to play a sound when teams are scrambled? 1=Yes, 0=No. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
		
	//Fade
	g_ats_fadeColor = CreateConVar( "ats_fade", "1", "Fade-in players screens when teams are scrambled. 0 = disabled, 1 = enabled. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Real score
	g_ats_real_score = CreateConVar( "ats_real_score", "1", "Reset team scores when scrambling teams (recommended for timelimits only). 0 = disabled, 1 = enabled (Default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Min players
	g_ats_minplayers = CreateConVar( "ats_minplayers", "8", "Number of players needed in the playable teams (i.e. T/CT in CS) to scramble.", 
		FCVAR_PLUGIN, true, 0.0 );
	
	//3rd mode
	g_ats_required_value = CreateConVar( "ats_required_value", "1", "If CVar 'ats' value is '3', then a team will have X players. Min 1.", 
		FCVAR_PLUGIN, true, 1.0, true, 64.0 );
	g_ats_required_team = CreateConVar( "ats_required_team", "1", "If CVar 'ats' value is '3', then specified team will have an exact number of players. 0 = terro, 1 = CTs.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Config
	AutoExecConfig( true, "autoteamscramble" );
	
	//Hooks on events
	if ( g_currentMod != Working_Mod:GAME_DODS )
	{
		HookEvent( "round_start", Event_RoundStart, EventHookMode_Pre );
		HookEvent( "round_end", Event_RoundEnd ); //can clean queries
	}
	else
	{
		HookEvent( "dod_round_start", Event_RoundStart, EventHookMode_Pre );
		HookEvent( "dod_round_win", Event_RoundEnd ); //can clean queries
	}
	
	//Translation file
	LoadTranslations( "autoteamscramble.phrases" );
}

//Precache sounds only

public OnAllPluginsLoaded()
{
	if ( !LibraryExists( "teamsmanagement.core" ) ) 
		SetFailState("Unabled to find plugin: Teams Management Interface");
}

//===== Events

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//No need to check if plugin is enable (initialization only)
	if ( GetTeamScore( 2 ) + GetTeamScore( 3 ) == 0 ) //first round
	{
		g_roundNumber = 0;
		g_TScore = 0;
		g_CTScore = 0;
		g_winStreak = 0; //CS:S/GO fix, as RoundEnd isn't called when using mp_restartgame :$
	}
	
	if ( GetConVarInt( g_ats ) == 0 || !hasEnoughPlayers() )
		return bool:Plugin_Continue;
		
	teamScoreUpdate();
	
	return bool:Plugin_Continue;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_ats ) == 0 || 
			( GetConVarInt( g_ats_round ) == 0 &&
			GetConVarInt( g_ats_bestof ) == 0 &&
			GetConVarInt( g_ats_winstreak ) == 0 &&
			GetConVarInt( g_ats_inequity ) == 0 ) )
		return bool:Plugin_Continue;
	
	new iWinner = g_currentMod != Working_Mod:GAME_DODS ? GetEventInt( event, "winner" ) : GetEventInt( event, "team" );
	if ( iWinner == 1 ) //draw "enough player joins so restart game" / "people left"--> no round++/verbose
	{
		g_winStreak = 0;
		return bool:Plugin_Continue;
	}
	
	if ( !hasEnoughPlayers() )
		return bool:Plugin_Continue;
	
	//Affect score/round
	++g_roundNumber;
	changeScore( iWinner );
	
	//Verbose
	messageScore(); //Do it before timer
	messageRules(); //^
	
	//React to score/round
	if ( !roundCheck() ) //if no scramble happen
		if ( !bestOfCheck() ) //again
			if ( !streakCheck() )
				inequityCheck();
	
	teamScoreUpdate();
	
	return bool:Plugin_Continue;
}

//=====Begin private (+ 1 timer)

changeScore( any:winner )
{
	if ( winner == 2 )
	{
		++g_TScore;
		
		if ( g_lastRoundWinnerIsT || g_roundNumber == 1) //First round ou dernier round = t
			++g_winStreak;
		else //Not first round & CT we last to win
			g_winStreak = 1;
			
		g_lastRoundWinnerIsT = true;
	}
	else
	{
		++g_CTScore;
		
		if ( !g_lastRoundWinnerIsT || g_roundNumber == 1) //First round ou dernier round = ct
			++g_winStreak;
		else //Not first round & CT we last to win
			g_winStreak = 1;
			
		g_lastRoundWinnerIsT = false;
	}
}

bool:roundCheck()
{
	new roundToScramble = GetConVarInt( g_ats_round );
	if ( roundToScramble == 0 )
		return false;
	
	if ( roundToScramble > g_roundNumber )
		return false;
		
	sendScrambleRequest( Scramble_Reason:REASON_ROUND );
	
	return true;
}
bool:bestOfCheck()
{
	new bestOf = GetConVarInt( g_ats_bestof );
	if ( bestOf == 0 )
		return false;
	
	if ( g_TScore < bestOf / 2 + 1 )
		return false;
	
	sendScrambleRequest( Scramble_Reason:REASON_BESTOF );
	
	return true;
}
bool:streakCheck()
{
	new winStreak = GetConVarInt( g_ats_winstreak );
	if ( winStreak == 0 )
		return false;
	
	if ( winStreak > g_winStreak )
		return false;
	
	sendScrambleRequest( Scramble_Reason:REASON_WINSTREAK );
	
	return true;
}
bool:inequityCheck()
{
	new inequity = GetConVarInt( g_ats_inequity );
	if ( inequity == 0 )
		return false;
	
	if ( ( g_TScore > g_CTScore ? g_TScore - g_CTScore : g_CTScore - g_TScore ) < inequity )
		return false;
	
	sendScrambleRequest( Scramble_Reason:REASON_INEQUITY );
	
	return true;
}

teamScoreUpdate()
{
	if ( GetConVarInt( g_ats_real_score ) == 1 )
	{
		SetTeamScore( 2, g_TScore );
		SetTeamScore( 3, g_CTScore );
	}
}

bool:hasEnoughPlayers()
{
	new playerNbNeeded = GetConVarInt( g_ats_minplayers );
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) && GetClientTeam( i ) > 1 )
		{
			--playerNbNeeded;
			if ( playerNbNeeded <= 0 )
				return true;
		}
	}
	
	return false;
}

//=====Scramble/team-swap related

sendScrambleRequest( Scramble_Reason:reason )
{
	new atsValue = GetConVarInt( g_ats );
	if ( !RequestTeamsManagement( any:reason,
		ATS_PRIORITY,
		TeamsManagementType:TMT_TEAMS,
		atsValue,
		atsValue == 3 ? ( GetConVarInt( g_ats_required_value )  | ( GetConVarInt( g_ats_required_team ) << 8 ) ) : 0,
		( GetConVarInt( g_ats_fadeColor ) == 1 ? FTMI_FADE : 0 ) | ( GetConVarInt( g_ats_sound ) == 1 ? FTMI_SOUND : 0 ) ) )
	{
		//Reset
		g_roundNumber = 0;
		g_TScore = 0;
		g_CTScore = 0;
		g_winStreak = 0;
	}
}

public OnTeamsManagementExecutedRequest( const Handle:plugin, 
    const reasonId,
    const priority, 
    const TeamsManagementType:type,
    const actionId, 
    const any:customValue, 
    const flags)
{
	//The TM we wanted is done; msg + sound !
	//Verbose + sound end-round
	if ( plugin == GetMyHandle() )
	{
		messageReasonScramble( Scramble_Reason:reasonId );
		
		//Reset
		g_roundNumber = 0;
		g_TScore = 0;
		g_CTScore = 0;
		g_winStreak = 0;
	}
}
public OnTeamsManagementAbandonedRequest( const Handle:plugin, 
    const reasonId,
    const priority, 
    const TeamsManagementType:type,
    const actionId, 
    const any:customValue, 
    const flags)
{
	//Our TM request is denied =( ; we've to reset
	if ( plugin == GetMyHandle() )
	{
		//Reset
		g_roundNumber = 0;
		g_TScore = 0;
		g_CTScore = 0;
		g_winStreak = 0;
	}
}

//=====End scramble/team-swap related

//=====Verbose related

messageScore()
{
	if ( GetConVarInt( g_ats_verbose_score ) == 0 )
		return;
	
	new ats_round = GetConVarInt( g_ats_round );
	new ats_bestof = GetConVarInt( g_ats_bestof );
	new ats_winstreak = GetConVarInt( g_ats_winstreak );
	new ats_inequity = GetConVarInt( g_ats_inequity );
	
	new nbElements;
	if ( ats_round )
		++nbElements;
	if ( ats_bestof )
		++nbElements;
	if ( ats_winstreak )
		++nbElements;
	if ( ats_inequity )
		++nbElements;
	
	if ( nbElements > 0 )
	{
		decl String:szBuffer[ 256 ];
		
		FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01" );
		
		if ( ats_round )
		{
			Format( szBuffer, sizeof(szBuffer), "%s%T ", szBuffer, "RoundXEnd", LANG_SERVER,
				"\x04", g_roundNumber, "\x01" );
		}
		if ( ats_bestof || ats_inequity )
		{
			//Get team
			decl String:szTeamName[ MAX_NAME_LENGTH ];
			if ( g_TScore > g_CTScore )
				getTeamNameConditionalLowerCase( 2, szTeamName, sizeof(szTeamName) );
			else if ( g_TScore < g_CTScore )
				getTeamNameConditionalLowerCase( 3, szTeamName, sizeof(szTeamName) );
			else
				FormatEx( szTeamName, sizeof(szTeamName), "%T", "NoTeamLeading", LANG_SERVER );
			
			if ( ats_bestof )
			{
				Format( szBuffer, sizeof(szBuffer), "%s%T ", szBuffer, "ScoreBestOf", LANG_SERVER,
					"\x04", g_TScore, "\x01",
					"\x04", g_CTScore, "\x01",
					"\x04", szTeamName, "\x01" );
			}
			if ( ats_inequity )
			{
				Format( szBuffer, sizeof(szBuffer), "%s%T ", szBuffer, "Inequity", LANG_SERVER,
					"\x04", g_TScore > g_CTScore ? g_TScore - g_CTScore : g_CTScore - g_TScore, "\x01",
					"\x04", szTeamName, "\x01" );
			}
		}
		if ( ats_winstreak )
		{
			Format( szBuffer, sizeof(szBuffer), "%s%T ", szBuffer, "WinStreak", LANG_SERVER,
				"\x04", g_winStreak, "\x01" );
		}
		
		PrintToChatAll( "%s", szBuffer );
	}
}

messageRules()
{
	if ( GetConVarInt( g_ats_verbose_rule ) == 0 )
		return;
	
	if ( g_roundNumber % GetConVarInt( g_ats_verbose_rule ) != 0 )
		return;
	
	new ats_round = GetConVarInt( g_ats_round );
	new ats_bestof = GetConVarInt( g_ats_bestof );
	new ats_winstreak = GetConVarInt( g_ats_winstreak );
	new ats_inequity = GetConVarInt( g_ats_inequity );
	
	new nbElements;
	if ( ats_round )
		++nbElements;
	if ( ats_bestof )
		++nbElements;
	if ( ats_winstreak )
		++nbElements;
	if ( ats_inequity )
		++nbElements;
	
	//Start msg
	decl String:szBuffer[ 256 ];
	
	if ( nbElements > 0 )
	{
		FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T ", "RulesWhenToScramble", LANG_SERVER );
		
		if ( ats_round )
		{
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "RuleRound", LANG_SERVER, "\x04", ats_round, "\x01" );
			
			if ( --nbElements > 0 )
				Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "Or", LANG_SERVER );
		}
		
		if ( ats_bestof )
		{
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "RuleBestOf", LANG_SERVER, "\x04", ats_bestof, "\x01" );
			
			if ( --nbElements > 0 )
				Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "Or", LANG_SERVER );
		}
		
		if ( ats_winstreak )
		{
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "RuleWinStreak", LANG_SERVER, "\x04", ats_winstreak, "\x01" );
			
			if ( --nbElements > 0 )
				Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "Or", LANG_SERVER );
		}
		
		if ( ats_inequity )
		{
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "RuleInequity", LANG_SERVER, "\x04", ats_inequity, "\x01" );
		}
		
		PrintToChatAll( "%s.", szBuffer );
	}
}

messageReasonScramble( Scramble_Reason:reason )
{
	if ( GetConVarInt( g_ats_verbose_scramble ) == 0 )
		return;
	
	decl String:szBuffer[ 256 ];
	
	if ( reason == Scramble_Reason:REASON_ROUND )
	{
		FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T", "ScrambledRound", LANG_SERVER, 
			"\x04", g_roundNumber, "\x01" );
	}
	else //Scramble_Reason:REASON_BESTOF/WINSTREAK/REASON_INEQUITY ; need team name
	{
		decl String:szTeamName[ MAX_NAME_LENGTH ];
		getTeamNameConditionalLowerCase( g_lastRoundWinnerIsT ? 2 : 3, szTeamName, sizeof(szTeamName) );
		
		if ( g_currentMod == Working_Mod:GAME_DODS ) //stoopid bug in DoD:S ; "alliess" and "axiss"
		{
			szTeamName[ strlen( szTeamName ) - 1 ] = '\0';
		}
		
		if ( reason == Scramble_Reason:REASON_BESTOF )
		{
			FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T", "ScrambledBestOf", LANG_SERVER, 
				"\x04", szTeamName, "\x01", "\x04", GetConVarInt( g_ats_bestof ), "\x01" );
		}
		else if ( reason == Scramble_Reason:REASON_WINSTREAK )
		{
			FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T", "ScrambledWinStreak", LANG_SERVER, 
				"\x04", szTeamName, "\x01", "\x04", g_winStreak, "\x01" );
		}
		else //( reason == Scramble_Reason:REASON_INEQUITY )
		{
			FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T", "ScrambledInequity", LANG_SERVER, 
				"\x04", szTeamName, "\x01", "\x04", GetConVarInt( g_ats_inequity ), "\x01" );
		}
	}
	
	Format( szBuffer, sizeof(szBuffer), "%s. %T", szBuffer, "ScrambledTherefore", LANG_SERVER );
	PrintToChatAll( "%s", szBuffer );
}

getTeamNameConditionalLowerCase(any:teamId, String:szBuffer[ ], any:size)
{
	//Team name
	GetTeamName( teamId, szBuffer, size );
	
	//Lower cases
	if ( strlen( szBuffer ) > 3 ) //4+ chars = lower
		for ( new i = 1; i < size; ++i )
			szBuffer[ i ] = CharToLower( szBuffer[ i ] );
}