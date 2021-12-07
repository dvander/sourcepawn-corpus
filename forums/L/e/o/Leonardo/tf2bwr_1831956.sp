#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>
#include <tf2items>
#define REQUIRE_PLUGIN
#include <tf2itemsinfo>
#undef REQUIRE_PLUGIN
//#tryinclude <updater>
//#tryinclude <tf2spawnitem>

#pragma semicolon					1

//#define HIDDEN_CODE

#define PLUGIN_VERSION				"1.2.6.7-20130609"
#define PLUGIN_TAG					"[TF2BWR]"
#define PLUGIN_UPDATE_URL			"http://files.xpenia.org/sourcemod/tf2bwr/updatelist.txt"

#define ERROR_NONE					0		// PrintToServer only
#define ERROR_LOG					(1<<0)	// use LogToFile
#define ERROR_BREAKF				(1<<1)	// use ThrowError
#define ERROR_BREAKN				(1<<2)	// use ThrowNativeError
#define ERROR_BREAKP				(1<<3)	// use SetFailState
#define ERROR_NOPRINT				(1<<4)	// don't use PrintToServer

#define GIANTSCOUT_SND_LOOP			"mvm/giant_scout/giant_scout_loop.wav"
#define GIANTSOLDIER_SND_LOOP		"mvm/giant_soldier/giant_soldier_loop.wav"
#define GIANTPYRO_SND_LOOP			"mvm/giant_pyro/giant_pyro_loop.wav"
#define GIANTDEMOMAN_SND_LOOP		"mvm/giant_demoman/giant_demoman_loop.wav"
#define GIANTHEAVY_SND_LOOP			")mvm/giant_heavy/giant_heavy_loop.wav"
#define SENTRYBUSTER_SND_INTRO		")mvm/sentrybuster/mvm_sentrybuster_intro.wav"
#define SENTRYBUSTER_SND_LOOP		"mvm/sentrybuster/mvm_sentrybuster_loop.wav"
#define SENTRYBUSTER_SND_SPIN		")mvm/sentrybuster/mvm_sentrybuster_spin.wav"
#define SENTRYBUSTER_SND_EXPLODE	")mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define GIANTROBOT_SND_DEPLOYING	"mvm/mvm_deploy_giant.wav"
#define SMALLROBOT_SND_DEPLOYING	"mvm/mvm_deploy_small.wav"

#define SENTRYBUSTER_DISTANCE		400.0
#define SENTRYBUSTER_DAMAGE			99999
#if defined HIDDEN_CODE
#define SENTRYBUSTER_CLASSVARIANT	7
#else
#define SENTRYBUSTER_CLASSVARIANT	5
#endif

#define TF_MVM_MAX_PLAYERS			10
#define TF_MVM_MAX_DEFENDERS		6

#define SPAWNTYPE_NORMAL			0
#define SPAWNTYPE_LOWER				1
#define SPAWNTYPE_GIANT				2
#define SPAWNTYPE_SNIPER			3
#define SPAWNTYPE_SPY				4
#define SPAWNTYPE_MAX				5

#if !defined _tf2itemsinfo_included
new TF2ItemSlot = 8;
#endif

enum
{
	Spawn_Normal,
	Spawn_Lower,
	Spawn_Sniper,
	Spawn_Spy,
	Spawn_Giant
};
enum
{
	BotSkill_Easy,
	BotSkill_Normal,
	BotSkill_Hard,
	BotSkill_Expert
};

enum RobotMode
{
	Robot_Stock,
	Robot_Normal,
	Robot_BigNormal,
	Robot_Giant,
	Robot_SentryBuster
};
enum Effects
{
	Effect_None,
	Effect_AlwaysCrits,
	Effect_FullCharge,
	Effect_Invisible,
	Effect_AlwaysInvisible
};
new TFClassType:iRobotClass[MAXPLAYERS];
new RobotMode:iRobotMode[MAXPLAYERS];
new Effects:iEffect[MAXPLAYERS];
new iRobotVariant[MAXPLAYERS];
new iSelectedVariant[MAXPLAYERS];
new bool:bInRespawn[MAXPLAYERS];
new bool:bFreezed[MAXPLAYERS];
new Float:flNextChangeTeam[MAXPLAYERS];
new Handle:hTimer_SentryBuster_Beep[MAXPLAYERS+1];
new bool:bSkipSpawnEventMsg[MAXPLAYERS+1];
new bool:bSkipInvAppEvent[MAXPLAYERS+1];
new bool:bStripItems[MAXPLAYERS+1];

new iDeployingBomb;
new iDeployingAnim[][2] = {{120,2},{49,49},{163,149},{100,100},{82,82},{89,89},{96,93}};
new iFilterEnt[2];
new iLaserModel = -1;
new Float:flLastSentryBuster;
new Float:flLastAnnounce;

#if defined _tf2spawnitem_included
new bool:bUseTF2SI = false;
#endif

new Handle:hSDKEquipWearable = INVALID_HANDLE;
new Handle:hSDKRemoveWearable = INVALID_HANDLE;

new Handle:sm_tf2bwr_version;
new Handle:sm_tf2bwr_logs;
new Handle:sm_tf2bwr_flag;
new Handle:sm_tf2bwr_freeze;
new Handle:sm_tf2bwr_respawn_red;
new Handle:sm_tf2bwr_respawn_blue;
new Handle:sm_tf2bwr_randomizer;
new Handle:sm_tf2bwr_autojoin;
#if defined _updater_included
new Handle:sm_tf2bwr_autoupdate;
#endif
new Handle:sm_tf2bwr_max_defenders;
new Handle:sm_tf2bwr_min_defenders;
new Handle:sm_tf2bwr_min_defenders4giants;
new Handle:sm_tf2bwr_restrict_ready;
new Handle:sm_tf2bwr_notifications;
new Handle:sm_tf2bwr_myloadouts;
new Handle:sm_tf2bwr_sentrybuster_debug;
new Handle:sm_tf2bwr_engineers;
new bool:bUseLogs;
new bool:bFlagPickup;
new bool:bSpawnFreeze;
new iRespawnTimeRED;
new iRespawnTimeBLU;
new bool:bRandomizer;
new bool:bAutoJoin;
#if defined _updater_included
new bool:bAutoUpdate = true;
#endif
new iMaxDefenders;
new iMinDefenders;
new iMinDefenders4Giants;
new bool:bRestrictReady;
new bool:bNotifications;
new bool:bMyLoadouts;
new bool:bSentryBusterDebug;
new nMaxEngineers;

public Plugin:myinfo = 
{
	name = "TF2 Be With Robots",
	author = "Leonardo",
	description = "Play both as RED and BLU team.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
}

public OnPluginStart()
{
	sm_tf2bwr_version = CreateConVar( "sm_tf2bwr_version", PLUGIN_VERSION, "TF2 Be With Robots", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_tf2bwr_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2bwr_version, OnConVarChanged_PluginVersion );
	
	decl String:strGameDir[8];
	GetGameFolderName( strGameDir, sizeof(strGameDir) );
	if( !StrEqual( strGameDir, "tf", false ) /*&& !StrEqual( strGameDir, "tf_beta", false )*/ )
		Error( ERROR_BREAKP|ERROR_LOG, _, "THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!" );
	
	sm_tf2bwr_logs = CreateConVar( "sm_tf2bwr_logs", "1", "", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_logs, OnConVarChanged );
	
	sm_tf2bwr_flag = CreateConVar( "sm_tf2bwr_flag", "1", "Allow flag pick up by humans.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_flag, OnConVarChanged );
	
	sm_tf2bwr_freeze = CreateConVar( "sm_tf2bwr_freeze", "1", "Disable movement for robohumans between rounds.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_freeze, OnConVarChanged );
	
	sm_tf2bwr_respawn_red = CreateConVar( "sm_tf2bwr_respawn_red", "20", "Respawn fix for RED team. Set -1 to disable it.", FCVAR_PLUGIN, true, -1.0 );
	HookConVarChange( sm_tf2bwr_respawn_red, OnConVarChanged );
	
	sm_tf2bwr_respawn_blue = CreateConVar( "sm_tf2bwr_respawn_blue", "7", "Respawn fix for BLU team. Set -1 to disable it.", FCVAR_PLUGIN, true, -1.0 );
	HookConVarChange( sm_tf2bwr_respawn_blue, OnConVarChanged );
	
	sm_tf2bwr_randomizer = CreateConVar( "sm_tf2bwr_randomizer", "1", "Picking random class variants.", FCVAR_PLUGIN|FCVAR_NOTIFY );
	HookConVarChange( sm_tf2bwr_randomizer, OnConVarChanged );
	
	sm_tf2bwr_autojoin = CreateConVar( "sm_tf2bwr_autojoin", "1", "Handle autojoin command, trow player in RED or BLU team.", FCVAR_PLUGIN );
	HookConVarChange( sm_tf2bwr_autojoin, OnConVarChanged );
	
#if defined _updater_included
	sm_tf2bwr_autoupdate = CreateConVar( "sm_tf2bwr_autoupdate", "1", "If Updater plugin installed, autoupdate plugin.", FCVAR_PLUGIN );
	HookConVarChange( sm_tf2bwr_autoupdate, OnConVarChanged );
#endif
	
	sm_tf2bwr_max_defenders = CreateConVar( "sm_tf2bwr_max_defenders", "7", "Limit of RED team players. All other players will be thrown as BLU team. Set 0 to disable.", FCVAR_PLUGIN, true, 0.0, true, 10.0 );
	HookConVarChange( sm_tf2bwr_max_defenders, OnConVarChanged );
	
	sm_tf2bwr_min_defenders = CreateConVar( "sm_tf2bwr_min_defenders", "4", "Minimum number of defenders required to join BLU team. Set 0 to disable.", FCVAR_PLUGIN, true, 0.0, true, 10.0 );
	HookConVarChange( sm_tf2bwr_min_defenders, OnConVarChanged );
	
	sm_tf2bwr_min_defenders4giants = CreateConVar( "sm_tf2bwr_min_defenders4giants", "6", "Minimum number of defenders required to allow BLU team select giant robots. Set 0 to disable.", FCVAR_PLUGIN, true, 0.0, true, 10.0 );
	HookConVarChange( sm_tf2bwr_min_defenders4giants, OnConVarChanged );
	
	sm_tf2bwr_restrict_ready = CreateConVar( "sm_tf2bwr_restrict_ready", "1", "Block BLU team Ready status command.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_restrict_ready, OnConVarChanged );
	
	sm_tf2bwr_notifications = CreateConVar( "sm_tf2bwr_notifications", "1", "Show/hide chat notifications.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_notifications, OnConVarChanged );
	
	sm_tf2bwr_myloadouts = CreateConVar( "sm_tf2bwr_myloadouts", "1", "Allow human robots to select My Loadout variants.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_myloadouts, OnConVarChanged );
	
	sm_tf2bwr_sentrybuster_debug = CreateConVar( "sm_tf2bwr_sentrybuster_debug", "0", "Beams: red - too far, yellow - didn't hit anything, green - valid target, blue - barrier/wall", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bwr_sentrybuster_debug, OnConVarChanged );
	
	sm_tf2bwr_engineers = CreateConVar( "sm_tf2bwr_engineers", "0", "Allow/disallow engineers", FCVAR_PLUGIN, true, -1.0, true, 10.0 );
	HookConVarChange( sm_tf2bwr_engineers, OnConVarChanged );
	
	AddNormalSoundHook( NormalSoundHook );
	
	AddCommandListener( Command_JoinTeam, "jointeam" );
	AddCommandListener( Command_JoinTeam, "autoteam" );
	AddCommandListener( Command_JoinClass, "joinclass" );
	AddCommandListener( Command_JoinClass, "join_class" );
	AddCommandListener( Command_Taunt, "taunt" );
	AddCommandListener( Command_Taunt, "+taunt" );
	AddCommandListener( Command_Action, "+use_action_slot_item" );
	AddCommandListener( Command_Action, "+use_action_slot_item_server" );
	AddCommandListener( Command_BuyBack, "td_buyback" );
	AddCommandListener( Command_Kick, "kickid" );
	AddCommandListener( Command_Suicide, "kill" );
	AddCommandListener( Command_Suicide, "explode" );
	AddCommandListener( Command_Vote, "callvote" );
	AddCommandListener( Command_Ready, "tournament_player_readystate" );
	AddCommandListener( Command_Listener );
	
	decl String:strCmdDescr[128];
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Display robot menu", PLUGIN_TAG );
	RegConsoleCmd( "sm_robotmenu", Command_ChangeClassMenu, strCmdDescr );
	RegConsoleCmd( "sm_robomenu", Command_ChangeClassMenu, strCmdDescr );
	RegConsoleCmd( "sm_robotclass", Command_ChangeClassMenu, strCmdDescr );
	RegConsoleCmd( "sm_roboclass", Command_ChangeClassMenu, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Display help message", PLUGIN_TAG );
	RegConsoleCmd( "sm_robothelp", Command_ShowHelpMessage, strCmdDescr );
	RegConsoleCmd( "sm_robohelp", Command_ShowHelpMessage, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Join BLU team", PLUGIN_TAG );
	RegConsoleCmd( "sm_bewithrobots", Command_JoinTeamBlue, strCmdDescr );
	RegConsoleCmd( "sm_joinblue", Command_JoinTeamBlue, strCmdDescr );
	RegConsoleCmd( "sm_joinblu", Command_JoinTeamBlue, strCmdDescr );
	RegConsoleCmd( "sm_bwr", Command_JoinTeamBlue, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Join RED team", PLUGIN_TAG );
	RegConsoleCmd( "sm_joinred", Command_JoinTeamRed, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Display player list", PLUGIN_TAG );
	RegConsoleCmd( "sm_bwr_players", Command_ShowPlayerList, strCmdDescr );
	Format( strCmdDescr, sizeof(strCmdDescr), "%s Move player to spectators", PLUGIN_TAG );
	RegAdminCmd( "sm_bwr_kick", Command_MoveToSpec, ADMFLAG_KICK, strCmdDescr );
	
	AddTempEntHook( "PlayerAnimEvent", TEHook_PlayerAnimEvent );
	AddTempEntHook( "TFExplosion", TEHook_TFExplosion );
	
	HookEvent( "player_team", OnPlayerChangeTeam );
	HookEvent( "player_changeclass", OnPlayerChangeClass );
	HookEvent( "player_death", OnPlayerDeath );
	HookEvent( "player_spawn", OnPlayerSpawnPre, EventHookMode_Pre );
	HookEvent( "player_spawn", OnPlayerSpawn );
	HookEvent( "post_inventory_application", OnPostInventoryApplication );
	HookEvent( "teamplay_round_win", OnRoundWinPre, EventHookMode_Pre );
	HookEvent( "teamplay_round_start", OnRoundStartPre, EventHookMode_Pre );
	
	decl String:strFilePath[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, strFilePath, sizeof(strFilePath), "gamedata/tf2items.randomizer.txt" );
	if( FileExists( strFilePath ) )
	{
		new Handle:hGameConf = LoadGameConfigFile( "tf2items.randomizer" );
		if( hGameConf != INVALID_HANDLE )
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable" );
			PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
			hSDKEquipWearable = EndPrepSDKCall();
			if( hSDKEquipWearable == INVALID_HANDLE )
			{
				// Old gamedata
				StartPrepSDKCall(SDKCall_Player);
				PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "EquipWearable" );
				PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
				hSDKEquipWearable = EndPrepSDKCall();
			}
			
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "CTFPlayer::RemoveWearable" );
			PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
			hSDKRemoveWearable = EndPrepSDKCall();
			if( hSDKRemoveWearable == INVALID_HANDLE )
			{
				// Old gamedata
				StartPrepSDKCall(SDKCall_Player);
				PrepSDKCall_SetFromConf( hGameConf, SDKConf_Virtual, "RemoveWearable" );
				PrepSDKCall_AddParameter( SDKType_CBaseEntity, SDKPass_Pointer );
				hSDKRemoveWearable = EndPrepSDKCall();
			}
			
			CloseHandle( hGameConf );
		}
	}
	
	iDeployingBomb = -1;
	
	for( new i = 0; i < MAXPLAYERS; i++ )
	{
		ResetData( i, true );
		if( IsValidClient( i ) )
		{
			SDKHook( i, SDKHook_OnTakeDamage, OnTakeDamage );
			if( !IsFakeClient( i ) && GetClientTeam( i ) == _:TFTeam_Blue && IsPlayerAlive( i ) )
				TF2_RespawnPlayer( i );
		}
	}
	
	//CreateTimer( 10.0, Timer_AutoBalance, 0, TIMER_REPEAT );
	
#if defined _tf2spawnitem_included
	bUseTF2SI = LibraryExists( "tf2spawnitem" );
#endif
}
public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidRobot(i) )
		{
			if( GetTeamPlayerCount( _:TFTeam_Red ) >= TF_MVM_MAX_DEFENDERS )
				Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( i ) );
			else
			{
				Timer_TurnHuman( INVALID_HANDLE, GetClientUserId( i ) );
				if( IsPlayerAlive(i) && bFreezed[i] )
				{
					SetEntityFlags( i, GetEntityFlags(i) & ~FL_ATCONTROLS );
					TF2_RegeneratePlayer( i );
				}
			}
		}
}

public OnLibraryAdded( const String:strLibrary[] )
{
#if defined _updater_included
	if( StrEqual( strLibrary, "updater", false ) && bAutoUpdate )
		Updater_AddPlugin( PLUGIN_UPDATE_URL );
#endif
#if defined _tf2spawnitem_included
	if( StrEqual( strLibrary, "tf2spawnitem", false ) )
		bUseTF2SI = true;
#endif
}
public OnLibraryRemoved( const String:strLibrary[] )
{
#if defined _tf2spawnitem_included
	if( StrEqual( strLibrary, "tf2spawnitem", false ) )
		bUseTF2SI = false;
#endif
}

public OnConfigsExecuted()
{
	bUseLogs = GetConVarBool( sm_tf2bwr_logs );
	bFlagPickup = GetConVarBool( sm_tf2bwr_flag );
	bSpawnFreeze = GetConVarBool( sm_tf2bwr_freeze );
	iRespawnTimeRED = GetConVarInt( sm_tf2bwr_respawn_red );
	iRespawnTimeBLU = GetConVarInt( sm_tf2bwr_respawn_blue );
	bAutoJoin = GetConVarBool( sm_tf2bwr_autojoin );
	bRandomizer = GetConVarBool( sm_tf2bwr_randomizer );
#if defined _updater_included
	bAutoUpdate = GetConVarBool( sm_tf2bwr_autoupdate );
	if( LibraryExists("updater") )
	{
		if( bAutoUpdate )
			Updater_AddPlugin( PLUGIN_UPDATE_URL );
		else
			Updater_RemovePlugin();
	}
#endif
	iMaxDefenders = GetConVarInt( sm_tf2bwr_max_defenders );
	iMinDefenders = GetConVarInt( sm_tf2bwr_min_defenders );
	iMinDefenders4Giants = GetConVarInt( sm_tf2bwr_min_defenders4giants );
	bRestrictReady = GetConVarBool( sm_tf2bwr_restrict_ready );
	bNotifications = GetConVarBool( sm_tf2bwr_notifications );
	bMyLoadouts = GetConVarBool( sm_tf2bwr_myloadouts );
	bSentryBusterDebug = GetConVarBool( sm_tf2bwr_sentrybuster_debug );
	nMaxEngineers = GetConVarBool( sm_tf2bwr_engineers );
}
public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

public OnMapStart()
{
	if( IsMvM( true ) )
	{
		new iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "item_teamflag") ) != -1 )
		{
			SDKHook( iEnt, SDKHook_StartTouch, OnFlagTouch );
			SDKHook( iEnt, SDKHook_Touch, OnFlagTouch );
			SDKHook( iEnt, SDKHook_EndTouch, OnFlagTouch );
		}
		iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "func_respawnroom") ) != -1 )
			if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
			{
				SDKHook( iEnt, SDKHook_Touch, OnSpawnStartTouch );
				SDKHook( iEnt, SDKHook_EndTouch, OnSpawnEndTouch );
			}
		iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "func_capturezone") ) != -1 )
			if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
			{
				SDKHook( iEnt, SDKHook_Touch, OnCapZoneTouch );
				SDKHook( iEnt, SDKHook_EndTouch, OnCapZoneEndTouch );
			}
		
		iLaserModel = PrecacheModel("materials/sprites/laserbeam.vmt");
		
		flLastSentryBuster = 0.0;
		flLastAnnounce = 0.0;
		
		decl String:strAnnounceLine[PLATFORM_MAX_PATH];
		for( new a = 1; a <= 7; a++ )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts0%i.wav", a );
			PrecacheSnd( strAnnounceLine, _, true );
		}
		for( new a = 1; a <= 4; a++ )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_spy_spawn0%i.wav", a );
			PrecacheSnd( strAnnounceLine, _, true );
		}
	}
}

