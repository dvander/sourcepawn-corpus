#include <sourcemod>
#include <sdktools_functions>
#include <zombiereloaded>
public Plugin:myinfo = 
{
    name = "noknives",
    author = "REZOR",
    description = "Invis Knife for zombies",
    version = "1.0",
    url = "http://css-pro.ru/"
}
public OnPluginStart()
{
	HookEvent( "player_spawn", HookPlayerSpawn, EventHookMode_Post );
}
public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if ( IsPlayerAlive( client ) )
    {   
		new knife_entity = GetPlayerWeaponSlot(client, 2);
		SetEntityRenderMode(knife_entity, RENDER_NONE);
	}
}
public ZR_OnClientHumanPost(client, bool:respawn, bool:protect)
{
	if ( IsPlayerAlive( client ) )
    {   
		new knife_entity = GetPlayerWeaponSlot(client, 2);
		SetEntityRenderMode(knife_entity, RENDER_NONE);
	}
}

public HookPlayerSpawn( Handle:event, const String:name[ ], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( IsPlayerAlive( client ) && ZR_IsClientHuman(client) )
	{
			new knife_entity = GetPlayerWeaponSlot(client, 2);
			SetEntityRenderMode(knife_entity, RENDER_TRANSCOLOR);
	}
}