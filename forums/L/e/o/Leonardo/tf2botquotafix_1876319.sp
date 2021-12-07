#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

//#define DEBUG_MSG 1

/////////////
/* Globals */

new Handle:sm_tf2bqf_version = INVALID_HANDLE;
new Handle:sm_tf2bqf_enable = INVALID_HANDLE;
new Handle:sm_tf2bqf_debug = INVALID_HANDLE;
new Handle:sm_tf2bqf_count = INVALID_HANDLE;
new Handle:sm_tf2bqf_mode = INVALID_HANDLE;
new Handle:tf_bot_quota_mode = INVALID_HANDLE;
new Handle:tf_bot_quota = INVALID_HANDLE;

new bool:bPluginLocked = false;
new bool:bPluginEnabled = false;
new bool:bDebugMode = false;
new bool:bQuotaFillMode = false;
new _:nNewBotQuota = 0;
new _:nCurrentQuota = 0;
new _:nOriginalQuota = 0;
new _:nOverrideMode = 1;
new _:nOverrideQuota = 0;

new bool:bChangedByPlugin = false;

/////////////////
/* Plugin info */

public Plugin:myinfo = {
	name = "[TF2] Bot Quota Fix",
	author = "Leonardo",
	description = "Keeps right playing bots count in Fill mode",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
};

////////////
/* Events */

