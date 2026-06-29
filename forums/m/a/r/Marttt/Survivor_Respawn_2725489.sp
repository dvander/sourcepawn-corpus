#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
#include <topmenus>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

/* Definition Strings */
#define PLUGIN_VERSION 			"2.1"
#define TRANSLATION_FILENAME 	"SurvivorRespawn.phrases"

/* Definition Integers */
#define TEAM_SPECTATOR 	1
#define TEAM_SURVIVOR 	2

/* Booleans */
bool bRescuable[ MAXPLAYERS + 1 ] = false;
static bool bL4D2;

/* SDK Handles */
Handle hRoundRespawn;
Handle hGameConf;

/* ConVars */
ConVar hCvar_Enable;
ConVar hCvar_IncludeBots;
ConVar hCvar_RespawnHanging;
ConVar hCvar_RespawnIncapped;
ConVar hCvar_RespawnRespect;
ConVar hCvar_RespawnLimit;
ConVar hCvar_RespawnTimeout;
ConVar hCvar_RespawnHP;
ConVar hCvar_RespawnBuffHP;
ConVar hCvar_IncapDelay;
ConVar hCvar_HangingDelay;
ConVar hCvar_SaveStats;
ConVar hCvar_BotReplaced;

ConVar FirstWeapon;
ConVar SecondWeapon;
ConVar ThrownWeapon;
ConVar PrimeHealth;
ConVar SecondaryHealth;

/* Handler Menu */
TopMenu hTopMenu;
TopMenu hTopMenuHandle;

/* Timer Handles With Arrays */
Handle RespawnTimer[ MAXPLAYERS + 1 ];
Handle HangingTimer[ MAXPLAYERS + 1 ];
Handle IncapTimer[ MAXPLAYERS + 1 ];

int RespawnLimit[ MAXPLAYERS + 1 ] = 0;
int BufferHP = -1;

/* Arrays */
char sPlayerSave[45][] =
{
    "m_checkpointAwardCounts",
    "m_missionAwardCounts",
    "m_checkpointZombieKills",
    "m_missionZombieKills",
    "m_checkpointSurvivorDamage",
    "m_missionSurvivorDamage",
    "m_classSpawnCount",
    "m_checkpointMedkitsUsed",
    "m_checkpointPillsUsed",
    "m_missionMedkitsUsed",
    "m_checkpointMolotovsUsed",
    "m_missionMolotovsUsed",
    "m_checkpointPipebombsUsed",
    "m_missionPipebombsUsed",
    "m_missionPillsUsed",
    "m_checkpointDamageTaken",
    "m_missionDamageTaken",
    "m_checkpointReviveOtherCount",
    "m_missionReviveOtherCount",
    "m_checkpointFirstAidShared",
    "m_missionFirstAidShared",
    "m_checkpointIncaps",
    "m_missionIncaps",
    "m_checkpointDamageToTank",
    "m_checkpointDamageToWitch",
    "m_missionAccuracy",
    "m_checkpointHeadshots",
    "m_checkpointHeadshotAccuracy",
    "m_missionHeadshotAccuracy",
    "m_checkpointDeaths",
    "m_missionDeaths",
    "m_checkpointPZIncaps",
    "m_checkpointPZTankDamage",
    "m_checkpointPZHunterDamage",
    "m_checkpointPZSmokerDamage",
    "m_checkpointPZBoomerDamage",
    "m_checkpointPZKills",
    "m_checkpointPZPounces",
    "m_checkpointPZPushes",
    "m_checkpointPZTankPunches",
    "m_checkpointPZTankThrows",
    "m_checkpointPZHung",
    "m_checkpointPZPulled",
    "m_checkpointPZBombed",
    "m_checkpointPZVomited"
};

char sPlayerSave_L4D2[15][] =
{
    "m_checkpointBoomerBilesUsed",
    "m_missionBoomerBilesUsed",
    "m_checkpointAdrenalinesUsed",
    "m_missionAdrenalinesUsed",
    "m_checkpointDefibrillatorsUsed",
    "m_missionDefibrillatorsUsed",
    "m_checkpointMeleeKills",
    "m_missionMeleeKills",
    "m_checkpointPZJockeyDamage",
    "m_checkpointPZSpitterDamage",
    "m_checkpointPZChargerDamage",    
	"m_checkpointPZHighestDmgPounce",
    "m_checkpointPZLongestSmokerGrab",
    "m_checkpointPZLongestJockeyRide",
    "m_checkpointPZNumChargeVictims"
};

int iPlayerData[ MAXPLAYERS + 1 ][ sizeof( sPlayerSave ) ];
int iPlayerData_L4D2[ MAXPLAYERS + 1 ][ sizeof( sPlayerSave_L4D2 ) ];
float fPlayerData[ MAXPLAYERS + 1 ][ 2 ];
int Seconds[ MAXPLAYERS + 1 ];

