#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#tryinclude <tf2betheghost>
//#tryinclude <updater>

#define PLUGIN_VERSION "1.1.3"
#define PLUGIN_UPDATE_URL "http://files.xpenia.org/sourcemod/tf2btg/updatelist.txt"

#define ERROR_NONE		0		// PrintToServer only
#define ERROR_LOG		(1<<0)	// use LogToFile
#define ERROR_BREAKF	(1<<1)	// use ThrowError
#define ERROR_BREAKN	(1<<2)	// use ThrowNativeError
#define ERROR_BREAKP	(1<<3)	// use SetFailState
#define ERROR_NOPRINT	(1<<4)	// don't use PrintToServer

#define HAUNTED_COLOR 0x8650AC

/////////////
/* Globals */

static const String:strGhostModels[][64] = {
	"models/props_halloween/ghost.mdl",
	"models/props_halloween/ghost_no_hat.mdl"
};
static const String:strGhostMoans[][64] = {
	"vo/halloween_moan1.wav",
	"vo/halloween_moan2.wav",
	"vo/halloween_moan3.wav",
	"vo/halloween_moan4.wav"
};
static const String:strGhostBoos[][64] = {
	"vo/halloween_boo1.wav",
	"vo/halloween_boo2.wav",
	"vo/halloween_boo3.wav",
	"vo/halloween_boo4.wav",
	"vo/halloween_boo5.wav",
	"vo/halloween_boo6.wav",
	"vo/halloween_boo7.wav"
};
static const String:strGhostEffects[][64] = {
	"vo/halloween_haunted1.wav",
	"vo/halloween_haunted2.wav",
	"vo/halloween_haunted3.wav",
	"vo/halloween_haunted4.wav",
	"vo/halloween_haunted5.wav"
};

new Handle:fwdCanPlayAsGhost = INVALID_HANDLE;
new Handle:fwdCanBeScared = INVALID_HANDLE;

new Handle:sm_tf2btg_version = INVALID_HANDLE;
new Handle:sm_tf2btg_debug = INVALID_HANDLE;
new Handle:sm_tf2btg_notify = INVALID_HANDLE;
new Handle:sm_tf2btg_adminonly = INVALID_HANDLE;
new Handle:sm_tf2btg_scary_delay = INVALID_HANDLE;
new Handle:sm_tf2btg_scary_distance = INVALID_HANDLE;
new Handle:sm_tf2btg_scary_distance_admin = INVALID_HANDLE;
new Handle:sm_tf2btg_scary_duration = INVALID_HANDLE;
new Handle:sm_tf2btg_scary_duration_admin = INVALID_HANDLE;
new Handle:sm_tf2btg_ghost_speed = INVALID_HANDLE;
new Handle:sm_tf2btg_ghost_speed_admin = INVALID_HANDLE;
new Handle:sm_tf2btg_scary_objects = INVALID_HANDLE;
new Handle:sm_tf2btg_spawnroom_protect = INVALID_HANDLE;

new bool:bDebugMode = false;
new nNotifications = 2;
new bool:bAdminOnly = true;
new Float:flCheckDelay = 0.1;
new Float:flCheckDistance = 240.0;
new Float:flACheckDistance = 240.0;
new Float:flStunDuration = 5.0;
new Float:flAStunDuration = 5.0;
new Float:flGhostSpeed = 200.0;
new Float:flAGhostSpeed = 200.0;
new nDisableObjects = 0;
new bool:bSpawnProtect = true;

new bool:bLateLoaded = false;

new bool:bGhostEnabled[MAXPLAYERS+1];
new bool:bGhostStatus[MAXPLAYERS+1];
new bool:bGhostInvisible[MAXPLAYERS+1];

new bool:bInSpawnRoom[MAXPLAYERS+1];

new Float:flDefaultSpeed[MAXPLAYERS+1];
new bool:bSkipUpdateCheck[MAXPLAYERS+1];

/////////////////
/* Plugin info */

public Plugin:myinfo = {
	name = "[TF2] Be The Ghost",
	author = "Leonardo",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org"
};

