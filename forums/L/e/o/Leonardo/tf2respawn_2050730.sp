#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION		"1.0.3-20131108"
#define RESPAWN_TIME_WAVE	15.0
#define RESPAWN_TIME_WARN	2.0

new Handle:sm_respawn_override_version = INVALID_HANDLE;
new Handle:sm_respawn_time = INVALID_HANDLE;
new Handle:sm_respawn_time_min = INVALID_HANDLE;
new Handle:sm_respawn_mode = INVALID_HANDLE;
new Handle:sm_respawn_dist_min = INVALID_HANDLE;
new Handle:sm_respawn_dist_max = INVALID_HANDLE;
new Handle:sm_respawn_effects = INVALID_HANDLE;
new Handle:sm_respawn_crits = INVALID_HANDLE;
new Handle:sm_respawn_crits2uber = INVALID_HANDLE;
new Handle:sm_respawn_boost = INVALID_HANDLE;
new Handle:sv_tags = INVALID_HANDLE;
new Handle:hRespawnTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:hRevengeTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Float:flRespawnWaveTime = -1.0;
new Float:flRespawnTime;
new Float:flRespawnTimeMin;
new nRespawnMode;
new Float:flDistanceMin;
new Float:flDistanceMax;
new bool:bEffects;
new Float:flCritsDuration;
new nCrits2Uber;
new Float:flBoostDuration;

new bool:bReady = false;
new bool:bDiedSinceSpawn[MAXPLAYERS+1];
new nCritsOnSpawn[MAXPLAYERS+1];
new bool:bBoostOnSpawn[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[TF2] Respawn Time Override",
	author = "Leonardo",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
}

