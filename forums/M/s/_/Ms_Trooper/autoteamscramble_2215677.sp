//Sources & credits from where I've taken the two default sounds :
//http://www.gamebanana.com/sounds/15669	ats1.wav	by Darkclaw Deathstrike
//http://www.gamebanana.com/sounds/5351		ats2.wav	by XxXworlockzXxX

#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.5.3"

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
//others
new Handle:g_ats_real_score;
new Handle:g_ats_delay;
new Handle:g_ats_blockDmg;

//verbose
new Handle:g_ats_verbose_score;
new Handle:g_ats_verbose_rule;
new Handle:g_ats_verbose_scramble;

new Handle:g_ats_sound;

//sounds
#define	SOUNDS_STRING_PREPREFIX		"sound/"
#define	SOUNDS_STRING_PREFIX		"misc/ats"
#define	SOUNDS_STRING_SUFFIX		".wav"
new any:g_iSoundsCount;

//Vars

//Round number, scores, and streak
new any:g_roundNumber;
new any:g_TScore;
new any:g_CTScore;
new bool:g_lastRoundWinnerIsT;
new any:g_winStreak;
new bool:g_blockDamageOnPlayer;
new bool:g_bTimerCanAct;

//Sounds
new bool:g_bShouldPlaySound;

enum Scramble_Reason
{
	REASON_ROUND = 1,
	REASON_BESTOF,
	REASON_WINSTREAK
};

//Multi-mod allowance
new bool:g_bIsCSS;

//===== Forwards