///////////////
/* SM Events */

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	CreateNative( "TF2BTG_IsPlayerGhost", Native_IsPlayerGhost );
	fwdCanPlayAsGhost = CreateGlobalForward( "TF2BTG_CanPlayAsGhost", ET_Hook, Param_Cell );
	fwdCanBeScared = CreateGlobalForward( "TF2BTG_CanBeScared", ET_Hook, Param_Cell, Param_Cell );
	RegPluginLibrary("tf2betheghost");
	bLateLoaded = bLateLoad;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	
	sm_tf2btg_version = CreateConVar( "sm_tf2btg_version", PLUGIN_VERSION, "TF2 Be The Ghost plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_tf2btg_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2btg_version, OnConVarChanged_PluginVersion );
	
	sm_tf2btg_debug = CreateConVar( "sm_tf2btg_debug", "0", "Debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2btg_debug, OnConVarChanged );
	
	sm_tf2btg_notify = CreateConVar( "sm_tf2btg_notify", "2", "Chat notificationsn2 - public, 1 - private, 0 - disabled", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	HookConVarChange( sm_tf2btg_notify, OnConVarChanged );
	
	sm_tf2btg_adminonly = CreateConVar( "sm_tf2btg_adminonly", "1", "", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2btg_adminonly, OnConVarChanged );
	
	sm_tf2btg_scary_delay = CreateConVar( "sm_tf2btg_scary_delay", "0.1", "Delay between checks. Low values could cause extra lags!", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2btg_scary_delay, OnConVarChanged );
	
	sm_tf2btg_scary_distance = CreateConVar( "sm_tf2btg_scary_distance", "240.0", "", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2btg_scary_distance, OnConVarChanged );
	
	sm_tf2btg_scary_distance_admin = CreateConVar( "sm_tf2btg_scary_distance_admin", "240.0", "", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2btg_scary_distance_admin, OnConVarChanged );
	
	sm_tf2btg_scary_duration = CreateConVar( "sm_tf2btg_scary_duration", "5.0", "", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2btg_scary_duration, OnConVarChanged );
	
	sm_tf2btg_scary_duration_admin = CreateConVar( "sm_tf2btg_scary_duration_admin", "5.0", "", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2btg_scary_duration_admin, OnConVarChanged );
	
	sm_tf2btg_ghost_speed = CreateConVar( "sm_tf2btg_ghost_speed", "200.0", "", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2btg_ghost_speed, OnConVarChanged );
	
	sm_tf2btg_ghost_speed_admin = CreateConVar( "sm_tf2btg_ghost_speed_admin", "200.0", "", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( sm_tf2btg_ghost_speed_admin, OnConVarChanged );
	
	sm_tf2btg_scary_objects = CreateConVar( "sm_tf2btg_scary_objects", "0", "2 - everyone, 1 - adminOnly, 0 - disabled", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	HookConVarChange( sm_tf2btg_scary_objects, OnConVarChanged );
	
	sm_tf2btg_spawnroom_protect = CreateConVar( "sm_tf2btg_spawnroom_protect", "1", "Enable/diable spawnroom protection", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2btg_spawnroom_protect, OnConVarChanged );
	
	decl String:strGameDir[8];
	GetGameFolderName(strGameDir, sizeof(strGameDir));
	if(!StrEqual(strGameDir, "tf", false) && !StrEqual(strGameDir, "tf_beta", false))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	HookEvent( "player_activate", OnPlayerActivate, EventHookMode_Post );
	HookEvent( "player_death", OnPlayerDeath, EventHookMode_Pre );
	HookEvent( "post_inventory_application", OnPlayerUpdate, EventHookMode_Post );
	HookEvent( "teamplay_round_win", OnRoundEnd, EventHookMode_Post );
	
	AddNormalSoundHook( NormalSoundHook );
	
	RegConsoleCmd( "sm_betheghost", Command_ToggleEffect );
	RegConsoleCmd( "sm_btg", Command_ToggleEffect );
	RegConsoleCmd( "sm_btgfix", Command_ParticleFix );
	
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
	{
		bInSpawnRoom[iClient] = false;
		if( IsValidClient(iClient) )
			RemoveGhostModel( iClient );
		else
		{
			bGhostEnabled[iClient] = false;
			bGhostStatus[iClient] = false;
			bGhostInvisible[iClient] = false;
			bSkipUpdateCheck[iClient] = false;
		}
	}
	
	if( bLateLoaded )
	{
		new iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "func_respawnroom" ) ) != -1 )
		{
			SDKHook( iEntity, SDKHook_StartTouchPost, OnSpawnRoomStartTouch );
			SDKHook( iEntity, SDKHook_TouchPost, OnSpawnRoomStartTouch );
			SDKHook( iEntity, SDKHook_EndTouchPost, OnSpawnRoomEndTouch );
		}
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "trigger_capture_area" ) ) != -1 )
		{
			SDKHook( iEntity, SDKHook_StartTouch, OnCPTouch );
			SDKHook( iEntity, SDKHook_Touch, OnCPTouch );
		}
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "item_teamflag" ) ) != -1 )
		{
			SDKHook( iEntity, SDKHook_StartTouch, OnFlagTouch );
			SDKHook( iEntity, SDKHook_Touch, OnFlagTouch );
		}
	}
	
#if defined _updater_included
	if( LibraryExists("updater") )
        Updater_AddPlugin( PLUGIN_UPDATE_URL );
#endif
}

public OnPluginEnd()
{
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
		if( bGhostEnabled[iClient] )
		{
			DontBeTheGhost( iClient );
			bGhostEnabled[iClient] = false;
			bGhostStatus[iClient] = false;
			bGhostInvisible[iClient] = false;
			bSkipUpdateCheck[iClient] = false;
		}
}