public OnPluginStart()
{
	sm_respawn_override_version = CreateConVar( "sm_respawn_override_version", PLUGIN_VERSION, "TF2 Respawn Time Override plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	SetConVarString( sm_respawn_override_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_respawn_override_version, OnConVarChanged_Version );
	
	LoadTranslations( "tf2respawn.phrases" );
	LoadTranslations( "common.phrases" );
	
	decl String:strGameDir[8];
	GetGameFolderName( strGameDir, sizeof(strGameDir) );
	if( !StrEqual( strGameDir, "tf", false ) && !StrEqual( strGameDir, "tf_beta", false ) )
		SetFailState( "THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!" );
	
	HookEvent( "teamplay_round_start", OnNewRound, EventHookMode_PostNoCopy );
	HookEvent( "player_team", OnPlayerChangeTeam );
	HookEvent( "post_inventory_application", OnPlayerRegen );
	HookEvent( "player_spawn", OnPlayerSpawn );
	HookEvent( "player_death", OnPlayerDeath );
	
	RegAdminCmd( "sm_respawn", Command_Respawn, ADMFLAG_GENERIC, "Usage: sm_respawn <targets>" );
	RegAdminCmd( "sm_regenerate", Command_Regenerate, ADMFLAG_GENERIC, "Usage: sm_regenerate <targets>" );
	RegAdminCmd( "sm_regen", Command_Regenerate, ADMFLAG_GENERIC, "Usage: sm_regenerate <targets>" );
	
	HookConVarChange( sm_respawn_time = CreateConVar( "sm_respawn_time", "6.25", "Maximal respawn time.\nSet -1 to disable.", FCVAR_PLUGIN, true, -1.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_time_min = CreateConVar( "sm_respawn_time_min", "2.0", "Minimal respawn time.", FCVAR_PLUGIN, true, 0.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_mode = CreateConVar( "sm_respawn_mode", "0", "Respawn mode:\n0 - regular,\n1 - based on distance from spawnroom to death point.", FCVAR_PLUGIN, true, 0.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_dist_min = CreateConVar( "sm_respawn_dist_min", "500", _, FCVAR_PLUGIN, true, 0.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_dist_max = CreateConVar( "sm_respawn_dist_max", "5000", _, FCVAR_PLUGIN, true, 0.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_effects = CreateConVar( "sm_respawn_effects", "1", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_crits = CreateConVar( "sm_respawn_crits", "6", "Duration of revenge crits after death at spawn room.\nMultiplied by player speed.", FCVAR_PLUGIN, true, 0.0, true, 30.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_crits2uber = CreateConVar( "sm_respawn_crits2uber", "3", "Revenge crits became uber after this amount of deaths.", FCVAR_PLUGIN, true, 0.0 ), OnConVarChanged );
	HookConVarChange( sm_respawn_boost = CreateConVar( "sm_respawn_boost", "3", "Duration of speed boost when player dies too far.\nMultiplied by player speed.", FCVAR_PLUGIN, true, 0.0, true, 30.0 ), OnConVarChanged );
	
	sv_tags = FindConVar( "sv_tags" );
	
	bReady = false;
}

public OnMapStart()
{
	TF2_IsArenaMap( true );
	TF2_IsMultiStage( true );
	for( new i = 0; i <= MAXPLAYERS; i++ )
		OnClientConnected( i );
	bReady = true;
}

public OnMapEnd()
	bReady = false;

public OnConfigsExecuted()
{
	flRespawnTime = GetConVarFloat( sm_respawn_time );
	if( flRespawnTime > 0.0 )
		flRespawnWaveTime = flRespawnTime + RESPAWN_TIME_WAVE;
	else if( flRespawnTime == 0.0 )
		flRespawnWaveTime = flRespawnTime;
	else
	{
		flRespawnWaveTime = -1.0;
		bReady = false;
	}
	flRespawnTimeMin = FloatMax( GetConVarFloat( sm_respawn_time_min ), 0.0 );
	nRespawnMode = GetConVarInt( sm_respawn_mode );
	flDistanceMin = GetConVarFloat( sm_respawn_dist_min );
	flDistanceMax = GetConVarFloat( sm_respawn_dist_max );
	bEffects = GetConVarBool( sm_respawn_effects );
	flCritsDuration = GetConVarFloat( sm_respawn_crits );
	nCrits2Uber = GetConVarInt( sm_respawn_crits2uber );
	flBoostDuration = GetConVarFloat( sm_respawn_boost );
	
	SetTags();
}

public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();
public OnConVarChanged_Version( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( !StrEqual( strNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );

public OnClientConnected( iClient )
{
	bDiedSinceSpawn[iClient] = false;
	nCritsOnSpawn[iClient] = 0;
	bBoostOnSpawn[iClient] = false;
}

public OnClientDisconnect( iClient )
{
	OnClientConnected( iClient );
	StopTimer( hRespawnTimers[iClient] );
	StopTimer( hRevengeTimers[iClient] );
}

public OnGameFrame()
{
	new RoundState:nRoundState = GameRules_GetRoundState();
	if( RoundState_Preround <= nRoundState <= RoundState_TeamWin && ( bReady && flRespawnWaveTime >= 0.0 || !bReady && flRespawnWaveTime < 0.0 ) )
	{
		new bool:bQuickSpawn = flRespawnWaveTime == 0.0 || nRoundState == RoundState_Preround || nRoundState == RoundState_TeamWin;
		new bool:bResetTimer = flRespawnWaveTime < 0.0;
		if( bResetTimer )
			bReady = true;
		for( new i = _:TFTeam_Red; i <= _:TFTeam_Blue; i++ )
			GameRules_SetPropFloat( "m_TeamRespawnWaveTimes", ( bResetTimer ? -1.0 : ( bQuickSpawn ? 0.0 : flRespawnWaveTime ) ), i );
	}
}

public Action:Command_Respawn( iClient, nArgs )
{
	if( !( iClient == 0 || 0 < iClient <= MaxClients && IsClientInGame(iClient) ) )
		return Plugin_Continue;
	
	decl String:target_string[65];
	if( nArgs < 1 && iClient > 0 && 2 <= GetClientTeam(iClient) <= 3 )
		strcopy( target_string, sizeof(target_string), "@me" );
	else if( nArgs >= 1 )
		GetCmdArg( 1, target_string, sizeof(target_string) );
	else
	{
		ReplyToCommand( iClient, "Usage: sm_respawn <targets>" );
		return Plugin_Handled;
	}
	StripQuotes(target_string);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			target_string,
			iClient,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_DEAD,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(iClient, target_count);
		return Plugin_Handled;
	}
	
	for( new i = 0; i < target_count; i++ )
	{
		StopTimer( hRespawnTimers[target_list[i]] );
		TF2_RespawnPlayer( target_list[i] );
	}
	
	return Plugin_Handled;
}

public Action:Command_Regenerate( iClient, nArgs )
{
	if( !( iClient == 0 || 0 < iClient <= MaxClients && IsClientInGame(iClient) ) )
		return Plugin_Continue;
	
	decl String:target_string[65];
	if( nArgs < 1 && iClient > 0 && 2 <= GetClientTeam(iClient) <= 3 )
		strcopy( target_string, sizeof(target_string), "@me" );
	else if( nArgs >= 1 )
		GetCmdArg( 1, target_string, sizeof(target_string) );
	else
	{
		ReplyToCommand( iClient, "Usage: sm_regenerate <targets>" );
		return Plugin_Handled;
	}
	StripQuotes(target_string);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			target_string,
			iClient,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(iClient, target_count);
		return Plugin_Handled;
	}
	
	for( new i = 0; i < target_count; i++ )
		TF2_RegeneratePlayer( target_list[i] );
	
	return Plugin_Handled;
}

public OnNewRound( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
	CreateTimer( 0.666, Timer_OnNewRound ); // HELLTOWER

public Action:Timer_OnNewRound( Handle:hTimer, any:iTimer )
{
	for( new i = 1; i <= MaxClients; i++ )
		if( 0 < i <= MaxClients && IsClientConnected( i ) && !IsPlayerAlive( i ) )
		{
			StopTimer( hRespawnTimers[i] );
			TF2_RespawnPlayer( i );
		}
	return Plugin_Stop;
}

public OnPlayerChangeTeam( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iUserID = GetEventInt( hEvent, "userid" );
	new iClient = GetClientOfUserId( iUserID );
	if( !( 0 < iClient <= MaxClients ) || !IsClientConnected( iClient ) )
		return;
	
	nCritsOnSpawn[iClient] = 0;
	bBoostOnSpawn[iClient] = false;
	StopTimer( hRespawnTimers[iClient] );
	
	if( !GetEventInt( hEvent, "disconnect" ) && 2 <= GetEventInt( hEvent, "team" ) <= 3 )
	{
		//PrintToChat( iClient, "%t", "RespawnIn", 8.0 );
		hRespawnTimers[iClient] = CreateTimer( 8.0, Timer_Respawn_Warn, iUserID, TIMER_FLAG_NO_MAPCHANGE );
	}
}

public OnPlayerRegen( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iUserID = GetEventInt( hEvent, "userid" );
	new iClient = GetClientOfUserId( iUserID );
	if( 0 < iClient <= MaxClients )
		CreateTimer( 0.0, Timer_OnPlayerRegen, iUserID );
}
public Action:Timer_OnPlayerRegen( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) && IsPlayerAlive( iClient ) && bEffects )
	{
		TF2_AddCondition( iClient, TFCond_Overhealed, 3.0 );
		TF2_AddCondition( iClient, TFCond_InHealRadius, 1.0 );
	}
	return Plugin_Stop;
}

public OnPlayerSpawn( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iUserID = GetEventInt( hEvent, "userid" );
	new iClient = GetClientOfUserId( iUserID );
	if( !( 0 < iClient <= MaxClients ) )
		return;
	
	StopTimer( hRespawnTimers[iClient] );
	
	CreateTimer( 0.0, Timer_OnPlayerSpawn, iUserID );
	
	if( !IsValidClient( iClient ) || !IsPlayerAlive( iClient ) )
	{
		bDiedSinceSpawn[iClient] = false;
		StopTimer( hRevengeTimers[iClient] );
		return;
	}
	
	if( bEffects && GetClientTeam( iClient ) != 1 )
	{
		new Float:vecOrigin[3];
		GetClientAbsOrigin( iClient, vecOrigin );
		if( GetClientTeam( iClient ) == _:TFTeam_Red )
			CreateParticle( vecOrigin, _, "teleportedin_red", 1.5 );
		else
			CreateParticle( vecOrigin, _, "teleportedin_blue", 1.5 );
		TF2_AddCondition( iClient, TFCond_TeleportedGlow, 1.0 );
	}
}
public Action:Timer_OnPlayerSpawn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsValidClient( iClient ) || !IsPlayerAlive( iClient ) )
	{
		bDiedSinceSpawn[iClient] = false;
		StopTimer( hRevengeTimers[iClient] );
		return Plugin_Stop;
	}
	
	new Float:flSpeed = FloatMax( 8.0, GetEntPropFloat( iClient, Prop_Send, "m_flMaxspeed" ) );
	
	if( flCritsDuration > 0.0 && nCritsOnSpawn[iClient] )
	{
		new Float:flCrits = FloatMin( 30.0, flDistanceMin * flCritsDuration / flSpeed );
		if( nCrits2Uber > 0 && nCritsOnSpawn[iClient] >= nCrits2Uber )
		{
			PrintToChat( iClient, "%t", "RespawnBonus_Uber", flCrits );
			TF2_AddCondition( iClient, TFCond_Ubercharged, flCrits );
			TF2_AddCondition( iClient, TFCond_CritOnKill, flCrits );
		}
		else
		{
			PrintToChat( iClient, "%t", "RespawnBonus_Crits", flCrits );
			TF2_AddCondition( iClient, TFCond_CritOnKill, flCrits );
		}
		StopTimer( hRevengeTimers[iClient] );
		hRevengeTimers[iClient] = CreateTimer( flCrits, Timer_DisableRevengeCrits, iUserID );
	}
	
	if( flBoostDuration > 0.0 && bBoostOnSpawn[iClient] )
	{
		bBoostOnSpawn[iClient] = false;
		
		new Float:flBoost = FloatMin( 30.0, flDistanceMin * flBoostDuration / flSpeed );
		PrintToChat( iClient, "%t", "RespawnBonus_Boost", flBoost );
		TF2_AddCondition( iClient, TFCond_SpeedBuffAlly, flBoost );
	}
	
	bDiedSinceSpawn[iClient] = false;
	return Plugin_Stop;
}
public Action:Timer_DisableRevengeCrits( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !IsValidClient( iClient ) || !bDiedSinceSpawn[iClient] )
		nCritsOnSpawn[iClient] = 0;
	StopTimer( hRevengeTimers[iClient] );
	return Plugin_Stop;
}

public OnPlayerDeath( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iUserID = GetEventInt( hEvent, "userid" );
	new iClient = GetClientOfUserId( iUserID );
	new iKiller = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	if( !( 0 < iClient <= MaxClients ) )
		return;
	
	StopTimer( hRespawnTimers[iClient] );
	
	if( !IsValidClient( iClient ) )
		return;
	
	if( ( GetEventInt( hEvent, "death_flags" ) & TF_DEATHFLAG_DEADRINGER ) == TF_DEATHFLAG_DEADRINGER )
		return;
	
	new RoundState:iRoundState = GameRules_GetRoundState();
	new bool:bNextRound = ( TF2_IsSuddenDeath() || TF2_IsArenaMap() || iRoundState == RoundState_GameOver || iRoundState == RoundState_TeamWin );
	if( bNextRound )
	{
		PrintToChat( iClient, "%t", "RespawnNextRound" );
		return;
	}
	
	if( nCritsOnSpawn[iClient] > 0 )
		bDiedSinceSpawn[iClient] = true;
	else
		nCritsOnSpawn[iClient] = 0;
	
	new Float:flRespawnTimer = flRespawnTime;
	
	if( flRespawnTime < 0.0 )
		flRespawnTimer = 30.0;
	else
	{
		if( nRespawnMode == 1 )
		{
			new Float:flDistance, Float:flNearest = -1.0;
			new nClientTeam = GetClientTeam( iClient );
			new Float:vecClientPos[3], Float:vecSpawnPos[3];
			GetClientAbsOrigin( iClient, vecClientPos );
			
			new iSpawnEnt = -1, iCPEnt = -1, nSPTeam, nCPTeam, String:szCPName[2][64];
			while( ( iSpawnEnt = FindEntityByClassname( iSpawnEnt, "info_player_teamspawn" ) ) != -1 )
			{
				if( GetEntProp( iSpawnEnt, Prop_Data, "m_bDisabled" ) )
					continue;
				
				nSPTeam = GetEntProp( iSpawnEnt, Prop_Send, "m_iTeamNum" );
				if( nSPTeam != nClientTeam )
					continue;
				
				GetEntPropString( iSpawnEnt, Prop_Data, "m_iszControlPointName", szCPName[0], sizeof( szCPName[] ) );
				if( strlen( szCPName[0] ) )
				{
					nCPTeam = -1;
					iCPEnt = -1;
					while( ( iCPEnt = FindEntityByClassname( iCPEnt, "team_control_point" ) ) != -1 )
					{
						GetEntPropString( iCPEnt, Prop_Data, "m_iGlobalname", szCPName[1], sizeof( szCPName[] ) );
						if( StrEqual( szCPName[0], szCPName[1] ) )
						{
							nCPTeam = GetEntProp( iCPEnt, Prop_Send, "m_iTeamNum" );
							break;
						}
					}
					if( iCPEnt != -1 && nSPTeam != nCPTeam )
						continue;
				}
				
				// Calculate distance
				GetEntPropVector( iSpawnEnt, Prop_Data, "m_vecAbsOrigin", vecSpawnPos );
				flDistance = FloatAbs( GetVectorDistance( vecClientPos, vecSpawnPos ) );
				if( flNearest == -1.0 || flNearest > flDistance )
					flNearest = flDistance;
			}
			
			if( flNearest != -1.0 )
			{
				flRespawnTimer = flRespawnTime - flRespawnTimer * FloatMax( flDistance - flDistanceMin, 0.0 ) / flDistanceMax;
				if( flRespawnTimer < FloatMin( flRespawnTime, FloatMax( flRespawnTimeMin, RESPAWN_TIME_WARN ) ) || flDistance > flDistanceMax )
				{
					if( 0 <= iKiller <= MaxClients && iKiller != iClient )
						bBoostOnSpawn[iClient] = true;
					flRespawnTimer = FloatMin( flRespawnTime, FloatMax( flRespawnTimeMin, RESPAWN_TIME_WARN ) );
				}
			}
			
			if( 0 < iKiller <= MaxClients && iKiller != iClient && FloatMax( flRespawnTime, RESPAWN_TIME_WAVE ) - 1.0 <= flRespawnTimer <= FloatMax( flRespawnTime, RESPAWN_TIME_WAVE ) + 1.0 )
				nCritsOnSpawn[iClient]++;
			else
				nCritsOnSpawn[iClient] = 0;
		}
		else if( 0 < iKiller <= MaxClients && iKiller != iClient && flRespawnTime - 1.0 <= flRespawnTimer <= flRespawnTime + 1.0 )
			nCritsOnSpawn[iClient]++;
		else
			nCritsOnSpawn[iClient] = 0;
	}
	
	if( flRespawnTimer > FloatMax( flRespawnTimeMin, RESPAWN_TIME_WARN ) )
	{
		if( flRespawnTime >= 0.0 )
		{
			if( nCritsOnSpawn[iClient] )
				PrintToChat( iClient, "%t", "RevengeIn", flRespawnTimer );
			else
				PrintToChat( iClient, "%t", "RespawnIn", flRespawnTimer );
		}
		hRespawnTimers[iClient] = CreateTimer( flRespawnTimer, Timer_Respawn_Warn, iUserID, TIMER_FLAG_NO_MAPCHANGE );
	}
	else
	{
		if( nCritsOnSpawn[iClient] )
			PrintToChat( iClient, "%t", "RevengeInWarn" );
		else
			PrintToChat( iClient, "%t", "RespawnInWarn" );
		hRespawnTimers[iClient] = CreateTimer( flRespawnTimer, Timer_Respawn, iUserID, TIMER_FLAG_NO_MAPCHANGE );
	}
}

public Action:Timer_Respawn_Warn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !( 0 < iClient <= MaxClients ) )
		return Plugin_Stop;
	
	if( hRespawnTimers[iClient] == INVALID_HANDLE )
	{
		PrintToChat( iClient, "%t", "RespawnCancelled" );
		return Plugin_Stop;
	}
	else
		StopTimer( hRespawnTimers[iClient] );
	
	if( !IsValidClient( iClient ) || IsPlayerAlive( iClient ) )
		return Plugin_Stop;
	
	new RoundState:iRoundState = GameRules_GetRoundState();
	if( TF2_IsSuddenDeath() || TF2_IsArenaMap() || iRoundState == RoundState_GameOver || iRoundState == RoundState_TeamWin )
		return Plugin_Stop;
	
	if( nCritsOnSpawn[iClient] )
		PrintToChat( iClient, "%t", "RevengeInWarn" );
	else
		PrintToChat( iClient, "%t", "RespawnInWarn" );
	hRespawnTimers[iClient] = CreateTimer( RESPAWN_TIME_WARN, Timer_Respawn, iUserID );
	return Plugin_Stop;
}

public Action:Timer_Respawn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( !( 0 < iClient <= MaxClients ) )
		return Plugin_Stop;
	
	if( hRespawnTimers[iClient] == INVALID_HANDLE )
	{
		PrintToChat( iClient, "%t", "RespawnCancelled" );
		return Plugin_Stop;
	}
	else
		StopTimer( hRespawnTimers[iClient] );
	
	if( !IsValidClient( iClient ) || IsPlayerAlive( iClient ) )
		return Plugin_Stop;
	
	new RoundState:iRoundState = GameRules_GetRoundState();
	if( TF2_IsSuddenDeath() || TF2_IsArenaMap() || iRoundState == RoundState_GameOver || iRoundState == RoundState_TeamWin )
		return Plugin_Stop;
	
	TF2_RespawnPlayer( iClient );
	return Plugin_Stop;
}

SetTags()
{
	if( flRespawnTime > 0.0 )
	{
		RemoveTag( "norespawntime" );
		AddTag( "respawntimes" );
	}
	else if( flRespawnTime == 0 )
	{
		RemoveTag( "respawntimes" );
		AddTag( "norespawntime" );
	}
	else
	{
		RemoveTag( "respawntimes" );
		RemoveTag( "norespawntime" );
	}
}

stock AddTag( const String:strTag[] )
{
	if( sv_tags == INVALID_HANDLE )
		return;
	decl String:strBuffer[576], String:strOldTags[24][24], String:strNewTags[24][24];
	GetConVarString( sv_tags, strBuffer, sizeof( strBuffer ) );
	new nTags = ExplodeString( strBuffer, ",", strOldTags, sizeof( strOldTags ), sizeof( strOldTags[] ) );
	for( new n = 1, o = 0; o < nTags; o++ )
	{
		if( n >= 24 || StrEqual( strOldTags[o], strTag, false ) )
			return;
		strcopy( strNewTags[n++], sizeof( strNewTags[] ), strOldTags[o] );
	}
	strcopy( strNewTags[0], sizeof( strNewTags[] ), strTag );
	ImplodeStrings( strNewTags, sizeof( strNewTags ), ",", strBuffer, sizeof( strBuffer ) );
	SetConVarString( sv_tags, strBuffer );
}
stock RemoveTag( const String:strTag[] )
{
	if( sv_tags == INVALID_HANDLE )
		return;
	decl String:strBuffer[576], String:strOldTags[24][24], String:strNewTags[24][24];
	GetConVarString( sv_tags, strBuffer, sizeof( strBuffer ) );
	new nTags = ExplodeString( strBuffer, ",", strOldTags, sizeof( strOldTags ), sizeof( strOldTags[] ) );
	for( new n = 0, o = 0; o < nTags; o++ )
	{
		if( StrEqual( strOldTags[o], strTag, false ) )
			continue;
		strcopy( strNewTags[n++], sizeof( strNewTags[] ), strOldTags[o] );
	}
	ImplodeStrings( strNewTags, sizeof( strNewTags ), ",", strBuffer, sizeof( strBuffer ) );
	SetConVarString( sv_tags, strBuffer );
}

stock CreateParticle( Float:flOrigin[3], Float:flAngles[3] = NULL_VECTOR, const String:strParticle[], Float:flDuration = -1.0 )
{
	new iParticle = CreateEntityByName( "info_particle_system" );
	if( IsValidEdict( iParticle ) )
	{
		DispatchKeyValue( iParticle, "effect_name", strParticle );
		DispatchSpawn( iParticle );
		TeleportEntity( iParticle, flOrigin, flAngles, NULL_VECTOR );
		ActivateEntity( iParticle );
		AcceptEntityInput( iParticle, "Start" );
		if( flDuration >= 0.0 )
			CreateTimer( flDuration, RemoveParticle, EntIndexToEntRef(iParticle) );
	}
	return iParticle;
}
public Action:RemoveParticle( Handle:timer, any:iEntRef )
{
	new iEntity = EntRefToEntIndex( iEntRef );
	if( iEntity > 0 && IsValidEntity( iEntity ) )
	{
		new String:strClassname[32];
		GetEdictClassname( iEntity, strClassname, sizeof(strClassname) );
		if( StrEqual( strClassname, "info_particle_system", false ) )
		{
			AcceptEntityInput( iEntity, "Stop");
			AcceptEntityInput( iEntity, "Kill");
		}
	}
}

stock SetPlayerNextSpawn( iClient, Float:flNextSpawn )
{
	if( flNextSpawn < 0.0 || !IsValidClient( iClient ) )
		return false;
	if( flNextSpawn > 0.0 )
		GameRules_SetPropFloat( "m_flNextRespawnWave", flNextSpawn, iClient, true );
	else
		TF2_RespawnPlayer( iClient );
	return true;
}

stock TF2_IsArenaMap( bool:bRecalc = false )
{
	static bool:bChecked = false;
	static bool:bArena = false;
	if( bRecalc || !bChecked )
	{
		new iEnt = FindEntityByClassname( -1, "tf_logic_arena" );
		bArena = ( iEnt > MaxClients && IsValidEntity( iEnt ) );
		bChecked = true;
	}
	return bArena;
}

stock TF2_IsMultiStage( bool:bRecalc = false )
{
	static bool:bChecked = false;
	static bool:bStages = false;
	if( bRecalc || !bChecked )
	{
		new iEnt = FindEntityByClassname( -1, "team_control_point_master" );
		bStages = ( iEnt > MaxClients && IsValidEntity( iEnt ) && GetEntProp( iEnt, Prop_Data, "m_bPlayAllRounds" ) );
		bChecked = true;
	}
	return bStages;
}

stock bool:TF2_IsSuddenDeath()
{
	if( !GetConVarBool( FindConVar( "mp_stalemate_enable" ) ) )
		return false;
	if( TF2_IsArenaMap() )
		return false;
	if( GameRules_GetRoundState() == RoundState_Stalemate )
		return true;
	return false;
}

stock StopTimer( &Handle:hTimer = INVALID_HANDLE )
{
	if( hTimer != INVALID_HANDLE )
		KillTimer( hTimer );
	hTimer = INVALID_HANDLE;
}

stock Float:FloatMin( Float:flVal1, Float:flVal2 )
	return ( flVal1 > flVal2 ? flVal2 : flVal1 );
stock Float:FloatMax( Float:flVal1, Float:flVal2 )
	return ( flVal1 > flVal2 ? flVal1 : flVal2 );

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	if( !IsClientInGame(iClient) ) return false;
	return true;
}