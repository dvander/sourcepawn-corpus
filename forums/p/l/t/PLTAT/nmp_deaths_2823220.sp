#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define DEATHFLAG_NONE			0
#define DEATHFLAG_BLEED			(1<<0)
#define DEATHFLAG_INFECT		(1<<1)
#define USE_HUD					1


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

public Plugin:myinfo = 
{
	name = "Death Notify",
	author = "leonardo and edit by A3",
	description = "",
	version = "2.2",
	url = ""
};


public OnPluginStart()
{
	LoadTranslations("nmp_deaths.phrases");
	
	HookConVarChange( nmp_dn_enabled = CreateConVar( "nmp_dn_enabled", bEnabled ? "1" : "0", _, FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_debug = CreateConVar( "nmp_dn_debug", "0", "Debug messages:\n0 - disabled,\n1 - server console only,\n2 - server console and logs", FCVAR_NOTIFY, true, 0.0, true, 2.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_teamattacks = CreateConVar( "nmp_dn_teamattacks", bTA ? "1" : "0", "Enable TeamAttack notifications", FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_hardcore = CreateConVar( "nmp_dn_hardcore", "1", "Obey sv_hardcore_survival:\n0 - print all notifications,\n1 - print team kills only,\n2 - don't print anything", FCVAR_NOTIFY, true, 0.0, true, 2.0 ), OnConVarChanged );
	HookConVarChange( sv_hardcore_survival = FindConVar( "sv_hardcore_survival" ), OnConVarChanged );
#if defined USE_HUD
	HookConVarChange( nmp_dn_hud = CreateConVar( "nmp_dn_hud", bHUD ? "0" : "0", "Set 1 to print notifications in top right corner, otherwise - in chat", FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_hud_x = CreateConVar( "nmp_dn_hud_x", "1.0", _, FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_dn_hud_y = CreateConVar( "nmp_dn_hud_y", "0.0875", _, FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
#endif
	AutoExecConfig(true, "nmp_deaths");
	
	HookEvent( "player_spawn", Event_PlayerSpawn );
	HookEvent( "player_hurt", Event_PlayerHurt );
	HookEvent( "player_death", Event_PlayerDeath );
	
#if defined USE_HUD
	hHUDSync = CreateHudSynchronizer();
#endif
}

public OnMapStart()
{
	flLastTA = 0.0;
}
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
{
	OnConfigsExecuted();
}
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
		PrintToServer("%t", "%N was attacked by %N", iVClient, iAClient);
		if( !bDontBroadcast && ( !bHardcode || nHardcoreMode < 2 ) )
			PrintToChatAll("%t", "%N was attacked by %N", iVClient, iAClient);
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
					PrintToHUDAll("%t", "%N died to his dead mate", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to his dead mate", iVClient);
				}
				else if( StrContains( szWeapon, "_kidzombie", false ) > 0 )
				{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N died to kidzombie", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to kidzombie", iVClient);
				}
				else if( StrContains( szWeapon, "_runnerzombie", false ) > 0 )
				{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N died to runnerzombie", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to runnerzombie", iVClient);
				}
				else if( StrContains( szWeapon, "_shamblerzombie", false ) > 0 )
				{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N died to shamblerzombie", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to shamblerzombie", iVClient);
				}
				else if( StrContains( szWeapon, "zombie", false ) > 0 )
				{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N died to zombie", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to zombie", iVClient);
				}
				else
				{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N died to NPC", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to NPC", iVClient);
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
					PrintToHUDAll("%t", "%N died to infection", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to infection", iVClient);
				}
				DebugMessage( "Death: '%N', infection, '%s'", iVClient, szWeapon );
			}
			else if( bBleeding[iVClient] )
			{
				if( !bHardcode || nHardcoreMode < 1 )
				{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N died to loss of blood", iVClient );
				else
#endif
					PrintToChatAll("%t", "%N died to loss of blood", iVClient);
				}
				DebugMessage( "Death: '%N', blood loss, '%s'", iVClient, szWeapon );
			}
			else
			{
				if( !bHardcode || nHardcoreMode < 1 )
				{
#if defined USE_HUD
					if( bHUD )
						PrintToHUDAll("%t", "%N commited suicide", iVClient );
					else
#endif
					PrintToChatAll("%t", "%N commited suicide", iVClient);
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
					PrintToHUDAll("%t", "%N killed %N with %s", iAClient, iVClient, szWeapon );
				else
#endif
				PrintToChatAll("%t", "%N died at the hands of %N", iVClient,  iAClient);
			}
			DebugMessage( "Death: '%N', '%N', '%s'", iVClient, iAClient, szWeapon );
		}
		else if( iAttacker == 0 )
		{
			if( !bHardcode || nHardcoreMode < 1 )
			{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N crushed to death", iVClient );
				else
#endif
				PrintToChatAll("%t", "%N crushed to death", iVClient);
			}
			DebugMessage( "Death: '%N', world, '%s'", iVClient, szWeapon );
		}
		else
		{
			if( !bHardcode || nHardcoreMode < 1 )
			{
#if defined USE_HUD
				if( bHUD )
					PrintToHUDAll("%t", "%N dead", iVClient );
				else
#endif
				PrintToChatAll("%t", "%N dead", iVClient);
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