public OnPluginStart()
{
	bPluginLocked = true;
	
	sm_tf2bqf_version = CreateConVar( "sm_tf2bqf_version", PLUGIN_VERSION, "TF2 Bot Quota Fix", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD );
	SetConVarString( sm_tf2bqf_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2bqf_version, OnConVarChange_PluginVersion );
	
	
	decl String:strGameDir[8];
	GetGameFolderName( strGameDir, sizeof( strGameDir ) );
	if( !StrEqual( strGameDir, "tf", false ) && !StrEqual( strGameDir, "tf_beta", false ) )
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	
	tf_bot_quota = FindConVar( "tf_bot_quota" );
	if( tf_bot_quota == INVALID_HANDLE )
		SetFailState( "Failed to find tf_bot_quota" );
	HookConVarChange( tf_bot_quota, OnConVarChange_Quota );
	
	tf_bot_quota_mode = FindConVar( "tf_bot_quota_mode" );
	if( tf_bot_quota_mode == INVALID_HANDLE )
		SetFailState( "Failed to find tf_bot_quota_mode" );
	HookConVarChange( tf_bot_quota_mode, OnConVarChange_QuotaMode );
	
	HookConVarChange( sm_tf2bqf_enable = CreateConVar( "sm_tf2bqf_enable", "1", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChange );
	HookConVarChange( sm_tf2bqf_debug = CreateConVar( "sm_tf2bqf_debug", "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChange );
	HookConVarChange( sm_tf2bqf_count = CreateConVar( "sm_tf2bqf_count", "0", _, FCVAR_PLUGIN, true, 0.0 ), OnConVarChange_OverrideCount );
	HookConVarChange( sm_tf2bqf_mode = CreateConVar( "sm_tf2bqf_mode", "1", "1 - Fix tf_bot_quota on the fly;\n2 - First: sm_tf2bqf_count = tf_bot_quota; Then: tf_bot_quota = sm_tf2bqf_count + spectators;\n3 - tf_bot_quota = sm_tf2bqf_count + spectators.", FCVAR_PLUGIN, true, 1.0, true, 3.0 ), OnConVarChange_OverrideCountMode );
	
	AutoExecConfig( true );
}

public OnMapEnd()
	OnPluginEnd();

public OnPluginEnd()
{
	bPluginLocked = true;
	SetBotQuota( nOriginalQuota );
}

public OnConfigsExecuted()
{
	bPluginEnabled = !!GetConVarInt( sm_tf2bqf_enable );
	bDebugMode = !!GetConVarInt( sm_tf2bqf_debug );
	
	decl String:strQuotaMode[8];
	GetConVarString( tf_bot_quota_mode, strQuotaMode, sizeof(strQuotaMode) );
	bQuotaFillMode = ( strcmp( strQuotaMode, "fill", false ) == 0 );
	
	nOriginalQuota = nNewBotQuota = nCurrentQuota = GetConVarInt( tf_bot_quota );
	
	nOverrideMode = GetConVarInt( sm_tf2bqf_mode );
	nOverrideQuota = nOverrideMode == 2 ? nOriginalQuota : GetConVarInt( sm_tf2bqf_count );
	
	bPluginLocked = false;
}

public OnGameFrame()
{
	static Float:flLastMsg;
	
	if( bPluginLocked || !bPluginEnabled || !bQuotaFillMode )
		return;
	
	new RoundState:nState = GameRules_GetRoundState();
	if( /*nState <= RoundState_Init ||*/ nState == RoundState_GameOver )
		return;
	
	new nSpectators = 0;
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
		if( IsClientInGame( iClient ) && GetClientTeam( iClient ) == 1 )
		{
			nSpectators++;
			if( bDebugMode && ( flLastMsg + 1.0 ) < GetEngineTime() )
				PrintToServer( "spectator %L", iClient );
		}
	
	if( 2 <= nOverrideMode <= 3 )
	{
		if( bDebugMode && ( flLastMsg + 1.0 ) < GetEngineTime() )
			PrintToServer( "%d + %d %s= %d (override:%d)", nOverrideQuota, nSpectators, ( nOverrideQuota + nSpectators ) == nCurrentQuota ? "=":"!", nCurrentQuota, nOverrideMode );
		if( ( nOverrideQuota + nSpectators ) != nCurrentQuota )
			SetBotQuota( nOverrideQuota + nSpectators );
	}
	else if( nState <= RoundState_Pregame )
	{
		if( bDebugMode && ( flLastMsg + 1.0 ) < GetEngineTime() )
			PrintToServer( "%d + %d %s= %d (pregame)", nOriginalQuota, nSpectators, ( nOriginalQuota + nSpectators ) == nCurrentQuota ? "=":"!", nCurrentQuota );
		if( ( nOriginalQuota + nSpectators ) != nCurrentQuota )
			SetBotQuota( nOriginalQuota + nSpectators );
	}
	else
	{
		if( bDebugMode && ( flLastMsg + 1.0 ) < GetEngineTime() )
			PrintToServer( "%d + %d %s= %d (normal)", nNewBotQuota, nSpectators, ( nNewBotQuota + nSpectators ) == nCurrentQuota ? "=":"!", nCurrentQuota );
		if( ( nNewBotQuota + nSpectators ) != nCurrentQuota )
			SetBotQuota( nNewBotQuota + nSpectators );
	}
	
	if( bDebugMode && ( flLastMsg + 1.0 ) < GetEngineTime() )
		flLastMsg = GetEngineTime();
}

//////////////////
/* CVars & CMDs */

public OnConVarChange_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( !StrEqual( strNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
public OnConVarChange_Quota( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( bChangedByPlugin ) nCurrentQuota = StringToInt( strNewValue );
	else nNewBotQuota = StringToInt( strNewValue );
public OnConVarChange_QuotaMode( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	bQuotaFillMode = StrEqual( strNewValue, "fill", false );
public OnConVarChange_OverrideCount( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( nOverrideMode == 2 )
	{
		nOverrideQuota = GetBotQuota();
		SetConVarInt( hConVar, nOverrideQuota, false, false );
	}
	else
		nOverrideQuota = StringToInt( strNewValue );
public OnConVarChange_OverrideCountMode( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
{
	nOverrideMode = StringToInt( strNewValue );
	if( nOverrideMode == 2 )
		SetConVarInt( sm_tf2bqf_count, GetBotQuota(), false, false );
}
public OnConVarChange( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

////////////
/* Stocks */

stock GetBotQuota()
{
	if( tf_bot_quota != INVALID_HANDLE )
		return GetConVarInt( tf_bot_quota );
	return 0;
}
stock SetBotQuota( iValue = 0 )
{
	if( tf_bot_quota != INVALID_HANDLE )
	{
		bChangedByPlugin = true;
		SetConVarInt( tf_bot_quota, iValue, false, false );
		bChangedByPlugin = false;
	}
}