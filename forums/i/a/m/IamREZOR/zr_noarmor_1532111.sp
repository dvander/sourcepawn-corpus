#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "No armor for zombies",
	author = "REZOR (css-pro.ru)",
	description = "Remove armor from zombies",
	version = PLUGIN_VERSION,
	url = "http://www.css-pro.ru"
};

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if ( IsPlayerAlive( client ) )
    {
		SetEntProp( client, Prop_Send, "m_ArmorValue", 0, 1 );
	}
}