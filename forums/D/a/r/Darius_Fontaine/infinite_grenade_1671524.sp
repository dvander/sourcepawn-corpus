#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define AUTHOR "Metropolitaner"
//Modded for just HE Grenades for Inversion Therapy by Darius Fontaine

public Plugin:myinfo =
{
	name = "Unlimited Grenades",
	author = AUTHOR,
	description = "Unlimited Grenades",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("hegrenade_detonate", GrenadeDetonate);
}

public GiveGrenade(client, const String:Name[])
{
	GivePlayerItem(client, Name);
}

//public WeaponFire(Handle:event, String:name[], bool:dontBroadcast)
public Action:GrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(StrEqual(name, "hegrenade_detonate")) {GivePlayerItem(client, "weapon_hegrenade");}
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
	{
		GiveGrenade(client, "weapon_hegrenade");
	}
}