/* Float Coordinates */
float vPos[3];

public Plugin myinfo = 
{
    name 		= "[L4D1 AND L4D2] Survivor Respawn",
    author 		= "Mortiegama And Ernecio (Satanael)",
    description = "When a Survivor dies, is hanging, or is incapped, will respawn after a period of time.",
    version 	= PLUGIN_VERSION,
    url 		= "https://steamcommunity.com/profiles/76561198404709570/"
}

/**
 * @note Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2( Handle myself, bool late, char[] error, int err_max )
{	
	EngineVersion engine = GetEngineVersion();
	if ( engine != Engine_Left4Dead && engine != Engine_Left4Dead2 )
	{
		strcopy( error, err_max, "This plugin \"Survivor Respawn\" only runs in the \"Left 4 Dead 1/2\" Games!" );
		return APLRes_SilentFailure;
	}
	
	bL4D2 = ( engine == Engine_Left4Dead2 );
	return APLRes_Success;
}

void Load_Translations()
{
	LoadTranslations( "common.phrases" ); // SourceMod Native (Add native SourceMod translations to the menu).
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, sPath, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME );
	if (FileExists( sPath ) )
		LoadTranslations( TRANSLATION_FILENAME);
	else
		SetFailState( "Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME );
}

public void OnPluginStart()
{
	Load_Translations();
	
	CreateConVar( 						   "l4d_survivorrespawn_version", 	PLUGIN_VERSION, "Survivor Respawning Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	hCvar_Enable 			= CreateConVar("l4d_survivorrespawn_enable", 			"1", 	"Enables Survivors to respawn automatically when incapped and/or killed (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_IncludeBots 		= CreateConVar("l4d_survivorrespawn_enablebot", 		"1", 	"Allows Bots to respawn automatically when incapped and/or killed (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_RespawnHanging 	= CreateConVar("l4d_survivorrespawn_hanging", 			"0", 	"Survivors will be killed when hanging and respawn afterwards (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_RespawnIncapped 	= CreateConVar("l4d_survivorrespawn_incapped", 			"1", 	"Survivors will be killed when incapped and respawn afterwards (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_RespawnRespect 	= CreateConVar("l4d_survivorrespawn_limitenable", 		"1", 	"Enables the respawn limit for Survivors (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_RespawnLimit 		= CreateConVar("l4d_survivorrespawn_deathlimit", 		"2", 	"Amount of times a Survivor can respawn before permanently dying (Def 2)", FCVAR_NOTIFY, true, 0.0, false, _);
	hCvar_RespawnTimeout 	= CreateConVar("l4d_survivorrespawn_respawntimeout", 	"10", 	"How many seconds till the Survivor respawns (Def 10)", FCVAR_NOTIFY, true, 0.0, false, _);
	hCvar_IncapDelay 		= CreateConVar("l4d_survivorrespawn_incapdelay", 		"25", 	"How many seconds till the Survivor is killed after being incapacitated (Def 25)", FCVAR_NOTIFY, true, 0.0, false, _);
	hCvar_HangingDelay 		= CreateConVar("l4d_survivorrespawn_hangingdelay", 		"25", 	"How many seconds till the Survivor is killed while hanging (Def 25)", FCVAR_NOTIFY, true, 0.0, false, _);
	hCvar_RespawnHP 		= CreateConVar("l4d_survivorrespawn_respawnhp", 		"70", 	"Amount of HP a Survivor will respawn with (Def 70)", FCVAR_NOTIFY, true, 0.0, false, _);
	hCvar_RespawnBuffHP 	= CreateConVar("l4d_survivorrespawn_respawnbuffhp", 	"30", 	"Amount of buffer HP a Survivor will respawn with (Def 30)", FCVAR_NOTIFY, true, 0.0, false, _);
	hCvar_SaveStats 		= CreateConVar("l4d_survivorrespawn_savestats", 		"1", 	"Save player statistics if is have died.",  FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_BotReplaced 		= CreateConVar("l4d_survivorrespawn_botreplaced", 		"1", 	"Respawn bots if is dead in case of using Take Over.",  FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	if ( bL4D2 ) {
		FirstWeapon 		= CreateConVar("l4d_survivorrespawn_firstweapon", 		"1", 	"Which is first slot weapon will be given to the Survivor (1 - Autoshotgun, 2 - M16, 3 - Hunting Rifle, 4 - AK47 Assault Rifle, 5 - SCAR-L Desert Rifle,\n6 - M60 Assault Rifle, 7 - Military Sniper Rifle, 8 - SPAS Shotgun, 9 - Chrome Shotgun, 10 - None)", FCVAR_NOTIFY, true, 1.0, true, 10.0);
		SecondWeapon 		= CreateConVar("l4d_survivorrespawn_secondweapon", 		"1", 	"Which is second slot weapon will be given to the Survivor (1 - Dual Pistol, 2 - Bat, 3 - Magnum, 4 - None)", FCVAR_NOTIFY, true, 1.0, true, 4.0);
		ThrownWeapon 		= CreateConVar("l4d_survivorrespawn_thrownweapon", 		"1", 	"Which is thrown weapon will be given to the Survivor (1 - Moltov, 2 - Pipe Bomb, 3 - Bile Jar, 4 - None)", FCVAR_NOTIFY, true, 1.0, true, 4.0);
		PrimeHealth 		= CreateConVar("l4d_survivorrespawn_primehealth", 		"1", 	"Which prime health unit will be given to the Survivor (1 - Medkit, 2 - Defib, 3 - None)", FCVAR_NOTIFY, true, 1.0, true, 3.0);
		SecondaryHealth 	= CreateConVar("l4d_survivorrespawn_secondaryhealth", 	"1", 	"Which secondary health unit will be given to the Survivor (1 - Pills, 2 - Adrenaline, 3 - None)", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	} else {
		FirstWeapon 		= CreateConVar("l4d_survivorrespawn_firstweapon", 		"1", 	"Which is first slot weapon will be given to the Survivor (1 - Autoshotgun, 2 - M16, 3 - Hunting Rifle, 4 - None)", FCVAR_NOTIFY, true, 1.0, true, 4.0);
		SecondWeapon 		= CreateConVar("l4d_survivorrespawn_secondweapon", 		"1", 	"Which is second slot weapon will be given to the Survivor (1 - Dual Pistol, 4 - None)", FCVAR_NOTIFY, true, 1.0, true, 4.0);
		ThrownWeapon 		= CreateConVar("l4d_survivorrespawn_thrownweapon", 		"1", 	"Which is thrown weapon will be given to the Survivor (1 - Moltov, 2 - Pipe Bomb, 4 - None)", FCVAR_NOTIFY, true, 1.0, true, 4.0);
		PrimeHealth 		= CreateConVar("l4d_survivorrespawn_primehealth", 		"1", 	"Which prime health unit will be given to the Survivor (1 - Medkit, 3 - None)", FCVAR_NOTIFY, true, 1.0, true, 3.0);
		SecondaryHealth 	= CreateConVar("l4d_survivorrespawn_secondaryhealth", 	"1", 	"Which secondary health unit will be given to the Survivor (1 - Pills, 3 - None)", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	}
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post );
//	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_bot_replace", Event_BotReplace, EventHookMode_Post );
//	HookEvent("bot_player_replace", Event_PlayerReplace );
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
//	HookEvent("player_afk", Event_PlayerAFK);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	if ( bL4D2 )
		HookEvent("dead_survivor_visible", Event_DeadSurvivorVisible);
	
	RegAdminCmd( "sm_respawn", CMD_Respawn, ADMFLAG_BAN, "Respawn Target/s At Your Crosshair." );
	RegAdminCmd( "sm_respawnmenu", CMD_DisplayMenu, ADMFLAG_BAN, "Create A Menu Of Clients List And Respawn Targets At Your Crosshair." );
	
	TopMenu hTop_Menu;
	if ( LibraryExists( "adminmenu" ) && ( ( hTop_Menu = GetAdminTopMenu() ) != null ) )
		OnAdminMenuReady( hTop_Menu );
	
	hGameConf = LoadGameConfigFile( "SurvivorRespawn" );
	
	AutoExecConfig( true, "SurvivorRespawn" );
	
	BufferHP = FindSendPropInfo( "CTerrorPlayer", "m_healthBuffer" );
	
	StartPrepSDKCall( SDKCall_Player );
	PrepSDKCall_SetFromConf( hGameConf, SDKConf_Signature, "RoundRespawn" );
	
	hRoundRespawn = EndPrepSDKCall();
	if ( hRoundRespawn == null ) 
		SetFailState( "L4D_SM_Respawn: RoundRespawn Signature broken" );
}

public void Event_RoundStart( Event hEvent, const char[] sName, bool bDontBroadcast )
{
    for ( int client = 1; client <= MaxClients; client ++ )
	{
		RespawnLimit[client] = 0;
		
		if ( RespawnTimer[client] != null )
		{
			KillTimer( RespawnTimer[client] );
			RespawnTimer[client] = null;
		}
	}
}

public void Event_RoundEnd( Event hEvent, const char[] sName, bool bDontBroadcast )
{
    for ( int client = 1; client <= MaxClients; client ++ )
	{
		RespawnLimit[client] = 0;
		bRescuable[client] = false;
		
		if ( RespawnTimer[client] != null )
		{
			KillTimer( RespawnTimer[client] );
			RespawnTimer[client] = null;
		}
	}
}

public void Event_PlayerLedgeGrab( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );

	if ( hCvar_Enable.BoolValue && hCvar_RespawnHanging.BoolValue && IsValidClient( client ) )
	{
		HangingTimer[client] = CreateTimer( hCvar_HangingDelay.FloatValue, Timer_HangingRespawn, client ); 
		bRescuable[client] = true;
	}
}

public Action Timer_HangingRespawn( Handle hTimer, any client)
{
	int Limit = hCvar_RespawnLimit.IntValue;

	if (IsValidClient(client) && bRescuable[client] && IsPlayerHanging(client))
	{
		if ( RespawnLimit[client] < Limit )
		{
			ForcePlayerSuicide(client);
			bRescuable[client] = false;
		}
		else if ( RespawnLimit[client] >= Limit )
		{
			PrintHintText( client, "%t", "Respawn Limit" );
			bRescuable[client] = false;
		}
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
		bRescuable[client] = false;
	
	if (HangingTimer[client] != null)
	{
		KillTimer(HangingTimer[client]);
		HangingTimer[client] = null;
	}
	
	return Plugin_Stop;
}

public void Event_PlayerIncapped( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );

	if (hCvar_Enable.BoolValue && hCvar_RespawnIncapped.BoolValue && IsValidClient(client))
	{
		IncapTimer[client] = CreateTimer( hCvar_IncapDelay.FloatValue, Timer_IncapRespawn, client ); 
		bRescuable[client] = true;
	}
}

public Action Timer_IncapRespawn( Handle hTimer, any client)
{
	int Limit = hCvar_RespawnLimit.IntValue;
	
	if (IsValidClient(client) && bRescuable[client] && IsPlayerIncapped(client))
	{
		if ( RespawnLimit[client] < Limit )
			ForcePlayerSuicide(client);
		else if ( RespawnLimit[client] >= Limit )
			PrintHintText( client, "%t", "Respawn Limit" );
	}

	if (IsValidClient(client) && IsPlayerAlive(client))
		bRescuable[client] = false;
	
	if (IncapTimer[client] != null)
	{
		KillTimer(IncapTimer[client]);
		IncapTimer[client] = null;
	}
	
	return Plugin_Stop;
}

public void Event_PlayerDeath( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	int Limit = hCvar_RespawnLimit.IntValue;
	int Time = hCvar_RespawnTimeout.IntValue;

	if ( hCvar_Enable.BoolValue && !hCvar_RespawnRespect.BoolValue && IsValidClient( client ) )
	{
		RespawnTimer[client] = CreateTimer( hCvar_RespawnTimeout.FloatValue, Timer_Respawn, client ); 
		
		Seconds[client] = Time;
		CreateTimer( 1.0, TimerCount, GetClientUserId( client ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		
		if ( hCvar_SaveStats.BoolValue )
			SaveStats( client );
		
		bRescuable[client] = false;
	}

	if ( hCvar_Enable.BoolValue && hCvar_RespawnRespect.BoolValue && IsValidClient( client ) )
	{
		if ( RespawnLimit[client] < Limit )
		{
//			RespawnLimit[client] += 1;
			RespawnTimer[client] = CreateTimer( hCvar_RespawnTimeout.FloatValue, Timer_Respawn, client); 
			
			CreateTimer( 1.0, TimerCount, GetClientUserId( client ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE ); 
			
			if ( hCvar_SaveStats.BoolValue )
				SaveStats( client );
			
			Seconds[client] = Time;
			bRescuable[client] = false;
		}
		else if ( RespawnLimit[client] >= Limit )
		{
			PrintHintText( client, "%t", "Respawn Limit" );
			bRescuable[client] = false;
		}
	}
}

public void Event_BotReplace( Event hEvent, const char[] sName, bool bDontBroadcast )
{
//	int client = GetClientOfUserId( hEvent.GetInt( "player" ) );
	int bot = GetClientOfUserId( hEvent.GetInt( "bot" ) );
	int Limit = hCvar_RespawnLimit.IntValue;
	
	if ( IsPlayerAlive( bot ) || !IsFakeClient( bot ) || !hCvar_BotReplaced.BoolValue ) return;
		
	if ( hCvar_Enable.BoolValue && !hCvar_RespawnRespect.BoolValue && IsValidClient( bot ) )
	{
		RespawnTimer[bot] = CreateTimer( hCvar_RespawnTimeout.FloatValue, Timer_Respawn, bot );
		bRescuable[bot] = false;
		
//		if ( hCvar_SaveStats.BoolValue )
//			SaveStats( bot );
	}

	if ( hCvar_Enable.BoolValue && hCvar_RespawnRespect.BoolValue && IsValidClient( bot ) )
	{
		if ( RespawnLimit[bot] < Limit )
		{
//			RespawnLimit[bot] += 1;
			RespawnTimer[bot] = CreateTimer( hCvar_RespawnTimeout.FloatValue, Timer_Respawn, bot ); 
			bRescuable[bot] = false;
			
//			if ( hCvar_SaveStats.BoolValue )
//				SaveStats( bot );
		}
		else if ( RespawnLimit[bot] >= Limit )
			bRescuable[bot] = false;
	}
}
/*
public void Event_PlayerReplace( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "player" ) );
	int bot = GetClientOfUserId( hEvent.GetInt( "bot" ) );
	
	if ( RespawnTimer[client] != null )
	{
		KillTimer( RespawnTimer[client] );
		RespawnTimer[client] = null;
	}
	
	PrintToChatAll( "\x03%N \x01has replaced \x04%N", client, bot ); // Test.
}
*/
public void Event_PlayerSpawn( Event hEvent, const char[] sName, bool bDontBroadcast )
{	
	int UserID = hEvent.GetInt( "userid" );
	int client = GetClientOfUserId(UserID);
	
	if( IsValidClient( client ) )
		CreateTimer( 0.5, TimerDelay, UserID, TIMER_FLAG_NO_MAPCHANGE );
}