public OnMapStart()
{
	PrecacheModels( strGhostModels, sizeof(strGhostModels) );
	PrecacheSounds( strGhostMoans, sizeof(strGhostMoans) );
	PrecacheSounds( strGhostBoos, sizeof(strGhostBoos) );
	PrecacheSounds( strGhostEffects, sizeof(strGhostEffects) );
}

public OnEntityCreated( iEntity, const String:strClassname[] )
{
	if( StrEqual( strClassname, "func_respawnroom", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouchPost, OnSpawnRoomStartTouch );
		SDKHook( iEntity, SDKHook_TouchPost, OnSpawnRoomStartTouch );
		SDKHook( iEntity, SDKHook_EndTouchPost, OnSpawnRoomEndTouch );
	}
	else if( StrEqual( strClassname, "trigger_capture_area", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnCPTouch );
		SDKHook( iEntity, SDKHook_Touch, OnCPTouch );
	}
	else if( StrEqual( strClassname, "item_teamflag", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnFlagTouch );
		SDKHook( iEntity, SDKHook_Touch, OnFlagTouch );
	}
}

public OnLibraryAdded( const String:strName[] )
{
#if defined _updater_included
	if( strcmp( strName, "updater", nope ) == 0 )
        Updater_AddPlugin( PLUGIN_UPDATE_URL );
#endif
}

public OnConfigsExecuted()
{
	bDebugMode = GetConVarBool( sm_tf2btg_debug );
	nNotifications = GetConVarInt( sm_tf2btg_notify );
	bAdminOnly = GetConVarBool( sm_tf2btg_adminonly );
	flCheckDelay = GetConVarFloat( sm_tf2btg_scary_delay );
	flCheckDistance = GetConVarFloat( sm_tf2btg_scary_distance );
	flACheckDistance = GetConVarFloat( sm_tf2btg_scary_distance_admin );
	flStunDuration = GetConVarFloat( sm_tf2btg_scary_duration );
	flAStunDuration = GetConVarFloat( sm_tf2btg_scary_duration_admin );
	flGhostSpeed = GetConVarFloat( sm_tf2btg_ghost_speed );
	flAGhostSpeed = GetConVarFloat( sm_tf2btg_ghost_speed_admin );
	nDisableObjects = GetConVarInt( sm_tf2btg_scary_objects );
	bSpawnProtect = GetConVarBool( sm_tf2btg_spawnroom_protect );
}

public OnClientDisconnect( iClient )
{
	bInSpawnRoom[iClient] = false;
	bGhostEnabled[iClient] = false;
	bGhostStatus[iClient] = false;
	bGhostInvisible[iClient] = false;
	bSkipUpdateCheck[iClient] = false;
}

public OnGameFrame()
{
	static Float:flLastCall;
	if( GetEngineTime() - flCheckDelay <= flLastCall )
		return;
	flLastCall = GetEngineTime();
	
	new iClient, iGhost, Float:vecGhostOrigin[3], Float:vecClientOrigin[3], Float:flDistance;
	for( iGhost = 1; iGhost <= MaxClients; iGhost++ )
		if( bGhostStatus[iGhost] && IsValidClient(iGhost) )
		{
			SetEntPropFloat( iGhost, Prop_Send, "m_flMaxspeed", CheckCommandAccess( iGhost, "sm_betheghost_adminspeed", ADMFLAG_GENERIC ) ? flAGhostSpeed : flGhostSpeed );
			
			if( bGhostInvisible[iGhost] )
				continue;
			
			GetClientAbsOrigin( iGhost, vecGhostOrigin );
			for( iClient = 1; iClient <= MaxClients; iClient++ )
				if( !bGhostStatus[iClient] && IsValidClient(iClient) && IsPlayerAlive(iClient) && !bGhostInvisible[iClient] && ( !bSpawnProtect || !bInSpawnRoom[iClient] ) && !CheckCommandAccess( iClient, "sm_betheghost_immunity", ADMFLAG_ROOT ) )
				{
					GetClientAbsOrigin( iClient, vecClientOrigin );
					flDistance = GetVectorDistance( vecGhostOrigin, vecClientOrigin );
					if( flDistance < 0 )
						flDistance *= -1.0;
					if( flDistance <= ( CheckCommandAccess( iGhost, "sm_betheghost_admindistance", ADMFLAG_GENERIC ) ? flACheckDistance : flCheckDistance ) )
						ScarePlayer( iGhost, iClient );
				}
			
			if( !( nDisableObjects == 2 || nDisableObjects == 1 && !CheckCommandAccess( iClient, "sm_betheghost_objects", ADMFLAG_GENERIC ) ) )
				continue;
			
			DisableObjects( iGhost, vecGhostOrigin, "obj_dispenser" );
			DisableObjects( iGhost, vecGhostOrigin, "obj_sentrygun" );
			DisableObjects( iGhost, vecGhostOrigin, "obj_teleporter" );
		}
}

