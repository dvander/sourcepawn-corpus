#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0"

// Teams
#define TEAM_T	2
#define TEAM_CT	3

// Variables
new Handle:cvar_enable = INVALID_HANDLE;
new Handle:cvar_armor_amount_t = INVALID_HANDLE;
new Handle:cvar_armor_amount_ct = INVALID_HANDLE;
new Handle:cvar_helmet_t = INVALID_HANDLE;
new Handle:cvar_helmet_ct = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Spawn with Kevlar and Helmet",
	author = "Progressive, fezh",
	description = "Players will get kevlar and helmet on spawn.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar( "sm_spawn_kevlarhelmet_version", PLUGIN_VERSION, "Spawn with Kevlar and Helmet version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	cvar_enable = CreateConVar( "sm_spawn_kevlarhelmet_enable", "1", "Enables Spawn with Kevlar and Helmet" );
	cvar_armor_amount_t = CreateConVar( "sm_armor_amount_t", "100", "Amount of terrorists armor on spawn", _, true, 0.0, true, 125.0 );
	cvar_armor_amount_ct = CreateConVar( "sm_armor_amount_ct", "100", "Amount of counter-terrorists armor on spawn", _, true, 0.0, true, 125.0 );
	cvar_helmet_t = CreateConVar( "sm_give_helmet_t", "1", "Terrorists will get a helmet on spawn" );
	cvar_helmet_ct = CreateConVar( "sm_give_helmet_ct", "1", "Counter-Terrorists will get a helmet on spawn" );
	
	// Execute the config file, create if not present
	AutoExecConfig(true, "spawn_kevlarhelmet");
	
	HookEvent( "player_spawn", HookPlayerSpawn, EventHookMode_Post );
}

public HookPlayerSpawn( Handle:event, const String:name[ ], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( IsPlayerAlive( client ) && GetConVarInt( cvar_enable ) )
	{
		switch( GetClientTeam( client ) )
		{
			case TEAM_T:
			{
				if( GetConVarInt( cvar_helmet_t ) )
					GivePlayerItem( client, "item_assaultsuit"); // Give Kevlar Suit and a Helmet
				SetEntProp( client, Prop_Send, "m_ArmorValue", GetConVarInt( cvar_armor_amount_t ), 1 ); // Set kevlar armour
			}
			case TEAM_CT:
			{
				if( GetConVarInt( cvar_helmet_ct ) )
					GivePlayerItem( client, "item_assaultsuit"); // Give Kevlar Suit and a Helmet
				SetEntProp( client, Prop_Send, "m_ArmorValue", GetConVarInt( cvar_armor_amount_ct ), 1 ); // Set kevlar armour
			}
		}
	}
}
