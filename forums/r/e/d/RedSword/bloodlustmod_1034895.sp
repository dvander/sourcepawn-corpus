#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "2.1.0"

#pragma newdecls required

public Plugin myinfo =
{
	name = "Bloodlust Mod",
	author = "RedSword",
	description = "HP loss over time and HP gain with damage done. Automatically (i.e. on spawn) or manually (admin command).",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Mod specific
enum Acknowledged_Mod
{
	GAME_UNKNOWN	= 0,
	GAME_CSS		= 1,
	GAME_CSGO		= 2,
	GAME_DODS		= 3,
	GAME_TF2		= 4,
};

enum Game_State
{
	STATE_PREGAME	= 0, //if I have to bring CSGO stuff
	STATE_PREROUND	= 1, //i.e. freezetime
	STATE_ACTIVE	= 2, //PEWPEW
	STATE_ROUNDEND	= 3, //CSS 'pending'-to-respawn end-of-round thing
};

enum Bloodlust_Type
{
	BLOODLUST_NONE		= 0,
	BLOODLUST_REMOVED	= (1 << 0), //admin-removed (also prevent others)
	BLOODLUST_GIVEN		= (1 << 1), //at least given once this round ; removed atm
	BLOODLUST_AUTO		= (1 << 2), //auto-given
	BLOODLUST_MANUAL	= (1 << 3), //admin-given; may be lost, if so subsequent bloodlust will be _GIVEN
	BLOODLUST_ROUND		= (1 << 4), //given by bloodlust-round (admin/vote/random)
	BLOODLUST_TIME		= (1 << 5), //given by bloodlust-time (admin/vote)
};

#define ITRUE 1
#define IFALSE 0

//Convars
Handle g_hAutoBL;
Handle g_hAutoBLMinPlayers;
Handle g_hManualLoseOnDeath;
Handle g_hRandomRoundChance;
Handle g_hVote;
Handle g_hVotePercentageNeeded;
Handle g_hVoteLength;
Handle g_hVoteLengthType;
Handle g_hVoteRevoteDelay;
Handle g_hVoteHideTrigger;
Handle g_hHealthSpawn;
Handle g_hHealthSpawnType;
Handle g_hHealthMax;
Handle g_hHealthMaxType;
Handle g_hHealthLeech;
Handle g_hTf2HealthLeechMedigunTargetRatio;
Handle g_hTf2HealthLeechMedigunTargetRatioType;
Handle g_hTf2HealthLeechMedigunMedicRatio;
Handle g_hTf2HealthLeechMedigunSplitIfMany; //bool
Handle g_hTickDelay;
Handle g_hTickActiveGameOnly;
Handle g_hTickLoss;
Handle g_hTickLossType;
Handle g_hTickLossTypeRelativeRounding;
Handle g_hTickLossCanKill;
Handle g_hTickFadeThreshold;
Handle g_hTickFadeLength;
Handle g_hFf;
Handle g_hVerboseDeathBloodlust;
Handle g_hVerboseAnnounceRandomRound;
Handle g_hVerboseAnnounceOnSpawn;
Handle g_hVerboseAnnounceMinPlayers;
Handle g_hVerboseMinimumDelay;
Handle g_hLogAdmin;
Handle g_hLogPassedVote;

//Vars
Acknowledged_Mod g_currentMod;
Game_State g_currentState;
Bloodlust_Type g_bloodlustTypeForThisRound[ MAXPLAYERS + 1 ]; //zeroed on round end
Handle g_hDegenTimer[ MAXPLAYERS + 1 ];
bool g_bIsBloodlusted[ MAXPLAYERS + 1 ]; //needed because bloodlist can be tickless
int g_iSpawnWithBloodlust[ MAXPLAYERS + 1 ]; //[ 0 ] == nb of elem with index > 0 with value != 0
int g_iHealthOnSpawnPreBonus[ MAXPLAYERS + 1 ];
int g_iMaximumHealth[ MAXPLAYERS + 1 ];
int g_iVerboseBloodlustCount[ MAXPLAYERS + 1 ];
float g_fVerboseBloodlustLastTime[ MAXPLAYERS + 1 ]; //ensure that we have a minimum of 30 secs
int g_iVotedForBloodlust[ MAXPLAYERS + 1 ]; //[ 0 ] == count
bool g_bAutoTimersStarted; //To ensure only spawns after round_start are considered when creating timers
bool g_bHasEnoughPlayersForAuto; //updated only on round starts
float g_fLastMinPlayerReachedPrint; //when a round starts, if g_bHasEnoughPlayersForAuto changed we print ; allows to avoid spam with spawn
bool g_bIsCurrentRoundIsBloodlustForAll; //set on round end
int g_iNextRoundIsBloodlustForAll; //absolute; i.e. even if not enough players; if not enough players don't random though
float g_fTimelimitToGiveBloodlustForAll; //separate from round count
float g_fTimelimitNoVote; //prevent people from voting after having vote
//TF2specific
TFClassType g_tf2ClassType[ MAXPLAYERS + 1 ];
int g_iTf2ClassCount[ TFClassType ];

//Cache
char g_szVerbosePrefix[ 12 ];
char g_szVerbosePrefixForShowActivity[ 20 ];
char g_szModName[ 16 ];
int g_iFadeColor;

// ===== Forwards =====
public void OnPluginStart()
{
	//Allow multiples mod
	char szBuffer[ 16 ];
	GetGameFolderName( szBuffer, sizeof(szBuffer) );
	
	if ( StrEqual( szBuffer, "cstrike", false ) )
		g_currentMod = view_as<Acknowledged_Mod>(GAME_CSS);
	else if ( StrEqual( szBuffer, "csgo", false ) )
		g_currentMod = view_as<Acknowledged_Mod>(GAME_CSGO);
	else if ( StrEqual( szBuffer, "dod", false ) )
		g_currentMod = view_as<Acknowledged_Mod>(GAME_DODS);
	else if ( StrEqual( szBuffer, "tf", false ) )
		g_currentMod = view_as<Acknowledged_Mod>(GAME_TF2);
	else
		g_currentMod = view_as<Acknowledged_Mod>(GAME_UNKNOWN);
	
	//CVARs
	CreateConVar( "bloodlustversion", PLUGIN_VERSION, "Bloodlust mod version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_hAutoBL = CreateConVar( "bl_auto", "0", "Are people automatically in bloodlust ? 0= No/Random, 1= Yes, 2= (Team1=T/RED/Surv/Allies), 3= (Team2=CT/BLU/Inf/Axis), 4= Team3 (VPK).", FCVAR_PLUGIN, true, 0.0, true, 4.0 ); //1 = All, 2 = Ts, 3 = CTs (futur)
	g_hAutoBLMinPlayers = CreateConVar( "bl_minplayers", "0", "Minimum total players (no spec, includes bots) needed for auto/random bloodlust.", FCVAR_PLUGIN, true, 0.0 );
	g_hManualLoseOnDeath = CreateConVar( "bl_losebloodlustondeath", "1", "Does dying remove non-automatic bloodlust (i.e. tf2 where you respawn; with bl gotten via admin command) ? 0=No (Def), 1=Yes.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hRandomRoundChance = CreateConVar( "bl_round_chance", "0.0", "If _auto = 0, what is the chance for the next round to have bloodlust for everyone ? 0= 0%, 1= 100%.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hVote = CreateConVar( "bl_vote", "1.0", "Is bloodlust-for-all voting enabled ? 1=Yes (Def.), 0=No.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hVotePercentageNeeded = CreateConVar( "bl_vote_percent", "0.67", "Percent of vote needed to enable bloodlust-for-all. 1=100%.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hVoteLength = CreateConVar( "bl_vote_length", "5.0", "How long will bloodlust-for-all be available. If _type=1 it is in time, if _type=0 it is in rounds (excludes current).", FCVAR_PLUGIN, true, 0.0 );
	g_hVoteLengthType = CreateConVar( "bl_vote_length_type", "1.0", "Is bloodlust-for-all length in time (=1, Def.) or in round amount (=0; excludes current round).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hVoteRevoteDelay = CreateConVar( "bl_vote_revote_delay", "1.0", "Time in minutes after a vote passes before people can vote again. Def=1.0.", FCVAR_PLUGIN, true, 0.0 );
	g_hVoteHideTrigger = CreateConVar( "bl_vote_hide_trigger", "0.0", "Should the player vote trigger be hidden (i.e. hide \"!votebl\")? 1=Yes, 0=No (Def).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	g_hHealthSpawn = CreateConVar( "bl_health_spawn_bonus", "25", "Bonus HP players spawn with (or gets if admin command). 1= +100% if relative", FCVAR_PLUGIN );
	g_hHealthSpawnType = CreateConVar( "bl_health_spawn_bonus_type", "0", "0=Absolute (Def), 1=Relative to spawn health.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	g_hHealthMax = CreateConVar( "bl_health_max", "2.0", "Maximum HP players can get through HP leech. Excludes spawn. 1=100%=normal if relative.", FCVAR_PLUGIN );
	g_hHealthMaxType = CreateConVar( "bl_health_max_type", "1", "0=Absolute, 1=Relative to spawn health before bonus (Def).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hHealthLeech = CreateConVar( "bl_health_leech", "0.50", "Ratio of the damage done going to health (1 = 100%; < 0 = lose life).", FCVAR_PLUGIN );
	//TF2 ; leech related w/ medigun
	if ( g_currentMod == view_as<Acknowledged_Mod>(GAME_TF2) )
	{
		g_hTf2HealthLeechMedigunTargetRatio = CreateConVar( "bl_health_leech_medigun_target_ratio", "0.5", "Value is multiplied to the leeched amount before being applied to the healed target.", FCVAR_PLUGIN );
		g_hTf2HealthLeechMedigunTargetRatioType = CreateConVar( "bl_health_leech_medigun_target_ratio_type", "1", "Does at least one medic needs to be bloodlusted for the target to have its _ratio applied ? 1=Yes, 0=No.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
		g_hTf2HealthLeechMedigunMedicRatio = CreateConVar( "bl_health_leech_medigun_medic_ratio", "0.5", "Value is multiplied to the leeched amount before being applied to the healing medic(s).", FCVAR_PLUGIN );
		g_hTf2HealthLeechMedigunSplitIfMany = CreateConVar( "bl_health_leech_medigun_medic_split", "1", "Leeched HP given to the medics is split amongst them. 1=Yes (Def.), 0=No.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	}
	
	g_hTickDelay = CreateConVar( "bl_tick_delay", "2.0", "Set the time interval in seconds between each HP loss (0 = no degen).", FCVAR_PLUGIN, true, 0.0 );
	g_hTickActiveGameOnly = CreateConVar( "bl_tick_activegameonly", "1", "When the ticks can happen. 0=Always, 1=Only when the game is active (Def.).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hTickLoss = CreateConVar( "bl_tick_healthloss", "0.02", "Set the HP loss per interval. 1=100% if relative.", FCVAR_PLUGIN );
	g_hTickLossType = CreateConVar( "bl_tick_healthloss_type", "1", "0=Absolute (Def), 1=Relative to max health on spawn before spawn bonus, 2=Relative to current health.", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	g_hTickLossTypeRelativeRounding = CreateConVar( "bl_tick_healthloss_relativerounding", "1", "When bl_tick_healthloss is relative, how to round health loss? 0=Floor, 1=Nearest (Def), 2=Ceil.", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	g_hTickLossCanKill = CreateConVar( "bl_tick_healthloss_cankill", "2", "Can a player die from bloodlust (if not, minimum hp = 1) ? 2=Yes but only when game is active (Def), 1=Yes, 0=No.", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	g_hTickFadeThreshold = CreateConVar( "bl_tick_fade_threshold", "5", "Maximum HP when red fading screen happens ? Updated hp is taken. 0=Disable.", FCVAR_PLUGIN, true, 0.0 );
	g_hTickFadeLength = CreateConVar( "bl_tick_fade_length", "500", "Fade length (in ms) ? 0=Disable.", FCVAR_PLUGIN, true, 0.0 );
	Handle hHandle = CreateConVar( "bl_tick_fade_color", "255 0 0 127", "Fade color in R-G-B-A ? Every value must be between 0 and 255.", FCVAR_PLUGIN );
	//NOTE : Use ^, 0 (full-color duration), 1 (fade-from-color-to-game) as args
	char fadeStr[ 20 ];
	GetConVarString( hHandle, fadeStr, sizeof(fadeStr) );
	char fadeSubStr[ 5 ][ 4 ]; //5 for error detection
	if ( ExplodeString( fadeStr, " ", fadeSubStr, sizeof(fadeSubStr), sizeof(fadeSubStr[]) ) != 4 )
	{
		LogMessage( "Failed to update color with '%s', reverting to 255 0 0 127", fadeStr );
		g_iFadeColor = 0xFF00007F;
	}
	else
	{
		g_iFadeColor = 0;
		int tmp;
		for ( int i; i < 4; ++i )
		{
			tmp = StringToInt( fadeSubStr[ i ] );
			if ( tmp < 0 || tmp > 255 )
			{
				LogMessage( "Failed to update color with '%s', reverting to 255 0 0 127", fadeStr );
				g_iFadeColor = 0xFF00007F;
				break;
			}
			
			g_iFadeColor |= tmp << (8 * (3 - i));
		}
	}
	HookConVarChange( hHandle, ConVarChange_FadeColor );
	
	g_hFf = CreateConVar( "bl_ff", "0", "Allows feeding on teammates ? 1=Yes, 0=No(Def).", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Verbose & log
	
	g_hVerboseDeathBloodlust = CreateConVar( "bl_verbose_death", "1", "Advertise deaths from bloodlust ? 1=Yes (Def), 0=No.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hVerboseAnnounceRandomRound = CreateConVar( "bl_verbose_randomround", "1", "Should the random round be announced ? 1=Yes (Def.), 0=No", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hVerboseAnnounceOnSpawn = CreateConVar( "bl_verbose_spawn", "2", "How long (in spawns) will the plugin be advertised when automatically bloodlusting? Per user. 0=Don't.", FCVAR_PLUGIN, true, 0.0 );
	
	g_hVerboseAnnounceMinPlayers = CreateConVar( "bl_verbose_minplayers", "1", "Advertise when there are enough players", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	hHandle = CreateConVar( "bl_verbose_prefix", "[SM] ", "Prefix attached to verbose phrases. Default is '[SM] '.", FCVAR_PLUGIN );
	HookConVarChange( hHandle, ConVarChange_VerbosePrefix );
	GetConVarString( hHandle, g_szVerbosePrefix, sizeof(g_szVerbosePrefix) );
	strcopy( g_szVerbosePrefixForShowActivity, sizeof(g_szVerbosePrefixForShowActivity), "\x04" );
	StrCat( g_szVerbosePrefixForShowActivity, sizeof(g_szVerbosePrefixForShowActivity), g_szVerbosePrefix );
	StrCat( g_szVerbosePrefixForShowActivity, sizeof(g_szVerbosePrefixForShowActivity), "\x03" );
	
	hHandle = CreateConVar( "bl_verbose_modname", "Bloodlust", "Mod name. Default is 'Bloodlust'.", FCVAR_PLUGIN );
	HookConVarChange( hHandle, ConVarChange_VerboseModName );
	GetConVarString( hHandle, g_szModName, sizeof(g_szModName) );
	
	g_hVerboseMinimumDelay = CreateConVar( "bl_verbose_minimumdelay", "15.0", "Minimum time between one 'spawn' advertisement and either another one or a minplayers update. Def '15.0'.", FCVAR_PLUGIN, true, 0.0 );
	
	g_hLogAdmin = CreateConVar( "bl_log_admin", "1.0", "Log admin commands ? 1=Yes (Def), 0=No.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	g_hLogPassedVote = CreateConVar( "bl_log_passedvote", "1.0", "Log passed votes ? 1=Yes (Def), 0=No.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	
	//==Hooks on events
	//Player events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	//Round stats/end
	if ( g_currentMod == view_as<Acknowledged_Mod>(GAME_DODS) )
	{
		HookEvent( "dod_round_start", Event_RoundStart );
		HookEvent( "dod_round_win", Event_RoundEnd );
	}
	else if ( g_currentMod == view_as<Acknowledged_Mod>(GAME_TF2) )
	{
		HookEvent( "teamplay_round_start", Event_RoundStart );
		HookEvent( "teamplay_round_win", Event_RoundEnd ); //also teamplay_restart_round ? mmm
	}
	else
	{
		HookEvent( "round_start", Event_RoundStart );
		HookEvent( "round_end", Event_RoundEnd );
	}
	
	//Round active & tf2 class get for medic
	switch ( g_currentMod )
	{
		case GAME_CSS, GAME_CSGO:
			HookEvent( "round_freeze_end", Event_RoundActive );
		case GAME_DODS:
			HookEvent( "dod_round_active", Event_RoundActive );
		case GAME_TF2:
		{
			//teamplay_round_active = being able to move in setup; not what we want
			HookEvent( "teamplay_setup_finished", Event_RoundActive );
			HookEvent( "arena_round_start", Event_RoundActive );
			
			HookEvent( "post_inventory_application", Event_TF2RegisterClassIfNeeded ); //change_class is not enough, if we i.e. use TF2_SetPlayerClass
		}
		//default = GAME_UNKNOWN: none ; handled on round start
	}
	
	//Target
	RegAdminCmd( "sm_bloodlust", Command_GiveBloodlust, ADMFLAG_BAN, "sm_bloodlust <#userid|name|targets|[aimedTarget]>" );
	RegAdminCmd( "sm_blust", Command_GiveBloodlust, ADMFLAG_BAN, "sm_blust <#userid|name|targets|[aimedTarget]>" );
	RegAdminCmd( "sm_removebloodlust", Command_RemoveBloodlust, ADMFLAG_BAN, "sm_removebloodlust <#userid|name|targets|[aimedTarget]>" );
	RegAdminCmd( "sm_rblust", Command_RemoveBloodlust, ADMFLAG_BAN, "sm_rblust <#userid|name|targets|[aimedTarget]>" );
	RegAdminCmd( "sm_spawnbloodlust", Command_SpawnWithBloodlust, ADMFLAG_BAN, "sm_spawnbloodlust <#userid|name|targets|[aimedTarget]>" );
	RegAdminCmd( "sm_sblust", Command_SpawnWithBloodlust, ADMFLAG_BAN, "sm_sblust <#userid|name|targets|[aimedTarget]>" );
	RegAdminCmd( "sm_cancelspawnbloodlust", Command_CancelSpawnWithBloodlust, ADMFLAG_BAN, "sm_cancelspawnbloodlust <#userid|name|targets|[aimedTarget]>; only with manual bloodlust" );
	RegAdminCmd( "sm_csblust", Command_CancelSpawnWithBloodlust, ADMFLAG_BAN, "sm_csblust <#userid|name|targets|[aimedTarget]>; only with manual bloodlust" );
	//Non-target
	RegAdminCmd( "sm_bloodlustround", Command_BloodlustRound, ADMFLAG_BAN, "sm_bloodlustround ; enable bloodlust for the round" );
	RegAdminCmd( "sm_blustround", Command_BloodlustRound, ADMFLAG_BAN, "sm_blustround ; enable bloodlust for the round" );
	RegAdminCmd( "sm_bloodlustnextround", Command_BloodlustNextRound, ADMFLAG_BAN, "sm_bloodlustnextround ; enable bloodlust for the upcoming round" );
	RegAdminCmd( "sm_blustnround", Command_BloodlustNextRound, ADMFLAG_BAN, "sm_blustnround ; enable bloodlust for the upcoming round" );
	RegAdminCmd( "sm_bloodlusttime", Command_BloodlustTime, ADMFLAG_BAN, "sm_bloodlusttime <time> ; time is in minutes ; enable bloodlust for a time" );
	RegAdminCmd( "sm_blusttime", Command_BloodlustTime, ADMFLAG_BAN, "sm_blusttime <time> ; time is in minutes ; enable bloodlust for a time" );
	RegAdminCmd( "sm_cancelbloodlustround", Command_CancelBloodlust, ADMFLAG_BAN, 
		"sm_cancelbloodlustround ; cancel bloodlust initiated by sm_bloodlustround or sm_bloodlusttime" );
	RegAdminCmd( "sm_cblustround", Command_CancelBloodlust, ADMFLAG_BAN, 
		"sm_cblustround ; cancel bloodlust initiated by sm_bloodlustround or sm_bloodlusttime" );
	RegAdminCmd( "sm_cancelbloolustnextround", Command_CancelBloodlustNextRound, ADMFLAG_BAN, 
		"sm_cancelbloolustnextround ; cancel upcoming bloodlust rounds" );
	RegAdminCmd( "sm_cblustnround", Command_CancelBloodlustNextRound, ADMFLAG_BAN, 
		"sm_cblustnround ; cancel upcoming bloodlust rounds" );
	RegAdminCmd( "sm_cancelbloodlustrounds", Command_CancelBloodlustAndNextRounds, ADMFLAG_BAN, 
		"sm_cancelbloodlustrounds ; cancel bloodlust initiated by sm_bloodlustround or sm_bloodlusttime, and upcoming rounds" );
	RegAdminCmd( "sm_cblustrounds", Command_CancelBloodlustAndNextRounds, ADMFLAG_BAN, 
		"sm_cblustrounds ; cancel bloodlust initiated by sm_bloodlustround or sm_bloodlusttime, and upcoming rounds" );
	
	RegConsoleCmd( "sm_votebloodlust", Command_VoteBloodlustRound, "Vote to enable bloodlust for everyone" );
	RegConsoleCmd( "sm_voteblust", Command_VoteBloodlustRound, "Vote to enable bloodlust for everyone" );
	RegConsoleCmd( "sm_votebl", Command_VoteBloodlustRound, "Vote to enable bloodlust for everyone" );
	
	//Config
	AutoExecConfig( true, "bloodlustmod" );
	
	//Translation
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("bloodlustmod.phrases");
	
	g_fLastMinPlayerReachedPrint = -GetConVarFloat( g_hVerboseMinimumDelay );
	
	//Late load
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) == true )
		{
			g_iVerboseBloodlustCount[ i ] = GetConVarInt( g_hVerboseAnnounceOnSpawn );
			g_fVerboseBloodlustLastTime[ i ] = -GetConVarFloat( g_hVerboseMinimumDelay );
			
			SDKHook( i, SDKHook_OnTakeDamageAlive, Callback_SDKHook_OnTakeDamageAlive );
		}
	}
}
public void OnMapEnd()
{
	g_fTimelimitToGiveBloodlustForAll = 0.0;
	g_fTimelimitNoVote = 0.0;
	g_bIsCurrentRoundIsBloodlustForAll = false;
	g_iNextRoundIsBloodlustForAll = 0;
}
public void OnClientDisconnect(int iClient)
{
	//TF2
	if ( g_tf2ClassType[ iClient ] != TFClass_Unknown )
	{
		g_iTf2ClassCount[ g_tf2ClassType[ iClient ] ]--;
	}
	g_tf2ClassType[ iClient ] = TFClass_Unknown; //done on disconnect, so we don't have to check IsClientInGame if != TFClass_Unknown
	
	//Remove BL
	if ( g_iSpawnWithBloodlust[ iClient ] == ITRUE )
	{
		g_iSpawnWithBloodlust[ iClient ] = IFALSE;
		g_iSpawnWithBloodlust[ 0 ]--;
	}
	
	g_bloodlustTypeForThisRound[ iClient ] = BLOODLUST_NONE;
	
	g_bIsBloodlusted[ iClient ] = false;
	if ( g_hDegenTimer[ iClient ] != INVALID_HANDLE )
	{
		KillTimer( g_hDegenTimer[ iClient ] );
		g_hDegenTimer[ iClient ] = INVALID_HANDLE;
	}
}
public void OnClientDisconnect_Post(int iClient)
{
	if ( g_iVotedForBloodlust[ iClient ] == ITRUE )
	{
		g_iVotedForBloodlust[ iClient ] = IFALSE;
		g_iVotedForBloodlust[ 0 ]--;
	}
	else if ( GetConVarBool( g_hVote ) == true )
	{
		checkIfVotePassAndAct();
	}
}
public void OnClientPutInServer(int iClient)
{
	g_iVerboseBloodlustCount[ iClient ] = GetConVarInt( g_hVerboseAnnounceOnSpawn );
	g_fVerboseBloodlustLastTime[ iClient ] = -GetConVarFloat( g_hVerboseMinimumDelay );
	
	SDKHook( iClient, SDKHook_OnTakeDamageAlive, Callback_SDKHook_OnTakeDamageAlive );
}

// ===== Events ======

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_currentState = STATE_PREROUND;
	
	int autoMode = GetConVarInt( g_hAutoBL );
	
	int playerCount = GetTeamClientCount( 2 ) + GetTeamClientCount( 3 );
	bool nowHasEnoughPlayers = playerCount >= GetConVarInt( g_hAutoBLMinPlayers );
	if ( autoMode >= 1 &&
		nowHasEnoughPlayers != g_bHasEnoughPlayersForAuto )
	{
		//Get team
		char szTeamName[ MAX_NAME_LENGTH ];
		if ( autoMode > 1 )
			getTeamNameConditionalLowerCase( autoMode, szTeamName, sizeof(szTeamName) );
		else //everyone
			FormatEx( szTeamName, sizeof(szTeamName), "%T", "Everyone", LANG_SERVER );
		
		if ( GetConVarBool( g_hVerboseAnnounceMinPlayers ) == true && playerCount > 0 )
		{
			if ( nowHasEnoughPlayers )
				PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "Announce Enough Players", "\x04", g_szModName, "\x01", "\x04", szTeamName, "\x01" );
			else
				PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "Announce Not Enough Players", "\x04", g_szModName, "\x01" );
			
			g_fLastMinPlayerReachedPrint = GetGameTime();
		}
		
		//give health as they didn't get the bonus from whe they spawned before roundstart
		if ( nowHasEnoughPlayers == true )
		{
			for ( int i = 1; i <= MaxClients; ++i )
			{
				if ( !IsClientInGame( i ) || !IsPlayerAlive( i ) || GetClientTeam( i ) < 2 || 
				( g_bloodlustTypeForThisRound[ i ] & ~BLOODLUST_REMOVED ) != BLOODLUST_NONE || 
				( autoMode > 1 && GetClientTeam( i ) != autoMode ) )
					continue;
				
				singlePlayer_ApplySpawnHealthBonus( i );
			}
		}
		//Reset health; this may not be necessary; but in case a mod does not spawn once more the player between 2 rounds
		else/*if ( nowHasEnoughPlayers == false )*/
		{
			for ( int i = 1; i <= MaxClients; ++i )
			{
				if ( !IsClientInGame( i ) || !IsPlayerAlive( i ) || GetClientTeam( i ) < 2 )
					continue;
				
				if ( GetClientHealth( i ) > g_iHealthOnSpawnPreBonus[ i ] )
				{
					SetEntityHealth( i, g_iHealthOnSpawnPreBonus[ i ] );
				}
			}
		}
	}
	g_bHasEnoughPlayersForAuto = nowHasEnoughPlayers;
	
	if ( g_bAutoTimersStarted == false && GetConVarBool( g_hTickActiveGameOnly ) == false )
	{
		//launch timer
		manyPlayersAuto_StartBloodlustTimers();
		
		g_bAutoTimersStarted = true;
	}
	
	if ( g_currentMod == GAME_UNKNOWN )
	{
		//do round_active stuff
		Event_RoundActive(event, name, dontBroadcast);
	}
}
public void Event_RoundActive(Handle event, const char[] name, bool dontBroadcast)
{
	g_currentState = STATE_ACTIVE;
	
	if ( g_bAutoTimersStarted == false && GetConVarBool( g_hTickActiveGameOnly ) == true )
	{
		//launch timer
		manyPlayersAuto_StartBloodlustTimers();
		
		g_bAutoTimersStarted = true;
	}
}
void manyPlayersAuto_StartBloodlustTimers()
{
	int autoBL = GetConVarInt( g_hAutoBL );
	Bloodlust_Type newBloodlust_flags;
	
	float gameTime = GetGameTime();
	
	for ( int i = 1; i <= MaxClients; ++i )
	{
		//a client that DC'ed wont have g_iSpawnWithBloodlust[ iClient ] == ITRUE due to OnClientDisconnected
		if ( !IsClientInGame( i ) || ( g_bloodlustTypeForThisRound[ i ] & BLOODLUST_REMOVED ) ) 
			continue;
		
		newBloodlust_flags = BLOODLUST_NONE;
		
		//if ( g_bloodlustTypeForThisRound[ i ] & BLOODLUST_GIVEN ) //to possibly restart; and only in respawn can we lose it
		//	newBloodlust_flags |= BLOODLUST_GIVEN;
		
		if ( g_bHasEnoughPlayersForAuto && ( autoBL == 1 || autoBL == GetClientTeam( i ) ) )
			newBloodlust_flags |= BLOODLUST_AUTO;
		
		if ( g_bloodlustTypeForThisRound[ i ] & BLOODLUST_MANUAL )
			newBloodlust_flags |= BLOODLUST_MANUAL;
		else if ( g_iSpawnWithBloodlust[ i ] == ITRUE ) //manual; needs to do it before to clean the array
		{
			g_iSpawnWithBloodlust[ i ] = IFALSE;
			g_iSpawnWithBloodlust[ 0 ]--;
			
			newBloodlust_flags |= BLOODLUST_MANUAL; //we may lose the flag if player is alive or spec
		}
		
		if ( g_bIsCurrentRoundIsBloodlustForAll == true )
			newBloodlust_flags |= BLOODLUST_ROUND;
		
		if ( gameTime < g_fTimelimitToGiveBloodlustForAll ) //not considered on round spawn
			newBloodlust_flags |= BLOODLUST_TIME;
		
		if ( !IsPlayerAlive( i ) || GetClientTeam( i ) < 2 )
			continue;
		
		if ( newBloodlust_flags == BLOODLUST_NONE )
			continue;
		
		//do not add health lately, and add only if user wasn't in bloodlust
		if ( g_currentState == STATE_PREROUND && ( g_bloodlustTypeForThisRound[ i ] & ~BLOODLUST_REMOVED ) == BLOODLUST_NONE )
			singlePlayer_ApplySpawnHealthBonus( i );
		
		if ( g_hDegenTimer[ i ] != INVALID_HANDLE )
		{
			KillTimer( g_hDegenTimer[ i ] );
			g_hDegenTimer[ i ] = INVALID_HANDLE;
		}
		
		singlePlayer_EnterBL( i );
		
		//newBloodlust_flags |= BLOODLUST_GIVEN;
		g_bloodlustTypeForThisRound[ i ] |= newBloodlust_flags; //if we were to reapply it in the future (i.e. player spawn happening later)
	}
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_currentState = STATE_ROUNDEND;
	
	//Remove for current round; next round will take care of giving it back
	//Ugh : By doing so we dont have the bonus HP if we're starting timers when unfreezing players; and onSpawn wont have any clue 
	for ( int i; i <= MaxClients; ++i )
		g_bloodlustTypeForThisRound[ i ] = BLOODLUST_NONE;
	
	g_bAutoTimersStarted = false;
	
	g_bIsCurrentRoundIsBloodlustForAll = false;
	
	if ( g_iNextRoundIsBloodlustForAll == 0 && //shouldn't have a bl round next
		GetTeamClientCount( 2 ) + GetTeamClientCount( 3 ) >= GetConVarInt( g_hAutoBLMinPlayers ) )
	{
		float randomRoundChance = GetConVarFloat( g_hRandomRoundChance ); //needs to check 0.0; due to 0% vs 100%
		if ( randomRoundChance != 0.0 && 
			GetRandomFloat() <= randomRoundChance )
		{
			g_iNextRoundIsBloodlustForAll = 1;
			
			if ( GetConVarBool( g_hVerboseAnnounceRandomRound ) == true )
				PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "Announce Random Bloodust Round", "\x04", g_szModName, "\x01" );
		}
	}
	
	if ( g_iNextRoundIsBloodlustForAll > 0 )
	{
		g_bIsCurrentRoundIsBloodlustForAll = true;
		g_iNextRoundIsBloodlustForAll--;
	}
}
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	//allow late tick; i.e. via admin ; or when executed before round starts
	g_iHealthOnSpawnPreBonus[ iClient ] = GetClientHealth( iClient );
	
	//Set Max health (for HP leech and possible negative loss (=++hp))
	if ( GetConVarInt( g_hHealthMaxType ) == 0 )/*absolute*/
	{
		g_iMaximumHealth[ iClient ] = g_iHealthOnSpawnPreBonus[ iClient ] + GetConVarInt( g_hHealthMax );
	}
	else //relative
	{
		g_iMaximumHealth[ iClient ] = RoundToNearest( GetConVarFloat( g_hHealthMax ) * float( g_iHealthOnSpawnPreBonus[ iClient ] ) );
	}
	
	//Remove bloodlust
	g_bIsBloodlusted[ iClient ] = false;
	if ( g_hDegenTimer[ iClient ] != INVALID_HANDLE )
	{
		KillTimer( g_hDegenTimer[ iClient ] );
		g_hDegenTimer[ iClient ] = INVALID_HANDLE;
	}
	
	if ( g_bloodlustTypeForThisRound[ iClient ] & BLOODLUST_REMOVED )
		return;
	
	Bloodlust_Type newBloodlust_flags;
	
	//not needed here; only on round start
	//if ( g_bloodlustTypeForThisRound[ iClient ] & BLOODLUST_GIVEN )
	//	newBloodlust_flags |= BLOODLUST_GIVEN;
	
	int autoBL = GetConVarInt( g_hAutoBL );
	if ( ( autoBL == 1 || autoBL == GetClientTeam( iClient ) ) && g_bHasEnoughPlayersForAuto == true )
		newBloodlust_flags |= BLOODLUST_AUTO;
	
	if ( g_bloodlustTypeForThisRound[ iClient ] & BLOODLUST_MANUAL ) //check not needed on RoundStart
	{
		newBloodlust_flags |= BLOODLUST_MANUAL;
	}
	else if ( g_iSpawnWithBloodlust[ iClient ] == ITRUE )
	{
		g_iSpawnWithBloodlust[ iClient ] = IFALSE;
		g_iSpawnWithBloodlust[ 0 ]--;
		
		newBloodlust_flags |= BLOODLUST_MANUAL;
	}
	
	if ( g_bIsCurrentRoundIsBloodlustForAll == true )
		newBloodlust_flags |= BLOODLUST_ROUND;
	
	if ( GetGameTime() < g_fTimelimitToGiveBloodlustForAll )
		newBloodlust_flags |= BLOODLUST_TIME;
	
	if ( newBloodlust_flags != BLOODLUST_NONE ) //if the player is affected by the mod of the plugin; BLOODLUST_REMOVED checked before
	{
		if ( GetClientTeam( iClient ) < 2 ) //if we were to spawn obs next round; we lose it
			return;
		
		//1- Modify starts health
		singlePlayer_ApplySpawnHealthBonus( iClient );
		
		//2- Start degen; do not do so if it can be postponed to roundstart / roundactive
		if ( g_bAutoTimersStarted == true )
		{
			singlePlayer_EnterBL( iClient );
		}
		
		float gameTime = GetGameTime();
		//if ( !IsFakeClient( iClient ) )
		//	PrintToChatAll("REMOVE count%d, indTime%.2f, pubTime%.2f, gametime%.2f", g_iVerboseBloodlustCount[ iClient ], g_fVerboseBloodlustLastTime[ iClient ], g_fLastMinPlayerReachedPrint, gameTime );

		//3- Announce
		if ( g_iVerboseBloodlustCount[ iClient ] > 0 && 
			g_fVerboseBloodlustLastTime[ iClient ] + GetConVarFloat( g_hVerboseMinimumDelay ) < gameTime &&
			g_fLastMinPlayerReachedPrint + GetConVarFloat( g_hVerboseMinimumDelay ) < gameTime )
		{
			PrintToChat( iClient, "\x04%s\x01%t", g_szVerbosePrefix, "Announce Explain Bloodlust", "\x04", g_szModName, "\x01" );
			g_iVerboseBloodlustCount[ iClient ]--;
			g_fVerboseBloodlustLastTime[ iClient ] = gameTime;
		}
		
		//newBloodlust_flags |= BLOODLUST_GIVEN;
		g_bloodlustTypeForThisRound[ iClient ] |= newBloodlust_flags; //will allow for instance to use RoundStart after being spawned to trigger the timer
	}
	
	return;
}
void singlePlayer_EnterBL(const int iClient)
{
	g_bIsBloodlusted[ iClient ] = true;
	if ( GetConVarFloat( g_hTickDelay ) > 0.0 )
	{
		g_hDegenTimer[ iClient ] = CreateTimer( GetConVarFloat( g_hTickDelay ), Timer_Degen, (iClient << 16) | GetClientUserId( iClient ), TIMER_REPEAT );
	}
}
void singlePlayer_ApplySpawnHealthBonus(int iClient)
{
	int healthModification;
	if ( GetConVarInt( g_hHealthSpawnType ) == 0 )/*absolute*/
	{
		healthModification = GetConVarInt( g_hHealthSpawn );
	}
	else //relative
	{
		healthModification = RoundToNearest( GetConVarFloat( g_hHealthSpawn ) * float( g_iHealthOnSpawnPreBonus[ iClient ] ) );
	}
	//Set health ; we do not consider MaxHealth on spawn
	SetEntityHealth( iClient, g_iHealthOnSpawnPreBonus[ iClient ] + healthModification );
}
public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	g_bIsBloodlusted[ iClient ] = false;
	if ( g_hDegenTimer[ iClient ] != INVALID_HANDLE )
	{
		KillTimer( g_hDegenTimer[ iClient ] );
		g_hDegenTimer[ iClient ] = INVALID_HANDLE;
	}
	
	//if we're bloodlusted for this round and that we should lose it ==> remove manual flag
	if ( GetConVarBool( g_hManualLoseOnDeath ) == true )
		g_bloodlustTypeForThisRound[ iClient ] &= ~BLOODLUST_MANUAL;
}
public void Event_TF2RegisterClassIfNeeded(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	//Take for granted it is always > 0 ; I hope :$
	
	TFClassType possibleNewClass = TF2_GetPlayerClass( iClient );
	
	if ( possibleNewClass != g_tf2ClassType[ iClient ] )
	{
		if ( g_tf2ClassType[ iClient ] != TFClass_Unknown )  // exclude civilians
			g_iTf2ClassCount[ g_tf2ClassType[ iClient ] ]--;
		
		if ( possibleNewClass != TFClass_Unknown )
		{
			g_iTf2ClassCount[ possibleNewClass ]++;
			g_tf2ClassType[ iClient ] = possibleNewClass;
		}
	}
}

// ===== Callbacks : SDKHooks =====

//needs to be pre to have the victim health
public Action Callback_SDKHook_OnTakeDamageAlive(int iVictim, int& iAttacker, int& inflictor, float& damage, int& damagetype)
{
	if ( iAttacker > MaxClients ||
		g_bIsBloodlusted[ iAttacker ] == false ||
		iAttacker == iVictim )
		return Plugin_Continue;
	
	float fHealthLeech = GetConVarFloat( g_hHealthLeech );
	
	if ( fHealthLeech == 0.0 )
		return Plugin_Continue;
	
	int health = GetClientHealth( iAttacker );
	
	//Get the amount of health leeched and set it if possible
	if ( health < g_iMaximumHealth[ iAttacker ] && //If hp isn't at max, player can heal
		( GetClientTeam( iAttacker ) != GetClientTeam( iVictim ) || //Different team
		( GetClientTeam( iAttacker ) == GetClientTeam( iVictim ) && //Same team
		GetConVarBool( g_hFf ) == true ) ) ) //Same team allowed ?
	{
		//Limit HP leech to the target's life
		float suckableHP = damage;
		float victimHealth = float( GetClientHealth( iVictim ) );
		if ( suckableHP > victimHealth )
			suckableHP = victimHealth;
		
		if ( g_currentMod == view_as<Acknowledged_Mod>(GAME_TF2) )
		{
			int healerCount;
			int bloodlustedHealerClientIds[ MAXPLAYERS ];
			int bloodlustedHealersCount;
			getHealers_TF2( iAttacker, GetClientTeam( iAttacker ), bloodlustedHealerClientIds, bloodlustedHealersCount, healerCount );
			
			if ( healerCount > 0 )
			{
				float medigunMedicRatio = GetConVarFloat( g_hTf2HealthLeechMedigunMedicRatio );
				if ( medigunMedicRatio != 0.0 && bloodlustedHealersCount > 0 )
				{
					int medicBonusHealth = 
						GetConVarBool( g_hTf2HealthLeechMedigunSplitIfMany ) == true ?
						RoundToNearest( medigunMedicRatio * suckableHP / float( healerCount ) ) :
						RoundToNearest( medigunMedicRatio * suckableHP );
					
					if ( medicBonusHealth > 0 )
					{
						int newMedicHealth;
						int medicClientId;
						for ( int i; i < bloodlustedHealersCount; ++i )
						{
							medicClientId = bloodlustedHealerClientIds[ i ];
							newMedicHealth = GetClientHealth( medicClientId ) + medicBonusHealth;
							if ( newMedicHealth > g_iMaximumHealth[ medicClientId ] )
								newMedicHealth = g_iMaximumHealth[ medicClientId ];
							
							SetEntityHealth( medicClientId, newMedicHealth );
						}
					}
				}
				
				if ( GetConVarBool( g_hTf2HealthLeechMedigunTargetRatioType ) == false ||
					( GetConVarBool( g_hTf2HealthLeechMedigunTargetRatioType ) == true && bloodlustedHealersCount > 0 ) ) //needs at least 1 bloodlust
				{
					suckableHP *= GetConVarFloat( g_hTf2HealthLeechMedigunTargetRatio );
				}
			}
		} /* END_TF2 */
		
		int newHealth = health + RoundToNearest( suckableHP * fHealthLeech );
		if ( newHealth > g_iMaximumHealth[ iAttacker ] )
		{
			newHealth = g_iMaximumHealth[ iAttacker ];
		}
		
		//Set health
		SetEntityHealth( iAttacker, newHealth );
	}
	
	return Plugin_Continue;
}

// ===== Callbacks : Timers =====

//Reasons for the timer to be killed : Player disconnect, player dies, player spawn, player change team (may not trigger death AFAIK)
public Action Timer_Degen(Handle timer, int iUserId)
{
	if ( GetConVarBool( g_hTickActiveGameOnly ) == true && g_currentState != STATE_ACTIVE )
		return Plugin_Continue;
	
	int iClient = GetClientOfUserId( iUserId & 0xFFFF );
	
	//Normally iClient > 0 since OnClientDisconnect handles that,
	//but just to be safe...
	if ( iClient == 0 )
	{
		g_bIsBloodlusted[ (iUserId >> 16) ] = false;
		g_hDegenTimer[ (iUserId >> 16) ] = INVALID_HANDLE;
		return Plugin_Stop; //stops timer
	}
	
	//Get health
	if ( GetClientTeam( iClient ) < 2 || IsPlayerAlive( iClient ) == false )
	{
		g_bIsBloodlusted[ iClient ] = false;
		g_hDegenTimer[ iClient ] = INVALID_HANDLE; //allow timer at next spawn
		return Plugin_Stop; //stops timer
	}
	
	int health = GetClientHealth( iClient );
	
	int healthLoss;
	if ( GetConVarInt( g_hTickLossType ) == 0 )/*absolute*/ 
	{
		healthLoss = GetConVarInt( g_hTickLoss );
	}
	else //relative
	{
		int healthLossFactor;
		if ( GetConVarInt( g_hTickLossType ) == 1 ) /*Health on spawn pre bonus*/
		{
			healthLossFactor = g_iHealthOnSpawnPreBonus[ iClient ];
		}
		else /* current */
		{
			healthLossFactor = health;
		}
		
		switch ( GetConVarInt( g_hTickLossTypeRelativeRounding ) )
		{
			case 0 :
				healthLoss = RoundToFloor( healthLossFactor * GetConVarFloat( g_hTickLoss ) );
			case 1 :
				healthLoss = RoundToNearest( healthLossFactor * GetConVarFloat( g_hTickLoss ) );
			default/*case 2*/ :
				healthLoss = RoundToCeil( healthLossFactor * GetConVarFloat( g_hTickLoss ) );
		}
	}
	
	int newHealth = health - healthLoss;
	if ( GetConVarInt( g_hTickLossCanKill ) == 0 ||
		( GetConVarInt( g_hTickLossCanKill ) == 2 && ( g_currentState != STATE_ACTIVE ) ) )
	{
		if ( newHealth <= 0 )
			newHealth = 1;
	}
	
	if ( newHealth <= 0 ) //If player would be dead (0 hp or less)
	{
		ForcePlayerSuicide( iClient );
		if ( GetConVarBool( g_hVerboseDeathBloodlust ) == true )
		{
			PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "Death From Bloodlust", "\x04", iClient, "\x01" );
		}
		
		g_bIsBloodlusted[ iClient ] = false;
		g_hDegenTimer[ iClient ] = INVALID_HANDLE; //allow timer at next spawn
		return Plugin_Stop; //stops timer
	}
	else
	{
		//Since I'm allowing negative ticks
		//if healthLoss is negative = gain
		if ( healthLoss < 0 && newHealth > g_iMaximumHealth[ iClient ] )
		{
			newHealth = g_iMaximumHealth[ iClient ];
		}
		
		//Fade
		if ( newHealth <= GetConVarInt( g_hTickFadeThreshold ) && GetConVarInt( g_hTickFadeLength ) > 0 )
		{
			Handle msg = StartMessageOne( "Fade", iClient );
			
			if ( GetUserMessageType() == UM_Protobuf )
			{
				PbSetInt( msg, "duration", GetConVarInt( g_hTickFadeLength ) );
				PbSetInt( msg, "hold_time", 0);
				PbSetInt( msg, "flags", 1);
				int clr[ 4 ]; //need a temp var zzz
				clr[ 0 ] = (g_iFadeColor >> 24) & 0xFF;
				clr[ 1 ] = (g_iFadeColor >> 16) & 0xFF;
				clr[ 2 ] = (g_iFadeColor >> 8) & 0xFF;
				clr[ 3 ] = g_iFadeColor & 0xFF;
				PbSetColor( msg, "clr", clr );
			}
			else
			{
				BfWriteShort( msg, GetConVarInt( g_hTickFadeLength ) ); //duration
				BfWriteShort( msg, 0 ); //duration until reset
				BfWriteShort( msg, 1 ); //type
				BfWriteByte( msg, (g_iFadeColor >> 24) & 0xFF ); //red
				BfWriteByte( msg, (g_iFadeColor >> 16) & 0xFF ); //green
				BfWriteByte( msg, (g_iFadeColor >> 8) & 0xFF ); //blue
				BfWriteByte( msg, g_iFadeColor & 0xFF ); //alpha
			}
			
			EndMessage();
		}
		
		//Set health
		if ( newHealth == health ) //deny function call since there are no need change health
			return Plugin_Continue;
		
		SetEntityHealth( iClient, newHealth );
	}
	
	return Plugin_Continue;
}

// ===== Admin Commands =====

public Action Command_GiveBloodlust(int client, int args)
{
	char target_name[ MAX_TARGET_LENGTH ];
	int target_list[ MAXPLAYERS ];
	int target_count;
	bool tn_is_ml;
	
	if ( getAdminCmdTargets( client, args, "sm_bloodlust|say !bloodlust", 
		target_name, sizeof(target_name), target_list, target_count, tn_is_ml ) == false )
		return Plugin_Handled;
	
	//If not Game ending --> apply
	//else --> do on spawn
	if ( g_currentState != STATE_ROUNDEND )
	{
		int currentTarget;
		for ( int i; i < target_count; ++i )
		{
			currentTarget = target_list[ i ];
			//if already in bloodlust, restart
			g_bIsBloodlusted[ currentTarget ] = false;
			if ( g_hDegenTimer[ currentTarget ] != INVALID_HANDLE )
			{
				KillTimer( g_hDegenTimer[ currentTarget ] );
				g_hDegenTimer[ currentTarget ] = INVALID_HANDLE;
			}
			
			g_bloodlustTypeForThisRound[ currentTarget ] |= BLOODLUST_MANUAL;
			//g_bloodlustTypeForThisRound[ currentTarget ] |= BLOODLUST_GIVEN;
			g_bloodlustTypeForThisRound[ currentTarget ] &= ~BLOODLUST_REMOVED; //remove REMOVE flag
			
			singlePlayer_EnterBL( currentTarget );
		}
		
		if ( tn_is_ml )
		{
			ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Gives Bloodlust To", 
				"\x04", g_szModName, "\x01", "\x04", target_name, "\x01");
		}
		else
		{
			ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Gives Bloodlust To", 
				"\x04", g_szModName, "\x01", "\x04", "_s", target_name, "\x01");
		}
		
		if ( GetConVarBool( g_hLogAdmin ) == true )
			LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
				"\"%L\" gave/regave bloodlust to \"%s\" (%d affected clients).", client, target_name, target_count );
	}
	else //ROUND_END --> next round; do as if it was a "on-spawn"
	{
		int changeCount;
		for ( int i; i < target_count; ++i )
		{
			if ( g_iSpawnWithBloodlust[ target_list[ i ] ] == IFALSE )
			{
				g_iSpawnWithBloodlust[ target_list[ i ] ] = ITRUE;
				changeCount++;
			}
		}
		g_iSpawnWithBloodlust[ 0 ] += changeCount;
		
		if ( tn_is_ml )
		{
			ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Gives Bloodlust on Spawn To", 
				"\x04", g_szModName, "\x01", "\x04", target_name, "\x01" );
		}
		else
		{
			ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Gives Bloodlust on Spawn To", 
				"\x04", g_szModName, "\x01", "\x04", "_s", target_name, "\x01" );
		}
		
		
		if ( GetConVarBool( g_hLogAdmin ) == true )
			LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
				"\"%L\" gave bloodlust-on-next-spawn to \"%s\" (%d affected clients).", client, target_name, changeCount );
	}
	
	return Plugin_Handled;
}
public Action Command_RemoveBloodlust(int client, int args)
{
	if ( g_currentState == STATE_ROUNDEND )
	{
		ReplyToCommand( client, "\x04[SM] \x01%t", "AdminCmdReply Not Now" );
		return Plugin_Handled;
	}
	
	char target_name[ MAX_TARGET_LENGTH ];
	int target_list[ MAXPLAYERS ];
	int target_count;
	bool tn_is_ml;
	
	if ( getAdminCmdTargets( client, args, "sm_removebloodlust|say !removebloodlust", 
		target_name, sizeof(target_name), target_list, target_count, tn_is_ml ) == false )
		return Plugin_Handled;
	
	//If not Game ending --> remove
	//else --> do nothing
	int currentTarget;
	for ( int i; i < target_count; ++i )
	{
		currentTarget = target_list[ i ];
		
		//Remove bloodlust
		g_bIsBloodlusted[ currentTarget ] = false;
		if ( g_hDegenTimer[ currentTarget ] != INVALID_HANDLE )
		{
			KillTimer( g_hDegenTimer[ currentTarget ] );
			g_hDegenTimer[ currentTarget ] = INVALID_HANDLE;
		}
		
		//prevent further bloodlust for this round
		g_bloodlustTypeForThisRound[ currentTarget ] = BLOODLUST_REMOVED;
	}
	
	if ( tn_is_ml )
	{
		ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Removes Bloodlust To", 
			"\x04", g_szModName, "\x01", "\x04", target_name, "\x01");
	}
	else
	{
		ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Removes Bloodlust To", 
			"\x04", g_szModName, "\x01", "\x04", "_s", target_name, "\x01");
	}
	
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
			"\"%L\" removed bloodlust from \"%s\" (%d affected clients).", client, target_name, target_count );
	
	return Plugin_Handled;
}
public Action Command_SpawnWithBloodlust(int client, int args)
{
	char target_name[ MAX_TARGET_LENGTH ];
	int target_list[ MAXPLAYERS ];
	int target_count;
	bool tn_is_ml;
	
	if ( getAdminCmdTargets( client, args, "sm_spawnbloodlust|say !spawnbloodlust", 
		target_name, sizeof(target_name), target_list, target_count, tn_is_ml ) == false )
		return Plugin_Handled;
	
	int changeCount;
	for ( int i; i < target_count; ++i )
	{
		if ( g_iSpawnWithBloodlust[ target_list[ i ] ] == IFALSE )
		{
			g_iSpawnWithBloodlust[ target_list[ i ] ] = ITRUE;
			changeCount++;
		}
	}
	g_iSpawnWithBloodlust[ 0 ] += changeCount;
	
	if ( tn_is_ml )
	{
		ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Gives Bloodlust on Spawn To", 
			"\x04", g_szModName, "\x01", "\x04", target_name, "\x01" );
	}
	else
	{
		ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Gives Bloodlust on Spawn To", 
			"\x04", g_szModName, "\x01", "\x04", "_s", target_name, "\x01" );
	}
	
	
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
			"\"%L\" gave bloodlust-on-next-spawn to \"%s\" (%d affected clients).", client, target_name, changeCount );
	
	return Plugin_Handled;
}
public Action Command_CancelSpawnWithBloodlust(int client, int args)
{
	char target_name[ MAX_TARGET_LENGTH ];
	int target_list[ MAXPLAYERS ];
	int target_count;
	bool tn_is_ml;
	
	if ( getAdminCmdTargets( client, args, "sm_cancelspawnbloodlust|say !csblust", 
		target_name, sizeof(target_name), target_list, target_count, tn_is_ml, "; only with manual bloodlust" ) == false )
		return Plugin_Handled;
	
	int changeCount;
	for ( int i; i < target_count; ++i )
	{
		if ( g_iSpawnWithBloodlust[ target_list[ i ] ] == ITRUE )
		{
			g_iSpawnWithBloodlust[ target_list[ i ] ] = IFALSE;
			changeCount++;
		}
	}
	g_iSpawnWithBloodlust[ 0 ] -= changeCount;
	
	if ( tn_is_ml )
	{
		ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Cancel Bloodlust on Spawn Of", 
			"\x04", g_szModName, "\x01", "\x04", target_name, "\x01");
	}
	else
	{
		ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Cancel Bloodlust on Spawn Of",
			"\x04", g_szModName, "\x01", "\x04", "_s", target_name, "\x01");
	}
	
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
			"\"%L\" canceled the bloodlust-on-spawn of \"%s\" (%d affected clients).", client, target_name, changeCount );
	
	return Plugin_Handled;
}
public Action Command_BloodlustRound(int client, int args)
{
	if ( g_bIsCurrentRoundIsBloodlustForAll == true ||
		( g_currentState == STATE_ROUNDEND && g_iNextRoundIsBloodlustForAll > 0 ) )
	{
		ReplyToCommand( client, "\x04[SM] \x01%t", "AdminCmdReply Round In Question Already" );
		return Plugin_Handled;
	}
	
	startsBloodlustForEveryoneAndAddFlag( BLOODLUST_ROUND );
	
	g_bIsCurrentRoundIsBloodlustForAll = true;
	
	ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Bloodlust Round", 
		"\x04", g_szModName, "\x01" );
		
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, -1, "\"%L\" made the round bloodlust.", client );
	
	return Plugin_Handled;
}
public Action Command_BloodlustNextRound(int client, int args)
{
	if ( g_iNextRoundIsBloodlustForAll > 0 )
	{
		ReplyToCommand( client, "\x04[SM] \x01%t", "AdminCmdReply Round In Question Already" );
		return Plugin_Handled;
	}
	
	g_iNextRoundIsBloodlustForAll = 1;
	
	ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Bloodlust Next Round", 
		"\x04", g_szModName, "\x01" );
		
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, -1, "\"%L\" made the next round bloodlust.", client );
	
	return Plugin_Handled;
}
public Action Command_BloodlustTime(int client, int args)
{
	if ( args != 1 )
	{
		ReplyToCommand( client, "\x04[SM] \x01Usage: <sm_bloodlusttime <time>> ; time is in minutes" );
		return Plugin_Handled;
	}
	
	char strTime[ 8 ];
	GetCmdArg( 1, strTime, sizeof(strTime) );
	
	g_fTimelimitToGiveBloodlustForAll = GetGameTime() + StringToFloat( strTime ) * 60.0;
	
	//Currently a vote wouldn't change anything; so lets reset it ?
	if ( GetConVarInt( g_hVoteLengthType ) == 1 && 
		g_fTimelimitToGiveBloodlustForAll > GetConVarFloat( g_hVoteLength ) * 60.0 )
	{
		for ( int i; i <= MaxClients; ++i )
			g_iVotedForBloodlust[ i ] = IFALSE;
	}
	
	startsBloodlustForEveryoneAndAddFlag( BLOODLUST_TIME );
	
	ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Bloodlust Time", 
		"\x04", g_szModName, "\x01", "\x04", g_fTimelimitToGiveBloodlustForAll, "\x01" );
		
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, -1, "\"%L\" made the next %s minutes bloodlust.", client, strTime );
	
	return Plugin_Handled;
}
public Action Command_CancelBloodlust(int client, int args)
{
	if ( g_bIsCurrentRoundIsBloodlustForAll == false &&
		g_fTimelimitToGiveBloodlustForAll == 0.0 )
	{
		ReplyToCommand( client, "\x04[SM] \x01%t", "AdminCmdReply Nothing To Cancel" );
		return Plugin_Handled;
	}
	
	cancelCurrentRoundAndTimelimit();
	
	ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Bloodlust Round Cancel", 
		"\x04", g_szModName, "\x01" );
		
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, -1, "\"%L\" canceled current bloodlust round/time.", client );
	
	return Plugin_Handled;
}
public Action Command_CancelBloodlustNextRound(int client, int args)
{
	if ( g_iNextRoundIsBloodlustForAll == 0 )
	{
		ReplyToCommand( client, "\x04[SM] \x01%t", "AdminCmdReply Nothing To Cancel Future" );
		return Plugin_Handled;
	}
	
	g_iNextRoundIsBloodlustForAll = 0;
	
	ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Bloodlust Next Round Cancel", 
		"\x04", g_szModName, "\x01" );
		
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, -1, "\"%L\" canceled next round bloodlust.", client );
		
	return Plugin_Handled;
}
public Action Command_CancelBloodlustAndNextRounds(int client, int args)
{
	if ( g_iNextRoundIsBloodlustForAll == 0 && 
		g_bIsCurrentRoundIsBloodlustForAll == false &&
		g_fTimelimitToGiveBloodlustForAll == 0.0 )
	{
		ReplyToCommand( client, "\x04[SM] \x01%t", "AdminCmdReply Nothing To Cancel" );
		return Plugin_Handled;
	}
	
	cancelCurrentRoundAndTimelimit();
	
	//Next rounds
	g_iNextRoundIsBloodlustForAll = 0;
	
	ShowActivity2( client, g_szVerbosePrefixForShowActivity, "\x01%t", "AdminCmd Bloodlust Round AND Next Round Cancel", 
		"\x04", g_szModName, "\x01" );
		
	if ( GetConVarBool( g_hLogAdmin ) == true )
		LogAction( client, -1, "\"%L\" canceled current & next bloodlust round, and time bloodlust.", client );
		
	return Plugin_Handled;
}
public Action Command_VoteBloodlustRound(int client, int args)
{
	if ( GetConVarBool( g_hVote ) == false )
		return Plugin_Continue;
	
	if ( client == 0 )
	{
		ReplyToCommand( client, "wtf cmon bro" );
		return Plugin_Handled;
	}
	
	float gameTime = GetGameTime();
	if ( gameTime < g_fTimelimitNoVote )
	{
		PrintToChat( client, "\x04%s\x01%t", g_szVerbosePrefix, "BL You cant vote now",
		"\x04", ( g_fTimelimitNoVote - gameTime ) / 60.0, "\x01" );
		return Plugin_Handled;
	}
	
	//A vote would have no effects right now (i.e. the time we win would be less than currentTimeRemaining)
	if ( GetConVarInt( g_hVoteLengthType ) == 1 && g_fTimelimitToGiveBloodlustForAll > gameTime + GetConVarFloat( g_hVoteLength ) * 60.0 )
	{
		PrintToChat( client, "\x04%s\x01%t", g_szVerbosePrefix, "BL Vote no effect",
		"\x04", g_fTimelimitToGiveBloodlustForAll, "\x01", "\x04", g_szModName, "\x01" );
		return Plugin_Handled;
	}
	
	if ( g_iVotedForBloodlust[ client ] == ITRUE )
	{
		PrintToChat( client, "\x04%s\x01%t", g_szVerbosePrefix, "BL You already voted" );
		return Plugin_Handled;
	}
	
	g_iVotedForBloodlust[ client ] = ITRUE;
	g_iVotedForBloodlust[ 0 ]++;
	
	int inFavour = g_iVotedForBloodlust[ 0 ];
	
	int playerCountNeeded = checkIfVotePassAndAct();
	
	if ( playerCountNeeded != 0 )
		PrintToChatAll( "\x04%s\x01%t", g_szVerbosePrefix, "BL Vote not yet pass more needed", 
			"\x04", client, "\x01", "\x04", g_szModName, "\x01", 
			"\x04", inFavour, "\x01", "\x04", playerCountNeeded - inFavour, "\x01" );
	else //vote passes; need to apply BL to everyone
	{
		startsBloodlustForEveryoneAndAddFlag( GetConVarInt( g_hVoteLengthType ) == 1 ? BLOODLUST_TIME : BLOODLUST_ROUND );
	}
	
	if ( GetConVarBool( g_hVoteHideTrigger ) == true )
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

// ===== ConVarChange =====
public void ConVarChange_FadeColor( Handle conVar, const char[] oldvalue, const char[] newvalue )
{
	char fadeSubStr[ 5 ][ 4 ]; //5 for error detection
	if ( ExplodeString( newvalue, " ", fadeSubStr, sizeof(fadeSubStr), sizeof(fadeSubStr[]) ) != 4 )
	{
		LogMessage( "Failed to update color with '%s', value won't be updated", newvalue );
		return;
	}
	
	int newFadeColor = 0;
	int tmp;
	for ( int i; i < 4; ++i )
	{
		tmp = StringToInt( fadeSubStr[ i ] );
		if ( tmp < 0 || tmp > 255 )
		{
			LogMessage( "Failed to update color with '%s', value won't be updated", newvalue );
			break;
		}
		
		newFadeColor |= tmp << (8 * (3 - i));
	}
	g_iFadeColor = newFadeColor;
}
public void ConVarChange_VerbosePrefix( Handle conVar, const char[] oldvalue, const char[] newvalue )
{
	strcopy( g_szVerbosePrefix, sizeof(g_szVerbosePrefix), newvalue );
	strcopy( g_szVerbosePrefixForShowActivity, sizeof(g_szVerbosePrefixForShowActivity), "\x04" );
	StrCat( g_szVerbosePrefixForShowActivity, sizeof(g_szVerbosePrefixForShowActivity), g_szVerbosePrefix );
	StrCat( g_szVerbosePrefixForShowActivity, sizeof(g_szVerbosePrefixForShowActivity), "\x03" );
}
public void ConVarChange_VerboseModName( Handle conVar, const char[] oldvalue, const char[] newvalue )
{
	strcopy( g_szModName, sizeof(g_szModName), newvalue );
}

// ===== Privates ======
// === TF2 ===
int getHealingTarget_TF2(const int medicClientId) //player_healedbymedic event doesn't work :(
{
	char netClassname[ 16 ];
	
	int index = GetEntPropEnt( medicClientId, Prop_Send, "m_hActiveWeapon" );
	if ( index > 0 )
		GetEntityNetClass( index, netClassname, sizeof(netClassname) );
	
	if ( StrEqual( netClassname, "CWeaponMedigun" ) )
	{
		if ( GetEntProp( index, Prop_Send, "m_bHealing" ) == 1 )
		{
			return GetEntPropEnt( index, Prop_Send, "m_hHealingTarget" );
		}
	}
	return -1;
}
int getHealers_TF2(const int targetClientId, const int targetTeam, int[] bloodlustedHealers, int& bloodlustedHealerCount, int& healerCount )
{
	if ( g_iTf2ClassCount[ TFClass_Medic ] == 0 )
		return;
	
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( g_tf2ClassType[ i ] != TFClass_Medic ) //DC or not medic
			continue;
		
		if ( GetClientTeam( i ) != targetTeam )
			continue;
		
		if ( IsPlayerAlive( i ) == false ) //might not be needed ; but what if medic dies when healing ? don't wanna test zzz
			continue;
		
		if ( getHealingTarget_TF2( i ) == targetClientId )
		{
			if ( g_bIsBloodlusted[ i ] == true )
				bloodlustedHealers[ bloodlustedHealerCount++ ] = i;
			
			healerCount++;
			if ( healerCount == g_iTf2ClassCount[ TFClass_Medic ] ) //no more medic to check
				return;
		}
	}
}
// === others ===
//used to save space ; me cod iz 2 fat =(
//ret = shouldContinue
bool getAdminCmdTargets( const int client, const int args, const char[] cmdInfo,
	char[] target_name, 
	const int target_name_size, int[] target_list, 
	int& target_count, bool& tn_is_ml, const char[] cmdInfoSuffix="" )
{
	if (args < 1 && client != 0) //If no arg; check target aimed at
	{
		target_list[ target_count++ ] = GetClientAimTarget( client );
	}
	else if (args < 2)
	{
		char targetArg[ 65 ];
		GetCmdArg( 1, targetArg, sizeof(targetArg) );
		
		if ((target_count = ProcessTargetString(
				targetArg,
				client,
				target_list,
				MAXPLAYERS,
				0, //always need alive & dead
				target_name,
				target_name_size,
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return false;
		}
	}
	
	if ( target_count < 1 ) //i.e. 2 args
	{
		ReplyToCommand( client, "\x04[SM] \x01Usage: <%s> <#userid|name|target|[aimedTarget]>%s", cmdInfo, cmdInfoSuffix );
		return false;
	}
	
	return true;
}
//return amount of player needed for the vote to pass
int checkIfVotePassAndAct()
{
	//count players
	int playerCount;
	for ( int i = 1; i <= MaxClients; ++i )
		if ( IsClientInGame( i ) && !IsFakeClient( i ) )
			++playerCount;
	
	//check ratio
	if ( playerCount > 0 )
	{
		float voteCurrentRatio = float( g_iVotedForBloodlust[ 0 ] ) / float( playerCount );
		if ( voteCurrentRatio  >= GetConVarFloat( g_hVotePercentageNeeded ) )
		{
			int voteLengthType = GetConVarInt( g_hVoteLengthType );
			
			g_iVotedForBloodlust[ 0 ] = 0;
			for ( int i = 1; i <= MaxClients; ++i )
			{
				if ( IsClientInGame( i ) == false )
					continue;
				
				g_iVotedForBloodlust[ i ] = IFALSE;
				
				if ( IsPlayerAlive( i ) == false ||
					GetClientTeam( i ) < 2 )
					continue;
				
				//if already in bloodlust, restart
				g_bIsBloodlusted[ i ] = false;
				if ( g_hDegenTimer[ i ] != INVALID_HANDLE )
				{
					KillTimer( g_hDegenTimer[ i ] );
					g_hDegenTimer[ i ] = INVALID_HANDLE;
				}
				
				g_bloodlustTypeForThisRound[ i ] |= ( voteLengthType == 1 ) ? BLOODLUST_TIME : BLOODLUST_ROUND;
				//g_bloodlustTypeForThisRound[ i ] |= BLOODLUST_GIVEN;
				g_bloodlustTypeForThisRound[ i ] &= ~BLOODLUST_REMOVED; //remove REMOVE flag
				
				singlePlayer_EnterBL( i );
			}
			
			//Effects & verbose
			if ( voteLengthType )
			{
				g_fTimelimitToGiveBloodlustForAll = GetGameTime() + GetConVarFloat( g_hVoteLength ) * 60.0;
				
				PrintToChatAll( "\x04%s\x01%t%t", g_szVerbosePrefix, "BL Vote passed", "\x04", g_szModName, "\x01", 
					"BL Vote passed time",
					"\x04", g_szModName, "\x01", 
					"\x04", GetConVarFloat( g_hVoteLength ), "\x01" );
			}
			else
			{
				g_bIsCurrentRoundIsBloodlustForAll = true;
				g_iNextRoundIsBloodlustForAll = GetConVarInt( g_hVoteLength );
				
				if ( g_iNextRoundIsBloodlustForAll == 0 )
				{
					PrintToChatAll( "\x04%s\x01%t%t", g_szVerbosePrefix, "BL Vote passed", "\x04", g_szModName, "\x01", 
						"BL Vote passed round_zero",
						"\x04", g_szModName, "\x01" );
				}
				else
				{
					PrintToChatAll( "\x04%s\x01%t%t", g_szVerbosePrefix, "BL Vote passed", "\x04", g_szModName, "\x01", 
						"BL Vote passed round",
						"\x04", g_szModName, "\x01", 
						"\x04", g_iNextRoundIsBloodlustForAll, "\x01" );
				}
				
			}
			
			g_fTimelimitNoVote = GetGameTime() + GetConVarFloat( g_hVoteRevoteDelay ) * 60.0;
			
			if ( GetConVarBool( g_hLogPassedVote ) == true )
				LogMessage( "A vote passed to enable bloodlust." );
			
			return 0; //0 = don't want to print to user vote when it passed
		}
		
		return RoundToCeil( float( playerCount ) * GetConVarFloat( g_hVotePercentageNeeded ) );
	}
	
	return 0;
}
void startsBloodlustForEveryoneAndAddFlag( const Bloodlust_Type flags )
{
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) == false )
			continue;
		
		//if already in bloodlust, restart
		g_bIsBloodlusted[ i ] = false;
		if ( g_hDegenTimer[ i ] != INVALID_HANDLE )
		{
			KillTimer( g_hDegenTimer[ i ] );
			g_hDegenTimer[ i ] = INVALID_HANDLE;
		}
		
		g_bloodlustTypeForThisRound[ i ] |= flags;
		g_bloodlustTypeForThisRound[ i ] &= ~BLOODLUST_REMOVED; //remove REMOVE flag
		
		if ( GetClientTeam( i ) < 2 || IsPlayerAlive( i ) == false )
			continue;
		
		singlePlayer_EnterBL( i );
	}
}
void cancelCurrentRoundAndTimelimit()
{
	//Time & current round
	
	g_bIsCurrentRoundIsBloodlustForAll = false;
	g_fTimelimitToGiveBloodlustForAll = 0.0;
	g_fTimelimitNoVote = 0.0;
	
	Bloodlust_Type flagsToCheck = BLOODLUST_ROUND | BLOODLUST_TIME;
	
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( g_bloodlustTypeForThisRound[ i ] & flagsToCheck ) //disconnected client = NONE ; REMOVED flag shouldn't occur; auto 
		{
			g_bloodlustTypeForThisRound[ i ] &= ~flagsToCheck; //remove flagsToCheck
			
			if ( g_bloodlustTypeForThisRound[ i ] == BLOODLUST_NONE ) //we don't have bloodlust anymore; remove it
			{
				g_bIsBloodlusted[ i ] = false;
				if ( g_hDegenTimer[ i ] != INVALID_HANDLE )
				{
					KillTimer( g_hDegenTimer[ i ] );
					g_hDegenTimer[ i ] = INVALID_HANDLE;
				}
			}
		}
	}
}
// === strings ===
void getTeamNameConditionalLowerCase(const int teamId, char[] szBuffer, const int size)
{
	//Team name
	GetTeamName( teamId, szBuffer, size );
	
	//Lower cases
	if ( strlen( szBuffer ) > 3 ) //4+ chars = lower
		for ( int i = 1; i < size; ++i )
			szBuffer[ i ] = CharToLower( szBuffer[ i ] );
}