public OnSpawnRoomStartTouch( iSpawn, iOther )
{
	if( IsValidClient(iOther) )
		bInSpawnRoom[iOther] = true;
}
public OnSpawnRoomEndTouch( iSpawn, iOther )
{
	if( IsValidClient(iOther) )
		bInSpawnRoom[iOther] = false;
}

public Action:OnCPTouch( iPoint, iOther )
{
	if( IsValidClient(iOther) && bGhostStatus[iOther] )
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action:OnFlagTouch( iFlag, iOther )
{
	if( IsValidClient(iOther) && bGhostStatus[iOther] )
		return Plugin_Handled;
	return Plugin_Continue;
}

/////////////////
/* Game Events */

public OnRoundEnd( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
	{
		if( !IsValidClient(iClient) || !IsPlayerAlive(iClient) || !bGhostInvisible[iClient] )
			continue;
		
		SetEntityRenderColor( iClient, _, _, _, 255 );
		SetEntityRenderMode( iClient, RENDER_NORMAL );
		BeTheGhost( iClient );
		bGhostInvisible[iClient] = false;
	}
}

public OnPlayerActivate( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iClient) )
		return;
	
	bGhostEnabled[iClient] = false;
	bGhostStatus[iClient] = false;
	bGhostInvisible[iClient] = false;
	bSkipUpdateCheck[iClient] = false;
}

public OnPlayerUpdate( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( IsValidClient(iClient) && IsPlayerAlive(iClient) && bGhostEnabled[iClient] && !bSkipUpdateCheck[iClient] )
		BeTheGhost( iClient );
}

public Action:OnPlayerDeath( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( IsValidClient(iClient) && bGhostStatus[iClient] )
		DontBeTheGhost( iClient );
	return Plugin_Continue;
}

public Action:NormalSoundHook( iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags )
{
	if( !IsValidClient( iEntity ) || !bGhostStatus[iEntity] && !bGhostInvisible[iEntity] )
		return Plugin_Continue;
	
	if( bGhostInvisible[iEntity] )
		return Plugin_Stop;
	
	if( StrContains( strSample, "footsteps", false ) != -1 )
		return Plugin_Stop;
	
	if( StrContains( strSample, "vo/", false ) == 0 && StrContains( strSample, "vo/halloween_", false ) == -1 )
	{
		Format( strSample, sizeof(strSample), strGhostMoans[ GetRandomInt( 0, sizeof(strGhostMoans)-1 ) ] );
		return Plugin_Changed;
	}
	
	if( bDebugMode )
		PrintToServer( "%N - Sample: %s", iEntity, strSample );
	
	return Plugin_Continue;
}

//////////////////
/* CMDs & CVars */

public Action:Command_ParticleFix( iClient, nArgs )
{
	for( new i = 1; i <= MaxClients; i++ )
		Timer_FixParticles( INVALID_HANDLE, i );
	ReplyToCommand( iClient, "Done." );
	return Plugin_Handled;
}