public Action TimerDelay( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( client == 0 || !IsPlayerAlive( client ) || !IsClientInGame( client ) ) return;
	
	if ( RespawnTimer[client] != null )
	{
		KillTimer( RespawnTimer[client] );
		RespawnTimer[client] = null;
	}
}
/*
public void Event_PlayerAFK( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "player" ) );
	
	PrintToChatAll("\x03%N \x01Is Idle", client ); // Test.
}
*/
public void Event_DeadSurvivorVisible( Event hEvent, const char[] sName, bool bDontBroadcast )
{	
	int DeadBody = hEvent.GetInt( "subject" );
	int DeadPlayer = GetClientOfUserId( hEvent.GetInt( "deadplayer" ) );
	
	if ( !DeadPlayer || !DeadBody ) 
		return;
	
	if ( IsFakeClient( DeadPlayer ) ) 				return;
	else if ( GetClientTeam( DeadPlayer ) != 2 ) 	return;
	else if ( IsPlayerAlive( DeadPlayer ) ) 		AcceptEntityInput( DeadBody, "Kill" );
	
//	PrintToChatAll( "\x03%N\x01's body has been removed", DeadPlayer ); // Test.
//	PrintToChatAll( "\x03%i \x01Client Index", DeadBody ); // Test.
}

public void Event_ReviveSuccess( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "victim" ) );
	bRescuable[client] = false;
}

