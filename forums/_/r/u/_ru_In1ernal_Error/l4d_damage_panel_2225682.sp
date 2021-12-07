#pragma semicolon 1;

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
    name = "L4D Damage Panel",
    author = "Ellome",
    description = "Shows damage done to survivors",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=251734"
}

new Handle: 	g_hCvarInfectedLimit;
new Handle: 	g_hCvarDuration;

new g_iDamage[ MAXPLAYERS + 1 ];
new g_iDontShow[ MAXPLAYERS + 1 ];

public OnPluginStart( )
{
	
	LoadTranslations("l4d_damage_panel.phrases");
	
	RegConsoleCmd( "sm_damage", Damage );
	RegConsoleCmd( "sm_damageoff", DamageHide );
	
	CreateConVar( "l4d_damage_panel_version", PLUGIN_VERSION, "L4D Damage Panel version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	
	g_hCvarInfectedLimit = FindConVar( "z_max_player_zombies" );
	g_hCvarDuration = CreateConVar( "l4d2_damage_duration", "5", "How long the damage panel will be shown", FCVAR_PLUGIN, true, 5.0, true, 10.0 );
	
	HookEvent( "player_death", Event_PlayerKilled );
	HookEvent( "player_disconnect", Event_PlayerDisconnected );
	
}

public Event_PlayerKilled( Handle:event, const String:name[], bool:dontBroadcast )
{

	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( 	g_iDontShow[ victim ] == 0 && 
			IsClientAndInGame( victim ) && 
			!IsFakeClient( victim ) && 
			GetClientTeam( victim ) == 3 &&
			CountRealPlayers( 3 ) > 5
	)
		ShowPanel( victim );

}

public Event_PlayerDisconnected( Handle:event, const String:name[], bool:dontBroadcast )
{

	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	g_iDontShow[ client ] = 0;

}

public Action:Damage(client, args)
{
	
	g_iDontShow[ client ] = 0;
	
	ShowPanel( client );
	
}

public Action:DamageHide(client, args)
{
	
	g_iDontShow[ client ] = 1;
	
	PrintToChat( client, "%t", "TurnDamagePanelOn" );

}

public ShowPanel( client )
{

	// collecting data
	new entity = GetPlayerResourceEntity( );
	new index = -1;
	
	new g_iInfectedLimit = GetConVarInt( g_hCvarInfectedLimit );
	
	new Infected[ g_iInfectedLimit ];

	for ( new i = 1; i <= MaxClients; i++ ) 
	{
		if ( !IsClientAndInGame( i ) || IsFakeClient( i ) || GetClientTeam( i ) != 3 )
			continue;
		
		index++;

		Infected[ index ] = i;
		g_iDamage[ i ] = GetEntProp( entity, Prop_Send, "m_iScore", _, i );

    }

	SortCustom1D( Infected, g_iInfectedLimit, SortByDamageDesc );
	
	// drawing panel
	new Handle:DamagePanel = CreatePanel( );
	new String:text[ 128 ];
	new String:name[ 64 ];
	
	Format( text, sizeof( text ), "%T", "DamageDoneToSurvivors", client);
	
	SetPanelTitle( DamagePanel, text );
	DrawPanelText( DamagePanel, " \n" );
	
	for( new i = 0; i <= index; i++)
	{
		
		GetClientName( Infected[ i ], name, sizeof( name ) );
		
		Format( text, sizeof(text), "%s - %i \n", name, g_iDamage[ Infected[ i ] ] );
		
		DrawPanelItem( DamagePanel, text );
		
	}
	
	SendPanelToClient( DamagePanel, client, PanelHandler, GetConVarInt( g_hCvarDuration ) );

	CloseHandle( DamagePanel );
	
	// send chat notification
	PrintToChat( client, "%t", "TurnDamagePanelOff" );

}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_Select){
		
	} else if (action == MenuAction_Cancel) {
		
	} 

}

public SortByDamageDesc(elem1, elem2, const array[], Handle:hndl)
{
		
	if ( g_iDamage[ elem1 ] < g_iDamage[ elem2 ] ) return 1;
	else if ( g_iDamage[ elem2 ] < g_iDamage[ elem1 ] ) return -1;
	
	else if ( elem1 < elem2 ) return 1;
	else if ( elem2 < elem1 ) return -1;
		
	return 0;
	
}

bool:IsClientAndInGame(index)
{
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}

public CountRealPlayers( team )
{

	new Count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			Count++;
		}
	}
	return Count;

}