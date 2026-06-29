#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1.1-20140202"

#define PLUGIN_REPLY_PREFIX "[NMP-TKP] "


new Handle:nmp_tkp_version = INVALID_HANDLE;
new Handle:nmp_tkp_warn = INVALID_HANDLE;
new Handle:nmp_tkp_min_kills = INVALID_HANDLE;
new Handle:nmp_tkp_kick_only = INVALID_HANDLE;
new Handle:nmp_tkp_ban_time = INVALID_HANDLE;
new Handle:nmp_tkp_cool_down = INVALID_HANDLE;
new Handle:nmp_tkp_no_infected = INVALID_HANDLE;
new Handle:nmp_tkp_multikill = INVALID_HANDLE;
new Handle:nmp_tkp_debug = INVALID_HANDLE;

new bool:bFirstWarn = true;
new bool:bKickOnly = false;
new iBanDuration = 600;
new iMinKills = 3;
new Float:flCoolDown = 60.0;
new bool:bAllowInfected = true;
new bool:bMultikill = false;
new nDebugMode = 0;

new iKills[MAXPLAYERS+1];
new Float:flLastTK[MAXPLAYERS+1];
new Float:flLastCD[MAXPLAYERS+1];
new bool:bSilentDeath[MAXPLAYERS+1];
new bool:bKillOnSpawn[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "[NMRiH] Team Kill Punishment",
	author = "Leonardo",
	description = "Kill me one - shame on you. Kill me twice - also shame on you. Kill me three time - you'll be banned.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};


public OnPluginStart()
{
	LoadTranslations( "common.phrases.txt" );
	LoadTranslations( "nmp_tkp.phrases.txt" );
	
	nmp_tkp_version = CreateConVar( "nmp_tkp_version", PLUGIN_VERSION, "NoMorePlugins Team Kill Punishment", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	SetConVarString( nmp_tkp_version, PLUGIN_VERSION );
	HookConVarChange( nmp_tkp_version, OnConVarChanged_Version );
	
	HookConVarChange( nmp_tkp_warn = CreateConVar( "nmp_tkp_warn", bFirstWarn ? "1" : "0", "Warn on first TK.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_kick_only = CreateConVar( "nmp_tkp_kick_only", bKickOnly ? "1" : "0", "Just kick TKers.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_min_kills = CreateConVar( "nmp_tkp_min_kills", "3", "Amount of killed teammates required to punish.", FCVAR_PLUGIN, true, 0.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_ban_time = CreateConVar( "nmp_tkp_ban_time", "30", "Ban time in minutes. (0 = permanent)", FCVAR_PLUGIN, true, 0.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_cool_down = CreateConVar( "nmp_tkp_cool_down", "90", "Cooldown (TK count decrease) frequency. (in seconds)", FCVAR_PLUGIN, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_no_infected = CreateConVar( "nmp_tkp_no_infected", bAllowInfected ? "1" : "0", "Do not punish for killing infected mates.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_multikill = CreateConVar( "nmp_tkp_multikill", bMultikill ? "1" : "0", "Count multikill as a single kill.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_debug = CreateConVar( "nmp_tkp_debug", "0", "Debug messages:\n0 - disabled,\n1 - server console only,\n2 - server console and logs.", FCVAR_PLUGIN, true, 0.0, true, 2.0 ), OnConVarChanged );
	
	AutoExecConfig( true, "plugin.nmp_tkp" );
	
	HookEvent( "player_spawn", Event_PlayerSpawn_Post, EventHookMode_Post );
	HookEvent( "player_death", Event_PlayerDeath_Post, EventHookMode_Post );
	HookEvent( "player_death", Event_PlayerDeath_Pre, EventHookMode_Pre );
	
	CreateTimer( 1.0, Timer_CoolDown, _, TIMER_REPEAT );
	
	for( new i = 0; i <= MAXPLAYERS; i++ )
		if( 0 < i <= MaxClients && IsClientInGame( i ) )
			OnClientPutInServer( i );
		else
			OnClientDisconnect_Post( i );
}

public OnConfigsExecuted()
{
	bFirstWarn = GetConVarBool( nmp_tkp_warn );
	bKickOnly = GetConVarBool( nmp_tkp_kick_only );
	iMinKills = GetConVarInt( nmp_tkp_min_kills );
	iBanDuration = GetConVarInt( nmp_tkp_ban_time );
	flCoolDown = float( GetConVarInt( nmp_tkp_cool_down ) );
	bAllowInfected = GetConVarBool( nmp_tkp_no_infected );
	bMultikill = GetConVarBool( nmp_tkp_multikill );
	nDebugMode = GetConVarInt( nmp_tkp_debug );
}


public OnConVarChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[]) {
    OnConfigsExecuted();
}

public OnConVarChanged_Version(Handle:hConVar, const String:szOldValue[], const String:szNewValue[]) {
    if (strcmp(szNewValue, PLUGIN_VERSION, false)) {
        SetConVarString(view_as<ConVar>(hConVar), PLUGIN_VERSION, true, true);
    }
}


public OnClientPutInServer( iClient )
{
	OnClientDisconnect_Post( iClient );
	//SDKHook( iClient, SDKHook_OnTakeDamage, OnClientTakeDamage );
}

public OnClientDisconnect_Post( iClient )
{
	iKills[iClient] = 0;
	flLastTK[iClient] = -1.0;
	flLastCD[iClient] = GetGameTime();
	bSilentDeath[iClient] = false;
	bKillOnSpawn[iClient] = false;
}


public Action:OnClientTakeDamage( iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamageType )
{
	if( iAttacker <= 0 || iAttacker > MaxClients || iVictim <= 0 || iVictim > MaxClients || iVictim == iAttacker )
		return Plugin_Continue;
	
	if( GetUserFlagBits( iAttacker ) & ADMFLAG_ROOT )
		return Plugin_Continue;
	
	if( CheckCommandAccess( iVictim, "tk_hurt_immunity", ADMFLAG_ROOT, true ) )
	{
		flDamage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}


public Event_PlayerSpawn_Post( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	
	if( iClient <= 0 || iClient > MaxClients || !bKillOnSpawn[iClient] || !IsClientInGame( iClient ) )
		return;
	
	DebugMessage( "PvP: %N (%d) killed temmate [late slay]", iClient, iKills[iClient] );
	KillPlayer( iClient );
}

public Action:Event_PlayerDeath_Pre( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
	{
		SetEventBroadcast( hEvent, bSilentDeath[iClient] );
		if( bSilentDeath[iClient] )
			bSilentDeath[iClient] = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Event_PlayerDeath_Post( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iVictim = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	new iAttacker = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	
	if(
		iVictim == iAttacker
		|| !( 0 < iVictim <= MaxClients )
		|| !IsClientInGame( iVictim )
		|| !( 0 < iAttacker <= MaxClients )
		|| !IsClientInGame( iAttacker )
		|| IsFakeClient( iAttacker )
	)
		return;
	
	new Float:flCurTime = GetGameTime();
	
	if( bAllowInfected && GetEntPropFloat( iVictim, Prop_Send, "m_flInfectionDeathTime" ) >= 0.0 )
	{
		DebugMessage( "PvP: %N (%d) killed %N (%d) [ignore:infected]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
		return;
	}
	
	if( bMultikill && ( flCurTime - flLastTK[iAttacker] ) < 0.1 )
	{
		DebugMessage( "PvP: %N (%d) killed %N (%d) [ignore:multikill]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
		return;
	}
	
	flLastTK[iAttacker] = flCurTime;
	iKills[iAttacker]++;
	
	if( iKills[iAttacker] >= iMinKills && !bKickOnly && !CheckCommandAccess( iAttacker, "tk_ban_immunity", ADMFLAG_UNBAN, true ) )
	{
		DebugMessage( "PvP: %N (%d) killed %N (%d) [punish:ban]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
		PrintToChatAll( "%t (%N)", "NMP Ban Message", iAttacker );
		BanPlayer( iAttacker, iBanDuration, "%t", "NMP Ban Message" );
	}
	else if( iKills[iAttacker] >= iMinKills && !CheckCommandAccess( iAttacker, "tk_kick_immunity", ADMFLAG_KICK, true ) )
	{
		DebugMessage( "PvP: %N (%d) killed %N (%d) [punish:kick]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
		PrintToChatAll( "%t (%N)", "NMP Kick Message", iAttacker );
		CreateTimer( 1.0, Timer_Kick, GetClientUserId( iAttacker ), TIMER_REPEAT );
	}
	else if( iKills[iAttacker] <= _:bFirstWarn )
	{
		DebugMessage( "PvP: %N (%d) killed %N (%d) [punish:warn]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
		PrintToChat( iAttacker, "%t", "NMP Warn Message" );
	}
	else if( CheckCommandAccess( iAttacker, "tk_slay_immunity", ADMFLAG_ROOT, true ) )
		DebugMessage( "PvP: %N (%d) killed %N (%d) [ignore:immune]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
	else if( !IsPlayerAlive( iAttacker ) )
	{
		DebugMessage( "PvP: %N (%d) killed %N (%d) [delay:dead]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
		bKillOnSpawn[iAttacker] = true;
	}
	else
	{
		DebugMessage( "PvP: %N (%d) killed %N (%d) [punish:slay]", iAttacker, iKills[iAttacker], iVictim, iKills[iVictim] );
		KillPlayer( iAttacker );
	}
}


public Action:Timer_CoolDown( Handle:hTimer, any:iUnused )
{
	new Float:flCurTime = GetGameTime();
	for( new i = 1; i <= MaxClients; i++ )
		if( iKills[i] > 1 && IsClientInGame( i ) && ( flCurTime - flLastCD[i] ) > flCoolDown && ( flCurTime - flLastTK[i] ) > flCoolDown )
		{
			iKills[i]--;
			flLastCD[i] = flCurTime;
			DebugMessage( "PvP: %N's TK counter decreased to %d", i, iKills[i] );
		}
	return Plugin_Handled;
}


enum
{
	ExternalBan_Unknown = -1,
	ExternalBan_None,
	ExternalBan_SourceBans,
	ExternalBan_MySQLBans
}

stock BanPlayer( iClient, iDuration = 0, const String:szFormat[] = "", any:... )
{
	new String:szReason[120];
	SetGlobalTransTarget( iClient );
	VFormat( szReason, sizeof( szReason ), szFormat, 4 );
	
	static nExternalBan = ExternalBan_Unknown;
	
	if( nExternalBan == ExternalBan_Unknown )
	{
		new Handle:hConVar = FindConVar( "sb_version" );
		if ( hConVar != INVALID_HANDLE )
			nExternalBan = ExternalBan_SourceBans;
		else
		{
			hConVar = FindConVar( "mysql_bans_version" );
			if( hConVar != INVALID_HANDLE )
				nExternalBan = ExternalBan_MySQLBans;
			else
				nExternalBan = ExternalBan_None;
		}
		if( hConVar != INVALID_HANDLE )
			CloseHandle( hConVar );
	}
	
	switch( nExternalBan )
	{
		case ExternalBan_SourceBans:
			ServerCommand( "sm_ban #%d %d \"%s\"", GetClientUserId( iClient ), iDuration, szReason );
		case ExternalBan_MySQLBans:
			ServerCommand( "mysql_ban #%d %d \"%s\"", GetClientUserId( iClient ), iDuration, szReason );
		default:
		{
			new String:szMessage[120];
			Format( szMessage, sizeof( szMessage ), "You have been banned for %d minutes.", iDuration );
			BanClient( iClient, iDuration, BANFLAG_AUTHID, szReason, szMessage );
		}
	}
	
	CreateTimer( 1.0, Timer_Kick, GetClientUserId( iClient ), TIMER_REPEAT );
}
public Action:Timer_Kick( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
	{
		KickClient( iClient, "%t", "NMP Kick Message" );
		return Plugin_Handled;
	}
	return Plugin_Stop;
}

stock KillPlayer( iClient )
{
	bKillOnSpawn[iClient] = false;
	bSilentDeath[iClient] = true;
	ForcePlayerSuicide( iClient );
	PrintToChatAll( "%s%t", PLUGIN_REPLY_PREFIX, "NMP Slay Message", iClient );
}

stock DebugMessage( const String:szFormat[] = "", any:... )
{
	if( nDebugMode <= 0 || nDebugMode > 2 )
		return;
	
	new String:szMessage[251];
	SetGlobalTransTarget( 0 );
	VFormat( szMessage, sizeof( szMessage ), szFormat, 4 );
	
	PrintToServer( szMessage );
	
	if( nDebugMode < 2 )
		return;
	
	new String:szFile[PLATFORM_MAX_PATH];
	FormatTime( szFile, sizeof( szFile ), "%Y%m%d" );
	BuildPath( Path_SM, szFile, sizeof( szFile ), "logs/nmp_tkp_%s.log", szFile );
	LogToFile( szFile, szMessage );
}