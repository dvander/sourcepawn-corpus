#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define TEAM_SPECTATORS 1

#define PLUGIN_VERSION "1.0.0"

/////////////
/* Globals */

new Handle:sm_tf2bqf_version = INVALID_HANDLE;
new Handle:sm_tf2bqf_enable = INVALID_HANDLE;
new Handle:tf_bot_quota = INVALID_HANDLE;
new Handle:tf_bot_quota_mode = INVALID_HANDLE;

new bool:bPluginEnabled = false;
new bool:bQuotaFillMode = false;
new _:nNewBotQuota = 0;
new _:nCurrentQuota = 0;
new _:nOriginalQuota = 0;

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
	sm_tf2bqf_version = CreateConVar( "sm_tf2bqf_version", PLUGIN_VERSION, "TF2 Bot Quota Fix", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_tf2bqf_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_tf2bqf_version, OnConVarChanged_PluginVersion );
	
	
	decl String:sGameDir[8];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if(!StrEqual(sGameDir, "tf", false) && !StrEqual(sGameDir, "tf_beta", false))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	
	tf_bot_quota = FindConVar( "tf_bot_quota" );
	if( tf_bot_quota == INVALID_HANDLE )
		SetFailState("Failed to find tf_bot_quota");
	HookConVarChange( tf_bot_quota, OnConVarChanged_Quota );
	
	tf_bot_quota_mode = FindConVar( "tf_bot_quota_mode" );
	if( tf_bot_quota_mode == INVALID_HANDLE )
		SetFailState("Failed to find tf_bot_quota_mode");
	HookConVarChange( tf_bot_quota_mode, OnConVarChanged_QuotaMode );
	
	sm_tf2bqf_enable = CreateConVar( "sm_tf2bqf_enable", "1", "", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	HookConVarChange( sm_tf2bqf_enable, OnConVarChanged );
	
	
	OnConfigsExecuted();
}

public OnPluginEnd()
{
	bChangedByPlugin = true;
	SetConVarInt( tf_bot_quota, nOriginalQuota, false, false );
	bChangedByPlugin = false;
}

public OnConfigsExecuted()
{
	bPluginEnabled = !!GetConVarInt( sm_tf2bqf_enable );
	
	decl String:strQuotaMode[8];
	GetConVarString( tf_bot_quota_mode, strQuotaMode, sizeof(strQuotaMode) );
	
	bQuotaFillMode = ( strcmp( strQuotaMode, "fill", false ) == 0 );
	
	nOriginalQuota = nNewBotQuota = nCurrentQuota = GetConVarInt( tf_bot_quota );
}

public OnGameFrame()
{
	if( !bPluginEnabled )
		return;
	if( !bQuotaFillMode )
		return;
	
	new iClient, nSpectators = 0;
	for( iClient = 1; iClient <= MaxClients; iClient++ )
		if( IsValidClient( iClient ) && GetClientTeam( iClient ) == TEAM_SPECTATORS )
			nSpectators++;
	
	//PrintToServer( "%d + %d %s= %d", nNewBotQuota, nSpectators, (nNewBotQuota + nSpectators)==nCurrentQuota?"=":"!", nCurrentQuota );
	
	if( ( nNewBotQuota + nSpectators ) != nCurrentQuota )
	{
		bChangedByPlugin = true;
		SetConVarInt( tf_bot_quota, nNewBotQuota + nSpectators, false, false );
		bChangedByPlugin = false;
	}
}

//////////////////
/* CVars & CMDs */

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
public OnConVarChanged_Quota( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
{
	if( !bChangedByPlugin )
		nNewBotQuota = StringToInt( strNewValue );
	nCurrentQuota = StringToInt( strNewValue );
}
public OnConVarChanged_QuotaMode( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	bQuotaFillMode = ( strcmp( strNewValue, "fill", false ) == 0 );
public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

////////////
/* STOCKS */

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}