/******************************************************************************************************/

public Action CMD_Respawn( int client, int args )
{
	if ( args < 1 )
	{
		ReplyToCommand( client, "\x04[\x01SM\x04] %t", "CMD Respawn" );
		return Plugin_Handled;
	}
	
	char sArgs[MAX_TARGET_LENGTH];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargetList[MAXPLAYERS];
	int  iTargetCount;
	bool bTN_IS_ML;
	
	GetCmdArg( 1, sArgs, sizeof( sArgs ) );
	
	if ( ( iTargetCount = ProcessTargetString( sArgs, client, iTargetList, MAXPLAYERS, 0, sTargetName, sizeof( sTargetName ), bTN_IS_ML ) ) <= 0 )
	{
		ReplyToTargetError( client, iTargetCount ); // Create an error report if there are two targets with the same name.
		return Plugin_Handled;
	}
	
	for ( int i = 0; i < iTargetCount; i ++ )
		if ( IsValidClient( iTargetList[i] ) && !IsPlayerAlive( iTargetList[i] ) )
			RespawnTarget_Crosshair( client, iTargetList[i] );
		else if ( IsValidClient( iTargetList[i] ) )
			PrintToChat( client, "%t", "No Need To Respawn", iTargetList[i] );
	
	return Plugin_Handled;
}