public OnGameFrame()
{
	if( !IsMvM() )
		return;
	
	new i, iFlag = -1, nTeamNum;
	while( ( iFlag = FindEntityByClassname( iFlag, "item_teamflag" ) ) != -1 )
	{
		i = GetEntPropEnt( iFlag, Prop_Send, "m_hOwnerEntity" );
		if( IsValidClient(i) && ( !bFlagPickup || GetClientTeam(i) != _:TFTeam_Blue ) )
			AcceptEntityInput( iFlag, "ForceReset" );
	}
	
	new iEFlags, iHealth;
	for( i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) && IsPlayerAlive(i) )
		{
			nTeamNum = GetClientTeam(i);
			
			iFlag = GetEntPropEnt( i, Prop_Send, "m_hItem" );
			if( !IsValidEdict( iFlag ) )
				iFlag = 0;
			
			if( IsFakeClient(i) )
				continue;
			
			// blue/yellow eyes
			SetEntProp( i, Prop_Send, "m_nBotSkill", BotSkill_Easy );
			SetEntProp( i, Prop_Send, "m_bIsMiniBoss", _:false );
			if( nTeamNum == _:TFTeam_Blue )
				if( iRobotMode[i] == Robot_Giant || iRobotMode[i] == Robot_BigNormal )
					SetEntProp( i, Prop_Send, "m_bIsMiniBoss", _:true );
				else if( iRobotMode[i] == Robot_Stock )
					SetEntProp( i, Prop_Send, "m_nBotSkill", BotSkill_Expert );
			
			if( nTeamNum != _:TFTeam_Blue )
			{
				if( iFlag )
					AcceptEntityInput( iFlag, "ForceDrop" );
				continue;
			}
			else if( iFlag && ( !bFlagPickup || iRobotMode[i] == Robot_SentryBuster ) )
				AcceptEntityInput( iFlag, "ForceDrop" );
			
			SetEntProp( i, Prop_Send, "m_bIsReadyToHighFive", 0 );
			
			if( iEffect[i] == Effect_AlwaysCrits )
				TF2_AddCondition( i, TFCond_CritOnKill, 0.125 );
			else if( iEffect[i] == Effect_AlwaysInvisible )
				SetEntPropFloat( i, Prop_Send, "m_flCloakMeter", 100.0 );
			
			iEFlags = GetEntityFlags(i);
			if( iDeployingBomb == i || bSpawnFreeze && GameRules_GetRoundState() == RoundState_BetweenRounds )
			{
				SetEntPropFloat( i, Prop_Send, "m_flMaxspeed", 1.0 );
				iEFlags |= FL_ATCONTROLS;
				SetEntityFlags( i, iEFlags );
				bFreezed[i] = true;
			}
			else if( bFreezed[i] )
			{
				iEFlags &= ~FL_ATCONTROLS;
				SetEntityFlags( i, iEFlags );
				iHealth = GetClientHealth( i );
				TF2_RegeneratePlayer( i );
				SetEntityHealth( i, iHealth );
				bFreezed[i] = false;
			}
		}
}

public OnClientPutInServer( iClient )
{
	ResetData( iClient, true );
	if( IsValidClient( iClient ) )
		SDKHook( iClient, SDKHook_OnTakeDamage, OnTakeDamage );
}
public OnClientDisconnect( iClient )
{
	ResetData( iClient, true );
	DestroyBuildings( iClient );
	FixSounds( iClient );
}

public OnEntityCreated( iEntity, const String:strClassname[] )
{
	if( StrEqual( strClassname, "obj_sentrygun", false ) || StrEqual( strClassname, "obj_dispenser", false ) || StrEqual( strClassname, "obj_teleporter", false ) )
		SDKHook( iEntity, SDKHook_OnTakeDamage, OnBuildingTakeDamage );
	else if( StrEqual( strClassname, "item_teamflag", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnFlagTouch );
		SDKHook( iEntity, SDKHook_Touch, OnFlagTouch );
		SDKHook( iEntity, SDKHook_EndTouch, OnFlagTouch );
	}
	else if( StrEqual( strClassname, "func_respawnroom", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnSpawnStartTouch );
		SDKHook( iEntity, SDKHook_EndTouch, OnSpawnEndTouch );
	}
	else if( StrEqual( strClassname, "func_capturezone", false ) )
	{
		SDKHook( iEntity, SDKHook_Touch, OnCapZoneTouch );
		SDKHook( iEntity, SDKHook_EndTouch, OnCapZoneEndTouch );
	}
}

