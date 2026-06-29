#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION			"1.3.2-20181014"

#define PLUGIN_LOG_PREFIX		"[NMP-TKP] "
#define PLUGIN_CHAT_PREFIX		"\x01[TKP]\x03 "

#define CHAT_COLOR_PRIMARY		3
#define CHAT_COLOR_SECONDARY	1


new Handle:nmp_tkp_version = INVALID_HANDLE;
new Handle:nmp_tkp_debug = INVALID_HANDLE;
new Handle:nmp_tkp_silent = INVALID_HANDLE;
new Handle:nmp_tkp_leo_suck = INVALID_HANDLE;
new Handle:nmp_tkp_team_attacks = INVALID_HANDLE;
new Handle:nmp_tkp_slay_on_ta = INVALID_HANDLE;
new Handle:nmp_tkp_ta_cooldown = INVALID_HANDLE;
new Handle:nmp_tkp_min_kills = INVALID_HANDLE;
new Handle:nmp_tkp_ban_time = INVALID_HANDLE;
new Handle:nmp_tkp_ban_cleanup = INVALID_HANDLE;
new Handle:nmp_tkp_notify = INVALID_HANDLE;
new Handle:nmp_tkp_menu_time = INVALID_HANDLE;
new Handle:nmp_tkp_allow_forgive = INVALID_HANDLE;
new Handle:nmp_tkp_allow_slap = INVALID_HANDLE;
new Handle:nmp_tkp_allow_slay = INVALID_HANDLE;
//new Handle:nmp_tkp_allow_bury = INVALID_HANDLE;
new Handle:nmp_tkp_allow_infect = INVALID_HANDLE;
new Handle:nmp_tkp_allow_disarm = INVALID_HANDLE;
new Handle:nmp_tkp_allow_revenge = INVALID_HANDLE;

new nDebugMode = 0;
new bool:bSilentAdmin = true;
new bool:bLeoSuck = false;
new iMinAttacks = 4;
new bool:bSlayOnTA = false;
new Float:flTACooldown = 30.0;
new iMinKills = 3;
new iBanDuration = 30;
new bool:bCleanUpOnBan = true;
new bool:bNotify = true;
new iMenuTime = 15;
new bool:bAllowForgive = true;
new bool:bAllowSlap = true;
new bool:bAllowSlay = true;
//new bool:bAllowBury = true;
new bool:bAllowInfect = true;
new bool:bAllowDisarm = true;
new nAllowRevenge = 2;

new nTeamAttacks[MAXPLAYERS+1];
new nTeamKills[MAXPLAYERS+1];
new Float:flLastTA[MAXPLAYERS+1];
new Float:flLastTK[MAXPLAYERS+1];
new Handle:hPunishTimer[MAXPLAYERS+1];
new Handle:hPunishMenu[MAXPLAYERS+1];
new iPunisher[MAXPLAYERS+1];
new nPunishment[MAXPLAYERS+1];

new Handle:hDataTable = INVALID_HANDLE;
new bool:bPreGame = false;
new Float:flLastTACD = 0.0;

enum
{
	Punishment_None = -1,
	
	Punishment_Forgive,
	Punishment_Increase,
	Punishment_Slap,
	Punishment_Slay,
	//Punishment_Bury,
	Punishment_Infect,
	Punishment_Disarm,
	
	Punishment_Revenge,
	
	Punishment_Max
}

enum
{
	ExternalBan_Unknown = -1,
	ExternalBan_None,
	ExternalBan_SourceBans,
	ExternalBan_MySQLBans
}