public Action CMD_DisplayMenu( int client, int args )
{
	if ( client == 0 )
	{
		ReplyToCommand( client, "[SM] %t", "Command is in-game only" ); // SourceMod Native.
		return Plugin_Handled;
	}
	
	DisplayRespawnMenu( client );
	return Plugin_Handled;
}
/***********************************************************************************************************/
public void OnAdminMenuReady( Handle hTop_Menu )
{
	if ( hTop_Menu == hTopMenuHandle )
		return;
	
	hTopMenuHandle = view_as<TopMenu>( hTop_Menu );
	TopMenuObject Menu_Category_Respawn = hTopMenuHandle.AddCategory( "Respawn Targets", Category_Handler );
	
	if ( Menu_Category_Respawn != INVALID_TOPMENUOBJECT )
		hTopMenuHandle.AddItem( "sm_respawntest", AdminMenu_Respawn, Menu_Category_Respawn, "sm_respawntest", ADMFLAG_BAN );
}

//Admin Category Names In Main Menu.
public int Category_Handler( TopMenu hTop_Menu, TopMenuAction hAction, TopMenuObject topobj_id, int param, char[] buffer, int maxlength )
{
	if ( hAction == TopMenuAction_DisplayTitle )
		Format( buffer, maxlength, "%T", "Select Options", param );
	
	else if( hAction == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "%T", "Main Menu Name", param );
}