public Action:Command_JoinTeam( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
	
	decl String:strTeam[16];
	if( nArgs > 0 )
		GetCmdArg( 1, strTeam, sizeof(strTeam) );
	
	new TFTeam:iTeam = TFTeam_Unassigned;
	if( StrEqual( strTeam, "red", false ) )
		iTeam = TFTeam_Red;
	else if( StrEqual( strTeam, "blue", false ) )
		iTeam = TFTeam_Blue;
	else if( StrEqual( strTeam, "spectate", false ) || StrEqual( strTeam, "spectator", false ) )
		iTeam = TFTeam_Spectator;
	else if( !StrEqual( strCommand, "autoteam", false ) )
		return Plugin_Continue;
	
	new Float:flCalmDown = flNextChangeTeam[iClient] - GetGameTime();
	if( flCalmDown > 0.0 && iTeam > TFTeam_Spectator )
	{
		PrintToChat( iClient, "* Please wait for %0.1f seconds before joining team.", flCalmDown );
		return Plugin_Handled;
	}
	
	new iNumDefenders = GetTeamPlayerCount( _:TFTeam_Red );
	new iNumHumanRobots = GetTeamPlayerCount( _:TFTeam_Blue );
	new bool:bACanJoinRED = CheckCommandAccess( iClient, "tf2bwr_joinred", 0, true );
	new bool:bACanJoinBLU = CheckCommandAccess( iClient, "tf2bwr_joinblue", 0, true );
	new bool:bCanJoinRED = ( iMaxDefenders <= 0 || iNumDefenders < iMaxDefenders ) && bACanJoinRED;
	new bool:bEnoughRED = ( iMinDefenders <= 0 || iNumDefenders > iMinDefenders );
	new bool:bCanJoinBLU = ( bEnoughRED && ( iMaxDefenders <= 0 || iNumHumanRobots < ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) ) ) && bACanJoinBLU;
	
	if( iTeam == TFTeam_Red && !bACanJoinRED )
		PrintToChat( iClient, "* You don't have persmission to join RED team." );
	else if( iTeam == TFTeam_Blue && !bACanJoinBLU )
		PrintToChat( iClient, "* You don't have persmission to join BLU team." );
	
	if( iTeam == TFTeam_Unassigned || StrEqual( strCommand, "autoteam", false ) || StrEqual( strTeam, "auto", false ) )
	{
		if( !bAutoJoin )
			iTeam = TFTeam_Red;
		else
		{
			if( bCanJoinBLU && bCanJoinRED )
			{
				if( ( GetURandomInt() % 2 ) == 0 )
					iTeam = TFTeam_Blue;
				else
					iTeam = TFTeam_Red;
			}
			else if( !bCanJoinBLU && bCanJoinRED )
				iTeam = TFTeam_Red;
			else if( bCanJoinBLU && !bCanJoinRED )
				iTeam = TFTeam_Blue;
			else //if( !bCanJoinBLU && !bCanJoinRED )
				iTeam = TFTeam_Spectator;
		}
	}
	
	if( iTeam == TFTeam_Spectator )
	{
		CreateTimer( 0.0, Timer_TurnSpec, GetClientUserId( iClient ) );
		return Plugin_Handled;
	}
	else if( iTeam == TFTeam_Blue )
	{
		if( TFTeam:GetClientTeam( iClient ) == TFTeam_Blue )
			return Plugin_Handled;
		if( !bCanJoinBLU )
		{
			if( !bEnoughRED )
				PrintToChat( iClient, "Not enough RED team players to join BLU team." );
			else
				PrintToChat( iClient, "There's no free slots in BLU team." );
			return Plugin_Handled;
		}
		CreateTimer( 0.0, Timer_TurnRobot, GetClientUserId( iClient ) );
		return Plugin_Handled;
	}
	else if( iTeam == TFTeam_Red )
	{
		if( TFTeam:GetClientTeam( iClient ) == TFTeam_Red )
			return Plugin_Handled;
		if( !bCanJoinRED )
		{
			PrintToChat( iClient, "There's no free slots in RED team." );
			return Plugin_Handled;
		}
		CreateTimer( 0.0, Timer_TurnHuman, GetClientUserId( iClient ) );
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public Action:Command_JoinClass( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return Plugin_Continue;
	
	if( !bInRespawn[iClient] && IsPlayerAlive(iClient) )
		ForcePlayerSuicide( iClient );
	
	if( GameRules_GetRoundState() != RoundState_BetweenRounds )
	{
		ShowClassMenu( iClient );
		return Plugin_Handled;
	}
	
	ResetData( iClient );
	
	decl String:strClass[16];
	if( nArgs > 0 )
		GetCmdArg( 1, strClass, sizeof(strClass) );
	
	if( strlen(strClass) <= 0 )
		return Plugin_Handled;
	
	if( StrEqual( strClass, "auto", false ) || StrEqual( strClass, "engineer", false ) && !CanPlayEngineer(iClient) )
	{
		decl String:strClasses[9][16] = { "scout","sniper","soldier","demoman","medic","heavyweapons","pyro","spy","engineer" };
		FakeClientCommand( iClient, "%s %s", strCommand, strClasses[GetRandomInt(0,7)] );
		return Plugin_Handled;
	}
	
	if( StrEqual( strClass, "scout", false ) )
		iRobotClass[iClient] = TFClass_Scout;
	else if( StrEqual( strClass, "sniper", false ) )
		iRobotClass[iClient] = TFClass_Sniper;
	else if( StrEqual( strClass, "soldier", false ) )
		iRobotClass[iClient] = TFClass_Soldier;
	else if( StrEqual( strClass, "demoman", false ) )
		iRobotClass[iClient] = TFClass_DemoMan;
	else if( StrEqual( strClass, "medic", false ) )
		iRobotClass[iClient] = TFClass_Medic;
	else if( StrEqual( strClass, "heavyweapons", false ) )
		iRobotClass[iClient] = TFClass_Heavy;
	else if( StrEqual( strClass, "pyro", false ) )
		iRobotClass[iClient] = TFClass_Pyro;
	else if( StrEqual( strClass, "spy", false ) )
		iRobotClass[iClient] = TFClass_Spy;
	else if( StrEqual( strClass, "engineer", false ) )
		iRobotClass[iClient] = TFClass_Engineer;
	if( iRobotClass[iClient] != TFClass_Unknown )
		SetClassVariant( iClient, iRobotClass[iClient], bRandomizer ? PickRandomClassVariant( iRobotClass[iClient] ) : 0 );
	
	return Plugin_Continue;
}
public Action:Command_Taunt( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || !( GetEntityFlags(iClient) & FL_ONGROUND ) || TF2_IsPlayerInCondition( iClient, TFCond_Taunting ) )
		return Plugin_Continue;
	
	if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		SentryBuster_Explode( iClient );
		return Plugin_Continue;
	}
	else if( iRobotMode[iClient] == Robot_Giant || iRobotMode[iClient] == Robot_BigNormal )
	{
		new TFClassType:iClass = TF2_GetPlayerClass( iClient );
		if( iClass == TFClass_DemoMan || iClass == TFClass_Heavy || iClass == TFClass_Pyro || iClass == TFClass_Scout || iClass == TFClass_Soldier )
		{
			// No animations for taunting 'boss' models
			return Plugin_Handled;
		}
	}
	
	new iWeapon = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon" );
	if( !IsValidEntity(iWeapon) )
		return Plugin_Handled;
	
	new String:strClassname[96];
	new String:strValidClassname[][96] = {
		"tf_weapon_fists",
		"tf_weapon_flamethrower",
		"tf_weapon_grenadelauncher",
		"tf_weapon_knife",
		"tf_weapon_minigun",
		"tf_weapon_rocketlauncher",
		"tf_weapon_scattergun",
		"tf_weapon_sniperrifle",
		"tf_weapon_syringegun_medic",
		"tf_weapon_sword"
	};
	GetEntityClassname( iWeapon, strClassname, sizeof(strClassname) );
	if( iRobotVariant[iClient] <= -1 || FindStrInArray( strValidClassname, sizeof(strValidClassname), strClassname ) != -1 )
	{
		new iFlag = GetEntPropEnt( iClient, Prop_Send, "m_hItem" );
		if( IsValidEdict( iFlag ) )
		{
			// TODO: rage levels
		}
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}
public Action:Command_Action( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return Plugin_Continue;
	return Plugin_Handled;
}
public Action:Command_BuyBack( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return Plugin_Continue;
	
	return Plugin_Handled;
}
public Action:Command_Kick( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || iClient != 0 )
		return Plugin_Continue;
	
	decl String:strTarget[8];
	GetCmdArg( 1, strTarget, sizeof(strTarget) );
	
	new iTarget = GetClientOfUserId( StringToInt( strTarget ) );
	if( !IsValidRobot( iTarget ) || GameRules_GetRoundState() != RoundState_BetweenRounds )
		return Plugin_Continue;
	
	return Plugin_Handled;
}
public Action:Command_Suicide( iClient, const String:strCommand[], nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster )
		return Plugin_Continue;
	
	FakeClientCommand( iClient, "taunt" );
	return Plugin_Handled;
}
public Action:Command_Vote( iClient, const String:strCommand[], nArgs )
{
	if( nArgs != 2 || !IsMvM() )
		return Plugin_Continue;
	
	decl String:strIssue[16];
	GetCmdArg( 1, strIssue, sizeof(strIssue) );
	if( !StrEqual( strIssue, "kick", false ) )
		return Plugin_Continue;
	
	decl String:strTarget[256];
	GetCmdArg( 2, strTarget, sizeof(strTarget) );
	
	new iUserID = 0;
	new iSpacePos = FindCharInString( strTarget, ' ' );
	if( iSpacePos > -1 )
	{
		decl String:strUserID[12];
		strcopy( strUserID, ( iSpacePos+1 < sizeof(strUserID) ? iSpacePos+1 : sizeof(strUserID) ), strTarget );
		iUserID = StringToInt( strUserID );
	}
	else
		iUserID = StringToInt( strTarget );
	
	new iTarget = GetClientOfUserId( iUserID );
	if( IsValidRobot(iTarget,false) && IsFakeClient(iTarget) )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
public Action:Command_Ready( iClient, const String:strCommand[], nArgs )
{
	if( IsMvM() && bRestrictReady && GetClientTeam(iClient) == _:TFTeam_Blue )
	{
		if( bNotifications )
			PrintToChat( iClient, "* BLU team can't start the game." );
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public Action:Command_Listener( iClient, const String:strCmdName[], nArgs )
{
	/*
	decl String:strCommand[512];
	GetCmdArgString( strCommand, sizeof(strCommand) );
	PrintToServer( "%L :  %s %s", iClient, strCmdName, strCommand );
	*/
	return Plugin_Continue;
}
public Action:Command_ChangeClassMenu( iClient, nArgs )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return Plugin_Continue;
	
	if( !bRandomizer && ( bInRespawn[iClient] || !IsPlayerAlive(iClient) ) && GameRules_GetRoundState() == RoundState_BetweenRounds )
		ShowClassMenu( iClient, TF2_GetPlayerClass( iClient ) );
	else
		ShowClassMenu( iClient );
	return Plugin_Handled;
}
public Action:Command_ShowHelpMessage( iClient, nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) )
		return Plugin_Continue;
	
	ReplyToCommand( iClient, "\x03:: \x04TF2 Be With Robots\x03 plugin ver.%s", PLUGIN_VERSION );
	ReplyToCommand( iClient, "\x03:: \x01You can play as BLU team on this server." );
	ReplyToCommand( iClient, "\x03:: \x01Type \x03jointeam blue\x01 in console or \x03/joinblue\x01 in chat." );
	ReplyToCommand( iClient, "\x03:: \x01Type \x03/robomenu\x01 to change robot class/variant." );
	
	return Plugin_Handled;
}
public Action:Command_JoinTeamBlue( iClient, nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
	
	FakeClientCommand( iClient, "jointeam blue" );
	return Plugin_Handled;
}
public Action:Command_JoinTeamRed( iClient, nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
	
	FakeClientCommand( iClient, "jointeam red" );
	return Plugin_Handled;
}
public Action:Command_ShowPlayerList( iClient, nArgs )
{
	if( !IsMvM() )
		return Plugin_Continue;
	
	new bool:bChat = iClient > 0 && GetCmdReplySource() == SM_REPLY_TO_CHAT;
	
	new String:strPlayerList[3][250], iPlayerCount[3], iIndex;
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			iIndex = GetClientTeam(i) - 1;
			if( iIndex < 0 || iIndex > 2 )
				iIndex = 0;
			iPlayerCount[iIndex]++;
			Format( strPlayerList[iIndex], sizeof(strPlayerList[]), "%s%s%s%N%s", strPlayerList[iIndex], strlen(strPlayerList[iIndex]) ? ", " : "", bChat ? "\x03" : "", i, bChat ? "\x01" : "" );
		}
	
	ReplyToCommand( iClient, "%s%d%s players in RED team: %s", bChat ? "\x03:: \x04" : "", iPlayerCount[1], bChat ? "\x01" : "", strPlayerList[1] );
	ReplyToCommand( iClient, "%s%d%s players in BLU team: %s", bChat ? "\x03:: \x04" : "", iPlayerCount[2], bChat ? "\x01" : "", strPlayerList[2] );
	ReplyToCommand( iClient, "%s%d%s other players: %s", bChat ? "\x03:: \x04" : "", iPlayerCount[0], bChat ? "\x01" : "", strPlayerList[0] );
	
	return Plugin_Handled;
}
public Action:Command_MoveToSpec( iClient, nArgs )
{
	if( !IsMvM() )
		return Plugin_Continue;
	
	if( nArgs < 1 )
	{
		ReplyToCommand( iClient, "Usage: sm_bwr_kick <target>" );
		return Plugin_Handled;
	}
	
	decl String:strTargets[64];
	GetCmdArg( 1, strTargets, sizeof(strTargets) );
	
	new nTargets, iTargets[MAXPLAYERS+1], String:strTargetName[MAX_NAME_LENGTH], bool:tn_is_ml;
	if( ( nTargets = ProcessTargetString( strTargets, iClient, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, strTargetName, sizeof(strTargetName), tn_is_ml ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	new iTeam;
	for( new i = 0; i < nTargets; i++ )
		if( ( iTeam = GetClientTeam( iTargets[i] ) ) > _:TFTeam_Spectator )
		{
			flNextChangeTeam[ iTargets[i] ] = 0.0;
			FakeClientCommand( iTargets[i], "jointeam spectate" );
			ShowActivity2( iClient, "[SM] ", "Kicked %N from %s team to spectators.", iTargets[i], iTeam == _:TFTeam_Red ? "RED" : "BLU" );
			flNextChangeTeam[ iTargets[i] ] = GetGameTime() + 30.0;
		}
	
	return Plugin_Handled;
}

public Action:TEHook_PlayerAnimEvent(const String:te_name[], const Players[], numClients, Float:delay)
{
	//PrintToServer( "%s: %d %d %d", te_name, TE_ReadNum( "m_iPlayerIndex" ), TE_ReadNum( "m_iEvent" ), TE_ReadNum( "m_nData" ) );
	return Plugin_Continue;
}
public Action:TEHook_TFExplosion(const String:te_name[], const Players[], numClients, Float:delay)
{
	//PrintToServer( "%s: %d %d %d %d %d", te_name, TE_ReadNum( "entindex" ), TE_ReadNum( "m_nDefID" ), TE_ReadNum( "m_nSound" ), TE_ReadNum( "m_iWeaponID" ), TE_ReadNum( "m_iCustomParticleIndex" ) );
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd( iClient, &iButtons, &iImpulse, Float:flVelocity[3], Float:flAngles[3], &iWeapon )
{
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) )
		return Plugin_Continue;
	
	if( bSpawnFreeze && GameRules_GetRoundState() == RoundState_BetweenRounds /*&& bInRespawn[iClient]*/ )
	{
		if( iButtons & IN_JUMP )
		{
			iButtons &= ~IN_JUMP;
			return Plugin_Changed;
		}
		else if( iButtons & IN_ATTACK )
		{
			iButtons &= ~IN_ATTACK;
			return Plugin_Changed;
		}
		else if( iButtons & IN_ATTACK2 )
		{
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
	}
	else if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		if( iButtons & IN_ATTACK )
		{
			FakeClientCommand( iClient, "taunt" );
			iButtons &= ~IN_ATTACK;
			return Plugin_Changed;
		}
		else if( iButtons & IN_JUMP )
		{
			iButtons &= ~IN_JUMP;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_TurnSpec( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	DestroyBuildings( iClient );
	FixSounds( iClient );
	
	SetVariantString( "" );
	AcceptEntityInput( iClient, "SetCustomModel" );
	SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.0 );
	
	SetEntProp( iClient, Prop_Send, "m_nBotSkill", BotSkill_Easy );
	SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
	
	ChangeClientTeam( iClient, _:TFTeam_Spectator );
	
	ResetData( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_TurnHuman( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	ResetData( iClient );
	DestroyBuildings( iClient );
	FixSounds( iClient );
	
	SetVariantString( "" );
	AcceptEntityInput( iClient, "SetCustomModel" );
	SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.0 );
	
	SetEntProp( iClient, Prop_Send, "m_nBotSkill", BotSkill_Easy );
	SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
	
	new i, iTargets[MAXPLAYERS+1], nTargets, bool:bOverlimits = GetTeamPlayerCount( _:TFTeam_Red ) >= TF_MVM_MAX_DEFENDERS;
	if( bOverlimits ) for( i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red )
			iTargets[nTargets++] = i;
	
	nTargets -= TF_MVM_MAX_DEFENDERS - 1;
	
	for( i = 0; i < nTargets; i++ ) if( iTargets[i] ) SetEntProp( iTargets[i], Prop_Send, "m_iTeamNum", _:TFTeam_Blue );
	ChangeClientTeam( iClient, _:TFTeam_Red );
	for( i = 0; i < nTargets; i++ ) if( iTargets[i] ) SetEntProp( iTargets[i], Prop_Send, "m_iTeamNum", _:TFTeam_Red );
	
	if( GetEntProp( iClient, Prop_Send, "m_iDesiredPlayerClass" ) == _:TFClass_Unknown )
		ShowClassPanel( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_TurnRobot( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	ResetData( iClient );
	DestroyBuildings( iClient );
	FixSounds( iClient );
	
	SetEntProp( iClient, Prop_Send, "m_nBotSkill", BotSkill_Easy );
	SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
	
	if( bRandomizer )
		PickRandomRobot( iClient );
	
	new iEntFlags = GetEntityFlags( iClient );
	SetEntityFlags( iClient, iEntFlags|FL_FAKECLIENT );
	ChangeClientTeam( iClient, _:TFTeam_Blue );
	SetEntityFlags( iClient, iEntFlags&~FL_FAKECLIENT );
	
	if( GetEntProp( iClient, Prop_Send, "m_iDesiredPlayerClass" ) == _:TFClass_Unknown )
		ShowClassPanel( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_Respawn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Stop;
	
	if( !IsPlayerAlive( iClient ) && GameRules_GetRoundState() == RoundState_RoundRunning )
		TF2_RespawnPlayer( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_SentryBuster_Explode( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster )
		return Plugin_Stop;
	
	new Float:flExplosionPos[3];
	GetClientAbsOrigin( iClient, flExplosionPos );
	
	if( bSentryBusterDebug || GameRules_GetRoundState() != RoundState_BetweenRounds )
	{
		new i;
		for( i = 1; i <= MaxClients; i++ )
			if( i != iClient && IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red )
				if( CanSeeTarget( iClient, i, SENTRYBUSTER_DISTANCE ) )
					DealDamage( i, SENTRYBUSTER_DAMAGE, iClient );
		
		new String:strObjects[5][] = { "obj_sentrygun","obj_dispenser","obj_teleporter","obj_teleporter_entrance","obj_teleporter_exit" };
		for( new o = 0; o < sizeof(strObjects); o++ )
		{
			i = -1;
			while( ( i = FindEntityByClassname( i, strObjects[o] ) ) != -1 )
				if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue && !GetEntProp( i, Prop_Send, "m_bCarried" ) && !GetEntProp( i, Prop_Send, "m_bPlacing" ) )
					if( CanSeeTarget( iClient, i, SENTRYBUSTER_DISTANCE ) )
						DealDamage( i, SENTRYBUSTER_DAMAGE, iClient );
		}
	}
	
	CreateParticle( flExplosionPos, "fluidSmokeExpl_ring_mvm", 6.5 );
	
	ForcePlayerSuicide( iClient );
	
	return Plugin_Stop;
}
public Action:Timer_SentryBuster_Beep( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster || TF2_IsPlayerInCondition( iClient, TFCond_Taunting ) )
	{
		if( hTimer_SentryBuster_Beep[iClient] != INVALID_HANDLE )
			KillTimer( hTimer_SentryBuster_Beep[iClient] );
		hTimer_SentryBuster_Beep[iClient] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	PrecacheSnd( SENTRYBUSTER_SND_INTRO );
	EmitSoundToAll( SENTRYBUSTER_SND_INTRO, iClient, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE );
	return Plugin_Handled;
}
public Action:Timer_OnPlayerSpawn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) )
		return Plugin_Stop;
	
	decl String:strAnnounceLine[PLATFORM_MAX_PATH];
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		PrecacheSnd( SENTRYBUSTER_SND_LOOP );
		EmitSoundToAll( SENTRYBUSTER_SND_LOOP, iClient, SNDCHAN_STATIC, SNDLEVEL_TRAIN );
		if( hTimer_SentryBuster_Beep[iClient] != INVALID_HANDLE )
			KillTimer( hTimer_SentryBuster_Beep[iClient] );
		hTimer_SentryBuster_Beep[iClient] = CreateTimer( 5.0, Timer_SentryBuster_Beep, GetClientUserId(iClient), TIMER_REPEAT );
		TriggerTimer( hTimer_SentryBuster_Beep[iClient] );
		
		if( ( flLastAnnounce + 10.0 ) < GetEngineTime() && GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			if( ( flLastSentryBuster + 360.0 ) > GetEngineTime() ) switch( GetRandomInt(0,1) )
			{
				case 1: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts02.wav" );
				default: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts03.wav" );
			}
			else switch( GetRandomInt(0,4) )
			{
				case 4: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts07.wav" );
				case 3: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts06.wav" );
				case 2: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts05.wav" );
				case 1: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts04.wav" );
				default: Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_sentry_buster_alerts01.wav" );
			}
			flLastSentryBuster = GetEngineTime();
			flLastAnnounce = GetEngineTime();
			EmitSoundToClients( strAnnounceLine );
		}
	}
	else if( iRobotMode[iClient] == Robot_Giant || iRobotMode[iClient] == Robot_BigNormal )
	{
		if( iClass == TFClass_Scout )
		{
			PrecacheSnd( GIANTSCOUT_SND_LOOP );
			EmitSoundToAll( GIANTSCOUT_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_Soldier )
		{
			PrecacheSnd( GIANTSOLDIER_SND_LOOP );
			EmitSoundToAll( GIANTSOLDIER_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_DemoMan )
		{
			PrecacheSnd( GIANTDEMOMAN_SND_LOOP );
			EmitSoundToAll( GIANTDEMOMAN_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_Heavy )
		{
			PrecacheSnd( GIANTHEAVY_SND_LOOP );
			EmitSoundToAll( GIANTHEAVY_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
		else if( iClass == TFClass_Pyro )
		{
			PrecacheSnd( GIANTPYRO_SND_LOOP );
			EmitSoundToAll( GIANTPYRO_SND_LOOP, iClient, _, SNDLEVEL_DISHWASHER );
		}
	}
	
	if( ( flLastAnnounce + 10.0 ) < GetEngineTime() && GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		if( iClass == TFClass_Engineer )
		{
			if( GetNumEngineers( iClient ) > 1 )
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/announcer_mvm_engbot_another01.wav" );
			else
				Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/announcer_mvm_engbot_arrive01.wav" );
			flLastAnnounce = GetEngineTime();
			EmitSoundToClients( strAnnounceLine );
		}
		else if( iClass == TFClass_Spy )
		{
			Format( strAnnounceLine, sizeof(strAnnounceLine), "vo/mvm_spy_spawn0%d.wav", GetRandomInt(1,4) );
			flLastAnnounce = GetEngineTime();
			EmitSoundToClients( strAnnounceLine );
		}
	}
	
	if( iEffect[iClient] == Effect_FullCharge )
	{
		if( iClass == TFClass_Medic )
		{
			new iWeapon = GetPlayerWeaponSlot( iClient, 1 );
			if( IsValidEdict( iWeapon ) )
				SetEntPropFloat( iWeapon, Prop_Send, "m_flChargeLevel", 1.0 );
		}
		else if( iClass == TFClass_Soldier )
			SetEntPropFloat( iClient, Prop_Send, "m_flNextRageEarnTime", 100.0 );
	}
	else if( iClass == TFClass_Spy && ( iEffect[iClient] == Effect_Invisible || iEffect[iClient] == Effect_AlwaysInvisible ) )
	{
		TF2_AddCondition( iClient, TFCond_Cloaked, -1.0 );
		new Handle:hTargets = CreateArray(), TFClassType:iTargetClass;
		for( new i = 1; i <= MaxClients; i++ )
			if( IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red )
			{
				iTargetClass = TF2_GetPlayerClass(i);
				if( iTargetClass != TFClass_Unknown )
					PushArrayCell( hTargets, i );
			}
		if( GetArraySize(hTargets) > 0 )
		{
			new iTarget = GetArrayCell( hTargets, GetRandomInt(0,GetArraySize(hTargets)-1) );
			TF2_DisguisePlayer( iClient, TFTeam_Red, TF2_GetPlayerClass(iTarget), iTarget );
		}
		else
			TF2_DisguisePlayer( iClient, TFTeam_Red, TFClassType:GetRandomInt(1,9) );
		CloseHandle( hTargets );
	}
	
	new iEnt = -1, Float:vecOrigin[3], Float:vecAngles[3];
	if( iRobotMode[iClient] == Robot_Giant || iRobotMode[iClient] == Robot_BigNormal || iRobotMode[iClient] == Robot_SentryBuster )
		iEnt = FindRandomSpawnPoint( Spawn_Giant );
	else if( iRobotMode[iClient] == Robot_Normal || iRobotMode[iClient] == Robot_Stock )
	{
		if( iClass == TFClass_Sniper )
			iEnt = FindRandomSpawnPoint( Spawn_Sniper );
		else if( iClass == TFClass_Spy )
			iEnt = FindRandomSpawnPoint( Spawn_Spy );
		else if( GetRandomInt(0,1) )
			iEnt = FindRandomSpawnPoint( Spawn_Lower );
	}
	if( iEnt <= MaxClients || !IsValidEntity( iEnt ) )
		iEnt = FindRandomSpawnPoint( Spawn_Normal );
	if( iEnt > MaxClients && IsValidEntity( iEnt ) )
	{
		GetEntPropVector( iEnt, Prop_Send, "m_vecOrigin", vecOrigin );
		GetEntPropVector( iEnt, Prop_Data, "m_angRotation", vecAngles );
		TeleportEntity( iClient, vecOrigin, vecAngles, NULL_VECTOR );
	}
	
	return Plugin_Stop;
}
public Action:Timer_OnPlayerChangeTeam( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidClient(iClient) )
		return Plugin_Stop;
	
	CheckTeamBalance( false, iClient );
	
	return Plugin_Stop;
}
public Action:Timer_OnPlayerDeath( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) || IsPlayerAlive(iClient) )
		return Plugin_Stop;
	
	FixSounds( iClient );
	
	if( IsValidRobot(iClient) )
	{
		if( iDeployingBomb == iClient )
			iDeployingBomb = -1;
		if( iRobotMode[iClient] != Robot_Stock && iRobotMode[iClient] != Robot_Normal )
		{
			PrecacheSnd( SENTRYBUSTER_SND_EXPLODE );
			EmitSoundToAll( SENTRYBUSTER_SND_EXPLODE, iClient, SNDCHAN_STATIC, 125 );
		}
	}
	
	if( GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Stop;
	
	if( CheckTeamBalance( false, iClient ) )
		return Plugin_Stop;
	
	new iTeamNum = GetClientTeam(iClient);
	if( iTeamNum == _:TFTeam_Blue && iRespawnTimeBLU >= 0  )
	{
		if( bRandomizer && iRobotVariant[iClient] > -1 )
			PickRandomRobot( iClient );
		
		CreateTimer( float(iRespawnTimeBLU), Timer_Respawn, GetClientUserId(iClient) );
	}
	else if( iTeamNum == _:TFTeam_Red && iRespawnTimeRED >= 0 )
		CreateTimer( float(iRespawnTimeRED), Timer_Respawn, GetClientUserId(iClient) );
	
	return Plugin_Stop;
}
public Action:Timer_DeployingBomb( Handle:hTimer, any:iUserID )
{
	if( iDeployingBomb > -1 )
		return Plugin_Stop;
	
	new iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidRobot(iClient) || !IsPlayerAlive(iClient) || !( GetEntityFlags(iClient) & FL_ONGROUND ) )
	{
		iDeployingBomb = -1;
		return Plugin_Stop;
	}
	
	GameRules_SetProp( "m_bPlayingMannVsMachine", 0 );
	CreateTimer( 0.1, Timer_SetMannVsMachines );
	
	return Plugin_Stop;
}
public Action:Timer_SetMannVsMachines( Handle:hTimer, any:data )
{
	FinishDeploying();
	return Plugin_Stop;
}
/*
public Action:Timer_AutoBalance( Handle:hTimer, any:iAutoBalance )
{
	if( !IsMvM() )
		return Plugin_Handled;
	
	PrintToServer( "Timer_AutoBalance( %d )", iAutoBalance );
	
	if( iAutoBalance )
	{
		CheckTeamBalance( true );
		return Plugin_Stop;
	}
	
	//new iBalanceReason = CheckTeamBalance();
	new iNumDefenders = GetTeamPlayerCount( _:TFTeam_Red );
	new iNumHumanRobots = GetTeamPlayerCount( _:TFTeam_Blue );
	new bool:bEnoughRED = ( iMinDefenders <= 0 || iNumDefenders >= iMinDefenders );
	new bool:bTooManyRED = ( iNumDefenders > iMaxDefenders );
	new bool:bTooManyBLU = ( iNumHumanRobots > ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) );
	if( CheckTeamBalance() && ( !bEnoughRED && iNumHumanRobots > 0 || bTooManyRED && iNumDefenders > 0 || bTooManyBLU && iNumHumanRobots > 0 ) )
	{
		if( bNotifications )
			PrintToChatAll( "Teams will be auto-balanced." );
		//CreateTimer( 5.0, Timer_AutoBalance, 1 );
	}
	return Plugin_Handled;
}
*/
public Action:Timer_SetRobotModel( Handle:hTimer, any:iClient )
{
	if( !IsMvM() )
		return Plugin_Stop;
	
	if( !IsValidRobot( iClient ) )
		return Plugin_Stop;
	
	if( !IsPlayerAlive( iClient ) )
		return Plugin_Handled;
	
	if( TF2_IsPlayerInCondition( iClient, TFCond_Taunting ) || TF2_IsPlayerInCondition( iClient, TFCond_Dazed) )
		return Plugin_Handled;
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if( iRobotMode[iClient] == Robot_SentryBuster )
	{
		SetRobotModel( iClient, "models/bots/demo/bot_sentry_buster.mdl" );
		SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.8 );
	}
	else
	{
		new String:strModel[PLATFORM_MAX_PATH];
		switch( iClass )
		{
			case TFClass_Scout: strcopy( strModel, sizeof(strModel), "scout" );
			case TFClass_Sniper: strcopy( strModel, sizeof(strModel), "sniper" );
			case TFClass_Soldier: strcopy( strModel, sizeof(strModel), "soldier" );
			case TFClass_DemoMan: strcopy( strModel, sizeof(strModel), "demo" );
			case TFClass_Medic: strcopy( strModel, sizeof(strModel), "medic" );
			case TFClass_Heavy: strcopy( strModel, sizeof(strModel), "heavy" );
			case TFClass_Pyro: strcopy( strModel, sizeof(strModel), "pyro" );
			case TFClass_Spy: strcopy( strModel, sizeof(strModel), "spy" );
			case TFClass_Engineer: strcopy( strModel, sizeof(strModel), "engineer" );
		}
		
		if( strlen(strModel) > 0 )
		{
			if( iRobotMode[iClient] == Robot_Giant )
			{
				if( iClass == TFClass_DemoMan || iClass == TFClass_Heavy || iClass == TFClass_Pyro || iClass == TFClass_Scout || iClass == TFClass_Soldier )
					Format( strModel, sizeof( strModel ), "models/bots/%s_boss/bot_%s_boss.mdl", strModel, strModel );
				else
					Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
				SetRobotModel( iClient, strModel );
				SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.8 );
			}
			else
			{
				Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
				SetRobotModel( iClient, strModel );
				if( iRobotMode[iClient] == Robot_BigNormal )
					SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.8 );
				else
					SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.0 );
			}
		}
	}
	
	return Plugin_Stop;
}
public Action:Timer_DeleteParticle( Handle:hTimer, any:iEntRef )
{
	new iParticle = EntRefToEntIndex( iEntRef );
	if( IsValidEntity(iParticle) )
	{
		decl String:strClassname[256];
		GetEdictClassname( iParticle, strClassname, sizeof(strClassname) );
		if( StrEqual( strClassname, "info_particle_system", false ) )
			AcceptEntityInput( iParticle, "Kill" );
	}
}


public OnPlayerChangeTeam( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	if( GetEventInt( hEvent, "team" ) <= _:TFTeam_Spectator )
		return;
	
	flNextChangeTeam[iClient] = GetGameTime() + 15.0;
	
	CreateTimer( 0.0, Timer_OnPlayerChangeTeam, GetEventInt( hEvent, "userid" ) );
}

public OnPlayerChangeClass( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	DestroyBuildings( iClient );
}

public OnPlayerDeath( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	CreateTimer( 0.0, Timer_OnPlayerDeath, GetEventInt( hEvent, "userid" ) );
}
public Action:OnPlayerSpawnPre( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return Plugin_Continue;
	
	bSkipInvAppEvent[iClient] = false;
	
	if( GetClientTeam(iClient) != _:TFTeam_Blue )
		return Plugin_Continue;
	
	new bool:bCanPlayEngineer = CanPlayEngineer(iClient);
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if( iClass < TFClass_Scout || iClass > TFClass_Engineer || iClass > TFClass_Spy && !bCanPlayEngineer )
	{
		iClass = TFClassType:GetRandomInt(1,(bCanPlayEngineer?9:8));
		TF2_SetPlayerClass( iClient, iClass, _, true );
		TF2_RegeneratePlayer( iClient );
	}
	
	CreateTimer( 0.1, Timer_SetRobotModel, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	
	return Plugin_Continue;
}
public OnPlayerSpawn( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	FixSounds( iClient );
	
	new bool:bPrintMsg = bNotifications && !bSkipSpawnEventMsg[iClient];
	if( !bSkipSpawnEventMsg[iClient] )
		bSkipSpawnEventMsg[iClient] = true;
	
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	
	new iTeamNum = GetClientTeam(iClient);
	if( iTeamNum == _:TFTeam_Blue )
	{
		decl String:strVariant[128];
		if( iRobotVariant[iClient] == -1 )
			PrintToChat( iClient, "\x01You're spawned as \x03You are\x01", strVariant );
		else if( GetRobotVariantName( iClass, iRobotVariant[iClient], strVariant, sizeof(strVariant) ) )
			PrintToChat( iClient, "\x01You're spawned as \x03%s\x01", strVariant );
		
		if( bPrintMsg )
			PrintToChat( iClient, "\x01Type \x03/robomenu\x01 to change variant of your roboclass." );
	}
	else if( iTeamNum == _:TFTeam_Red )
	{
		if( bPrintMsg )
			PrintToChat( iClient, "\x01You can play as BLU team. Type \x03/robohelp\x01 for details." );
		return;
	}
	else
		return;
	
	if( iClass == TFClass_Unknown )
		return;
	
	CreateTimer( 0.1, Timer_OnPlayerSpawn, GetClientUserId(iClient) );
	
	if( iRobotMode[iClient] == Robot_SentryBuster )
		PrintToChat( iClient, "\x01SentryBuster: Press \x03Attack\x01/\x03Taunt\x01 button to detonate." );
}
/*
public Action:TF2Items_OnGiveNamedItem( iClient, String:strClassname[], iItemDefID, &Handle:hItem )
{
	if( !IsMvM() )
		return Plugin_Continue;
	
	if( !IsValidRobot(iClient) )
		return Plugin_Continue;
	
	new TFClassType:iClass = TF2_GetPlayerClass( iClient );
	new TF2ItemSlot:iSlot = TF2II_GetItemSlot( iItemDefID, iClass );
	
	if( iSlot == TF2ItemSlot_Action || iSlot == TF2ItemSlot_Misc )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
*/
public OnPostInventoryApplication( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	if( !IsMvM() )
		return;
	
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iClient) || IsFakeClient(iClient) || !IsPlayerAlive(iClient) )
		return;
	
	if( bSkipInvAppEvent[iClient] )
	{
		bSkipInvAppEvent[iClient] = false;
		return;
	}
	
	if( GetClientTeam(iClient) != _:TFTeam_Blue )
	{
		if( bStripItems[iClient] )
			StripItems( iClient );
		bStripItems[iClient] = false;
		
		bSkipInvAppEvent[iClient] = true;
		TF2_RegeneratePlayer( iClient );
		return;
	}
	
	StripItems( iClient );
	
	new TFClassType:iClass = TF2_GetPlayerClass( iClient ), Handle:hAttributes = INVALID_HANDLE;
	switch( iClass )
	{
		case TFClass_Scout:
		{
			if( iRobotVariant[iClient] == 0 )
				SpawnItem( iClient, 13 );
			
			if( iRobotVariant[iClient] == 1 )
				SpawnItem( iClient, 46 );
			
			if( iRobotVariant[iClient] == 0 || iRobotVariant[iClient] == 1 || iRobotVariant[iClient] == 5 )
			{
				if( iRobotVariant[iClient] == 5 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:1475.0 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.7 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.7 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:5.0 );
				}
				SpawnItem( iClient, 0, hAttributes );
			}
			if( iRobotVariant[iClient] == 3 || iRobotVariant[iClient] == 7 )
			{
				if( iRobotVariant[iClient] == 7 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:1490.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:2.0 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.7 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.7 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:5.0 );
					PushArrayCell( hAttributes, 278 ); PushArrayCell( hAttributes, _:0.1 );
				}
				else
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:15.0 );
				}
				SpawnItem( iClient, 44, hAttributes );
			}
			if( iRobotVariant[iClient] == 2 || iRobotVariant[iClient] == 6 )
			{
				if( iRobotVariant[iClient] == 6 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:1075.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:2.0 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.7 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.7 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:5.0 );
				}
				SpawnItem( iClient, 221, hAttributes );
			}
			if( iRobotVariant[iClient] == 4 )
				SpawnItem( iClient, 648 );
		}
		case TFClass_Soldier:
		{
			if( iRobotVariant[iClient] == 6 )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:3600.0 );
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 318 ); PushArrayCell( hAttributes, _:0.2 );
				PushArrayCell( hAttributes, 103 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:2.0 );
				PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.4 );
				PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.4 );
				PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:3.0 );
				SpawnItem( iClient, 513, hAttributes );
			}
			else
			{
				if( iRobotVariant[iClient] == 5 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:3600.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.4 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.4 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:3.0 );
				}
				else if( iRobotVariant[iClient] == 7 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:3600.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 103 ); PushArrayCell( hAttributes, _:0.65 );
					PushArrayCell( hAttributes, 318 ); PushArrayCell( hAttributes, _:-0.8 );
					PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.4 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.4 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:3.0 );
				}
				SpawnItem( iClient, 18, hAttributes );
			}
			
			if( iRobotVariant[iClient] >= 1 && iRobotVariant[iClient] <= 4 )
			{
				hAttributes = CreateArray();
				if( iRobotVariant[iClient] == 1 )
				{
					PushArrayCell( hAttributes, 116 ); PushArrayCell( hAttributes, _:1.0 );
				}
				else
				{
					PushArrayCell( hAttributes, 116 ); PushArrayCell( hAttributes, _:( iRobotVariant[iClient] == 4 ? 3.0 : ( iRobotVariant[iClient] == 3 ? 2.0 : 1.0 ) ) );
					PushArrayCell( hAttributes, 319 ); PushArrayCell( hAttributes, _:9.0 );
				}
				SpawnItem( iClient, ( iRobotVariant[iClient] == 4 ? 226 : ( iRobotVariant[iClient] == 3 ? 354 : 129 ) ), hAttributes );
			}
			
			SpawnItem( iClient, 6 );
		}
		case TFClass_Pyro:
		{
			if( iRobotVariant[iClient] == 5 )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:2825.0 );
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.6 );
				PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.6 );
				PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:6.0 );
				PushArrayCell( hAttributes, 255 ); PushArrayCell( hAttributes, _:5.0 );
				PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:0.05 );
				PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:1.0 );
				SpawnItem( iClient, 215, hAttributes );
			}
			else if( iRobotVariant[iClient] == 0 || iRobotVariant[iClient] == 3 )
			{
				if( iRobotVariant[iClient] == 3 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:2825.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.6 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.6 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:6.0 );
				}
				SpawnItem( iClient, 21, hAttributes );
			}
			
			if( iRobotVariant[iClient] == 1 || iRobotVariant[iClient] == 4 )
			{
				if( iRobotVariant[iClient] == 4 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 25 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:2825.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.6 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.6 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:6.0 );
					PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:0.3 );
					PushArrayCell( hAttributes, 103 ); PushArrayCell( hAttributes, _:1.0 );
				}
				else
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 25 ); PushArrayCell( hAttributes, _:0.5 );
				}
				SpawnItem( iClient, 39, hAttributes );
			}
			else if( iRobotVariant[iClient] == 2 )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:1.0 );
				PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:0.75 );
				PushArrayCell( hAttributes, 318 ); PushArrayCell( hAttributes, _:1.25 );
				PushArrayCell( hAttributes, 103 ); PushArrayCell( hAttributes, _:0.35 );
				SpawnItem( iClient, 740, hAttributes );
			}
			
			SpawnItem( iClient, 2, hAttributes );
		}
		case TFClass_DemoMan:
		{
			if( iRobotVariant[iClient] == SENTRYBUSTER_CLASSVARIANT )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:2325.0 );
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:2.0 );
				PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:7.0 );
				PushArrayCell( hAttributes, 402 ); PushArrayCell( hAttributes, _:1.0 );
				SpawnItem( iClient, 307, hAttributes );
			}
			else
			{
				if( iRobotVariant[iClient] == 0 || iRobotVariant[iClient] == 2 || iRobotVariant[iClient] == 3 )
				{
					if( iRobotVariant[iClient] == 2 )
					{
						hAttributes = CreateArray();
						PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:3128.0 );
						PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 318 ); PushArrayCell( hAttributes, _:-0.4 );
						PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:0.75 );
						PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:4.0 );
					}
					else if( iRobotVariant[iClient] == 3 )
					{
						hAttributes = CreateArray();
						PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:2825.0 );
						PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:4.0 );
					}
					SpawnItem( iClient, 19, hAttributes );
				
					SpawnItem( iClient, 1 );
				}
				else if( iRobotVariant[iClient] == 1 || iRobotVariant[iClient] == 4 )
				{
					if( iRobotVariant[iClient] == 4 )
					{
						hAttributes = CreateArray();
						PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:3150.0 );
						PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 31 ); PushArrayCell( hAttributes, _:3.0 );
						PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.5 );
						PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:4.0 );
					}
					SpawnItem( iClient, 132, hAttributes );
					
					if( hSDKEquipWearable != INVALID_HANDLE )
					{
						SpawnItem( iClient, 131 );
					
						if( iRobotVariant[iClient] == 4 )
							SpawnItem( iClient, 405 );
					}
				}
			}
		}
		case TFClass_Heavy:
		{
			if( iRobotVariant[iClient] == 0 || iRobotVariant[iClient] == 6 )
			{
				if( iRobotVariant[iClient] == 6 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:4700.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:1.5 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.3 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.3 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:2.0 );
				}
				SpawnItem( iClient, 15, hAttributes );
			}
			else if( iRobotVariant[iClient] == 1 )
			{
				SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 0.65 );
				
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:1.3 );
				PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:0.2 );
				PushArrayCell( hAttributes, 125 ); PushArrayCell( hAttributes, _:-240.0 );
				SpawnItem( iClient, 656, hAttributes );
			}
			else if( iRobotVariant[iClient] == 2 )
			{
				SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.5 );
				
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:600.0 );
				SpawnItem( iClient, 331, hAttributes );
			}
			else if( iRobotVariant[iClient] == 3 || iRobotVariant[iClient] == 5 || iRobotVariant[iClient] == 11 )
			{
				if( iRobotVariant[iClient] == 5 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:4700.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:1.2 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.3 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.3 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:2.0 );
					PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:6.0 );
				}
				else if( iRobotVariant[iClient] == 11 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:59700.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.4 );
					PushArrayCell( hAttributes, 57 ); PushArrayCell( hAttributes, _:250.0 );
					PushArrayCell( hAttributes, 6 ); PushArrayCell( hAttributes, _:0.6 );
					PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:5.0 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.3 );
					PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:2.0 );
					PushArrayCell( hAttributes, 405 ); PushArrayCell( hAttributes, _:0.1 );
					PushArrayCell( hAttributes, 478 ); PushArrayCell( hAttributes, _:0.1 );
				}
				SpawnItem( iClient, 43, hAttributes );
			}
			else if( iRobotVariant[iClient] == 4 )
				SpawnItem( iClient, 239 );
			else if( iRobotVariant[iClient] == 7 )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:4700.0 );
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:1.5 );
				PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:2.0 );
				PushArrayCell( hAttributes, 323 ); PushArrayCell( hAttributes, _:1.0 );
				SpawnItem( iClient, 850, hAttributes );
			}
			else if( iRobotVariant[iClient] == 8 )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:4700.0 );
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:1.5 );
				PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:2.0 );
				SpawnItem( iClient, 312, hAttributes );
			}
			else if( iRobotVariant[iClient] == 9 )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:4700.0 );
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:1.5 );
				PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:2.0 );
				SpawnItem( iClient, 41, hAttributes );
			}
			else if( iRobotVariant[iClient] == 10 )
			{
				hAttributes = CreateArray();
				PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:4700.0 );
				PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
				PushArrayCell( hAttributes, 2 ); PushArrayCell( hAttributes, _:1.5 );
				PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.3 );
				PushArrayCell( hAttributes, 330 ); PushArrayCell( hAttributes, _:2.0 );
				SpawnItem( iClient, 811, hAttributes );
			}
			
			if( iRobotVariant[iClient] == 0 || iRobotVariant[iClient] >= 6 )
				SpawnItem( iClient, 5 );
		}
		case TFClass_Medic:
		{
			SpawnItem( iClient, 17 );
			
			if( iRobotVariant[iClient] >= 3 && iRobotVariant[iClient] <= 5 )
			{
				if( iRobotVariant[iClient] == 4 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 10 ); PushArrayCell( hAttributes, _:0.1 );
					PushArrayCell( hAttributes, 8 ); PushArrayCell( hAttributes, _:10.0 );
				}
				else if( iRobotVariant[iClient] == 5 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:4350.0 );
					PushArrayCell( hAttributes, 107 ); PushArrayCell( hAttributes, _:0.5 );
					PushArrayCell( hAttributes, 252 ); PushArrayCell( hAttributes, _:0.6 );
					PushArrayCell( hAttributes, 329 ); PushArrayCell( hAttributes, _:0.6 );
					PushArrayCell( hAttributes, 8 ); PushArrayCell( hAttributes, _:200.0 );
				}
				SpawnItem( iClient, 411, hAttributes );
			}
			else
			{
				if( iRobotVariant[iClient] == 1 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 10 ); PushArrayCell( hAttributes, _:5.0 );
					PushArrayCell( hAttributes, 8 ); PushArrayCell( hAttributes, _:0.1 );
					PushArrayCell( hAttributes, 314 ); PushArrayCell( hAttributes, _:-3.0 );
				}
				else if( iRobotVariant[iClient] == 2 )
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 10 ); PushArrayCell( hAttributes, _:0.25 );
					PushArrayCell( hAttributes, 8 ); PushArrayCell( hAttributes, _:5.0 );
				}
				else /*if( iRobotVariant[iClient] == 0 )*/
				{
					hAttributes = CreateArray();
					PushArrayCell( hAttributes, 10 ); PushArrayCell( hAttributes, _:2.0 );
					PushArrayCell( hAttributes, 8 ); PushArrayCell( hAttributes, _:5.0 );
				}
				SpawnItem( iClient, 29, hAttributes );
			}
			
			SpawnItem( iClient, 8 );
		}
		case TFClass_Sniper:
		{
			if( iRobotVariant[iClient] == 0 || iRobotVariant[iClient] == 1 )
				SpawnItem( iClient, 14 );
			else if( iRobotVariant[iClient] == 2 )
				SpawnItem( iClient, 230 );
			else if( iRobotVariant[iClient] == 4 )
				SpawnItem( iClient, 56 );
			
			if( iRobotVariant[iClient] == 1 )
				SpawnItem( iClient, 58 );
			else if( iRobotVariant[iClient] == 3 )
				SpawnItem( iClient, 58 );
			else if( iRobotVariant[iClient] == 0 || iRobotVariant[iClient] == 2 || iRobotVariant[iClient] == 4 )
				SpawnItem( iClient, 16 );
			
			SpawnItem( iClient, 3 );
		}
		case TFClass_Spy:
		{
			SpawnItem( iClient, 24 );
			
			SpawnItem( iClient, 735 );
			
			SpawnItem( iClient, 4 );
			
			SpawnItem( iClient, 27 );
			
			SpawnItem( iClient, 60 );
		}
		case TFClass_Engineer:
		{
			SpawnItem( iClient, 9 );
			
			SpawnItem( iClient, 22 );
			
			hAttributes = CreateArray();
			PushArrayCell( hAttributes, 26 ); PushArrayCell( hAttributes, _:150.0 );
			SpawnItem( iClient, 7, hAttributes );
			
			SpawnItem( iClient, 25 );
			
			SpawnItem( iClient, 26 );
			
			SpawnItem( iClient, 28 );
		}
	}
	
	if( iRobotVariant[iClient] <= -1 )
	{
		bSkipInvAppEvent[iClient] = true;
		TF2_RegeneratePlayer( iClient );
	}
	else
		bStripItems[iClient] = true;
	
	FixTPose( iClient );
}
public Action:OnRoundWinPre( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	if( IsMvM() )
		FinishDeploying();
	return Plugin_Continue;
}

