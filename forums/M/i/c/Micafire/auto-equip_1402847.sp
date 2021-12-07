// Plugin Information
// This plugin is made by someone who has just about started Sourcepawn scripting!
// If their is an error you may gladly correct it on the forums.
// Contact me for more information at wocketspice@gmail.com
//
// About This plugin: Auto-Equip will Give All Players a Grenade Weapon
// Purpose:To Give players weapons set by the cvar on every spawn.
// ToDo:
//	-Allow the weapons to be given on teams set by the cvar
//	-Allow more weapons than the grenade to be given set by flags on a cvar.
//	-Allow Support for other mods(except TF2, will need someone to continue this plugin
// with a version for TF2.
//	-Create an In-Game menu to control the plugin such as weapons to be given on spawn.
//	-OptionalCreate a Timer before giving the items after spawning.
//
// Version History:
//	[1.0.0]Inital Release
//
//

// Includes

#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION	"1.0.0"

// Plugin Information

public Plugin:myinfo =
{
	name 		= "Auto-Equip",
	author 		= "mcilwain(Mars)",
	description 	= "Provides every player on spawn with a Grenade",
	version 	= PLUGIN_VERSION,
	url 		= "http://www.toxicatinggaming.com/"
}
// Cvar's

new Handle:g_Cvar_aeEnabled	= INVALID_HANDLE;

// Code

public OnPluginStart()
{
	g_Cvar_aeEnabled = CreateConVar("sm_Auto_Equip_enabled", "1", "Enable Auto Equip - 1=Enabled");
	HookEvent("player_spawn", Event_Playerspawn);
}

public Action:Event_Playerspawn(Handle:Event, const String:name[], bool:dontbroadcast)
{
	if( GetConVarBool( g_Cvar_aeEnabled ) )
	{
		new Client = GetClientOfUserId(GetEventInt( Event, "userid" ));

		if( Client != 0 && IsClientInGame( Client ) )
		{
			CreateTimer( 0.5, Timer_GiveWeapons, Client );
		}
	}
}

public Action:Timer_GiveWeapons( Handle:Timer, any:client )
{
	GivePlayerItem(client, "weapon_hegrenade");		
}