public void AdminMenu_Respawn( TopMenu hTop_Menu, TopMenuAction hAction, TopMenuObject object_id, int param, char[] buffer, int maxlength )
{
	if ( hAction == TopMenuAction_DisplayOption )
		Format( buffer, maxlength, "%T", "Players List", param );
	
	else if ( hAction == TopMenuAction_SelectOption )
		DisplayRespawnMenu( param );
}
/***********************************************************************************************************/
void DisplayRespawnMenu( int client )
{
	Menu hMenu = new Menu( MenuHandler_Respawn );
	
	char sTitle[100];
	Format( sTitle, sizeof( sTitle ), "%T", "Respawn Menu", client );
	hMenu.SetTitle( sTitle );
//	hMenu.ExitBackButton = true;
	
//	AddTargetsToMenu( hMenu, client, true, true );
	Custom_AddTargetsToMenu( hMenu );
	
	hMenu.Display( client, MENU_TIME_FOREVER );
}

public int MenuHandler_Respawn( Menu hMenu, MenuAction hAction, int Param1, int Param2 )
{
	if ( hAction == MenuAction_End )
		delete hMenu;
	
	else if ( hAction == MenuAction_Cancel )
	{
		if ( Param2 == MenuCancel_ExitBack && hTopMenu )
			hTopMenu.Display( Param1, TopMenuPosition_LastCategory );
	}
	else if ( hAction == MenuAction_Select )
	{
		char sInfo[32];
		int UserID, Target;
		
		hMenu.GetItem( Param2, sInfo, sizeof( sInfo ) );
		UserID = StringToInt( sInfo );
		
		if ( ( Target = GetClientOfUserId( UserID ) ) == 0 )
			PrintToChat( Param1, "[SM] %t", "Player no longer available" ); // SourceMod Native.
		
		else if ( !CanUserTarget( Param1, Target ) )
			PrintToChat( Param1, "[SM] %t", "Unable to target" ); // SourceMod Native.
		
		else
		{
			char sName[MAX_NAME_LENGTH];
			GetClientName( Target, sName, sizeof( sName ) );
			
			if ( !IsPlayerAlive( Target ) )
				RespawnTarget_Crosshair( Param1, Target );
			else 
				PrintToChat( Param1, "%t", "No Need To Respawn Menu", sName );
			
//			ShowActivity2( Param1, "[SM] ", "Respawned Target '%s'", sName );
		}
		
		if ( IsClientInGame( Param1 ) && !IsClientInKickQueue( Param1 ) )  // Re-draw the menu if they're still valid
			DisplayRespawnMenu( Param1 );
	}
}

/******************************************************************************************************/

public Action Timer_Respawn( Handle hTimer, any client )
{
	if ( IsValidClient( client ) && !IsPlayerAlive( client ) )
		RespawnTarget( client );
	else if ( IsValidClient( client ) )
		PrintToChatAll( "%t", "Not Needed To Respawn", client );
	
	if ( RespawnTimer[client] != null )
	{
		KillTimer( RespawnTimer[client] );
		RespawnTimer[client] = null;
	}
	
	return Plugin_Stop;
}
/***********************************************************/
public Action TimerCount( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( client == 0 || Seconds[client]  <= 0 || IsPlayerAlive( client ) || !IsClientInGame( client ) || !IsClientConnected( client ) || IsFakeClient( client ) || IsClientIdle( client ) ) 
		return Plugin_Stop;
	
	Seconds[client] --;
	
	PrintHintText( client, "%t", "Seconds To Respawn", Seconds[client] );

	return Plugin_Continue;
}

void RespawnTarget_Crosshair( int client, int target )
{
	bool bCanTeleport = bSetTeleportEndPoint( client );
	SDKCall( hRoundRespawn, target );
	
	SetHealth( target );
	GiveItems( target );
	RespawnLimit[target] += 1;
	
	char sPlayerName[64];
	GetClientName( target, sPlayerName, sizeof( sPlayerName ) );
	
	if ( hCvar_SaveStats.BoolValue )
		CreateTimer( 1.0, Timer_LoadStatDelayed, GetClientUserId( target ), TIMER_FLAG_NO_MAPCHANGE );
	
	PrintToChatAll( "%t", "Respawned", sPlayerName );
	
	if ( bCanTeleport )
		vPerformTeleport( client, target, vPos );
	
	if ( RespawnTimer[client] != null )
	{
		KillTimer( RespawnTimer[client] );
		RespawnTimer[client] = null;
	}
}