public Action:OnRoundStartPre( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	if( IsMvM()	)
	{
		new bool:bGiants = iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red );
		for( new iClient = 1; iClient <= MaxClients; iClient++ )
			if( IsValidRobot( iClient ) && !CheckTeamBalance( false, iClient ) && ( iRobotVariant[iClient] >= 0 || !bMyLoadouts ) && ( bRandomizer || !bGiants && ( iRobotMode[iClient] == Robot_Giant || iRobotMode[iClient] == Robot_BigNormal ) ) )
				PickRandomRobot( iClient );
	}
	return Plugin_Continue;
}

public Action:OnSpawnStartTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidRobot(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue )
		return Plugin_Continue;
	
	bInRespawn[iOther] = true;
	return Plugin_Continue;
}
public Action:OnSpawnEndTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidRobot(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue )
		return Plugin_Continue;
	
	bInRespawn[iOther] = false;
	return Plugin_Continue;
}
public Action:OnCapZoneTouch( iEntity, iOther )
{
	static Float:flLastSndPlay[MAXPLAYERS];
	
	if( iDeployingBomb >= 0 )
		return Plugin_Continue;
	
	if(
		!IsMvM()
		|| GameRules_GetRoundState() != RoundState_RoundRunning
		|| !IsValidClient(iOther)
		|| IsFakeClient(iOther)
		|| iRobotMode[iOther] == Robot_SentryBuster
		|| !( GetEntityFlags(iOther) & FL_ONGROUND )
		|| !IsValidEdict( GetEntPropEnt( iOther, Prop_Send, "m_hItem" ) )
	)
		return Plugin_Continue;
	
	if( ( flLastSndPlay[iOther] + 2.0 ) <= GetGameTime() )
	{
		if( iRobotMode[iOther] == Robot_Giant || iRobotMode[iOther] == Robot_BigNormal )
		{
			PrecacheSnd( GIANTROBOT_SND_DEPLOYING );
			EmitSoundToAll( GIANTROBOT_SND_DEPLOYING, iOther, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
		else
		{
			PrecacheSnd( SMALLROBOT_SND_DEPLOYING );
			EmitSoundToAll( SMALLROBOT_SND_DEPLOYING, iOther, SNDCHAN_STATIC, SNDLEVEL_SCREAMING );
		}
		flLastSndPlay[iOther] = GetGameTime();
		new iClass = _:TF2_GetPlayerClass(iOther);
		if( iClass >= 1 && iClass < 8 )
			TF2_PlayAnimation( iOther, 21, iDeployingAnim[iClass-1][_:(iRobotMode[iOther]==Robot_Giant)] );
		else
			FakeClientCommand( iOther, "taunt" );
	}
	iDeployingBomb = iOther;
	CreateTimer( 1.8, Timer_DeployingBomb, GetClientUserId(iOther) );
	return Plugin_Continue;
}
public Action:OnCapZoneEndTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidClient(iOther) || iOther != iDeployingBomb )
		return Plugin_Continue;
	
	iDeployingBomb = -1;
	return Plugin_Continue;
}
public Action:OnFlagTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidClient(iOther) || IsFakeClient(iOther) )
		return Plugin_Continue;
	
	if( GetClientTeam(iOther) != _:TFTeam_Blue || !bFlagPickup || TF2_GetPlayerClass(iOther) == TFClass_Spy || TF2_GetPlayerClass(iOther) == TFClass_Engineer || iRobotMode[iOther] == Robot_SentryBuster )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