public Plugin:myinfo =
{
	name = "[NMRiH] Team Kill Punishment",
	author = "Leonardo",
	description = "Punching TKers in the face since January 6th, 2014.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};


public OnPluginStart()
{
	LoadTranslations( "common.phrases.txt" );
	LoadTranslations( "nmp_tkp.phrases.txt" );
	
	nmp_tkp_version = CreateConVar( "nmp_tkp_version", PLUGIN_VERSION, "NoMorePlugins Team Kill Punishment", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY );
	SetConVarString( nmp_tkp_version, PLUGIN_VERSION );
	HookConVarChange( nmp_tkp_version, OnConVarChanged_Version );
	
	HookConVarChange( nmp_tkp_debug = CreateConVar( "nmp_tkp_debug", "0", "Debug messages:\n0 - disabled,\n1 - server console only,\n2 - server console and logs.", FCVAR_PLUGIN, true, 0.0, true, 2.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_silent = CreateConVar( "nmp_tkp_silent", bSilentAdmin ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_leo_suck = CreateConVar( "nmp_tkp_leo_suck", bLeoSuck ? "1" : "0", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_team_attacks = CreateConVar( "nmp_tkp_team_attacks", "5", "Number of team attacks to count as team kill. (-1 = disabled)", FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( nmp_tkp_slay_on_ta = CreateConVar( "nmp_tkp_slay_on_ta", bSlayOnTA ? "1" : "0", "Simply slay players after nmp_tkp_team_attacks team attacks, show TK menu otherwise.", FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( nmp_tkp_ta_cooldown = CreateConVar( "nmp_tkp_ta_cooldown", "25.0", "(Less than 1.0 = disabled)", FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( nmp_tkp_min_kills = CreateConVar( "nmp_tkp_min_kills", "3", "Amount of killed teammates required to ban/kick.", FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( nmp_tkp_ban_time = CreateConVar( "nmp_tkp_ban_time", "30", "Ban time in minutes. (0 = permanent, -1 = kick only)", FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( nmp_tkp_ban_cleanup = CreateConVar( "nmp_tkp_ban_cleanup", bCleanUpOnBan ? "1" : "0", "Remove TKer data on ban.", FCVAR_PLUGIN ), OnConVarChanged );
	HookConVarChange( nmp_tkp_notify = CreateConVar( "nmp_tkp_notify", bNotify ? "1" : "0", "Print notifications.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_menu_time = CreateConVar( "nmp_tkp_menu_time", "15", "Seconds to react, automatically pick punishment otherwise. (0 = instant)", FCVAR_PLUGIN, true, 0.0, true, 60.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_allow_forgive = CreateConVar( "nmp_tkp_allow_forgive", bAllowForgive ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_allow_slap = CreateConVar( "nmp_tkp_allow_slap", bAllowSlap ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_allow_slay = CreateConVar( "nmp_tkp_allow_slay", bAllowSlay ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	//HookConVarChange( nmp_tkp_allow_bury = CreateConVar( "nmp_tkp_allow_bury", bAllowBury ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_allow_infect = CreateConVar( "nmp_tkp_allow_infect", bAllowInfect ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_allow_disarm = CreateConVar( "nmp_tkp_allow_disarm", bAllowDisarm ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_tkp_allow_revenge = CreateConVar( "nmp_tkp_allow_revenge", "2", _, FCVAR_PLUGIN, true, 0.0, true, 2.0 ), OnConVarChanged );
	
	AutoExecConfig( true, "plugin.nmp_tkp" );
	
	RegAdminCmd( "sm_tkp_reset_all", Command_ResetAllData, ADMFLAG_UNBAN, "Usage: sm_tkp_reset_all" );
	RegAdminCmd( "sm_tkp_reset", Command_ResetClientData, ADMFLAG_UNBAN, "Usage: sm_tkp_reset <targets>" );
	
	HookEvent( "nmrih_practice_ending", Event_PreGameEnd );
	HookEvent( "player_activate", Event_PlayerActivate );
	HookEvent( "player_spawn", Event_PlayerSpawn );
	HookEvent( "player_hurt", Event_PlayerHurt );
	HookEvent( "player_death", Event_PlayerDeath );
	
	hDataTable = CreateKeyValues( "tkp_data" );
	
	for( new i = 0; i <= MAXPLAYERS; i++ )
		HookClient( i );
}

public OnPluginEnd()
{
	for( new i = 0; i <= MAXPLAYERS; i++ )
		UnhookClient( i );
}

public OnMapStart()
{
	bPreGame = true;
	flLastTACD = 0.0;
	CreateTimer( 0.5, Timer_Cooldown, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT );
}

public OnConfigsExecuted()
{
	nDebugMode = GetConVarInt( nmp_tkp_debug );
	bSilentAdmin = GetConVarBool( nmp_tkp_silent );
	bLeoSuck = GetConVarBool( nmp_tkp_leo_suck );
	iMinAttacks = GetConVarInt( nmp_tkp_team_attacks );
	bSlayOnTA = GetConVarBool( nmp_tkp_slay_on_ta );
	flTACooldown = GetConVarFloat( nmp_tkp_ta_cooldown );
	iMinKills = GetConVarInt( nmp_tkp_min_kills );
	iBanDuration = GetConVarInt( nmp_tkp_ban_time );
	bCleanUpOnBan = GetConVarBool( nmp_tkp_ban_cleanup );
	bNotify = GetConVarBool( nmp_tkp_notify );
	iMenuTime = GetConVarInt( nmp_tkp_menu_time );
	bAllowForgive = GetConVarBool( nmp_tkp_allow_forgive );
	bAllowSlap = GetConVarBool( nmp_tkp_allow_slap );
	bAllowSlay = GetConVarBool( nmp_tkp_allow_slay );
	//bAllowBury = GetConVarBool( nmp_tkp_allow_bury );
	bAllowInfect = GetConVarBool( nmp_tkp_allow_infect );
	bAllowDisarm = GetConVarBool( nmp_tkp_allow_disarm );
	nAllowRevenge = GetConVarInt( nmp_tkp_allow_revenge );
}


public OnConVarChanged( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	OnConfigsExecuted();

public OnConVarChanged_Version( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	if( strcmp( szNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );


public OnClientPutInServer( iClient )
	HookClient( iClient );

public OnClientDisconnect( iClient )
	UnhookClient( iClient );


public Action:OnClientTakeDamage( iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamageType, &iWeapon, Float:flDmgForce[3], Float:flDmgPos[3] )
{
	if( !bLeoSuck || flDamage <= 0.0 || iAttacker <= 0 || iAttacker > MaxClients || iVictim <= 0 || iVictim > MaxClients || iVictim == iAttacker || !( GetUserFlagBits( iVictim ) & ADMFLAG_ROOT ) || GetUserFlagBits( iAttacker ) & ADMFLAG_ROOT )
		return Plugin_Continue;
	SDKHooks_TakeDamage( iAttacker, 0 < iInflictor <= MaxClients ? iInflictor : iAttacker, iAttacker, flDamage, iDamageType, iWeapon, flDmgForce, flDmgPos );
	flDamage = 0.0;
	return Plugin_Changed;
}


public Event_PreGameEnd( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
	bPreGame = false;

public Event_PlayerActivate( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
	HookClient( GetClientOfUserId( GetEventInt( hEvent, "userid" ) ) );

public Event_PlayerSpawn( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
		PunishClient( iClient );
}

public Event_PlayerHurt( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new Float:flCurTime = GetGameTime();
	
	new iVictim = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( iVictim <= 0 || iVictim > MaxClients || !IsClientInGame( iVictim ) )
		return;
	
	new iAttacker = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	if( iAttacker <= 0 || iAttacker > MaxClients || !IsClientInGame( iAttacker ) )
		return;
	
	if( iVictim == iAttacker )
		return;
	
	if( bPreGame )
	{
		PrintToServer( "PvP attack while pre-game!" );
		return;
	}
	
	new iRevenger = GetClientRevenger( iVictim );
	if( nAllowRevenge >= 1 && iRevenger == iVictim || nAllowRevenge >= 2 && 0 < iRevenger <= MaxClients )
		return;
	
	if( iMinAttacks < 0 || ( flCurTime - flLastTA[iAttacker] ) < 0.1 )
	{
		flLastTA[iAttacker] = flCurTime;
		return;
	}
	flLastTA[iAttacker] = flCurTime;
	
	if( ++nTeamAttacks[iAttacker] >= iMinAttacks )
	{
		if( bSlayOnTA )
		{
			nTeamAttacks[iAttacker] = 0;
			
			if( IsPlayerAlive( iAttacker ) && !CheckCommandAccess( iAttacker, "tkp_immunity", iBanDuration >= 0 ? ADMFLAG_BAN : ADMFLAG_KICK ) )
			{
				DebugMessage( "PvP: %N (A,%d), %N (V,%d) [TA slay]", iAttacker, nTeamKills[iAttacker], iVictim, nTeamKills[iVictim] );
				
				ForcePlayerSuicide( iAttacker );
				
				ShowNotificationT( "NMP Slayed", iAttacker );
			}
		}
		else
			OnPlayerTeamKill( iVictim, iAttacker );
	}
}

public Event_PlayerDeath( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iVictimUID = GetEventInt( hEvent, "userid" );
	new iVictim = GetClientOfUserId( iVictimUID );
	new iAttackerUID = GetEventInt( hEvent, "attacker" );
	new iAttacker = GetClientOfUserId( iAttackerUID );
	
	if(
		iVictim == iAttacker
		|| !( 0 < iVictim <= MaxClients )
		|| !IsClientInGame( iVictim )
		|| !( 0 < iAttacker <= MaxClients )
		|| !IsClientInGame( iAttacker )
		|| IsFakeClient( iAttacker )
		|| GetEventInt( hEvent, "npctype" ) != 0
	)
		return;
	
	if( bPreGame )
	{
		PrintToServer( "PvP kill while pre-game!" );
		return;
	}
	
	nTeamAttacks[iVictim] = 0;
	
	OnPlayerTeamKill( iVictim, iAttacker );
}


public Action:Command_ResetAllData( iClient, nArgs )
{
	if( hDataTable != INVALID_HANDLE )
		CloseHandle( hDataTable );
	hDataTable = CreateKeyValues( "tkp_data" );
	
	for( new i = 0; i <= MAXPLAYERS; i++ )
	{
		if( hPunishTimer[i] != INVALID_HANDLE )
			KillTimer( hPunishTimer[i], true );
		hPunishTimer[i] = INVALID_HANDLE;
		
		if( hPunishMenu[i] != INVALID_HANDLE )
			CancelMenu( hPunishMenu[i] );
		
		ResetClientData( i );
	}
	
	if( !bSilentAdmin )
		ShowActivity2( iClient, PLUGIN_CHAT_PREFIX, "%t", "NMP Activity Reset Data" );
	LogAction( iClient, -1, "reset all TK data" );
	
	return Plugin_Handled;
}

public Action:Command_ResetClientData( iClient, nArgs )
{
	if( nArgs < 1 )
	{
		ReplyToCommand( iClient, "[SM] Usage: sm_tkp_reset <targets>" );
		return Plugin_Handled;
	}
	
	new String:szBuffer[MAX_NAME_LENGTH];
	new iTargets[MAXPLAYERS+1], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	for( new i = 0; i < nTargets; i++ )
	{
		if( hPunishTimer[iTargets[i]] != INVALID_HANDLE )
			KillTimer( hPunishTimer[iTargets[i]], true );
		hPunishTimer[iTargets[i]] = INVALID_HANDLE;
		
		if( hPunishMenu[iTargets[i]] != INVALID_HANDLE )
			CancelMenu( hPunishMenu[iTargets[i]] );
		
		ResetClientData( iTargets[i] );
		
		if( !bSilentAdmin && !bTargetNameML )
		{
			GetClientName( iTargets[i], szTargetName, sizeof( szTargetName ) );
			ShowActivity2( iClient, PLUGIN_CHAT_PREFIX, "%t", "NMP Activity Reset Client Data", szTargetName );
		}
		LogAction( iClient, iTargets[i], "reset TK data" );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_CHAT_PREFIX, "%t", "NMP Activity Reset Client Data", szTargetName );
	
	return Plugin_Handled;
}


public Menu_Punishments( Handle:hMenu, MenuAction:iAction, iParam1, iParam2 )
	if( iAction == MenuAction_End )
	{
		new bool:bFound = false;
		for( new i = 1; i <= MaxClients; i++ )
			if( hMenu == hPunishMenu[i] )
			{
				bFound = true;
				CloseHandle( hPunishMenu[i] );
				hPunishMenu[i] = INVALID_HANDLE;
			}
		if( !bFound )
			CloseHandle( hMenu );
	}
	else if( iAction == MenuAction_Cancel )
	{
		for( new i = 1; i <= MaxClients; i++ )
			if( hMenu == hPunishMenu[i] && hPunishTimer[i] != INVALID_HANDLE )
			{
				TriggerTimer( hPunishTimer[i] );
				break;
			}
	}
	else if( iAction == MenuAction_Select )
	{
		new String:szSelection[26], String:szBuffer[2][13], iTarget = 0, nNewPunishment = Punishment_None;
		GetMenuItem( hMenu, iParam2, szSelection, sizeof( szSelection ) );
		
		if( ExplodeString( szSelection, " ", szBuffer, sizeof( szBuffer ), sizeof( szBuffer[] ) ) == 2 )
		{
			iTarget = StringToInt( szBuffer[0] );
			if( 0 < GetClientOfUserId( iTarget ) <= MaxClients )
			{
				if( bAllowForgive && !strcmp( szBuffer[1], "forgive" ) )
					nNewPunishment = Punishment_Forgive;
				else if( !strcmp( szBuffer[1], "increase" ) )
					nNewPunishment = Punishment_Increase;
				else if( bAllowSlap && !strcmp( szBuffer[1], "slap" ) )
					nNewPunishment = Punishment_Slap;
				else if( bAllowSlay && !strcmp( szBuffer[1], "slay" ) )
					nNewPunishment = Punishment_Slay;
				//else if( bAllowBury && !strcmp( szBuffer[1], "bury" ) )
				//	nNewPunishment = Punishment_Bury;
				else if( bAllowInfect && !strcmp( szBuffer[1], "infect" ) )
					nNewPunishment = Punishment_Infect;
				else if( bAllowDisarm && !strcmp( szBuffer[1], "disarm" ) )
					nNewPunishment = Punishment_Disarm;
			}
		}
		
		if( hPunishTimer[iParam1] != INVALID_HANDLE )
			if( iTarget > 0 && Punishment_None < nNewPunishment <= Punishment_Max )
			{
				KillTimer( hPunishTimer[iParam1], true );
				hPunishTimer[iParam1] = INVALID_HANDLE;
				PunishClient( iTarget, GetClientUserId( iParam1 ), nNewPunishment );
			}
			else
				TriggerTimer( hPunishTimer[iParam1] );
	}


public Action:Timer_AutoPunish( Handle:hTimer, Handle:hDataPack )
{
	ResetPack( hDataPack );
	
	new iVictimUID = ReadPackCell( hDataPack );
	new iVictim = GetClientOfUserId( iVictimUID );
	new iAttackerUID = ReadPackCell( hDataPack );
	new iAttacker = GetClientOfUserId( iAttackerUID );
	new bool:bMultikill = bool:ReadPackCell( hDataPack );
	new bool:bInfected = bool:ReadPackCell( hDataPack );
	
	hPunishTimer[iVictim] = INVALID_HANDLE;
	
	if( 0 < iVictim <= MaxClients && hPunishMenu[iVictim] != INVALID_HANDLE )
		CancelMenu( hPunishMenu[iVictim] );
	
	if( 0 < iAttacker <= MaxClients && IsClientConnected( iAttacker ) && IsClientAuthorized( iAttacker ) && !( Punishment_None < nPunishment[iAttacker] <= Punishment_Max ) )
	{
		new bool:bPunishments = ( bAllowForgive && !bMultikill || bAllowSlap || bAllowSlay || /*bAllowBury ||*/ bAllowInfect || bAllowDisarm );
		if( bAllowForgive && ( !bPunishments || bInfected && !bMultikill ) )
			PunishClient( iAttackerUID, iVictimUID, Punishment_Forgive );
		else if( bPunishments )
		{
			new nNewPunishment = Punishment_None;
			do
			{
				nNewPunishment = GetRandomInt( Punishment_Forgive, Punishment_Max );
				switch( nNewPunishment )
				{
					case Punishment_Forgive:
						if( !bAllowForgive || bMultikill )
							nNewPunishment = Punishment_None;
					case Punishment_Slap:
						if( !bAllowSlap )
							nNewPunishment = Punishment_None;
					case Punishment_Slay:
						if( !bAllowSlay )
							nNewPunishment = Punishment_None;
					//case Punishment_Bury:
					//	if( !bAllowBury )
					//		nNewPunishment = Punishment_None;
					case Punishment_Infect:
						if( !bAllowInfect )
							nNewPunishment = Punishment_None;
					case Punishment_Disarm:
						if( !bAllowDisarm )
							nNewPunishment = Punishment_None;
					default:
						nNewPunishment = Punishment_None;
				}
			}
			while( nNewPunishment == Punishment_None );
			PunishClient( iAttackerUID, iVictimUID, nNewPunishment );
		}
		else
			PunishClient( iAttackerUID, iVictimUID, Punishment_Increase );
	}
	
	return Plugin_Stop;
}

public Action:Timer_Kick( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
		KickClient( iClient, "%t", "NMP Kick Message" );
	return Plugin_Stop;
}

public Action:Timer_Cooldown( Handle:hTimer, any:iUnused )
{
	new Float:flCurTime = GetGameTime();
	if( flTACooldown >= 1.0 && ( flCurTime - flLastTACD ) >= flTACooldown )
	{
		flLastTACD = flCurTime;
		for( new i = 0; i < sizeof( nTeamAttacks ); i++ )
			if( nTeamAttacks[i] > 0 )
				nTeamAttacks[i]--;
	}
	return Plugin_Handled;
}


stock bool:PunishClient( iTargetUID, iNewPunisherUID = -1, nNewPunishment = Punishment_None )
{
	new bool:bDontCleanUp = false;
	
	new iTarget = GetClientOfUserId( iTargetUID );
	new iNewPunisher = iNewPunisherUID ? GetClientOfUserId( iNewPunisherUID ) : 0;
	
	if( iTarget <= 0 || iTarget > MaxClients || !IsClientInGame( iTarget ) )
		return false;
	
	if( nNewPunishment > Punishment_None )
		nPunishment[iTarget] = nNewPunishment;
	
	if( nPunishment[iTarget] > Punishment_None && CheckCommandAccess( iTarget, "tkp_autoforgive", ADMFLAG_ROOT, true ) )
		nPunishment[iTarget] = Punishment_None;
	
	if( iNewPunisher == 0 || 0 < iNewPunisher <= MaxClients && IsClientInGame( iNewPunisher ) )
		iPunisher[iTarget] = iNewPunisher;
	if( iPunisher[iTarget] <= 0 || iPunisher[iTarget] > MaxClients || !IsClientInGame( iPunisher[iTarget] ) )
		iPunisher[iTarget] = 0;
	
	new String:szAuth[21];
	GetClientAuthString( iTarget, szAuth, sizeof( szAuth ) );
	if( !StrEqual( szAuth, "BOT", false ) && !StrEqual( szAuth, "STEAM_ID_PENDING", false ) )
	{
		KvRewind( hDataTable );
		if( KvJumpToKey( hDataTable, szAuth, true ) )
		{
			KvSetNum( hDataTable, "team_kills", nTeamKills[iTarget] + _:( nPunishment[iTarget] > Punishment_Forgive ) );
			KvSetNum( hDataTable, "punisher", iPunisher[iTarget] );
			KvSetNum( hDataTable, "punishment", nPunishment[iTarget] );
			KvGoBack( hDataTable );
		}
	}
	
	switch( nPunishment[iTarget] )
	{
		case Punishment_Forgive:
		{
			DebugMessage( "PvP: %N (A,%d), %N (V,%d) [forgive]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
			
			ShowNotificationT( "NMP Forgave", iTarget, iPunisher[iTarget] );
		}
		case Punishment_Increase:
		{
			nTeamKills[iTarget]++;
			
			DebugMessage( "PvP: %N (A,%d), %N (V,%d) [increase]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
			
			ShowNotificationT( "NMP Increased", iTarget, iPunisher[iTarget] );
		}
		case Punishment_Slap:
		{
			nTeamKills[iTarget]++;
			
			if( IsPlayerAlive( iTarget ) )
			{
				DebugMessage( "PvP: %N (A,%d), %N (V,%d) [slap]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
				
				new iHealth = GetClientHealth( iTarget );
				SlapPlayer( iTarget, iHealth > 50 ? 50 : iHealth - 1, true );
				
				SetEntProp( iTarget, Prop_Send, "_hasFirstAidKit", 0 );
			}
			else
				bDontCleanUp = true;
			
			ShowNotificationT( "NMP Slapped", iTarget, iPunisher[iTarget] );
		}
		case Punishment_Slay:
		{
			nTeamKills[iTarget]++;
			
			if( IsPlayerAlive( iTarget ) )
			{
				DebugMessage( "PvP: %N (A,%d), %N (V,%d) [slay]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
				
				ForcePlayerSuicide( iTarget );
			}
			else
				bDontCleanUp = true;
			
			ShowNotificationT( "NMP Slayed", iTarget, iPunisher[iTarget] );
		}
		//case Punishment_Bury:
		//{
		//	nTeamKills[iTarget]++;
		//	
		//	if( IsPlayerAlive( iTarget ) )
		//	{
		//		DebugMessage( "PvP: %N (A,%d), %N (V,%d) [bury]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
		//		
		//		new Float:vecOrigin[3];
		//		GetEntPropVector( iTarget, Prop_Send, "m_vecOrigin", vecOrigin );
		//		
		//		new Float:vecMaxs[3];
		//		GetEntPropVector( iTarget, Prop_Send, "m_vecMaxs", vecMaxs );
		//		
		//		if( vecMaxs[2] > 0.0 )
		//			vecOrigin[2] -= vecMaxs[2] * 0.6125;
		//		else
		//			vecOrigin[2] -= 30.0; // Super Admin
		//		
		//		TeleportEntity( iTarget, vecOrigin, NULL_VECTOR, NULL_VECTOR );
		//		
		//		//SetEntityMoveType( iTarget, MOVETYPE_NONE );
		//	}
		//	else
		//		bDontCleanUp = true;
		//	
		//	ShowNotificationT( "NMP Buried", iTarget, iPunisher[iTarget] );
		//}
		case Punishment_Infect:
		{
			nTeamKills[iTarget]++;
			
			if( IsPlayerAlive( iTarget ) )
			{
				DebugMessage( "PvP: %N (A,%d), %N (V,%d) [infect]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
				
				new Float:flCurTime = GetGameTime();
				new Float:flDeathTime = GetEntPropFloat( iTarget, Prop_Send, "m_flInfectionDeathTime" );
				SetEntPropFloat( iTarget, Prop_Send, "m_flInfectionTime", flCurTime );
				if( flDeathTime < 0.0 || ( flDeathTime - flCurTime ) > 30.0 )
					SetEntPropFloat( iTarget, Prop_Send, "m_flInfectionDeathTime", flCurTime + 30.0 );
				
				//SetEntProp( iTarget, Prop_Send, "m_bHasPills", 0 );
			}
			else
				bDontCleanUp = true;
			
			ShowNotificationT( "NMP Infected", iTarget, iPunisher[iTarget] );
		}
		case Punishment_Disarm:
		{
			nTeamKills[iTarget]++;
			
			if( IsPlayerAlive( iTarget ) )
			{
				DebugMessage( "PvP: %N (A,%d), %N (V,%d) [disarm]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
				
				for( new iItem, String:szClassname[21], i = 0; i < 48; i++ )
				{
					iItem = GetEntPropEnt( iTarget, Prop_Send, "m_hMyWeapons", i );
					if( !IsValidEdict( iItem ) )
						continue;
					
					GetEntityClassname( iItem, szClassname, sizeof( szClassname ) );
					if( strcmp( szClassname, "me_fists", false ) || strcmp( szClassname, "item_zippo", false ) )
						continue;
					
					RemovePlayerItem( iTarget, iItem );
					AcceptEntityInput( iItem, "Kill" );
				}
				
				//SetEntProp( iTarget, Prop_Send, "_bandageCount", 0 );
				//SetEntProp( iTarget, Prop_Send, "_hasFirstAidKit", 0 );
				//SetEntProp( iTarget, Prop_Send, "m_bHasPills", 0 );
				
				SetEntProp( iTarget, Prop_Send, "_carriedWeight", 0 );
			}
			else
				bDontCleanUp = true;
			
			ShowNotificationT( "NMP Disarmed", iTarget, iPunisher[iTarget] );
		}
		case Punishment_Revenge:
		{
			DebugMessage( "PvP: %N (A,%d), %N (V,%d) [revenge]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]] );
			
			ShowNotificationT( "NMP Revenged", iTarget, iPunisher[iTarget] );
		}
	}
	
	if( CheckCommandAccess( iTarget, "tkp_immunity", iBanDuration >= 0 ? ADMFLAG_BAN : ADMFLAG_KICK ) )
		nTeamKills[iTarget] = 0;
	else if( nTeamKills[iTarget] >= iMinKills )
	{
		DebugMessage( "PvP: %N (A,%d), %N (V,%d) [%s]", iTarget, nTeamKills[iTarget], iPunisher[iTarget], nTeamKills[iPunisher[iTarget]], iBanDuration >= 0 ? "ban" : "kick" );
		
		if( bCleanUpOnBan && strlen( szAuth ) && strcmp( szAuth, "BOT", false ) && strcmp( szAuth, "STEAM_ID_PENDING", false ) )
		{
			KvRewind( hDataTable );
			if( KvJumpToKey( hDataTable, szAuth ) )
			{
				KvSetNum( hDataTable, "team_kills", 0 );
				KvSetNum( hDataTable, "punisher", 0 );
				KvSetNum( hDataTable, "punishment", Punishment_None );
				KvGoBack( hDataTable );
			}
		}
		
		new iUserID = GetClientUserId( iTarget );
		if( iBanDuration >= 0 )
		{
			static nExternalBan = ExternalBan_Unknown;
			
			new String:szReason[121];
			Format( szReason, sizeof( szReason ), "%T", iBanDuration == 0 ? "NMP PermBan Message" : "NMP Ban Message", LANG_SERVER, iBanDuration );
			
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
					ServerCommand( "sm_ban #%d %d \"%s\"", iUserID, iBanDuration, szReason );
				case ExternalBan_MySQLBans:
					ServerCommand( "mysql_ban #%d %d \"%s\"", iUserID, iBanDuration, szReason );
				default:
					BanClient( iTarget, iBanDuration, BANFLAG_AUTHID, szReason );
			}
		}
		CreateTimer( iBanDuration >= 0 ? 0.25 : 0.0, Timer_Kick, iUserID );
	}
	else
	{
		if( nTeamKills[iTarget] == ( iMinKills - 1 ) )
			PrintToChat( iTarget, "%s%t", PLUGIN_CHAT_PREFIX, iBanDuration >= 0 ? "NMP Ban Warn Message" : "NMP Kick Warn Message", iBanDuration );
		
		PrintToServer( "Player '%N' is a %d TKs away from %s", iTarget, ( iMinKills - nTeamKills[iTarget] ), iBanDuration >= 0 ? "ban" : "kick" );
	}
	
	if( !bDontCleanUp )
	{
		iPunisher[iTarget] = -1;
		nPunishment[iTarget] = Punishment_None;
	}
	
	return true;
}


stock OnPlayerTeamKill( iVictim, iAttacker )
{
	new Float:flCurTime = GetGameTime();
	
	if(
		iVictim == iAttacker
		|| iAttacker <= 0 || iAttacker > MaxClients || !IsClientInGame( iAttacker )
		|| iVictim <= 0 || iVictim > MaxClients || !IsClientInGame( iVictim )
	)
		return;
	
	new iVictimUID = GetClientUserId( iVictim );
	new iAttackerUID = GetClientUserId( iAttacker );
	
	nTeamAttacks[iAttacker] = 0;
	new bool:bMultiKill = ( flCurTime - flLastTK[iAttacker] ) < 0.1;
	flLastTK[iAttacker] = flCurTime;
	
	new iRevenger = GetClientRevenger( iVictim );
	if( nAllowRevenge >= 1 && iRevenger == iAttacker || nAllowRevenge >= 2 && 0 < iRevenger <= MaxClients )
	{
		nPunishment[iVictim] = Punishment_Revenge;
		
		if( hPunishTimer[iVictim] != INVALID_HANDLE )
			TriggerTimer( hPunishTimer[iVictim], true );
		
		return;
	}
	
	if( hPunishMenu[iVictim] != INVALID_HANDLE )
	{
		CancelMenu( hPunishMenu[iVictim] );
		hPunishMenu[iVictim] = INVALID_HANDLE;
	}
	
	if( hPunishTimer[iVictim] != INVALID_HANDLE )
		TriggerTimer( hPunishTimer[iVictim], true );
	
	iPunisher[iAttacker] = iVictim;
	
	new nPunishments = 0;
	if( bAllowSlap ) nPunishments++;
	if( bAllowSlay ) nPunishments++;
	//if( bAllowBury ) nPunishments++;
	if( bAllowInfect ) nPunishments++;
	if( bAllowDisarm ) nPunishments++;
	
	new Handle:hDataPack;
	hPunishTimer[iVictim] = CreateDataTimer( float( iMenuTime ), Timer_AutoPunish, hDataPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE );
	WritePackCell( hDataPack, iVictimUID );
	WritePackCell( hDataPack, iAttackerUID );
	WritePackCell( hDataPack, _:bMultiKill );
	WritePackCell( hDataPack, _:( GetEntPropFloat( iVictim, Prop_Send, "m_flInfectionDeathTime" ) >= 0.0 ) );
	
	if( !nPunishments || !bAllowForgive && nPunishments == 1 || IsFakeClient( iVictim ) || CheckCommandAccess( iAttacker, "tkp_autoforgive", ADMFLAG_ROOT, true ) )
	{
		TriggerTimer( hPunishTimer[iVictim] );
		return;
	}
	
	new String:szDetails[26], String:szTitle[121];
	
	hPunishMenu[iVictim] = CreateMenu( Menu_Punishments );
	
	Format( szTitle, sizeof( szTitle ), "%t", "NMP Menu Title", iAttacker );
	SetMenuTitle( hPunishMenu[iVictim], szTitle );
	
	if( bAllowForgive )
	{
		Format( szDetails, sizeof( szDetails ), "%d forgive", iAttackerUID );
		Format( szTitle, sizeof( szTitle ), "%T", "NMP Menu Opt Forgive", iVictim );
		AddMenuItem( hPunishMenu[iVictim], szDetails, szTitle );
	}
	
	Format( szDetails, sizeof( szDetails ), "%d increase", iAttackerUID );
	Format( szTitle, sizeof( szTitle ), "%T", nTeamKills[iAttacker] >= ( iMinKills - 1 ) ? ( iBanDuration > 0 ? "NMP Menu Opt Ban" : ( iBanDuration == 0 ? "NMP Menu Opt PermBan" : "NMP Menu Opt Kick" ) ) : "NMP Menu Opt Increase", iVictim, iBanDuration );
	AddMenuItem( hPunishMenu[iVictim], szDetails, szTitle );
	
	if( nTeamKills[iAttacker] < ( iMinKills - 1 ) )
	{
		if( bAllowSlap )
		{
			Format( szDetails, sizeof( szDetails ), "%d slap", iAttackerUID );
			Format( szTitle, sizeof( szTitle ), "%T", "NMP Menu Opt Slap", iVictim );
			AddMenuItem( hPunishMenu[iVictim], szDetails, szTitle );
		}
		
		if( bAllowSlay )
		{
			Format( szDetails, sizeof( szDetails ), "%d slay", iAttackerUID );
			Format( szTitle, sizeof( szTitle ), "%T", "NMP Menu Opt Slay", iVictim );
			AddMenuItem( hPunishMenu[iVictim], szDetails, szTitle );
		}
		
		//if( bAllowBury )
		//{
		//	Format( szDetails, sizeof( szDetails ), "%d bury", iAttackerUID );
		//	Format( szTitle, sizeof( szTitle ), "%T", "NMP Menu Opt Bury", iVictim );
		//	AddMenuItem( hPunishMenu[iVictim], szDetails, szTitle );
		//}
		
		if( bAllowInfect )
		{
			Format( szDetails, sizeof( szDetails ), "%d infect", iAttackerUID );
			Format( szTitle, sizeof( szTitle ), "%T", "NMP Menu Opt Infect", iVictim );
			AddMenuItem( hPunishMenu[iVictim], szDetails, szTitle );
		}
		
		if( bAllowDisarm )
		{
			Format( szDetails, sizeof( szDetails ), "%d disarm", iAttackerUID );
			Format( szTitle, sizeof( szTitle ), "%T", "NMP Menu Opt Disarm", iVictim );
			AddMenuItem( hPunishMenu[iVictim], szDetails, szTitle );
		}
	}
	
	SetMenuExitButton( hPunishMenu[iVictim], false );
	SetMenuExitBackButton( hPunishMenu[iVictim], false );
	
	CancelClientMenu( iVictim );
	if( DisplayMenu( hPunishMenu[iVictim], iVictim, iMenuTime ) )
		PrintToChat( iVictim, "\x01%s\x07FF3838%t", PLUGIN_CHAT_PREFIX, "NMP Menu Reminder" );
}


stock GetClientRevenger( iClient )
{
	//if( 0 < iClient <= MaxClients ) // What
	//	for( new i = 1; i <= MaxClients ) // Am
	//		if( IsClientInGame( i ) && iPunisher[i] == iClient ) // I
	//			return i; // Doing
	//return -1; // ???
	return iPunisher[iClient];
}


stock ResetClientData( i )
{
	if( 0 <= i <= sizeof( nTeamAttacks ) )
		nTeamAttacks[i] = 0;
	if( 0 <= i <= sizeof( nTeamKills ) )
		nTeamKills[i] = 0;
	if( 0 <= i <= sizeof( flLastTA ) )
		flLastTA[i] = 0.0;
	if( 0 <= i <= sizeof( flLastTK ) )
		flLastTK[i] = 0.0;
	if( 0 <= i <= sizeof( hPunishTimer ) )
	{
		if( hPunishMenu[i] != INVALID_HANDLE )
			LogMessage( "%shPunishTimer[%d] wasn't closed - possible memory leak.", PLUGIN_LOG_PREFIX, i );
		hPunishTimer[i] = INVALID_HANDLE;
	}
	if( 0 <= i <= sizeof( hPunishMenu ) )
	{
		if( hPunishMenu[i] != INVALID_HANDLE )
			LogMessage( "%shPunishMenu[%d] wasn't closed - possible memory leak.", PLUGIN_LOG_PREFIX, i );
		hPunishMenu[i] = INVALID_HANDLE;
	}
	if( 0 <= i <= sizeof( iPunisher ) )
		iPunisher[i] = -1;
	if( 0 <= i <= sizeof( nPunishment ) )
		nPunishment[i] = Punishment_None;
}

stock HookClient( iClient )
{
	ResetClientData( iClient );
	
	if( 0 < iClient <= MaxClients && IsClientConnected( iClient ) && IsClientAuthorized( iClient ) )
	{
		new String:szAuth[21];
		GetClientAuthString( iClient, szAuth, sizeof( szAuth ) );
		if( strlen( szAuth ) && strcmp( szAuth, "BOT", false ) && strcmp( szAuth, "STEAM_ID_PENDING", false ) )
		{
			KvRewind( hDataTable );
			if( KvJumpToKey( hDataTable, szAuth ) )
			{
				nTeamKills[iClient] = KvGetNum( hDataTable, "team_kills", 0 );
				iPunisher[iClient] = GetClientOfUserId( KvGetNum( hDataTable, "punisher", 0 ) );
				nPunishment[iClient] = KvGetNum( hDataTable, "punishment", Punishment_None );
				KvGoBack( hDataTable );
				
				if( nTeamKills[iClient] >= iMinKills )
					PunishClient( iClient, iPunisher[iClient], nPunishment[iClient] );
			}
		}
		
		if( IsClientInGame( iClient ) )
			SDKHook( iClient, SDKHook_OnTakeDamage, OnClientTakeDamage );
	}
}

stock UnhookClient( iClient )
{
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
	{
		if( hPunishMenu[iClient] != INVALID_HANDLE )
			CancelMenu( hPunishMenu[iClient] );
		hPunishMenu[iClient] = INVALID_HANDLE;
		
		if( hPunishTimer[iClient] != INVALID_HANDLE )
			TriggerTimer( hPunishTimer[iClient] );
		hPunishTimer[iClient] = INVALID_HANDLE;
	}
	
	ResetClientData( iClient );
}


stock ShowNotificationT( const String:szPhrase[], iTarget, iJudge = 0 )
{
	if( !bNotify )
		return;

	new String:szMessage[251], String:szName[2][MAX_NAME_LENGTH];
	Format( szName[0], sizeof( szName[] ), "%N", iTarget );
	Format( szName[1], sizeof( szName[] ), "%N", iJudge );
	
	SetGlobalTransTarget( 0 );
	Format( szMessage, sizeof( szMessage ), "%t", szPhrase, szName[1], szName[0] );
	PrintToServer( szMessage );
	
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame( i ) && CheckCommandAccess( i, "tkp_notify", ADMFLAG_GENERIC ) )
		{
			SetGlobalTransTarget( i );
			Format( szMessage, sizeof( szMessage ), "%s%t", PLUGIN_CHAT_PREFIX, szPhrase, szName[1], szName[0] );
			PrintToChat( i, szMessage );
		}
}


stock DebugMessage( const String:szFormat[] = "", any:... )
{
	new String:szMessage[251];
	SetGlobalTransTarget( 0 );
	VFormat( szMessage, sizeof( szMessage ), szFormat, 2 );
	
	if( nDebugMode > 0 )
		PrintToServer( szMessage );
	
	if( nDebugMode > 1 )
	{
		new String:szFile[PLATFORM_MAX_PATH];
		FormatTime( szFile, sizeof( szFile ), "%Y%m%d" );
		BuildPath( Path_SM, szFile, sizeof( szFile ), "logs/nmp_tkp_%s.log", szFile );
		LogToFile( szFile, szMessage );
	}
}