void RespawnTarget( int client )
{
	SDKCall( hRoundRespawn, client );
	
	SetHealth( client );
	GiveItems( client);
	Teleport( client );
	RespawnLimit[client] += 1;
	
	char sPlayerName[64];
	GetClientName( client, sPlayerName, sizeof( sPlayerName ) );
	
	if ( hCvar_SaveStats.BoolValue )
		CreateTimer( 1.0, Timer_LoadStatDelayed, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
	
	PrintToChatAll( "%t", "Respawned", sPlayerName );
}

public Action Timer_LoadStatDelayed( Handle hTimer, int UserId )
{
	int client = GetClientOfUserId( UserId );
	if( client > 0 && IsClientInGame( client ) )
		if ( IsPlayerAlive( client ) ) 			// Not died in 1.0 sec after spawn?
			LoadStats(client);
}
/***********************************************************/
void SetHealth( int client )
{
	float Buff = GetEntDataFloat( client, BufferHP );
	int BonusHP = hCvar_RespawnHP.IntValue;
	int BuffHP = hCvar_RespawnBuffHP.IntValue;

	SetEntProp( client, Prop_Send, "m_iHealth", BonusHP, 1 );
	SetEntDataFloat( client, BufferHP, Buff + BuffHP, true );
}

void GiveItems( int client )
{
	int Flags = GetCommandFlags( "give" );
	SetCommandFlags( "give", Flags & ~FCVAR_CHEAT );
	
	switch ( FirstWeapon.IntValue )
	{
		case 1: FakeClientCommand( client, "give autoshotgun" );
		case 2: FakeClientCommand( client, "give rifle" );
		case 3: FakeClientCommand( client, "give hunting_rifle" );
		case 4: FakeClientCommand( client, "give rifle_ak47" );
		case 5: FakeClientCommand( client, "give rifle_desert" );
		case 6: FakeClientCommand( client, "give rifle_m60" );
		case 7: FakeClientCommand( client, "give sniper_military" );
		case 8: FakeClientCommand( client, "give shotgun_spas" );
		case 9: FakeClientCommand( client, "give shotgun_chrome" );
	}
	
	switch ( SecondWeapon.IntValue )
	{
		case 1:
		{
				FakeClientCommand( client, "give pistol" );
				FakeClientCommand( client, "give pistol" );
		}
		case 2: FakeClientCommand( client, "give baseball_bat" );
		case 3: FakeClientCommand( client, "give pistol_magnum" );
	}
	switch ( ThrownWeapon.IntValue )
	{
		case 1: FakeClientCommand( client, "give molotov" );
		case 2: FakeClientCommand( client, "give pipe_bomb" );
		case 3: FakeClientCommand( client, "give vomitjar" );
	}
	switch ( PrimeHealth.IntValue )
	{
		case 1: FakeClientCommand( client, "give first_aid_kit" );
		case 2: FakeClientCommand( client, "give defibrillator" );
	}
	switch ( SecondaryHealth.IntValue )
	{
		case 1: FakeClientCommand( client, "give pain_pills" );
		case 2: FakeClientCommand( client, "give adrenaline" );
	}
	
	SetCommandFlags( "give", Flags|FCVAR_CHEAT );
}

void Teleport( int client ) // Get the position coordinates of any active living player
{
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame( i ) && GetClientTeam( i ) == 2 && IsPlayerAlive( i ) && i != client )
		{
			float Coordinates[3];
			GetClientAbsOrigin( i, Coordinates );
			TeleportEntity( client, Coordinates, NULL_VECTOR, NULL_VECTOR );
			break;
		}
	}
}
/******************************************************************************************************/

bool bSetTeleportEndPoint( int client )
{
	float vAngles[3];
	float vOrigin[3];
	
	GetClientEyePosition( client,vOrigin );
	GetClientEyeAngles( client, vAngles );
	Handle hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_SHOT, RayType_Infinite, bTraceEntityFilterPlayer );
	
	if ( TR_DidHit( hTrace ) )
	{
		float vBuffer[3];
		float vStart[3];
		float vDistance = -35.0;
		
		TR_GetEndPosition( vStart, hTrace );
		GetVectorDistance( vOrigin, vStart, false );
		GetAngleVectors( vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR );
		
		vPos[0] = vStart[0] + ( vBuffer[0] * vDistance );
		vPos[1] = vStart[1] + ( vBuffer[1] * vDistance );
		vPos[2] = vStart[2] + ( vBuffer[2] * vDistance );
	}
	else
	{
		PrintToChat( client, "\x04[\x01SM\x04]\x01 %t", "Couldn't Teleport" );
		
		delete hTrace;
		return false;
	}
	
	delete hTrace;
	return true;
}