public Action:OnTakeDamage( iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamageBits, &iWeapon, Float:flDamageForce[3], Float:flDamagePosition[3], iDamageCustom )
{
	if( !IsMvM() || !IsValidClient(iVictim) )
		return Plugin_Continue;
	
	//PrintToChat( iVictim, "Damage: %0.2f (%d) (%d)", flDamage, iDamageBits, iDamageCustom );
	
	if( GetClientTeam(iVictim) == _:TFTeam_Blue && iRobotMode[iVictim] == Robot_SentryBuster )
	{
		if( TF2_IsPlayerInCondition( iVictim, TFCond_Taunting ) )
		{
			flDamage = 0.0;
			return Plugin_Changed;
		}
		else if( flDamage * ( iDamageBits & DMG_CRIT ? 3.0 : 1.0 ) >= float( GetClientHealth(iVictim) ) )
		{
			if( GetEntityFlags(iVictim) & FL_ONGROUND )
				FakeClientCommand( iVictim, "taunt" );
			else
				SentryBuster_Explode( iVictim );
			flDamage = 0.0;
			return Plugin_Changed;
		}
	}
	
	if( GetClientTeam(iVictim) == _:TFTeam_Blue )
	{
		if( ( bInRespawn[iVictim] || GameRules_GetRoundState() == RoundState_BetweenRounds ) && ( iAttacker == iVictim || IsValidClient(iAttacker) && flDamage > 0.0 ) )
		{
			flDamage = 0.0;
			if( iAttacker != iVictim )
				TF2_AddCondition( iVictim, TFCond_Ubercharged, 1.0 );
			return Plugin_Changed;
		}
		else if( IsValidClient(iAttacker) && iAttacker != iVictim && GetFeatureStatus( FeatureType_Capability, "SDKHook_DmgCustomInOTD" ) == FeatureStatus_Available && iDamageCustom == TF_CUSTOM_BACKSTAB )
		{
			iDamageBits &= ~DMG_CRIT;
			iDamageCustom = 0;
			flDamage /= 10.0;
			return Plugin_Changed;
		}
		else if( IsValidClient(iAttacker) && iAttacker != iVictim && TF2_GetPlayerClass(iAttacker) == TFClass_Spy && IsValidEntity(iWeapon) && ( iDamageBits & DMG_CRIT ) == DMG_CRIT && flDamage >= 300.0 )
		{
			decl String:strWeaponClass[32];
			GetEntityClassname( iWeapon, strWeaponClass, sizeof(strWeaponClass) );
			if( strcmp( strWeaponClass, "tf_weapon_knife", false ) == 0 || strcmp( strWeaponClass, "saxxy", false ) == 0 )
			{
				iDamageBits &= ~DMG_CRIT;
				flDamage /= 10.0;
				return Plugin_Changed;
			}
		}
	}
	
	if( GetClientTeam(iVictim) == _:TFTeam_Red && iVictim != iAttacker && ( IsValidClient(iAttacker) && GetClientTeam(iAttacker) == _:TFTeam_Blue && bInRespawn[iAttacker] || GameRules_GetRoundState() == RoundState_BetweenRounds ) )
	{
		flDamage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
public Action:OnBuildingTakeDamage( iBuilding, &iAttacker, &iInflictor, &Float:flDamage, &iDamageBits, &iWeapon, Float:flDamageForce[3], Float:flDamagePosition[3], iDamageCustom )
{
	if( true || !IsMvM() || !IsValidEdict(iBuilding) )
		return Plugin_Continue;
	
	if( IsValidClient(iAttacker) && !IsFakeClient(iAttacker) && ( bInRespawn[iAttacker] || GameRules_GetRoundState() == RoundState_BetweenRounds ) && GetClientTeam(iAttacker) == _:TFTeam_Blue )
	{
		flDamage = 0.0;
		if( bNotifications )
			PrintToChat( iAttacker, "You can't hit enemies from spawn zone." );
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:NormalSoundHook( iClients[64], &iNumClients, String:strSound[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags )
{
	//if( StrContains( strSound, "vo/mvm_", false ) != -1 ) PrintToServer( "%s %d %f %d %d %d", strSound, iChannel, flVolume, iLevel, iPitch, iFlags );
	
	if( !IsMvM() || !IsValidRobot(iEntity) )
		return Plugin_Continue;
	
	new TFClassType:iClass = TF2_GetPlayerClass( iEntity );
	if( StrContains( strSound, "announcer", false ) != -1 )
		return Plugin_Continue;
	else if( StrContains( strSound, "player/footsteps/", false ) != -1 )
	{
		if( iClass == TFClass_Medic )
			return Plugin_Stop;
		if( iClass == TFClass_Spy && ( TF2_IsPlayerInCondition( iEntity, TFCond_Cloaked ) || TF2_IsPlayerInCondition( iEntity, TFCond_DeadRingered ) || TF2_IsPlayerInCondition( iEntity, TFCond_Disguised ) ) )
			return Plugin_Continue;
		
		new iStep;
		if( iRobotMode[iEntity] == Robot_Giant || iRobotMode[iEntity] == Robot_BigNormal )
		{
			iPitch = 100;
			switch( iClass )
			{
				//case TFClass_Scout:		Format( strSound, sizeof( strSound ), "mvm/giant_scout/giant_scout_step_0%i.wav", GetRandomInt(1,4) );
				//case TFClass_Soldier:	Format( strSound, sizeof( strSound ), "mvm/giant_soldier/giant_soldier_step0%i.wav", GetRandomInt(1,4) );
				//case TFClass_DemoMan:	Format( strSound, sizeof( strSound ), "mvm/giant_demoman/giant_demoman_step_0%i.wav", GetRandomInt(1,4) );
				//case TFClass_Heavy:		Format( strSound, sizeof( strSound ), "mvm/giant_heavy/giant_heavy_step0%i.wav", GetRandomInt(1,4) );
				//case TFClass_Pyro:		Format( strSound, sizeof( strSound ), "mvm/giant_pyro/giant_pyro_step_0%i.wav", GetRandomInt(1,4) );
				default:				Format( strSound, sizeof( strSound ), "^mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1,8) );
			}
		}
		else if( iRobotMode[iEntity] == Robot_SentryBuster )
			return Plugin_Continue;
		else //if( iRobotMode[iEntity] == Robot_Normal || iRobotMode[iEntity] == Robot_Stock )
		{
			iPitch = GetRandomInt(95,100);
			iStep = GetRandomInt(1,18);
			Format( strSound, sizeof( strSound ), "mvm/player/footsteps/robostep_%s%i.wav", ( iStep < 10 ? "0" : "" ), iStep );
		}
		PrecacheSnd( strSound );
		EmitSoundToAll( strSound, iEntity, SNDCHAN_STATIC, 95, _, _, iPitch );
		return Plugin_Stop;
	}
	else if( StrContains( strSound, ")weapons/rocket_", false ) != -1 && ( iRobotMode[iEntity] == Robot_Giant || iRobotMode[iEntity] == Robot_BigNormal ) )
	{
		ReplaceString( strSound, sizeof( strSound ), ")weapons/", "mvm/giant_soldier/giant_soldier_" );
		PrecacheSnd( strSound );
		EmitSoundToAll( strSound, iEntity, SNDCHAN_STATIC, 95, _, _, iPitch );
		return Plugin_Stop;
	}
	else if( StrContains( strSound, "weapons\\quake_rpg_fire_remastered", false ) != -1 && ( iRobotMode[iEntity] == Robot_Giant || iRobotMode[iEntity] == Robot_BigNormal ) )
	{
		ReplaceString( strSound, sizeof( strSound ), "weapons\\quake_rpg_fire_remastered", "mvm/giant_soldier/giant_soldier_rocket_shoot" );
		PrecacheSnd( strSound );
		EmitSoundToAll( strSound, iEntity, SNDCHAN_STATIC, 95, _, _, iPitch );
		return Plugin_Stop;
	}
	else if( StrContains( strSound, "vo/", false ) != -1 )
	{
		if( iRobotMode[iEntity] == Robot_SentryBuster || TF2_IsPlayerInCondition( iEntity, TFCond_Disguised ) )
			return Plugin_Continue;
		
		if(
			StrContains( strSound, "vo/mvm/", false ) != -1
			|| StrContains( strSound, "/demoman_", false ) == -1
			&& StrContains( strSound, "/engineer_", false ) == -1
			&& StrContains( strSound, "/heavy_", false ) == -1
			&& StrContains( strSound, "/medic_", false ) == -1
			&& StrContains( strSound, "/pyro_", false ) == -1
			&& StrContains( strSound, "/scout_", false ) == -1
			&& StrContains( strSound, "/sniper_", false ) == -1
			&& StrContains( strSound, "/soldier_", false ) == -1
			&& StrContains( strSound, "/spy_", false ) == -1
			&& StrContains( strSound, "/engineer_", false ) == -1
		)
			return Plugin_Continue;
		
		if( iRobotMode[iEntity] == Robot_Giant || iRobotMode[iEntity] == Robot_BigNormal )
		{
			switch( iClass )
			{
				case TFClass_Scout:		ReplaceString( strSound, sizeof(strSound), "scout_", "scout_mvm_m_", false );
				case TFClass_Sniper:	ReplaceString( strSound, sizeof(strSound), "sniper_", "sniper_mvm_", false );
				case TFClass_Soldier:	ReplaceString( strSound, sizeof(strSound), "soldier_", "soldier_mvm_m_", false );
				case TFClass_DemoMan:	ReplaceString( strSound, sizeof(strSound), "demoman_", "demoman_mvm_m_", false );
				case TFClass_Medic:		ReplaceString( strSound, sizeof(strSound), "medic_", "medic_mvm_", false );
				case TFClass_Heavy:		ReplaceString( strSound, sizeof(strSound), "heavy_", "heavy_mvm_m_", false );
				case TFClass_Pyro:		ReplaceString( strSound, sizeof(strSound), "pyro_", "pyro_mvm_m_", false );
				case TFClass_Spy:		ReplaceString( strSound, sizeof(strSound), "spy_", "spy_mvm_", false );
				case TFClass_Engineer:	ReplaceString( strSound, sizeof(strSound), "engineer_", "engineer_mvm_", false );
				default:				return Plugin_Continue;
			}
		}
		else
		{
			switch( iClass )
			{
				case TFClass_Scout:		ReplaceString( strSound, sizeof(strSound), "scout_", "scout_mvm_", false );
				case TFClass_Sniper:	ReplaceString( strSound, sizeof(strSound), "sniper_", "sniper_mvm_", false );
				case TFClass_Soldier:	ReplaceString( strSound, sizeof(strSound), "soldier_", "soldier_mvm_", false );
				case TFClass_DemoMan:	ReplaceString( strSound, sizeof(strSound), "demoman_", "demoman_mvm_", false );
				case TFClass_Medic:		ReplaceString( strSound, sizeof(strSound), "medic_", "medic_mvm_", false );
				case TFClass_Heavy:		ReplaceString( strSound, sizeof(strSound), "heavy_", "heavy_mvm_", false );
				case TFClass_Pyro:		ReplaceString( strSound, sizeof(strSound), "pyro_", "pyro_mvm_", false );
				case TFClass_Spy:		ReplaceString( strSound, sizeof(strSound), "spy_", "spy_mvm_", false );
				case TFClass_Engineer:	ReplaceString( strSound, sizeof(strSound), "engineer_", "engineer_mvm_", false );
				default:				return Plugin_Continue;
			}
		}
		if( StrContains( strSound, "_mvm_m_", false ) > -1 )
			ReplaceString( strSound, sizeof( strSound ), "vo/", "vo/mvm/mght/", false );
		else
			ReplaceString( strSound, sizeof( strSound ), "vo/", "vo/mvm/norm/", false );
		ReplaceString( strSound, sizeof( strSound ), ".wav", ".mp3", false );
		
		decl String:strSoundCheck[PLATFORM_MAX_PATH];
		Format( strSoundCheck, sizeof(strSoundCheck), "sound/%s", strSound );
		if( !FileExists(strSoundCheck) )
		{
			PrintToServer( "Missing sound: %s", strSound );
			return Plugin_Stop;
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Menu_Classes( Handle:hMenu, MenuAction:nAction, iClient, nMenuItem )
{
	if( nAction == MenuAction_Select ) 
	{
		decl String:strSelection[32];
		GetMenuItem( hMenu, nMenuItem, strSelection, sizeof(strSelection) );
		
		if( bRandomizer )
		{
			if( StrEqual( strSelection, "random_attack", false ) )
			{
				new TFClassType:iClass[5] = {TFClass_Scout,TFClass_Soldier,TFClass_DemoMan,TFClass_Heavy,TFClass_Pyro};
				iRobotClass[iClient] = iClass[GetRandomInt(0,sizeof(iClass)-1)];
				SetClassVariant( iClient, iRobotClass[iClient], -2 );
			}
			else if( StrEqual( strSelection, "random_support", false ) )
			{
				new TFClassType:iClass[4] = {TFClass_Sniper,TFClass_Medic,TFClass_Spy,TFClass_Engineer};
				iRobotClass[iClient] = iClass[GetRandomInt(0,sizeof(iClass)-(CanPlayEngineer(iClient)?1:2))];
				SetClassVariant( iClient, iRobotClass[iClient], -3 );
			}
			else
			{
				iRobotClass[iClient] = TFClassType:GetRandomInt(1,(CanPlayEngineer(iClient)?9:8));
				SetClassVariant( iClient, iRobotClass[iClient], PickRandomClassVariant( iRobotClass[iClient] ) );
			}
		}
		else
			ShowClassMenu( iClient, TFClassType:StringToInt( strSelection ) );
	}
	else if( nAction == MenuAction_Cancel ) 
	{
		if( nMenuItem == MenuCancel_ExitBack )
			ShowClassMenu( iClient );
	}
	else if( nAction == MenuAction_End )
		CloseHandle( hMenu );
}
public Menu_ClassVariants( Handle:hMenu, MenuAction:nAction, iClient, nMenuItem )
{
	if( nAction == MenuAction_Select ) 
	{
		decl String:strSelection[32];
		GetMenuItem( hMenu, nMenuItem, strSelection, sizeof(strSelection) );
		
		decl String:strBuffer[2][32];
		ExplodeString( strSelection, "_", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]) );
		
		if( StrEqual( strBuffer[0], "scout", false ) )
			iRobotClass[iClient] = TFClass_Scout;
		else if( StrEqual( strBuffer[0], "sniper", false ) )
			iRobotClass[iClient] = TFClass_Sniper;
		else if( StrEqual( strBuffer[0], "soldier", false ) )
			iRobotClass[iClient] = TFClass_Soldier;
		else if( StrEqual( strBuffer[0], "demo", false ) )
			iRobotClass[iClient] = TFClass_DemoMan;
		else if( StrEqual( strBuffer[0], "medic", false ) )
			iRobotClass[iClient] = TFClass_Medic;
		else if( StrEqual( strBuffer[0], "heavy", false ) )
			iRobotClass[iClient] = TFClass_Heavy;
		else if( StrEqual( strBuffer[0], "pyro", false ) )
			iRobotClass[iClient] = TFClass_Pyro;
		else if( StrEqual( strBuffer[0], "spy", false ) )
			iRobotClass[iClient] = TFClass_Spy;
		else if( StrEqual( strBuffer[0], "engineer", false ) )
			iRobotClass[iClient] = TFClass_Engineer;
		else
		{
			ShowClassMenu( iClient );
			return;
		}
		new bool:bGiants = false, iVariant = StringToInt(strBuffer[1]);
		if( iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red ) )
			bGiants = true;
		if(
			!bMyLoadouts 
			&&
			iVariant == -1
			||
			iVariant > -1
			&&
			(
				bRandomizer
				||
				iRobotClass[iClient] == TFClass_Engineer
				&&
				!CanPlayEngineer(iClient)
				||
				!bGiants
				&&
				(
					iRobotMode[iClient] == Robot_BigNormal
					||
					iRobotMode[iClient] == Robot_Giant
				)
			)
			||
			iRobotClass[iClient] == TFClass_DemoMan
			&&
			iVariant == SENTRYBUSTER_CLASSVARIANT
			&&
			!CheckCommandAccess( iClient, "tf2bwr_sentrybuster", 0, true )
		)
			iVariant = PickRandomClassVariant( iRobotClass[iClient] );
		SetClassVariant( iClient, iRobotClass[iClient], iVariant );
	}
	else if( nAction == MenuAction_Cancel ) 
	{
		if( nMenuItem == MenuCancel_ExitBack )
			ShowClassMenu( iClient );
	}
	else if( nAction == MenuAction_End )
		CloseHandle( hMenu );
}

stock PrecacheMdl( const String:strModel[PLATFORM_MAX_PATH], bool:bPreload = false )
{
	if( FileExists( strModel, true ) || FileExists( strModel, false ) )
		if( !IsModelPrecached( strModel ) )
			return PrecacheModel( strModel, bPreload );
	return -1;
}
stock PrecacheSnd( const String:strSample[PLATFORM_MAX_PATH], bool:bPreload = false, bool:bForceCache = false )
{
	decl String:strSound[PLATFORM_MAX_PATH];
	strcopy( strSound, sizeof(strSound), strSample );
	if( strSound[0] == ')' || strSound[0] == '^' || strSound[0] == ']' )
		strcopy( strSound, sizeof(strSound), strSound[1] );
	Format( strSound, sizeof(strSound), "sound/%s", strSound );
	if( FileExists( strSound, true ) || FileExists( strSound, false ) )
	{
		if( bForceCache || !IsSoundPrecached( strSample ) )
			return PrecacheSound( strSample, bPreload );
	}
	else if( strSound[0] != ')' && strSound[0] != '^' && strSound[0] != ']' )
		PrintToServer( "Missing sound file: %s", strSample );
	return -1;
}
stock EmitSoundToClients( const String:strSample[PLATFORM_MAX_PATH] )
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) )
			EmitSoundToClient( i, strSample );
}
stock StopSnd( iClient, iChannel = SNDCHAN_AUTO, const String:strSample[PLATFORM_MAX_PATH] )
{
	if( !IsValidEntity(iClient) )
		return;
	StopSound( iClient, iChannel, strSample );
}

stock FinishDeploying()
{
	GameRules_SetProp( "m_bPlayingMannVsMachine", 1 );
	
	if( IsValidClient(iDeployingBomb) )
		ForcePlayerSuicide( iDeployingBomb );
	iDeployingBomb = -1;
}

stock CheckTeamBalance( bool:bAutoBalance = false, iClient = 0 )
{
	new iNumDefenders = GetTeamPlayerCount( _:TFTeam_Red );
	new iNumHumanRobots = GetTeamPlayerCount( _:TFTeam_Blue );
	new bool:bCanJoinRED = ( iMaxDefenders <= 0 || iNumDefenders < iMaxDefenders );
	new bool:bEnoughRED = ( iMinDefenders <= 0 || iNumDefenders >= iMinDefenders );
	new bool:bCanJoinBLU = ( bEnoughRED && ( iMaxDefenders <= 0 || iNumHumanRobots < ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) ) );
	
	/*
	PrintToServer( "iNumDefenders: %d", iNumDefenders );
	PrintToServer( "iNumHumanRobots: %d", iNumHumanRobots );
	PrintToServer( "bCanJoinRED: %d", bCanJoinRED );
	PrintToServer( "bEnoughRED: %d", bEnoughRED );
	PrintToServer( "bCanJoinBLU: %d", bCanJoinBLU );
	*/
	
	if( !bEnoughRED )
	{
		for( new i = 0; i < ( bAutoBalance ? iMinDefenders - iNumDefenders : 1 ); i++ )
		{
			if( bAutoBalance )
				iClient = PickRandomPlayer( TFTeam_Blue );
			if( iClient && TFTeam:GetClientTeam(iClient) == TFTeam_Blue )
			{
				if( bCanJoinRED )
					Timer_TurnHuman( INVALID_HANDLE, GetClientUserId( iClient ) );
				else
					Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( iClient ) );
				PrintToChat( iClient, "You are moved to the other team for game balance" );
			}
		}
		return 1;
	}
	else if( iMaxDefenders > 0 )
	{
		new bool:bOverlimit = ( iNumHumanRobots > ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) );
		if( bOverlimit )
		{
			for( new i = 0; i < ( bAutoBalance ? iNumHumanRobots - ( TF_MVM_MAX_PLAYERS - iMaxDefenders ) : 1 ); i++ )
			{
				if( bAutoBalance )
					iClient = PickRandomPlayer( TFTeam_Blue );
				if( iClient && TFTeam:GetClientTeam(iClient) != TFTeam_Blue )
				{
					if( bCanJoinRED )
						Timer_TurnHuman( INVALID_HANDLE, GetClientUserId( iClient ) );
					else
						Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( iClient ) );
					PrintToChat( iClient, "You are moved to the other team for game balance" );
				}
			}
			return 2;
		}
		bOverlimit = ( iNumDefenders > iMaxDefenders );
		if( bOverlimit )
		{
			for( new i = 0; i < ( bAutoBalance ? iNumDefenders - iMaxDefenders : 1 ); i++ )
			{
				if( bAutoBalance )
					iClient = PickRandomPlayer( TFTeam_Red );
				if( iClient && TFTeam:GetClientTeam(iClient) == TFTeam_Red )
				{
					if( bCanJoinBLU )
						Timer_TurnRobot( INVALID_HANDLE, GetClientUserId( iClient ) );
					else
						Timer_TurnSpec( INVALID_HANDLE, GetClientUserId( iClient ) );
					PrintToChat( iClient, "You are moved to the other team for game balance" );
				}
			}
			return 3;
		}
	}
	
	return 0;
}

