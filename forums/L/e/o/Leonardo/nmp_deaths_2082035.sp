#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.2-20181014"

#define PLUGIN_REPLY_PREFIX		"[NMP-DN] "


#define DEATHFLAG_NONE			0
#define DEATHFLAG_BLEED			(1<<0)
#define DEATHFLAG_INFECT		(1<<1)

#define CHAT_COLOR_PRIMARY		3
#define CHAT_COLOR_SECONDARY	1

//#define USE_HUD					1 // UNDONE


new Handle:nmp_dn_version = INVALID_HANDLE;
new Handle:nmp_dn_enabled = INVALID_HANDLE;
new Handle:nmp_dn_debug = INVALID_HANDLE;
new Handle:nmp_dn_teamattacks = INVALID_HANDLE;
new Handle:nmp_dn_hardcore = INVALID_HANDLE;
new Handle:sv_hardcore_survival = INVALID_HANDLE;
#if defined USE_HUD
new Handle:nmp_dn_hud = INVALID_HANDLE;
new Handle:nmp_dn_hud_x = INVALID_HANDLE;
new Handle:nmp_dn_hud_y = INVALID_HANDLE;
#endif

new bool:bEnabled = true;
new nDebugMode = 0;
new bool:bTA = true;
new bool:bHardcode = true;
new nHardcoreMode = 1;
#if defined USE_HUD
new bool:bHUD = true;
new Float:flHUDPosition[2] = { -1.0, -1.0 };
#endif

new bool:bBleeding[MAXPLAYERS+1] = { false, ... };

new Float:flLastTA = 0.0;

#if defined USE_HUD
new Handle:hHUDSync = INVALID_HANDLE;
#endif