public Action:Command_ToggleEffect( iClient, nArgs )
{
	new bool:bHasAccess = ( IsValidClient(iClient) && ( !bAdminOnly || CheckCommandAccess( iClient, "sm_betheghost_override", ADMFLAG_GENERIC ) ) );
	
	decl String:strCommandName[16];
	GetCmdArg( 0, strCommandName, sizeof(strCommandName) );
	
	if( nArgs == 0 && IsValidClient(iClient) ) 
	{
		if( !bGhostEnabled[iClient] && !bHasAccess )
			return Plugin_Continue;
		
		bGhostEnabled[iClient] = !bGhostEnabled[iClient];
		PrintStatus(iClient);
		if( IsPlayerAlive(iClient) )
		{
			if( bGhostEnabled[iClient] )
				BeTheGhost( iClient );
			else
				DontBeTheGhost( iClient );
		}
	}
	else if( nArgs == 1 ) 
	{
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		
		if( IsCharNumeric(strTargets[0]) )
		{
			if( !IsValidClient(iClient) )
			{
				ReplyToCommand( iClient, "Usage: %s <target> [0/1]", strCommandName );
				return Plugin_Handled;
			}
			
			if( !bGhostEnabled[iClient] && !bHasAccess )
				return Plugin_Continue;
			
			bGhostEnabled[iClient] = StringToInt(strTargets) != 0;
			PrintStatus(iClient);
			if( IsPlayerAlive(iClient) )
			{
				if( bGhostEnabled[iClient] )
					BeTheGhost( iClient );
				else
					DontBeTheGhost( iClient );
			}
			return Plugin_Handled;
		}
		else if( !bHasAccess )
			return Plugin_Continue;
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS];
		decl nTargets;
		decl bool:tn_is_ml;
		if((nTargets = ProcessTargetString(strTargets, iClient, iTargets, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError( iClient, nTargets );
			return Plugin_Handled;
		}
		for( new i = 0; i < nTargets; i++ )
			if( IsValidClient( iTargets[i] ) )
			{
				bGhostEnabled[iTargets[i]] = !bGhostEnabled[iTargets[i]];
				PrintStatus(iTargets[i]);
				if( IsPlayerAlive(iTargets[i]) )
				{
					if( bGhostEnabled[iTargets[i]] )
						BeTheGhost( iTargets[i] );
					else
						DontBeTheGhost( iTargets[i] );
				}
			}
	}
	else if( nArgs == 2 )
	{
		if( !bHasAccess )
			return Plugin_Continue;
		
		decl String:strState[2];
		GetCmdArg( 2, strState, sizeof(strState) );
		new bool:bState = StringToInt( strState ) != 0;
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS];
		decl nTargets;
		decl bool:tn_is_ml;
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		if((nTargets = ProcessTargetString(strTargets, iClient, iTargets, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError( iClient, nTargets );
			return Plugin_Handled;
		}
		for( new i = 0; i < nTargets; i++ )
			if( IsValidClient( iTargets[i] ) )
			{
				bGhostEnabled[iTargets[i]] = bState;
				PrintStatus(iTargets[i]);
				if( IsPlayerAlive(iTargets[i]) )
				{
					if( bGhostEnabled[iTargets[i]] )
						BeTheGhost( iTargets[i] );
					else
						DontBeTheGhost( iTargets[i] );
				}
			}
	}
	else if( bHasAccess )
		ReplyToCommand( iClient, "Usage: %s [target] [0/1]", strCommandName );
	else if( iClient == 0 )
		ReplyToCommand( iClient, "Usage: %s <target> [0/1]", strCommandName );
	else
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );

public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

public Action:OnPlayerRunCmd( iClient, &iButtons, &iImpulse, Float:vecVelocity[3], Float:vecAngles[3], &iWeapon )
{
	static iLastButtons[MAXPLAYERS+1];
	
	if( !IsValidClient(iClient) || !bGhostStatus[iClient] && !bGhostInvisible[iClient] )
		return Plugin_Continue;
	
	if( GetEntityMoveType( iClient ) == MOVETYPE_FLY )
	{
		new Float:flMaxSpeed = GetEntPropFloat( iClient, Prop_Data, "m_flMaxspeed" );
		new Float:flFallVel = GetEntPropFloat( iClient, Prop_Send, "m_flFallVelocity" ) * -1.0;
		
		new Float:flMaxSpeedLimit = CheckCommandAccess( iClient, "sm_betheghost_adminspeed", ADMFLAG_GENERIC ) ? flAGhostSpeed : flGhostSpeed;
		if( flMaxSpeed > flMaxSpeedLimit )
			flMaxSpeed = flMaxSpeedLimit;
		
		if( (iButtons&IN_JUMP) == IN_JUMP )
		{
			if ( flFallVel <= flMaxSpeed * -1 + 20)
				vecVelocity[2] = flMaxSpeed / 2;
			else
				vecVelocity[2] = flMaxSpeed;
		}
		
		if( (iButtons&IN_DUCK) == IN_DUCK )
		{
			if ( flFallVel >= flMaxSpeed - 20)
				vecVelocity[2] = flMaxSpeed / -2;
			else
				vecVelocity[2] = flMaxSpeed * -1;
		}
	}
	
	if( !((iLastButtons[iClient] & IN_ATTACK2) == IN_ATTACK2) && (iButtons & IN_ATTACK2) == IN_ATTACK2 )
	{
		if( GetEntityRenderMode(iClient) == RENDER_NORMAL )
		{
			if( GameRules_GetRoundState() != RoundState_TeamWin )
			{
				DontBeTheGhost( iClient, true );
				BeTheGhost( iClient, true );
				SetEntityRenderMode( iClient, RENDER_TRANSCOLOR );
				SetEntityRenderColor( iClient, _, _, _, 0 );
				bGhostInvisible[iClient] = true;
				Timer_FixParticles( INVALID_HANDLE, iClient );
				CreateTimer( 1.0, Timer_FixParticles, iClient, TIMER_FLAG_NO_MAPCHANGE );
			}
		}
		else
		{
			SetEntityRenderColor( iClient, _, _, _, 255 );
			SetEntityRenderMode( iClient, RENDER_NORMAL );
			BeTheGhost( iClient );
			bGhostInvisible[iClient] = false;
		}
	}
	if( (iButtons & IN_ATTACK) == IN_ATTACK )
	{
		SetEntityMoveType( iClient, MOVETYPE_FLY );
		
		new Float:vecOrigin[3];
		GetClientAbsOrigin( iClient, vecOrigin );
		
		vecOrigin[0] = vecOrigin[0] + 2.0 * Cosine( DegToRad(vecAngles[1]) );
		vecOrigin[1] = vecOrigin[1] + 2.0 * Sine( DegToRad(vecAngles[1]) );
		vecOrigin[2] = vecOrigin[2] - 2.0 * Sine( DegToRad(vecAngles[0]) );
		
		TeleportEntity( iClient, vecOrigin, vecAngles, NULL_VECTOR );
	}
	else
		SetEntityMoveType( iClient, GetEntityFlags(iClient) & FL_ONGROUND == FL_ONGROUND ? MOVETYPE_WALK : MOVETYPE_FLY );
	
	iLastButtons[iClient] = iButtons;
	return Plugin_Changed;
}
public Action:Timer_FixParticles( Handle:hTimer, any:iClient )
{
	if( !IsValidClient(iClient) )
		return Plugin_Stop;
	
	SetVariantString( "ParticleEffectStop" );
	AcceptEntityInput( iClient, "DispatchEffect" );
	return Plugin_Stop;
}

///////////////
/* Functions */

BeTheGhost( iClient, bool:bInvisibility = false )
{
	if( !IsValidClient(iClient) )
	{
		Error( ERROR_LOG, _, "Invalid client: %d", iClient );
		return;
	}
	
	DropFlag( iClient );
	
	if( !bInvisibility )
	{
		new Action:result;
		Call_StartForward( fwdCanPlayAsGhost );
		Call_PushCell( iClient );
		Call_Finish( result );
		if( result >= Plugin_Handled )
			return;
		
		if( !bGhostStatus[iClient] )
			flDefaultSpeed[iClient] = GetEntPropFloat( iClient, Prop_Send, "m_flMaxspeed" );
		
		bGhostStatus[iClient] = true;
		bGhostInvisible[iClient] = false;
		
		AttachParticle( iClient, "ghost_appearation", _, 2.0, 2.0 );
		EmitSoundToAll( strGhostMoans[ GetRandomInt( 0, sizeof(strGhostMoans)-1 ) ], iClient );
		SetGhostModel( iClient, strGhostModels[ GetRandomInt( 0, sizeof(strGhostModels)-1 ) ] );
	}
	else
		bGhostStatus[iClient] = true;
	
	SetWeaponsAlpha( iClient, 0 );
	SetEntPropFloat( iClient, Prop_Send, "m_flMaxspeed", CheckCommandAccess( iClient, "sm_betheghost_adminspeed", ADMFLAG_GENERIC ) ? flAGhostSpeed : flGhostSpeed );
	SetEntProp( iClient, Prop_Data, "m_takedamage", 0, 1 );
	SetEntProp( iClient, Prop_Send, "m_CollisionGroup", 2 );
	//SetEntProp( iClient, Prop_Send, "m_nSolidType", 0 );
	//SetEntProp( iClient, Prop_Send, "m_usSolidFlags", 4 );
	SetEntityFlags( iClient, GetEntityFlags( iClient ) | FL_NOTARGET );
	SetEntProp( iClient, Prop_Send, "m_bDrawViewmodel", 0 );
	TF2_RemoveAllWeapons( iClient );
}
DontBeTheGhost( iClient, bool:bInvisibility = false )
{
	if( !IsValidClient(iClient) )
	{
		Error( ERROR_LOG, _, "Invalid client: %d", iClient );
		return;
	}
	
	bGhostStatus[iClient] = false;
	
	RemoveGhostModel( iClient );
	if( !bInvisibility )
	{
		bGhostInvisible[iClient] = false;
		
		SetWeaponsAlpha( iClient, 255 );
		if( GetEntityRenderMode(iClient) != RENDER_NORMAL )
		{
			SetEntityRenderColor( iClient, _, _, _, 255 );
			SetEntityRenderMode( iClient, RENDER_NORMAL );
		}
	}
	AttachParticle( iClient, "ghost_appearation", _, 2.0, 2.0 );
	EmitSoundToAll( strGhostEffects[ GetRandomInt( 0, sizeof(strGhostEffects)-1 ) ], iClient );
	SetEntPropFloat( iClient, Prop_Send, "m_flMaxspeed", flDefaultSpeed[iClient] );
	SetEntityMoveType( iClient, MOVETYPE_WALK );
	SetEntProp( iClient, Prop_Data, "m_takedamage", 2, 1 );
	SetEntProp( iClient, Prop_Send, "m_CollisionGroup", 5 );
	//SetEntProp( iClient, Prop_Send, "m_nSolidType", 2 );
	//SetEntProp( iClient, Prop_Send, "m_usSolidFlags", 16 );
	SetEntityFlags( iClient, GetEntityFlags( iClient ) & ~FL_NOTARGET );
	new iHealth = GetClientHealth( iClient );
	bSkipUpdateCheck[iClient] = true;
	TF2_RegeneratePlayer( iClient );
	bSkipUpdateCheck[iClient] = false;
	SetEntityHealth( iClient, iHealth );
	SetEntProp( iClient, Prop_Send, "m_bDrawViewmodel", 1 );
}

SetGhostModel( iClient, const String:strModelName[] )
{
	if( !IsValidClient( iClient ) )
		return;
	
	if( !IsModelPrecached( strModelName ) )
		if( PrecacheModel( strModelName ) == 0 )
		{
			Error( ERROR_LOG, _, "Faild to precache model: %s", strModelName );
			return;
		}
	
	SetVariantString( strModelName );
	AcceptEntityInput( iClient, "SetCustomModel" );
}
RemoveGhostModel( iClient )
{
	if( !IsValidClient( iClient ) )
		return;
	
	SetVariantString( "" );
	AcceptEntityInput( iClient, "SetCustomModel" );
	
	Timer_FixParticles( INVALID_HANDLE, iClient );
	CreateTimer( 1.0, Timer_FixParticles, iClient, TIMER_FLAG_NO_MAPCHANGE );
}

ScarePlayer( iGhost, iClient )
{
	static Float:flLastScare[MAXPLAYERS+1];
	static Float:flLastBoo;
	
	if( !bGhostEnabled[iGhost] || !IsValidClient(iGhost) || !IsValidClient(iClient)/* || TF2_IsPlayerInCondition( iClient, TFCond_Dazed )*/ )
		return;
	
	new Action:result;
	Call_StartForward( fwdCanBeScared );
	Call_PushCell( iGhost );
	Call_PushCell( iClient );
	Call_Finish( result );
	if( result >= Plugin_Handled )
		return;
	
	if( GetEngineTime() - ( CheckCommandAccess( iGhost, "sm_betheghost_adminstun", ADMFLAG_GENERIC ) ? flAStunDuration : flStunDuration ) <= flLastScare[iClient] )
		return;
	flLastScare[iClient] = GetEngineTime();
	
	if( GetEngineTime() - 1.0 > flLastBoo )
	{
		flLastBoo = GetEngineTime();
		EmitSoundToAll( strGhostBoos[ GetRandomInt( 0, sizeof(strGhostBoos)-1 ) ], iGhost );
	}
	
	new Handle:hData;
	CreateDataTimer( 0.5, Timer_StunPlayer, hData, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE );
	WritePackCell( hData, iGhost );
	WritePackCell( hData, iClient );
}
public Action:Timer_StunPlayer( Handle:hTimer, any:hData )
{
	ResetPack( hData );
	new iGhost = ReadPackCell( hData );
	new iClient = ReadPackCell( hData );
	if( IsValidClient(iClient) )
		TF2_StunPlayer( iClient, CheckCommandAccess( iGhost, "sm_betheghost_adminstun", ADMFLAG_GENERIC ) ? flAStunDuration : flStunDuration, _, TF_STUNFLAGS_GHOSTSCARE );
	return Plugin_Stop;
}
DisableObjects( iGhost, Float:vecGhostOrigin[3], const String:strClassname[] )
{
	if( !IsValidClient(iGhost) || !bGhostStatus[iGhost] || bGhostInvisible[iGhost] )
		return;
	
	new Float:flDuration = ( CheckCommandAccess( iGhost, "sm_betheghost_adminstun", ADMFLAG_GENERIC ) ? flAStunDuration : flStunDuration );
	
	new offsBuilder = -1;
	decl String:strNetClass[32];
	
	new iObject = -1, iOwner, Float:flDistance, Float:vecOrigin[3];
	while( ( iObject = FindEntityByClassname( iObject, strClassname ) ) != -1 )
		if( GetEntProp( iObject, Prop_Send, "m_bDisabled" ) == 0 )
		{
			if( offsBuilder == -1 )
			{
				GetEntityNetClass( iObject, strNetClass, sizeof(strNetClass) );
				offsBuilder = FindSendPropOffs( strNetClass, "m_hBuilder" );
			}
			if( offsBuilder != -1 )
			{
				iOwner = GetEntDataEnt2( iObject, offsBuilder );
				if( CheckCommandAccess( iOwner, "sm_betheghost_immunity", ADMFLAG_ROOT ) )
					continue;
			}
			GetEntPropVector( iObject, Prop_Send, "m_vecOrigin", vecOrigin );
			flDistance = GetVectorDistance( vecGhostOrigin, vecOrigin );
			if( flDistance < 0 )
				flDistance *= -1.0;
			if( flDistance <= ( CheckCommandAccess( iGhost, "sm_betheghost_admindistance", ADMFLAG_GENERIC ) ? flACheckDistance : flCheckDistance ) )
			{
				SetEntProp( iObject, Prop_Send, "m_bDisabled", 1 );
				CreateTimer( flDuration, Timer_ObjectWakeUp, EntIndexToEntRef(iObject), TIMER_FLAG_NO_MAPCHANGE );
			}
		}
}
public Action:Timer_ObjectWakeUp( Handle:hTimer, any:iEntRef )
{
	new iEntity = EntRefToEntIndex( iEntRef );
	if( IsValidEntity(iEntity) && GameRules_GetRoundState() != RoundState_TeamWin )
		SetEntProp( iEntity, Prop_Send, "m_bDisabled", 0 );
	return Plugin_Stop;
}

PrintStatus( iClient )
{
	if( !IsValidClient(iClient) )
		return;
	if( bGhostEnabled[iClient] )
	{
		if( nNotifications == 2 )
			PrintToChatAll( "\x07%06X%N\x01 is now as ghost.", HAUNTED_COLOR, iClient );
		else if( nNotifications == 1 )
			PrintToChat( iClient, "* You're now as ghost." );
	}
	else
	{
		if( nNotifications == 2 )
			PrintToChatAll( "\x07%06X%N\x01 is no longer as ghost.", HAUNTED_COLOR, iClient );
		else if( nNotifications == 1 )
			PrintToChat( iClient, "* You're no longer as ghost." );
	}
}

AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0, Float:flSelfDestruct=0.0)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if(strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		
		if( flSelfDestruct > 0.0 )
			CreateTimer( flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
		
		return iParticle;
	}
	
	return 0;
}
public Action:Timer_DeleteParticle(Handle:hTimer, any:iRefEnt)
{
	new iEntity = EntRefToEntIndex(iRefEnt);
	if(iEntity > MaxClients)
		AcceptEntityInput(iEntity, "Kill");
	
	return Plugin_Handled;
}

DropFlag( iClient )
{
	if( !IsValidClient(iClient) )
		return;
	
	new iFlag = -1, iCTeam = GetClientTeam(iClient);
	while( ( iFlag = FindEntityByClassname( iFlag, "item_teamflag" ) ) != -1 )
	{
		if( GetEntProp( iFlag, Prop_Send, "m_iTeamNum" ) == iCTeam )
			continue;
		if( GetEntProp( iFlag, Prop_Send, "m_nFlagStatus" ) != 1 )
			continue;
		if( GetEntPropEnt( iFlag, Prop_Send, "m_hPrevOwner" ) != iClient )
			continue;
		AcceptEntityInput( iFlag, "ForceDrop" );
	}
}

/////////////
/* Natives */

public Native_IsPlayerGhost( Handle:hPlugin, nParams )
{
	new iClient = GetNativeCell(1);
	return IsValidClient( iClient ) && bGhostStatus[iClient];
}

////////////
/* Stocks */

stock Error( iFlags = ERROR_NONE, iNativeErrCode = SP_ERROR_NONE, const String:strMessage[], any:... )
{
	decl String:strBuffer[1024];
	VFormat( strBuffer, sizeof(strBuffer), strMessage, 4 );
	
	if( iFlags )
	{
		if( iFlags & ERROR_LOG )
		{
			decl String:strFile[PLATFORM_MAX_PATH];
			FormatTime( strFile, sizeof(strFile), "%Y%m%d" );
			Format( strFile, sizeof(strFile), "TF2BTG%s", strFile );
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
	
	PrintToServer( strBuffer );
}

stock SetWeaponsAlpha( iClient, iAlpha )
{
	if( IsClientInGame(iClient) )
	{
		decl String:classname[64];
		new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
		for(new i = 0, weapon; i < 47; i += 4)
		{
			weapon = GetEntDataEnt2(iClient, m_hMyWeapons + i);
			if(weapon > -1 && IsValidEdict(weapon))
			{
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "saxxy", false) != -1 || StrContains(classname, "tf_wearable", false) != -1)
				{
					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, 255, 255, 255, iAlpha);
				}
			}
		}
		
		new iEnt;
		while( ( iEnt = FindEntityByClassname( iEnt, "tf_wearable" ) ) != -1 )
		{
			if( GetEntPropEnt( iEnt, Prop_Send, "m_hOwnerEntity" ) == iClient )
			{
				SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEnt, 255, 255, 255, iAlpha);
			}
		}
		iEnt = 0;
		while( ( iEnt = FindEntityByClassname( iEnt, "tf_wearable_demoshield" ) ) != -1 )
		{
			if( GetEntPropEnt( iEnt, Prop_Send, "m_hOwnerEntity" ) == iClient )
			{
				SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEnt, 255, 255, 255, iAlpha);
			}
		}
		iEnt = 0;
		while( ( iEnt = FindEntityByClassname( iEnt, "tf_wearable_robot_arm" ) ) != -1 )
		{
			if( GetEntPropEnt( iEnt, Prop_Send, "m_hOwnerEntity" ) == iClient )
			{
				SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iEnt, 255, 255, 255, iAlpha);
			}
		}
	}
}

stock PrecacheModels( const String:strModels[][], iArraySize )
{
	for( new i = 0; i < iArraySize; i++ )
		if( PrecacheModel( strModels[i], true ) == 0 )
			Error( ERROR_LOG, _, "Faild to precache model: %s", strModels[i] );
}
stock PrecacheSounds( const String:strSounds[][], iArraySize )
{
	for( new i = 0; i < iArraySize; i++ )
		if( !PrecacheSound( strSounds[i] ) )
			Error( ERROR_LOG, _, "Faild to precache sound: %s", strSounds[i] );
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}