stock PickRandomPlayer( TFTeam:iTeam = TFTeam_Unassigned )
{
	new target_list[MaxClients];
	new target_count = 0;
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) )
			if( iTeam == TFTeam_Unassigned || TFTeam:GetClientTeam( i ) == iTeam )
				target_list[target_count++] = i;
	return ( target_count ? target_list[GetRandomInt(0,target_count-1)] : 0 );
}

stock PickRandomRobot( iClient, bool:bChangeClass = true )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return;
	
	if( GameRules_GetRoundState() == RoundState_RoundRunning && iRobotMode[iClient] != Robot_SentryBuster && GetRandomInt(0,9) == 0 && CheckCommandAccess( iClient, "tf2bwr_sentrybuster", 0, true ) )
	{
		new iSentry = -1, nSentries = 0;
		while( ( iSentry = FindEntityByClassname( iSentry, "obj_sentrygun" ) ) != -1 )
			if( GetEntProp( iSentry, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
				nSentries++;
		if( GetRandomInt(0,1) && GetRandomInt(1,3) >= nSentries )
		{
			SetClassVariant( iClient, TFClass_DemoMan, SENTRYBUSTER_CLASSVARIANT );
			return;
		}
	}
	
	new TFClassType:iClass = iRobotClass[iClient];
	if( !bChangeClass && iClass == TFClass_Unknown )
		iClass = TF2_GetPlayerClass( iClient );
	if( bChangeClass || iClass == TFClass_Unknown )
		if( iSelectedVariant[iClient] == -2 )
		{
			new TFClassType:iValidClass[5] = {TFClass_Scout,TFClass_Soldier,TFClass_DemoMan,TFClass_Heavy,TFClass_Pyro};
			iClass = iValidClass[GetRandomInt(0,sizeof(iValidClass)-1)];
		}
		else if( iSelectedVariant[iClient] == -3 )
		{
			new TFClassType:iValidClass[4] = {TFClass_Sniper,TFClass_Medic,TFClass_Spy,TFClass_Engineer};
			iClass = iValidClass[GetRandomInt(0,sizeof(iValidClass)-(CanPlayEngineer(iClient)?1:2))];
		}
		else
			iClass = TFClassType:GetRandomInt(6,8);
	iRobotClass[iClient] = iClass;
	SetClassVariant( iClient, iRobotClass[iClient], ( iSelectedVariant[iClient] >= -3 && iSelectedVariant[iClient] < -1 ? iSelectedVariant[iClient] : PickRandomClassVariant( iRobotClass[iClient] ) ) );
}
stock PickRandomClassVariant( TFClassType:iClass = TFClass_Unknown )
{
	new bool:bGiants = false;
	if( iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red ) )
		bGiants = true;
	switch( iClass )
	{
#if defined HIDDEN_CODE
		case TFClass_Scout:		return !bGiants ? GetRandomInt(0,4) : GetRandomInt(0,8);
		case TFClass_Soldier:	return !bGiants ? GetRandomInt(0,4) : GetRandomInt(0,9);
		case TFClass_DemoMan:	return !bGiants ? GetRandomInt(0,1) : GetRandomInt(0,6);
		case TFClass_Pyro:		return !bGiants ? GetRandomInt(0,2) : GetRandomInt(0,6);
		case TFClass_Heavy:		return !bGiants ? GetRandomInt(0,5) : GetRandomInt(0,11);
#else
		case TFClass_Scout:		return !bGiants ? GetRandomInt(0,4) : GetRandomInt(0,7);
		case TFClass_Soldier:	return !bGiants ? GetRandomInt(0,4) : GetRandomInt(0,7);
		case TFClass_DemoMan:	return !bGiants ? GetRandomInt(0,1) : GetRandomInt(0,4);
		case TFClass_Pyro:		return !bGiants ? GetRandomInt(0,2) : GetRandomInt(0,5);
		case TFClass_Heavy:		return !bGiants ? GetRandomInt(0,5) : GetRandomInt(0,10);
#endif
		case TFClass_Medic:		return !bGiants ? GetRandomInt(0,4) : GetRandomInt(0,5);
		case TFClass_Sniper:	return GetRandomInt(0,4);
		case TFClass_Spy:		return 0;
		case TFClass_Engineer:	return 0;
	}
	return -1;
}

