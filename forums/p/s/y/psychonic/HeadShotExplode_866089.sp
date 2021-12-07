#include <sourcemod>
#include <sdktools>

#define ANY 0
#define DODS 1
#define TF2 2

#pragma semicolon 1
#define PLUGIN_VERSION	"1.1"
#define PLUGIN_AUTHOR	"tuty, psychonic"
#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"

new Handle:gPluginEnabled;
new g_ExplosionSprite;
new g_SmokeSprite;
new Float:iNormal[ 3 ] = { 0.0, 0.0, 1.0 };
new g_iGamemod = 0;

public Plugin:myinfo = 
{
	name = "HeadShot Explode",
	author = PLUGIN_AUTHOR,
	description = "Explode enemy's body on Headshot.",
	version = PLUGIN_VERSION,
	url = "http://www.ligs.us/"
};
public OnPluginStart()
{
	CreateConVar("sm_headshot_explode", PLUGIN_VERSION, "HeadShot Explode", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	gPluginEnabled = CreateConVar( "sm_headshot_explode", "1" );
	
	decl String: szGameDesc[64];
	GetGameDescription(szGameDesc, sizeof(szGameDesc), true);
	if (StrContains(szGameDesc, "Day of Defeat", false) != -1)
	{
		g_iGamemod = DODS;
		HookEvent( "player_hurt", Event_PlayerHurt );
	}
	else if (StrContains(szGameDesc, "Team Fortress", false) != -1)
	{
		g_iGamemod = TF2;
		HookEvent( "player_death", Event_PlayerDeath );
	}
	else
	{
		HookEvent( "player_death", Event_PlayerDeath );
	}
}
public OnMapStart() 
{
	PrecacheSound( EXPLODE_SOUND, true );
	g_ExplosionSprite = PrecacheModel( "sprites/blueglow2.vmt" );
	g_SmokeSprite = PrecacheModel( "sprites/steam1.vmt" );
}
public Action:Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{
		new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
		new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );

		if( victim == attacker )
		{
			return Plugin_Handled;
		}
		
		if( (g_iGamemod == ANY && GetEventBool( event, "headshot" )) || (g_iGamemod == TF2 && GetEventInt(event, "customkill") == 1) )
		{
			DoExplosion(victim);
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerHurt( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{
		new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
		new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );

		if( victim == attacker )
		{
			return Plugin_Handled;
		}
		
		new Float:iVec[ 3 ];
		GetClientAbsOrigin( victim, Float:iVec );
		
		if( GetEventInt(event, "health") <= 0 && GetEventInt(event, "hitgroup") == 1 )
		{
			TE_SetupExplosion( iVec, g_ExplosionSprite, 5.0, 1, 0, 50, 40, iNormal );
			TE_SendToAll();
			
			TE_SetupSmoke( iVec, g_SmokeSprite, 10.0, 3 );
			TE_SendToAll();
	
			EmitAmbientSound( EXPLODE_SOUND, iVec, victim, SNDLEVEL_NORMAL );
		}
	}
	return Plugin_Continue;
}

DoExplosion(victim)
{
	new Float:iVec[ 3 ];
	GetClientAbsOrigin( victim, Float:iVec );
	
	TE_SetupExplosion( iVec, g_ExplosionSprite, 5.0, 1, 0, 50, 40, iNormal );
	TE_SendToAll();
	
	TE_SetupSmoke( iVec, g_SmokeSprite, 10.0, 3 );
	TE_SendToAll();

	EmitAmbientSound( EXPLODE_SOUND, iVec, victim, SNDLEVEL_NORMAL );
}