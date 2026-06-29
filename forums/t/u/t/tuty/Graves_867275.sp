#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR	"tuty"
#define PLUGIN_VERSION	"1.2"
#define NULL_ENTITY	-1
#define SOLID_BBOX_SM	2
#define DAMAGE_AIM_SM	2
#pragma semicolon 1

enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,             
	FxHologram,             
	FxExplode,             
	FxGlowShell,            
	FxClampMinScale,        
	FxEnvRain,              
	FxEnvSnow,              
	FxSpotlight,     
	FxRagdoll,
	FxPulseFastWider
};
enum Render
{
	Normal = 0, 		
	TransColor, 		
	TransTexture,		
	Glow,				
	TransAlpha,		
	TransAdd,			
	Environmental,		
	TransAddFrameBlend,	
	TransAlphaAdd,		
	WorldGlow,			
	None			
};

new Handle:gGravesEnabled = INVALID_HANDLE;
new Handle:gGravesGlow = INVALID_HANDLE;
new Handle:gGraveHealth = INVALID_HANDLE;

new const String:szGravesModel[] = "models/props/de_inferno/monument.mdl";

public Plugin:myinfo = 
{
	name = "Graves",
	author = PLUGIN_AUTHOR,
	description = "When a player die, on his body appear a grave.",
	version = PLUGIN_VERSION,
	url = "www.ligs.us"
};
public OnPluginStart()
{
	HookEvent( "player_death", Event_PlayerDeath );
	HookEvent( "round_start", Event_RoundStart ); 
	
	CreateConVar ( "graves_version", PLUGIN_VERSION, "Graves Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	gGravesEnabled = CreateConVar( "graves_enable", "1" );
	gGravesGlow = CreateConVar( "graves_glow", "1" );
	gGraveHealth = CreateConVar( "graves_health", "200" );
}
public OnMapStart()
{
	PrecacheModel( szGravesModel );
}
public Action:Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gGravesEnabled ) == 1 )
	{
		new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		if( !IsClientConnected( victim ) && !IsClientInGame( victim ) )
		{
			return Plugin_Handled;
		}
		
		new Float:vOrigin[ 3 ],Float:nOrigin[ 3 ];
		GetClientAbsOrigin( victim, Float:vOrigin );
		
		nOrigin[ 0 ] = vOrigin[ 0 ] + 20.0;
		nOrigin[ 1 ] = vOrigin[ 1 ];
		nOrigin[ 2 ] = vOrigin[ 2 ] - 65.0;
		
		new ent = CreateEntityByName( "prop_physics_override" );
		
		if( !IsValidEntity( ent ) )
		{
			return Plugin_Handled;
		}
		
		SetEntityModel( ent, szGravesModel );
		DispatchSpawn( ent );
		TeleportEntity( ent, nOrigin, NULL_VECTOR, NULL_VECTOR );
		SetEntityMoveType( ent, MOVETYPE_NONE );

		if( GetConVarInt( gGravesGlow ) == 1 )
		{
			switch( GetClientTeam( victim ) )
			{
				case 2:	SetEntityRendering( ent, FxNone, 255, 0, 0, Normal, 7 );// Terorists
				case 3:	SetEntityRendering( ent, FxNone, 0, 0, 255, Normal, 7 );// CT's
			}
		}

		SetEntProp( ent, Prop_Data, "m_nSolidType", SOLID_BBOX_SM );
		SetEntProp( ent, Prop_Data, "m_takedamage", DAMAGE_AIM_SM );
		SetEntProp( ent, Prop_Data, "m_iHealth", GetConVarInt( gGraveHealth ) );
		SetEntPropFloat( ent, Prop_Data, "m_flNextThink", GetGameTime() + 0.1 );

	}
	return Plugin_Handled;
}
public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gGravesEnabled ) == 1 )
	{
		new ent = NULL_ENTITY;
		while( ( ent = FindEntityByClassname( ent, "prop_physics_override" ) != NULL_ENTITY ) )
		{
			RemoveEdict( ent );
		}
	}
}
stock SetEntityRendering( entity, FX:fx = FxNone, r = 255, g = 255, b = 255, Render:render = Normal, amount = 255 )
{
	SetEntProp( entity, Prop_Send, "m_nRenderFX", _:fx, 1 );
	SetEntProp( entity, Prop_Send, "m_nRenderMode", _:render, 1 );

	new offset = GetEntSendPropOffs( entity, "m_clrRender" );
	
	SetEntData( entity, offset, r, 1, true );
	SetEntData( entity, offset + 1, g, 1, true );
	SetEntData( entity, offset + 2, b, 1, true );
	SetEntData( entity, offset + 3, amount, 1, true );
}