stock bool:SetClassVariant( iClient, TFClassType:iClass = TFClass_Unknown, iSVariant = -1 )
{
	if( !IsMvM() || !IsValidRobot(iClient) )
		return false;
	
	if( iClass == TFClass_Unknown && ( iClass = TF2_GetPlayerClass(iClient) ) == TFClass_Unknown )
		return false;
	
	new bool:bValidVariant = false, iVariant = iSVariant, RobotMode:iMode = Robot_Normal, Effects:iNewEffect = Effect_None;
	if( bMyLoadouts && ( iVariant == -1 || iSVariant == -1 || iSVariant < -3 ) )
	{
		iRobotVariant[iClient] = -1;
		iSelectedVariant[iClient] = -1;
		PrintToChat( iClient, "* Your loadout won't be changed." );
		bValidVariant = true;
	}
	
	if( !bValidVariant )
	{
		if( iVariant < -1 || !bMyLoadouts && iVariant == -1 )
			iVariant = PickRandomClassVariant( iClass );
		
		switch( iClass )
		{
			case TFClass_Scout:
			{
				if( iVariant >= 0 && iVariant <= 8 )
				{
					bValidVariant = true;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant >= 5 )
						iMode = Robot_Giant;
				}
			}
			case TFClass_Soldier:
			{
				if( iVariant >= 0 && iVariant <= 9 )
				{
					bValidVariant = true;
					
					if( iVariant >= 1 && iVariant <= 4 )
						iNewEffect = Effect_FullCharge;
					else if( iVariant == 6 )
						iNewEffect = Effect_AlwaysCrits;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant >= 5 )
						iMode = Robot_Giant;
				}
			}
			case TFClass_DemoMan:
			{
				if( iVariant >= 0 && iVariant <= 7 )
				{
					bValidVariant = true;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant == SENTRYBUSTER_CLASSVARIANT )
						iMode = Robot_SentryBuster;
					else if( iVariant == 4 )
						iMode = Robot_BigNormal;
					else if( iVariant >= 2 )
						iMode = Robot_Giant;
				}
			}
			case TFClass_Pyro:
			{
				if( iVariant >= 0 && iVariant <= 6 )
				{
					bValidVariant = true;
					
					if( iVariant == 2 )
						iNewEffect = Effect_AlwaysCrits;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant >= 3 )
						iMode = Robot_Giant;
				}
			}
			case TFClass_Heavy:
			{
				if( iVariant >= 0 && iVariant <= 11 )
				{
					bValidVariant = true;
					
					if( iVariant == 1 )
						iNewEffect = Effect_AlwaysCrits;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant == 5 || iVariant == 11 )
						iMode = Robot_BigNormal;
					else if( iVariant >= 6 )
						iMode = Robot_Giant;
				}
			}
			case TFClass_Medic:
			{
				if( iVariant >= 0 && iVariant <= 5 )
				{
					bValidVariant = true;
					
					if( iVariant < 3 || iVariant > 4 )
						iNewEffect = Effect_FullCharge;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
					else if( iVariant == 5 )
						iMode = Robot_Giant;
				}
			}
			case TFClass_Sniper:
			{
				if( iVariant >= 0 && iVariant <= 4 )
				{
					bValidVariant = true;
					
					if( iVariant == 0 )
						iMode = Robot_Stock;
				}
			}
			case TFClass_Spy:
			{
				if( iVariant == 0 )
				{
					bValidVariant = true;
					
					iMode = Robot_Stock;
					
					iNewEffect = Effect_AlwaysInvisible;
				}
			}
			case TFClass_Engineer:
			{
				if( iVariant == 0 )
				{
					bValidVariant = true;
					
					iMode = Robot_Stock;
				}
			}
		}
	}
	
	
	if( bValidVariant )
	{
		new bool:bAlive = IsPlayerAlive( iClient );
		if( bAlive && !bInRespawn[iClient] )
			ForcePlayerSuicide( iClient );
		else if( !bAlive && iRespawnTimeBLU >= 0 )
			CreateTimer( float(iRespawnTimeBLU), Timer_Respawn, GetClientUserId(iClient) );
		
		iRobotMode[iClient] = iMode;
		iEffect[iClient] = iNewEffect;
		iRobotVariant[iClient] = iVariant;
		iSelectedVariant[iClient] = ( iSVariant < -1 && bRandomizer /*|| iVariant == -1*/ ? iSVariant : iVariant );
		
		if( iClass != TF2_GetPlayerClass(iClient) )
			TF2_SetPlayerClass( iClient, iClass, true );
		if( bRandomizer )
			iRobotClass[iClient] = iClass;
		
		if( bAlive && bInRespawn[iClient] )
		{
			bSkipSpawnEventMsg[iClient] = true;
			TF2_RespawnPlayer( iClient );
		}
	}
	
	return bValidVariant;
}

stock SentryBuster_Explode( iClient )
{
	if( !IsMvM() || !IsValidRobot(iClient) || iRobotMode[iClient] != Robot_SentryBuster || !IsPlayerAlive(iClient) )
		return;
	
	CreateTimer( 2.0, Timer_SentryBuster_Explode, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE );
	
	SetEntProp( iClient, Prop_Data, "m_takedamage", 0, 1 );
	//SetEntityHealth( iClient, 1 );
	
	StopSnd( iClient, SNDCHAN_STATIC, SENTRYBUSTER_SND_LOOP );
	PrecacheSnd( SENTRYBUSTER_SND_SPIN );
	EmitSoundToAll( SENTRYBUSTER_SND_SPIN, iClient, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN );
}

stock FindRandomSpawnPoint( iType )
{
	new Handle:hSpawnPoint = CreateArray();
	new String:strSpawnName[64], iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "info_player_teamspawn") ) != -1 )
		if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
		{
			GetEntPropString( iEnt, Prop_Data, "m_iName", strSpawnName, sizeof(strSpawnName) );
			if( StrEqual( strSpawnName, "spawnbot_mission_sniper" ) )
			{
				if( iType == Spawn_Sniper )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( StrEqual( strSpawnName, "spawnbot_mission_spy" ) )
			{
				if( iType == Spawn_Spy )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( iType == Spawn_Giant && StrEqual( strSpawnName, "spawnbot_giant" ) )
			{
				if( iType == Spawn_Giant )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else if( StrEqual( strSpawnName, "spawnbot_lower" ) )
			{
				if( iType == Spawn_Lower )
					PushArrayCell( hSpawnPoint, iEnt );
			}
			else
			{
				if( iType == Spawn_Normal )
					PushArrayCell( hSpawnPoint, iEnt );
			}
		}
	if( GetArraySize(hSpawnPoint) > 0 )
		return GetArrayCell( hSpawnPoint, GetRandomInt(0,GetArraySize(hSpawnPoint)-1) );
	return -1;
}

stock ResetData( iClient, bool:bFullReset = false )
{
	if( iClient < 0 || iClient >= MAXPLAYERS )
		return;
	
	iRobotClass[iClient] = TFClass_Unknown;
	iRobotMode[iClient] = Robot_Normal;
	if( IsValidClient(iClient) && TF2_GetPlayerClass(iClient) == TFClass_Spy )
		if( iRobotVariant[iClient] )
			iEffect[iClient] = Effect_AlwaysInvisible;
		else
			iEffect[iClient] = Effect_Invisible;
	else
		iEffect[iClient] = Effect_None;
	iRobotVariant[iClient] = 0;
	iSelectedVariant[iClient] = 0;
	if( bFullReset )
	{
		bInRespawn[iClient] = false;
		bFreezed[iClient] = false;
		flNextChangeTeam[iClient] = 0.0;
		bSkipSpawnEventMsg[iClient] = false;
		bSkipInvAppEvent[iClient] = false;
		bStripItems[iClient] = false;
	}
	if( hTimer_SentryBuster_Beep[iClient] != INVALID_HANDLE )
		KillTimer( hTimer_SentryBuster_Beep[iClient] );
	hTimer_SentryBuster_Beep[iClient] = INVALID_HANDLE;
}

stock DestroyBuildings( iClient )
{
	decl String:strObjects[3][] = {"obj_sentrygun","obj_dispenser","obj_teleporter"};
	for( new o = 0; o < sizeof(strObjects); o++ )
	{
		new iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, strObjects[o] ) ) != -1 )
			if( IsValidEdict(iEnt) && GetEntPropEnt( iEnt, Prop_Send, "m_hBuilder" ) == iClient && GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
			{
				SetEntityHealth( iEnt, 100 );
				SetVariantInt( 1488 );
				AcceptEntityInput( iEnt, "RemoveHealth" );
			}
	}
}

stock StripItems( iClient )
{
	if( !IsValidClient( iClient ) || IsFakeClient( iClient ) || !IsPlayerAlive( iClient ) )
		return;
	
	for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
		TF2_RemoveWeaponSlot( iClient, iSlot );
	
	new iOwner, iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == iClient )
		{
			if( hSDKRemoveWearable != INVALID_HANDLE )
				SDKCall( hSDKRemoveWearable, iClient, iEntity );
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == iClient )
		{
			if( hSDKRemoveWearable != INVALID_HANDLE )
				SDKCall( hSDKRemoveWearable, iClient, iEntity );
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
	if( GetClientTeam(iClient) == _:TFTeam_Blue )
	{
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_powerup_bottle" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == iClient )
				AcceptEntityInput( iEntity, "Kill" );
		}
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_usableitem" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == iClient )
				AcceptEntityInput( iEntity, "Kill" );
		}
	}
}

stock FixTPose( iClient )
{
	new iWeapon = -1;
	
	if( !IsValidClient(iClient) || !IsPlayerAlive(iClient) )
		return iWeapon;
	
	for( new s = 0; s < _:TF2ItemSlot; s++ )
	{
		iWeapon = GetPlayerWeaponSlot( iClient, s );
		if( IsValidEdict( iWeapon ) )
		{
			EquipPlayerWeapon( iClient, iWeapon );
			return iWeapon;
		}
	}
	
	return iWeapon;
}

stock FixSounds( iEntity )
{
	if( iEntity <= 0 || !IsValidEntity(iEntity) )
		return;
	
	StopSnd( iEntity, _, GIANTSCOUT_SND_LOOP );
	StopSnd( iEntity, _, GIANTSOLDIER_SND_LOOP );
	StopSnd( iEntity, _, GIANTPYRO_SND_LOOP );
	StopSnd( iEntity, _, GIANTDEMOMAN_SND_LOOP );
	StopSnd( iEntity, _, GIANTHEAVY_SND_LOOP );
	StopSnd( iEntity, SNDCHAN_STATIC, SENTRYBUSTER_SND_INTRO );
	StopSnd( iEntity, SNDCHAN_STATIC, SENTRYBUSTER_SND_LOOP );
	StopSnd( iEntity, SNDCHAN_STATIC, SENTRYBUSTER_SND_SPIN );
}

stock bool:CanPlayEngineer( iClient )
{
	if( !nMaxEngineers )
		return false;
	if( nMaxEngineers < 0 )
		return true;
	if( !CheckCommandAccess( iClient, "tf2bwr_engineer", 0, true ) )
		return false;
	if( GetNumEngineers(iClient) >= nMaxEngineers )
	{
		PrintToChat( iClient, "* Too many engineers." );
		return false;
	}
	return true;
}

stock bool:CanSeeTarget( iEntity, iOther, Float:flMaxDistance = 0.0 )
{
	if( iEntity <= 0 || iOther <= 0 || !IsValidEntity(iEntity) || !IsValidEntity(iOther) )
		return false;
	
	new Float:vecStart[3];
	new Float:vecStartMaxs[3];
	new Float:vecTarget[3];
	new Float:vecTargetMaxs[3];
	new Float:vecEnd[3];
	
	GetEntPropVector( iEntity, Prop_Data, "m_vecOrigin", vecStart );
	GetEntPropVector( iEntity, Prop_Send, "m_vecMaxs", vecStartMaxs );
	GetEntPropVector( iOther, Prop_Data, "m_vecOrigin", vecTarget );
	GetEntPropVector( iOther, Prop_Send, "m_vecMaxs", vecTargetMaxs );
	
	vecStart[2] += vecStartMaxs[2] / 2.0;
	vecTarget[2] += vecTargetMaxs[2] / 2.0;
	
	if( flMaxDistance > 0.0 )
	{
		new Float:flDistance = GetVectorDistance( vecStart, vecTarget );
		if( flDistance > flMaxDistance )
		{
			BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{255,0,0,255},0.0,0);
			return false;
		}
	}
	
	iFilterEnt[0] = iEntity;
	iFilterEnt[1] = iOther;
	new Handle:hTrace = TR_TraceRayFilterEx( vecStart, vecTarget, MASK_VISIBLE, RayType_EndPoint, TraceFilter );
	if( !TR_DidHit( hTrace ) )
	{
		BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{255,255,0,255},0.0,0);
		CloseHandle( hTrace );
		return false;
	}
	
	new iHitEnt = TR_GetEntityIndex( hTrace );
	TR_GetEndPosition( vecEnd, hTrace );
	CloseHandle( hTrace );
	
	if( iHitEnt == iOther || GetVectorDistanceMeter( vecEnd, vecTarget ) <= 1.0 )
	{
		BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{0,255,0,255},0.0,0);
		return true;
	}
	
	BeamEffect(vecStart,vecEnd,6.0,5.0,5.0,{0,0,255,255},0.0,0);
	return false;
}
stock Float:GetVectorDistanceMeter( const Float:vec1[3], const Float:vec2[3], bool:squared = false )
	return ( GetVectorDistance( vec1, vec2, squared ) / 50.00 );
public bool:TraceFilter( iEntity, iContentsMask )
{
	if( iEntity == 0 || IsValidEntity(iEntity) && !IsValidEdict(iEntity) )
		return true;
	if( iEntity == iFilterEnt[0] )
		return false;
	if( iEntity == iFilterEnt[1] )
		return true;
	new String:strClassname[64];
	GetEdictClassname( iEntity, strClassname, sizeof(strClassname) ); 
	if( StrEqual( strClassname, "player", false ) || StrContains( strClassname, "obj_", false ) == 0 || StrEqual( strClassname, "tf_ammo_pack", false ) )
		return false;
	//PrintToServer( "%s - block", strClassname );
	return true;
}

stock bool:GetRobotVariantName( TFClassType:iClass, iVariant, String:strBuffer[], iBufferSize )
{
	strcopy( strBuffer, iBufferSize, "" );
	switch( iClass )
	{
		case TFClass_Scout:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Scout" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Scout" );
				case 1: strcopy( strBuffer, iBufferSize, "Bonk Scout" );
				case 2: strcopy( strBuffer, iBufferSize, "Scout with Fish" );
				case 3: strcopy( strBuffer, iBufferSize, "Minor League Scout" );
				case 4: strcopy( strBuffer, iBufferSize, "Wrap Assassin" );
				case 5: strcopy( strBuffer, iBufferSize, "Giant Scout" );
				case 6: strcopy( strBuffer, iBufferSize, "Super Scout" );
				case 7: strcopy( strBuffer, iBufferSize, "Major League Scout" );
				case 8: strcopy( strBuffer, iBufferSize, "Major League" );
			}
		}
		case TFClass_Sniper:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Sniper" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Sniper" );
				case 1: strcopy( strBuffer, iBufferSize, "Razorback Sniper" );
				case 2: strcopy( strBuffer, iBufferSize, "Sydney Sniper" );
				case 3: strcopy( strBuffer, iBufferSize, "Jarate Master" );
				case 4: strcopy( strBuffer, iBufferSize, "Bowman" );
			}
		}
		case TFClass_Soldier:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Soldier" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Soldier" );
				case 1: strcopy( strBuffer, iBufferSize, "Buff Soldier" );
				case 2: strcopy( strBuffer, iBufferSize, "Extended Buff Soldier" );
				case 3: strcopy( strBuffer, iBufferSize, "Extended Conch Soldier" );
				case 4: strcopy( strBuffer, iBufferSize, "Extended Backup Soldier" );
				case 5: strcopy( strBuffer, iBufferSize, "Giant Soldier" );
				case 6: strcopy( strBuffer, iBufferSize, "Giant Charged Soldier" );
				case 7: strcopy( strBuffer, iBufferSize, "Giant Rapid Fire Soldier" );
#if defined HIDDEN_CODE
				case 8: strcopy( strBuffer, iBufferSize, "Giant Burst Fire Soldier" );
				case 9: strcopy( strBuffer, iBufferSize, "Sergeant Crits" );
#endif
			}
		}
		case TFClass_DemoMan:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Demoman" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Demoman" );
				case 1: strcopy( strBuffer, iBufferSize, "Demoknight" );
				case 2: strcopy( strBuffer, iBufferSize, "Giant Rapid Fire Demoman" );
				case 3: strcopy( strBuffer, iBufferSize, "Giant Demoman" );
				case 4: strcopy( strBuffer, iBufferSize, "Giant Demoknight" );
#if defined HIDDEN_CODE
				case 5: strcopy( strBuffer, iBufferSize, "Major Bomber" );
				case 6: strcopy( strBuffer, iBufferSize, "Chief Tavish" );