public OnPluginStart()
{
	//Allow multiples mod
	decl String:szBuffer[ 16 ];
	GetGameFolderName( szBuffer, sizeof(szBuffer) );
	
	g_bIsCSS = StrEqual( szBuffer, "cstrike", false );
	
	//CVARs
	CreateConVar( "autoteamscrambleversion", PLUGIN_VERSION, "Team Scramble version", 
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_ats = CreateConVar( "ats", "1", "Is the plugin enabled? 0 = disabled, 1 = enabled (fair team), 2 = enabled (possible unfair, i.e. 12v5), 3 = for custom maps (i.e. jailbreak 2vALL). Def. 1.", 
		FCVAR_PLUGIN, true, 0.0, true, 3.0 );
		
	//Rules
	g_ats_round = CreateConVar( "ats_rule_round", "0", "Frequence (in round) of team scrambling. 0 = disabled, 1+ = enabled. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_ats_bestof = CreateConVar( "ats_rule_bestof", "0", "Scramble when a team win a best-of-X (odd number recommended; even will go with an additionnal round; i.e. 4 -> 5). 0 = disabled, 1+ = enabled. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_ats_winstreak = CreateConVar( "ats_rule_winstreak", "4", "Scramble when a team win X victories in a row. 0 = disabled, 1+ = enabled. Def. 4.", 
		FCVAR_PLUGIN, true, 0.0 );
	
	//Verboses
	g_ats_verbose_score = CreateConVar( "ats_verbose_score", "1", "Tell players the score after every rounds. 0 = disabled, 1 = enabled (Default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_ats_verbose_rule = CreateConVar( "ats_verbose_rule", "1", "Tell players every X rounds how team can get scrambled. 0 = disabled, 1+ = enabled. Def. 1.", 
		FCVAR_PLUGIN, true, 0.0 );
	g_ats_verbose_scramble = CreateConVar( "ats_verbose_scramble", "1", "Tell players when team are scrambled. 0 = disabled, 1 = enabled (Default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Sounds
	g_ats_sound = CreateConVar( "ats_sound", "0", "Play a sound when teams are scrambled. 0 = disabled, 1 = enabled. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	g_ats_real_score = CreateConVar( "ats_real_score", "1", "Reset team scores when scrambling teams (recommended for timelimits only). 0 = disabled, 1 = enabled (Default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//3rd mode
	g_ats_required_value = CreateConVar( "ats_required_value", "1", "If CVar 'ats' value is '3', then a team will have X players. Min 1.", 
		FCVAR_PLUGIN, true, 1.0 );
	g_ats_required_team = CreateConVar( "ats_required_team", "1", "If CVar 'ats' value is '3', then specified team will have an exact number of players. 0 = terro, 1 = CTs.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
		
	//Other ConVars
	g_ats_delay = CreateConVar( "ats_delay", "0.1", "Time in seconds before round start when team will be scrambled. Default 0.1.", 
		FCVAR_PLUGIN, true, 0.1 );
	g_ats_blockDmg = CreateConVar( "ats_blockdmg", "1", 
		"If damage is blocked between scrambling and round start. 0=no, 1=yes (default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Config
	AutoExecConfig( true, "autoteamscramble" );
	
	//Hooks on events
	HookEvent( "round_start", Event_RoundStart, EventHookMode_Pre ); //Post sinon pre
	HookEvent( "round_end", Event_RoundEnd );
	
	if ( g_bIsCSS )
		HookEvent( "cs_win_panel_match", Event_GameEnd ); //Need to prevent scrambling if game end
	
	//Translation file
	LoadTranslations( "autoteamscramble.phrases" );
}

//Precache sounds only
public OnConfigsExecuted()
{
	//If plugin is disabled or sound is disabled then don't precache
	if ( GetConVarInt( g_ats ) == 0 || GetConVarInt( g_ats_sound ) == 0 )
		return;
	
	decl String:szBufferShort[ 64 ];
	decl String:szBufferLong[ 64 ];
	
	new whereDigitIsShort = strlen( SOUNDS_STRING_PREFIX );
	new whereIsDigitIsLong = strlen( SOUNDS_STRING_PREPREFIX ) + whereDigitIsShort;
	
	FormatEx( szBufferShort, sizeof(szBufferShort), "%s%d%s", SOUNDS_STRING_PREFIX, 5, SOUNDS_STRING_SUFFIX ); //5--> just to say there is something
	FormatEx( szBufferLong, sizeof(szBufferLong), "%s%s", SOUNDS_STRING_PREPREFIX, szBufferShort );
	
	decl String:theDigit[ 2 ]; //2nd slot is needed for ESC char
	
	new i;
	g_iSoundsCount = 0;
	
	//Up to 9 sounds
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
			++g_iSoundsCount;
		}
		else
		{
			if ( i == 1)
				LogMessage("%s not found. Stopped counting sounds.", szBufferLong);
			break;
		}
	}
	
	whereDigitIsShort -= strlen( SOUNDS_STRING_PREPREFIX );
}

public OnClientPutInServer(client)
{
	SDKHook( client, SDKHook_OnTakeDamage, Event_SDKHook_OnTakeDamage );
}

//===== Events

public Action:Event_SDKHook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ( GetConVarInt( g_ats ) == 0 || //Plugin disabled
			!g_blockDamageOnPlayer ) //Plugin not blocking dmg after scrambling 
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
	g_blockDamageOnPlayer = false; //people can get hurt
	
	//No need to check if plugin is enable (initialization only)
	if ( GetTeamScore( 2 ) + GetTeamScore( 3 ) == 0 ) //first round
	{
		g_roundNumber = 0;
		g_TScore = 0;
		g_CTScore = 0;
		g_winStreak = 0; //1.5.3
		g_bShouldPlaySound = false;
	}
	
	if ( g_bShouldPlaySound )
		playRandomSoundToAllPlayers( );
	
	if ( GetConVarInt( g_ats ) == 0 )
		return bool:Plugin_Continue;
		
	teamScoreUpdate();
	
	return bool:Plugin_Continue;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_ats ) == 0 || 
			( GetConVarInt( g_ats_round ) == 0 &&
			GetConVarInt( g_ats_bestof ) == 0 &&
			GetConVarInt( g_ats_winstreak ) == 0 ) )
		return bool:Plugin_Continue;
	
	new iWinner = GetEventInt( event, "winner" );
	if ( iWinner == 1 ) //draw "enough player joins so restart game" / "people left"--> no round++/verbose
	{
		g_winStreak = 0;
		return bool:Plugin_Continue;
	}
	
	//Affect score/round
	++g_roundNumber;
	changeScore( iWinner );
	
	//Verbose
	messageScore(); //Do it before timer
	messageRules(); //^
	
	//React to score/round
	if ( !roundCheck() ) //if no scramble happen
		if ( !bestOfCheck() ) //again
			streakCheck();
	
	teamScoreUpdate();
	
	return bool:Plugin_Continue;
}

//Prevent end game scramble
public Event_GameEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bTimerCanAct = false;
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
	if ( g_roundNumber >= roundToScramble )
	{
		//Scramble
		startScrambleTeamsCountdown( Scramble_Reason:REASON_ROUND );
	}
	
	return true;
}

bool:bestOfCheck()
{
	new bestOf = GetConVarInt( g_ats_bestof );
	if ( bestOf == 0)
		return false;
	
	if ( g_TScore < bestOf / 2 + 1 )
		return false;
	
	startScrambleTeamsCountdown( Scramble_Reason:REASON_BESTOF );
	
	return true;
}

bool:streakCheck()
{
	new winStreak = GetConVarInt( g_ats_winstreak );
	if ( winStreak == 0)
		return false;
	
	if ( winStreak > g_winStreak )
		return false;
	
	startScrambleTeamsCountdown( Scramble_Reason:REASON_WINSTREAK );
	
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

//=====Scramble/team-swap related

startScrambleTeamsCountdown( Scramble_Reason:reason )
{
	if ( GetConVarInt( g_ats_blockDmg ) == 1 ) //Prevent friendly-fire (friend2foe / foe2friend)
		g_blockDamageOnPlayer = true;
	
	if ( g_bIsCSS )
	{
		new Float:timeB4Scramble = GetConVarFloat( FindConVar( "mp_round_restart_delay" ) ) - GetConVarFloat( g_ats_delay );
		if ( timeB4Scramble > 0.1 ) //Minimum time to switch team correctly
		{
			g_bTimerCanAct = true;
			CreateTimer( timeB4Scramble, scrambleTeams, reason, TIMER_FLAG_NO_MAPCHANGE );
		}
		else
			scrambleTeams( INVALID_HANDLE, reason );
	}
	else
		scrambleTeams( INVALID_HANDLE, reason );
}

public Action:scrambleTeams(Handle:timer, any:reason)
{
	if ( timer != INVALID_HANDLE && !g_bTimerCanAct )
	{
		return Plugin_Handled;
	}
	new ats = GetConVarInt( g_ats );
	if ( ats == 0 )
	{
		return Plugin_Handled;
	}
	
	//Verbose + sound end-round
	messageReasonScramble( reason );
	
	if ( GetConVarInt( g_ats_sound ) == 1 )
		g_bShouldPlaySound = true;
	
	//Create array and fill array	
	//new Handle:playersArray = CreateArray();
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
				//PushArrayCell( playersArray, i );
				playersId[ playersIdSize++ ] = i;
			}
		}
	}
	
	//Use array
	//new arraySize = GetArraySize( playersArray );
	
	if ( playersIdSize > 0 )
	{
		//Put at least 1 T and 1 CT
		//First setTeam
		new randomTeam = GetRandomInt( 2, 3 );
		new randomIndex = GetRandomInt( 0, playersIdSize - 1 );
		
		//new randomClient = GetArrayCell( playersArray, randomIndex );
		new randomClient = playersId[ randomIndex ];
		//RemoveFromArray( playersArray, randomIndex );
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
			
			//randomClient = GetArrayCell( playersArray, randomIndex );
			randomClient = playersId[ randomIndex ];
			//RemoveFromArray( playersArray, randomIndex );
			for ( new i = randomIndex; i < playersIdSize - 1; ++i )
			{
				playersId[ i ] = playersId[ i + 1 ];
			}
			--playersIdSize;
			
			setClientTeam( randomClient, randomTeam );
		}
		
		//Then, depending on ats convar value
		//LOOP
		if ( ats == 2 )
		{
			for ( new i; i < playersIdSize; ++i )
				setClientTeam( playersId[ i ], GetRandomInt( 2, 3 ) );
		}
		else if ( ats == 3 )
		{
			new requiredPlayers = GetConVarInt( g_ats_required_value ) - 1; //already put one
			new primordialTeam = GetConVarInt( g_ats_required_team );
			
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
				if ( requiredPlayers != 0 ) //if the primordial team has enough people
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
		else //ats == 1
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
	
	//Reset
	g_roundNumber = 0;
	g_TScore = 0;
	g_CTScore = 0;
	g_winStreak = 0;
	
	return Plugin_Handled;
}

