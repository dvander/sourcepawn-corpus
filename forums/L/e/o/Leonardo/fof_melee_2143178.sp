#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamworks>

#define PLUGIN_VERSION		"1.2.4-20140622"

#if !defined IN_FOF_KICK
	#define IN_FOF_KICK		(1<<17)
#endif
#if !defined IN_FOF_DROP
	#define IN_FOF_DROP		(1<<19)
#endif

new Handle:sm_fof_melee_version = INVALID_HANDLE;
new Handle:fof_melee_only = INVALID_HANDLE;
new Handle:fof_melee_only_near_map_end = INVALID_HANDLE;
new Handle:fof_melee_only_kicks = INVALID_HANDLE;
new Handle:mp_teamplay = INVALID_HANDLE;
new Handle:fof_sv_maxteams = INVALID_HANDLE;
new bool:bMeleeOnly = false;
new nKicksMode = 0;
new iAutoFF_timeleft = 0;
new bool:bAutoFF = false;
new bool:bTeamPlay = false;
new nMaxTeams = 2;

public Plugin:myinfo =
{
	name = "[FoF] Fistfight",
	author = "Leonardo",
	description = "Melee-only.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};

public OnPluginStart()
{
	sm_fof_melee_version = CreateConVar( "sm_fof_melee_version", PLUGIN_VERSION, "FoF Fistfight Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD );
	SetConVarString( sm_fof_melee_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_fof_melee_version, OnVerionCVarChanged );
	
	HookConVarChange( ( fof_melee_only = CreateConVar( "fof_melee_only", "0", _, FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0 ) ), OnCVarChanged );
	HookConVarChange( ( fof_melee_only_near_map_end = CreateConVar( "fof_melee_only_near_map_end", "0", "Enable melee-only near map end (in seconds).", FCVAR_PLUGIN, true, 0.0 ) ), OnCVarChanged );
	HookConVarChange( ( fof_melee_only_kicks = CreateConVar( "fof_melee_only_kicks", "0", "0 - disable kicks, 1 - allow kicks, 2 - allow kicks but with no damage.", FCVAR_PLUGIN, true, 0.0, true, 2.0 ) ), OnCVarChanged );
	
	AutoExecConfig();
	
	mp_teamplay = FindConVar( "mp_teamplay" );
	fof_sv_maxteams = FindConVar( "fof_sv_maxteams" );
	
	HookEvent( "player_activate", Event_PlayerActivate );
	HookEvent( "player_spawn", Event_PlayerSpawn );
	
	for( new iClient = 1; iClient <= MaxClients; iClient++ )
		if( IsClientConnected( iClient ) )
			SDKHook( iClient, SDKHook_OnTakeDamage, OnPlayerTakeDamage );
}

public OnMapStart()
{
	bTeamPlay = mp_teamplay != INVALID_HANDLE ? GetConVarBool( mp_teamplay ) : false;
	nMaxTeams = fof_sv_maxteams != INVALID_HANDLE ? GetConVarInt( fof_sv_maxteams ) : 2;
	CreateTimer( 1.0, Timer_Repeat, .flags = TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	PrecacheSound( "vehicles/train/whistle.wav", true );
}

public OnConfigsExecuted()
{
	bMeleeOnly = GetConVarBool( fof_melee_only );
	iAutoFF_timeleft = GetConVarInt( fof_melee_only_near_map_end );
	nKicksMode = GetConVarInt( fof_melee_only_kicks );
	if( nKicksMode > 2 ) nKicksMode = 2; if( nKicksMode < 0 ) nKicksMode = 0;
	
	if( !bMeleeOnly )
		for( new iClient = 1; iClient <= MaxClients; iClient++ )
			if( IsClientInGame( iClient ) )
				Timer_PlayerSpawn( INVALID_HANDLE, GetClientUserId( iClient ) );
	
	new String:szDescription[64];
	if( bTeamPlay )
		Format( szDescription, sizeof( szDescription ), "%d Team Fistfight", nMaxTeams );
	else
		strcopy( szDescription, sizeof( szDescription ), "Fistfight" );
	SetGameDescription( szDescription, bMeleeOnly );
}

public OnVerionCVarChanged( Handle:hCVar, const String:szOldValue[], const String:szNewValue[] )
	if( strcmp( szNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hCVar, PLUGIN_VERSION, true, true );
public OnCVarChanged( Handle:hCVar, const String:szOldValue[], const String:szNewValue[] )
	OnConfigsExecuted();

public Action:OnPlayerTakeDamage( iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDmgType, &iWeapon, Float:vecDmgForce[3], Float:vecDmgPosition[3], iDmgCustom )
{
	if( ( bMeleeOnly || bAutoFF ) && nKicksMode == 2 && iDmgCustom == 11 )
	{
		flDamage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Event_PlayerActivate( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
		SDKHook( iClient, SDKHook_OnTakeDamage, OnPlayerTakeDamage );
}

public Event_PlayerSpawn( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
	if( bMeleeOnly || bAutoFF )
		CreateTimer( 0.0, Timer_PlayerSpawn, GetEventInt( hEvent, "userid" ), TIMER_FLAG_NO_MAPCHANGE );

public Action:Timer_Repeat( Handle:hTimer, any:iUserID )
{
	new iTimeleft, bool:bAutoFF_new;
	bAutoFF_new = iAutoFF_timeleft > 0 && GetMapTimeLeft( iTimeleft ) && iTimeleft > 0 && iTimeleft <= iAutoFF_timeleft;
	if( bAutoFF != bAutoFF_new && bAutoFF_new && !bMeleeOnly )
	{
		PrintCenterTextAll( "IT'S A FISTFIGHT TIME!" );
		
		new iPitch = GetRandomInt( 85, 110 );
		for( new iClient = 1; iClient <= MaxClients; iClient++ )
			if( IsClientInGame( iClient ) )
			{
				CreateTimer( GetRandomFloat( 0.0, 2.0 ), Timer_PlayerTaunt, GetClientUserId( iClient ) );
				EmitSoundToClient( iClient, "vehicles/train/whistle.wav", .flags = SND_CHANGEPITCH, .pitch = iPitch );
			}
	}
	bAutoFF = bAutoFF_new;
	return Plugin_Handled;
}

public Action:Timer_PlayerTaunt( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
		FakeClientCommand( iClient, "vc 8 3" );
	return Plugin_Stop;
}

public Action:Timer_PlayerSpawn( Handle:hTimer, any:iUserID )
{
	new iClient = GetClientOfUserId( iUserID );
	if( iClient <= 0 || iClient > MaxClients || !IsClientInGame( iClient ) || !IsPlayerAlive( iClient ) )
		return Plugin_Stop;
	
	ClientCommand( iClient, "use weapon_fists" );
	
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd( iClient, &iButtons, &iImpulse, Float:vecVelocity[3], Float:vecAngles[3], &iNewWeapon, &iSubType, &nCommand, &iTick, &iSeed, iMouse[2] )
{
	if( ( bMeleeOnly || bAutoFF ) && 0 < iClient <= MaxClients && IsClientInGame( iClient ) && IsPlayerAlive( iClient ) )
	{
		new String:szClassname[16], iWeapon[2], bool:bFists = false, bool:bMelee = false, iNewButtons = iButtons;
		
		iWeapon[0] = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon" );
		iWeapon[1] = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon2" );
		for( new w = 0; w < sizeof( iWeapon ); w++ )
			if( iWeapon[w] > 0 && IsValidEdict( iWeapon[w] ) )
			{
				GetEntityClassname( iWeapon[w], szClassname, sizeof( szClassname ) );
				bFists = StrEqual( szClassname, "weapon_fists" );
				bMelee = ( bFists || StrEqual( szClassname, "weapon_knife" ) && CheckCommandAccess( iClient, "meleeonly_knives", ADMFLAG_GENERIC, true ) || StrEqual( szClassname, "weapon_axe" ) && CheckCommandAccess( iClient, "meleeonly_axes", ADMFLAG_BAN, true ) );
				if( !bMelee )
				{
					if( IsFakeClient( iClient ) )
						FakeClientCommand( iClient, "use weapon_fists" );
					else
						ClientCommand( iClient, "use weapon_fists" );
				}
			}
		
		if( !bMelee && ( iButtons & IN_ATTACK ) )
			iNewButtons |= ~IN_ATTACK;
		if( !CheckCommandAccess( iClient, "meleeonly_throw", ADMFLAG_SLAY, true ) )
		{
			if( !bFists && ( iButtons & IN_ATTACK2 ) )
				iNewButtons |= ~IN_ATTACK2;
			if( iButtons & IN_FOF_DROP )
				iNewButtons |= ~IN_FOF_DROP;
		}
		if( nKicksMode == 0 && ( iButtons & IN_FOF_KICK ) )
			iNewButtons |= ~IN_FOF_KICK;
		
		if( iNewButtons != iButtons )
		{
			iButtons = iNewButtons;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock bool:SetGameDescription( String:szNewValue[], bool:bOverride = true )
{
#if defined _SteamWorks_Included
	if( bOverride )
		return SteamWorks_SetGameDescription( szNewValue );
	
	new String:szOldValue[64];
	GetGameDescription( szOldValue, sizeof( szOldValue ), false );
	if( StrEqual( szOldValue, szNewValue ) )
	{
		GetGameDescription( szOldValue, sizeof( szOldValue ), true );
		return SteamWorks_SetGameDescription( szOldValue );
	}
#endif
	return false;
}