public Plugin:myinfo = {
	name = "[NMRiH] Death Notifications",
	author = "Leonardo",
	description = "Nuff said.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};


public OnPluginStart()
{
	nmp_dn_version = CreateConVar( "nmp_dn_version", PLUGIN_VERSION, "NoMorePlugins Death Notifications", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	SetConVarString( nmp_dn_version, PLUGIN_VERSION );
	HookConVarChange( nmp_dn_version, OnConVarChanged_Version );
	
	HookConVarChange( nmp_dn_enabled = CreateConVar( "nmp_dn_enabled", bEnabled ? "1" : "0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_debug = CreateConVar( "nmp_dn_debug", "0", "Debug messages:\n0 - disabled,\n1 - server console only,\n2 - server console and logs.", FCVAR_PLUGIN, true, 0.0, true, 2.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_teamattacks = CreateConVar( "nmp_dn_teamattacks", bTA ? "1" : "0", "Enable TeamAttack notifications.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_hardcore = CreateConVar( "nmp_dn_hardcore", "1", "Obey sv_hardcore_survival:\n0 - print all notifications,\n1 - print team kills only,\n2 - don't print anything.", FCVAR_PLUGIN, true, 0.0, true, 2.0 ), OnConVarChanged );
	HookConVarChange( sv_hardcore_survival = FindConVar( "sv_hardcore_survival" ), OnConVarChanged );
#if defined USE_HUD
	HookConVarChange( nmp_dn_hud = CreateConVar( "nmp_dn_hud", bHUD ? "1" : "0", "Set 1 to print notifications in top right corner, otherwise - in chat.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_hud_x = CreateConVar( "nmp_dn_hud_x", "1.0", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_hud_y = CreateConVar( "nmp_dn_hud_y", "0.0875", _, FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
#endif
	
	HookEvent( "player_spawn", Event_PlayerSpawn );
	HookEvent( "player_hurt", Event_PlayerHurt );
	HookEvent( "player_death", Event_PlayerDeath );
	
#if defined USE_HUD
	hHUDSync = CreateHudSynchronizer();
#endif
}

public OnMapStart()
	flLastTA = 0.0;

public OnConfigsExecuted()
{
	bEnabled = GetConVarBool( nmp_dn_enabled );
	
	nDebugMode = GetConVarInt( nmp_dn_debug );
	if( nDebugMode > 2 )
		nDebugMode = 2;
	else if( nDebugMode < 0 )
		nDebugMode = 0;
	
	bTA = GetConVarBool( nmp_dn_teamattacks );
	
	bHardcode = GetConVarBool( sv_hardcore_survival );
	
	nHardcoreMode = GetConVarBool( nmp_dn_hardcore );
	if( nHardcoreMode > 2 )
		nHardcoreMode = 2;
	else if( nHardcoreMode < 0 )
		nHardcoreMode = 0;
	
#if defined USE_HUD
	bHUD = GetConVarBool( nmp_dn_hud );
	
	flHUDPosition[0] = GetConVarFloat( nmp_dn_hud_x );
	if( flHUDPosition[0] > 1.0 )
		flHUDPosition[0] = 1.0;
	else if( flHUDPosition[0] < 0.0 )
		flHUDPosition[0] = -1.0;
	
	flHUDPosition[1] = GetConVarFloat( nmp_dn_hud_y );
	if( flHUDPosition[1] > 1.0 )
		flHUDPosition[1] = 1.0;
	else if( flHUDPosition[1] < 0.0 )
		flHUDPosition[1] = -1.0;
#endif
}


public OnConVarChanged( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	OnConfigsExecuted();

public OnConVarChanged_Version( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	if( strcmp( szNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );


public Event_PlayerSpawn( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( 0 < iClient <= MaxClients )
		bBleeding[iClient] = false;
}

public Event_PlayerHurt( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	if( !bEnabled || !bTA )
		return;
	
	new Float:flCurTime = GetGameTime();
	new iVClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	new iAClient = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	if( iVClient != iAClient && 0 < iVClient <= MaxClients && 0 < iAClient <= MaxClients && IsClientInGame( iAClient ) && ( flCurTime - flLastTA ) > 3.0 )
	{
		flLastTA = flCurTime;
		PrintToServer( "%N attacked a teammate", iAClient );
		if( !bDontBroadcast && ( !bHardcode || nHardcoreMode < 2 ) )
			PrintToChatAll( "%c%N%c has attacked a teammate", CHAT_COLOR_SECONDARY, iAClient, CHAT_COLOR_PRIMARY );
	}
}

public Event_PlayerDeath( Handle:hEvent, const String:szEventName[], bool:bDontBroadcast )
{
	new iAttacker = GetEventInt( hEvent, "attacker" );
	new iAClient = GetClientOfUserId( iAttacker );
	new iVClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	new iNPCType = GetEventInt( hEvent, "npctype" );
	
	new String:szWeapon[32];
	GetEventString( hEvent, "weapon", szWeapon, sizeof( szWeapon ) );
	
	if( iVClient <= 0 || iVClient > MaxClients || !IsClientInGame( iVClient ) )
		return;
	
	if( bEnabled && !bDontBroadcast )
	{
		if( iNPCType != 0 && !StrContains( szWeapon, "npc", false ) )
		{
			if( !bHardcode || nHardcoreMode < 1 )
			{
				if( StrContains( szWeapon, "_turnedzombie", false ) > 0 )
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll( "%N died to his dead mate.", iVClient );
					else
#endif
					PrintToChatAll( "%cPlayer %c%N%c died to his dead mate.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
				}
				else if( StrContains( szWeapon, "_kidzombie", false ) > 0 )
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll( "%N died to zombie kid.", iVClient );
					else
#endif
					PrintToChatAll( "%cPlayer %c%N%c died to zombie kid.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
				}
				else if( StrContains( szWeapon, "zombie", false ) > 0 )
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll( "%N died to zombie.", iVClient );
					else
#endif
					PrintToChatAll( "%cPlayer %c%N%c died to zombie.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
				}
				else
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll( "%N died to NPC.", iVClient );
					else
#endif
					PrintToChatAll( "%cPlayer %c%N%c died to NPC.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
				}
			}
			DebugMessage( "Death: '%N', NPC, '%s'", iVClient, szWeapon );
		}
		else if( iAClient == iVClient )
		{
			new Float:flInfDeathTime = GetEntPropFloat( iVClient, Prop_Send, "m_flInfectionDeathTime" );
			if( GetEntProp( iVClient, Prop_Send, "m_bDiedWhileInfected" ) || flInfDeathTime >= 0.0 && ( GetGameTime() - flInfDeathTime ) >= 0.0 )
			{
				if( !bHardcode || nHardcoreMode < 1 )
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll( "%N died to infection.", iVClient );
					else
#endif
					PrintToChatAll( "%cPlayer %c%N%c died to infection.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
				}
				DebugMessage( "Death: '%N', infection, '%s'", iVClient, szWeapon );
			}
			else if( bBleeding[iVClient] )
			{
				if( !bHardcode || nHardcoreMode < 1 )
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll( "%N died to loss of blood.", iVClient );
					else
#endif
					PrintToChatAll( "%cPlayer %c%N%c died to loss of blood.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
				}
				DebugMessage( "Death: '%N', blood loss, '%s'", iVClient, szWeapon );
			}
			else
			{
				if( !bHardcode || nHardcoreMode < 1 )
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll( "%N bid farewell, cruel world!", iVClient );
					else
#endif
					PrintToChatAll( "%cPlayer %c%N%c commited suicide.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
				}
				DebugMessage( "Death: '%N', suicide, '%s'", iVClient, szWeapon );
			}
		}
		else if( 0 < iAClient <= MaxClients && IsClientInGame( iAClient ) )
		{
			if( !bHardcode || nHardcoreMode < 2 )
			{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll( "%N killed %N with %s", iAClient, iVClient, szWeapon );
				else
#endif
				PrintToChatAll( "%cPlayer %c%N%c died at the hands of %c%N%c.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iAClient, CHAT_COLOR_PRIMARY );
			}
			DebugMessage( "Death: '%N', '%N', '%s'", iVClient, iAClient, szWeapon );
		}
		else if( iAttacker == 0 )
		{
			if( !bHardcode || nHardcoreMode < 1 )
			{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll( "%N fell to a clumsy, painful death!", iVClient );
				else
#endif
				PrintToChatAll( "%cPlayer %c%N%c crushed to death.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
			}
			DebugMessage( "Death: '%N', world, '%s'", iVClient, szWeapon );
		}
		else
		{
			if( !bHardcode || nHardcoreMode < 1 )
			{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll( "%N dead.", iVClient );
				else
#endif
				PrintToChatAll( "%cPlayer %c%N%c dead.", CHAT_COLOR_PRIMARY, CHAT_COLOR_SECONDARY, iVClient, CHAT_COLOR_PRIMARY );
			}
			DebugMessage( "Death: '%N', #%d, '%s'", iVClient, iAttacker, szWeapon );
		}
	}
	
	bBleeding[iVClient] = false;
}


public OnGameFrame()
{
	for( new i = 1; i <= MaxClients; i++ )
		if( !IsClientInGame( i ) )
			bBleeding[i] = false;
		else if( IsPlayerAlive( i ) )
			bBleeding[i] = !!GetEntProp( i, Prop_Send, "_bleedingOut" );
}


stock DebugMessage( const String:szFormat[] = "", any:... )
{
	new String:szMessage[251];
	SetGlobalTransTarget( 0 );
	VFormat( szMessage, sizeof( szMessage ), szFormat, 2 );
	
	if( nDebugMode >= 1 )
		PrintToServer( szMessage );
	
	if( nDebugMode >= 2 )
	{
		new String:szFile[PLATFORM_MAX_PATH];
		FormatTime( szFile, sizeof( szFile ), "%Y%m%d" );
		BuildPath( Path_SM, szFile, sizeof( szFile ), "logs/nmp_deaths_%s.log", szFile );
		LogToFile( szFile, szMessage );
	}
}

#if defined USE_HUD
stock PrintToHUD( iClient, const String:szFormat[], any:... )
{
	if( iClient <= 0 || iClient > MaxClients || !IsClientInGame( iClient ) )
	{
		ThrowError( "Client %d is invalid", iClient );
		return;
	}
	
	new String:szBuffer[512];
	SetGlobalTransTarget( iClient );
	VFormat( szBuffer, sizeof( szBuffer ), szFormat, 3 );
	
	SetHudTextParams( flHUDPosition[0], flHUDPosition[1], 5.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0 );
	ShowSyncHudText( iClient, hHUDSync, szBuffer );
}
stock PrintToHUDAll( const String:szFormat[], any:... )
{
	new String:szBuffer[512];
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame( i ) )
		{
			SetGlobalTransTarget( i );
			VFormat( szBuffer, sizeof( szBuffer ), szFormat, 2 );
			PrintToHUD( i, szBuffer );
		}
}
#endif