setClientTeam(any:iClient, any:iTeam)
{
	if ( IsClientInGame( iClient ) && GetClientTeam( iClient ) != iTeam )
	{
		if ( g_bIsCSS )
			CS_SwitchTeam( iClient, iTeam );
		else
			ChangeClientTeam( iClient, iTeam );
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
	
	new nbElements;
	if ( ats_round )
		++nbElements;
	if ( ats_bestof )
		++nbElements;
	if ( ats_winstreak )
		++nbElements;
	
	//TODO : MAKE this fct DEPENDING OF PLUGIN MODE
	
	if ( nbElements > 0 ) //nbElements check is useless mmm... but if I was to delay the msg that would be useful
	{
		decl String:szBuffer[ 256 ];
		
		strcopy( szBuffer, sizeof(szBuffer), "\x04[SM] \x01" );
		
		if ( ats_round )
		{
			Format( szBuffer, sizeof(szBuffer), "%s%T ", szBuffer, "RoundXEnd", LANG_SERVER,
				"\x04", g_roundNumber, "\x01" );
		}
		if ( ats_bestof )
		{
			//Get team
			decl String:szTeamName[ MAX_NAME_LENGTH ];
			if ( g_TScore > g_CTScore )
				getTeamNameConditionalLowerCase( 2, szTeamName, sizeof(szTeamName) );
			else if ( g_TScore < g_CTScore )
				getTeamNameConditionalLowerCase( 3, szTeamName, sizeof(szTeamName) );
			else
				FormatEx( szTeamName, sizeof(szTeamName), "%T", "NoTeamLeading", LANG_SERVER );
				
			Format( szBuffer, sizeof(szBuffer), "%s%T ", szBuffer, "Score", LANG_SERVER,
				"\x04", g_TScore, "\x01",
				"\x04", g_CTScore, "\x01",
				"\x04", szTeamName, "\x01" );
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
	
	new nbElements;
	if ( ats_round )
		++nbElements;
	if ( ats_bestof )
		++nbElements;
	if ( ats_winstreak )
		++nbElements;
	
	//Start msg
	decl String:szBuffer[ 256 ];
	
	if ( nbElements > 0 ) //nbElements check is useless mmm... but if I was to delay the msg that would be useful
	{
		FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T ", "RulesWhenToScramble", LANG_SERVER );
		
		if ( ats_round )
		{
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "RuleRound", LANG_SERVER, "\x04", ats_round, "\x01" );
			
			if ( nbElements > 1 ) //more than 1 element
				Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "Or", LANG_SERVER );
		}
		
		if ( ats_bestof )
		{
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "RuleBestOf", LANG_SERVER, "\x04", ats_bestof, "\x01" );
			
			if ( ats_winstreak != 0 ) // 1 more element
				Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "Or", LANG_SERVER );
		}
		
		if ( ats_winstreak )
		{ //tha end ! ('.')
			Format( szBuffer, sizeof(szBuffer), "%s %T", szBuffer, "RuleWinStreak", LANG_SERVER, "\x04", ats_winstreak, "\x01" );
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
	else //Scramble_Reason:REASON_BESTOF/WINSTREAK
	{
		decl String:szTeamName[ MAX_NAME_LENGTH ];
		getTeamNameConditionalLowerCase( g_lastRoundWinnerIsT ? 2 : 3, szTeamName, sizeof(szTeamName) );
		
		if ( reason == Scramble_Reason:REASON_BESTOF )
		{
			FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T", "ScrambledBestOf", LANG_SERVER, 
				"\x04", szTeamName, "\x01", "\x04", GetConVarInt( g_ats_bestof ), "\x01" );
		}
		else //( reason == Scramble_Reason:REASON_WINSTREAK )
		{
			FormatEx( szBuffer, sizeof(szBuffer), "\x04[SM] \x01%T", "ScrambledWinStreak", LANG_SERVER, 
				"\x04", szTeamName, "\x01", "\x04", g_winStreak, "\x01" );
		}
	}
	
	Format( szBuffer, sizeof(szBuffer), "%s. %T", szBuffer, "ScrambledTherefore", LANG_SERVER );
	PrintToChatAll( "%s", szBuffer );
}

playRandomSoundToAllPlayers()
{
	g_bShouldPlaySound = false;
	
	if ( GetConVarInt( g_ats_sound ) == 0 )
		return;
	
	if ( g_iSoundsCount == 0 )
	{
		LogMessage( "Couldn't precache sounds ; they may not have been found." );
		return;
	}
	
	decl String:szBufferShort[ 64 ];
	
	FormatEx( szBufferShort, sizeof(szBufferShort), "%s%d%s", SOUNDS_STRING_PREFIX, GetRandomInt( 1, g_iSoundsCount ), SOUNDS_STRING_SUFFIX );
	
	EmitSoundToAll( szBufferShort, SOUND_FROM_PLAYER, SNDCHAN_REPLACE );
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