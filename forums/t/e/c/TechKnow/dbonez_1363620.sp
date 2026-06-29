#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR	"TechKnow"
#define PLUGIN_VERSION	"1.2"
#define NULL_ENTITY	-1
#define SOLID_BBOX_SM	2
#define DAMAGE_AIM_SM	2
#define MAX_FILE_LEN 256
//#pragma semicolon 1

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

new Handle:gDbonezEnabled = INVALID_HANDLE;
new Handle:gDbonezGlow = INVALID_HANDLE;
new Handle:gDbonezHealth = INVALID_HANDLE;

new const String:szDbonezModel[] = "models/props_techknow/d-bonez.mdl";

public Plugin:myinfo = 
{
	name = "Dbonez",
	author = PLUGIN_AUTHOR,
	description = "When a player dies, a dancing skeleton appears.",
	version = PLUGIN_VERSION,
	url = "http://techknowmodels.19.forumer.com"
};
public OnPluginStart()
{
	HookEvent( "player_death", Event_PlayerDeath );
	HookEvent( "round_start", Event_RoundStart ); 
	
	CreateConVar ( "Dbonez_version", PLUGIN_VERSION, "Dbonez Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	gDbonezEnabled = CreateConVar( "Dbonez_enable", "1" );
	gDbonezGlow = CreateConVar( "Dbonez_glow", "1" );
	gDbonezHealth = CreateConVar( "Dbonez_health", "50" );
}
public OnMapStart()
{
	AddFileToDownloadsTable("models/props_techknow/d-bonez.mdl");
	AddFileToDownloadsTable("models/props_techknow/d-bonez.phy");
	AddFileToDownloadsTable("models/props_techknow/d-bonez.vvd");
	AddFileToDownloadsTable("models/props_techknow/d-bonez.sw.vtx");
	AddFileToDownloadsTable("models/props_techknow/d-bonez.dx80.vtx");
	AddFileToDownloadsTable("models/props_techknow/d-bonez.dx90.vtx");
	PrecacheModel( szDbonezModel );
}
public Action:Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gDbonezEnabled ) == 1 )
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
		
		new ent = CreateEntityByName( "prop_dynamic_override" );
		
		if( !IsValidEntity( ent ) )
		{
			return Plugin_Handled;
		}
		
		SetEntityModel( ent, szDbonezModel );
                DispatchKeyValue(ent, "StartDisabled", "false");
                DispatchKeyValue(ent, "Solid", "6");
		DispatchSpawn( ent );
                AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
                AcceptEntityInput(ent, "EnableCollision");
		TeleportEntity( ent, nOrigin, NULL_VECTOR, NULL_VECTOR );
                SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);
                SetEntProp(ent, Prop_Data, "m_usSolidFlags", 28);
                SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
                SetEntityMoveType(ent, MOVETYPE_NONE);
                DispatchKeyValue(ent, "spawnflags", "8");
                SetVariantString("idle");
                AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);


		if( GetConVarInt( gDbonezGlow ) == 1 )
		{
			switch( GetClientTeam( victim ) )
			{
				case 2:	SetEntityRendering( ent, FxNone, 255, 0, 0, Normal, 7 );// Terorists
				case 3:	SetEntityRendering( ent, FxNone, 0, 0, 255, Normal, 7 );// CT's
			}
		}

		SetEntProp( ent, Prop_Data, "m_nSolidType", SOLID_BBOX_SM );
		SetEntProp( ent, Prop_Data, "m_takedamage", DAMAGE_AIM_SM );
		SetEntProp( ent, Prop_Data, "m_iHealth", GetConVarInt( gDbonezHealth ) );

	}
	return Plugin_Handled;
}
public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gDbonezEnabled ) == 1 )
	{
		new ent = NULL_ENTITY;
		while( ( ent = FindEntityByClassname( ent, "prop_dynamic_override" ) != NULL_ENTITY ) )
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