#endif
				case SENTRYBUSTER_CLASSVARIANT: strcopy( strBuffer, iBufferSize, "Sentry Buster" );
			}
		}
		case TFClass_Medic:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Medic" );
				case 0: strcopy( strBuffer, iBufferSize, "Uber Medic" );
				case 1: strcopy( strBuffer, iBufferSize, "QuickUber Medic" );
				case 2: strcopy( strBuffer, iBufferSize, "SlowUber Medic" );
				case 3: strcopy( strBuffer, iBufferSize, "Quick-Fix Medic" );
				case 4: strcopy( strBuffer, iBufferSize, "BigHeal Medic" );
				case 5: strcopy( strBuffer, iBufferSize, "Giant Medic" );
			}
		}
		case TFClass_Heavy:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Heavy" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Heavy" );
				case 1: strcopy( strBuffer, iBufferSize, "Heavy Mittens" );
				case 2: strcopy( strBuffer, iBufferSize, "Steel Gauntlet" );
				case 3: strcopy( strBuffer, iBufferSize, "Heavyweight Champ" );
				case 4: strcopy( strBuffer, iBufferSize, "Fast Heavyweight Champ" );
				case 5: strcopy( strBuffer, iBufferSize, "Super Heavyweight Champ" );
				case 6: strcopy( strBuffer, iBufferSize, "Giant Heavy (Sascha)" );
				case 8: strcopy( strBuffer, iBufferSize, "Giant Heavy (BrassBeast)" );
				case 9: strcopy( strBuffer, iBufferSize, "Giant Heavy (Natascha)" );
				case 7: strcopy( strBuffer, iBufferSize, "Giant Deflector Heavy" );
				case 10: strcopy( strBuffer, iBufferSize, "Giant Heater Heavy" );
#if defined HIDDEN_CODE
				case 11: strcopy( strBuffer, iBufferSize, "Captain Punch" );
#endif
			}
		}
		case TFClass_Pyro:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Pyro" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Pyro" );
				case 1: strcopy( strBuffer, iBufferSize, "Flare Pyro" );
				case 2: strcopy( strBuffer, iBufferSize, "Pyro Pusher" );
				case 3: strcopy( strBuffer, iBufferSize, "Giant Pyro" );
				case 4: strcopy( strBuffer, iBufferSize, "Giant Flare Pyro" );
				case 5: strcopy( strBuffer, iBufferSize, "Giant Airblast Pyro" );
#if defined HIDDEN_CODE
				case 6: strcopy( strBuffer, iBufferSize, "Chief Pyro" );
#endif
			}
		}
		case TFClass_Spy:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Spy" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Spy" );
			}
		}
		case TFClass_Engineer:
		{
			switch( iVariant )
			{
				case -1: strcopy( strBuffer, iBufferSize, "Your own Engineer" );
				case 0: strcopy( strBuffer, iBufferSize, "Normal Engineer" );
			}
		}
	}
	return strlen(strBuffer) > 0;
}
stock bool:GetClassName( TFClassType:iClass, String:strBuffer[], iBufferSize )
{
	strcopy( strBuffer, iBufferSize, "" );
	switch( iClass )
	{
		case TFClass_Scout:		strcopy( strBuffer, iBufferSize, "scout" );
		case TFClass_Sniper:	strcopy( strBuffer, iBufferSize, "sniper" );
		case TFClass_Soldier:	strcopy( strBuffer, iBufferSize, "soldier" );
		case TFClass_DemoMan:	strcopy( strBuffer, iBufferSize, "demo" );
		case TFClass_Medic:		strcopy( strBuffer, iBufferSize, "medic" );
		case TFClass_Heavy:		strcopy( strBuffer, iBufferSize, "heavy" );
		case TFClass_Pyro:		strcopy( strBuffer, iBufferSize, "pyro" );
		case TFClass_Spy:		strcopy( strBuffer, iBufferSize, "spy" );
		case TFClass_Engineer:	strcopy( strBuffer, iBufferSize, "engineer" );
	}
	return strlen(strBuffer) > 0;
}

stock ShowClassPanel( iClient )
{
	if( !IsValidClient(iClient) || IsFakeClient(iClient) )
		return;
	
	ShowVGUIPanel( iClient, GetClientTeam(iClient) == _:TFTeam_Red ? "class_red" : "class_blue" );
}

stock ShowClassMenu( iClient, TFClassType:iClass = TFClass_Unknown )
{
	if( !IsValidClient( iClient ) )
		return;
	new Handle:hMenu, bool:bGiants = false, i;
	decl String:strVariantID[16], String:strVariantName[32];
	if( iMinDefenders4Giants <= GetTeamPlayerCount( _:TFTeam_Red ) )
		bGiants = true;
	if( iClass <= TFClass_Unknown || iClass >= TFClassType )
		hMenu = CreateMenu( Menu_Classes );
	else
		hMenu = CreateMenu( Menu_ClassVariants );
	SetMenuTitle( hMenu, "Select Variant:" );
	SetMenuExitBackButton( hMenu, false );
	SetMenuExitButton( hMenu, true );
	switch( iClass )
	{
		case TFClass_Scout:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "scout_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 4 : 7 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "scout_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "scout_", "Random variant" );
		}
		case TFClass_Sniper:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "sniper_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= 4; i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "sniper_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "sniper_", "Random variant" );
		}
		case TFClass_Soldier:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "soldier_-1", "My loadout" );
			if( !bRandomizer )
			{
				for( i = 0; i <= ( !bGiants ? 4 : 7 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "soldier_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			}
			else
				AddMenuItem( hMenu, "soldier_", "Random variant" );
		}
		case TFClass_DemoMan:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "demo_-1", "My loadout" );
			if( !bRandomizer )
			{
				for( i = 0; i <= ( !bGiants ? 1 : 4 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "demo_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
				AddMenuItem( hMenu, "demo_5", "Sentry Buster" );
			}
			else
				AddMenuItem( hMenu, "demo_", "Random variant" );
		}
		case TFClass_Medic:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "medic_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 4 : 5 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "medic_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "medic_", "Random variant" );
		}
		case TFClass_Heavy:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "heavy_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 5 : 11 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "heavy_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "heavy_", "Random variant" );
		}
		case TFClass_Pyro:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "pyro_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= ( !bGiants ? 2 : 6 ); i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "pyro_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "pyro_", "Random variant" );
		}
		case TFClass_Spy:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "spy_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= 0; i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "spy_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "spy_", "Random variant" );
		}
		case TFClass_Engineer:
		{
			if( bMyLoadouts )
				AddMenuItem( hMenu, "engineer_-1", "My loadout" );
			if( !bRandomizer )
				for( i = 0; i <= 0; i++ )
				{
					Format( strVariantID, sizeof(strVariantID), "engineer_%d", i );
					GetRobotVariantName( iClass, i, strVariantName, sizeof(strVariantName) );
					AddMenuItem( hMenu, strVariantID, strVariantName );
				}
			else
				AddMenuItem( hMenu, "engineer_", "Random variant" );
		}
		default:
		{
			SetMenuTitle( hMenu, "Select Class:" );
			if( bRandomizer )
			{
				AddMenuItem( hMenu, "random_any",		"Random Robot" );
				AddMenuItem( hMenu, "random_attack",	"Attack Robot" );
				AddMenuItem( hMenu, "random_support",	"Support Robot" );
				if( bMyLoadouts )
				{
					AddMenuItem( hMenu, "scout_-1",			"My Own Scout" );
					AddMenuItem( hMenu, "soldier_-1",		"My Own Soldier" );
					AddMenuItem( hMenu, "pyro_-1",			"My Own Pyro" );
					AddMenuItem( hMenu, "demo_-1",			"My Own Demoman" );
					AddMenuItem( hMenu, "heavy_-1",			"My Own Heavy" );
					AddMenuItem( hMenu, "medic_-1",			"My Own Medic" );
					AddMenuItem( hMenu, "sniper_-1",		"My Own Sniper" );
					AddMenuItem( hMenu, "spy_-1",			"My Own Spy" );
					if( CanPlayEngineer(iClient) )
						AddMenuItem( hMenu, "engineer_-1",	"My Own Engineer" );
				}
			}
			else
			{
				AddMenuItem( hMenu, "1", "Scout" );
				AddMenuItem( hMenu, "3", "Soldier" );
				AddMenuItem( hMenu, "7", "Pyro" );
				AddMenuItem( hMenu, "4", "Demo" );
				AddMenuItem( hMenu, "6", "Heavy" );
				AddMenuItem( hMenu, "5", "Medic" );
				AddMenuItem( hMenu, "2", "Sniper" );
				AddMenuItem( hMenu, "8", "Spy" );
				if( CanPlayEngineer(iClient) )
					AddMenuItem( hMenu, "9", "Engineer" );
			}
		}
	}
	DisplayMenu( hMenu, iClient, MENU_TIME_FOREVER );
}

stock SetRobotModel( iClient, const String:strModel[PLATFORM_MAX_PATH] = "" )
{
	if( !IsValidClient( iClient ) || IsFakeClient( iClient ) || !IsPlayerAlive( iClient ) )
		return;
	
	if( strlen(strModel) > 2 )
		PrecacheMdl( strModel );
	
	SetVariantString( strModel );
	AcceptEntityInput( iClient, "SetCustomModel" );
	SetEntProp( iClient, Prop_Send, "m_bUseClassAnimations", 1 );
}

stock CreateParticle( Float:flOrigin[3], const String:strParticle[], Float:flDuration = -1.0 )
{
	new iParticle = CreateEntityByName( "info_particle_system" );
	if( IsValidEdict( iParticle ) )
	{
		DispatchKeyValue( iParticle, "effect_name", strParticle );
		DispatchSpawn( iParticle );
		TeleportEntity( iParticle, flOrigin, NULL_VECTOR, NULL_VECTOR );
		ActivateEntity( iParticle );
		AcceptEntityInput( iParticle, "Start" );
		if( flDuration >= 0.0 )
			CreateTimer( flDuration, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
	}
	return iParticle;
}

stock TF2_PlayAnimation( iClient, iEvent, nData = 0 )
{
	if( !IsMvM() || !IsValidClient( iClient ) || !IsPlayerAlive( iClient ) || !( GetEntityFlags( iClient ) & FL_ONGROUND ) )
		return;
	
	TE_Start( "PlayerAnimEvent" );
	TE_WriteNum( "m_iPlayerIndex", iClient );
	TE_WriteNum( "m_iEvent", iEvent );
	TE_WriteNum( "m_nData", nData );
	TE_SendToAll();
}

stock SpawnItem( iClient, iItemDefID, &Handle:hNewAttributes = INVALID_HANDLE )
{
#if defined _tf2spawnitem_included
	if( bUseTF2SI )
		return TF2_SpawnItem( iClient, iItemDefID, 6, 1, hNewAttributes, 1 );
#endif
	
	new iEntity = -1;
	
	if( !IsValidClient(iClient) || !TF2II_IsValidItemID( iItemDefID ) )
		return iEntity;
	
	new iQuality = 6;
	if( TF2II_IsBaseItem( iItemDefID ) )
		iQuality = 0;
	
	new String:strClassname[96];
	TF2II_GetItemClass( iItemDefID, strClassname, sizeof(strClassname), TF2_GetPlayerClass(iClient) );
	
	new bool:bWearable = StrContains( strClassname, "tf_wearable", false ) > -1;
	
	new Handle:hAttributes = TF2II_GetItemAttributes( iItemDefID );
	if( hAttributes == INVALID_HANDLE )
		hAttributes = CreateArray();
	if( hNewAttributes != INVALID_HANDLE )
	{
		for( new a = 0; a < RoundToFloor( float( GetArraySize( hNewAttributes ) ) / 2.0 ); a++ )
		{
			PushArrayCell( hAttributes, GetArrayCell( hNewAttributes, a * 2 ) );
			PushArrayCell( hAttributes, GetArrayCell( hNewAttributes, a * 2 + 1 ) );
		}
		CloseHandle( hNewAttributes );
		hNewAttributes = INVALID_HANDLE;
	}
	new nAttributes = RoundToFloor( float( GetArraySize( hAttributes ) ) / 2.0 );
	if( nAttributes > 15 )
		nAttributes = 15;
	
	new Handle:hItem = TF2Items_CreateItem( StrEqual( strClassname, "saxxy", false ) ? OVERRIDE_ALL : OVERRIDE_ALL|FORCE_GENERATION );
	TF2Items_SetClassname( hItem, strClassname );
	TF2Items_SetItemIndex( hItem, iItemDefID );
	TF2Items_SetQuality( hItem, iQuality );
	TF2Items_SetLevel( hItem, 1 );
	TF2Items_SetNumAttributes( hItem, nAttributes );
	if( nAttributes )
		for( new a = 0; a < nAttributes; a++ )
			TF2Items_SetAttribute( hItem, a, GetArrayCell( hAttributes, a * 2 ), Float:GetArrayCell( hAttributes, a * 2 + 1 ) );
	CloseHandle( hAttributes );
	
	iEntity = TF2Items_GiveNamedItem( iClient, hItem );
	CloseHandle( hItem );
	
	if( IsValidEdict( iEntity ) )
		if( bWearable )
		{
			if( hSDKEquipWearable != INVALID_HANDLE )
				SDKCall( hSDKEquipWearable, iClient, iEntity );
		}
		else
			EquipPlayerWeapon( iClient, iEntity );
	
	return iEntity;
}

stock IsMvM( bool:bRecalc = false )
{
	static bool:bChecked = false;
	static bool:bMannVsMachines = false;
	
	if( bRecalc || !bChecked )
	{
		new iEnt = FindEntityByClassname( -1, "tf_logic_mann_vs_machine" );
		bMannVsMachines = ( iEnt > MaxClients && IsValidEntity( iEnt ) );
		bChecked = true;
	}
	
	return bMannVsMachines;
}

stock FindIntInArray( iArray[], iSize, iItem )
{
	for( new i = 0; i < iSize; i++ )
		if( iArray[i] == iItem )
			return i;
	return -1;
}
stock FindStrInArray( const String:strArray[][], iSize, const String:strItem[] )
{
	if( strlen(strItem) > 0 )
		for( new i = 0; i < iSize; i++ )
			if( !strcmp( strArray[i], strItem, false ) )
				return i;
	return -1;
}

stock GetTeamPlayerCount( iTeamNum = -1 )
{
	new iCounter = 0;
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient( i ) && !IsFakeClient( i ) && ( iTeamNum == -1 || GetClientTeam( i ) == iTeamNum ) )
			iCounter++;
	return iCounter;
}
stock GetNumEngineers( iClient = 0 )
{
	new iCounter = 0;
	for( new i = 1; i <= MaxClients; i++ )
		if( iClient != i && IsValidRobot( i ) && !IsFakeClient( i ) && TF2_GetPlayerClass( i ) == TFClass_Engineer )
			iCounter++;
	return iCounter;
}

stock BeamEffect(Float:startvec[3],Float:endvec[3],Float:life,Float:width,Float:endwidth,const color[4],Float:amplitude,speed)
{
	if( !bSentryBusterDebug ) return;
	TE_SetupBeamPoints(startvec,endvec,iLaserModel,0,0,66,life,width,endwidth,0,amplitude,color,speed);
	TE_SendToAll();
} 

stock DealDamage( victim, damage, attacker = 0, dmg_type = 0 )
{
	if( victim > 0 && IsValidEntity(victim) && ( victim > MaxClients || IsClientInGame(victim) && IsPlayerAlive(victim) ) && damage > 0 )
	{
		new String:dmg_str[16];
		IntToString(damage, dmg_str, 16);
		
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);

		new pointHurt = CreateEntityByName("point_hurt");
		if( pointHurt )
		{
			DispatchKeyValue(victim, "targetname", "point_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "point_hurtme");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "point_donthurtme");
			AcceptEntityInput(pointHurt, "Kill");
		}
	}
}

stock bool:IsValidRobot( iClient, bool:bIgnoreBots = true )
{
	if( !IsValidClient(iClient) ) return false;
	if( GetClientTeam(iClient) != _:TFTeam_Blue ) return false;
	if( bIgnoreBots && IsFakeClient(iClient) ) return false;
	return true;
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}

stock Error( iFlags = ERROR_NONE, iNativeErrCode = SP_ERROR_NONE, const String:strMessage[], any:... )
{
	decl String:strBuffer[1024];
	VFormat( strBuffer, sizeof(strBuffer), strMessage, 4 );
	
	if( iFlags )
	{
		if( iFlags & ERROR_LOG && bUseLogs )
		{
			decl String:strFile[PLATFORM_MAX_PATH];
			FormatTime( strFile, sizeof(strFile), "%Y%m%d" );
			decl String:strTag[64];
			strcopy( strTag, sizeof(strTag), PLUGIN_TAG );
			strcopy( strTag, strlen(strTag)-2, strTag[1] );
			Format( strFile, sizeof(strFile), "TF2BWR%s", strFile );
			BuildPath( Path_SM, strFile, sizeof(strFile), "logs/%s.log", strFile );
			LogToFileEx( strFile, strBuffer );
		}
		
		if( iFlags & ERROR_BREAKF )
			ThrowError( strBuffer );
		if( iFlags & ERROR_BREAKN )
			ThrowNativeError( iNativeErrCode, strBuffer );
		if( iFlags & ERROR_BREAKP )
			SetFailState( strBuffer );
		
		if( iFlags & ERROR_NOPRINT )
			return;
	}
	
	PrintToServer( "%s %s", PLUGIN_TAG, strBuffer );
}