public bool bTraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > MaxClients || !entity );
}

void vPerformTeleport( int client, int target, float vCoordinates[3] )
{
	vCoordinates[2] += 40.0;
	TeleportEntity( target, vCoordinates, NULL_VECTOR, NULL_VECTOR );
	LogAction( client, target, "\"%L\" Teleported \"%L\" After Respawning Him/Her" , client, target );
//	PrintToChatAll( "\x03\"%L\" \x01Teleported \x04\"%L\" \x01After Respawning Him/Her" , client, target ); // Test.
}
/******************************************************************************************************/

/**************************************/
/* 				STOCKs 				  */
/**************************************/

stock bool IsValidClient( int client )
{
	if ( client == 0 || !IsClientInGame( client ) || GetClientTeam( client ) != 2 || ( IsFakeClient( client ) && !hCvar_IncludeBots.BoolValue ) )
		return false;
	
	return true;
}

stock bool IsPlayerIncapped( int client )
{
	if ( GetEntProp( client, Prop_Send, "m_isIncapacitated", 1 ) ) 
		return true;
		
	return false;
}

stock bool IsPlayerHanging( int client )
{
	if ( GetEntProp( client, Prop_Send, "m_isHangingFromLedge", 1 ) ) 
		return true;
		
	return false;
}

stock void SaveStats( int client )
{
	fPlayerData[client][0] = GetEntPropFloat( client, Prop_Send, "m_maxDeadDuration" );
	fPlayerData[client][1] = GetEntPropFloat( client, Prop_Send, "m_totalDeadDuration" );
	
	for( int i = 0; i < sizeof( iPlayerData[] ); i++ )
		iPlayerData[client][i] = GetEntProp( client, Prop_Send, sPlayerSave[i] );
	
	if ( bL4D2 )
		for( int i = 0; i < sizeof( iPlayerData_L4D2[] ); i++ )
			iPlayerData_L4D2[client][i] = GetEntProp( client, Prop_Send, sPlayerSave_L4D2[i] );
}

stock void LoadStats( int client )
{
	SetEntPropFloat( client, Prop_Send, "m_maxDeadDuration", fPlayerData[client][0] );
	SetEntPropFloat( client, Prop_Send, "m_totalDeadDuration", fPlayerData[client][1] );
 
	for( int i = 0; i < sizeof(iPlayerData[] ); i++ )
		SetEntProp( client, Prop_Send, sPlayerSave[i], iPlayerData[client][i] );
	
	if ( bL4D2 )
		for( int i = 0; i < sizeof( iPlayerData_L4D2[] ); i++ )
			SetEntProp( client, Prop_Send, sPlayerSave_L4D2[i], iPlayerData_L4D2[client][i] );
}

/**
 * @note Adds targets to an admin menu.
 *
 * Each client is displayed as: name (userid)
 * Each item contains the userid as a string for its info.
 *
 * @param menu 			Menu Handle.
 * @return 				Returns the number of players depending on whether it is valid or not.
 */
stock int Custom_AddTargetsToMenu( Menu hMenu )
{
	char sUser_ID[12];
	char sName[MAX_NAME_LENGTH];
	char sDisplay[MAX_NAME_LENGTH+12];
	int  Num_Clients;
	
	for ( int i = 1; i <= MaxClients; i ++ )
	{
		if ( !IsValidClient( i ) )
			continue;
		
//		if ( IsPlayerAlive( i ) )
//			continue;
		
		IntToString( GetClientUserId( i ), sUser_ID, sizeof( sUser_ID ) );
		GetClientName( i, sName, sizeof( sName ) );
		Format( sDisplay, sizeof( sDisplay ), "%s (%s)", sName, sUser_ID );
		hMenu.AddItem( sUser_ID, sDisplay );
		Num_Clients ++;
	}
	
	return Num_Clients;
}

stock bool IsClientIdle( int client )
{
	if ( GetClientTeam( client ) != TEAM_SPECTATOR )
		return false;
	
	for ( int i = 1; i <= MaxClients; i ++ )
		if ( IsClientInGame( i ) )
			if ( ( GetClientTeam( i ) == TEAM_SURVIVOR ) && IsAlive( i ) )
				if ( IsFakeClient( i ) && HasEntProp(i, Prop_Send, "m_humanSpectatorUserID") )
					if ( GetClientOfUserId( GetEntProp( i, Prop_Send, "m_humanSpectatorUserID" ) ) == client )
						return true;
					
	return false;
}

bool IsAlive( int client )
{
	if ( !GetEntProp( client, Prop_Send, "m_lifeState" ) )
		return true;
	
	return false;
}